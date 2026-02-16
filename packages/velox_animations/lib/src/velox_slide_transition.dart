import 'package:flutter/material.dart';

/// Direction from which a slide animation enters.
enum VeloxSlideDirection {
  /// Slide in from the left.
  left,

  /// Slide in from the right.
  right,

  /// Slide in from the top.
  top,

  /// Slide in from the bottom.
  bottom,
}

/// A widget that slides its child in from the given direction.
class VeloxSlideIn extends StatefulWidget {
  /// Creates a [VeloxSlideIn] widget.
  const VeloxSlideIn({
    required this.child,
    super.key,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
    this.direction = VeloxSlideDirection.left,
  });

  /// The widget to animate.
  final Widget child;

  /// The duration of the slide animation.
  final Duration duration;

  /// The delay before the animation starts.
  final Duration delay;

  /// The curve of the animation.
  final Curve curve;

  /// The direction from which the child slides in.
  final VeloxSlideDirection direction;

  @override
  State<VeloxSlideIn> createState() => _VeloxSlideInState();
}

class _VeloxSlideInState extends State<VeloxSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<Offset>(
      begin: _offsetForDirection(widget.direction),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
    _startAnimation();
  }

  static Offset _offsetForDirection(VeloxSlideDirection direction) =>
      switch (direction) {
        VeloxSlideDirection.left => const Offset(-1, 0),
        VeloxSlideDirection.right => const Offset(1, 0),
        VeloxSlideDirection.top => const Offset(0, -1),
        VeloxSlideDirection.bottom => const Offset(0, 1),
      };

  Future<void> _startAnimation() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
    }
    if (mounted) {
      await _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SlideTransition(
        position: _animation,
        child: widget.child,
      );
}
