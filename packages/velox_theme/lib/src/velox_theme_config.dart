import 'package:flutter/material.dart';
import 'package:velox_theme/src/velox_color_scheme.dart';
import 'package:velox_theme/src/velox_text_theme.dart';

/// Configuration for generating Velox themes.
///
/// Provides all the customization points for generating consistent
/// Material 3 themes with extended semantic colors.
class VeloxThemeConfig {
  /// Creates a [VeloxThemeConfig].
  const VeloxThemeConfig({
    required this.seedColor,
    this.fontFamily,
    this.textTheme = const VeloxTextTheme(),
    this.lightColors,
    this.darkColors,
    this.useMaterial3 = true,
    this.borderRadius = 12.0,
    this.elevation = 1.0,
  });

  /// The seed color used to generate the Material 3 color scheme.
  final Color seedColor;

  /// The font family. Overrides [textTheme]'s fontFamily if set.
  final String? fontFamily;

  /// The text theme configuration.
  final VeloxTextTheme textTheme;

  /// Custom light semantic colors. Uses defaults if null.
  final VeloxColorScheme? lightColors;

  /// Custom dark semantic colors. Uses defaults if null.
  final VeloxColorScheme? darkColors;

  /// Whether to use Material 3. Defaults to true.
  final bool useMaterial3;

  /// Default border radius for components. Defaults to 12.0.
  final double borderRadius;

  /// Default elevation for components. Defaults to 1.0.
  final double elevation;

  /// The effective text theme, considering [fontFamily] override.
  VeloxTextTheme get effectiveTextTheme =>
      fontFamily != null ? textTheme.copyWith(fontFamily: fontFamily) : textTheme;

  /// Creates a copy with the given fields replaced.
  VeloxThemeConfig copyWith({
    Color? seedColor,
    String? fontFamily,
    VeloxTextTheme? textTheme,
    VeloxColorScheme? lightColors,
    VeloxColorScheme? darkColors,
    bool? useMaterial3,
    double? borderRadius,
    double? elevation,
  }) =>
      VeloxThemeConfig(
        seedColor: seedColor ?? this.seedColor,
        fontFamily: fontFamily ?? this.fontFamily,
        textTheme: textTheme ?? this.textTheme,
        lightColors: lightColors ?? this.lightColors,
        darkColors: darkColors ?? this.darkColors,
        useMaterial3: useMaterial3 ?? this.useMaterial3,
        borderRadius: borderRadius ?? this.borderRadius,
        elevation: elevation ?? this.elevation,
      );
}
