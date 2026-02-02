import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/zxy_button.dart';
import 'package:zxy_app/views/video_handler.dart';
import 'package:zxy_app/views/video_player_view/video_player_view.dart';
import 'package:zxy_app/views/view_item_state.dart';

class StreamRow extends StatelessWidget {
  final VideoHandler handler;
  final ValueChanged<int> onStreamSelect;
  final VoidCallback onTap;
  final Color? color;
  final bool isMobile;
  const StreamRow({
    super.key,
    required this.handler,
    this.isMobile = false,
    required this.onStreamSelect,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      notifiers: [
        handler.getCurrentStreamsNotifier(),
        handler.getSelectedStreamNotifier(),
        handler.getProgressNotifier(),
      ],
      builder: (_) {
        final progress = handler.getProgressNotifier().value;
        final streams = handler.getCurrentStreamsNotifier().value;
        return Row(
          mainAxisAlignment: isMobile
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            ZxyButton(
              radius: AppTheme.radiusLarge,
              onTap: () {
                // if (streams is ItemLoading) {
                showStreamSelectionDialog(
                  context,
                  color,
                  handler.getCurrentStreamsNotifier(),
                  onStreamSelect,
                  handler.getSelectedStreamNotifier(),
                );
                // }
              },
              color: color,
              child: Row(
                spacing: AppTheme.spacingS,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    AppIcons.play,
                    colorFilter: const ColorFilter.mode(
                      AppTheme.textPrimary,
                      BlendMode.srcIn,
                    ),
                    height: AppTheme.spacingM,
                  ),
                  Text(
                    progress == 0 ? "Play" : "Resume",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (progress != 0) ...[
                    AppTheme.boxWidthXS,
                    SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        borderRadius: AppTheme.roundedXSmall,
                        value: progress / 100,
                        color: AppTheme.textPrimary,
                        backgroundColor: Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (streams is ItemLoading)
              LottieBuilder.asset(
                AppIcons.loading,
                height: 80,
                width: 100,
                fit: BoxFit.fill,
              ),
            if (streams is ItemLoaded<ZxyStreamResponse>)
              Builder(
                builder: (_) {
                  final streamsList = List.from(streams.data.uhd)
                    ..addAll(streams.data.fhd)
                    ..addAll(streams.data.hd);
                  if (streamsList.isEmpty) {
                    return SizedBox.shrink();
                  }
                  final selected =
                      streamsList[handler.getSelectedStreamNotifier().value];
                  return Row(
                    spacing: AppTheme.spacingS,
                    children: [
                      AppTheme.boxWidthS,
                      if (selected.resolution == "2160p")
                        SvgPicture.asset(AppIcons.uhd, height: 20, width: 80),
                      if (selected.resolution == "1080p")
                        SvgPicture.asset(AppIcons.fhd, height: 20, width: 80),
                      if (selected.resolution == "720p")
                        Text(
                          selected.resolution,
                          style: Theme.of(context).textTheme.labelSmall!
                              .copyWith(color: AppTheme.textPrimary),
                        ),
                      if (selected.visualTags.contains("HDR") ||
                          selected.visualTags.contains("HDR10") ||
                          selected.visualTags.contains("HDR10+"))
                        SvgPicture.asset(AppIcons.hdr, height: 20, width: 80),
                    ],
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
  ValueListenable<ViewItemState<ZxyStreamResponse>> notifier,
  ValueChanged<int> onStreamSelect,
  ValueListenable<int> selectedStreamNotifier,
) {
  showDialog(
    context: context,
    barrierDismissible: true,
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
          child: MultiValueListenableBuilder(
            notifiers: [notifier, selectedStreamNotifier],
            builder: (context) {
              final state = notifier.value;
              final selected = selectedStreamNotifier.value;
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
              if (state is ItemLoaded<ZxyStreamResponse>) {
                final streams = List<ZxyResolutionItem>.from(state.data.uhd)
                  ..addAll(state.data.fhd)
                  ..addAll(state.data.hd);
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
                          String streamString = stream.resolution;
                          streamString += "|${stream.quality}";
                          if (stream.visualTags.isNotEmpty) {
                            streamString += "|";
                            streamString += stream.visualTags.join("|");
                          }
                          // if (stream.audioTags.isNotEmpty) {
                          //   streamString += "|";
                          //   streamString += stream.audioTags.join("|");
                          // }
                          final sz = (stream.size ?? 0) / (1024 * 1024 * 1024);
                          streamString += "|${sz.toStringAsFixed(2)}Gb";
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
                                    streamString,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
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
