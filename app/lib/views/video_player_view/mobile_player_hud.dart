import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:zxy_app/bloc/settings_bloc.dart';
import 'package:zxy_app/views/video_player_view/video_player_view.dart';

class MobileVideoPlayerHUD extends StatelessWidget {
  const MobileVideoPlayerHUD({
    super.key,
    required ZxyPlayerState state,
    required this.pinRadius,
    required this.progressHeight,
    required this.onPauseOrPlay,
    required Player player,
    required this.onBackOrStop,
    required this.iconHeight,
    required this.settingsBloc,
    required this.onSkipForward,
    required this.onSkipBackward,
  }) : _state = state,
       _player = player;

  final ZxyPlayerState _state;
  final SettingsBloc settingsBloc;
  final double pinRadius;
  final double progressHeight;
  final Player _player;
  final double iconHeight;
  final VoidCallback onPauseOrPlay;
  final VoidCallback onBackOrStop;
  final VoidCallback onSkipForward;
  final VoidCallback onSkipBackward;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Subtle background darkening for better contrast
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.40),
          ),
        ),

        // Settings / Back Bar (Top)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _TopBar(
            state: _state,
            player: _player,
            settingsBloc: settingsBloc,
            onBackOrStop: onBackOrStop,
          ),
        ),

        // Center Play/Pause & Skips
        Center(
          child: _CenterControls(
            state: _state,
            onPauseOrPlay: onPauseOrPlay,
            onSkipForward: onSkipForward,
            onSkipBackward: onSkipBackward,
          ),
        ),

        // Bottom Progress Bar & Time
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _BottomBar(
            state: _state, 
            player: _player,
            progressHeight: progressHeight,
            pinRadius: pinRadius,
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.state,
    required this.player,
    required this.settingsBloc,
    required this.onBackOrStop,
  });

  final ZxyPlayerState state;
  final Player player;
  final SettingsBloc settingsBloc;
  final VoidCallback onBackOrStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.85), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back Button
            _GlassControlButton(
              onTap: onBackOrStop,
              icon: Icons.arrow_back_rounded,
              size: 44,
              iconSize: 24,
            ),
            const Spacer(),
            // Volume Toggle
            ValueListenableBuilder<double>(
              valueListenable: settingsBloc.volume,
              builder: (_, vol, __) => _GlassControlButton(
                onTap: () {
                  if (vol != 0) {
                    settingsBloc.volume = 0;
                    player.setVolume(0);
                  } else {
                    settingsBloc.volume = 100;
                    player.setVolume(100);
                  }
                },
                icon: vol == 0
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                size: 44,
                iconSize: 22,
              ),
            ),
            const SizedBox(width: 16),
            // Settings Toggle
            _GlassControlButton(
              onTap: () {
                state.isOverlayVisible.value = false;
                state.settingsVisible.value = !state.settingsVisible.value;
              },
              icon: Icons.more_vert_rounded,
              size: 44,
              iconSize: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterControls extends StatelessWidget {
  const _CenterControls({
    required this.state,
    required this.onPauseOrPlay,
    required this.onSkipForward,
    required this.onSkipBackward,
  });

  final ZxyPlayerState state;
  final VoidCallback onPauseOrPlay;
  final VoidCallback onSkipForward;
  final VoidCallback onSkipBackward;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: state.isPlaying,
      builder: (_, isPlaying, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SkipTap(
              onTap: onSkipBackward, 
              forward: false,
            ),
            const SizedBox(width: 70),
            _PlayPauseTap(
              isPlaying: isPlaying, 
              onTap: onPauseOrPlay,
            ),
            const SizedBox(width: 70),
            _SkipTap(
              onTap: onSkipForward, 
              forward: true,
            ),
          ],
        );
      },
    );
  }
}

class _GlassControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _GlassControlButton({
    required this.icon,
    required this.onTap,
    this.size = 50,
    this.iconSize = 28,
  });

  @override
  State<_GlassControlButton> createState() => _GlassControlButtonState();
}

class _GlassControlButtonState extends State<_GlassControlButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.size / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.2,
                ),
              ),
              child: Icon(
                widget.icon,
                color: Colors.white.withOpacity(0.95),
                size: widget.iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseTap extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  const _PlayPauseTap({required this.isPlaying, required this.onTap});

  @override
  State<_PlayPauseTap> createState() => _PlayPauseTapState();
}

class _PlayPauseTapState extends State<_PlayPauseTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(44),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
                child: Icon(
                  widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(widget.isPlaying),
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipTap extends StatefulWidget {
  final VoidCallback onTap;
  final bool forward;
  const _SkipTap({required this.onTap, required this.forward});

  @override
  State<_SkipTap> createState() => _SkipTapState();
}

class _SkipTapState extends State<_SkipTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.forward ? Icons.rotate_right_rounded : Icons.rotate_left_rounded,
                color: Colors.white.withOpacity(0.95),
                size: 44,
              ),
              const SizedBox(height: 2),
              Text(
                "10",
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.state, 
    required this.player,
    required this.progressHeight,
    required this.pinRadius,
  });

  final ZxyPlayerState state;
  final Player player;
  final double progressHeight;
  final double pinRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.9), Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 60),
      child: SafeArea(
        top: false,
        child: ValueListenableBuilder(
          valueListenable: state.seekInfo,
          builder: (_, seekInfo, __) {
            final current = seekInfo?.current ?? Duration.zero;
            final playback = seekInfo?.playback ?? Duration.zero;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      getPlayBackInfoString(current),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      getPlayBackInfoString(playback),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 0.5,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 32,
                  child: ZxyProgressBar(
                    renderMobileLayout: true,
                    player: player,
                    state: state,
                    pinRadius: pinRadius * 1.25,
                    progressHeight: progressHeight * 1.5,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
