import 'package:flutter/cupertino.dart';

class ScaleFadeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve scaleCurve;
  final Curve opacityCurve;
  final double initialScale;

  const ScaleFadeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.scaleCurve = Curves.easeOutBack,
    this.opacityCurve = Curves.easeOut,
    this.initialScale = 0.85,
  });

  @override
  State<ScaleFadeWidget> createState() => _ScaleFadeWidgetState();
}

class _ScaleFadeWidgetState extends State<ScaleFadeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnim = Tween<double>(begin: widget.initialScale, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.scaleCurve),
    );

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: widget.opacityCurve),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    return FadeTransition(
      opacity: _opacityAnim,
      child: ScaleTransition(scale: _scaleAnim, child: widget.child),
    );
  }
}

