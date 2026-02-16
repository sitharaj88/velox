import 'package:flutter/widgets.dart';
import 'package:velox_responsive/src/velox_breakpoint.dart';

/// Extension on [BuildContext] providing responsive screen information.
///
/// Uses [MediaQuery.sizeOf] to read the screen dimensions and derives
/// the current [VeloxBreakpoint].
///
/// ```dart
/// if (context.isMobile) {
///   // show mobile layout
/// }
/// ```
extension VeloxScreenInfo on BuildContext {
  /// The current screen width in logical pixels.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// The current screen height in logical pixels.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// The current [VeloxBreakpoint] based on screen width.
  VeloxBreakpoint get breakpoint =>
      VeloxBreakpoint.fromWidth(MediaQuery.sizeOf(this).width);

  /// Whether the current breakpoint is [VeloxBreakpoint.mobile].
  bool get isMobile => breakpoint == VeloxBreakpoint.mobile;

  /// Whether the current breakpoint is [VeloxBreakpoint.tablet].
  bool get isTablet => breakpoint == VeloxBreakpoint.tablet;

  /// Whether the current breakpoint is [VeloxBreakpoint.desktop].
  bool get isDesktop => breakpoint == VeloxBreakpoint.desktop;

  /// Whether the current breakpoint is [VeloxBreakpoint.wide].
  bool get isWide => breakpoint == VeloxBreakpoint.wide;
}
