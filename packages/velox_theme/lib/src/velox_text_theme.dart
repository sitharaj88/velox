import 'package:flutter/material.dart';

/// Configuration for the Velox text theme system.
///
/// Generates Material 3 [TextTheme] with optional custom font family
/// and scale factor for responsive typography.
class VeloxTextTheme {
  /// Creates a [VeloxTextTheme] configuration.
  const VeloxTextTheme({
    this.fontFamily,
    this.scaleFactor = 1.0,
    this.letterSpacingFactor = 1.0,
  });

  /// The font family to use. If null, defaults to the platform font.
  final String? fontFamily;

  /// Scale factor applied to all font sizes. Defaults to 1.0.
  final double scaleFactor;

  /// Scale factor applied to letter spacing. Defaults to 1.0.
  final double letterSpacingFactor;

  /// Generates a Material 3 [TextTheme] with the configured settings.
  TextTheme toTextTheme({Color? color}) {
    final baseTheme = Typography.material2021().englishLike;
    return baseTheme.apply(
      fontFamily: fontFamily,
      fontSizeFactor: scaleFactor,
      bodyColor: color,
      displayColor: color,
    );
  }

  /// Creates a copy with the given fields replaced.
  VeloxTextTheme copyWith({
    String? fontFamily,
    double? scaleFactor,
    double? letterSpacingFactor,
  }) =>
      VeloxTextTheme(
        fontFamily: fontFamily ?? this.fontFamily,
        scaleFactor: scaleFactor ?? this.scaleFactor,
        letterSpacingFactor: letterSpacingFactor ?? this.letterSpacingFactor,
      );
}
