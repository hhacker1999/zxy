import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/movie_details.dart';
import 'package:zxy_app/views/movie_view/movie_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/base_scaffold.dart';
import 'package:zxy_app/views/shared/cast_crew.dart';
import 'package:zxy_app/views/shared/library_list.dart';
import 'package:zxy_app/views/shared/media_info_banner.dart';
import 'package:zxy_app/views/shared/media_info_poster.dart';
import 'package:zxy_app/views/shared/media_view_shimmer.dart';
import 'package:zxy_app/views/shared/scale_fade_widget.dart';
import 'package:zxy_app/views/shared/stream_row.dart';
import 'package:zxy_app/views/view_item_state.dart';

class MovieView extends StatefulWidget {
  final int id;
  const MovieView({super.key, required this.id});

  @override
  State<MovieView> createState() => _MovieViewState();
}

class _MovieViewState extends State<MovieView> {
  late final MovieViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = context.read<MovieViewModel>();
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
                    child: Text(
                      "Go Back",
                      style: TextStyle(color: AppTheme.textBlack),
                    ),
                  ),
                  Text((state as ItemError).error),
                ],
              );
            }
            if (state is! ItemLoaded) {
              return MediaViewShimmer(
                isMobile: screenInfo.shouldRenderMobile,
                headerHeight: height,
              );
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
            return ScaleFadeWidget(
            initialScale: 1,
              child: SingleChildScrollView(
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
                        isInLibrary: vm.isInLibrary,
                        onLibraryToggle: () => vm.toggleLibrary(widget.id),
                      ),
                      child: SizedBox(
                        height: height,
                        child: MediaInfoBanner(
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
                          size: "original",
                          color: color,
                          isInLibrary: vm.isInLibrary,
                          onLibraryToggle: () => vm.toggleLibrary(widget.id),
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
                                  name: e.name,
                                  title: e.title,
                                  imdbRatings: e.imdbRatings,
                                  adult: e.adult ?? false,
                                  genreIds: e.genreIds ?? [],
                                  type: ZxyMediaType.movie,
                                  id: e.id,
                                  originalLanguage: "",
                                  overview: "",
                                  popularity: e.popularity,
                                  posterPath: e.posterPath,
                                  voteAverage: e.voteAverage,
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
                    
                          if (details.recommendations != null &&
                              details.recommendations!.results.isNotEmpty) ...[
                            screenInfo.shouldRenderMobile
                                ? AppTheme.boxHeightM
                                : AppTheme.boxHeightL,
                            LibraryList(
                              updateColorOnHover: false,
                              resource: details.recommendations!.results.map((
                                e,
                              ) {
                                return ZxyMedia(
                                  imdbRatings: e.imdbRatings,
                                  title: e.title,
                                  adult: e.adult ?? false,
                                  genreIds: e.genreIds ?? [],
                                  type: ZxyMediaType.movie,
                                  id: e.id,
                                  originalLanguage: "",
                                  overview: "",
                                  popularity: e.popularity,
                                  posterPath: e.posterPath,
                                  voteAverage: e.voteAverage,
                                  voteCount: null,
                                );
                              }).toList(),
                              title: "You may also like",
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
                                  imdbRatings: e.imdbRatings,
                                  title: e.title,
                                  adult: e.adult ?? false,
                                  genreIds: e.genreIds ?? [],
                                  type: ZxyMediaType.movie,
                                  id: e.id,
                                  originalLanguage: "",
                                  overview: "",
                                  popularity: e.popularity,
                                  posterPath: e.posterPath,
                                  voteAverage: e.voteAverage,
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
              ),
            );
          },
        );
      },
    );
  }
}
