import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';

class LibraryListItem extends StatelessWidget {
  const LibraryListItem({
    super.key,
    required this.resource,
    required this.onTap,
  });

  final List<ZxyMedia> resource;
  final void Function(ZxyMedia) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: ListView.separated(
        separatorBuilder: (_, _) {
          return SizedBox(width: AppTheme.spacingXL);
        },
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          return Align(
            alignment: Alignment.topCenter,
            child: LibraryCard(
              resource: resource[index],
              onTap: onTap,
              height: 240,
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
  final double width;
  const LibraryCard({
    super.key,
    required this.resource,
    required this.onTap,
    this.height = 240,
    this.width = 160,
  });

  final ZxyMedia resource;
  final void Function(ZxyMedia) onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: Colors.transparent,
      onHover: (entered) {
        if (entered) {
          context.read<ImageBloc>().setGradColorFromImage(resource.posterPath);
        }
      },
      onTap: () {
        onTap(resource);
      },
      child: ZxyImage(
        enableShadow: true,
        height: height,
        width: width,
        isPoster: true,
        path: resource.posterPath,
        radius: AppTheme.roundedMedium,
        size: "w185",
      ),
    );
  }
}
