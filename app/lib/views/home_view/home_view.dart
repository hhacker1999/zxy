import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/views/home_view/continue_watching.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/home_view/top_banner.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/series_view/series_view.dart';
import 'package:zxy_app/views/shared/library_list.dart';
import 'package:zxy_app/views/shared/shimmer_loading.dart';
import 'package:zxy_app/views/view_item_state.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel homeViewModel;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    homeViewModel = context.read<HomeViewModel>()..initialise(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenData = Screen.of(context);
    return ValueListenableBuilder(
      valueListenable: homeViewModel.homeViewLists,
      builder: (_, homeLists, _) {
        final listLength = homeLists.length + 3;
        return ListView.separated(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          separatorBuilder: (_, _) {
            return screenData.shouldRenderMobile
                ? AppTheme.boxHeightM
                : AppTheme.boxHeightL;
          },
          itemCount: homeLists.length + 3,
          itemBuilder: (_, index) {
            if (index == 0) {
              return TopBanner(
                vm: homeViewModel,
              );
            }
            if (index == 1) {
              return Padding(
                padding: EdgeInsets.only(left: AppTheme.spacingM),
                child: ContinueWatchingHeader(homeViewModel: homeViewModel),
              );
            }
            if (index == (listLength - 1)) {
              return AppTheme.boxHeightXXXL;
            }

            final listIndex = index - 2;
            final item = homeLists[listIndex];
            return ValueListenableBuilder<ViewItemState>(
              valueListenable: item.state,
              builder: (_, value, _) {
                if (value is ItemLoading) {
                  return Padding(
                    padding: EdgeInsets.only(left: AppTheme.spacingM),
                    child: _LibraryListShimmer(
                      isMobile: screenData.shouldRenderMobile,
                    ),
                  );
                }
                if (value is ItemError) {
                  return Center(child: Text(value.error));
                }

                final List<ZxyMedia> resourceList =
                    (value as ItemLoaded<List<ZxyMedia>>).data;
                return Padding(
                  padding: EdgeInsets.only(left: AppTheme.spacingM),
                  child: LibraryList(
                    resource: resourceList,
                    title: item.title,
                    onTap: (res) {
                      if (item.type == ZxyMediaType.movie) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.movieView,
                          arguments: res.id,
                        );
                      } else {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.seriesView,
                          arguments: SeriesViewData(id: res.id),
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LibraryListShimmer extends StatelessWidget {
  final bool isMobile;

  const _LibraryListShimmer({required this.isMobile});

  static const _posterAspectRatio = 2 / 3;

  @override
  Widget build(BuildContext context) {
    final double cardWidth = isMobile ? 120 : 160;
    final double imageHeight = cardWidth / _posterAspectRatio;
    final double itemHeight = imageHeight + (isMobile ? 42 : 50);
    final double separatorWidth = isMobile
        ? AppTheme.spacingM
        : AppTheme.spacingXL;

    final double screenWidth = MediaQuery.of(context).size.width;
    final int itemCount = ((screenWidth + separatorWidth) / (cardWidth + separatorWidth)).ceil() + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title placeholder
        Container(
          width: isMobile ? 100 : 140,
          height: isMobile ? 18 : 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        SizedBox(height: isMobile ? AppTheme.spacingS : AppTheme.spacingL),
        SizedBox(
          height: itemHeight,
          child: ShimmerLoading(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              separatorBuilder: (_, _) => SizedBox(width: separatorWidth),
              itemBuilder: (_, index) {
                return SizedBox(
                  width: cardWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Poster placeholder
                      Container(
                        height: imageHeight,
                        width: cardWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      SizedBox(
                        height: isMobile
                            ? AppTheme.spacingS
                            : AppTheme.spacingM,
                      ),
                      // Title placeholder
                      Container(
                        width: cardWidth * 0.7,
                        height: isMobile ? 12 : 14,
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
