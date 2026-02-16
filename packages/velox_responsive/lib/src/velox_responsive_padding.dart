import 'package:flutter/widgets.dart';
import 'package:velox_responsive/src/velox_breakpoint.dart';
import 'package:velox_responsive/src/velox_responsive_value.dart';

/// A widget that applies different padding per responsive breakpoint.
///
/// Uses [LayoutBuilder] internally to determine the current breakpoint
/// and resolves the appropriate [EdgeInsets] from the provided
/// [VeloxResponsiveValue].
///
/// ```dart
/// VeloxResponsivePadding(
///   padding: VeloxResponsiveValue<EdgeInsets>(
///     mobile: EdgeInsets.all(8),
///     tablet: EdgeInsets.all(16),
///     desktop: EdgeInsets.all(24),
///   ),
///   child: Text('Hello'),
/// )
/// ```
class VeloxResponsivePadding extends StatelessWidget {
  /// Creates a [VeloxResponsivePadding].
  const VeloxResponsivePadding({
    required this.padding,
    required this.child,
    super.key,
  });

  /// The responsive padding values per breakpoint.
  final VeloxResponsiveValue<EdgeInsets> padding;

  /// The child widget to wrap with padding.
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final breakpoint = VeloxBreakpoint.fromWidth(constraints.maxWidth);
          return Padding(
            padding: padding.resolve(breakpoint),
            child: child,
          );
        },
      );
}
