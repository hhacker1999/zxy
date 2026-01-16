import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:zxy_app/usecase/progress/model.dart';
import 'package:zxy_app/usecase/progress/usecase.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/usecase/stream/stream.dart';
import 'package:zxy_app/views/video_handler.dart';
import 'package:zxy_app/views/view_item_state.dart';

class SeriesViewModel implements VideoHandler {
  final MediaUsecase mediaUc;
  final StreamUsecase streamUc;
  final ProgressUsecase progressUc;

  late final List<SeasonDetails> seasons;
  final Map<String, List<StreamItem>> _streams = {};

  int? _selectedStream = 0;
  String? imdbId;

  int? get selectedStream => _selectedStream;

  SeriesViewModel({
    required this.mediaUc,
    required this.streamUc,
    required this.progressUc,
  });

  final ValueNotifier<ViewItemState<SeriesDetails>> _seriesDetailsState =
      ValueNotifier(ItemLoading());

  ValueListenable<ViewItemState<SeriesDetails>> get seriesDetailState =>
      _seriesDetailsState;

  final ValueNotifier<Map<String, WatchProgress>> _progressNotifier =
      ValueNotifier({});
  ValueListenable<Map<String, WatchProgress>> get progress => _progressNotifier;

  final ValueNotifier<ViewItemState<List<StreamItem>>> _episodeStreamsState =
      ValueNotifier(ItemInitial());

  ValueListenable<ViewItemState<List<StreamItem>>> get episodeStreamsState =>
      _episodeStreamsState;

  final ValueNotifier<(int, int?)> activeSeasonEpisode =
      ValueNotifier<(int, int?)>((0, null));

  Future<void> initialise(int id) async {
    try {
      final details = await mediaUc.getSeriesDetails(id);
      imdbId = details.externalIds.imdbId;
      seasons = details.seasons;

      final progressRes = await progressUc.getProgressShow(
        details.id.toString(),
      );
      for (var element in progressRes) {
        _progressNotifier.value[element.mediaId] = element;
      }
      _seriesDetailsState.value = ItemLoaded(data: details);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _seriesDetailsState.value = ItemError(error: e.toString());
      rethrow;
    }
  }

  void onStreamSelect(int index) {
    _selectedStream = index;
  }

  void onSeasonSelect(int index) {
    if (activeSeasonEpisode.value.$1 == index) {
      return;
    }
    activeSeasonEpisode.value = (index, null);
    _selectedStream = null;
  }

  (SeasonDetails, Episode) _getCurrentSeasonEpisode() {
    return (
      seasons[activeSeasonEpisode.value.$1],
      seasons[activeSeasonEpisode.value.$1].episodes[activeSeasonEpisode
          .value
          .$2!],
    );
  }

  Future<void> onEpisodeSelect(int episodeIndex) async {
    if (activeSeasonEpisode.value.$2 == episodeIndex) {
      return;
    }
    _resetVideoHandler();
    activeSeasonEpisode.value = (activeSeasonEpisode.value.$1, episodeIndex);

    final cacheStreams =
        _streams["${activeSeasonEpisode.value.$1}:${activeSeasonEpisode.value.$2}"];
    if (cacheStreams != null) {
      _episodeStreamsState.value = ItemLoaded(data: cacheStreams);
      return;
    }
    try {
      _episodeStreamsState.value = ItemLoading();
      final streams = await streamUc.getSeriesStreams(
        imdbId!,
        seasons[activeSeasonEpisode.value.$1].seasonNumber,
        seasons[activeSeasonEpisode.value.$1]
            .episodes[activeSeasonEpisode.value.$2!]
            .episodeNumber,
      );
      _streams["${activeSeasonEpisode.value.$1}:${activeSeasonEpisode.value.$2}"] =
          streams;
      _episodeStreamsState.value = ItemLoaded(data: streams);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _episodeStreamsState.value = ItemError(error: e.toString());
      rethrow;
    }
  }

  void dispose() {
    _seriesDetailsState.dispose();
    _episodeStreamsState.dispose();
    _progressNotifier.dispose();
    activeSeasonEpisode.dispose();
    _progressTimer?.cancel();
  }

  //----------------------------------Handler Methods--------------------------------------------

  void _resetVideoHandler() {
    _progressTimer?.cancel();
    _totalDuration = Duration.zero;
    _currentProgress = Duration.zero;
    _isPaused = false;
    _lastProgressSent = 0;
  }

  Timer? _progressTimer;
  Duration _totalDuration = Duration.zero;
  Duration _currentProgress = Duration.zero;
  bool _isPaused = false;
  double _lastProgressSent = 0;

  @override
  List<StreamItem> getCurrentStreams() {
    return _streams["${activeSeasonEpisode.value.$1}:${activeSeasonEpisode.value.$2}"] ??
        [];
  }

  @override
  int getSelectedStreamIndex() => _selectedStream ?? 0;

  @override
  double getStartingPercentage() {
    final info = _getCurrentSeasonEpisode();

    final series =
        (_seriesDetailsState.value as ItemLoaded<SeriesDetails>).data;

    final key = "${series.id}:${info.$1.seasonNumber}:${info.$2.episodeNumber}";

    final value = _progressNotifier.value[key];
    if (value == null) {
      return 0;
    }
    return value.progress;
  }

  @override
  bool isMovie() => false;

  @override
  void onDurationUpdate(Duration duration) {
    _totalDuration = duration;
  }

  @override
  void onPause() {
    _isPaused = true;
  }

  @override
  void onPlay() {
    _isPaused = false;

    final info = _getCurrentSeasonEpisode();
    final series =
        (_seriesDetailsState.value as ItemLoaded<SeriesDetails>).data;

    final key = "${series.id}:${info.$1.seasonNumber}:${info.$2.episodeNumber}";
    final value = _progressNotifier.value[key];
    _progressTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (_totalDuration == Duration.zero || _isPaused) {
        return;
      }
      _lastProgressSent =
          (_currentProgress.inSeconds / _totalDuration.inSeconds) * 100;
      progressUc.updateWatchProgressShow(
        series.id.toString(),
        info.$1.seasonNumber,
        info.$2.episodeNumber,
        _lastProgressSent,
      );
      if (value == null) {
        _progressNotifier.value[key] = WatchProgress(
          mediaId: key,
          progress: _lastProgressSent,
          userId: -1,
          profileId: -1,
          isWatched: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        _progressNotifier.value[key] = value.copyWith(
          progress: _lastProgressSent,
        );
      }
      _progressNotifier.value = Map.from(_progressNotifier.value);
    });
  }

  @override
  void onProgress(Duration duration) {
    _currentProgress = duration;
  }
}
