import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';

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
      child: ListView.separated(
        separatorBuilder: (_, _) {
          return SizedBox(width: AppTheme.spacingXL);
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
            ),
          );
        },
        itemCount: resource.length,
      ),
    );
  }
}

class LibraryCard extends StatelessWidget {
  final double height;
  final double imageHeight;
  final double width;
  final bool updateColorOnHover;
  const LibraryCard({
    super.key,
    required this.resource,
    required this.onTap,
    this.height = 290,
    this.imageHeight = 240,
    this.width = 160,
    required this.updateColorOnHover,
  });

  final ZxyMedia resource;
  final void Function(ZxyMedia) onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: Colors.transparent,
      onHover: (entered) {
        if (entered && updateColorOnHover) {
          context.read<ImageBloc>().setGradColorFromImage(resource.posterPath);
        }
      },
      onTap: () {
        onTap(resource);
      },
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ZxyImage(
              enableShadow: true,
              height: imageHeight,
              width: width,
              path: resource.posterPath,
              radius: AppTheme.roundedMedium,
              size: "w185",
            ),
            Screen.of(context).shouldRenderMobile
                ? AppTheme.boxHeightS
                : AppTheme.boxHeightM,
            Text(
              resource.name ?? resource.title ?? "",
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Screen.of(context).shouldRenderMobile
                  ? Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: AppTheme.textSecondary,
                    )
                  : Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: AppTheme.textSecondary,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
