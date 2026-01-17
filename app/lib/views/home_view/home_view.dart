import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';
import 'package:zxy_app/views/continue_watching_card.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/library_card.dart';
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
    final readToken =
        "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NWJjYTJhN2NhODdkNTZkZGZlMDgyZDAzOWNiZjk1ZiIsIm5iZiI6MTY1MDA0MzA3My4wMTksInN1YiI6IjYyNTlhOGMxZWNhZWY1MTVmZjY3OGY3MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EppXuTBWBa1uXJgfie3m7lKAEpspRwnc_aHr33UBkHU";
    homeViewModel = context.read<HomeViewModel>()..initialise(readToken);
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
                ValueListenableBuilder(
                  valueListenable: homeViewModel.topBannerState,
                  builder: (_, state, _) {
                    if (state is! ItemLoaded<List<ZxyMedia>>) {
                      return SizedBox.shrink();
                    }
                    return TopBanner(media: state.data);
                  },
                ),
                ContinueWatchingHeader(homeViewModel: homeViewModel),
                Column(
                  children: list.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingXL,
                      ),
                      child: ValueListenableBuilder<ViewItemState>(
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
                      ),
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
    return LayoutBuilder(
      builder: (_, constr) {
        final width = constr.maxWidth;
        final height = (width * 9) / 16;
        return Column(
          children: [
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: AppTheme.roundedLarge,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              height: height,
              width: width,
              child: PageView.builder(
                scrollDirection: Axis.horizontal,
                controller: _controller,
                itemBuilder: (_, index) {
                  return InkWell(
                    onTap: () {},
                    child: HomeViewBannerItem(
                      media: widget.media[index],
                      height: height,
                      width: width,
                      size: Screen.of(context).shouldRenderMobile
                          ? "w780"
                          : "w1280",
                    ),
                  );
                },
              ),
            ),
            AppTheme.boxHeightM,
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
              AppTheme.boxHeightXL,
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class LibraryList extends StatelessWidget {
  final String title;
  final void Function(ZxyMedia) onTap;
  const LibraryList({
    super.key,
    required this.resource,
    required this.title,
    required this.onTap,
  });

  final List<ZxyMedia> resource;

  @override
  Widget build(BuildContext context) {
    final screenData = Screen.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: screenData.shouldRenderMobile
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(
          height: screenData.shouldRenderMobile
              ? AppTheme.spacingM
              : AppTheme.spacingL,
        ),
        LibraryListItem(resource: resource, onTap: onTap),
      ],
    );
  }
}

class HomeViewBannerItem extends StatelessWidget {
  final ZxyMedia media;
  final double height;
  final double width;
  final String size;
  const HomeViewBannerItem({
    super.key,
    required this.media,
    required this.height,
    required this.width,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ZxyImage(
          height: height,
          width: width,
          path: media.backdropPath!,
          isPoster: false,
          size: size,
        ),
      ],
    );
  }
}
