/// Defines responsive breakpoints for different screen sizes.
///
/// Each breakpoint corresponds to a range of screen widths:
/// - [mobile]: 0 - 599 pixels
/// - [tablet]: 600 - 1023 pixels
/// - [desktop]: 1024 - 1439 pixels
/// - [wide]: 1440+ pixels
enum VeloxBreakpoint {
  /// Mobile breakpoint: 0 - 599 pixels.
  mobile,

  /// Tablet breakpoint: 600 - 1023 pixels.
  tablet,

  /// Desktop breakpoint: 1024 - 1439 pixels.
  desktop,

  /// Wide breakpoint: 1440+ pixels.
  wide;

  /// The minimum width for this breakpoint.
  double get minWidth => switch (this) {
        VeloxBreakpoint.mobile => 0,
        VeloxBreakpoint.tablet => 600,
        VeloxBreakpoint.desktop => 1024,
        VeloxBreakpoint.wide => 1440,
      };

  /// The maximum width for this breakpoint.
  ///
  /// Returns [double.infinity] for [wide] since it has no upper bound.
  double get maxWidth => switch (this) {
        VeloxBreakpoint.mobile => 599,
        VeloxBreakpoint.tablet => 1023,
        VeloxBreakpoint.desktop => 1439,
        VeloxBreakpoint.wide => double.infinity,
      };

  /// Returns the [VeloxBreakpoint] that matches the given [width].
  ///
  /// Defaults to [mobile] if [width] is negative.
  static VeloxBreakpoint fromWidth(double width) {
    if (width >= 1440) return VeloxBreakpoint.wide;
    if (width >= 1024) return VeloxBreakpoint.desktop;
    if (width >= 600) return VeloxBreakpoint.tablet;
    return VeloxBreakpoint.mobile;
  }
}
