import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zxy_app/app_theme.dart';

class RatingTag extends StatelessWidget {
  const RatingTag({
    super.key,
    required this.rating,
    required this.icon,
    required this.shouldRenderMobile,
  });

  final String rating;
  final String icon;
  final bool shouldRenderMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingXS),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: AppTheme.roundedSmall,
        border: Border.all(color: AppTheme.textSecondary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: AppTheme.spacingXS,
        children: [
          Text(
            rating,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontSize: shouldRenderMobile ? 10 : 12,
            ),
          ),
          SvgPicture.asset(icon, height: shouldRenderMobile ? 10 : 12),
        ],
      ),
    );
  }
}
