import 'package:flutter/material.dart';

/// A widget that scales its child in from a given starting scale.
class VeloxScaleIn extends StatefulWidget {
  /// Creates a [VeloxScaleIn] widget.
  const VeloxScaleIn({
    required this.child,
    super.key,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
    this.beginScale = 0.0,
  });

  /// The widget to animate.
  final Widget child;

  /// The duration of the scale animation.
  final Duration duration;

  /// The delay before the animation starts.
  final Duration delay;

  /// The curve of the animation.
  final Curve curve;

  /// The initial scale value before the animation starts.
  final double beginScale;

  @override
  State<VeloxScaleIn> createState() => _VeloxScaleInState();
}

class _VeloxScaleInState extends State<VeloxScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(
      begin: widget.beginScale,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
    _startAnimation();
  }

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
  Widget build(BuildContext context) => ScaleTransition(
        scale: _animation,
        child: widget.child,
      );
}
