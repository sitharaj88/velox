import 'package:flutter/material.dart';
import 'package:velox_buttons/src/velox_button_style.dart';

/// A versatile button widget that supports multiple variants and sizes.
///
/// [VeloxButton] maps each [VeloxButtonVariant] to the appropriate
/// Material button type, and applies sizing via [VeloxButtonSize].
class VeloxButton extends StatelessWidget {
  /// Creates a [VeloxButton].
  const VeloxButton({
    required this.label,
    super.key,
    this.onPressed,
    this.size = VeloxButtonSize.medium,
    this.variant = VeloxButtonVariant.filled,
    this.icon,
    this.isEnabled = true,
    this.color,
    this.child,
  });

  /// The text label displayed on the button.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// The size of the button.
  final VeloxButtonSize size;

  /// The visual variant of the button.
  final VeloxButtonVariant variant;

  /// An optional leading icon.
  final IconData? icon;

  /// Whether the button is enabled.
  final bool isEnabled;

  /// An optional custom color for the button.
  final Color? color;

  /// An optional child widget that replaces the default label text.
  final Widget? child;

  VoidCallback? get _effectiveOnPressed => isEnabled ? onPressed : null;

  ButtonStyle _buildStyle(BuildContext context) => ButtonStyle(
        padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(size.padding),
        minimumSize: WidgetStatePropertyAll<Size>(Size(0, size.height)),
        textStyle: WidgetStatePropertyAll<TextStyle>(size.textStyle(context)),
        foregroundColor: color != null && variant == VeloxButtonVariant.filled
            ? const WidgetStatePropertyAll<Color>(Colors.white)
            : color != null
                ? WidgetStatePropertyAll<Color>(color!)
                : null,
        backgroundColor: color != null && variant == VeloxButtonVariant.filled
            ? WidgetStatePropertyAll<Color>(color!)
            : null,
        side: color != null && variant == VeloxButtonVariant.outlined
            ? WidgetStatePropertyAll<BorderSide>(BorderSide(color: color!))
            : null,
      );

  @override
  Widget build(BuildContext context) {
    final style = _buildStyle(context);
    final content = child ?? Text(label);

    return switch (variant) {
      VeloxButtonVariant.filled => icon != null
          ? FilledButton.icon(
              onPressed: _effectiveOnPressed,
              icon: Icon(icon),
              label: content,
              style: style,
            )
          : FilledButton(
              onPressed: _effectiveOnPressed,
              style: style,
              child: content,
            ),
      VeloxButtonVariant.outlined => icon != null
          ? OutlinedButton.icon(
              onPressed: _effectiveOnPressed,
              icon: Icon(icon),
              label: content,
              style: style,
            )
          : OutlinedButton(
              onPressed: _effectiveOnPressed,
              style: style,
              child: content,
            ),
      VeloxButtonVariant.text => icon != null
          ? TextButton.icon(
              onPressed: _effectiveOnPressed,
              icon: Icon(icon),
              label: content,
              style: style,
            )
          : TextButton(
              onPressed: _effectiveOnPressed,
              style: style,
              child: content,
            ),
      VeloxButtonVariant.tonal => icon != null
          ? FilledButton.tonalIcon(
              onPressed: _effectiveOnPressed,
              icon: Icon(icon),
              label: content,
              style: style,
            )
          : FilledButton.tonal(
              onPressed: _effectiveOnPressed,
              style: style,
              child: content,
            ),
    };
  }
}
