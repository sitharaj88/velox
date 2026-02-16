import 'dart:async';

import 'package:velox_state/src/async_value.dart';
import 'package:velox_state/src/velox_notifier.dart';

/// A [VeloxNotifier] specialised for asynchronous operations.
///
/// [VeloxAsyncNotifier] wraps an [AsyncValue] so that consumers can react to
/// loading, data and error states in a type-safe way.
///
/// ```dart
/// final users = VeloxAsyncNotifier<List<User>>();
///
/// users.guard(() async {
///   final result = await api.fetchUsers();
///   return result;
/// });
/// ```
class VeloxAsyncNotifier<T> extends VeloxNotifier<AsyncValue<T>> {
  /// Creates a [VeloxAsyncNotifier] in the loading state.
  VeloxAsyncNotifier() : super(const AsyncLoading());

  /// Creates a [VeloxAsyncNotifier] with an initial data value.
  VeloxAsyncNotifier.withData(T data) : super(AsyncData<T>(data));

  /// Convenience getter that returns `true` when the current state is loading.
  bool get isLoading => state is AsyncLoading<T>;

  /// Convenience getter that returns `true` when the current state has data.
  bool get hasData => state is AsyncData<T>;

  /// Convenience getter that returns `true` when the current state is an error.
  bool get hasError => state is AsyncError<T>;

  /// Returns the data value if available, otherwise `null`.
  T? get data => switch (state) {
    AsyncData<T>(:final data) => data,
    _ => null,
  };

  /// Returns the error if present, otherwise `null`.
  Object? get error => switch (state) {
    AsyncError<T>(:final error) => error,
    _ => null,
  };

  /// Sets the state to [AsyncData] with the given [data].
  void setData(T data) {
    setState(AsyncData<T>(data));
  }

  /// Sets the state to [AsyncError] with the given [error] and optional
  /// [stackTrace].
  void setError(Object error, [StackTrace? stackTrace]) {
    setState(AsyncError<T>(error, stackTrace));
  }

  /// Sets the state to [AsyncLoading].
  void setLoading() {
    setState(const AsyncLoading());
  }

  /// Executes [future] and transitions the state through loading -> data or
  /// loading -> error automatically.
  ///
  /// Returns the value on success or `null` on failure.
  Future<T?> guard(Future<T> Function() future) async {
    setState(const AsyncLoading());
    try {
      final value = await future();
      setState(AsyncData<T>(value));
      return value;
    } on Object catch (e, st) {
      setState(AsyncError<T>(e, st));
      return null;
    }
  }
}
