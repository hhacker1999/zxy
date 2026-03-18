import 'package:flutter/material.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/series_view/series_view.dart';
import 'package:zxy_app/views/shared/library_card.dart';
import 'package:zxy_app/views/shared/shimmer_loading.dart';
import 'package:zxy_app/views/view_item_state.dart';

class MediaGrid extends StatelessWidget {
  const MediaGrid({
    super.key,
    required this.onScrollNearEnd,
    required this.showType,
    required this.scrollController,
    required this.notifier,
    required this.initialText,
  });

  final VoidCallback onScrollNearEnd;
  final String initialText;
  final bool showType;
  final ScrollController scrollController;
  final ValueNotifier<ViewItemState<List<ZxyMedia>>> notifier;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constr) {
        final ScreenData screenData = Screen.of(context);
        final double width = screenData.shouldRenderMobile ? 110 : 160;
        final double imageHeight = width / AppConstants.posterAspectRatio;
        final double textHeight = screenData.shouldRenderMobile ? 40 : 50;
        final double spacing = screenData.shouldRenderMobile
            ? AppTheme.spacingS
            : AppTheme.spacingL;
        final double itemHeight = imageHeight + textHeight;
        int crossAxisCount = ((constr.maxWidth + spacing) / (width + spacing))
            .floor();
        // Ensure at least 1 column
        crossAxisCount = crossAxisCount.clamp(1, 99);

        return ValueListenableBuilder(
          valueListenable: notifier,
          builder: (_, itemState, _) {
            if (itemState is ItemLoading) {
              return ShimmerLoading(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: crossAxisCount * 4,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: screenData.shouldRenderMobile
                        ? AppTheme.spacingXS
                        : AppTheme.spacingS,
                    childAspectRatio: width / itemHeight,
                  ),
                  itemBuilder: (_, index) {
                    return Center(
                      child: SizedBox(
                        width: width,
                        height: itemHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: imageHeight,
                              width: width,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: width * 0.7,
                              height: screenData.shouldRenderMobile ? 12 : 14,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXSmall,
                                ),
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            if (itemState is ItemInitial) {
              return Center(child: Text(initialText));
            }
            if (itemState is ItemError) {
              return Center(child: Text((itemState as ItemError).error));
            }
            final List<ZxyMedia> items =
                (itemState as ItemLoaded<List<ZxyMedia>>).data;
            if (items.isEmpty) {
              return Center(child: Text("No Items found"));
            }

            return NotificationListener<ScrollMetricsNotification>(
              onNotification: (noti) {
                if (scrollController.position.maxScrollExtent == 0) {
                  onScrollNearEnd();
                  return false;
                }
                final currOffset = scrollController.offset;
                final maxOffset = scrollController.position.maxScrollExtent;
                if ((maxOffset - currOffset) < 200) {
                  onScrollNearEnd();
                }
                return false;
              },
              child: GridView.builder(
                padding: EdgeInsets.zero,
                controller: scrollController,
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: screenData.shouldRenderMobile
                      ? AppTheme.spacingXS
                      : AppTheme.spacingS,
                  childAspectRatio: width / itemHeight,
                ),
                itemBuilder: (_, index) {
                  return Center(
                    child: LibraryCard(
                      key: ValueKey(index),
                      updateColorOnHover: true,
                      showMediaType: showType,
                      resource: items[index],
                      onTap: (_) {
                        Navigator.pushNamed(
                          context,
                          items[index].type == ZxyMediaType.movie
                              ? AppRoutes.movieView
                              : AppRoutes.seriesView,
                          arguments: items[index].type == ZxyMediaType.movie
                              ? items[index].id
                              : SeriesViewData(id: items[index].id),
                        );
                      },
                      width: width,
                      height: itemHeight,
                      imageHeight: imageHeight,
                      textHeight: textHeight,
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
