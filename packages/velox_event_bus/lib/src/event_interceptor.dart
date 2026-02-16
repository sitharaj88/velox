import 'package:velox_event_bus/src/velox_event.dart';

/// An interceptor that can transform or block events before delivery.
///
/// Interceptors act as middleware in the event pipeline. They can:
/// - Transform an event into a different event of the same type
/// - Block an event by returning `null`
/// - Pass an event through unchanged
///
/// ```dart
/// final bus = VeloxEventBus();
/// bus.addInterceptor(EventInterceptor<UserLoggedIn>(
///   (event) {
///     // Transform or return null to block
///     return event;
///   },
/// ));
/// ```
class EventInterceptor<T extends VeloxEvent> {
  /// Creates an [EventInterceptor] with the given [_intercept] function.
  ///
  /// The function receives an event and returns either:
  /// - The same event (pass-through)
  /// - A modified event of the same type (transform)
  /// - `null` to block the event from delivery
  EventInterceptor(this._intercept);

  final T? Function(T event) _intercept;

  /// The type this interceptor handles.
  Type get eventType => T;

  /// Applies this interceptor to the given [event].
  ///
  /// Returns `null` if the event should be blocked, or the (possibly
  /// transformed) event if it should continue through the pipeline.
  ///
  /// If the event is not of type [T], it is returned unchanged (pass-through).
  VeloxEvent? intercept(VeloxEvent event) {
    if (event is T) {
      return _intercept(event);
    }
    // Event type doesn't match this interceptor; pass through.
    return event;
  }
}
