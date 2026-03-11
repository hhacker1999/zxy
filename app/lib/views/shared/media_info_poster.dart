import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/extensions.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/movie_details.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/series_view/series_view.dart';
import 'package:zxy_app/views/shared/ratings_tag.dart';
import 'package:zxy_app/views/shared/stream_row.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';

import '../../bloc/image_bloc.dart';

class MediaInfoPoster extends StatefulWidget {
  final dynamic media;
  final double height;
  final double width;
  final String size;
  final StreamRow streamRow;
  final Color? color;
  const MediaInfoPoster({
    super.key,
    required this.media,
    required this.height,
    required this.color,
    required this.streamRow,
    required this.width,
    required this.size,
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
    return isMovie ? movie.posterPath : series.posterPath ?? "";
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
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
                      height: widget.height * 0.10,
                      path: _getLogo(),
                      size: "w154",
                      fit: BoxFit.contain,
                      replacement: Text(
                        isMovie ? movie.title : series.name,
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
                      children: List.generate(_getGenres().length, (index) {
                        var genres = _getGenres();
                        var genre = genres[index];
                        return Text(
                          "${genre.name}${index != genres.length - 1 ? ',' : ''}",
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(color: AppTheme.textSecondary),
                        );
                      }).toList(),
                    ),
                    AppTheme.boxHeightM,
                    widget.streamRow,
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
                    "${_getYear()}",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              AppTheme.boxHeightS,
              Row(
                spacing: AppTheme.spacingS,
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
              AppTheme.boxHeightS,
              Text(
                isMovie ? movie.overview : series.overview,
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
