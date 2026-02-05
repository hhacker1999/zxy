import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/movie_details.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';
import 'package:zxy_app/views/continue_watching_card.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/library_list.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';
import 'package:zxy_app/views/view_item_state.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel homeViewModel;
  @override
  void initState() {
    super.initState();
    homeViewModel = context.read<HomeViewModel>()..initialise();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingXL),
        child: ValueListenableBuilder(
          valueListenable: homeViewModel.homeViewLists,
          builder: (_, list, _) {
            return Column(
              children: [
                // ValueListenableBuilder(
                //   valueListenable: homeViewModel.topBannerState,
                //   builder: (_, state, _) {
                //     if (state is! ItemLoaded<List<ZxyMedia>>) {
                //       return SizedBox.shrink();
                //     }
                //     return TopBanner(media: state.data);
                //   },
                // ),
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

class TopBanner extends StatefulWidget {
  final List<ZxyMedia> media;
  const TopBanner({super.key, required this.media});

  @override
  State<TopBanner> createState() => _TopBannerState();
}

class _TopBannerState extends State<TopBanner> {
  late final PageController _controller;
  int? page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _controller.addListener(_listener);
  }

  void _listener() {
    if (_controller.hasClients) {
      page = _controller.page?.round();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenData = Screen.of(context);
    final bannerHeight = screenData.shouldRenderMobile ? 220.0 : 450.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: AppTheme.roundedMedium,
          child: SizedBox(
            height: bannerHeight,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.media.length,
              itemBuilder: (context, index) {
                final media = widget.media[index];
                final title = media.title ?? media.name ?? '';

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Backdrop Image
                    ZxyImage(
                      path: media.backdropPath ?? "",
                      size: screenData.shouldRenderMobile ? 'w300' : 'original',
                      height: bannerHeight,
                      width: double.maxFinite,
                      fit: BoxFit.cover,
                    ),

                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.9),
                          ],
                          stops: const [0.3, 0.7, 1.0],
                        ),
                      ),
                    ),

                    // Title Overlay
                    Positioned(
                      bottom: AppTheme.spacingL,
                      left: AppTheme.spacingL,
                      right: AppTheme.spacingL,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: screenData.shouldRenderMobile
                            ? Theme.of(
                                context,
                              ).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 8,
                                  ),
                                ],
                              )
                            : Theme.of(
                                context,
                              ).textTheme.displayMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        AppTheme.boxHeightM,
        // Page Indicators
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppTheme.spacingXS,
          children: List.generate(widget.media.length, (index) {
            return Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: page == index
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
            );
          }),
        ),
        AppTheme.boxHeightL,
      ],
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
