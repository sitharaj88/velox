import 'package:flutter/widgets.dart';
import 'package:velox_responsive/src/velox_breakpoint.dart';
import 'package:velox_responsive/src/velox_responsive_value.dart';

/// A responsive grid layout that adjusts its column count per breakpoint.
///
/// Uses [Wrap] internally and distributes child widths based on the
/// resolved column count for the current breakpoint.
///
/// Each child should be a [VeloxGridItem] with a [VeloxGridItem.span]
/// indicating how many columns it occupies.
///
/// ```dart
/// VeloxResponsiveGrid(
///   columns: VeloxResponsiveValue<int>(mobile: 2, tablet: 4, desktop: 6),
///   spacing: 8,
///   runSpacing: 8,
///   children: [
///     VeloxGridItem(span: 1, child: Card()),
///     VeloxGridItem(span: 2, child: Card()),
///   ],
/// )
/// ```
class VeloxResponsiveGrid extends StatelessWidget {
  /// Creates a [VeloxResponsiveGrid].
  const VeloxResponsiveGrid({
    required this.columns,
    required this.children,
    this.spacing = 0,
    this.runSpacing = 0,
    super.key,
  });

  /// Responsive column count per breakpoint.
  final VeloxResponsiveValue<int> columns;

  /// Horizontal spacing between grid items.
  final double spacing;

  /// Vertical spacing between grid rows.
  final double runSpacing;

  /// The grid items to display.
  final List<VeloxGridItem> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final breakpoint = VeloxBreakpoint.fromWidth(constraints.maxWidth);
          final columnCount = columns.resolve(breakpoint);
          final totalSpacing = spacing * (columnCount - 1);
          final columnWidth = (constraints.maxWidth - totalSpacing) / columnCount;

          return Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: [
              for (final item in children)
                SizedBox(
                  width: columnWidth * item.span +
                      spacing * (item.span - 1),
                  child: item.child,
                ),
            ],
          );
        },
      );
}

/// A single item within a [VeloxResponsiveGrid].
///
/// The [span] property controls how many columns this item occupies.
class VeloxGridItem extends StatelessWidget {
  /// Creates a [VeloxGridItem].
  const VeloxGridItem({
    required this.child,
    this.span = 1,
    super.key,
  });

  /// How many columns this item spans.
  final int span;

  /// The child widget to display.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
