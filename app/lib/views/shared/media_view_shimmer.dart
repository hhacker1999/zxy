import 'package:flutter/material.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/views/shared/shimmer_loading.dart';

class MediaViewShimmer extends StatelessWidget {
  final bool isMobile;
  final double headerHeight;

  const MediaViewShimmer({
    super.key,
    required this.isMobile,
    required this.headerHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Media/Banner Placeholder
            SizedBox(
              height: headerHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.08)),
                  Positioned(
                    bottom: isMobile ? 30 : 60,
                    left: isMobile ? AppTheme.spacingM : AppTheme.spacingXL,
                    right: isMobile ? AppTheme.spacingM : AppTheme.spacingXL,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: isMobile ? 200 : 350,
                          height: isMobile ? 32 : 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                        ),
                        AppTheme.boxHeightM,
                        Row(
                          children: List.generate(
                            3,
                            (index) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Container(
                                width: 60,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!isMobile) ...[
                          AppTheme.boxHeightM,
                          Container(
                            width: 420,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXSmall,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 300,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXSmall,
                              ),
                            ),
                          ),
                        ],
                        AppTheme.boxHeightM,
                        Container(
                          width: isMobile ? 120 : 160,
                          height: isMobile ? 40 : 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXXLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppTheme.boxHeightL,
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cast & Crew Title Placeholder
                  Container(
                    width: 120,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  AppTheme.boxHeightM,
                  // Cast Row Placeholder
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: List.generate(
                        5,
                        (index) => Padding(
                          padding: const EdgeInsets.only(
                            right: AppTheme.spacingM,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: isMobile ? 80 : 100,
                                height: isMobile ? 80 : 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              AppTheme.boxHeightS,
                              Container(
                                width: 70,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXSmall,
                                  ),
                                ),
                              ),
                              AppTheme.boxHeightXS,
                              Container(
                                width: 50,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXSmall,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  isMobile ? AppTheme.boxHeightM : AppTheme.boxHeightL,
                  // Library List Placeholder 1
                  Container(
                    width: 180,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  AppTheme.boxHeightM,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: List.generate(
                        4,
                        (index) => Padding(
                          padding: const EdgeInsets.only(
                            right: AppTheme.spacingM,
                          ),
                          child: Container(
                            width: 120,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  isMobile ? AppTheme.boxHeightM : AppTheme.boxHeightL,
                  // Library List Placeholder 2
                  Container(
                    width: 150,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  AppTheme.boxHeightM,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: List.generate(
                        4,
                        (index) => Padding(
                          padding: const EdgeInsets.only(
                            right: AppTheme.spacingM,
                          ),
                          child: Container(
                            width: 120,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
