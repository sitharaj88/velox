import 'package:meta/meta.dart';

/// Represents the state of an asynchronous operation.
///
/// [AsyncValue] is a sealed class hierarchy with three variants:
/// - [AsyncLoading]: the operation is in progress
/// - [AsyncData]: the operation completed successfully with a value
/// - [AsyncError]: the operation completed with an error
///
/// Use pattern matching to handle all cases:
///
/// ```dart
/// switch (asyncValue) {
///   case AsyncLoading():
///     return CircularProgressIndicator();
///   case AsyncData(:final data):
///     return Text('$data');
///   case AsyncError(:final error):
///     return Text('Error: $error');
/// }
/// ```
sealed class AsyncValue<T> {
  /// Creates an [AsyncValue].
  const AsyncValue();

  /// Folds this [AsyncValue] into a single value by calling the matching
  /// callback.
  R when<R>({
    required R Function() loading,
    required R Function(T data) onData,
    required R Function(Object error, StackTrace? stackTrace) onError,
  }) => switch (this) {
    AsyncLoading<T>() => loading(),
    AsyncData<T>(:final data) => onData(data),
    AsyncError<T>(:final error, :final stackTrace) => onError(
      error,
      stackTrace,
    ),
  };

  /// Like [when] but with optional callbacks. Returns `null` for unhandled
  /// cases.
  R? whenOrNull<R>({
    R Function()? loading,
    R Function(T data)? onData,
    R Function(Object error, StackTrace? stackTrace)? onError,
  }) => switch (this) {
    AsyncLoading<T>() => loading?.call(),
    AsyncData<T>(:final data) => onData?.call(data),
    AsyncError<T>(:final error, :final stackTrace) => onError?.call(
      error,
      stackTrace,
    ),
  };

  /// Maps the data value to a new type while preserving loading/error states.
  AsyncValue<R> map<R>(R Function(T data) transform) => switch (this) {
    AsyncLoading<T>() => AsyncLoading<R>(),
    AsyncData<T>(:final data) => AsyncData<R>(transform(data)),
    AsyncError<T>(:final error, :final stackTrace) => AsyncError<R>(
      error,
      stackTrace,
    ),
  };
}

/// The asynchronous operation is in progress.
@immutable
class AsyncLoading<T> extends AsyncValue<T> {
  /// Creates an [AsyncLoading].
  const AsyncLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AsyncLoading<T>;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AsyncLoading<$T>()';
}

/// The asynchronous operation completed successfully with [data].
@immutable
class AsyncData<T> extends AsyncValue<T> {
  /// Creates an [AsyncData] with the given [data].
  const AsyncData(this.data);

  /// The data value produced by the successful operation.
  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AsyncData<T> && other.data == data);

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'AsyncData<$T>($data)';
}

/// The asynchronous operation completed with an [error].
@immutable
class AsyncError<T> extends AsyncValue<T> {
  /// Creates an [AsyncError] with the given [error] and optional [stackTrace].
  const AsyncError(this.error, [this.stackTrace]);

  /// The error that caused the operation to fail.
  final Object error;

  /// The stack trace associated with the [error], if available.
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsyncError<T> && other.error == error);

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'AsyncError<$T>($error)';
}
