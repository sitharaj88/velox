import 'package:flutter/material.dart';

/// A group of buttons arranged horizontally or vertically with spacing.
///
/// Uses a [Wrap] widget to layout children with the specified
/// [direction] and [spacing].
class VeloxButtonGroup extends StatelessWidget {
  /// Creates a [VeloxButtonGroup].
  const VeloxButtonGroup({
    required this.children,
    super.key,
    this.direction = Axis.horizontal,
    this.spacing = 8,
  });

  /// The buttons to display in the group.
  final List<Widget> children;

  /// The direction to layout the buttons.
  final Axis direction;

  /// The spacing between buttons.
  final double spacing;

  @override
  Widget build(BuildContext context) => Wrap(
        direction: direction,
        spacing: spacing,
        runSpacing: spacing,
        children: children,
      );
}
