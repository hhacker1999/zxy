import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/zxy_button.dart';
import 'package:zxy_app/views/view_item_state.dart';

class StreamRow extends StatelessWidget {
  final ValueListenable<ViewItemState<List<StreamItem>>> streamState;
  final ValueChanged<int> onStreamSelect;
  final VoidCallback onTap;
  final Color? color;
  final bool isMobile;
  final ValueListenable<int> selectedStream;
  const StreamRow({
    super.key,
    required this.streamState,
    this.isMobile = false,
    required this.onStreamSelect,
    this.color,
    required this.onTap,
    required this.selectedStream,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: streamState,
      builder: (_, value, _) {
        return Row(
          mainAxisAlignment: isMobile
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            ZxyButton(
              onTap:
                  (value is ItemLoaded<List<StreamItem>>) &&
                      (value).data.isNotEmpty
                  ? onTap
                  : null,
              color: color,
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
                    "Play",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            AppTheme.boxWidthM,
            ZxyButton(
              changeColorBaseOnTap: true,
              color: AppTheme.textPrimary,
              child: Text(
                value is ItemLoaded ? "Select stream" : "Loading Streams",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(color: Colors.black),
              ),
              onTap: () {
                showStreamSelectionDialog(
                  context,
                  color,
                  streamState,
                  onStreamSelect,
                  selectedStream.value,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

void showStreamSelectionDialog(
  BuildContext context,
  Color? color,
  ValueListenable<ViewItemState<List<StreamItem>>> notifier,
  ValueChanged<int> onStreamSelect,
  int selected,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final screenInfo = Screen.of(context);
      return Dialog(
        backgroundColor: AppTheme.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: screenInfo.shouldRenderMobile ? screenInfo.width : 600,
            minWidth: screenInfo.shouldRenderMobile ? screenInfo.width : 0.0,
            maxHeight: screenInfo.height * 0.7,
          ),
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: ValueListenableBuilder(
            valueListenable: notifier,
            builder: (context, state, _) {
              if (state is ItemLoading) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Platform.isIOS || Platform.isMacOS
                        ? CupertinoActivityIndicator()
                        : CircularProgressIndicator(),
                    AppTheme.boxHeightM,
                    Text("Loading streams..."),
                  ],
                );
              }

              if (state is ItemLoaded<List<StreamItem>>) {
                final streams = state.data;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select Stream",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                    AppTheme.boxHeightM,
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: streams.length,
                        separatorBuilder: (_, _) => AppTheme.boxHeightS,
                        itemBuilder: (context, index) {
                          final stream = streams[index];
                          final isSelected = selected == index;
                          return InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            onTap: () {
                              onStreamSelect(index);
                            },
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                              decoration: BoxDecoration(
                                border: isSelected
                                    ? Border.all(
                                        color:
                                            color ??
                                            Theme.of(context).primaryColor,
                                        width: 2,
                                      )
                                    : Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 2,
                                      ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSmall,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stream.name,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    stream.description,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }

              if (state is ItemError) {
                return Center(
                  child: Text("Error: ${(state as ItemError).error}"),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    },
  );
}
