import 'dart:ui';
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
        // ── Mobile: vertical list ──────────────────────────────────────────
        if (renderMobile) {
          return Column(
            spacing: AppTheme.spacingS,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(season.episodes.length, (index) {
              final episode = season.episodes[index];
              final seasonsKey = "$id:${season.seasonNumber}";
              final mapKey =
                  "$id:${season.seasonNumber}:${episode.episodeNumber}";
              final bool isUpcoming = episode.airDate == null ||
                  episode.airDate!.isAfter(DateTime.now());
              return GestureDetector(
                key: ValueKey(mapKey),
                onLongPressStart: (details) {
                  if (isUpcoming) return;
                  _showWatchedContextMenu(
                    context,
                    details.globalPosition,
                    () => vm.onMarkWatched(mapKey),
                    () => vm.onMarkWatched(seasonsKey),
                  );
                },
                onSecondaryTapUp: (details) {
                  if (isUpcoming) return;
                  _showWatchedContextMenu(
                    context,
                    details.globalPosition,
                    () => vm.onMarkWatched(mapKey),
                    () => vm.onMarkWatched(seasonsKey),
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
                child: _MobileEpisodeRow(
                  episode: episode,
                  episodeWidth: episodeWidth,
                  episodeHeight: episodeHeight,
                  progress: progressMap[mapKey],
                  isUpcoming: isUpcoming,
                ),
              );
            }),
          );
        }

        // ── Desktop: card grid ────────────────────────────────────────────
        return Wrap(
          spacing: AppTheme.spacingM,
          runSpacing: AppTheme.spacingM,
          direction: Axis.horizontal,
          children: List.generate(season.episodes.length, (index) {
            final episode = season.episodes[index];
            final seasonsKey = "$id:${season.seasonNumber}";
            final mapKey =
                "$id:${season.seasonNumber}:${episode.episodeNumber}";
            final bool isUpcoming = episode.airDate == null ||
                episode.airDate!.isAfter(DateTime.now());
            return _DesktopEpisodeCard(
              key: ValueKey(mapKey),
              episode: episode,
              episodeWidth: episodeWidth,
              episodeHeight: episodeHeight,
              progress: progressMap[mapKey],
              isUpcoming: isUpcoming,
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
              onLongPressStart: (details) {
                if (isUpcoming) return;
                _showWatchedContextMenu(
                  context,
                  details.globalPosition,
                  () => vm.onMarkWatched(mapKey),
                  () => vm.onMarkWatched(seasonsKey),
                );
              },
              onSecondaryTapUp: (details) {
                if (isUpcoming) return;
                _showWatchedContextMenu(
                  context,
                  details.globalPosition,
                  () => vm.onMarkWatched(mapKey),
                  () => vm.onMarkWatched(seasonsKey),
                );
              },
            );
          }),
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
      shape: RoundedRectangleBorder(borderRadius: AppTheme.roundedMedium),
      color: AppTheme.surfaceColor,
      items: [
        PopupMenuItem(
          onTap: onMarkTap,
          child: Row(
            spacing: AppTheme.spacingS,
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: AppTheme.successColor),
              Text("Mark as Watched",
                  style: TextStyle(color: AppTheme.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: onRestMarkTap,
          child: Row(
            spacing: AppTheme.spacingS,
            children: [
              Icon(Icons.done_all, size: 18, color: AppTheme.successColor),
              Text("Mark Rest as Watched",
                  style: TextStyle(color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile: horizontal thumbnail + info row
// ─────────────────────────────────────────────────────────────────────────────

class _MobileEpisodeRow extends StatelessWidget {
  const _MobileEpisodeRow({
    required this.episode,
    required this.episodeWidth,
    required this.episodeHeight,
    required this.progress,
    required this.isUpcoming,
  });

  final Episode episode;
  final double episodeWidth;
  final double episodeHeight;
  final ValueNotifier<WatchProgress>? progress;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppTheme.roundedMedium,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: episodeHeight,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: AppTheme.roundedMedium,
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
              width: 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Stack(
                children: [
                  EpisodeImage(
                    episode: episode,
                    progress: progress,
                    episodeWidth: episodeWidth,
                    episodeHeight: episodeHeight,
                    size: "w185",
                  ),
                  if (isUpcoming)
                    Positioned(
                      top: AppTheme.spacingS,
                      left: AppTheme.spacingS,
                      child: _UpcomingBadge(),
                    ),
                ],
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: AppTheme.spacingS,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Episode badge + title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: AppTheme.roundedXSmall,
                            ),
                            child: Text(
                              "E${episode.episodeNumber}",
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          AppTheme.boxWidthXS,
                          Expanded(
                            child: Text(
                              episode.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppTheme.boxHeightXS,
                      // Overview
                      Expanded(
                        child: Text(
                          episode.overview,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary.withOpacity(0.85),
                            height: 1.5,
                          ),
                        ),
                      ),
                      // Runtime · Air date  (single row)
                      Row(
                        spacing: 4,
                        children: [
                          if (episode.runtime != null) ...[
                            Icon(
                              Icons.schedule_rounded,
                              size: 10,
                              color: AppTheme.textDisabled,
                            ),
                            Text(
                              "${episode.runtime}m",
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.textDisabled,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                          if (episode.runtime != null && episode.airDate != null)
                            Text(
                              "·",
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.textDisabled.withOpacity(0.6),
                              ),
                            ),
                          if (episode.airDate != null) ...[
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 10,
                              color: AppTheme.textDisabled,
                            ),
                            Flexible(
                              child: Text(
                                DateFormat('MMM d, yyyy').format(episode.airDate!),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.textDisabled,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop: card with hover overlay
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopEpisodeCard extends StatefulWidget {
  const _DesktopEpisodeCard({
    super.key,
    required this.episode,
    required this.episodeWidth,
    required this.episodeHeight,
    required this.progress,
    required this.isUpcoming,
    required this.onTap,
    required this.onLongPressStart,
    required this.onSecondaryTapUp,
  });

  final Episode episode;
  final double episodeWidth;
  final double episodeHeight;
  final ValueNotifier<WatchProgress>? progress;
  final bool isUpcoming;
  final VoidCallback onTap;
  final void Function(LongPressStartDetails) onLongPressStart;
  final void Function(TapUpDetails) onSecondaryTapUp;

  @override
  State<_DesktopEpisodeCard> createState() => _DesktopEpisodeCardState();
}

class _DesktopEpisodeCardState extends State<_DesktopEpisodeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPressStart: widget.onLongPressStart,
        onSecondaryTapUp: widget.onSecondaryTapUp,
        child: SizedBox(
          width: widget.episodeWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail card ───────────────────────────────────────────
              ClipRRect(
                borderRadius: AppTheme.roundedMedium,
                child: SizedBox(
                  width: widget.episodeWidth,
                  height: widget.episodeHeight,
                  child: Stack(
                    children: [
                      // Base image with progress/watched indicators
                      Positioned.fill(
                        child: EpisodeImage(
                          progress: widget.progress,
                          size: "w300",
                          episodeWidth: widget.episodeWidth,
                          episodeHeight: widget.episodeHeight,
                          episode: widget.episode,
                        ),
                      ),
                      // Hover overlay with blurred play button
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _hovered ? 1.0 : 0.0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.15),
                                Colors.black.withOpacity(0.70),
                              ],
                            ),
                          ),
                          child: Center(
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.35),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Upcoming badge
                      if (widget.isUpcoming)
                        Positioned(
                          top: AppTheme.spacingS,
                          left: AppTheme.spacingS,
                          child: _UpcomingBadge(),
                        ),
                    ],
                  ),
                ),
              ),
              // ── Episode info below thumbnail ─────────────────────────────
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Episode number badge
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: AppTheme.roundedXSmall,
                      ),
                      child: Text(
                        "${widget.episode.episodeNumber}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  AppTheme.boxWidthS,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.episode.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        // Runtime · Air date (single row)
                        if (widget.episode.runtime != null ||
                            widget.episode.airDate != null) ...[  
                          const SizedBox(height: 3),
                          Row(
                            spacing: 4,
                            children: [
                              if (widget.episode.runtime != null) ...[
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 11,
                                  color: AppTheme.textDisabled,
                                ),
                                Text(
                                  "${widget.episode.runtime}m",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textDisabled,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                              if (widget.episode.runtime != null &&
                                  widget.episode.airDate != null)
                                Text(
                                  "·",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textDisabled.withOpacity(0.6),
                                  ),
                                ),
                              if (widget.episode.airDate != null) ...[
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 11,
                                  color: AppTheme.textDisabled,
                                ),
                                Text(
                                  DateFormat('MMM d, yyyy').format(widget.episode.airDate!),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textDisabled,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Overview — fixed 2-line clamp, no layout shift
              if (widget.episode.overview.isNotEmpty) ...[  
                const SizedBox(height: 5),
                Text(
                  widget.episode.overview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withOpacity(0.85),
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: "Upcoming" pill badge
// ─────────────────────────────────────────────────────────────────────────────

class _UpcomingBadge extends StatelessWidget {
  const _UpcomingBadge();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2CB67D).withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: const Text(
            "UPCOMING",
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
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
    final bool isMobile = screenData.shouldRenderMobile;
    return SizedBox(
      height: episodeHeight,
      width: episodeWidth,
      child: Stack(
        children: [
          // ── Base image ──────────────────────────────────────────────────
          Positioned.fill(
            child: ZxyImage(
              radius: AppTheme.roundedMedium,
              enableShadow: false,
              animate: false,
              width: episodeWidth,
              height: episodeHeight,
              path: episode.stillPath ?? "",
              size: size,
            ),
          ),
          // ── Progress bar (bottom gradient strip) ───────────────────────
          if (progress != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder(
                valueListenable: progress!,
                builder: (_, prog, _) {
                  if (prog.progress == 0) return const SizedBox.shrink();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // subtle gradient fade before the bar
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(AppTheme.radiusMedium),
                          bottomRight: Radius.circular(AppTheme.radiusMedium),
                        ),
                        child: LinearProgressIndicator(
                          value: prog.progress / 100,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF3D9BE9), // matches watched badge
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          // ── Watched check badge ─────────────────────────────────────────
          if (progress != null)
            Positioned(
              top: isMobile ? 5 : 8,
              right: isMobile ? 5 : 8,
              child: ValueListenableBuilder(
                valueListenable: progress!,
                builder: (_, prog, _) {
                  if (!prog.isWatched) return const SizedBox.shrink();
                  // Electric blue — visually distinct from green foliage
                  // in episode thumbnails and from the upcoming badge
                  const Color watchedColor = Color(0xFF3D9BE9);
                  return Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: watchedColor,
                      boxShadow: [
                        BoxShadow(
                          color: watchedColor.withOpacity(0.55),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: isMobile ? 10 : 13,
                      color: Colors.white,
                    ),
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
