import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:zxy_app/bloc/settings_bloc.dart';
import 'package:zxy_app/views/video_player_view/video_player_view.dart';

// ---------------------------------------------------------------------------
// MobileVideoPlayerHUD
// Pure gradient overlay — no cards, no pills. Netflix/Plex style.
// ---------------------------------------------------------------------------

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
        // ── Top gradient + icons ──────────────────────────────────────────
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

        // ── Center play / skip controls ───────────────────────────────────
        Center(
          child: _CenterControls(
            state: _state,
            onPauseOrPlay: onPauseOrPlay,
            onSkipForward: onSkipForward,
            onSkipBackward: onSkipBackward,
          ),
        ),

        // ── Bottom gradient + scrubber ────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _BottomBar(state: _state, player: _player),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar — back + volume + settings
// ---------------------------------------------------------------------------

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
      padding: const EdgeInsets.only(left: 12, right: 12, top: 20, bottom: 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.55), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back
            _TapIcon(
              onTap: onBackOrStop,
              icon: Icons.arrow_back_ios_new_rounded,
            ),
            const Spacer(),
            // Volume
            ValueListenableBuilder<double>(
              valueListenable: settingsBloc.volume,
              builder: (_, vol, __) => _TapIcon(
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
              ),
            ),
            const SizedBox(width: 4),
            // Settings
            _TapIcon(
              onTap: () {
                state.isOverlayVisible.value = false;
                state.settingsVisible.value = !state.settingsVisible.value;
              },
              icon: Icons.tune_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Center — ⏮10  ▶/⏸  ⏭10
// ---------------------------------------------------------------------------

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
          children: [
            _SkipTap(onTap: onSkipBackward, forward: false),
            const SizedBox(width: 40),
            _PlayPauseTap(isPlaying: isPlaying, onTap: onPauseOrPlay),
            const SizedBox(width: 40),
            _SkipTap(onTap: onSkipForward, forward: true),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Play / Pause — clean borderless icon, subtle background ring only
// ---------------------------------------------------------------------------

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
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.82,
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
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.18),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(widget.isPlaying),
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skip tap — icon only, very lean
// ---------------------------------------------------------------------------

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
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.72,
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
        child: Icon(
          widget.forward ? Icons.forward_10_rounded : Icons.replay_10_rounded,
          color: Colors.white.withOpacity(0.9),
          size: 34,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom — thin gradient strip, progress bar flush to bottom
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state, required this.player});

  final ZxyPlayerState state;
  final Player player;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.70), Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10, top: 80),
      child: SafeArea(
        top: false,
        child: ValueListenableBuilder(
          valueListenable: state.seekInfo,
          builder: (_, seekInfo, __) {
            final current = seekInfo?.current ?? Duration.zero;
            final playback = seekInfo?.playback ?? Duration.zero;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timestamps — left: elapsed, right: total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getPlayBackInfoString(current),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      getPlayBackInfoString(playback),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Scrubber — tall touch target, thin track
                SizedBox(
                  height: 24,
                  child: ZxyProgressBar(
                    renderMobileLayout: true,
                    player: player,
                    state: state,
                    pinRadius: 8,
                    progressHeight: 3,
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

// ---------------------------------------------------------------------------
// Minimal tap icon — no container, just an icon with press feedback
// ---------------------------------------------------------------------------

class _TapIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TapIcon({required this.icon, required this.onTap});

  @override
  State<_TapIcon> createState() => _TapIconState();
}

class _TapIconState extends State<_TapIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.75,
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
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(widget.icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
