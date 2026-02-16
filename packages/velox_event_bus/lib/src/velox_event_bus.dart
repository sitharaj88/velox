// ignore_for_file: cancel_subscriptions

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:velox_event_bus/src/event_handler.dart';
import 'package:velox_event_bus/src/event_interceptor.dart';
import 'package:velox_event_bus/src/event_subscription.dart';
import 'package:velox_event_bus/src/velox_event.dart';

/// A typed, broadcast-based event bus for decoupled communication.
///
/// [VeloxEventBus] uses a single [StreamController.broadcast] internally
/// and filters events by type when subscribers call [on].
///
/// Features:
/// - **Type-safe subscriptions** via [on] and [listen]
/// - **Priority-based handling** with [listen] and [priority] parameter
/// - **Async event handling** via [emitAsync] that awaits all handlers
/// - **One-shot listeners** via [listenOnce] that auto-cancel
/// - **Event history** with configurable buffer and [listenWithHistory]
/// - **Event filtering** with [filter] parameter on [listen]
/// - **Sticky events** retained per type for late subscribers
/// - **Event interceptors** to transform or block events
/// - **Stream-based API** via [on] returning typed streams
/// - **Error isolation** ensuring one failing handler cannot block others
///
/// ```dart
/// final bus = VeloxEventBus();
///
/// // Subscribe to a specific event type.
/// bus.on<UserLoggedIn>().listen((event) {
///   print('User logged in: ${event.userId}');
/// });
///
/// // Fire an event.
/// bus.fire(UserLoggedIn('user-42'));
///
/// // Dispose when done.
/// bus.dispose();
/// ```
class VeloxEventBus {
  /// Creates a new [VeloxEventBus].
  ///
  /// [historySize] controls how many recent events per type are retained
  /// for replay via [listenWithHistory]. Defaults to `0` (no history).
  VeloxEventBus({this.historySize = 0})
      : assert(historySize >= 0, 'historySize must be non-negative');

  /// The maximum number of past events per type to retain for replay.
  final int historySize;

  final StreamController<VeloxEvent> _controller =
      StreamController<VeloxEvent>.broadcast();

  bool _isDisposed = false;

  /// Registered handlers per event type, sorted by priority.
  ///
  /// Handlers are stored as their concrete [EventHandler<T>] type but
  /// referenced via the [EventHandler] base parameterized on [VeloxEvent]
  /// to avoid type erasure issues. Dispatch uses [EventHandler.invoke]
  /// which internally casts back to the correct type.
  final Map<Type, List<EventHandler<VeloxEvent>>> _handlers = {};

  /// Interceptors that can transform or block events before delivery.
  final List<EventInterceptor<VeloxEvent>> _interceptors = [];

  /// History buffer per event type.
  final Map<Type, List<VeloxEvent>> _history = {};

  /// Sticky events: last emitted event per type.
  final Map<Type, VeloxEvent> _stickyEvents = {};

  /// Error handler called when a handler throws.
  ///
  /// If not set, errors in handlers are silently caught and do not
  /// prevent other handlers from executing.
  void Function(Object error, StackTrace stackTrace)? onError;

  /// Whether this event bus has been disposed.
  ///
  /// Once disposed, no events can be fired and no new subscriptions
  /// can be created.
  bool get isDisposed => _isDisposed;

  // ---------------------------------------------------------------------------
  // Stream-based API
  // ---------------------------------------------------------------------------

  /// Returns a stream of events of type [T].
  ///
  /// Only events that are exactly of type [T] or a subtype of [T] will
  /// be delivered to listeners on this stream.
  ///
  /// ```dart
  /// bus.on<UserLoggedIn>().listen((event) {
  ///   print(event.userId);
  /// });
  /// ```
  ///
  /// Throws a [StateError] if the event bus has been disposed.
  Stream<T> on<T extends VeloxEvent>() {
    _assertNotDisposed();
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  // ---------------------------------------------------------------------------
  // Handler-based API (priority, filter, once)
  // ---------------------------------------------------------------------------

  /// Registers a handler for events of type [T].
  ///
  /// [handler] is invoked each time a matching event is fired.
  /// [priority] determines execution order; higher values execute first.
  /// Handlers with the same priority execute in registration order.
  /// [filter] is an optional predicate to restrict which events trigger
  /// this handler.
  ///
  /// Returns a [VeloxEventSubscription] that can be used to cancel the
  /// registration.
  ///
  /// Throws a [StateError] if the event bus has been disposed.
  VeloxEventSubscription listen<T extends VeloxEvent>(
    EventCallback<T> handler, {
    int priority = 0,
    EventFilter<T>? filter,
  }) {
    _assertNotDisposed();

    final eventHandler = EventHandler<T>(
      callback: handler,
      priority: priority,
      filter: filter,
    );

    _addHandler<T>(eventHandler);

    // We create a no-op stream subscription just for lifecycle management
    // (pause/resume/cancel). The actual handler invocation happens in
    // _dispatchToHandlers which is called synchronously from fire().
    final sub = on<T>().listen((event) {});

    return VeloxEventSubscription(
      sub,
      onCancel: () => _removeHandler<T>(eventHandler),
    );
  }

  /// Registers a one-shot handler that auto-cancels after the first event.
  ///
  /// [handler] is invoked exactly once for the first matching event,
  /// then the subscription is automatically cancelled.
  /// [priority] determines execution order relative to other handlers.
  /// [filter] is an optional predicate.
  ///
  /// Returns a [VeloxEventSubscription] that can be used to cancel before
  /// the handler fires.
  ///
  /// Throws a [StateError] if the event bus has been disposed.
  VeloxEventSubscription listenOnce<T extends VeloxEvent>(
    EventCallback<T> handler, {
    int priority = 0,
    EventFilter<T>? filter,
  }) {
    _assertNotDisposed();

    final eventHandler = EventHandler<T>(
      callback: handler,
      priority: priority,
      filter: filter,
      isOnce: true,
    );

    _addHandler<T>(eventHandler);

    final sub = on<T>().listen((event) {});

    return VeloxEventSubscription(
      sub,
      onCancel: () => _removeHandler<T>(eventHandler),
    );
  }

  /// Registers a handler and immediately replays the last [count] events
  /// of type [T] from the history buffer.
  ///
  /// [handler] is invoked for each replayed event and for all future events.
  /// [count] limits how many historical events to replay. Defaults to the
  /// full history buffer.
  /// [priority] determines execution order.
  /// [filter] is an optional predicate.
  ///
  /// Requires [historySize] > 0 on the bus for events to be retained.
  ///
  /// Returns a [VeloxEventSubscription].
  ///
  /// Throws a [StateError] if the event bus has been disposed.
  VeloxEventSubscription listenWithHistory<T extends VeloxEvent>(
    EventCallback<T> handler, {
    int? count,
    int priority = 0,
    EventFilter<T>? filter,
  }) {
    _assertNotDisposed();

    // Replay historical events.
    final history = _getHistory<T>();
    final replayCount = count ?? history.length;
    final start =
        history.length > replayCount ? history.length - replayCount : 0;

    for (var i = start; i < history.length; i++) {
      final event = history[i] as T;
      if (filter == null || filter(event)) {
        handler(event);
      }
    }

    // Register for future events.
    return listen<T>(handler, priority: priority, filter: filter);
  }

  /// Registers a handler and immediately delivers the sticky (most recent)
  /// event of type [T] if one exists.
  ///
  /// The sticky event is the last event of each type that was fired.
  /// Sticky events persist until [clearStickyEvent] or [clearAllStickyEvents]
  /// is called.
  ///
  /// Returns a [VeloxEventSubscription].
  ///
  /// Throws a [StateError] if the event bus has been disposed.
  VeloxEventSubscription listenSticky<T extends VeloxEvent>(
    EventCallback<T> handler, {
    int priority = 0,
    EventFilter<T>? filter,
  }) {
    _assertNotDisposed();

    // Deliver sticky event immediately if available.
    final sticky = _stickyEvents[T];
    if (sticky != null && sticky is T) {
      if (filter == null || filter(sticky)) {
        handler(sticky);
      }
    }

    return listen<T>(handler, priority: priority, filter: filter);
  }

  // ---------------------------------------------------------------------------
  // Firing events
  // ---------------------------------------------------------------------------

  /// Fires a single [event] to all matching listeners.
  ///
  /// The event passes through all registered interceptors first. If any
  /// interceptor returns `null`, the event is blocked and not delivered.
  ///
  /// After interceptors, the event is dispatched to all registered handlers
  /// in priority order (highest first), then added to the broadcast stream.
  ///
  /// Throws a [StateError] if the event bus has been disposed.
  void fire(VeloxEvent event) {
    _assertNotDisposed();

    final processed = _applyInterceptors(event);
    if (processed == null) return;

    _recordEvent(processed);
    _dispatchToHandlers(processed);
    _controller.add(processed);
  }

  /// Fires multiple [events] to all matching listeners.
  ///
  /// Events are dispatched in order. Each event passes through interceptors
  /// individually.
  ///
  /// Throws a [StateError] if the event bus has been disposed.
  void fireAll(List<VeloxEvent> events) {
    _assertNotDisposed();
    for (final event in events) {
      fire(event);
    }
  }

  /// Fires an [event] and asynchronously awaits all async handlers.
  ///
  /// Like [fire], the event passes through interceptors first.
  /// Unlike [fire], this method awaits all handler futures, collecting
  /// errors without preventing other handlers from executing.
  ///
  /// Returns a [Future] that completes when all handlers have finished.
  /// If any handlers throw, the errors are reported via [onError] but
  /// do not cause this future to fail.
  ///
  /// Throws a [StateError] if the event bus has been disposed.
  Future<void> emitAsync(VeloxEvent event) async {
    _assertNotDisposed();

    final processed = _applyInterceptors(event);
    if (processed == null) return;

    _recordEvent(processed);
    await _dispatchToHandlersAsync(processed);
    _controller.add(processed);
  }

  // ---------------------------------------------------------------------------
  // Interceptors
  // ---------------------------------------------------------------------------

  /// Adds an [interceptor] to the event pipeline.
  ///
  /// Interceptors are applied in the order they are added. Each interceptor
  /// can transform the event or return `null` to block it.
  ///
  /// Throws a [StateError] if the event bus has been disposed.
  void addInterceptor<T extends VeloxEvent>(EventInterceptor<T> interceptor) {
    _assertNotDisposed();
    _interceptors.add(interceptor as EventInterceptor<VeloxEvent>);
  }

  /// Removes a previously added [interceptor].
  ///
  /// Returns `true` if the interceptor was found and removed.
  bool removeInterceptor<T extends VeloxEvent>(
    EventInterceptor<T> interceptor,
  ) =>
      _interceptors.remove(interceptor);

  // ---------------------------------------------------------------------------
  // Sticky events
  // ---------------------------------------------------------------------------

  /// Returns the sticky event for type [T], or `null` if none exists.
  T? getStickyEvent<T extends VeloxEvent>() => _stickyEvents[T] as T?;

  /// Clears the sticky event for type [T].
  ///
  /// Returns the removed event, or `null` if none existed.
  T? clearStickyEvent<T extends VeloxEvent>() =>
      _stickyEvents.remove(T) as T?;

  /// Clears all sticky events.
  void clearAllStickyEvents() {
    _stickyEvents.clear();
  }

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  /// Returns a copy of the event history for type [T].
  List<T> getHistory<T extends VeloxEvent>() =>
      List<T>.unmodifiable(_getHistory<T>());

  /// Clears the event history for type [T].
  void clearHistory<T extends VeloxEvent>() {
    _history.remove(T);
  }

  /// Clears all event history.
  void clearAllHistory() {
    _history.clear();
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns `true` if there is at least one listener on this event bus.
  ///
  /// Note: Because the bus uses a single broadcast stream controller,
  /// this checks for listeners on the bus as a whole. To check for
  /// listeners of a specific type, use [hasListenersFor].
  bool get hasListeners =>
      _controller.hasListener || _handlers.values.any((h) => h.isNotEmpty);

  /// Returns `true` if there is at least one listener on this event bus.
  ///
  /// Because the bus uses a single broadcast [StreamController], this
  /// reports whether *any* listener is attached. For fine-grained
  /// per-type checking, maintain your own bookkeeping.
  @visibleForTesting
  bool hasListenersFor<T extends VeloxEvent>() => _controller.hasListener;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Closes the underlying stream controller and releases resources.
  ///
  /// After calling [dispose], any calls to [fire], [fireAll], or [on]
  /// will throw a [StateError].
  ///
  /// Returns a [Future] that completes when the controller is closed.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _handlers.clear();
    _interceptors.clear();
    _history.clear();
    _stickyEvents.clear();
    await _controller.close();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _assertNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'Cannot use a VeloxEventBus after it has been disposed.',
      );
    }
  }

  void _addHandler<T extends VeloxEvent>(EventHandler<T> handler) {
    _handlers.putIfAbsent(T, () => [])
      ..add(handler as EventHandler<VeloxEvent>)
      // Sort by priority descending (highest first), stable sort preserves
      // insertion order for equal priorities.
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  void _removeHandler<T extends VeloxEvent>(EventHandler<T> handler) {
    _handlers[T]?.remove(handler);
  }

  VeloxEvent? _applyInterceptors(VeloxEvent event) {
    VeloxEvent? current = event;
    for (final interceptor in _interceptors) {
      if (current == null) return null;
      current = interceptor.intercept(current);
    }
    return current;
  }

  void _recordEvent(VeloxEvent event) {
    // Record sticky event.
    _stickyEvents[event.runtimeType] = event;

    // Record in history buffer.
    if (historySize > 0) {
      final typeHistory =
          _history.putIfAbsent(event.runtimeType, () => <VeloxEvent>[])
            ..add(event);
      if (typeHistory.length > historySize) {
        typeHistory.removeAt(0);
      }
    }
  }

  void _dispatchToHandlers(VeloxEvent event) {
    final eventType = event.runtimeType;
    final handlers = _handlers[eventType];
    if (handlers == null || handlers.isEmpty) return;

    final toRemove = <EventHandler<VeloxEvent>>[];

    for (final handler in List<EventHandler<VeloxEvent>>.of(handlers)) {
      try {
        if (handler.shouldHandle(event)) {
          handler.invoke(event);
          if (handler.isOnce) {
            toRemove.add(handler);
          }
        }
      } on Object catch (error, stackTrace) {
        _reportError(error, stackTrace);
      }
    }

    for (final handler in toRemove) {
      handlers.remove(handler);
    }
  }

  Future<void> _dispatchToHandlersAsync(VeloxEvent event) async {
    final eventType = event.runtimeType;
    final handlers = _handlers[eventType];
    if (handlers == null || handlers.isEmpty) return;

    final toRemove = <EventHandler<VeloxEvent>>[];

    for (final handler in List<EventHandler<VeloxEvent>>.of(handlers)) {
      try {
        if (handler.shouldHandle(event)) {
          await handler.invoke(event);
          if (handler.isOnce) {
            toRemove.add(handler);
          }
        }
      } on Object catch (error, stackTrace) {
        _reportError(error, stackTrace);
      }
    }

    for (final handler in toRemove) {
      handlers.remove(handler);
    }
  }

  void _reportError(Object error, StackTrace stackTrace) {
    onError?.call(error, stackTrace);
    // If no error handler is set, errors are silently swallowed
    // to prevent one failing handler from blocking others.
  }

  List<VeloxEvent> _getHistory<T extends VeloxEvent>() =>
      _history[T] ?? <VeloxEvent>[];

  // ---------------------------------------------------------------------------
  // Protected-like methods for subclass access (e.g., ScopedEventBus)
  // ---------------------------------------------------------------------------

  /// Injects an event directly into the broadcast stream and handler pipeline.
  ///
  /// This bypasses interceptors and is intended for internal use by subclasses
  /// such as [ScopedEventBus] when forwarding parent events.
  @protected
  void injectEvent(VeloxEvent event) {
    if (_isDisposed) return;
    _recordEvent(event);
    _dispatchToHandlers(event);
    _controller.add(event);
  }
}
