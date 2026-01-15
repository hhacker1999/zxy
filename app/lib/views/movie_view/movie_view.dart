import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/base_home_view/base_home_view.dart';
import 'package:zxy_app/views/movie_view/movie_view_model.dart';
import 'package:zxy_app/views/shared/base_scaffold.dart';
import 'package:zxy_app/views/shared/duration_extension.dart';
import 'package:zxy_app/views/shared/stream_row.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';
import 'package:zxy_app/views/view_item_state.dart';

class MovieView extends StatefulWidget {
  final ZxyMedia movie;
  const MovieView({super.key, required this.movie});

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
    vm.initialise(widget.movie);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      builder: (_, color) {
        return LayoutBuilder(
          builder: (_, constr) {
            return ValueListenableBuilder(
              valueListenable: vm.movieDetailState,
              builder: (_, state, _) {
                if (state is! ItemLoaded) {
                  return Center(child: CupertinoActivityIndicator());
                }
                final details = (state as ItemLoaded<MovieDetails>).data;
                final nonEmptyCast = details.credits.cast
                    .where(
                      (member) =>
                          member.profilePath != null &&
                          member.profilePath!.isNotEmpty,
                    )
                    .toList();
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TopHeader(
                        showBack: true,
                        searchController: searchController,
                        onSearch: () {
                          if (searchController.value.text.isNotEmpty) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.searchView,
                              arguments: searchController.value.text,
                            );
                            searchController.clear();
                          }
                        },
                      ),
                      AppTheme.boxHeightM,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 400,
                            child: AspectRatio(
                              aspectRatio: 2 / 3,
                              child: ZxyImage(
                                enableShadow: true,
                                radius: AppTheme.roundedSmall,
                                path: details.posterPath,
                                isPoster: true,
                                size: "w342",
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  details.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                                AppTheme.boxHeightM,
                                Row(
                                  spacing: AppTheme.spacingM,
                                  children: [
                                    Text(
                                      "${details.releaseDate.year}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge!
                                          .copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                    Text(
                                      Duration(
                                        minutes: details.runtime,
                                      ).toHourMinutes(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge!
                                          .copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                                AppTheme.boxHeightXS,
                                Row(
                                  spacing: AppTheme.spacingS,
                                  children: List.generate(
                                    details.genres.length,
                                    (index) {
                                      var genre = details.genres[index];
                                      return Text(
                                        genre.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge!
                                            .copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      );
                                    },
                                  ).toList(),
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
                                      details.voteAverage.toStringAsFixed(2),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge!
                                          .copyWith(
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
                                Text(
                                  details.overview,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          Spacer(flex: 3),
                        ],
                      ),
                      AppTheme.boxHeightXXL,
                      Text(
                        "Cast and Crew",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      AppTheme.boxHeightM,
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          separatorBuilder: (_, _) {
                            return AppTheme.boxWidthL;
                          },
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (_, index) {
                            return Column(
                              spacing: AppTheme.spacingM,
                              children: [
                                ZxyImage(
                                  radius: BorderRadius.circular(70),
                                  isPoster: true,
                                  fit: BoxFit.cover,
                                  size: "",
                                  height: 140,
                                  width: 140,
                                  path:
                                      "https://image.tmdb.org/t/p/w185/${nonEmptyCast[index].profilePath}",
                                ),
                                Text(
                                  nonEmptyCast[index].name,
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(color: AppTheme.textPrimary),
                                ),
                              ],
                            );
                          },
                          itemCount: nonEmptyCast.length,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
