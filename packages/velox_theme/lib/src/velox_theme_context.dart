import 'package:flutter/material.dart';
import 'package:velox_theme/src/velox_color_scheme.dart';
import 'package:velox_theme/src/velox_theme_builder.dart';

/// Extension on [BuildContext] for convenient theme access.
extension VeloxThemeContext on BuildContext {
  /// Returns the current [ThemeData].
  ThemeData get veloxTheme => Theme.of(this);

  /// Returns the current [ColorScheme].
  ColorScheme get veloxColorScheme => Theme.of(this).colorScheme;

  /// Returns the current [TextTheme].
  TextTheme get veloxTextTheme => Theme.of(this).textTheme;

  /// Returns the extended [VeloxColorScheme] if available.
  VeloxColorScheme? get veloxColors =>
      Theme.of(this).extension<VeloxColorSchemeExtension>()?.veloxColors;

  /// Returns the current brightness.
  Brightness get veloxBrightness => Theme.of(this).brightness;

  /// Whether the current theme is dark.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Returns the [VeloxThemeBuilderState] from the widget tree.
  VeloxThemeBuilderState? get veloxThemeBuilder =>
      VeloxThemeBuilder.maybeOf(this);
}
