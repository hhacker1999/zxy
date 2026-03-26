import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'video_player_view.dart';

class PlaybackSpeedChip extends StatelessWidget {
  const PlaybackSpeedChip({super.key, required ZxyPlayerState state})
    : _state = state;

  final ZxyPlayerState _state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ValueListenableBuilder<bool>(
        valueListenable: _state.isDoubleRate,
        builder: (_, isDouble, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) {
              return FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              );
            },
            child: isDouble
                ? ClipRRect(
                    key: const ValueKey('speed_chip'),
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fast_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '2x',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no_chip')),
          );
        },
      ),
    );
  }
}
