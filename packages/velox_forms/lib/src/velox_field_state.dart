/// A model representing the state of a single form field.
class VeloxFieldState<T> {
  /// Creates a [VeloxFieldState] with the given properties.
  const VeloxFieldState({
    this.value,
    this.errorText,
    this.isTouched = false,
    this.isValidating = false,
  });

  /// The current value of the field.
  final T? value;

  /// The current validation error message, or `null` if the field is valid.
  final String? errorText;

  /// Whether the user has interacted with this field.
  final bool isTouched;

  /// Whether the field is currently being validated asynchronously.
  final bool isValidating;

  /// Whether the field is valid (has no error).
  bool get isValid => errorText == null;

  /// Whether the field has an error and has been touched by the user.
  bool get hasError => errorText != null && isTouched;

  /// Returns a copy of this field state with the given fields replaced.
  VeloxFieldState<T> copyWith({
    T? value,
    String? errorText,
    bool? clearError,
    bool? isTouched,
    bool? isValidating,
  }) =>
      VeloxFieldState<T>(
        value: value ?? this.value,
        errorText:
            (clearError ?? false) ? null : (errorText ?? this.errorText),
        isTouched: isTouched ?? this.isTouched,
        isValidating: isValidating ?? this.isValidating,
      );
}
