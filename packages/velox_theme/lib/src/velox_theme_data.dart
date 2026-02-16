import 'package:flutter/material.dart';
import 'package:velox_theme/src/velox_color_scheme.dart';
import 'package:velox_theme/src/velox_theme_config.dart';

/// Generates Material 3 [ThemeData] from a [VeloxThemeConfig].
abstract final class VeloxThemeData {
  /// Generates a light [ThemeData] from the given [config].
  static ThemeData light(VeloxThemeConfig config) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: config.seedColor,
    );
    final veloxColors = config.lightColors ?? VeloxColorScheme.light();
    final textTheme = config.effectiveTextTheme.toTextTheme();

    return ThemeData(
      useMaterial3: config.useMaterial3,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: [VeloxColorSchemeExtension(veloxColors: veloxColors)],
      cardTheme: CardThemeData(
        elevation: config.elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
        ),
      ),
    );
  }

  /// Generates a dark [ThemeData] from the given [config].
  static ThemeData dark(VeloxThemeConfig config) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: config.seedColor,
      brightness: Brightness.dark,
    );
    final veloxColors = config.darkColors ?? VeloxColorScheme.dark();
    final textTheme = config.effectiveTextTheme.toTextTheme();

    return ThemeData(
      useMaterial3: config.useMaterial3,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: [VeloxColorSchemeExtension(veloxColors: veloxColors)],
      cardTheme: CardThemeData(
        elevation: config.elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
        ),
      ),
    );
  }
}
