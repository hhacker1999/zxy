import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/movie_details.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/continue_watching_card.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/home_view/top_banner.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/series_view/series_view.dart';
import 'package:zxy_app/views/shared/library_list.dart';
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
                parentScrollController: _scrollController,
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
                  return const Center(child: CupertinoActivityIndicator());
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
          return SizedBox(height: itemHeight);
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
