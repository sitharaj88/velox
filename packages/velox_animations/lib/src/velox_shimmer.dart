import 'package:flutter/material.dart';

/// A widget that applies a shimmer loading effect to its child.
class VeloxShimmer extends StatefulWidget {
  /// Creates a [VeloxShimmer] widget.
  const VeloxShimmer({
    required this.child,
    super.key,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  /// The widget to apply the shimmer effect to.
  final Widget child;

  /// The base color of the shimmer gradient.
  ///
  /// Defaults to `Colors.grey[300]`.
  final Color? baseColor;

  /// The highlight color of the shimmer gradient.
  ///
  /// Defaults to `Colors.grey[100]`.
  final Color? highlightColor;

  /// The duration of a single shimmer cycle.
  final Duration duration;

  @override
  State<VeloxShimmer> createState() => _VeloxShimmerState();
}

class _VeloxShimmerState extends State<VeloxShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? Colors.grey[300]!;
    final highlight = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [base, highlight, base],
          stops: const [0.0, 0.5, 1.0],
          transform: _SlidingGradientTransform(
            slidePercent: _controller.value,
          ),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(
        bounds.width * (slidePercent * 2 - 1),
        0,
        0,
      );
}
