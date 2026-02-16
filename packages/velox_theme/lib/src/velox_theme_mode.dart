import 'package:flutter/material.dart';

/// Represents the application theme mode.
enum VeloxThemeMode {
  /// Always use the light theme.
  light,

  /// Always use the dark theme.
  dark,

  /// Follow the system setting.
  system;

  /// Converts to Flutter's [ThemeMode].
  ThemeMode toThemeMode() => switch (this) {
        VeloxThemeMode.light => ThemeMode.light,
        VeloxThemeMode.dark => ThemeMode.dark,
        VeloxThemeMode.system => ThemeMode.system,
      };

  /// Creates from Flutter's [ThemeMode].
  static VeloxThemeMode fromThemeMode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => VeloxThemeMode.light,
        ThemeMode.dark => VeloxThemeMode.dark,
        ThemeMode.system => VeloxThemeMode.system,
      };
}
