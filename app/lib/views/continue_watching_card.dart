import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';

class ContinueWatchingCard extends StatelessWidget {
  final ContinueWatchingCardInfo info;
  final VoidCallback onTap;

  const ContinueWatchingCard({
    super.key,
    required this.info,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String? backdropPath;
    String? title;
    late final SeriesDetails series;
    late final MovieDetails movie;
    late final bool isShow;

    if (info.isShow) {
      isShow = true;
      series = info.media as SeriesDetails;
      backdropPath = series.backdropPath;
      title = series.name;
    } else {
      isShow = false;
      movie = info.media as MovieDetails;
      backdropPath = movie.backdropPath;
      title = movie.title;
    }
    return InkWell(
      onHover: (_) {
        context.read<ImageBloc>().setGradColorFromImage(backdropPath!);
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: onTap,
      child: SizedBox(
        width: 420, // Adjust width as needed for horizontal list
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ZxyImage(
                    enableShadow: true,
                    path: backdropPath,
                    size: "w780", // Using a decent size for backdrop
                    isPoster: false,
                    fit: BoxFit.cover,
                    radius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  Positioned(
                    bottom: AppTheme.spacingL,
                    left: AppTheme.spacingL,
                    right: AppTheme.spacingL,
                    child: LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      value: info.progress.progress / 100,
                      backgroundColor: AppTheme.surfaceLight,
                      color: AppTheme.textPrimary,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            AppTheme.boxHeightS,
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(),
                ),
                if (isShow)
                  Builder(
                    builder: (context) {
                      final splitted = info.progress.mediaId.split(":");
                      return Text(
                        " S${splitted[1].padLeft(2, '0')}:E${splitted[2].padLeft(2, '0')}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(),
                      );
                    },
                  ),
                if (!isShow) const SizedBox(height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
