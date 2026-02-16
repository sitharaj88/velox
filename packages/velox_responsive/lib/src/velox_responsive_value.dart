import 'package:velox_responsive/src/velox_breakpoint.dart';

/// Holds per-breakpoint values with automatic fallback to smaller breakpoints.
///
/// Only [mobile] is required. If a larger breakpoint value is not provided,
/// it falls back to the next smaller breakpoint value.
///
/// ```dart
/// final columns = VeloxResponsiveValue<int>(
///   mobile: 1,
///   tablet: 2,
///   desktop: 3,
///   wide: 4,
/// );
///
/// columns.resolve(VeloxBreakpoint.tablet); // 2
/// columns.resolve(VeloxBreakpoint.wide);   // 4
/// ```
class VeloxResponsiveValue<T> {
  /// Creates a [VeloxResponsiveValue] with per-breakpoint values.
  ///
  /// [mobile] is required; larger breakpoints fall back to the next
  /// smaller defined value when null.
  const VeloxResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
  });

  /// The value for the mobile breakpoint.
  final T mobile;

  /// The value for the tablet breakpoint, or null to fall back to [mobile].
  final T? tablet;

  /// The value for the desktop breakpoint, or null to fall back to [tablet].
  final T? desktop;

  /// The value for the wide breakpoint, or null to fall back to [desktop].
  final T? wide;

  /// Resolves the value for the given [breakpoint].
  ///
  /// Falls back to the next smaller breakpoint value when the requested
  /// breakpoint value is null.
  T resolve(VeloxBreakpoint breakpoint) => switch (breakpoint) {
        VeloxBreakpoint.wide => wide ?? desktop ?? tablet ?? mobile,
        VeloxBreakpoint.desktop => desktop ?? tablet ?? mobile,
        VeloxBreakpoint.tablet => tablet ?? mobile,
        VeloxBreakpoint.mobile => mobile,
      };
}
