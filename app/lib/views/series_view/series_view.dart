import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/base_home_view/base_home_view.dart';
import 'package:zxy_app/views/series_view/series_view_model.dart';
import 'package:zxy_app/views/shared/base_scaffold.dart';
import 'package:zxy_app/views/shared/drop_down.dart';
import 'package:zxy_app/views/shared/stream_row.dart';
import 'package:zxy_app/views/view_item_state.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';

class ShowView extends StatefulWidget {
  final ZxyMedia show;
  const ShowView({super.key, required this.show});

  @override
  State<ShowView> createState() => _ShowViewState();
}

class _ShowViewState extends State<ShowView> {
  late final SeriesViewModel vm;
  late final TextEditingController searchController;
  final episodeDF = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    vm = context.read<SeriesViewModel>();
    searchController = TextEditingController();
    vm.initialise(widget.show);
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
              valueListenable: vm.seriesDetailState,
              builder: (_, state, _) {
                if (state is! ItemLoaded) {
                  return Center(child: CupertinoActivityIndicator());
                }
                final details = (state as ItemLoaded<SeriesDetails>).data;
                final nonEmptyCast = details.credits.cast
                    .where(
                      (member) =>
                          member.profilePath != null &&
                          member.profilePath!.isNotEmpty,
                    )
                    .toList();
                return Column(
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
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        child: ValueListenableBuilder(
                                          valueListenable:
                                              vm.episodeStreamsState,
                                          builder: (_, streamState, _) {
                                            return ValueListenableBuilder(
                                              valueListenable:
                                                  vm.activeSeasonEpisode,
                                              builder: (_, activeDetails, _) {
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      details.name,
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.headlineLarge,
                                                    ),
                                                    AppTheme.boxHeightM,
                                                    if (activeDetails.$2 !=
                                                        null)
                                                      Text(
                                                        "$Season ${activeDetails.$1 + 1} Episode ${activeDetails.$2! + 1}",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelLarge!
                                                            .copyWith(
                                                              color: AppTheme
                                                                  .textSecondary,
                                                            ),
                                                      ),
                                                    if (activeDetails.$2 !=
                                                        null)
                                                      AppTheme.boxHeightXS,
                                                    Row(
                                                      spacing:
                                                          AppTheme.spacingM,
                                                      children: [
                                                        Text(
                                                          "${details.firstAirDate.year}",
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .labelLarge!
                                                              .copyWith(
                                                                color: AppTheme
                                                                    .textSecondary,
                                                              ),
                                                        ),
                                                        // Text(
                                                        //   Duration(
                                                        //     minutes: details.,
                                                        //   ).toHourMinutes(),
                                                        //   style: Theme.of(context)
                                                        //       .textTheme
                                                        //       .labelLarge!
                                                        //       .copyWith(
                                                        //         color: AppTheme.textSecondary,
                                                        //       ),
                                                        // ),
                                                      ],
                                                    ),
                                                    AppTheme.boxHeightXS,
                                                    Row(
                                                      spacing:
                                                          AppTheme.spacingS,
                                                      children: List.generate(
                                                        details.genres.length,
                                                        (index) {
                                                          var genre = details
                                                              .genres[index];
                                                          return Text(
                                                            genre.name,
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .labelLarge!
                                                                .copyWith(
                                                                  color: AppTheme
                                                                      .textSecondary,
                                                                ),
                                                          );
                                                        },
                                                      ).toList(),
                                                    ),

                                                    AppTheme.boxHeightXS,
                                                    Row(
                                                      spacing:
                                                          AppTheme.spacingXS,
                                                      children: [
                                                        SvgPicture.network(
                                                          AppConstants
                                                              .tmdbSmallLogo,
                                                          height: 16,
                                                          colorFilter:
                                                              const ColorFilter.mode(
                                                                Color(
                                                                  0xFF01B4E4,
                                                                ),
                                                                BlendMode.srcIn,
                                                              ),
                                                        ),
                                                        Text(
                                                          details.voteAverage
                                                              .toStringAsFixed(
                                                                2,
                                                              ),
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .labelLarge!
                                                              .copyWith(
                                                                color: AppTheme
                                                                    .textSecondary,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (activeDetails.$2 !=
                                                        null) ...[
                                                      AppTheme.boxHeightL,
                                                      StreamRow(
                                                        onTap: () {
                                                          Navigator.pushNamed(
                                                            context,
                                                            AppRoutes
                                                                .videoPlayerView,
                                                            arguments: vm
                                                                .getPlayerStreams(),
                                                          );
                                                        },
                                                        color: color,
                                                        streamState:
                                                            streamState,
                                                        onStreamSelect:
                                                            vm.onStreamSelect,
                                                      ),
                                                    ],
                                                    AppTheme.boxHeightM,
                                                    Text(
                                                      details.overview,
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodyLarge,
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Spacer(flex: 3),
                                  AppTheme.boxHeightXXL,
                                  Text(
                                    "Cast and Crew",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
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
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                    color: AppTheme.textPrimary,
                                                  ),
                                            ),
                                          ],
                                        );
                                      },
                                      itemCount: nonEmptyCast.length,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AppTheme.boxWidthM,
                          // NOTE: Side Panel
                          Container(
                            width: 400,
                            height: constr.maxHeight,
                            padding: EdgeInsets.all(AppTheme.spacingM),
                            decoration: BoxDecoration(
                              borderRadius: AppTheme.roundedMedium,
                              color: Colors.black.withOpacity(0.2),
                            ),
                            child: ValueListenableBuilder(
                              valueListenable: vm.episodeStreamsState,
                              builder: (_, streamState, _) {
                                return ValueListenableBuilder(
                                  valueListenable: vm.activeSeasonEpisode,
                                  builder: (_, activeSeasonEpisode, _) {
                                    return Column(
                                      children: [
                                        ModernDropdown(
                                          initialSelection: activeSeasonEpisode
                                              .$1
                                              .toString(),
                                          entries: List.generate(
                                            vm.seasons.length,
                                            (index) {
                                              return DropdownMenuEntry(
                                                value: index.toString(),
                                                label:
                                                    "Season ${vm.seasons[index].seasonNumber}",
                                              );
                                            },
                                          ),
                                          onSelected: (val) {
                                            if (val == null) {
                                              return;
                                            }
                                            final newIndex = int.tryParse(val);
                                            if (newIndex == null) {
                                              return;
                                            }
                                            vm.onSeasonSelect(newIndex);
                                          },
                                        ),
                                        AppTheme.boxHeightL,
                                        Expanded(
                                          child: ListView.separated(
                                            key: ValueKey(
                                              activeSeasonEpisode.$1.toString(),
                                            ),
                                            itemBuilder: (_, index) {
                                              final episode = vm
                                                  .seasons[activeSeasonEpisode
                                                      .$1]
                                                  .episodes[index];
                                              return InkWell(
                                                onTap:
                                                    streamState is! ItemLoading
                                                    ? () {
                                                        vm.onEpisodeSelect(
                                                          index,
                                                        );
                                                      }
                                                    : null,
                                                child: SizedBox(
                                                  height: 70,
                                                  child: Row(
                                                    children: [
                                                      AspectRatio(
                                                        aspectRatio: 16 / 9,
                                                        child: ZxyImage(
                                                          radius: AppTheme
                                                              .roundedSmall,
                                                          path:
                                                              episode
                                                                  .stillPath ??
                                                              "",
                                                          isPoster: true,
                                                          size: "w185",
                                                        ),
                                                      ),
                                                      AppTheme.boxWidthS,
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceAround,
                                                          children: [
                                                            Text(
                                                              episode.name,
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium!
                                                                  .copyWith(
                                                                    color: AppTheme
                                                                        .textPrimary,
                                                                  ),
                                                            ),
                                                            if (episode
                                                                    .airDate !=
                                                                null)
                                                              Text(
                                                                episodeDF.format(
                                                                  episode
                                                                      .airDate!,
                                                                ),
                                                                style: Theme.of(
                                                                  context,
                                                                ).textTheme.labelSmall,
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            separatorBuilder: (_, _) {
                                              return AppTheme.boxHeightM;
                                            },
                                            itemCount: vm
                                                .seasons[activeSeasonEpisode.$1]
                                                .episodes
                                                .length,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
