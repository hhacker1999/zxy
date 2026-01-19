import 'package:flutter/material.dart';
import 'package:zxy_app/app_theme.dart';

class ZxyButton extends StatelessWidget {
  final Color? color;
  final Widget child;
  final VoidCallback? onTap;
  final Duration? duration;
  final bool changeColorBaseOnTap;
  const ZxyButton({
    super.key,
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
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          borderRadius: AppTheme.roundedSmall,
          color: onTap == null && changeColorBaseOnTap
              ? AppTheme.textSecondary
              : color ?? AppTheme.accentColor,
        ),
        child: child,
      ),
    );
  }
}
