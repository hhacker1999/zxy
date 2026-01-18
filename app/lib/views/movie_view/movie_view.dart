import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/movie_details.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';
import 'package:zxy_app/views/movie_view/movie_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/base_scaffold.dart';
import 'package:zxy_app/views/shared/cast_crew.dart';
import 'package:zxy_app/views/shared/duration_extension.dart';
import 'package:zxy_app/views/shared/library_list.dart';
import 'package:zxy_app/views/shared/stream_row.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';
import 'package:zxy_app/views/view_item_state.dart';

class MovieView extends StatefulWidget {
  final int id;
  const MovieView({super.key, required this.id});

  @override
  State<MovieView> createState() => _MovieViewState();
}

class _MovieViewState extends State<MovieView> {
  late final MovieViewModel vm;
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    vm = context.read<MovieViewModel>();
    searchController = TextEditingController();
    vm.initialise(widget.id);
  }

  @override
  void dispose() {
    searchController.dispose();
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
          valueListenable: vm.movieDetailState,
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
            final details = (state as ItemLoaded<MovieDetails>).data;
            List<Cast> castList = List.empty();
            if (details.credits != null && details.credits!.cast != null) {
              castList = details.credits!.cast!
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
                    replacement: PosterItem(
                      vm: vm,
                      movie: details,
                      height: height,
                      width: width,
                      size: "w342",
                      color: color,
                    ),
                    child: SizedBox(
                      height: height,
                      child: BannerItem(
                        vm: vm,
                        movie: details,
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
                          castList: castList,
                          renderMobile: screenInfo.shouldRenderMobile,
                        ),
                        screenInfo.shouldRenderMobile
                            ? AppTheme.boxHeightS
                            : AppTheme.boxHeightL,
                        if (details.collection != null &&
                            details.collection!.parts.isNotEmpty) ...[
                          screenInfo.shouldRenderMobile
                              ? AppTheme.boxHeightM
                              : AppTheme.boxHeightL,
                          LibraryList(
                            updateColorOnHover: false,
                            resource: details.collection!.parts.map((e) {
                              return ZxyMedia(
                                adult: e.adult ?? false,
                                genreIds: e.genreIds ?? [],
                                type: ZxyMediaType.movie,
                                id: e.id,
                                originalLanguage: "",
                                overview: "",
                                popularity: e.popularity,
                                posterPath: e.posterPath,
                                voteAverage: null,
                                voteCount: null,
                              );
                            }).toList(),
                            title: details.collection!.name,
                            onTap: (media) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.movieView,
                                arguments: media.id,
                              );
                            },
                          ),
                        ],

                        if (details.similar != null &&
                            details.similar!.results.isNotEmpty) ...[
                          screenInfo.shouldRenderMobile
                              ? AppTheme.boxHeightM
                              : AppTheme.boxHeightL,
                          LibraryList(
                            updateColorOnHover: false,
                            resource: details.similar!.results.map((e) {
                              return ZxyMedia(
                                name: e.title,
                                adult: e.adult ?? false,
                                genreIds: e.genreIds ?? [],
                                type: ZxyMediaType.movie,
                                id: e.id,
                                originalLanguage: "",
                                overview: "",
                                popularity: e.popularity,
                                posterPath: e.posterPath,
                                voteAverage: null,
                                voteCount: null,
                              );
                            }).toList(),
                            title: "Similar Movies",
                            onTap: (media) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.movieView,
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

class PosterItem extends StatelessWidget {
  final MovieDetails movie;
  final double height;
  final double width;
  final String size;
  final MovieViewModel vm;
  final Color? color;
  const PosterItem({
    super.key,
    required this.movie,
    required this.height,
    required this.color,
    required this.vm,
    required this.width,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    String? logoPath;
    if ((movie.images?.logos?.isNotEmpty ?? false) == true) {
      logoPath = movie.images!.logos!
          .firstWhere(
            (element) => element.iso6391 == "en",
            orElse: () => movie.images!.logos!.first,
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
                    movie.posterPath,
                  );
                },
                height: height,
                width: width,
                path: movie.posterPath,
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
                      width: width,
                      height: height * 0.08,
                      path: logoPath ?? "",
                      size: "w500",
                      fit: BoxFit.contain,
                      replacement: Text(
                        movie.title,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ),
                    AppTheme.boxHeightM,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: AppTheme.spacingS,
                      children: List.generate(movie.genres?.length ?? 0, (
                        index,
                      ) {
                        var genre = movie.genres![index];
                        return Text(
                          "${genre.name}${index != movie.genres!.length - 1 ? ',' : ''}",
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(color: AppTheme.textSecondary),
                        );
                      }).toList(),
                    ),
                    AppTheme.boxHeightM,
                    ValueListenableBuilder(
                      valueListenable: vm.movieStreamState,
                      builder: (_, streamState, _) {
                        return StreamRow(
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              AppRoutes.videoPlayerView,
                              arguments: vm,
                            );
                            vm.onPause();
                          },
                          color: color,
                          streamState: streamState,
                          onStreamSelect: vm.onStreamSelect,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                left: AppTheme.spacingL,
                top: MediaQuery.of(context).viewPadding.top + AppTheme.spacingL,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back),
                ),
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
                    "${movie.releaseDate.year}",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    Duration(minutes: movie.runtime).toHourMinutes(),
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
                  SvgPicture.network(
                    AppConstants.tmdbSmallLogo,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF01B4E4),
                      BlendMode.srcIn,
                    ),
                  ),
                  Text(
                    movie.voteAverage.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              AppTheme.boxHeightS,
              Text(
                movie.overview,
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

class BannerItem extends StatelessWidget {
  final MovieDetails movie;
  final double height;
  final double width;
  final String size;
  final MovieViewModel vm;
  final Color? color;
  const BannerItem({
    super.key,
    required this.movie,
    required this.height,
    required this.color,
    required this.vm,
    required this.width,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    String? logoPath;
    if ((movie.images?.logos?.isNotEmpty ?? false) == true) {
      logoPath = movie.images!.logos!
          .firstWhere(
            (element) => element.iso6391 == "en",
            orElse: () => movie.images!.logos!.first,
          )
          .filePath;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ZxyImage(
          onLoad: (_) {
            context.read<ImageBloc>().setGradColorFromImage(
              movie.backdropPath!,
            );
          },
          height: height,
          width: width,
          path: movie.backdropPath!,
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
                width: width * 0.3,
                height: height * 0.3,
                path: logoPath ?? "",
                size: "w500",
                fit: BoxFit.contain,
                replacement: Text(
                  movie.title,
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
                    "${movie.releaseDate.year}",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    Duration(minutes: movie.runtime).toHourMinutes(),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              AppTheme.boxHeightM,
              Row(
                spacing: AppTheme.spacingS,
                children: List.generate(movie.genres?.length ?? 0, (index) {
                  var genre = movie.genres![index];
                  return Text(
                    "${genre.name}${index != movie.genres!.length - 1 ? ',' : ''}",
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
                  SvgPicture.network(
                    AppConstants.tmdbSmallLogo,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF01B4E4),
                      BlendMode.srcIn,
                    ),
                  ),
                  Text(
                    movie.voteAverage.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              AppTheme.boxHeightL,
              ValueListenableBuilder(
                valueListenable: vm.movieStreamState,
                builder: (_, streamState, _) {
                  return StreamRow(
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.videoPlayerView,
                        arguments: vm,
                      );
                      vm.onPause();
                    },
                    color: color,
                    streamState: streamState,
                    onStreamSelect: vm.onStreamSelect,
                  );
                },
              ),
              AppTheme.boxHeightM,
              SizedBox(
                width: width * 0.5,
                child: Text(
                  movie.overview,
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
