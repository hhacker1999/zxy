import 'package:flutter/material.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';

class CastAndCrew extends StatelessWidget {
  const CastAndCrew({
    super.key,
    required this.castList,
    required this.renderMobile,
  });

  final List<Cast> castList;
  final bool renderMobile;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: castList.isNotEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cast and Crew",
            style: renderMobile
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.titleLarge,
          ),
          AppTheme.boxHeightM,
          SizedBox(
            height: renderMobile ? 140 : 200,
            child: ListView.separated(
              separatorBuilder: (_, _) {
                return AppTheme.boxWidthL;
              },
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                return SizedBox(
                  width: renderMobile ? 100 : 140,
                  child: Column(
                    spacing: renderMobile
                        ? AppTheme.spacingS
                        : AppTheme.spacingM,
                    children: [
                      ZxyImage(
                        radius: BorderRadius.circular(renderMobile ? 45 : 70),
                        fit: BoxFit.cover,
                        size: "",
                        height: renderMobile ? 90 : 140,
                        width: renderMobile ? 90 : 140,
                        path:
                            "https://image.tmdb.org/t/p/w185/${castList[index].profilePath}",
                      ),
                      Text(
                        castList[index].name,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: renderMobile
                            ? Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: AppTheme.textPrimary,
                              )
                            : Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                      ),
                    ],
                  ),
                );
              },
              itemCount: castList.length,
            ),
          ),
        ],
      ),
    );
  }
}
