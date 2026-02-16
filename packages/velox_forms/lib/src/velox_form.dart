import 'package:flutter/widgets.dart';
import 'package:velox_forms/src/velox_form_controller.dart';

/// An inherited widget that provides a [VeloxFormController] to its
/// descendants.
class _VeloxFormScope extends InheritedWidget {
  const _VeloxFormScope({
    required this.controller,
    required super.child,
  });

  final VeloxFormController controller;

  @override
  bool updateShouldNotify(_VeloxFormScope oldWidget) =>
      controller != oldWidget.controller;
}

/// A declarative form widget that provides a [VeloxFormController] to its
/// descendants via [VeloxForm.of].
class VeloxForm extends StatefulWidget {
  /// Creates a [VeloxForm] with the given [controller] and [child].
  const VeloxForm({
    required this.controller,
    required this.child,
    this.onSubmit,
    this.autovalidate = false,
    super.key,
  });

  /// The controller that manages the form state and validation.
  final VeloxFormController controller;

  /// The widget tree below this form.
  final Widget child;

  /// An optional callback invoked when the form is submitted.
  final VoidCallback? onSubmit;

  /// Whether to automatically validate fields as they change.
  final bool autovalidate;

  /// Retrieves the nearest [VeloxFormController] from the widget tree.
  ///
  /// Returns `null` if no [VeloxForm] ancestor exists.
  static VeloxFormController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_VeloxFormScope>()
      ?.controller;

  @override
  State<VeloxForm> createState() => _VeloxFormState();
}

class _VeloxFormState extends State<VeloxForm> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(VeloxForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => _VeloxFormScope(
        controller: widget.controller,
        child: widget.child,
      );
}
