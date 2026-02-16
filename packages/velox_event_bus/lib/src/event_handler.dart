import 'dart:async';

import 'package:velox_event_bus/src/velox_event.dart';

/// A callback type for synchronous event handlers.
typedef EventCallback<T extends VeloxEvent> = void Function(T event);

/// A callback type for asynchronous event handlers.
typedef AsyncEventCallback<T extends VeloxEvent> = FutureOr<void> Function(
  T event,
);

/// A predicate function used to filter events before handler execution.
typedef EventFilter<T extends VeloxEvent> = bool Function(T event);

/// An internal registration of an event handler with priority and metadata.
///
/// [EventHandler] wraps a callback along with its [priority], optional
/// [filter], and configuration flags. Higher priority values execute first.
class EventHandler<T extends VeloxEvent> {
  /// Creates an [EventHandler] with the given configuration.
  ///
  /// [callback] is the function to invoke when a matching event is received.
  /// [priority] determines execution order (higher values run first).
  /// [filter] is an optional predicate to restrict which events trigger
  /// this handler.
  /// [isOnce] indicates whether the handler should auto-cancel after the
  /// first invocation.
  EventHandler({
    required AsyncEventCallback<T> callback,
    this.priority = 0,
    EventFilter<T>? filter,
    this.isOnce = false,
  })  : _callback = callback,
        _filter = filter;

  final AsyncEventCallback<T> _callback;
  final EventFilter<T>? _filter;

  /// The priority of this handler. Higher values execute first.
  ///
  /// Defaults to `0`. Handlers with the same priority execute in
  /// registration order.
  final int priority;

  /// Whether this handler should be removed after the first invocation.
  final bool isOnce;

  /// The type this handler is registered for.
  Type get eventType => T;

  /// Whether this handler should process the given [event].
  ///
  /// The event is cast to [T] internally. Returns `false` if the event
  /// does not match the filter.
  bool shouldHandle(VeloxEvent event) {
    if (event is! T) return false;
    return _filter == null || _filter(event);
  }

  /// Invokes the callback with the given [event].
  ///
  /// The event must be of type [T] or a subtype.
  FutureOr<void> invoke(VeloxEvent event) => _callback(event as T);
}
