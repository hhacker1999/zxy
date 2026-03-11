import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/main.dart';
import 'package:zxy_app/usecase/progress/model.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/series_view/series_view_model.dart';
import 'package:zxy_app/views/shared/base_scaffold.dart';
import 'package:zxy_app/views/shared/cast_crew.dart';
import 'package:zxy_app/views/shared/drop_down.dart';
import 'package:zxy_app/views/shared/library_list.dart';
import 'package:zxy_app/views/shared/media_info_banner.dart';
import 'package:zxy_app/views/shared/media_info_poster.dart';
import 'package:zxy_app/views/shared/stream_row.dart';
import 'package:zxy_app/views/shared/toast.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';
import 'package:zxy_app/views/view_item_state.dart';

import '../filter_view/filter_view_model.dart';

class SeriesViewData {
  final int id;
  int? seasonIndex;
  final int episodeIndex;

  SeriesViewData({required this.id, this.seasonIndex, this.episodeIndex = 0});
}

class SeriesView extends StatefulWidget {
  final SeriesViewData data;
  const SeriesView({super.key, required this.data});

  @override
  State<SeriesView> createState() => _SeriesViewState();
}

class _SeriesViewState extends State<SeriesView> with RouteAware {
  late final SeriesViewModel vm;
  final episodeDF = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    vm = context.read<SeriesViewModel>();
    vm.initialise(
      widget.data.id,
      season: widget.data.seasonIndex,
      episode: widget.data.episodeIndex,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    vm.updateShowProgressFromBE();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      loading: vm.scffoldLoading,
      padding: EdgeInsets.zero,
      builder: (_, color) {
        final screenInfo = Screen.of(context);
        final width = screenInfo.width;
        final height = screenInfo.shouldRenderMobile
            ? (width * 3) / 2
            : (width * 9) / 16;
        return ValueListenableBuilder(
          valueListenable: vm.seriesDetailState,
          builder: (_, state, _) {
            if (state is ItemError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppTheme.spacingM,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Go Back"),
                  ),
                  Text((state as ItemError).error),
                ],
              );
            }
            if (state is! ItemLoaded) {
              return Center(child: CupertinoActivityIndicator());
            }
            final details = (state as ItemLoaded<SeriesDetails>).data;
            List<Cast> nonEmptyCast = List.empty();
            if (details.credits != null && details.credits!.cast != null) {
              nonEmptyCast = details.credits!.cast!
                  .where(
                    (member) =>
                        member.profilePath != null &&
                        member.profilePath!.isNotEmpty,
                  )
                  .toList();
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: !Screen.of(context).shouldRenderMobile,
                    replacement: MediaInfoPoster(
                      streamRow: StreamRow(
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.videoPlayerView,
                            arguments: vm,
                          );
                          vm.onPause();
                        },
                        color: AppTheme.accentColor,
                        handler: vm,
                        onStreamSelect: vm.onStreamSelect,
                      ),
                      media: details,
                      height: height,
                      width: width,
                      size: "w500",
                      color: color,
                    ),
                    child: SizedBox(
                      height: height,
                      child: MediaInfoBanner(
                        streamRow: StreamRow(
                          color: AppTheme.accentColor,
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              AppRoutes.videoPlayerView,
                              arguments: vm,
                            );
                            vm.onPause();
                          },
                          handler: vm,
                          onStreamSelect: vm.onStreamSelect,
                        ),
                        media: details,
                        height: height,
                        width: width,
                        size: "original",
                        color: color,
                      ),
                    ),
                  ),
                  AppTheme.boxHeightL,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CastAndCrew(
                          castList: nonEmptyCast,
                          renderMobile: screenInfo.shouldRenderMobile,
                        ),
                        screenInfo.shouldRenderMobile
                            ? AppTheme.boxHeightM
                            : AppTheme.boxHeightL,
                        LayoutBuilder(
                          builder: (_, constr) {
                            return ValueListenableBuilder(
                              valueListenable: vm.activeSeasonEpisode,
                              builder: (_, active, _) {
                                final Season season = vm.seasons[active.$1];
                                final double episodeWidth =
                                    screenInfo.shouldRenderMobile
                                    ? 120
                                    : ((constr.maxWidth -
                                                  (3 * AppTheme.spacingL)) /
                                              4)
                                          .floorToDouble();

                                final double episodeHeight =
                                    (episodeWidth * 9) / 16;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ModernDropdown(
                                      height: 40,
                                      initialSelection: active.$1,
                                      entries: List.generate(vm.seasons.length, (
                                        index,
                                      ) {
                                        return DropdownMenuEntry(
                                          value: index,
                                          label:
                                              "Season ${vm.seasons[index].seasonNumber.toString().padLeft(2, '0')}",
                                        );
                                      }),
                                      onSelected: (val) {
                                        if (val == null) {
                                          return;
                                        }
                                        vm.onSeasonSelect(val);
                                      },
                                    ),
                                    screenInfo.shouldRenderMobile
                                        ? AppTheme.boxHeightM
                                        : AppTheme.boxHeightL,
                                    EpisodesList(
                                      id: widget.data.id,
                                      color: color,
                                      renderMobile:
                                          screenInfo.shouldRenderMobile,
                                      season: season,
                                      vm: vm,
                                      episodeWidth: episodeWidth,
                                      episodeHeight: episodeHeight,
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),

                        if (details.recommendations != null &&
                            details.recommendations!.results.isNotEmpty) ...[
                          screenInfo.shouldRenderMobile
                              ? AppTheme.boxHeightL
                              : AppTheme.boxHeightXXL,
                          LibraryList(
                            updateColorOnHover: false,
                            resource: details.recommendations!.results.map((e) {
                              return ZxyMedia(
                                imdbRatings: e.imdbRatings,
                                name: e.name,
                                adult: e.adult ?? false,
                                genreIds: e.genreIds ?? [],
                                type: ZxyMediaType.movie,
                                id: e.id,
                                originalLanguage: "",
                                overview: "",
                                popularity: e.popularity,
                                posterPath: e.posterPath ?? "",
                                voteAverage: e.voteAverage,
                                voteCount: null,
                              );
                            }).toList(),
                            title: "You may also like",
                            onTap: (media) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.seriesView,
                                arguments: SeriesViewData(id: media.id),
                              );
                            },
                          ),
                        ],

                        screenInfo.shouldRenderMobile
                            ? AppTheme.boxHeightS
                            : AppTheme.boxHeightL,
                        if (details.similar != null &&
                            details.similar!.results.isNotEmpty) ...[
                          screenInfo.shouldRenderMobile
                              ? AppTheme.boxHeightM
                              : AppTheme.boxHeightL,
                          LibraryList(
                            updateColorOnHover: false,
                            resource: details.similar!.results.map((e) {
                              return ZxyMedia(
                                imdbRatings: e.imdbRatings,
                                name: e.name,
                                adult: e.adult ?? false,
                                genreIds: e.genreIds ?? [],
                                type: ZxyMediaType.movie,
                                id: e.id,
                                originalLanguage: "",
                                overview: "",
                                popularity: e.popularity,
                                posterPath: e.posterPath ?? "",
                                voteAverage: e.voteAverage,
                                voteCount: null,
                              );
                            }).toList(),
                            title: "Similar Shows",
                            onTap: (media) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.seriesView,
                                arguments: SeriesViewData(id: media.id),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class EpisodesList extends StatelessWidget {
  const EpisodesList({
    super.key,
    required this.season,
    required this.vm,
    required this.episodeWidth,
    required this.episodeHeight,
    required this.renderMobile,
    required this.color,
    required this.id,
  });

  final Season season;
  final int id;
  final SeriesViewModel vm;
  final double episodeWidth;
  final double episodeHeight;
  final bool renderMobile;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: vm.progress,
      builder: (_, progressMap, _) {
        return Visibility(
          replacement: Column(
            spacing: AppTheme.spacingM,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(season.episodes.length, (index) {
              final episode = season.episodes[index];
              final seasonsKey = "$id:${season.seasonNumber}";
              final mapKey =
                  "$id:${season.seasonNumber}:${episode.episodeNumber}";
              return GestureDetector(
                key: ValueKey(mapKey),
                onLongPressStart: (details) {
                  if (episode.airDate == null ||
                      episode.airDate!.isAfter(DateTime.now())) {
                    return;
                  }
                  _showWatchedContextMenu(
                    context,
                    details.globalPosition,

                    () {
                      vm.onMarkWatched(mapKey);
                    },
                    () {
                      vm.onMarkWatched(seasonsKey);
                    },
                  );
                },
                onSecondaryTapUp: (details) {
                  if (episode.airDate == null ||
                      episode.airDate!.isAfter(DateTime.now())) {
                    return;
                  }
                  _showWatchedContextMenu(
                    context,
                    details.globalPosition,

                    () {
                      vm.onMarkWatched(mapKey);
                    },
                    () {
                      vm.onMarkWatched(seasonsKey);
                    },
                  );
                },
                onTap: () {
                  vm.onEpisodeSelect(index);
                  if (context
                      .read<UserBloc>()
                      .profileNotifier
                      .value!
                      .debridType
                      .isEmpty) {
                    showToast(context, true, "Setup debrid service first", "");
                    return;
                  }
                  Navigator.pushNamed(
                    context,
                    AppRoutes.videoPlayerView,
                    arguments: vm,
                  );
                },
                child: SizedBox(
                  height: episodeHeight,
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EpisodeImage(
                            episode: episode,
                            progress: progressMap[mapKey],
                            // radius: AppTheme.roundedSmall,
                            // enableShadow: true,
                            // animate: false,
                            episodeWidth: episodeWidth,
                            episodeHeight: episodeHeight,
                            size: "w185",
                          ),
                          AppTheme.boxWidthS,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${episode.episodeNumber}. ${episode.name}",
                                  maxLines: 2,
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(color: AppTheme.textPrimary),
                                ),
                                Expanded(
                                  child: Text(
                                    episode.overview,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(fontSize: 10),
                                  ),
                                ),
                                if (episode.runtime != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.av_timer_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 16,
                                      ),
                                      Text(
                                        "${episode.runtime} min",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall!
                                            .copyWith(fontSize: 10),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (episode.airDate == null ||
                          episode.airDate!.isAfter(DateTime.now()))
                        Positioned(
                          right: 15,
                          top: 15,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: AppTheme.roundedSmall,
                            ),
                            padding: const EdgeInsets.all(AppTheme.spacingS),
                            child: Text(
                              "Upcoming",
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge!.copyWith(fontSize: 8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
          visible: !renderMobile,
          child: Wrap(
            spacing: AppTheme.spacingL,
            runSpacing: AppTheme.spacingL,
            direction: Axis.horizontal,
            children: List.generate(season.episodes.length, (index) {
              final episode = season.episodes[index];
              final seasonsKey = "$id:${season.seasonNumber}";
              final mapKey =
                  "$id:${season.seasonNumber}:${episode.episodeNumber}";
              return MouseRegion(
                key: ValueKey(mapKey),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onLongPressStart: (details) {
                    if (episode.airDate == null ||
                        episode.airDate!.isAfter(DateTime.now())) {
                      return;
                    }
                    _showWatchedContextMenu(
                      context,
                      details.globalPosition,
                      () {
                        vm.onMarkWatched(mapKey);
                      },
                      () {
                        vm.onMarkWatched(seasonsKey);
                      },
                    );
                  },
                  onSecondaryTapUp: (details) {
                    if (episode.airDate == null ||
                        episode.airDate!.isAfter(DateTime.now())) {
                      return;
                    }
                    _showWatchedContextMenu(
                      context,
                      details.globalPosition,
                      () {
                        vm.onMarkWatched(mapKey);
                      },
                      () {
                        vm.onMarkWatched(seasonsKey);
                      },
                    );
                  },
                  onTap: () {
                    vm.onEpisodeSelect(index);
                    if (context
                        .read<UserBloc>()
                        .profileNotifier
                        .value!
                        .debridType
                        .isEmpty) {
                      showToast(
                        context,
                        true,
                        "Setup debrid service first",
                        "",
                      );
                      return;
                    }
                    Navigator.pushNamed(
                      context,
                      AppRoutes.videoPlayerView,
                      arguments: vm,
                    );
                  },
                  child: SizedBox(
                    width: episodeWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: episodeWidth,
                          height: episodeHeight,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: EpisodeImage(
                                  progress: progressMap[mapKey],
                                  size: "w300",
                                  episodeWidth: episodeWidth,
                                  episodeHeight: episodeHeight,
                                  episode: episode,
                                ),
                              ),
                              if (episode.airDate == null ||
                                  episode.airDate!.isAfter(DateTime.now()))
                                Positioned(
                                  right: 20,
                                  top: 20,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: AppTheme.roundedSmall,
                                    ),
                                    padding: const EdgeInsets.all(
                                      AppTheme.spacingS,
                                    ),
                                    child: Text(
                                      "Upcoming",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(fontSize: 10),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        AppTheme.boxHeightS,
                        Text(
                          "${episode.episodeNumber}. ${episode.name}",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          episode.overview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        if (episode.runtime != null)
                          Row(
                            children: [
                              Icon(
                                Icons.av_timer_outlined,
                                color: AppTheme.textSecondary,
                                size: 18,
                              ),
                              Text(
                                " ${episode.runtime} min",
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  void _showWatchedContextMenu(
    BuildContext context,
    Offset globalPosition,
    VoidCallback onMarkTap,
    VoidCallback onRestMarkTap,
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
            onRestMarkTap();
          },
          child: Text("Mark Rest as Watched"),
        ),
      ],
    );
  }
}

class EpisodeImage extends StatelessWidget {
  const EpisodeImage({
    super.key,
    required this.episodeWidth,
    required this.episodeHeight,
    required this.episode,
    required this.progress,
    required this.size,
  });

  final double episodeWidth;
  final double episodeHeight;
  final Episode episode;
  final String size;
  final ValueNotifier<WatchProgress>? progress;

  @override
  Widget build(BuildContext context) {
    final ScreenData screenData = Screen.of(context);
    return Container(
      height: episodeHeight,
      width: episodeWidth,
      decoration: BoxDecoration(borderRadius: AppTheme.roundedSmall),
      child: Stack(
        children: [
          Positioned.fill(
            child: ZxyImage(
              radius: AppTheme.roundedSmall,
              enableShadow: true,
              animate: false,
              width: episodeWidth,
              height: episodeHeight,
              path: episode.stillPath ?? "",
              size: size,
            ),
          ),
          if (progress != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder(
                valueListenable: progress!,
                builder: (_, progress, _) {
                  if (progress.progress == 0) {
                    return SizedBox.shrink();
                  }

                  return LinearProgressIndicator(
                    value: progress.progress / 100,
                    backgroundColor: AppTheme.surfaceLight,
                    color: AppTheme.textPrimary,
                    minHeight: 4,
                  );
                },
              ),
            ),
          if (progress != null)
            Positioned(
              top: screenData.shouldRenderMobile ? 5 : 10,
              right: screenData.shouldRenderMobile ? 5 : 10,
              child: ValueListenableBuilder(
                valueListenable: progress!,
                builder: (_, progress, _) {
                  if (!progress.isWatched) {
                    return SizedBox.shrink();
                  }
                  return Icon(
                    Icons.check_circle,
                    size: screenData.shouldRenderMobile ? 18 : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class MediaBackButton extends StatelessWidget {
  const MediaBackButton({super.key, required this.radius});
  final double radius;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        height: radius * 2,
        width: radius * 2,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.6),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(Icons.arrow_back),
      ),
    );
  }
}
