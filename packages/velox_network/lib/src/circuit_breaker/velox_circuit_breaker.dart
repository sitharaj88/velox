import 'dart:async';

/// The state of a circuit breaker.
enum CircuitBreakerState {
  /// Circuit is closed - requests flow normally.
  closed,

  /// Circuit is open - requests are rejected immediately.
  open,

  /// Circuit is half-open - a limited number of test requests are allowed.
  halfOpen,
}

/// A circuit breaker that prevents cascading failures by temporarily
/// blocking requests to a failing service.
///
/// The circuit breaker transitions between three states:
/// - **Closed**: Requests pass through. Failures are counted.
/// - **Open**: Requests are immediately rejected. After [recoveryTimeout],
///   transitions to half-open.
/// - **Half-Open**: A limited number of test requests are allowed. If they
///   succeed, the circuit closes. If they fail, it reopens.
///
/// ```dart
/// final breaker = VeloxCircuitBreaker(
///   failureThreshold: 5,
///   recoveryTimeout: Duration(seconds: 30),
///   onStateChange: (from, to) => print('$from -> $to'),
/// );
///
/// final result = await breaker.execute(() => httpClient.get('/api/data'));
/// ```
class VeloxCircuitBreaker {
  /// Creates a [VeloxCircuitBreaker].
  ///
  /// [failureThreshold] is the number of consecutive failures before opening
  /// the circuit. [recoveryTimeout] is how long to wait before attempting
  /// recovery (half-open state). [halfOpenMaxAttempts] is how many successful
  /// test requests are needed in half-open state to close the circuit.
  VeloxCircuitBreaker({
    required this.failureThreshold,
    required this.recoveryTimeout,
    this.halfOpenMaxAttempts = 1,
    this.onStateChange,
  });

  /// Number of consecutive failures before the circuit opens.
  final int failureThreshold;

  /// Duration to wait before transitioning from open to half-open.
  final Duration recoveryTimeout;

  /// Number of successful test requests needed in half-open state
  /// to close the circuit.
  final int halfOpenMaxAttempts;

  /// Callback invoked when the circuit state changes.
  final void Function(CircuitBreakerState from, CircuitBreakerState to)?
      onStateChange;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  int _halfOpenSuccessCount = 0;
  DateTime? _openedAt;

  /// The current state of the circuit breaker.
  CircuitBreakerState get state {
    _checkRecovery();
    return _state;
  }

  /// The current number of consecutive failures.
  int get failureCount => _failureCount;

  /// Whether the circuit breaker is allowing requests.
  bool get isAllowingRequests {
    _checkRecovery();
    return _state != CircuitBreakerState.open;
  }

  /// Executes [action] through the circuit breaker.
  ///
  /// If the circuit is open, throws a [CircuitBreakerOpenException]
  /// immediately without executing the action.
  Future<T> execute<T>(Future<T> Function() action) async {
    _checkRecovery();

    if (_state == CircuitBreakerState.open) {
      throw CircuitBreakerOpenException(
        message: 'Circuit breaker is open. '
            'Requests are blocked until recovery.',
        openedAt: _openedAt,
        recoveryTimeout: recoveryTimeout,
      );
    }

    try {
      final result = await action();
      _onSuccess();
      return result;
    } on Exception {
      _onFailure();
      rethrow;
    }
  }

  /// Manually resets the circuit breaker to the closed state.
  void reset() {
    final previous = _state;
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _halfOpenSuccessCount = 0;
    _openedAt = null;
    if (previous != CircuitBreakerState.closed) {
      onStateChange?.call(previous, CircuitBreakerState.closed);
    }
  }

  void _checkRecovery() {
    if (_state == CircuitBreakerState.open && _openedAt != null) {
      final elapsed = DateTime.now().difference(_openedAt!);
      if (elapsed >= recoveryTimeout) {
        _transitionTo(CircuitBreakerState.halfOpen);
        _halfOpenSuccessCount = 0;
      }
    }
  }

  void _onSuccess() {
    if (_state == CircuitBreakerState.halfOpen) {
      _halfOpenSuccessCount++;
      if (_halfOpenSuccessCount >= halfOpenMaxAttempts) {
        _transitionTo(CircuitBreakerState.closed);
        _failureCount = 0;
      }
    } else {
      _failureCount = 0;
    }
  }

  void _onFailure() {
    _failureCount++;

    if (_state == CircuitBreakerState.halfOpen) {
      _transitionTo(CircuitBreakerState.open);
      _openedAt = DateTime.now();
    } else if (_failureCount >= failureThreshold) {
      _transitionTo(CircuitBreakerState.open);
      _openedAt = DateTime.now();
    }
  }

  void _transitionTo(CircuitBreakerState newState) {
    if (_state != newState) {
      final previous = _state;
      _state = newState;
      onStateChange?.call(previous, newState);
    }
  }
}

/// Exception thrown when the circuit breaker is open and rejecting requests.
class CircuitBreakerOpenException implements Exception {
  /// Creates a [CircuitBreakerOpenException].
  const CircuitBreakerOpenException({
    required this.message,
    this.openedAt,
    this.recoveryTimeout,
  });

  /// Human-readable message.
  final String message;

  /// When the circuit was opened.
  final DateTime? openedAt;

  /// How long until recovery is attempted.
  final Duration? recoveryTimeout;

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}
