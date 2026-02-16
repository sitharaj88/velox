import 'package:flutter/material.dart';
import 'package:velox_theme/src/velox_theme_config.dart';
import 'package:velox_theme/src/velox_theme_data.dart';
import 'package:velox_theme/src/velox_theme_mode.dart';

/// Signature for the builder function used by [VeloxThemeBuilder].
typedef VeloxThemeWidgetBuilder = Widget Function(
  BuildContext context,
  ThemeData lightTheme,
  ThemeData darkTheme,
  VeloxThemeMode mode,
);

/// A widget that provides reactive theme switching.
///
/// Generates light and dark themes from a [VeloxThemeConfig] and
/// rebuilds when the theme mode changes.
class VeloxThemeBuilder extends StatefulWidget {
  /// Creates a [VeloxThemeBuilder].
  const VeloxThemeBuilder({
    required this.config,
    required this.builder,
    this.initialMode = VeloxThemeMode.system,
    super.key,
  });

  /// The theme configuration.
  final VeloxThemeConfig config;

  /// Builds the widget tree with the generated themes.
  final VeloxThemeWidgetBuilder builder;

  /// The initial theme mode.
  final VeloxThemeMode initialMode;

  /// Returns the [VeloxThemeBuilderState] from the closest ancestor.
  static VeloxThemeBuilderState of(BuildContext context) {
    final state = context.findAncestorStateOfType<VeloxThemeBuilderState>();
    assert(state != null, 'No VeloxThemeBuilder found in the widget tree.');
    return state!;
  }

  /// Returns the [VeloxThemeBuilderState] from the closest ancestor,
  /// or null if none exists.
  static VeloxThemeBuilderState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<VeloxThemeBuilderState>();

  @override
  State<VeloxThemeBuilder> createState() => VeloxThemeBuilderState();
}

/// State for [VeloxThemeBuilder].
///
/// Exposes [setMode] and [toggleMode] for controlling the theme.
class VeloxThemeBuilderState extends State<VeloxThemeBuilder> {
  late VeloxThemeMode _mode;
  late ThemeData _lightTheme;
  late ThemeData _darkTheme;

  /// The current theme mode.
  VeloxThemeMode get mode => _mode;

  /// The generated light theme.
  ThemeData get lightTheme => _lightTheme;

  /// The generated dark theme.
  ThemeData get darkTheme => _darkTheme;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _generateThemes();
  }

  @override
  void didUpdateWidget(VeloxThemeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _generateThemes();
    }
  }

  void _generateThemes() {
    _lightTheme = VeloxThemeData.light(widget.config);
    _darkTheme = VeloxThemeData.dark(widget.config);
  }

  /// Sets the theme mode and rebuilds the widget tree.
  void setMode(VeloxThemeMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
  }

  /// Toggles between light and dark mode.
  ///
  /// If currently in system mode, switches to light.
  void toggleMode() {
    setState(() {
      _mode = switch (_mode) {
        VeloxThemeMode.light => VeloxThemeMode.dark,
        VeloxThemeMode.dark => VeloxThemeMode.light,
        VeloxThemeMode.system => VeloxThemeMode.light,
      };
    });
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _lightTheme, _darkTheme, _mode);
}
