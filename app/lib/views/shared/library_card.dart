import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/bloc/settings_bloc.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';

class LibraryListItem extends StatelessWidget {
  const LibraryListItem({
    super.key,
    required this.resource,
    required this.onTap,
    required this.updateColorOnHover,
  });

  final bool updateColorOnHover;
  final List<ZxyMedia> resource;
  final void Function(ZxyMedia) onTap;
  static const _posterAspectRatio = (2 / 3);

  @override
  Widget build(BuildContext context) {
    final ScreenData screenData = Screen.of(context);
    final double width = screenData.shouldRenderMobile ? 120 : 160;
    final double imageHeight = width / _posterAspectRatio;
    final double itemHeight =
        imageHeight + (screenData.shouldRenderMobile ? 42 : 50);
    return SizedBox(
      height: itemHeight,
      child: ValueListenableBuilder(
        valueListenable: context.read<SettingsBloc>().showPosterRatings,
        builder: (_, posterRatings, _) {
          return ListView.separated(
            separatorBuilder: (_, _) {
              return SizedBox(
                width: screenData.shouldRenderMobile
                    ? AppTheme.spacingM
                    : AppTheme.spacingXL,
              );
            },
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, index) {
              return Align(
                alignment: Alignment.topCenter,
                child: LibraryCard(
                  updateColorOnHover: updateColorOnHover,
                  resource: resource[index],
                  onTap: onTap,
                  height: itemHeight,
                  imageHeight: imageHeight,
                  width: width,
                  showRatings: posterRatings,
                ),
              );
            },
            itemCount: resource.length,
          );
        },
      ),
    );
  }
}

class LibraryCard extends StatelessWidget {
  final double height;
  final double imageHeight;
  final double width;
  final bool updateColorOnHover;
  final bool showRatings;
  final bool showMediaType;
  final double? textHeight;
  const LibraryCard({
    super.key,
    required this.resource,
    required this.onTap,
    this.height = 290,
    this.imageHeight = 240,
    this.width = 160,
    this.showRatings = true,
    this.showMediaType = false,
    required this.updateColorOnHover,
    this.textHeight,
  });

  final ZxyMedia resource;
  final void Function(ZxyMedia) onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: Colors.transparent,
      onHover: (entered) {
        if (entered && updateColorOnHover) {
          context.read<ImageBloc>().setGradColorFromImage(
            resource.posterPath,
            context,
          );
        }
      },
      onTap: () {
        onTap(resource);
      },
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: imageHeight,
              width: width,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ZxyImage(
                      cache: true,
                      enableShadow: true,
                      height: imageHeight,
                      width: width,
                      path: resource.posterPath,
                      radius: AppTheme.roundedMedium,
                      size: "w300",
                    ),
                  ),
                  if (showRatings) RatingPosterCard(resource: resource),
                  if (showMediaType) MediaTypeChip(resource: resource),
                ],
              ),
            ),
            if (textHeight == null)
              Screen.of(context).shouldRenderMobile
                  ? AppTheme.boxHeightS
                  : AppTheme.boxHeightM,
            Visibility(
              visible: textHeight == null,
              replacement: Builder(
                builder: (_) {
                  return SizedBox(
                    height: textHeight!,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        resource.name ?? resource.title ?? "",
                        maxLines: 2,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        style: Screen.of(context).shouldRenderMobile
                            ? Theme.of(context).textTheme.labelSmall!.copyWith(
                                color: AppTheme.textSecondary,
                              )
                            : Theme.of(context).textTheme.labelMedium!.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                      ),
                    ),
                  );
                }
              ),
              child: Text(
                resource.name ?? resource.title ?? "",
                maxLines: 2,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style: Screen.of(context).shouldRenderMobile
                    ? Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: AppTheme.textSecondary,
                      )
                    : Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: AppTheme.textSecondary,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RatingPosterCard extends StatelessWidget {
  const RatingPosterCard({super.key, required this.resource});

  final ZxyMedia resource;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 3,
      bottom: 3,
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingXS),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: AppTheme.roundedSmall,
          border: Border.all(color: AppTheme.textSecondary),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: AppTheme.spacingXS,
          children: [
            Text(
              resource.imdbRatings != 0
                  ? resource.imdbRatings.toString()
                  : resource.voteAverage?.toString() ?? "0",
              style: Theme.of(
                context,
              ).textTheme.labelSmall!.copyWith(fontSize: 10),
            ),
            SvgPicture.asset(
              resource.imdbRatings != 0 ? AppIcons.imdb : AppIcons.tmdb,
              height: 10,
            ),
          ],
        ),
      ),
    );
  }
}

class MediaTypeChip extends StatelessWidget {
  const MediaTypeChip({super.key, required this.resource});

  final ZxyMedia resource;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 3,
      top: 3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark.withValues(alpha: 0.8),
          borderRadius: AppTheme.roundedSmall,
          border: Border.all(
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          resource.type == ZxyMediaType.movie ? "Movie" : "Show",
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
