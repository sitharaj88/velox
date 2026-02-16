import 'package:flutter/material.dart';
import 'package:velox_animations/src/velox_fade_transition.dart';
import 'package:velox_animations/src/velox_slide_transition.dart';

/// A widget that animates a list of children with staggered fade and slide
/// animations.
class VeloxStaggeredList extends StatelessWidget {
  /// Creates a [VeloxStaggeredList] widget.
  const VeloxStaggeredList({
    required this.children,
    super.key,
    this.staggerDuration = const Duration(milliseconds: 100),
    this.animationDuration = const Duration(milliseconds: 300),
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  /// The list of children to display with staggered animations.
  final List<Widget> children;

  /// The delay between each child's animation start.
  final Duration staggerDuration;

  /// The duration of each child's animation.
  final Duration animationDuration;

  /// The cross axis alignment for the internal [Column].
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          for (var i = 0; i < children.length; i++)
            VeloxFadeIn(
              duration: animationDuration,
              delay: staggerDuration * i,
              child: VeloxSlideIn(
                duration: animationDuration,
                delay: staggerDuration * i,
                child: children[i],
              ),
            ),
        ],
      );
}
