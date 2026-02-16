import 'package:flutter/material.dart';

/// The type of transition for [VeloxAnimatedSwitcher].
enum VeloxSwitchTransition {
  /// A fade transition.
  fade,

  /// A scale transition.
  scale,

  /// A slide-up transition.
  slideUp,

  /// A slide-down transition.
  slideDown,
}

/// An enhanced [AnimatedSwitcher] that supports multiple transition types.
class VeloxAnimatedSwitcher extends StatelessWidget {
  /// Creates a [VeloxAnimatedSwitcher] widget.
  const VeloxAnimatedSwitcher({
    required this.child,
    super.key,
    this.duration = const Duration(milliseconds: 300),
    this.transition = VeloxSwitchTransition.fade,
  });

  /// The current child widget to display.
  final Widget child;

  /// The duration of the switch animation.
  final Duration duration;

  /// The type of transition to use.
  final VeloxSwitchTransition transition;

  AnimatedSwitcherTransitionBuilder get _transitionBuilder =>
      switch (transition) {
        VeloxSwitchTransition.fade => _fadeBuilder,
        VeloxSwitchTransition.scale => _scaleBuilder,
        VeloxSwitchTransition.slideUp => _slideUpBuilder,
        VeloxSwitchTransition.slideDown => _slideDownBuilder,
      };

  static Widget _fadeBuilder(Widget child, Animation<double> animation) =>
      FadeTransition(
        opacity: animation,
        child: child,
      );

  static Widget _scaleBuilder(Widget child, Animation<double> animation) =>
      ScaleTransition(
        scale: animation,
        child: child,
      );

  static Widget _slideUpBuilder(Widget child, Animation<double> animation) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );

  static Widget _slideDownBuilder(Widget child, Animation<double> animation) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: duration,
        transitionBuilder: _transitionBuilder,
        child: child,
      );
}
