import 'package:flutter/material.dart';
import 'package:velox_buttons/src/velox_button_style.dart';

/// An enhanced icon button with optional badge support.
///
/// Wraps Flutter's [IconButton] with [VeloxButtonSize]-based sizing
/// and a [Badge] widget for notifications or counts.
class VeloxIconButton extends StatelessWidget {
  /// Creates a [VeloxIconButton].
  const VeloxIconButton({
    required this.icon,
    super.key,
    this.onPressed,
    this.tooltip,
    this.size = VeloxButtonSize.medium,
    this.variant = VeloxButtonVariant.filled,
    this.color,
    this.showBadge = false,
    this.badgeLabel,
  });

  /// The icon to display.
  final IconData icon;

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// An optional tooltip message.
  final String? tooltip;

  /// The size of the button.
  final VeloxButtonSize size;

  /// The visual variant of the button.
  final VeloxButtonVariant variant;

  /// An optional custom color.
  final Color? color;

  /// Whether to show a badge on the button.
  final bool showBadge;

  /// An optional label for the badge.
  final String? badgeLabel;

  double get _iconSize => switch (size) {
        VeloxButtonSize.small => 18,
        VeloxButtonSize.medium => 24,
        VeloxButtonSize.large => 30,
      };

  ButtonStyle get _style => switch (variant) {
        VeloxButtonVariant.filled => IconButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: color,
          ),
        VeloxButtonVariant.outlined => IconButton.styleFrom(
            foregroundColor: color,
            side: color != null ? BorderSide(color: color!) : null,
          ),
        VeloxButtonVariant.text => IconButton.styleFrom(
            foregroundColor: color,
          ),
        VeloxButtonVariant.tonal => IconButton.styleFrom(
            foregroundColor: color,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: _iconSize),
      tooltip: tooltip,
      style: _style,
      constraints: BoxConstraints(
        minWidth: size.height,
        minHeight: size.height,
      ),
    );

    if (!showBadge) {
      return button;
    }

    return Badge(
      label: badgeLabel != null ? Text(badgeLabel!) : null,
      child: button,
    );
  }
}
