import 'dart:math';
import 'package:flutter/material.dart';

/// Clips its child with a pinwheel (rotating arc) reveal animation.
class PinWheelReveal extends StatefulWidget {
  const PinWheelReveal({
    super.key,
    required this.child,
    required this.duration,
    this.delay = Duration.zero,
    this.curve = Curves.easeInOutCubic,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  @override
  State<PinWheelReveal> createState() => _PinWheelRevealState();
}

class _PinWheelRevealState extends State<PinWheelReveal>
    with SingleTickerProviderStateMixin {
  double _fraction = 0.0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation =
        Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: widget.curve),
        )..addListener(() {
          setState(() => _fraction = _animation.value);
        });
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _ArcClipper(fraction: _fraction),
      child: widget.child,
    );
  }
}

class _ArcClipper extends CustomClipper<Path> {
  const _ArcClipper({required this.fraction});
  final double fraction;

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: size.width + 500),
        _toRad(-90),
        _toRad(360 * fraction),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: 0),
        _toRad(269.999 * fraction),
        _toRad(-90) - _toRad(269.999 * fraction),
        false,
      );
    return path;
  }

  @override
  bool shouldReclip(_ArcClipper old) => old.fraction != fraction;

  double _toRad(double deg) => deg * (pi / 180);
}

/// Animates scale + opacity simultaneously.
class AnimatedScaleOpacity extends StatelessWidget {
  const AnimatedScaleOpacity({
    super.key,
    required this.child,
    required this.animateIn,
    this.duration = const Duration(milliseconds: 500),
    this.durationOpacity = const Duration(milliseconds: 100),
    this.alignment = AlignmentDirectional.center,
    this.curve = Curves.easeInOutCubicEmphasized,
  });

  final Widget child;
  final bool animateIn;
  final Duration duration;
  final Duration durationOpacity;
  final AlignmentDirectional alignment;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: durationOpacity,
      opacity: animateIn ? 1 : 0,
      child: AnimatedScale(
        scale: animateIn ? 1 : 0,
        duration: duration,
        curve: curve,
        alignment: alignment.resolve(Directionality.of(context)),
        child: child,
      ),
    );
  }
}

/// AnimatedSwitcher with a scale+fade transition.
class ScaledAnimatedSwitcher extends StatelessWidget {
  const ScaledAnimatedSwitcher({
    super.key,
    required this.keyToWatch,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
  });

  final String keyToWatch;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) {
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: const Interval(0.5, 1)),
        );
        final scale = Tween<double>(begin: 0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: const Interval(0, 1.0)),
        );
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: SizedBox(key: ValueKey(keyToWatch), child: child),
    );
  }
}
