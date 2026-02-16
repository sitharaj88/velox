import 'package:flutter/material.dart';

/// Defines the size of a Velox button.
enum VeloxButtonSize {
  /// A small button with reduced padding and text size.
  small,

  /// A medium button with default padding and text size.
  medium,

  /// A large button with increased padding and text size.
  large;

  /// The height for this button size.
  double get height => switch (this) {
        VeloxButtonSize.small => 32,
        VeloxButtonSize.medium => 40,
        VeloxButtonSize.large => 48,
      };

  /// The horizontal padding for this button size.
  EdgeInsetsGeometry get padding => switch (this) {
        VeloxButtonSize.small =>
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        VeloxButtonSize.medium =>
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        VeloxButtonSize.large =>
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      };

  /// The text style for this button size.
  TextStyle textStyle(BuildContext context) => switch (this) {
        VeloxButtonSize.small =>
          Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
        VeloxButtonSize.medium =>
          Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
        VeloxButtonSize.large =>
          Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
      };
}

/// Defines the visual variant of a Velox button.
enum VeloxButtonVariant {
  /// A filled button with a solid background color.
  filled,

  /// An outlined button with a border and transparent background.
  outlined,

  /// A text button with no background or border.
  text,

  /// A tonal button with a muted background color.
  tonal,
}
