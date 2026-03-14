
import 'package:flutter/material.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/resource/movie_details.dart';
import 'package:zxy_app/views/continue_watching_card.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/shimmer_loading.dart';
import 'package:zxy_app/views/view_item_state.dart';

import '../../usecase/resource/tv_details.dart';
import '../series_view/series_view.dart';

class ContinueWatchingHeader extends StatelessWidget {
  const ContinueWatchingHeader({super.key, required this.homeViewModel});

  final HomeViewModel homeViewModel;

  @override
  Widget build(BuildContext context) {
    final screenData = Screen.of(context);
    final double itemHeight = screenData.shouldRenderMobile ? 180 : 260;
    return ValueListenableBuilder<
      ViewItemState<List<ContinueWatchingCardInfo>>
    >(
      valueListenable: homeViewModel.continueWatchingState,
      builder: (_, state, _) {
        if (state is ItemLoading) {
          return _ContinueWatchingShimmer(
            isMobile: screenData.shouldRenderMobile,
            itemHeight: itemHeight,
          );
        }
        if (state is ItemLoaded<List<ContinueWatchingCardInfo>>) {
          final data = state.data;
          if (data.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Continue Watching",
                style: screenData.shouldRenderMobile
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.titleLarge,
              ),
              AppTheme.boxHeightM,
              SizedBox(
                height: itemHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppTheme.spacingM),
                  itemBuilder: (_, index) {
                    return ContinueWatchingCard(
                      key: ValueKey(data[index].progress.mediaId),
                      onLongPress: (details) {
                        _showContinueWatchingMenu(
                          context,
                          details.globalPosition,
                          () {
                            homeViewModel.markMediaWatched(
                              data[index].progress.mediaId,
                              data[index].media is MovieDetails,
                            );
                          },
                          () {
                            homeViewModel.removeFromContinue(
                              data[index].progress.mediaId,
                            );
                          },
                        );
                      },
                      onRightClick: (details) {
                        _showContinueWatchingMenu(
                          context,
                          details.globalPosition,
                          () {
                            homeViewModel.markMediaWatched(
                              data[index].progress.mediaId,
                              data[index].media is MovieDetails,
                            );
                          },
                          () {
                            homeViewModel.removeFromContinue(
                              data[index].progress.mediaId,
                            );
                          },
                        );
                      },
                      info: data[index],
                      onTap: () {
                        if (data[index].isShow) {
                          final splitted = data[index].progress.mediaId.split(
                            ":",
                          );
                          final seasonIndex =
                              (int.tryParse(splitted[1]) ?? 0) - 1;
                          final episodeIndex =
                              (int.tryParse(splitted[2]) ?? 0) - 1;
                          Navigator.pushNamed(
                            context,
                            AppRoutes.seriesView,
                            arguments: SeriesViewData(
                              id: (data[index].media as SeriesDetails).id,
                              seasonIndex: seasonIndex,
                              episodeIndex: episodeIndex,
                            ),
                          );
                        } else {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.movieView,
                            arguments: (data[index].media as MovieDetails).id,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

void _showContinueWatchingMenu(
  BuildContext context,
  Offset globalPosition,
  VoidCallback onMarkTap,
  VoidCallback onRemoveTap,
) {
  final RelativeRect position = RelativeRect.fromLTRB(
    globalPosition.dx,
    globalPosition.dy,
    globalPosition.dx,
    globalPosition.dy,
  );
  showMenu(
    context: context,
    position: position,
    items: [
      PopupMenuItem(
        onTap: () {
          onMarkTap();
        },
        child: Text("Mark Watched"),
      ),
      PopupMenuItem(
        onTap: () {
          onRemoveTap();
        },
        child: Text("Remove from Continue Watching"),
      ),
    ],
  );
}

class _ContinueWatchingShimmer extends StatelessWidget {
  final bool isMobile;
  final double itemHeight;

  const _ContinueWatchingShimmer({
    required this.isMobile,
    required this.itemHeight,
  });

  @override
  Widget build(BuildContext context) {
    final double cardWidth = isMobile ? 240 : 320;
    final double imageHeight = (cardWidth * 9) / 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shimmer title placeholder
        Container(
          width: isMobile ? 140 : 180,
          height: isMobile ? 18 : 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        AppTheme.boxHeightM,
        SizedBox(
          height: itemHeight,
          child: ShimmerLoading(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppTheme.spacingM),
              itemBuilder: (_, index) {
                return SizedBox(
                  width: cardWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Thumbnail placeholder
                      Container(
                        height: imageHeight,
                        width: cardWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        child: Stack(
                          children: [
                            // Fake progress bar
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Title placeholder
                      Container(
                        width: cardWidth * 0.6,
                        height: isMobile ? 14 : 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXSmall,
                          ),
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
