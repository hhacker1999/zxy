// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zxy_app/app_constants.dart';

import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/settings_bloc.dart';

import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/views/movie_view/movie_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/series_view/series_view_model.dart';
import 'package:zxy_app/views/shared/glass_container.dart';
import 'package:zxy_app/views/shared/toast.dart';
import 'package:zxy_app/views/video_handler.dart';
import 'package:zxy_app/views/view_item_state.dart';
import 'package:zxy_app/views/video_player_view/modern_sidebar.dart';

class SeekValueNotifier extends ChangeNotifier
    implements ValueListenable<SeekBarInfo?> {
  SeekValueNotifier(this._value) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  @override
  SeekBarInfo get value => _value;
  SeekBarInfo _value;
  set value(SeekBarInfo newValue) {
    if (_value == newValue) {
      if (_value.playback.compareTo(newValue.playback) != 0 ||
          _value.current.compareTo(newValue.current) != 0 ||
          _value.buffered.compareTo(newValue.buffered) != 0) {
        notifyListeners();
      }

      return;
    }
    _value = newValue;
    notifyListeners();
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}

class ZxyPlayerState {
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final SeekValueNotifier seekInfo = SeekValueNotifier(SeekBarInfo());
  final ValueNotifier<VideoTrack?> videoDetails = ValueNotifier(null);
  final ValueNotifier<(List<AudioTrack>, int)?> audioDetails = ValueNotifier(
    null,
  );
  final ValueNotifier<(List<SubtitleTrack>, int)?> subtitleDetails =
      ValueNotifier(null);
  final ValueNotifier<bool> isOverlayVisible = ValueNotifier(false);
  final ValueNotifier<bool> bufferingOrLoading = ValueNotifier(true);
  final ValueNotifier<bool> settingsVisible = ValueNotifier(false);
  final ValueNotifier<int> audioDelay = ValueNotifier(0);
  final ValueNotifier<int> subtitleDelay = ValueNotifier(0);
  final ValueNotifier<BoxFit> playerFit = ValueNotifier(BoxFit.contain);

  void dispose() {
    isPlaying.dispose();
    seekInfo.dispose();
    videoDetails.dispose();
    audioDetails.dispose();
    subtitleDetails.dispose();
    audioDelay.dispose();
    subtitleDelay.dispose();
    playerFit.dispose();
  }
}

class SeekBarInfo {
  Duration playback;
  Duration current;
  Duration buffered;

  SeekBarInfo({
    this.playback = Duration.zero,
    this.current = Duration.zero,
    this.buffered = Duration.zero,
  });

  SeekBarInfo copyWith({
    Duration? playback,
    Duration? current,
    Duration? buffered,
  }) {
    return SeekBarInfo(
      playback: playback ?? this.playback,
      current: current ?? this.current,
      buffered: buffered ?? this.buffered,
    );
  }
}

class VideoPlayerView extends StatefulWidget {
  final VideoHandler handler;
  const VideoPlayerView({super.key, required this.handler});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late Player _player;
  late VideoController _controller;
  late final StreamSubscription<Tracks> _trackSub;
  late final StreamSubscription<Duration> _playbackSub;
  late final StreamSubscription<Duration> _currentSub;
  late final StreamSubscription<Duration> _bufferSub;
  late final StreamSubscription<bool> _bufferingSub;
  late final StreamSubscription<bool> _playingSub;
  late final ZxyPlayerState _state;
  late final SettingsBloc _settingBloc;
  late final MovieViewModel mVm;
  late final SeriesViewModel sVm;
  DateTime? lastTap;
  bool updateLayoutToNormal = false;
  Timer? _hoverTimer;
  double pinRadius = 20;
  double progressHeight = 10;
  // NOTE: To determine zoom in or out for player fit
  double horizontalScale = 1;

  @override
  void initState() {
    super.initState();
    _settingBloc = context.read<SettingsBloc>();
    _state = ZxyPlayerState();
    _initialiseMpvPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialMobileDeviceSetup();
      setupPlayerUpdateSubscriptions();
      _updatePlayerBasedOnStreamsUpdate();
      widget.handler.getCurrentStreamsNotifier().addListener(
        _onCurrentStreamsUpdate,
      );
    });
  }

  Future<void> _initialiseMpvPlayer() async {
    _player = Player(configuration: PlayerConfiguration());
    _controller = VideoController(
      _player,
      configuration: VideoControllerConfiguration(
        // vo: "gpu",
        hwdec: "auto",
        enableHardwareAcceleration: true,
      ),
    );

    if (widget.handler.isMovie()) {
      mVm = widget.handler as MovieViewModel;
    } else {
      sVm = widget.handler as SeriesViewModel;
    }

    _player.setPlaylistMode(PlaylistMode.none);
    var player = _player.platform as NativePlayer;
    player.setVolume(context.read<SettingsBloc>().volume.value);
    await Future.wait([
      player.setProperty('icc-profile-auto', 'yes'),
      player.setProperty('tone-mapping', 'spline'),

      player.setProperty('target-peak', 'auto'),
      player.setProperty('videotoolbox-format', 'nv12'),
      player.setProperty('tone-mapping', 'bt.2446a'),
      player.setProperty('tone-mapping-mode', 'luma'),
      player.setProperty('gamut-mapping-mode', 'clip'),

      player.setProperty('cache', 'yes'),
      player.setProperty('demuxer-max-bytes', '1024MiB'),
      player.setProperty('demuxer-max-back-bytes', '200MiB'),

      player.setProperty('scale', 'ewa_lanczossharp'),
      player.setProperty('cscale', 'ewa_lanczossharp'),
    ]);
  }

  void _onCurrentStreamsUpdate() {
    _updatePlayerBasedOnStreamsUpdate();
  }

  // NOTE: This function listens to streams and load url from strems
  void _updatePlayerBasedOnStreamsUpdate() {
    final val = widget.handler.getCurrentStreamsNotifier().value;
    if (val is ItemLoading) {
      showToast(context, false, "Loading streams", "");
    }

    if (val is ItemError) {
      showToast(context, true, "Error loading streams", "");
    }

    if (val is ItemLoaded<ZxyStreamResponse>) {
      final uhdStreams = val.data.uhd;
      final fhdStreams = val.data.fhd;
      final hdStreams = val.data.hd;
      if (uhdStreams.isEmpty && fhdStreams.isEmpty && hdStreams.isEmpty) {
        showToast(context, true, "No Streams found", "");
        Navigator.pop(context);
        return;
      }

      final selectedStream = widget.handler.getSelectedStreamNotifier().value;
      final streams = List<ZxyResolutionItem>.from(uhdStreams)
        ..addAll(fhdStreams)
        ..addAll(hdStreams);
      print("Playing url ${streams[selectedStream].url}");
      _player.open(Media(streams[selectedStream].url), play: true);
    }
  }

  void onMediaInitialized(Tracks tracks) {
    _state.videoDetails.value = tracks.video.first;
    final List<AudioTrack> audioTracks = List<AudioTrack>.from(
      tracks.audio,
    ).where((e) => e.language != null).toList();
    audioTracks.sort((a, b) {
      if (a.bitrate == null) {
        return -1;
      }
      if (b.bitrate == null) {
        return 1;
      }

      int val = b.bitrate!.compareTo(a.bitrate!);
      if (val != 0) {
        return val;
      }

      if (a.channelscount == null) {
        return -1;
      }

      if (b.channelscount == null) {
        return 1;
      }

      val = b.channelscount!.compareTo(a.channelscount!);
      return val;
    });
    int trackIndex = audioTracks.indexWhere(
      (track) =>
          track.language != null &&
          LanguageMapper.getNameFromCode(track.language!) ==
              _settingBloc.langNotifier.value,
    );
    _state.audioDetails.value = (
      audioTracks,
      trackIndex == -1 ? 0 : trackIndex,
    );
    if (audioTracks.isNotEmpty) {
      _player.setAudioTrack(audioTracks[_state.audioDetails.value!.$2]);
    }

    final subtitles = tracks.subtitle.where((e) => e.language != null).toList();
    _state.subtitleDetails.value = (subtitles, -1);
    _player.setSubtitleTrack(SubtitleTrack.no());
    _player.play().then((_) => widget.handler.onPlay());
  }

  void setupPlayerUpdateSubscriptions() {
    _trackSub = _player.stream.tracks.listen((tracks) {
      if (tracks.video.isNotEmpty ||
          tracks.audio.isNotEmpty ||
          tracks.subtitle.isNotEmpty) {
        onMediaInitialized(tracks);
      }
    });

    _playbackSub = _player.stream.position.listen((position) {
      _state.seekInfo.value = _state.seekInfo.value.copyWith(current: position);
      widget.handler.onProgress(position);
    });

    _currentSub = _player.stream.duration.listen((duration) {
      if (_state.seekInfo.value.playback == Duration.zero &&
          duration != Duration.zero &&
          widget.handler.getStartingPercentage() != 0) {
        final startDuration =
            duration.inSeconds * (widget.handler.getStartingPercentage() / 100);
        _player.seek(Duration(seconds: startDuration.floor()));
      }
      _state.seekInfo.value = _state.seekInfo.value.copyWith(
        playback: duration,
      );
      widget.handler.onDurationUpdate(duration);
    });

    _bufferSub = _player.stream.buffer.listen((buffer) {
      _state.seekInfo.value = _state.seekInfo.value.copyWith(buffered: buffer);
    });

    // _player.stream.track.listen((track) {
    //   print(track.subtitle);
    // });

    _bufferingSub = _player.stream.buffering.listen((buffering) {
      _state.bufferingOrLoading.value = buffering;
    });
    _playingSub = _player.stream.playing.listen((playing) {
      _state.isPlaying.value = playing;
    });
  }

  void onTap() {
    if (_state.settingsVisible.value) {
      _state.settingsVisible.value = false;
      return;
    }
    _state.isOverlayVisible.value = !_state.isOverlayVisible.value;
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(seconds: 4), () {
      _state.isOverlayVisible.value = false;
    });
  }

  void onHover() {
    if (!_state.isOverlayVisible.value) {
      _state.isOverlayVisible.value = true;
    }
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(seconds: 4), () {
      _state.isOverlayVisible.value = false;
    });
  }

  void onPauseOrPlay() {
    if (_state.isPlaying.value) {
      _state.isPlaying.value = false;
      _player.pause();
      widget.handler.onPause();
    } else {
      _state.isPlaying.value = true;
      _player.play();
      widget.handler.onPlay();
    }
  }

  void onVideoStreamChanged(ZxyResolutionItem streamItem) {
    _player.stop();
    _state.bufferingOrLoading.value = true;
    print("Playing url ${streamItem.url}");
    _player.open(Media(streamItem.url), play: _state.isPlaying.value);
  }

  void initialMobileDeviceSetup() {
    if (Screen.of(context).isMobileDevice) {
      updateLayoutToNormal = true;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    }
  }

  void onBackPress() {
    _player.stop();
    if (updateLayoutToNormal) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,

        overlays: SystemUiOverlay.values,
      );
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    widget.handler.getCurrentStreamsNotifier().removeListener(
      _onCurrentStreamsUpdate,
    );
    _player.stop();
    widget.handler.onStop();
    _playbackSub.cancel();
    _currentSub.cancel();
    _bufferSub.cancel();
    _bufferingSub.cancel();
    _playingSub.cancel();
    _hoverTimer?.cancel();
    _trackSub.cancel();
    _player.dispose();
    _state.dispose();
    super.dispose();
  }

  void onSkipPressOrTap(bool isRight) {
    final currDur = _state.seekInfo.value.current;
    if (isRight) {
      _player.seek(
        currDur + Duration(seconds: _settingBloc.skipDuration.value),
      );
    } else {
      _player.seek(
        currDur - Duration(seconds: _settingBloc.skipDuration.value),
      );
    }
    // onHover();
  }

  @override
  Widget build(BuildContext context) {
    final screenData = Screen.of(context);
    return PopScope(
      onPopInvokedWithResult: (handled, _) {
        if (handled) return;
        onBackPress();
      },
      canPop: false,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (_, constr) {
            pinRadius = constr.maxHeight * 0.012;
            progressHeight = constr.maxHeight * 0.01;
            return SizedBox(
              height: constr.maxHeight,
              width: constr.maxWidth,
              child: CallbackShortcuts(
                bindings: {
                  SingleActivator(LogicalKeyboardKey.space): () {
                    onPauseOrPlay();
                    onHover();
                  },
                  SingleActivator(LogicalKeyboardKey.arrowRight): () {
                    onSkipPressOrTap(true);
                  },
                  SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                    onSkipPressOrTap(false);
                  },
                  SingleActivator(LogicalKeyboardKey.arrowUp): () {
                    final currVol = _settingBloc.volume.value;
                    final volumeToSet = min(100, currVol + 10);
                    _settingBloc.volume = volumeToSet.toDouble();
                    _player.setVolume(volumeToSet.toDouble());
                    onHover();
                  },
                  SingleActivator(LogicalKeyboardKey.arrowDown): () {
                    final currVol = _settingBloc.volume.value;
                    final volumeToSet = max(0, currVol - 10);
                    _settingBloc.volume = volumeToSet.toDouble();
                    _player.setVolume(volumeToSet.toDouble());
                    onHover();
                  },
                },
                child: Focus(
                  autofocus: true,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ValueListenableBuilder(
                          valueListenable: _state.isOverlayVisible,
                          builder: (_, visible, _) {
                            return MouseRegion(
                              cursor: visible
                                  ? MouseCursor.defer
                                  : SystemMouseCursors.none,
                              onHover: (_) {
                                onHover();
                              },
                              child: GestureDetector(
                                onScaleEnd: (_) {
                                  horizontalScale = 1;
                                },
                                onScaleUpdate: (details) {
                                  final prev = horizontalScale;
                                  horizontalScale *= details.horizontalScale;
                                  print(horizontalScale);
                                  if (horizontalScale < prev) {
                                    if (_state.playerFit.value ==
                                        BoxFit.cover) {
                                      _state.playerFit.value = BoxFit.contain;
                                    }
                                  }
                                  if (horizontalScale > prev) {
                                    if (_state.playerFit.value ==
                                        BoxFit.contain) {
                                      _state.playerFit.value = BoxFit.cover;
                                    }
                                  }
                                },
                                onTapDown: (details) async {
                                  final cTime = DateTime.now();
                                  if (lastTap != null) {
                                    final diff = cTime.difference(lastTap!);
                                    final isDoubleTap =
                                        diff < Duration(milliseconds: 200);
                                    if (isDoubleTap) {
                                      if (screenData.isMobileDevice) {
                                        final position = details.localPosition;
                                        final center = constr.maxWidth / 2;
                                        if (position.dx > center + 20) {
                                          onSkipPressOrTap(true);
                                        }
                                        if (position.dx < center - 20) {
                                          onSkipPressOrTap(false);
                                        }
                                      } else {
                                        if (await windowManager
                                            .isFullScreen()) {
                                          windowManager.setFullScreen(false);
                                        } else {
                                          windowManager.setFullScreen(true);
                                        }
                                      }
                                      lastTap = cTime;
                                      return;
                                    }
                                  }
                                  lastTap = cTime;
                                  onTap();
                                },
                                child: ValueListenableBuilder(
                                  valueListenable: _state.playerFit,
                                  builder: (_, fit, _) {
                                    return Video(
                                      fill: Colors.black,
                                      fit: fit,
                                      controller: _controller,
                                      controls: NoVideoControls,
                                      width: constr.maxWidth,
                                      subtitleViewConfiguration:
                                          SubtitleViewConfiguration(
                                            visible: false,
                                          ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: _settingBloc.subFontStyle,
                        builder: (_, style, _) {
                          return Positioned(
                            bottom: style.fontPadding,
                            left: 0,
                            right: 0,
                            child: SubtitleView(
                              controller: _controller,
                              configuration: SubtitleViewConfiguration(
                                style: TextStyle(
                                  height: 1.4,
                                  fontSize: style.fontSize,
                                  letterSpacing: 0.0,
                                  wordSpacing: 0.0,
                                  color: style.color,
                                  fontWeight: FontWeight.normal,
                                  backgroundColor: Colors.transparent,
                                ),
                                textAlign: TextAlign.center,
                                padding: EdgeInsets.only(
                                  bottom: style.fontPadding,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: MultiValueListenableBuilder(
                          notifiers: [_state.bufferingOrLoading],
                          builder: (_) {
                            final isBuffering = _state.bufferingOrLoading.value;
                            return Visibility(
                              visible: isBuffering,
                              child: CupertinoActivityIndicator(),
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: screenData.shouldRenderMobile
                            ? Alignment.center
                            : Alignment.bottomCenter,
                        child: ValueListenableBuilder(
                          valueListenable: _state.isOverlayVisible,
                          builder: (_, visible, _) {
                            return AnimatedVisibileOpacity(
                              visible: visible,
                              duration: const Duration(milliseconds: 400),
                              child: Padding(
                                padding: screenData.shouldRenderMobile
                                    ? EdgeInsets.zero
                                    : const EdgeInsets.only(bottom: 100),
                                child: screenData.shouldRenderMobile
                                    ? MobileVideoPlayerHUD(
                                        settingsBloc: _settingBloc,
                                        onBackOrStop: onBackPress,
                                        onPauseOrPlay: onPauseOrPlay,
                                        iconHeight: constr.maxHeight * 0.1,
                                        state: _state,
                                        pinRadius: pinRadius,
                                        progressHeight: progressHeight,
                                        player: _player,
                                      )
                                    : ProgressHudWithBar(
                                        settingsBloc: _settingBloc,
                                        onHoverOnOverlay: () {
                                          onHover();
                                        },
                                        onBackOrStop: onBackPress,
                                        onPauseOrPlay: onPauseOrPlay,
                                        iconHeight: constr.maxHeight * 0.1,
                                        state: _state,
                                        pinRadius: pinRadius,
                                        progressHeight: progressHeight,
                                        player: _player,
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      ModernSidebar(
                        state: _state,
                        height: constr.maxHeight - 40,
                        updateAudioDelay: () {
                          final delaySec = _state.audioDelay.value / 1000;
                          (_player.platform as NativePlayer).setProperty(
                            "audio-delay",
                            delaySec.toString(),
                          );
                        },
                        handler: widget.handler,
                        updateSubDelay: () {
                          final delaySec = _state.subtitleDelay.value / 1000;
                          (_player.platform as NativePlayer).setProperty(
                            "sub-delay",
                            delaySec.toString(),
                          );
                        },
                        onVideoStreamChanged: onVideoStreamChanged,
                        streamNotifier: widget.handler
                            .getCurrentStreamsNotifier(),
                        selectedStreamNotifier: widget.handler
                            .getSelectedStreamNotifier(),
                        player: _player,
                        settingsBloc: _settingBloc,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AnimatedVisibileOpacity extends StatefulWidget {
  final Duration duration;
  final bool visible;
  final Widget child;
  const AnimatedVisibileOpacity({
    super.key,
    required this.duration,
    required this.visible,
    required this.child,
  });

  @override
  State<AnimatedVisibileOpacity> createState() =>
      _AnimatedVisibileOpacityState();
}

class _AnimatedVisibileOpacityState extends State<AnimatedVisibileOpacity> {
  late Duration duration;
  late bool visible;
  Timer? _visibleTimer;

  @override
  void initState() {
    super.initState();
    visible = widget.visible;
    duration = widget.duration;
  }

  @override
  void didUpdateWidget(covariant AnimatedVisibileOpacity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _visibleTimer?.cancel();
      duration = Duration.zero;
      visible = true;
    }
    if (!widget.visible && oldWidget.visible) {
      duration = widget.duration;
      _visibleTimer?.cancel();
      _visibleTimer = Timer(duration, () {
        setState(() {
          visible = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: duration,
        child: widget.child,
      ),
    );
  }
}

class MultiValueListenableBuilder extends StatefulWidget {
  final List<ValueListenable> notifiers;
  final Widget Function(BuildContext) builder;
  const MultiValueListenableBuilder({
    super.key,
    required this.notifiers,
    required this.builder,
  });

  @override
  State<MultiValueListenableBuilder> createState() =>
      _MultiValueListenableBuilderState();
}

class _MultiValueListenableBuilderState
    extends State<MultiValueListenableBuilder> {
  @override
  void initState() {
    super.initState();
    for (var element in widget.notifiers) {
      element.addListener(listener);
    }
  }

  @override
  void didUpdateWidget(covariant MultiValueListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notifiers.length != oldWidget.notifiers.length) {
      for (var element in oldWidget.notifiers) {
        element.removeListener(listener);
      }
      for (var element in widget.notifiers) {
        element.addListener(listener);
      }
    }
  }

  void listener() {
    setState(() {});
  }

  @override
  void dispose() {
    for (var element in widget.notifiers) {
      element.removeListener(listener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

class ProgressHudWithBar extends StatelessWidget {
  const ProgressHudWithBar({
    super.key,
    required this.onHoverOnOverlay,
    required ZxyPlayerState state,
    required this.pinRadius,
    required this.progressHeight,
    required this.onPauseOrPlay,
    required Player player,
    required this.onBackOrStop,
    required this.iconHeight,
    required this.settingsBloc,
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
  final VoidCallback onHoverOnOverlay;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => onHoverOnOverlay(),
      child: GlassContainer(
        width: 480,
        height: 84,
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingS,
        ),
        radius: AppTheme.roundedMedium,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppTheme.spacingM,
          children: [
            MultiValueListenableBuilder(
              notifiers: [_state.isPlaying, settingsBloc.volume],
              builder: (_) {
                final isPlaying = _state.isPlaying.value;
                final volume = settingsBloc.volume.value;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: AppTheme.spacingXS,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            InkWell(
                              focusColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () {
                                if (volume != 0) {
                                  settingsBloc.volume = 0;
                                  _player.setVolume(0);
                                } else {
                                  settingsBloc.volume = 100;
                                  _player.setVolume(100);
                                }
                              },
                              child: Icon(
                                volume == 0
                                    ? Icons.volume_mute
                                    : Icons.volume_up,
                                size: 16,
                                color: Colors.grey.withOpacity(0.8),
                              ),
                            ),
                            ProgressBar(
                              onPanDown: (val) {
                                val *= 100;
                                _player.setVolume(val);
                                settingsBloc.volume = val;
                              },
                              onPanUp: (val) {
                                val *= 100;
                                _player.setVolume(val);
                                settingsBloc.volume = val;
                              },
                              onPanUpdate: (val) {
                                val *= 100;
                                _player.setVolume(val);
                                settingsBloc.volume = val;
                              },
                              size: Size(72, 16),
                              height: 5,
                              pinRadius: 8,
                              pinPosition: volume / 100,
                              regions: [
                                ProgressRegion(
                                  start: 0,
                                  end: 1,
                                  color: Colors.black.withOpacity(0.4),
                                ),
                                ProgressRegion(
                                  start: 0,
                                  end: volume / 100,
                                  color: Colors.grey.withOpacity(0.4),
                                ),
                              ],
                              pinColor: Colors.grey.withOpacity(0.8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        spacing: AppTheme.spacingS,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            focusColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () {
                              onPauseOrPlay();
                            },
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 32,
                              color: Colors.grey.withOpacity(0.8),
                            ),
                          ),
                          InkWell(
                            focusColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () {
                              onBackOrStop();
                            },
                            child: Icon(
                              Icons.stop,
                              size: 22,
                              color: Colors.grey.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          focusColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onTap: () {
                            _state.settingsVisible.value =
                                !_state.settingsVisible.value;
                          },
                          child: Icon(
                            Icons.settings,
                            size: 16,
                            color: Colors.grey.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            ValueListenableBuilder(
              valueListenable: _state.seekInfo,
              builder: (_, seekInfo, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        getPlayBackInfoString(seekInfo!.current),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Colors.grey.withOpacity(0.6),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 20,
                      child: ZxyProgressBar(
                        renderMobileLayout: false,
                        player: _player,
                        state: _state,
                        pinRadius: 8,
                        progressHeight: 8,
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        getPlayBackInfoString(seekInfo.playback),
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Colors.grey.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingL,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  onBackOrStop();
                },
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXS),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const Spacer(),
              // Volume Control
              ValueListenableBuilder<double>(
                valueListenable: settingsBloc.volume,
                builder: (context, volume, child) {
                  return GestureDetector(
                    onTap: () {
                      if (volume != 0) {
                        settingsBloc.volume = 0;
                        _player.setVolume(0);
                      } else {
                        settingsBloc.volume = 100;
                        _player.setVolume(100);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingXS),
                      child: Icon(
                        volume == 0 ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: AppTheme.spacingS),
              // Settings button
              GestureDetector(
                onTap: () {
                  _state.isOverlayVisible.value = false;
                  _state.settingsVisible.value = !_state.settingsVisible.value;
                },
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXS),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
        Spacer(),
        Center(
          child: ValueListenableBuilder<bool>(
            valueListenable: _state.isPlaying,
            builder: (context, isPlaying, child) {
              return GestureDetector(
                onTap: onPauseOrPlay,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              );
            },
          ),
        ),
        Spacer(),
        Container(
          padding: const EdgeInsets.only(
            left: AppTheme.spacingM,
            right: AppTheme.spacingM,
            bottom: AppTheme.spacingL,
            top: AppTheme.spacingM,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder(
                  valueListenable: _state.seekInfo,
                  builder: (context, seekInfo, child) {
                    return Column(
                      children: [
                        SizedBox(
                          height: 28, // Larger touch target for mobile
                          child: ZxyProgressBar(
                            renderMobileLayout: true,
                            player: _player,
                            state: _state,
                            pinRadius: 10,
                            progressHeight: 5,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              getPlayBackInfoString(seekInfo!.current),
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                            ),
                            Text(
                              getPlayBackInfoString(seekInfo.playback),
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String getPlayBackInfoString(Duration duration) {
  String res = "";
  var seconds = duration.inSeconds;
  var minutes = (seconds / 60).floor();
  seconds -= (minutes * 60);
  var hours = (minutes / 60).floor();
  minutes -= (hours * 60);

  res += hours.toString().padLeft(2, "0");
  res += ":";
  res += minutes.toString().padLeft(2, "0");
  res += ":";
  res += seconds.toString().padLeft(2, "0");

  return res;
}

class ProgressRegion {
  final double start;
  final double end;
  final Color color;

  const ProgressRegion({
    required this.start,
    required this.end,
    required this.color,
  });
}

class ProgressBarPainter extends CustomPainter {
  final List<ProgressRegion> regions;
  final double height;
  final double pinPosition;
  final double pinRadius;
  final Color pinColor;

  ProgressBarPainter({
    super.repaint,
    required this.regions,
    this.height = 10,
    this.pinPosition = 0,
    this.pinRadius = 20,
    required this.pinColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final usableWidth = size.width - (2 * pinRadius);
    final paint = Paint()
      ..strokeWidth = height
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    double y = pinRadius;
    for (var element in regions) {
      paint.color = element.color;
      double startx = ((element.start) * usableWidth) + pinRadius;
      double endx = ((element.end) * usableWidth) + pinRadius;
      canvas.drawLine(Offset(startx, y), Offset(endx, y), paint);
    }
    paint.color = pinColor;
    paint.strokeWidth = 0;
    paint.style = PaintingStyle.fill;
    final x = (usableWidth * pinPosition) + pinRadius;
    canvas.drawCircle(Offset(x, y), pinRadius, paint);
  }

  @override
  bool shouldRepaint(ProgressBarPainter oldDelegate) {
    // return true;
    if (oldDelegate.height != height) {
      return true;
    }
    if (oldDelegate.pinRadius != pinRadius) {
      return true;
    }
    if (oldDelegate.pinPosition != pinPosition) {
      return true;
    }
    if (oldDelegate.regions.length != regions.length) {
      return true;
    }
    if (oldDelegate.pinColor != pinColor) {
      return true;
    }
    for (var i = 0; i < oldDelegate.regions.length; i++) {
      var old = oldDelegate.regions[i];
      var newR = regions[i];
      if (old.start != newR.start ||
          old.end != newR.end ||
          old.color != newR.color) {
        return true;
      }
    }

    return false;
  }
}

class ZxyProgressBar extends StatelessWidget {
  final ZxyPlayerState state;
  final double pinRadius;
  final double progressHeight;
  final Player player;
  final bool renderMobileLayout;
  const ZxyProgressBar({
    super.key,
    required this.state,
    required this.player,
    required this.pinRadius,
    required this.renderMobileLayout,
    required this.progressHeight,
  });

  Duration getDurationOnPositionUpdate(double val, double width) {
    final sec = state.seekInfo.value.playback.inSeconds * val;
    final dur = Duration(seconds: sec.round());
    return dur;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constr) {
        return ProgressBar(
          onPanUpdate: (val) {
            final dur = getDurationOnPositionUpdate(val, constr.maxWidth);
            state.seekInfo.value = state.seekInfo.value.copyWith(current: dur);
          },
          onPanDown: (val) {
            final dur = getDurationOnPositionUpdate(val, constr.maxWidth);
            player.pause();
            state.seekInfo.value = state.seekInfo.value.copyWith(current: dur);
            state.isPlaying.value = false;
          },
          onPanUp: (val) {
            final dur = getDurationOnPositionUpdate(val, constr.maxWidth);
            state.seekInfo.value = state.seekInfo.value.copyWith(current: dur);
            player.seek(dur);
            player.play();
            state.isPlaying.value = true;
          },
          pinPosition: state.seekInfo.value.playback == Duration.zero
              ? 0
              : (state.seekInfo.value.current.inSeconds /
                    state.seekInfo.value.playback.inSeconds),
          pinRadius: pinRadius,
          height: progressHeight,
          regions: [
            ProgressRegion(
              start: 0,
              end: 1,
              color: renderMobileLayout
                  ? Colors.grey.withOpacity(0.4)
                  : Colors.black.withOpacity(0.4),
            ),
            ProgressRegion(
              start: state.seekInfo.value.playback == Duration.zero
                  ? 0
                  : (state.seekInfo.value.current.inSeconds /
                        state.seekInfo.value.playback.inSeconds),
              end: state.seekInfo.value.buffered == Duration.zero
                  ? 0
                  : (state.seekInfo.value.buffered.inSeconds /
                        state.seekInfo.value.playback.inSeconds),
              color: renderMobileLayout
                  ? Colors.white.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.4),
            ),
            ProgressRegion(
              start: 0,
              end: state.seekInfo.value.playback == Duration.zero
                  ? 0
                  : (state.seekInfo.value.current.inSeconds /
                        state.seekInfo.value.playback.inSeconds),
              color: renderMobileLayout
                  ? Colors.white
                  : Colors.grey.withOpacity(0.4),
            ),
          ],
          pinColor: renderMobileLayout
              ? Colors.white
              : Colors.grey.withOpacity(0.8),
          size: Size(constr.maxWidth, pinRadius * 2),
        );
      },
    );
  }
}

class ProgressBar extends StatelessWidget {
  final ValueChanged<double> onPanDown;
  final ValueChanged<double> onPanUp;
  final ValueChanged<double> onPanUpdate;
  final double pinPosition;
  final List<ProgressRegion> regions;
  final double pinRadius;
  final double height;
  final Size size;
  final Color pinColor;
  const ProgressBar({
    super.key,
    required this.onPanDown,
    required this.pinColor,
    required this.onPanUp,
    required this.onPanUpdate,
    required this.pinPosition,
    required this.regions,
    required this.pinRadius,
    required this.height,
    required this.size,
  });

  double onPinMove(double x) {
    final usableWidth = size.width - (2 * pinRadius);
    double relX = x - pinRadius;
    if (relX < 0) {
      relX = 0;
    }
    if (relX > usableWidth) {
      relX = usableWidth;
    }
    final per = relX / (usableWidth);
    return per;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (val) {
          onPanUpdate(onPinMove(val.localPosition.dx));
        },
        onPanDown: (val) {
          onPanDown(onPinMove(val.localPosition.dx));
        },
        onPanEnd: (val) {
          onPanUp(onPinMove(val.localPosition.dx));
        },
        onPanCancel: () {
          onPanUp(onPinMove(pinPosition));
        },
        child: CustomPaint(
          painter: ProgressBarPainter(
            pinPosition: pinPosition,
            pinRadius: pinRadius,
            height: height,
            regions: regions,
            pinColor: pinColor,
          ),
          size: size,
        ),
      ),
    );
  }
}

class SideBarToggleList extends StatefulWidget {
  final List<String> items;
  final String title;
  final int selected;
  final ValueChanged<int> onChanged;
  const SideBarToggleList({
    super.key,
    required this.items,
    required this.onChanged,
    required this.title,
    required this.selected,
  });

  @override
  State<SideBarToggleList> createState() => _SideBarToggleListState();
}

class _SideBarToggleListState extends State<SideBarToggleList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title),
        ...List.generate(widget.items.length, (index) {
          return Row(
            spacing: AppTheme.spacingS,
            children: [
              CupertinoRadio(
                value: index,
                groupValue: widget.selected,
                onChanged: (_) {
                  widget.onChanged(index);
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onChanged(index);
                  },
                  child: Text(
                    widget.items[index],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class SettingsPlusMinusWidget extends StatelessWidget {
  final String text;
  final String value;
  final VoidCallback onPlus;
  final VoidCallback onMinus;
  const SettingsPlusMinusWidget({
    super.key,
    required this.text,
    required this.value,
    required this.onPlus,
    required this.onMinus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text),
        Row(
          children: [
            IconButton(
              onPressed: () {
                onMinus();
              },
              icon: Icon(Icons.remove, color: AppTheme.textSecondary, size: 16),
            ),
            Text(value),
            IconButton(
              onPressed: () {
                onPlus();
              },
              icon: Icon(Icons.add, color: AppTheme.textSecondary, size: 16),
            ),
          ],
        ),
      ],
    );
  }
}
