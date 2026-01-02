import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/views/shared/drop_down.dart';
import 'package:zxy_app/views/view_item_state.dart';

class StreamRow extends StatelessWidget {
  final ViewItemState<List<StreamItem>> streamState;
  final ValueChanged<int> onStreamSelect;
  final VoidCallback onTap;
  final Color? color;
  const StreamRow({
    super.key,
    required this.streamState,
    required this.onStreamSelect,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        InkWell(
          onTap:
              (streamState is ItemLoaded<List<StreamItem>>) &&
                  (streamState as ItemLoaded<List<StreamItem>>).data.isNotEmpty
              ? onTap
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              borderRadius: AppTheme.roundedSmall,
              color: streamState is ItemLoaded
                  ? color
                  : AppTheme.backgroundDark.withOpacity(0.3),
            ),
            child: Row(
              spacing: AppTheme.spacingS,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (streamState is ItemLoaded)
                  SvgPicture.asset(
                    AppIcons.play,
                    colorFilter: const ColorFilter.mode(
                      AppTheme.textPrimary,
                      BlendMode.srcIn,
                    ),
                    height: AppTheme.spacingM,
                  ),
                Text(
                  (streamState is ItemLoaded<List<StreamItem>>) &&
                          (streamState as ItemLoaded<List<StreamItem>>)
                              .data
                              .isNotEmpty
                      ? "Play"
                      : (streamState is ItemLoaded<List<StreamItem>>) &&
                            (streamState as ItemLoaded<List<StreamItem>>)
                                .data
                                .isEmpty
                      ? "No Streams found"
                      : "Loading Streams",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ),
        if (streamState is ItemLoaded<List<StreamItem>> &&
            (streamState as ItemLoaded<List<StreamItem>>).data.isNotEmpty) ...[
          AppTheme.boxWidthM,
          Builder(
            builder: (context) {
              final streams =
                  (streamState as ItemLoaded<List<StreamItem>>).data;
              return ModernDropdown(
                height: 40,
                initialSelection: 0,
                entries: List.generate(streams.length, (index) {
                  return DropdownMenuEntry(
                    value: index,
                    label: streams[index].description,
                  );
                }),
                onSelected: (val) {
                  if (val == null) {
                    return;
                  }
                  onStreamSelect(val);
                },
              );
            },
          ),
        ],
      ],
    );
  }
}
