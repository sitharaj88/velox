import 'package:flutter/material.dart';
import 'package:velox_forms/src/velox_form.dart';
import 'package:velox_forms/src/velox_form_controller.dart';
import 'package:velox_forms/src/velox_validator.dart';

/// A text field widget that automatically integrates with the nearest
/// [VeloxForm] controller.
class VeloxTextField extends StatefulWidget {
  /// Creates a [VeloxTextField] with the given [name].
  const VeloxTextField({
    required this.name,
    this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validators,
    this.prefix,
    this.suffix,
    super.key,
  });

  /// The name of the field within the form controller.
  final String name;

  /// An optional label to display above the text field.
  final String? label;

  /// An optional hint to display inside the text field.
  final String? hint;

  /// Whether to obscure the text (e.g. for passwords).
  final bool obscureText;

  /// The keyboard type to use for this text field.
  final TextInputType? keyboardType;

  /// The maximum number of lines for the text field.
  final int maxLines;

  /// An optional list of validators for this field.
  final List<VeloxValidator<String>>? validators;

  /// An optional widget to display before the text field.
  final Widget? prefix;

  /// An optional widget to display after the text field.
  final Widget? suffix;

  @override
  State<VeloxTextField> createState() => _VeloxTextFieldState();
}

class _VeloxTextFieldState extends State<VeloxTextField> {
  late TextEditingController _textController;
  VeloxFormController? _formController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = VeloxForm.of(context);
    if (controller != null && controller != _formController) {
      _formController?.removeListener(_onControllerChanged);
      _formController = controller;
      controller
        ..addListener(_onControllerChanged)
        ..registerField<String>(
          widget.name,
          validators: widget.validators,
        );
      final field = controller.getField<String>(widget.name);
      if (field?.value != null && field!.value != _textController.text) {
        _textController.text = field.value!;
      }
    }
  }

  @override
  void dispose() {
    _formController?.removeListener(_onControllerChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onChanged(String value) {
    _formController?.setFieldValue<String>(widget.name, value);
  }

  void _onFocusLost() {
    _formController?.touchField(widget.name);
  }

  @override
  Widget build(BuildContext context) {
    final fieldState = _formController?.getField<String>(widget.name);
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) _onFocusLost();
      },
      child: TextField(
        controller: _textController,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        onChanged: _onChanged,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          errorText: (fieldState?.hasError ?? false)
              ? fieldState?.errorText
              : null,
          prefixIcon: widget.prefix,
          suffixIcon: widget.suffix,
        ),
      ),
    );
  }
}
