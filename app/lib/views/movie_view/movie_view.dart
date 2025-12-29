import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/movie_view/movie_view_model.dart';
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

  @override
  void initState() {
    super.initState();
    vm = context.read<MovieViewModel>();
    vm.initialise(widget.movie);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: ValueListenableBuilder(
        valueListenable: context.read<ImageBloc>().bgGradColor,
        builder: (_, color, _) {
          return AnimatedContainer(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            duration: const Duration(seconds: 1),
            height: double.maxFinite,
            width: double.maxFinite,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: color != null
                    ? [color.withOpacity(0.3), AppTheme.backgroundDark]
                    : [AppTheme.backgroundDark, AppTheme.backgroundDark],
                stops: color != null ? [0.0, 1.0] : [0.0, 1.0],
              ),
            ),
            child: LayoutBuilder(
              builder: (_, constr) {
                return ValueListenableBuilder(
                  valueListenable: vm.movieDetailState,
                  builder: (_, state, _) {
                    if (state is! ItemLoaded) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final details = (state as ItemLoaded<MovieDetails>).value;
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
                                    path:
                                        "${AppConstants.tmdbImageBaseUrl}/original/${details.posterPath}",
                                    isPoster: true,
                                    size: "",
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
                                          details.voteAverage.toStringAsFixed(
                                            2,
                                          ),
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
                                          color: color,
                                          streamState: streamState,
                                          onStreamSelect: vm.onStreamSelect,
                                        );
                                      },
                                    ),
                                    AppTheme.boxHeightM,
                                    Text(
                                      details.overview,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
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
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
