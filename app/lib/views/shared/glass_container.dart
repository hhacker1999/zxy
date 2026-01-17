import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? radius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? height;
  final double? width;
  final double borderOpacity;
  final double containerOpacity;
  const GlassContainer({
    super.key,
    required this.child,
    this.radius,
    this.padding,
    this.height,
    this.margin,
    this.width,
    this.borderOpacity = 0.1,
    this.containerOpacity = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          margin: margin,
          height: height,
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: 1.5,
            ),
            borderRadius: radius,
            color: Colors.black.withOpacity(containerOpacity),
          ),
          child: child,
        ),
      ),
    );
  }
}
