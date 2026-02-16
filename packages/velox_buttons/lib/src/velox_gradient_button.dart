import 'package:flutter/material.dart';
import 'package:velox_buttons/src/velox_button_style.dart';

/// A button with a gradient background.
///
/// Uses [DecoratedBox] with [Material] and [InkWell] for a custom
/// gradient appearance with ink splash effects.
class VeloxGradientButton extends StatelessWidget {
  /// Creates a [VeloxGradientButton].
  const VeloxGradientButton({
    required this.label,
    required this.gradient,
    super.key,
    this.onPressed,
    this.size = VeloxButtonSize.medium,
    this.textColor = Colors.white,
    this.borderRadius,
  });

  /// The text label displayed on the button.
  final String label;

  /// The gradient used for the button background.
  final Gradient gradient;

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// The size of the button.
  final VeloxButtonSize size;

  /// The color of the label text. Defaults to white.
  final Color textColor;

  /// The border radius of the button.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(8);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: effectiveRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: effectiveRadius,
          child: Padding(
            padding: size.padding.resolve(TextDirection.ltr),
            child: SizedBox(
              height: size.height -
                  size.padding.resolve(TextDirection.ltr).vertical,
              child: Center(
                child: Text(
                  label,
                  style: size.textStyle(context).copyWith(color: textColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
