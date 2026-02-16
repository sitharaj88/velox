import 'dart:async';

/// A token that can be used to cancel an in-flight HTTP request.
///
/// Create a [CancellationToken] and pass it to a request method.
/// Call [cancel] to abort the request.
///
/// ```dart
/// final token = CancellationToken();
///
/// // Start the request
/// final future = client.get('/data', cancellationToken: token);
///
/// // Cancel it later
/// token.cancel('User navigated away');
///
/// // The future will complete with a failure
/// final result = await future;
/// ```
class CancellationToken {
  final Completer<void> _completer = Completer<void>();
  String? _reason;

  /// Whether this token has been cancelled.
  bool get isCancelled => _completer.isCompleted;

  /// The reason for cancellation, if any.
  String? get reason => _reason;

  /// A future that completes when this token is cancelled.
  Future<void> get whenCancelled => _completer.future;

  /// Cancels this token with an optional [reason].
  void cancel([String? reason]) {
    if (!_completer.isCompleted) {
      _reason = reason;
      _completer.complete();
    }
  }

  /// Throws a [CancelledException] if this token has been cancelled.
  void throwIfCancelled() {
    if (isCancelled) {
      throw CancelledException(reason: _reason);
    }
  }
}

/// Exception thrown when a request is cancelled via [CancellationToken].
class CancelledException implements Exception {
  /// Creates a [CancelledException].
  const CancelledException({this.reason});

  /// The reason for cancellation.
  final String? reason;

  @override
  String toString() => 'CancelledException: ${reason ?? 'Request cancelled'}';
}
