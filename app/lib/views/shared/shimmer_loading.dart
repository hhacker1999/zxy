import 'package:flutter/material.dart';

/// A reusable shimmer loading effect. Wraps any child with an animated
/// diagonal sweep highlight. No external packages needed.
///
/// Usage:
/// ```dart
/// ShimmerLoading(
///   child: Container(width: 200, height: 100, color: Colors.white10),
/// )
/// ```
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                return CustomPaint(
                  painter: _ShimmerSweepPainter(progress: _controller.value),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Draws a diagonal shimmer sweep band across the widget area.
class _ShimmerSweepPainter extends CustomPainter {
  final double progress;

  _ShimmerSweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.save();
    canvas.clipRect(rect);

    // Rotate for diagonal sweep (~25 degrees)
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(0.44);
    canvas.translate(-size.width / 2, -size.height / 2);

    final bandWidth = size.width * 0.45;
    final diagonal = size.width + size.height;
    final startX = -bandWidth - diagonal * 0.3;
    final endX = size.width + bandWidth + diagonal * 0.3;
    final offset = startX + (endX - startX) * progress;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(offset, -diagonal, bandWidth, diagonal * 3));

    canvas.drawRect(
      Rect.fromLTWH(-diagonal, -diagonal, diagonal * 3, diagonal * 3),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShimmerSweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
