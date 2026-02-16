import 'package:flutter/foundation.dart';
import 'package:velox_forms/src/velox_field_state.dart';
import 'package:velox_forms/src/velox_validator.dart';

/// A controller that manages the state and validation of a form.
///
/// Extends [ChangeNotifier] so widgets can listen for state changes.
class VeloxFormController extends ChangeNotifier {
  final Map<String, VeloxFieldState<dynamic>> _fields =
      <String, VeloxFieldState<dynamic>>{};
  final Map<String, List<VeloxValidator<dynamic>>> _validators =
      <String, List<VeloxValidator<dynamic>>>{};
  final Map<String, dynamic> _initialValues = <String, dynamic>{};

  /// Registers a field with the given [name], optional [initialValue],
  /// and optional list of [validators].
  void registerField<T>(
    String name, {
    T? initialValue,
    List<VeloxValidator<T>>? validators,
  }) {
    if (_fields.containsKey(name)) return;
    _fields[name] = VeloxFieldState<T>(value: initialValue);
    _initialValues[name] = initialValue;
    if (validators != null) {
      _validators[name] = <VeloxValidator<dynamic>>[
        for (final v in validators) (dynamic value) => v(value as T?),
      ];
    }
  }

  /// Returns the [VeloxFieldState] for the field with the given [name],
  /// or `null` if no such field is registered.
  VeloxFieldState<T>? getField<T>(String name) {
    final field = _fields[name];
    if (field == null) return null;
    return VeloxFieldState<T>(
      value: field.value as T?,
      errorText: field.errorText,
      isTouched: field.isTouched,
      isValidating: field.isValidating,
    );
  }

  /// Sets the value of the field with the given [name] and runs validation.
  void setFieldValue<T>(String name, T value) {
    final field = _fields[name];
    if (field == null) return;

    final error = _runValidators(name, value);

    _fields[name] = VeloxFieldState<T>(
      value: value,
      errorText: error,
      isTouched: field.isTouched,
    );
    notifyListeners();
  }

  /// Marks the field with the given [name] as touched.
  void touchField(String name) {
    final field = _fields[name];
    if (field == null) return;
    _fields[name] = VeloxFieldState<dynamic>(
      value: field.value,
      errorText: field.errorText,
      isTouched: true,
      isValidating: field.isValidating,
    );
    notifyListeners();
  }

  /// Validates all registered fields and returns `true` if every field
  /// is valid.
  bool validate() {
    var allValid = true;
    for (final entry in _fields.entries) {
      final name = entry.key;
      final field = entry.value;
      final error = _runValidators(name, field.value);

      _fields[name] = VeloxFieldState<dynamic>(
        value: field.value,
        errorText: error,
        isTouched: true,
      );

      if (error != null) {
        allValid = false;
      }
    }
    notifyListeners();
    return allValid;
  }

  /// Whether all registered fields are currently valid.
  bool get isValid => _fields.values.every(
        (field) => field.isValid,
      );

  /// Returns a map of all field names to their current values.
  Map<String, dynamic> get values => <String, dynamic>{
        for (final entry in _fields.entries) entry.key: entry.value.value,
      };

  /// Resets all fields to their initial values and clears errors.
  void reset() {
    for (final entry in _fields.entries) {
      _fields[entry.key] = VeloxFieldState<dynamic>(
        value: _initialValues[entry.key],
      );
    }
    notifyListeners();
  }

  String? _runValidators(String name, dynamic value) {
    final fieldValidators = _validators[name];
    if (fieldValidators == null) return null;
    for (final validator in fieldValidators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }
}
