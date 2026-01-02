import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? radius;
  final EdgeInsets? padding;
  final double? height;
  final double? width;
  const GlassContainer({
    super.key,
    required this.child,
    this.radius,
    this.padding,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: height,
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            borderRadius: radius,
            color: Colors.black.withOpacity(0.4),
          ),
          child: child,
        ),
      ),
    );
  }
}
