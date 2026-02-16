import 'package:flutter/material.dart';
import 'package:velox_buttons/src/velox_button.dart';
import 'package:velox_buttons/src/velox_button_style.dart';

/// A button that displays a loading indicator when in the loading state.
///
/// When [isLoading] is true, the button shows a [CircularProgressIndicator]
/// and is disabled to prevent multiple taps.
class VeloxLoadingButton extends StatelessWidget {
  /// Creates a [VeloxLoadingButton].
  const VeloxLoadingButton({
    required this.label,
    required this.isLoading,
    super.key,
    this.onPressed,
    this.size = VeloxButtonSize.medium,
    this.variant = VeloxButtonVariant.filled,
    this.icon,
    this.color,
  });

  /// The text label displayed on the button.
  final String label;

  /// Whether the button is in the loading state.
  final bool isLoading;

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// The size of the button.
  final VeloxButtonSize size;

  /// The visual variant of the button.
  final VeloxButtonVariant variant;

  /// An optional leading icon.
  final IconData? icon;

  /// An optional custom color for the button.
  final Color? color;

  @override
  Widget build(BuildContext context) => VeloxButton(
        label: label,
        onPressed: isLoading ? null : onPressed,
        size: size,
        variant: variant,
        isEnabled: !isLoading,
        color: color,
        icon: isLoading ? null : icon,
        child: isLoading
            ? SizedBox(
                width: size.height * 0.5,
                height: size.height * 0.5,
                child: const CircularProgressIndicator.adaptive(
                  strokeWidth: 2,
                ),
              )
            : null,
      );
}
