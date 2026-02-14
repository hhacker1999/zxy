import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/progress/model.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/series_view/series_view_model.dart';
import 'package:zxy_app/views/shared/base_scaffold.dart';
import 'package:zxy_app/views/shared/cast_crew.dart';
import 'package:zxy_app/views/shared/drop_down.dart';
import 'package:zxy_app/views/shared/library_list.dart';
import 'package:zxy_app/views/shared/ratings_tag.dart';
import 'package:zxy_app/views/shared/stream_row.dart';
import 'package:zxy_app/views/shared/toast.dart';
import 'package:zxy_app/views/view_item_state.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';

import '../filter_view/filter_view_model.dart';

class ShowView extends StatefulWidget {
  final int id;
  const ShowView({super.key, required this.id});

  @override
  State<ShowView> createState() => _ShowViewState();
}

class _ShowViewState extends State<ShowView> {
  late final SeriesViewModel vm;
  final episodeDF = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    vm = context.read<SeriesViewModel>();
    vm.initialise(widget.id);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
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
                    replacement: PosterItemSeries(
                      vm: vm,
                      series: details,
                      height: height,
                      width: width,
                      size: "w500",
                      color: color,
                    ),
                    child: SizedBox(
                      height: height,
                      child: BannerItemSeries(
                        vm: vm,
                        series: details,
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
                                      initialSelection: 0,
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
                                      id: widget.id,
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
                                AppRoutes.showView,
                                arguments: media.id,
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
                                AppRoutes.showView,
                                arguments: media.id,
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
              final mapKey =
                  "$id:${season.seasonNumber}:${episode.episodeNumber}";
              return InkWell(
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
              final mapKey =
                  "$id:${season.seasonNumber}:${episode.episodeNumber}";
              return InkWell(
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
              );
            }),
          ),
        );
      },
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
    return Container(
      height: episodeHeight,
      width: episodeWidth,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: AppTheme.roundedSmall),
      child: Stack(
        children: [
          Positioned.fill(
            child: ZxyImage(
              radius: AppTheme.roundedSmall,
              enableShadow: false,
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
          Positioned(
            top: 10,
            right: 10,
            child: ValueListenableBuilder(
              valueListenable: progress!,
              builder: (_, progress, _) {
                if (!progress.isWatched) {
                  return SizedBox.shrink();
                }
                return Icon(Icons.check_circle);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PosterItemSeries extends StatelessWidget {
  final SeriesDetails series;
  final double height;
  final double width;
  final String size;
  final SeriesViewModel vm;
  final Color? color;
  const PosterItemSeries({
    super.key,
    required this.series,
    required this.height,
    required this.color,
    required this.vm,
    required this.width,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    String? logoPath;
    if ((series.images?.logos?.isNotEmpty ?? false) == true) {
      logoPath = series.images!.logos!
          .firstWhere(
            (element) => element.iso6391 == "en",
            orElse: () => series.images!.logos!.first,
          )
          .filePath;
    }

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ZxyImage(
                onLoad: (_) {
                  context.read<ImageBloc>().setGradColorFromImage(
                    series.posterPath ?? "",
                  );
                },
                height: height,
                width: width,
                path: series.posterPath ?? "",
                size: size,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.95),
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.3, 0.8],
                  ),
                ),
              ),
              Positioned(
                bottom: AppTheme.spacingL,
                left: AppTheme.spacingL,
                right: AppTheme.spacingL,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ZxyImage(
                      width: 140,
                      height: height * 0.10,
                      path: logoPath ?? "",
                      size: "w154",
                      fit: BoxFit.contain,
                      replacement: Text(
                        series.name,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                      ),
                    ),
                    AppTheme.boxHeightM,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      spacing: AppTheme.spacingS,
                      children: List.generate(series.genres.length, (index) {
                        var genre = series.genres[index];
                        return Text(
                          "${genre.name}${index != series.genres.length - 1 ? ',' : ''}",
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(color: AppTheme.textSecondary),
                        );
                      }).toList(),
                    ),
                    AppTheme.boxHeightM,
                    StreamRow(
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.videoPlayerView,
                          arguments: vm,
                        );
                        vm.onPause();
                      },
                      color: color,
                      handler: vm,
                      onStreamSelect: vm.onStreamSelect,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: AppTheme.spacingM,
                top: MediaQuery.of(context).viewPadding.top + AppTheme.spacingM,
                child: MediaBackButton(radius: 17.5),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
          child: Column(
            children: [
              AppTheme.boxHeightS,
              Row(
                spacing: AppTheme.spacingM,
                children: [
                  Text(
                    "${series.firstAirDate?.year}",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  // Text(
                  //   Duration(minutes: series.r).toHourMinutes(),
                  //   style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  //     color: AppTheme.textSecondary,
                  //   ),
                  // ),
                ],
              ),
              AppTheme.boxHeightS,
              Row(
                spacing: AppTheme.spacingS,
                children: [
                  RatingTag(
                    shouldRenderMobile: true,
                    rating: series.imdbRatings.toString(),
                    icon: AppIcons.imdb,
                  ),
                  RatingTag(
                    shouldRenderMobile: true,
                    rating: series.voteAverage.toStringAsFixed(2),
                    icon: AppIcons.tmdb,
                  ),
                ],
              ),
              AppTheme.boxHeightS,
              Text(
                series.overview,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
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

class BannerItemSeries extends StatelessWidget {
  final SeriesDetails series;
  final double height;
  final double width;
  final String size;
  final SeriesViewModel vm;
  final Color? color;
  const BannerItemSeries({
    super.key,
    required this.series,
    required this.height,
    required this.color,
    required this.vm,
    required this.width,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    String? logoPath;
    if ((series.images?.logos?.isNotEmpty ?? false) == true) {
      logoPath = series.images!.logos!
          .firstWhere(
            (element) => element.iso6391 == "en",
            orElse: () => series.images!.logos!.first,
          )
          .filePath;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ZxyImage(
          onLoad: (_) async {
            context.read<ImageBloc>().setGradColorFromImage(
              series.backdropPath!,
            );
          },
          height: height,
          width: width,
          path: series.backdropPath!,
          size: size,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.95),
                Colors.black.withOpacity(0.8),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: const [0.0, 0.3, 0.8],
            ),
          ),
        ),
        Positioned(
          bottom: AppTheme.spacingL,
          left: AppTheme.spacingL,
          right: AppTheme.spacingL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ZxyImage(
                path: logoPath ?? "",
                size: "w500",
                fit: BoxFit.contain,
                replacement: Text(
                  series.name,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              AppTheme.boxHeightM,
              Row(
                spacing: AppTheme.spacingM,
                children: [
                  Text(
                    "${series.firstAirDate?.year}",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              AppTheme.boxHeightM,
              Row(
                spacing: AppTheme.spacingS,
                children: List.generate(series.genres.length, (index) {
                  var genre = series.genres[index];
                  return Text(
                    "${genre.name}${index != series.genres.length - 1 ? ',' : ''}",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  );
                }).toList(),
              ),
              AppTheme.boxHeightXS,
              Row(
                spacing: AppTheme.spacingXS,
                children: [
                  RatingTag(
                    shouldRenderMobile: false,
                    rating: series.imdbRatings.toString(),
                    icon: AppIcons.imdb,
                  ),
                  RatingTag(
                    shouldRenderMobile: false,
                    rating: series.voteAverage.toStringAsFixed(2),
                    icon: AppIcons.tmdb,
                  ),
                ],
              ),
              AppTheme.boxHeightL,
              StreamRow(
                color: color,
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
              AppTheme.boxHeightM,
              SizedBox(
                width: width * 0.5,
                child: Text(
                  series.overview,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: AppTheme.spacingL,
          top: AppTheme.spacingL,
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back),
          ),
        ),
      ],
    );
  }
}
