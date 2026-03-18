import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/progress/model.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/movie_details.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/overlay_play_button.dart';

import 'package:zxy_app/views/shared/zxy_image.dart';

class ContinueWatchingCard extends StatelessWidget {
  final ContinueWatchingItem info;
  final VoidCallback onTap;
  final void Function(LongPressStartDetails) onLongPress;
  final void Function(TapUpDetails) onRightClick;

  const ContinueWatchingCard({
    super.key,
    required this.info,
    required this.onTap,
    required this.onLongPress,
    required this.onRightClick,
  });

  @override
  Widget build(BuildContext context) {
    String? backdropPath;
    String? title;
    late final bool isShow;

    if (info.media.type == ZxyMediaType.shows) {
      isShow = true;
      backdropPath = info.media.backdropPath;
      title = info.media.name;
    } else {
      isShow = false;
      backdropPath = info.media.backdropPath;
      title = info.media.title;
    }
    final screenData = Screen.of(context);
    final double width = screenData.shouldRenderMobile ? 240 : 320;
    final double imageHeight = (width * 9) / 16;

    // Calculate time remaining or percentage
    String statusText = "";
    int? runtime;

    if (info.media is SeriesDetails) {
      final s = info.media as SeriesDetails;
      if (s.episodeRunTime != null && s.episodeRunTime!.isNotEmpty) {
        runtime = s.episodeRunTime![0];
      }
    } else if (info.media is MovieDetails) {
      final m = info.media as MovieDetails;
      runtime = m.runtime;
    }

    if (runtime != null && runtime > 0) {
      final double progressPercent = info.progress.progress / 100;
      final int minutesLeft = ((runtime * (1 - progressPercent))).round();
      if (minutesLeft <= 1) {
        statusText = "Completed";
      } else {
        statusText = "$minutesLeft min left";
      }
    } else {
      // Fallback to percentage if runtime is missing
      statusText = "${(100 - info.progress.progress).round()}% left";
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onLongPressStart: (details) => onLongPress(details),
        onSecondaryTapUp: (details) => onRightClick(details),
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // THUMBNAIL CONTAINER
              Container(
                height: imageHeight,
                width: width,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  color: AppTheme.backgroundDark, // Fallback color
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    ZxyImage(
                      animate: false,
                      width: width,
                      height: imageHeight,
                      enableShadow: false,
                      path: backdropPath ?? "",
                      size: screenData.shouldRenderMobile ? "w300" : "w780",
                      fit: BoxFit.cover,
                    ),

                    // Dark Overlay for better contrast
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.4, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Play Button
                    OverlayPlayButton(),

                    // Info Overlay (Bottom of Image)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isShow)
                            Builder(
                              builder: (context) {
                                final splitted = info.progress.mediaId.split(
                                  ":",
                                );
                                final season = splitted.length > 1
                                    ? splitted[1]
                                    : "?";
                                final episode = splitted.length > 2
                                    ? splitted[2]
                                    : "?";
                                return Text(
                                  "S${season.padLeft(2, '0')} E${episode.padLeft(2, '0')}",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.8),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                          // Time Remaining / Percentage
                          Text(
                            statusText,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentColor,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.8),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Progress Bar at Bottom
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: info.progress.progress / 100,
                        color: AppTheme.accentColor,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // TITLE ONLY
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (screenData.shouldRenderMobile
                              ? Theme.of(context).textTheme.titleSmall
                              : Theme.of(context).textTheme.titleMedium)
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
