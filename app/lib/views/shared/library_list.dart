import 'package:flutter/material.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/library_card.dart';

class LibraryList extends StatelessWidget {
  final String title;
  final bool updateColorOnHover;
  final void Function(ZxyMedia) onTap;
  const LibraryList({
    super.key,
    required this.resource,
    required this.title,
    required this.onTap,
    this.updateColorOnHover = true,
  });

  final List<ZxyMedia> resource;

  @override
  Widget build(BuildContext context) {
    final screenData = Screen.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: screenData.shouldRenderMobile
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(
          height: screenData.shouldRenderMobile
              ? AppTheme.spacingM
              : AppTheme.spacingL,
        ),
        LibraryListItem(
          resource: resource,
          onTap: onTap,
          updateColorOnHover: updateColorOnHover,
        ),
      ],
    );
  }
}
