import 'package:flutter/material.dart';

/// Extended color scheme with semantic colors beyond Material 3 defaults.
///
/// Provides additional tokens for success, warning, and info states
/// that are commonly needed but not included in Material's [ColorScheme].
class VeloxColorScheme {
  /// Creates a [VeloxColorScheme] with the given semantic colors.
  const VeloxColorScheme({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  /// Creates a light [VeloxColorScheme] with default semantic colors.
  factory VeloxColorScheme.light() => const VeloxColorScheme(
        success: Color(0xFF2E7D32),
        onSuccess: Colors.white,
        successContainer: Color(0xFFC8E6C9),
        onSuccessContainer: Color(0xFF1B5E20),
        warning: Color(0xFFF57F17),
        onWarning: Colors.white,
        warningContainer: Color(0xFFFFF9C4),
        onWarningContainer: Color(0xFFE65100),
        info: Color(0xFF0288D1),
        onInfo: Colors.white,
        infoContainer: Color(0xFFB3E5FC),
        onInfoContainer: Color(0xFF01579B),
      );

  /// Creates a dark [VeloxColorScheme] with default semantic colors.
  factory VeloxColorScheme.dark() => const VeloxColorScheme(
        success: Color(0xFF66BB6A),
        onSuccess: Color(0xFF1B5E20),
        successContainer: Color(0xFF2E7D32),
        onSuccessContainer: Color(0xFFC8E6C9),
        warning: Color(0xFFFFCA28),
        onWarning: Color(0xFF3E2723),
        warningContainer: Color(0xFFF57F17),
        onWarningContainer: Color(0xFFFFF9C4),
        info: Color(0xFF4FC3F7),
        onInfo: Color(0xFF01579B),
        infoContainer: Color(0xFF0288D1),
        onInfoContainer: Color(0xFFB3E5FC),
      );

  /// The success color.
  final Color success;

  /// The color used for content on top of [success].
  final Color onSuccess;

  /// A lighter variant of [success] for containers.
  final Color successContainer;

  /// The color used for content on top of [successContainer].
  final Color onSuccessContainer;

  /// The warning color.
  final Color warning;

  /// The color used for content on top of [warning].
  final Color onWarning;

  /// A lighter variant of [warning] for containers.
  final Color warningContainer;

  /// The color used for content on top of [warningContainer].
  final Color onWarningContainer;

  /// The info/informational color.
  final Color info;

  /// The color used for content on top of [info].
  final Color onInfo;

  /// A lighter variant of [info] for containers.
  final Color infoContainer;

  /// The color used for content on top of [infoContainer].
  final Color onInfoContainer;

  /// Creates a copy with the given fields replaced.
  VeloxColorScheme copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
  }) =>
      VeloxColorScheme(
        success: success ?? this.success,
        onSuccess: onSuccess ?? this.onSuccess,
        successContainer: successContainer ?? this.successContainer,
        onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
        warning: warning ?? this.warning,
        onWarning: onWarning ?? this.onWarning,
        warningContainer: warningContainer ?? this.warningContainer,
        onWarningContainer: onWarningContainer ?? this.onWarningContainer,
        info: info ?? this.info,
        onInfo: onInfo ?? this.onInfo,
        infoContainer: infoContainer ?? this.infoContainer,
        onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      );

  /// Linearly interpolates between two [VeloxColorScheme]s.
  // ignore: prefer_constructors_over_static_methods
  static VeloxColorScheme lerp(
    VeloxColorScheme a,
    VeloxColorScheme b,
    double t,
  ) =>
      VeloxColorScheme(
        success: Color.lerp(a.success, b.success, t)!,
        onSuccess: Color.lerp(a.onSuccess, b.onSuccess, t)!,
        successContainer:
            Color.lerp(a.successContainer, b.successContainer, t)!,
        onSuccessContainer:
            Color.lerp(a.onSuccessContainer, b.onSuccessContainer, t)!,
        warning: Color.lerp(a.warning, b.warning, t)!,
        onWarning: Color.lerp(a.onWarning, b.onWarning, t)!,
        warningContainer:
            Color.lerp(a.warningContainer, b.warningContainer, t)!,
        onWarningContainer:
            Color.lerp(a.onWarningContainer, b.onWarningContainer, t)!,
        info: Color.lerp(a.info, b.info, t)!,
        onInfo: Color.lerp(a.onInfo, b.onInfo, t)!,
        infoContainer: Color.lerp(a.infoContainer, b.infoContainer, t)!,
        onInfoContainer:
            Color.lerp(a.onInfoContainer, b.onInfoContainer, t)!,
      );
}

/// A [ThemeExtension] that provides [VeloxColorScheme] through the theme.
class VeloxColorSchemeExtension
    extends ThemeExtension<VeloxColorSchemeExtension> {
  /// Creates a [VeloxColorSchemeExtension].
  const VeloxColorSchemeExtension({required this.veloxColors});

  /// The extended color scheme.
  final VeloxColorScheme veloxColors;

  @override
  VeloxColorSchemeExtension copyWith({VeloxColorScheme? veloxColors}) =>
      VeloxColorSchemeExtension(
        veloxColors: veloxColors ?? this.veloxColors,
      );

  @override
  ThemeExtension<VeloxColorSchemeExtension> lerp(
    covariant ThemeExtension<VeloxColorSchemeExtension>? other,
    double t,
  ) {
    if (other is! VeloxColorSchemeExtension) return this;
    return VeloxColorSchemeExtension(
      veloxColors: VeloxColorScheme.lerp(veloxColors, other.veloxColors, t),
    );
  }
}
