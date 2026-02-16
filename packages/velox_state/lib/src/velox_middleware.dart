import 'package:velox_state/src/velox_notifier.dart';

/// Intercepts state changes on a [VeloxNotifier] before they are applied.
///
/// A [VeloxMiddleware] can inspect, modify, or reject a state transition.
/// Middleware instances are chained together; each middleware calls [next] to
/// pass the (potentially modified) state to the next middleware in the chain.
/// If a middleware does not call [next], the state change is rejected.
///
/// ```dart
/// class LoggingMiddleware<T> extends VeloxMiddleware<T> {
///   @override
///   T? handle(T currentState, T newState, T Function(T) next) {
///     print('State changing from $currentState to $newState');
///     return next(newState);
///   }
/// }
/// ```
abstract class VeloxMiddleware<T> {
  /// Creates a [VeloxMiddleware].
  const VeloxMiddleware();

  /// Called when a state change is requested on the notifier.
  ///
  /// - [currentState] is the current state of the notifier.
  /// - [newState] is the proposed new state.
  /// - [next] passes the state to the next middleware (or applies it).
  ///
  /// Return the result of calling [next] to allow the change, or return
  /// `null` to reject it. You may also pass a modified value to [next].
  T? handle(T currentState, T newState, T Function(T) next);
}

/// A [VeloxNotifier] that supports a chain of [VeloxMiddleware] interceptors.
///
/// Middleware is executed in order for every call to [setState] or [update].
/// Each middleware can modify or reject the proposed state.
///
/// ```dart
/// final notifier = VeloxMiddlewareNotifier<int>(
///   0,
///   middleware: [ClampMiddleware(0, 100)],
/// );
/// ```
class VeloxMiddlewareNotifier<T> extends VeloxNotifier<T> {
  /// Creates a [VeloxMiddlewareNotifier] with the given [initialState] and
  /// optional list of [middleware].
  VeloxMiddlewareNotifier(
    super.initialState, {
    List<VeloxMiddleware<T>> middleware = const [],
  }) : _middleware = List.of(middleware);

  final List<VeloxMiddleware<T>> _middleware;

  /// The current middleware chain (read-only copy).
  List<VeloxMiddleware<T>> get middleware => List.unmodifiable(_middleware);

  /// Adds a [middleware] to the end of the chain.
  void addMiddleware(VeloxMiddleware<T> middleware) {
    _middleware.add(middleware);
  }

  /// Removes a [middleware] from the chain.
  void removeMiddleware(VeloxMiddleware<T> middleware) {
    _middleware.remove(middleware);
  }

  @override
  void setState(T newState) {
    final result = _runMiddleware(state, newState);
    if (result != null) {
      super.setState(result);
    }
  }

  @override
  void update(T Function(T current) updater) {
    final proposed = updater(state);
    final result = _runMiddleware(state, proposed);
    if (result != null) {
      super.setState(result);
    }
  }

  T? _runMiddleware(T currentState, T newState) {
    if (_middleware.isEmpty) {
      return newState;
    }

    // Build the chain from the inside out. The innermost function simply
    // returns the state (identity). Each middleware wraps the next.
    T? Function(T) chain = (state) => state;

    for (var i = _middleware.length - 1; i >= 0; i--) {
      final middleware = _middleware[i];
      final nextInChain = chain;
      chain = (state) {
        final result = middleware.handle(currentState, state, (s) => s);
        if (result == null) return null;
        return nextInChain(result);
      };
    }

    return chain(newState);
  }
}
