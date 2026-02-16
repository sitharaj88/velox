import 'package:flutter/material.dart';

/// A widget that fades its child in from transparent to opaque.
class VeloxFadeIn extends StatefulWidget {
  /// Creates a [VeloxFadeIn] widget.
  const VeloxFadeIn({
    required this.child,
    super.key,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeIn,
  });

  /// The widget to animate.
  final Widget child;

  /// The duration of the fade animation.
  final Duration duration;

  /// The delay before the animation starts.
  final Duration delay;

  /// The curve of the animation.
  final Curve curve;

  @override
  State<VeloxFadeIn> createState() => _VeloxFadeInState();
}

class _VeloxFadeInState extends State<VeloxFadeIn>
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
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
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
  Widget build(BuildContext context) => FadeTransition(
        opacity: _animation,
        child: widget.child,
      );
}

/// A widget that fades its child out from opaque to transparent.
class VeloxFadeOut extends StatefulWidget {
  /// Creates a [VeloxFadeOut] widget.
  const VeloxFadeOut({
    required this.child,
    super.key,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
  });

  /// The widget to animate.
  final Widget child;

  /// The duration of the fade animation.
  final Duration duration;

  /// The delay before the animation starts.
  final Duration delay;

  /// The curve of the animation.
  final Curve curve;

  @override
  State<VeloxFadeOut> createState() => _VeloxFadeOutState();
}

class _VeloxFadeOutState extends State<VeloxFadeOut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
    }
    if (mounted) {
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _animation,
        child: widget.child,
      );
}
