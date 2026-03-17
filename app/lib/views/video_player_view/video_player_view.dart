// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/settings_bloc.dart';
import 'package:zxy_app/service/http_proxy.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/views/movie_view/movie_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/series_view/series_view_model.dart';
import 'package:zxy_app/views/shared/glass_container.dart';
import 'package:zxy_app/views/shared/toast.dart';
import 'package:zxy_app/views/video_handler.dart';
import 'package:zxy_app/views/video_player_view/loading_indicator.dart';
import 'package:zxy_app/views/video_player_view/modern_sidebar.dart';
import 'package:zxy_app/views/video_player_view/playback_speed_chip.dart';
import 'package:zxy_app/views/view_item_state.dart';

import 'mobile_player_hud.dart';

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
  final ValueNotifier<DateTime?> lastTap = ValueNotifier(null);
  final ValueNotifier<bool> isDoubleRate = ValueNotifier(false);

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
  late final ProxyManager _pm;
  bool updateLayoutToNormal = false;
  Timer? _hoverTimer;
  double pinRadius = 20;
  double progressHeight = 10;
  // NOTE: To determine zoom in or out for player fit
  double horizontalScale = 1;
  // NOTE: This is here so that when user is tapping different stream links we can check
  // in our fuction calls to only start streaming from last user selected stream
  String? _currentInternalUrl;

  @override
  void initState() {
    super.initState();
    _settingBloc = context.read<SettingsBloc>();
    _pm = context.read<ProxyManager>();
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
      //NOTE: settings for faster first frame load times
      player.setProperty('vd-lavc-threads', 'auto'),
      player.setProperty('demuxer-lavf-analyzeduration', '2'),
      player.setProperty('demuxer-lavf-probesize', '64000000'),
      player.setProperty('cache-pause', 'no'),
      player.setProperty('cache', 'yes'),
      if (Platform.isIOS || Platform.isAndroid) ...[
        player.setProperty('demuxer-max-bytes', '300MiB'),
        player.setProperty('demuxer-max-back-bytes', '10MiB'),
        player.setProperty('demuxer-readahead-secs', '120'),
      ],

      if (Platform.isMacOS || Platform.isWindows) ...[
        player.setProperty('demuxer-max-bytes', '500MiB'),
        player.setProperty('demuxer-max-back-bytes', '50MiB'),
        player.setProperty('demuxer-readahead-secs', '300'),
      ],

      // HDR to SDR tonemapping settings
      player.setProperty('icc-profile-auto', 'yes'),
      player.setProperty('tone-mapping', 'bt.2446a'),
      player.setProperty('tone-mapping-mode', 'auto'),
      player.setProperty('hdr-compute-peak', 'yes'),
      player.setProperty('target-peak', '150'),
      player.setProperty('gamut-mapping-mode', 'perceptual'),

      if (Platform.isIOS || Platform.isAndroid) ...[
        player.setProperty('scale', 'bilinear'),
        player.setProperty('cscale', 'bilinear'),
      ],
      if (Platform.isWindows || Platform.isMacOS) ...[
        player.setProperty('scale', 'spline36'),
        player.setProperty('cscale', 'spline36'),
      ],
      if (kDebugMode) player.setProperty('log-level', 'debug'),
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
      // _pm.setInternalUrl(streams[selectedStream].url);
      // _player.open(Media(streams[selectedStream].url), play: true);
      _currentInternalUrl = streams[selectedStream].url;
      widget.handler
          .getStreamUrl(streams[selectedStream].url)
          .then((url) {
            print("Final url $url");
            _player.open(Media(url), play: true);
          })
          .onError((e, _) {
            if (context.mounted) {
              showToast(context, true, e.toString(), "");
            }
          });
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
              _settingBloc.langNotifier.value &&
          track.codec?.toLowerCase() != "truehd",
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
      if (position == Duration.zero) {
        return;
      }
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

  void startOverlayTimer() {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(seconds: 4), () {
      _state.isOverlayVisible.value = false;
    });
  }

  void onHover() {
    if (!_state.isOverlayVisible.value) {
      _state.isOverlayVisible.value = true;
    }
    startOverlayTimer();
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
    // _pm.setInternalUrl(streamItem.url);
    _currentInternalUrl = streamItem.url;
    widget.handler
        .getStreamUrl(streamItem.url)
        .then((url) {
          print("Final url $url");
          _player.open(Media(url), play: true);
        })
        .onError((e, _) {
          if (context.mounted) {
            showToast(context, true, e.toString(), "");
          }
        });
    // _player.open(Media("http://127.0.0.1:6969"), play: true);
    // _player.open(Media(streamItem.url), play: _state.isPlaying.value);
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
                                onLongPressStart: (_) {
                                  if (!_state.isPlaying.value ||
                                      _state.bufferingOrLoading.value) {
                                    return;
                                  }
                                  _state.isDoubleRate.value = true;
                                  _player.setRate(2.0);
                                },
                                onLongPressEnd: (_) {
                                  if (_state.isDoubleRate.value) {
                                    _state.isDoubleRate.value = false;
                                    _player.setRate(1.0);
                                  }
                                },
                                onScaleEnd: (_) {
                                  horizontalScale = 1;
                                },
                                onScaleUpdate: (details) {
                                  final prev = horizontalScale;
                                  horizontalScale *= details.horizontalScale;
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
                                onTapUp: (details) async {
                                  final cTime = DateTime.now();
                                  final lastTap = _state.lastTap.value;
                                  _state.lastTap.value = cTime;
                                  if (lastTap != null) {
                                    final diff = cTime.difference(lastTap);
                                    final isDoubleTap =
                                        diff < Duration(milliseconds: 200);
                                    // NOTE: In mobile UI, second tap goes to
                                    // hud so we dont need to check for mobile here
                                    if (isDoubleTap &&
                                        !screenData.isMobileDevice) {
                                      if (await windowManager.isFullScreen()) {
                                        windowManager.setFullScreen(false);
                                      } else {
                                        windowManager.setFullScreen(true);
                                      }
                                      return;
                                    }
                                  }
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
                          final double shadowOffset = style.fontSize * 0.04;
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
                                  shadows: [
                                    Shadow(
                                      offset: Offset(
                                        -shadowOffset,
                                        -shadowOffset,
                                      ),
                                      color: Colors.black,
                                    ),
                                    Shadow(
                                      offset: Offset(
                                        shadowOffset,
                                        -shadowOffset,
                                      ),
                                      color: Colors.black,
                                    ),
                                    Shadow(
                                      offset: Offset(
                                        shadowOffset,
                                        shadowOffset,
                                      ),
                                      color: Colors.black,
                                    ),
                                    Shadow(
                                      offset: Offset(
                                        -shadowOffset,
                                        shadowOffset,
                                      ),
                                      color: Colors.black,
                                    ),
                                  ],
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
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: isBuffering
                                  ? const VideoBufferingIndicator()
                                  : const SizedBox.shrink(),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 0,
                        right: 0,
                        child: PlaybackSpeedChip(state: _state),
                      ),
                      if (screenData.shouldRenderMobile)
                        Positioned.fill(
                          child: ValueListenableBuilder(
                            valueListenable: _state.isOverlayVisible,
                            builder: (_, visible, _) {
                              return AnimatedVisibileOpacity(
                                visible: visible,
                                duration: const Duration(milliseconds: 400),
                                child: MobileVideoPlayerHUD(
                                  onDoubleTap: (details) {
                                    final position = details.localPosition;
                                    final center = constr.maxWidth / 2;
                                    if (position.dx > center + 20) {
                                      onSkipPressOrTap(true);
                                    }
                                    if (position.dx < center - 20) {
                                      onSkipPressOrTap(false);
                                    }
                                    startOverlayTimer();
                                  },
                                  onUserInteraction: () {
                                    startOverlayTimer();
                                  },
                                  settingsBloc: _settingBloc,
                                  onBackOrStop: onBackPress,
                                  onPauseOrPlay: onPauseOrPlay,
                                  iconHeight: constr.maxHeight * 0.1,
                                  state: _state,
                                  pinRadius: pinRadius,
                                  progressHeight: progressHeight,
                                  player: _player,
                                  onSkipForward: () => onSkipPressOrTap(true),
                                  onSkipBackward: () => onSkipPressOrTap(false),
                                ),
                              );
                            },
                          ),
                        ),
                      if (!screenData.shouldRenderMobile)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: ValueListenableBuilder(
                            valueListenable: _state.isOverlayVisible,
                            builder: (_, visible, _) {
                              return AnimatedVisibileOpacity(
                                visible: visible,
                                duration: const Duration(milliseconds: 400),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 100),
                                  child: ProgressHudWithBar(
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
