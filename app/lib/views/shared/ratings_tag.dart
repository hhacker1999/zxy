import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zxy_app/app_constants.dart';
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

  /// The accent colour for the score number – amber for IMDB, teal for TMDB.
  Color get _accentColor {
    if (icon == AppIcons.imdb) return const Color(0xFFF5C518); // IMDB gold
    if (icon == AppIcons.tmdb) return const Color(0xFF01B4E4); // TMDB blue
    return AppTheme.textSecondary;
  }

  double get _logoSize => shouldRenderMobile ? 28 : 32;
  double get _fontSize => shouldRenderMobile ? 11 : 13;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 6,
        children: [
          SvgPicture.asset(icon, height: _logoSize * 0.4),
          Text(
            rating,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              color: _accentColor,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
