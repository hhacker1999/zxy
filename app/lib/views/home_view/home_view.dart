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
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingXL),
        child: ValueListenableBuilder(
          valueListenable: homeViewModel.homeViewLists,
          builder: (_, list, _) {
            return Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: homeViewModel.topBannerState,
                  builder: (_, state, _) {
                    if (state is! ItemLoaded<List<ZxyMedia>>) {
                      return SizedBox.shrink();
                    }
                    return TopBanner(
                      media: state.data,
                      parentScrollController: _scrollController,
                    );
                  },
                ),
                ContinueWatchingHeader(homeViewModel: homeViewModel),
                Column(
                  spacing: Screen.of(context).shouldRenderMobile
                      ? AppTheme.spacingM
                      : AppTheme.spacingXL,
                  children: list.map((item) {
                    return ValueListenableBuilder<ViewItemState>(
                      valueListenable: item.state,
                      builder: (_, value, _) {
                        if (value is ItemLoading) {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        }
                        if (value is ItemError) {
                          return Center(child: Text(value.error));
                        }
                        final List<ZxyMedia> resourceList =
                            (value as ItemLoaded<List<ZxyMedia>>).data;
                        return LibraryList(
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
                                AppRoutes.showView,
                                arguments: res.id,
                              );
                            }
                          },
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
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
                      info: data[index],
                      onTap: () {
                        if (data[index].isShow) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.showView,
                            arguments: (data[index].media as SeriesDetails).id,
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
              screenData.shouldRenderMobile
                  ? AppTheme.boxHeightXS
                  : AppTheme.boxHeightXL,
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
