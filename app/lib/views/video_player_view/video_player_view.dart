// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/views/shared/glass_container.dart';
import 'package:zxy_app/views/video_handler.dart';

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

class SubtitleFontStyle {
  SubtitleFontStyle copyWith({
    double? fontSize,
    Color? color,
    double? fontPadding,
    Color? bgColor,
  }) {
    return SubtitleFontStyle(
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      fontPadding: fontPadding ?? this.fontPadding,
      bgColor: bgColor ?? this.bgColor,
    );
  }

  final double fontSize;
  final double fontPadding;
  final Color color;
  final Color bgColor;

  const SubtitleFontStyle({
    required this.fontSize,
    required this.fontPadding,
    required this.color,
    required this.bgColor,
  });
}

class ZxyPlayerState {
  final ValueListenable? a = null;
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final SeekValueNotifier seekInfo = SeekValueNotifier(SeekBarInfo());
  final ValueNotifier<VideoTrack?> videoDetails = ValueNotifier(null);
  final ValueNotifier<(List<AudioTrack>, int)?> audioDetails = ValueNotifier(
    null,
  );
  final ValueNotifier<(List<SubtitleTrack>, int)?> subtitleDetails =
      ValueNotifier(null);
  final ValueNotifier<double> volumeDetails = ValueNotifier(100);
  final ValueNotifier<bool> isOverlayVisible = ValueNotifier(false);
  final ValueNotifier<bool> buffering = ValueNotifier(true);
  final ValueNotifier<bool> settingsVisible = ValueNotifier(false);
  final ValueNotifier<int> audioDelay = ValueNotifier(0);
  final ValueNotifier<int> subtitleDelay = ValueNotifier(0);
  final ValueNotifier<SubtitleFontStyle> subtitleFontStyle = ValueNotifier(
    SubtitleFontStyle(
      fontSize: 24,
      fontPadding: 20,
      color: AppTheme.textPrimary,
      bgColor: Colors.transparent,
    ),
  );

  void dispose() {
    isPlaying.dispose();
    seekInfo.dispose();
    videoDetails.dispose();
    audioDetails.dispose();
    subtitleDetails.dispose();
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
  late final Player _player;
  late final VideoController _controller;
  late final StreamSubscription<Tracks> _trackSub;
  late final StreamSubscription<Duration> _playbackSub;
  late final StreamSubscription<Duration> _currentSub;
  late final StreamSubscription<Duration> _bufferSub;
  late final StreamSubscription<bool> _bufferingSub;
  late final StreamSubscription<bool> _playingSub;
  late final ZxyPlayerState _state;
  late List<StreamItem> _streams;
  int _selectedStream = 0;
  Timer? _hoverTimer;
  double pinRadius = 20;
  double progressHeight = 10;

  @override
  void initState() {
    super.initState();
    _streams = widget.handler.getCurrentStreams();
    _selectedStream = widget.handler.getSelectedStreamIndex();
    print("Link playing");
    print(_streams[_selectedStream].url);
    print("--------------------------------------------------");
    _state = ZxyPlayerState();
    _player = Player(configuration: PlayerConfiguration());
    _controller = VideoController(
      _player,
      configuration: VideoControllerConfiguration(
        // vo: "gpu",
        hwdec: "auto",
        enableHardwareAcceleration: true,
      ),
    );
    var player = _player.platform as NativePlayer;
    Future.wait([
      player.setProperty('icc-profile-auto', 'yes'),
      player.setProperty('tone-mapping', 'spline'),

      player.setProperty('target-peak', 'auto'),
      player.setProperty('videotoolbox-format', 'nv12'),
      player.setProperty('tone-mapping', 'bt.2446a'),
      player.setProperty('tone-mapping-mode', 'luma'),
      player.setProperty('gamut-mapping-mode', 'clip'),

      player.setProperty('cache', 'yes'),
      player.setProperty('demuxer-max-bytes', '5024MiB'),
      player.setProperty('demuxer-max-back-bytes', '200MiB'),

      player.setProperty('scale', 'ewa_lanczossharp'),
      player.setProperty('cscale', 'ewa_lanczossharp'),
    ]).then((_) {
      _player.open(
        Media(_streams[_selectedStream].url),
        play: _state.isPlaying.value,
      );
    });
    print(_streams[_selectedStream].description);
    print(_streams[_selectedStream].url);
    setupSubscriptions();
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
    int trackIndex = audioTracks.indexWhere((track) => track.language == "eng");
    _state.audioDetails.value = (
      audioTracks,
      trackIndex == -1 ? 0 : trackIndex,
    );
    if (audioTracks.isNotEmpty) {
      print("selected track is ${audioTracks[_state.audioDetails.value!.$2]}");
      _player.setAudioTrack(audioTracks[_state.audioDetails.value!.$2]);
    }

    final subtitles = tracks.subtitle.where((e) => e.language != null).toList();
    _state.subtitleDetails.value = (subtitles, -1);
    _player.setSubtitleTrack(SubtitleTrack.no());
    _player.play().then((_) => widget.handler.onPlay());
  }

  void setupSubscriptions() {
    _trackSub = _player.stream.tracks.listen((tracks) {
      if (tracks.video.isNotEmpty ||
          tracks.audio.isNotEmpty ||
          tracks.subtitle.isNotEmpty) {
        //NOTE: All media info is now available
        print("Printing video details");
        for (var element in tracks.video) {
          print("Codec ${element.codec}");
          print("Bitrate ${element.bitrate}");
        }
        print("--------------------------------------------------");

        print("Printing audio details");
        for (var element in tracks.audio) {
          print("Codec ${element.codec}");
          print("Bitrate ${element.bitrate}");
          print("Language ${element.language}");
        }
        print("--------------------------------------------------");

        print("Printing subtitiles details");
        for (var element in tracks.subtitle) {
          print("Language ${element.language}");
          print("Title ${element.title}");
        }
        print("--------------------------------------------------");
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
        // NOTE: Video is initialised so we need to pickup from where we left off
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

    _player.stream.track.listen((track) {
      print(track.subtitle);
    });

    _bufferingSub = _player.stream.buffering.listen((buffering) {
      _state.buffering.value = buffering;
    });
    _playingSub = _player.stream.playing.listen((playing) {
      _state.isPlaying.value = playing;
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

  @override
  void dispose() {
    _player.pause();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (_, constr) {
          pinRadius = constr.maxHeight * 0.012;
          progressHeight = constr.maxHeight * 0.01;
          return SizedBox(
            height: constr.maxHeight,
            width: constr.maxWidth,
            child: MouseRegion(
              onHover: (_) {
                onHover();
              },
              child: CallbackShortcuts(
                bindings: {
                  SingleActivator(LogicalKeyboardKey.space): () {
                    onPauseOrPlay();
                    onHover();
                  },
                  SingleActivator(LogicalKeyboardKey.arrowRight): () {
                    final currDur = _state.seekInfo.value.current;
                    _player.seek(currDur + Duration(seconds: 15));
                    onHover();
                  },
                  SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                    final currDur = _state.seekInfo.value.current;
                    _player.seek(currDur - Duration(seconds: 15));
                    onHover();
                  },
                  SingleActivator(LogicalKeyboardKey.arrowUp): () {
                    final currVol = _state.volumeDetails.value;
                    final volumeToSet = min(100, currVol + 10);
                    _state.volumeDetails.value = volumeToSet.toDouble();
                    _player.setVolume(volumeToSet.toDouble());
                    onHover();
                  },
                  SingleActivator(LogicalKeyboardKey.arrowDown): () {
                    final currVol = _state.volumeDetails.value;
                    final volumeToSet = max(0, currVol - 10);
                    _state.volumeDetails.value = volumeToSet.toDouble();
                    _player.setVolume(volumeToSet.toDouble());
                    onHover();
                  },
                },
                child: Focus(
                  autofocus: true,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Video(
                          controller: _controller,
                          controls: NoVideoControls,
                          width: constr.maxWidth,
                          subtitleViewConfiguration: SubtitleViewConfiguration(
                            visible: false,
                          ),
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: _state.subtitleFontStyle,
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
                                  backgroundColor: style.bgColor,
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
                          notifiers: [_state.buffering],
                          builder: (_) {
                            final isBuffering = _state.buffering.value;
                            return Visibility(
                              visible: isBuffering,
                              child: CupertinoActivityIndicator(),
                            );
                          },
                        ),
                      ),
                      VideoSettingsSidebar(
                        player: _player,
                        state: _state,
                        height: constr.maxHeight - 40,
                      ),
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
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class VideoSettingsSidebar extends StatelessWidget {
  final double height;
  final Player player;
  const VideoSettingsSidebar({
    super.key,
    required ZxyPlayerState state,
    required this.height,
    required this.player,
  }) : _state = state;

  final ZxyPlayerState _state;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _state.settingsVisible,
      builder: (_, settingsVisible, child) {
        return AnimatedPositioned(
          curve: Curves.elasticOut,
          top: 0,
          bottom: 0,
          right: settingsVisible ? 0 : -400,
          duration: const Duration(milliseconds: 800),
          child: child!,
        );
      },
      child: GlassContainer(
        height: height,
        width: 400,
        padding: const EdgeInsets.all(20),
        radius: AppTheme.roundedMedium,
        child: MultiValueListenableBuilder(
          notifiers: [
            _state.audioDetails,
            _state.videoDetails,
            _state.subtitleDetails,
            _state.subtitleDelay,
            _state.audioDelay,
            _state.subtitleFontStyle,
          ],
          builder: (_) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Audio Tracks"),
                  if (_state.audioDetails.value != null &&
                      _state.audioDetails.value!.$1.isNotEmpty)
                    ...List.generate(_state.audioDetails.value!.$1.length + 1, (
                      index,
                    ) {
                      final radioSelectedVal =
                          _state.audioDetails.value!.$2 + 1;
                      final currentBuildAudioInfo = _state
                          .audioDetails
                          .value!
                          .$1[index != 0 ? index - 1 : 0];
                      return Row(
                        spacing: AppTheme.spacingS,
                        children: [
                          CupertinoRadio(
                            value: index,
                            groupValue: radioSelectedVal,
                            onChanged: (_) {
                              if (index == 0) {
                                player.setAudioTrack(AudioTrack.no());
                                _state.audioDetails.value = (
                                  _state.audioDetails.value!.$1,
                                  -1,
                                );
                                return;
                              }
                              player.setAudioTrack(currentBuildAudioInfo);
                              _state.audioDetails.value = (
                                _state.audioDetails.value!.$1,
                                index - 1,
                              );
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (index == 0) {
                                  player.setAudioTrack(AudioTrack.no());
                                  _state.audioDetails.value = (
                                    _state.audioDetails.value!.$1,
                                    -1,
                                  );
                                  return;
                                }
                                player.setAudioTrack(currentBuildAudioInfo);
                                _state.audioDetails.value = (
                                  _state.audioDetails.value!.$1,
                                  index - 1,
                                );
                              },
                              child: Text(
                                index == 0
                                    ? "None"
                                    : "[${currentBuildAudioInfo.language!.length == 3 ? AppConstants.iso6392Languages[currentBuildAudioInfo.language] : AppConstants.isoLanguages[currentBuildAudioInfo.language]}] ${currentBuildAudioInfo.codec ?? ''} ${currentBuildAudioInfo.title ?? ''} ${currentBuildAudioInfo.channelscount ?? 0}ch",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  AppTheme.boxHeightM,
                  Text("Subtitle Tracks"),
                  if (_state.subtitleDetails.value != null)
                    ...List.generate(
                      _state.subtitleDetails.value!.$1.length + 1,
                      (index) {
                        final radioSelectedVal =
                            _state.subtitleDetails.value!.$2 + 1;
                        final currentBuildsubtitleInfo =
                            _state.subtitleDetails.value!.$1.isNotEmpty
                            ? _state.subtitleDetails.value!.$1[index != 0
                                  ? index - 1
                                  : 0]
                            : null;
                        return Row(
                          spacing: AppTheme.spacingS,
                          children: [
                            CupertinoRadio(
                              value: index,
                              groupValue: radioSelectedVal,
                              onChanged: (_) {
                                if (index == 0) {
                                  player.setSubtitleTrack(SubtitleTrack.no());
                                  _state.subtitleDetails.value = (
                                    _state.subtitleDetails.value!.$1,
                                    -1,
                                  );
                                  return;
                                }
                                player.setSubtitleTrack(
                                  currentBuildsubtitleInfo!,
                                );
                                _state.subtitleDetails.value = (
                                  _state.subtitleDetails.value!.$1,
                                  index - 1,
                                );
                              },
                            ),
                            GestureDetector(
                              onTap: () {
                                if (index == 0) {
                                  player.setSubtitleTrack(SubtitleTrack.no());
                                  _state.subtitleDetails.value = (
                                    _state.subtitleDetails.value!.$1,
                                    -1,
                                  );
                                  return;
                                }
                                player.setSubtitleTrack(
                                  currentBuildsubtitleInfo!,
                                );
                                _state.subtitleDetails.value = (
                                  _state.subtitleDetails.value!.$1,
                                  index - 1,
                                );
                              },
                              child: Text(
                                index == 0
                                    ? "None"
                                    : "[${currentBuildsubtitleInfo!.language!.length == 3 ? AppConstants.iso6392Languages[currentBuildsubtitleInfo.language] : AppConstants.isoLanguages[currentBuildsubtitleInfo.language]}] ${currentBuildsubtitleInfo.title ?? 0}",
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  AppTheme.boxHeightM,
                  Text("Audio delay"),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _state.audioDelay.value -= 10;
                        },
                        icon: Icon(
                          Icons.remove,

                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                      ),
                      Text("${_state.audioDelay.value}ms"),
                      IconButton(
                        onPressed: () {
                          _state.audioDelay.value += 10;
                        },
                        icon: Icon(
                          Icons.add,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  AppTheme.boxHeightM,
                  Text("Subtitle delay"),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _state.subtitleDelay.value -= 10;
                        },
                        icon: Icon(
                          Icons.remove,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                      ),
                      Text("${_state.subtitleDelay.value}ms"),
                      IconButton(
                        onPressed: () {
                          _state.subtitleDelay.value += 10;
                        },
                        icon: Icon(
                          Icons.add,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                      ),
                    ],
                  ),

                  AppTheme.boxHeightM,
                  Text("Subtitle font size"),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _state.subtitleFontStyle.value = _state
                              .subtitleFontStyle
                              .value
                              .copyWith(
                                fontSize: max(
                                  _state.subtitleFontStyle.value.fontSize - 6,
                                  0,
                                ),
                              );
                        },
                        icon: Icon(
                          Icons.remove,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                      ),
                      Text("${_state.subtitleFontStyle.value.fontSize}"),
                      IconButton(
                        onPressed: () {
                          _state.subtitleFontStyle.value = _state
                              .subtitleFontStyle
                              .value
                              .copyWith(
                                fontSize: min(
                                  _state.subtitleFontStyle.value.fontSize + 6,
                                  150,
                                ),
                              );
                        },
                        icon: Icon(
                          Icons.add,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  Text("Subtitle padding"),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _state.subtitleFontStyle.value = _state
                              .subtitleFontStyle
                              .value
                              .copyWith(
                                fontPadding: max(
                                  _state.subtitleFontStyle.value.fontPadding -
                                      6,
                                  0,
                                ),
                              );
                        },
                        icon: Icon(
                          Icons.remove,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                      ),
                      Text("${_state.subtitleFontStyle.value.fontPadding}"),
                      IconButton(
                        onPressed: () {
                          _state.subtitleFontStyle.value = _state
                              .subtitleFontStyle
                              .value
                              .copyWith(
                                fontPadding: min(
                                  _state.subtitleFontStyle.value.fontPadding +
                                      6,
                                  150,
                                ),
                              );
                        },
                        icon: Icon(
                          Icons.add,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
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
    required ZxyPlayerState state,
    required this.pinRadius,
    required this.progressHeight,
    required this.onPauseOrPlay,
    required Player player,
    required this.iconHeight,
  }) : _state = state,
       _player = player;

  final ZxyPlayerState _state;
  final double pinRadius;
  final double progressHeight;
  final Player _player;
  final double iconHeight;
  final VoidCallback onPauseOrPlay;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
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
            notifiers: [_state.isPlaying, _state.volumeDetails],
            builder: (_) {
              final isPlaying = _state.isPlaying.value;
              final volume = _state.volumeDetails.value;
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
                          GestureDetector(
                            onTap: () {
                              if (volume != 0) {
                                _state.volumeDetails.value = 0;
                                _player.setVolume(0);
                              } else {
                                _state.volumeDetails.value = 100;
                                _player.setVolume(100);
                              }
                            },
                            child: Icon(
                              volume == 0 ? Icons.volume_mute : Icons.volume_up,
                              size: 16,
                              color: Colors.grey.withOpacity(0.8),
                            ),
                          ),
                          ProgressBar(
                            onPanDown: (val) {
                              val *= 100;
                              _player.setVolume(val);
                              _state.volumeDetails.value = val;
                            },
                            onPanUp: (val) {
                              val *= 100;
                              _player.setVolume(val);
                              _state.volumeDetails.value = val;
                            },
                            onPanUpdate: (val) {
                              val *= 100;
                              _player.setVolume(val);
                              _state.volumeDetails.value = val;
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
                        GestureDetector(
                          onTap: () {
                            onPauseOrPlay();
                          },
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 32,
                            color: Colors.grey.withOpacity(0.8),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
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
                      child: GestureDetector(
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
  const ZxyProgressBar({
    super.key,
    required this.state,
    required this.player,
    required this.pinRadius,
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
              color: Colors.black.withOpacity(0.4),
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
              color: Colors.grey.withOpacity(0.4),
            ),
            ProgressRegion(
              start: 0,
              end: state.seekInfo.value.playback == Duration.zero
                  ? 0
                  : (state.seekInfo.value.current.inSeconds /
                        state.seekInfo.value.playback.inSeconds),
              color: Colors.grey.withOpacity(0.4),
            ),
          ],
          pinColor: Colors.grey.withOpacity(0.8),
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
    return GestureDetector(
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
    );
  }
}
