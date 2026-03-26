
import 'dart:math';

import 'package:flutter/material.dart';

class VideoBufferingIndicator extends StatefulWidget {
  const VideoBufferingIndicator({super.key});

  @override
  State<VideoBufferingIndicator> createState() =>
      _VideoBufferingIndicatorState();
}

class _VideoBufferingIndicatorState extends State<VideoBufferingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 52;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController]),
        builder: (_, _) {
          final pulseValue =
              Curves.easeInOut.transform(_pulseController.value);
          final glowOpacity = 0.12 + pulseValue * 0.18;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing glow backdrop
              Container(
                width: size + 16,
                height: size + 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(glowOpacity),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              // Rotating arc ring
              Transform.rotate(
                angle: _rotationController.value * 2 * 3.14159265,
                child: CustomPaint(
                  size: const Size(size, size),
                  painter: _ArcRingPainter(
                    progress: _rotationController.value,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Draws a gradient arc ring used as the spinning element of the loading indicator.
class _ArcRingPainter extends CustomPainter {
  final double progress;
  _ArcRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2.5;
    const strokeWidth = 3.0;
    const sweepAngle = 4.4; // ~250 degrees in radians

    // Track ring (subtle)
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withOpacity(0.08)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: sweepAngle,
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(0.5),
        Colors.white.withOpacity(0.95),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);

    canvas.drawArc(rect, 0, sweepAngle, false, arcPaint);

    // Bright dot at the leading tip of the arc
    final tipAngle = sweepAngle;
    final tipX = center.dx + radius * cos(tipAngle);
    final tipY = center.dy + radius * sin(tipAngle);
    final tipPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(tipX, tipY), 2.5, tipPaint);
  }

  @override
  bool shouldRepaint(_ArcRingPainter oldDelegate) => false;
}
