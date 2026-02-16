import 'package:meta/meta.dart';

/// A type-safe way to handle success and failure without exceptions.
///
/// [Result] is a sealed class with two variants:
/// - [Success] containing a value of type [T]
/// - [Failure] containing an error of type [E]
///
/// ```dart
/// Result<User, VeloxException> fetchUser(int id) {
///   try {
///     final user = api.getUser(id);
///     return Success(user);
///   } catch (e) {
///     return Failure(VeloxException(message: e.toString()));
///   }
/// }
///
/// final result = fetchUser(1);
/// result.when(
///   success: (user) => print(user.name),
///   failure: (error) => print(error.message),
/// );
/// ```
sealed class Result<T, E> {
  /// Creates a [Result].
  const Result();

  /// Creates a successful result.
  const factory Result.success(T value) = Success<T, E>;

  /// Creates a failure result.
  const factory Result.failure(E error) = Failure<T, E>;

  /// Returns `true` if this is a [Success].
  bool get isSuccess => this is Success<T, E>;

  /// Returns `true` if this is a [Failure].
  bool get isFailure => this is Failure<T, E>;

  /// Returns the success value or `null`.
  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failure() => null,
  };

  /// Returns the error or `null`.
  E? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };

  /// Returns the success value or throws the error.
  ///
  /// The error type [E] must be a subtype of [Object] for throwing.
  T get valueOrThrow => switch (this) {
    Success(:final value) => value,
    // ignore: only_throw_errors
    Failure(:final error) => throw error as Object,
  };

  /// Pattern matches on the result.
  ///
  /// Both [success] and [failure] must be provided.
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) => switch (this) {
    Success(:final value) => success(value),
    Failure(:final error) => failure(error),
  };

  /// Pattern matches with optional handlers.
  ///
  /// Returns [orElse] if the matching handler is not provided.
  R maybeWhen<R>({
    required R Function() orElse,
    R Function(T value)? success,
    R Function(E error)? failure,
  }) => switch (this) {
    Success(:final value) => success != null ? success(value) : orElse(),
    Failure(:final error) => failure != null ? failure(error) : orElse(),
  };

  /// Transforms the success value.
  Result<R, E> map<R>(R Function(T value) transform) => switch (this) {
    Success(:final value) => Success(transform(value)),
    Failure(:final error) => Failure(error),
  };

  /// Transforms the error value.
  Result<T, R> mapError<R>(R Function(E error) transform) => switch (this) {
    Success(:final value) => Success(value),
    Failure(:final error) => Failure(transform(error)),
  };

  /// Chains a computation that returns a [Result].
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) transform) =>
      switch (this) {
        Success(:final value) => transform(value),
        Failure(:final error) => Failure(error),
      };

  /// Returns the success value or a default.
  T getOrElse(T Function() defaultValue) => switch (this) {
    Success(:final value) => value,
    Failure() => defaultValue(),
  };

  /// Returns the success value or a default value.
  T getOrDefault(T defaultValue) => switch (this) {
    Success(:final value) => value,
    Failure() => defaultValue,
  };
}

/// A successful result containing a [value].
@immutable
final class Success<T, E> extends Result<T, E> {
  /// Creates a successful result with the given [value].
  const Success(this.value);

  /// The success value.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, E> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// A failed result containing an [error].
@immutable
final class Failure<T, E> extends Result<T, E> {
  /// Creates a failure result with the given [error].
  const Failure(this.error);

  /// The error value.
  final E error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T, E> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}

/// Extension to convert futures to [Result].
extension FutureResultExtension<T> on Future<T> {
  /// Wraps this future in a [Result], catching any exceptions.
  Future<Result<T, Exception>> toResult() async {
    try {
      return Success(await this);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
