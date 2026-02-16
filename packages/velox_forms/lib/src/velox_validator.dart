/// A synchronous validator function that returns an error message string
/// if the value is invalid, or `null` if it is valid.
typedef VeloxValidator<T> = String? Function(T? value);

/// An asynchronous validator function that returns a [Future] with an error
/// message string if the value is invalid, or `null` if it is valid.
typedef VeloxAsyncValidator<T> = Future<String?> Function(T? value);

/// A collection of common built-in validators.
abstract final class VeloxValidators {
  /// Returns a validator that checks whether a string value is non-null
  /// and non-empty.
  static VeloxValidator<String> required({String? message}) =>
      (value) => value == null || value.isEmpty
          ? (message ?? 'This field is required')
          : null;

  /// Returns a validator that checks whether a string value has at least
  /// [min] characters.
  static VeloxValidator<String> minLength(int min, {String? message}) =>
      (value) => value != null && value.length < min
          ? (message ?? 'Must be at least $min characters')
          : null;

  /// Returns a validator that checks whether a string value has at most
  /// [max] characters.
  static VeloxValidator<String> maxLength(int max, {String? message}) =>
      (value) => value != null && value.length > max
          ? (message ?? 'Must be at most $max characters')
          : null;

  /// Returns a validator that checks whether a string value is a valid
  /// email address.
  static VeloxValidator<String> email({String? message}) => (value) {
        if (value == null || value.isEmpty) return null;
        final regex = RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        );
        return regex.hasMatch(value)
            ? null
            : (message ?? 'Invalid email address');
      };

  /// Returns a validator that checks whether a string value matches the
  /// given [regex] pattern.
  static VeloxValidator<String> pattern(
    RegExp regex, {
    String? message,
  }) =>
      (value) {
        if (value == null || value.isEmpty) return null;
        return regex.hasMatch(value)
            ? null
            : (message ?? 'Invalid format');
      };

  /// Returns a validator that checks whether a string value matches the
  /// value returned by [other]. Useful for password confirmation fields.
  static VeloxValidator<String> match(
    String Function() other, {
    String? message,
  }) =>
      (value) =>
          value != other() ? (message ?? 'Values do not match') : null;

  /// Composes multiple validators into a single validator that runs all
  /// of them in order and returns the first error encountered.
  static VeloxValidator<T> compose<T>(List<VeloxValidator<T>> validators) =>
      (value) {
        for (final validator in validators) {
          final error = validator(value);
          if (error != null) return error;
        }
        return null;
      };
}
