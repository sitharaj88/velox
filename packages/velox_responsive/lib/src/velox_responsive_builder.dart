import 'package:flutter/widgets.dart';
import 'package:velox_responsive/src/velox_breakpoint.dart';

/// Signature for the builder function used by [VeloxResponsiveBuilder].
typedef VeloxResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  VeloxBreakpoint breakpoint,
  BoxConstraints constraints,
);

/// A widget that rebuilds based on the current responsive breakpoint.
///
/// Uses [LayoutBuilder] internally to determine the available width,
/// then resolves the corresponding [VeloxBreakpoint] and passes it
/// to the [builder] function.
///
/// ```dart
/// VeloxResponsiveBuilder(
///   builder: (context, breakpoint, constraints) {
///     return switch (breakpoint) {
///       VeloxBreakpoint.mobile => const MobileLayout(),
///       VeloxBreakpoint.tablet => const TabletLayout(),
///       _ => const DesktopLayout(),
///     };
///   },
/// )
/// ```
class VeloxResponsiveBuilder extends StatelessWidget {
  /// Creates a [VeloxResponsiveBuilder].
  const VeloxResponsiveBuilder({
    required this.builder,
    super.key,
  });

  /// Builds the widget tree with the resolved breakpoint.
  final VeloxResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final breakpoint = VeloxBreakpoint.fromWidth(constraints.maxWidth);
          return builder(context, breakpoint, constraints);
        },
      );
}
