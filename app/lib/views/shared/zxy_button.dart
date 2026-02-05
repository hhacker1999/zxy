import 'package:flutter/material.dart';
import 'package:zxy_app/app_theme.dart';

class ZxyButton extends StatelessWidget {
  final Color? color;
  final Widget child;
  final VoidCallback? onTap;
  final Duration? duration;
  final bool changeColorBaseOnTap;
  final double? radius;
  final EdgeInsets? padding;
  const ZxyButton({
    super.key,
    this.padding,
    this.radius,
    required this.color,
    required this.child,
    this.changeColorBaseOnTap = false,
    this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: duration ?? const Duration(milliseconds: 300),
        padding:
            padding ??
            EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingS,
            ),
        decoration: BoxDecoration(
          borderRadius: radius != null
              ? BorderRadius.circular(radius!)
              : AppTheme.roundedSmall,
          color: onTap == null && changeColorBaseOnTap
              ? AppTheme.textSecondary
              : color ?? AppTheme.accentColor,
        ),
        child: child,
      ),
    );
  }
}
