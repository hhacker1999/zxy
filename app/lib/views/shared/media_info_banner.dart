import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/extensions.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/movie_details.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/shared/ratings_tag.dart';
import 'package:zxy_app/views/shared/stream_row.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';

import 'glass_circular_button.dart';

class MediaInfoBanner extends StatefulWidget {
  final dynamic media;
  final double height;
  final double width;
  final String size;
  final StreamRow streamRow;
  final Color? color;
  const MediaInfoBanner({
    super.key,
    required this.media,
    required this.height,
    required this.color,
    required this.streamRow,
    required this.width,
    required this.size,
  });

  @override
  State<MediaInfoBanner> createState() => _MediaInfoBannerState();
}

class _MediaInfoBannerState extends State<MediaInfoBanner> {
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

  String _backDropPath() {
    return isMovie ? movie.backdropPath! : series.backdropPath!;
  }

  String _getLogo() {
    return isMovie
        ? movie.images?.logos?.getLogo()?.filePath ?? ""
        : series.images?.logos?.getLogo()?.filePath ?? "";
  }

  int? _getYear() {
    return isMovie ? movie.releaseDate.year : series.firstAirDate?.year;
  }

  List<Genre> _getGenres() {
    return isMovie ? movie.genres : series.genres;
  }

  /// Format movie runtime (total minutes) as "2h 14m" or "45m".
  String _formatMovieRuntime(int minutes) {
    if (minutes <= 0) return '';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Returns a human-readable runtime string, or null if unavailable.
  String? _getRuntimeLabel() {
    if (isMovie) {
      final rt = movie.runtime;
      if (rt <= 0) return null;
      return _formatMovieRuntime(rt);
    } else {
      // Prefer episodeRunTime list, fall back to lastEpisode runtime
      final rts = series.episodeRunTime;
      if (rts != null && rts.isNotEmpty) {
        final rt = rts.first as int?;
        if (rt != null && rt > 0) return _formatMovieRuntime(rt);
      }
      final epRt = series.lastEpisodeToAir?.runtime;
      if (epRt != null && epRt > 0) return _formatMovieRuntime(epRt);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final genres = _getGenres();
    final year = _getYear();
    final runtime = _getRuntimeLabel();

    return Stack(
      fit: StackFit.expand,
      children: [
        ZxyImage(
          onLoad: (_) {
            WidgetsBinding.instance.addPostFrameCallback((e) {
              context.read<ImageBloc>().setGradColorFromImage(
                _backDropPath(),
                context,
              );
            });
          },
          height: widget.height,
          width: widget.width,
          path: _backDropPath(),
          size: widget.size,
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
                path: _getLogo(),
                size: "w500",
                fit: BoxFit.contain,
                replacement: Text(
                  isMovie ? movie.title : series.name,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              AppTheme.boxHeightS,

              Row(
                children: [
                  if (year != null)
                    Text(
                      '$year',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (year != null && runtime != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                      ),
                      child: Text(
                        '·',
                        style: TextStyle(
                          color: AppTheme.textDisabled,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                  if (runtime != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
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
              AppTheme.boxHeightM,

              if (genres.isNotEmpty)
                Wrap(
                  spacing: AppTheme.spacingXS,
                  runSpacing: AppTheme.spacingXS,
                  children: genres.map((genre) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
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
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              AppTheme.boxHeightS,

              Row(
                spacing: AppTheme.spacingXS,
                children: [
                  RatingTag(
                    shouldRenderMobile: false,
                    rating: isMovie
                        ? movie.imdbRatings.toString()
                        : series.imdbRatings.toString(),
                    icon: AppIcons.imdb,
                  ),
                  RatingTag(
                    shouldRenderMobile: false,
                    rating: isMovie
                        ? movie.voteAverage.toStringAsFixed(2)
                        : series.voteAverage.toStringAsFixed(2),
                    icon: AppIcons.tmdb,
                  ),
                ],
              ),
              AppTheme.boxHeightL,

              widget.streamRow,
              AppTheme.boxHeightM,

              SizedBox(
                width: widget.width * 0.5,
                child: Text(
                  isMovie ? movie.overview : series.overview,
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
          child: GlassCircularButton(
            onTap: () {
              Navigator.pop(context);
            },
            icon: Icons.arrow_back_rounded,
            size: 44,
            iconSize: 24,
          ),
        ),
      ],
    );
  }
}
