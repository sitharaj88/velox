import 'dart:async';

/// A callback that is invoked when a subscription is cancelled.
typedef CancelCallback = void Function();

/// A handle to an event bus subscription that can be cancelled.
///
/// Wraps a [StreamSubscription] and provides a simplified cancellation API.
/// Use this to manage the lifecycle of event listeners:
///
/// ```dart
/// final subscription = bus.on<UserLoggedIn>().listen(print);
/// final handle = VeloxEventSubscription(subscription);
///
/// // Later, when you no longer need to listen:
/// handle.cancel();
/// ```
class VeloxEventSubscription {
  /// Creates a [VeloxEventSubscription] wrapping the given [_subscription].
  ///
  /// An optional [onCancel] callback is invoked when the subscription is
  /// cancelled, allowing cleanup of handler registrations.
  VeloxEventSubscription(this._subscription, {CancelCallback? onCancel})
      : _onCancel = onCancel;

  final StreamSubscription<dynamic> _subscription;
  final CancelCallback? _onCancel;

  bool _isCancelled = false;

  /// Whether this subscription has been cancelled.
  bool get isCancelled => _isCancelled;

  /// Cancels the underlying stream subscription.
  ///
  /// After calling this method, no more events will be delivered.
  /// Calling [cancel] more than once has no effect.
  Future<void> cancel() async {
    if (_isCancelled) return;
    _isCancelled = true;
    _onCancel?.call();
    await _subscription.cancel();
  }

  /// Pauses the underlying stream subscription.
  ///
  /// Events will be buffered until [resume] is called.
  void pause() => _subscription.pause();

  /// Resumes a previously paused subscription.
  void resume() => _subscription.resume();

  /// Whether the underlying subscription is currently paused.
  bool get isPaused => _subscription.isPaused;
}
