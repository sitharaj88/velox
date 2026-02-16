import 'dart:async';

import 'package:meta/meta.dart';
import 'package:velox_event_bus/src/velox_event.dart';

/// A typed, broadcast-based event bus for decoupled communication.
///
/// [VeloxEventBus] uses a single [StreamController.broadcast] internally
/// and filters events by type when subscribers call [on].
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
  VeloxEventBus();

  final StreamController<VeloxEvent> _controller =
      StreamController<VeloxEvent>.broadcast();

  bool _isDisposed = false;

  /// Whether this event bus has been disposed.
  ///
  /// Once disposed, no events can be fired and no new subscriptions
  /// can be created.
  bool get isDisposed => _isDisposed;

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

  /// Fires a single [event] to all matching listeners.
  ///
  /// The event will be delivered to every listener whose type filter
  /// matches the runtime type of [event].
  ///
  /// Throws a [StateError] if the event bus has been disposed.
  void fire(VeloxEvent event) {
    _assertNotDisposed();
    _controller.add(event);
  }

  /// Fires multiple [events] to all matching listeners.
  ///
  /// Events are dispatched in order. Each event will be delivered to
  /// every listener whose type filter matches.
  ///
  /// Throws a [StateError] if the event bus has been disposed.
  void fireAll(List<VeloxEvent> events) {
    _assertNotDisposed();
    for (final event in events) {
      _controller.add(event);
    }
  }

  /// Returns `true` if there is at least one listener on this event bus.
  ///
  /// Note: Because the bus uses a single broadcast stream controller,
  /// this checks for listeners on the bus as a whole. To check for
  /// listeners of a specific type, use [hasListenersFor].
  bool get hasListeners => _controller.hasListener;

  /// Returns `true` if there is at least one listener on this event bus.
  ///
  /// Because the bus uses a single broadcast [StreamController], this
  /// reports whether *any* listener is attached. For fine-grained
  /// per-type checking, maintain your own bookkeeping.
  @visibleForTesting
  bool hasListenersFor<T extends VeloxEvent>() => _controller.hasListener;

  /// Closes the underlying stream controller and releases resources.
  ///
  /// After calling [dispose], any calls to [fire], [fireAll], or [on]
  /// will throw a [StateError].
  ///
  /// Returns a [Future] that completes when the controller is closed.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _controller.close();
  }

  void _assertNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'Cannot use a VeloxEventBus after it has been disposed.',
      );
    }
  }
}
