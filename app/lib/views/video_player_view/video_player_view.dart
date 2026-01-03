// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:ui';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/views/shared/glass_container.dart';

class VideoPlayerInput {
  final List<StreamItem> streams;
  final int index;
  VideoPlayerInput({required this.streams, required this.index});
}

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
  final VideoPlayerInput input;
  const VideoPlayerView({super.key, required this.input});

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
  Timer? _hoverTimer;
  double pinRadius = 20;
  double progressHeight = 10;

  @override
  void initState() {
    super.initState();
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
        Media(widget.input.streams[widget.input.index].url),
        play: _state.isPlaying.value,
      );
    });
    print(widget.input.streams[widget.input.index].description);
    print(widget.input.streams[widget.input.index].url);
    setupSubscriptions();
  }

  void onMediaInitialized(Tracks tracks) {
    _state.videoDetails.value = tracks.video.first;
    final List<AudioTrack> audioTracks = List.from(tracks.audio);
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
    print("selected track is ${audioTracks[_state.audioDetails.value!.$2]}");
    _player.setAudioTrack(audioTracks[_state.audioDetails.value!.$2]);
    _player.setSubtitleTrack(SubtitleTrack.no());
    _player.play();
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
    });

    _currentSub = _player.stream.duration.listen((duration) {
      _state.seekInfo.value = _state.seekInfo.value.copyWith(
        playback: duration,
      );
    });

    _bufferSub = _player.stream.buffer.listen((buffer) {
      _state.seekInfo.value = _state.seekInfo.value.copyWith(buffered: buffer);
    });

    _bufferingSub = _player.stream.buffering.listen((buffering) {
      print("--------------------------------------------------");
      print("buffering received from server");
      print("--------------------------------------------------");
      _state.buffering.value = buffering;
    });
    _playingSub = _player.stream.playing.listen((playing) {
      _state.isPlaying.value = playing;
    });
  }

  @override
  void dispose() {
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
    print("build is being called");
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
                if (!_state.isOverlayVisible.value) {
                  _state.isOverlayVisible.value = true;
                }
                _hoverTimer?.cancel();
                _hoverTimer = Timer(const Duration(seconds: 4), () {
                  _state.isOverlayVisible.value = false;
                });
              },
              child: Listener(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Video(
                        controller: _controller,
                        controls: NoVideoControls,
                        width: constr.maxWidth,
                      ),
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
                    ValueListenableBuilder(
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
                        height: constr.maxHeight - 40,
                        width: 400,
                        padding: const EdgeInsets.all(20),
                        radius: AppTheme.roundedMedium,
                        child: SizedBox(),
                      ),
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
          );
        },
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
    required Player player,
    required this.iconHeight,
  }) : _state = state,
       _player = player;

  final ZxyPlayerState _state;
  final double pinRadius;
  final double progressHeight;
  final Player _player;
  final double iconHeight;

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
                            if (isPlaying) {
                              _player.pause();
                              _state.isPlaying.value = false;
                            } else {
                              _player.play();
                              _state.isPlaying.value = true;
                            }
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
