import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/extensions.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/movie_details.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/shared/ratings_tag.dart';
import 'package:zxy_app/views/shared/stream_row.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';

import '../../bloc/image_bloc.dart';
import 'glass_circular_button.dart';

class MediaInfoPoster extends StatefulWidget {
  final dynamic media;
  final double height;
  final double width;
  final String size;
  final StreamRow streamRow;
  final Color? color;
  final ValueListenable<bool> isInLibrary;
  final VoidCallback onLibraryToggle;
  const MediaInfoPoster({
    super.key,
    required this.media,
    required this.height,
    required this.color,
    required this.streamRow,
    required this.width,
    required this.size,
    required this.isInLibrary,
    required this.onLibraryToggle,
  });

  @override
  State<MediaInfoPoster> createState() => _MediaInfoPosterState();
}

class _MediaInfoPosterState extends State<MediaInfoPoster> {
  late final SeriesDetails series;
  late final MovieDetails movie;
  late final bool isMovie;

  @override
  void initState() {
    super.initState();
    if (widget.media is SeriesDetails) {
      series = widget.media;
      isMovie = false;
    }
    if (widget.media is MovieDetails) {
      movie = widget.media;
      isMovie = true;
    }
  }

  String _getPosterPath() {
    return isMovie ? movie.posterPath : series.posterPath ?? '';
  }

  String _getLogo() {
    return isMovie
        ? movie.images?.logos?.getLogo()?.filePath ?? ''
        : series.images?.logos?.getLogo()?.filePath ?? '';
  }

  int? _getYear() {
    return isMovie ? movie.releaseDate.year : series.firstAirDate?.year;
  }

  List<Genre> _getGenres() {
    return isMovie ? movie.genres : series.genres;
  }

  String _formatRuntime(int minutes) {
    if (minutes <= 0) return '';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String? _getRuntimeLabel() {
    if (isMovie) {
      final rt = movie.runtime;
      if (rt <= 0) return null;
      return _formatRuntime(rt);
    } else {
      final rts = series.episodeRunTime;
      if (rts != null && rts.isNotEmpty) {
        final rt = rts.first as int?;
        if (rt != null && rt > 0) return _formatRuntime(rt);
      }
      final epRt = series.lastEpisodeToAir?.runtime;
      if (epRt != null && epRt > 0) return _formatRuntime(epRt);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final genres = _getGenres();
    final year = _getYear();
    final runtime = _getRuntimeLabel();
    final topPad = MediaQuery.of(context).viewPadding.top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero poster with everything overlaid ──────────────────────────
        SizedBox(
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster image
              ZxyImage(
                onLoad: (_) {
                  context.read<ImageBloc>().setGradColorFromImage(
                    _getPosterPath(),
                    context,
                  );
                },
                height: widget.height,
                width: widget.width,
                path: _getPosterPath(),
                size: widget.size,
              ),

              // Gradient — tall enough to cover logo + meta + chips + stream
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.97),
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.45, 0.72, 1.0],
                  ),
                ),
              ),

              // Content pinned to bottom
              Positioned(
                bottom: AppTheme.spacingL,
                left: AppTheme.spacingM,
                right: AppTheme.spacingM,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo / title
                    ZxyImage(
                      width: 160,
                      height: widget.height * 0.12,
                      path: _getLogo(),
                      size: 'w154',
                      fit: BoxFit.contain,
                      replacement: Text(
                        isMovie ? movie.title : series.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Year · runtime
                    Row(
                      children: [
                        if (year != null)
                          Text(
                            '$year',
                            style: Theme.of(context).textTheme.labelLarge!
                                .copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        if (year != null && runtime != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '·',
                              style: TextStyle(
                                color: AppTheme.textDisabled,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        if (runtime != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: AppTheme.textDisabled,
                              ),
                              Text(
                                runtime,
                                style: Theme.of(context).textTheme.labelLarge!
                                    .copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Genre chips
                    if (genres.isNotEmpty)
                      Wrap(
                        spacing: AppTheme.spacingXS,
                        runSpacing: AppTheme.spacingXS,
                        children: genres.map((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              genre.name,
                              style: Theme.of(context).textTheme.labelSmall!
                                  .copyWith(
                                    color: Colors.white.withOpacity(0.85),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 10),

                    // Ratings
                    Row(
                      spacing: AppTheme.spacingXS,
                      children: [
                        RatingTag(
                          shouldRenderMobile: true,
                          rating: isMovie
                              ? movie.imdbRatings.toString()
                              : series.imdbRatings.toString(),
                          icon: AppIcons.imdb,
                        ),
                        RatingTag(
                          shouldRenderMobile: true,
                          rating: isMovie
                              ? movie.voteAverage.toStringAsFixed(2)
                              : series.voteAverage.toStringAsFixed(2),
                          icon: AppIcons.tmdb,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Stream row
                    widget.streamRow,
                  ],
                ),
              ),

              Positioned(
                left: AppTheme.spacingM,
                top: topPad + AppTheme.spacingM,
                child: GlassCircularButton(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  icon: Icons.arrow_back_rounded,
                  size: 44,
                  iconSize: 24,
                ),
              ),
              Positioned(
                right: AppTheme.spacingM,
                top: topPad + AppTheme.spacingM,
                child: ValueListenableBuilder<bool>(
                  valueListenable: widget.isInLibrary,
                  builder: (_, inLib, _) {
                    return GlassCircularButton(
                      onTap: widget.onLibraryToggle,
                      icon: inLib
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 44,
                      iconSize: 24,
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Overview below the poster ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          child: Text(
            isMovie ? movie.overview : series.overview,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
