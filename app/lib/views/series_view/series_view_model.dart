import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:zxy_app/bloc/settings_bloc.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
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
  final UserBloc userBloc;
  final SettingsBloc settingsBloc;

  late final List<Season> seasons;
  final Map<String, ZxyStreamResponse> _streams = {};

  String? imdbId;

  ValueNotifier<int> selectedStream = ValueNotifier(0);

  SeriesViewModel({
    required this.mediaUc,
    required this.streamUc,
    required this.progressUc,
    required this.userBloc,
    required this.settingsBloc,
  });

  final ValueNotifier<bool> scffoldLoading = ValueNotifier(false);

  final ValueNotifier<ViewItemState<SeriesDetails>> _seriesDetailsState =
      ValueNotifier(ItemLoading());

  ValueListenable<ViewItemState<SeriesDetails>> get seriesDetailState =>
      _seriesDetailsState;

  final ValueNotifier<Map<String, ValueNotifier<WatchProgress>>>
  _progressNotifier = ValueNotifier({});
  ValueListenable<Map<String, ValueNotifier<WatchProgress>>> get progress =>
      _progressNotifier;

  final ValueNotifier<ViewItemState<ZxyStreamResponse>> _episodeStreamsState =
      ValueNotifier(ItemInitial());

  ValueListenable<ViewItemState<ZxyStreamResponse>> get episodeStreamsState =>
      _episodeStreamsState;

  final ValueNotifier<(int, int)> activeSeasonEpisode =
      ValueNotifier<(int, int)>((0, -1));

  Future<void> initialise(int id, {int? season, int episode = 0}) async {
    try {
      final details = await mediaUc.getSeriesDetails(id);
      imdbId = details.externalIds.imdbId;
      seasons = details.seasons;

      final progressRes = await progressUc.getProgressShow(
        details.id.toString(),
      );
      for (var element in progressRes) {
        _progressNotifier.value[element.mediaId] = ValueNotifier(element);
      }
      if (season == null) {
        outerLoop:
        for (var element in details.seasons) {
          for (var item in element.episodes) {
            season = element.seasonNumber - 1;
            episode = item.episodeNumber - 1;
            var key = "$id:${element.seasonNumber}:${item.episodeNumber}";
            final value = _progressNotifier.value[key]?.value;
            if (value == null) {
              break outerLoop;
            }
            if (!value.isWatched) {
              break outerLoop;
            }
          }
        }
      }

      activeSeasonEpisode.value = (season!, activeSeasonEpisode.value.$2);
      onEpisodeSelect(episode);
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
    selectedStream.value = index;
  }

  void onSeasonSelect(int index) {
    if (activeSeasonEpisode.value.$1 == index) {
      return;
    }
    activeSeasonEpisode.value = (index, -1);
    onEpisodeSelect(0);
  }

  (Season, Episode) _getCurrentSeasonEpisode() {
    return (
      seasons[activeSeasonEpisode.value.$1],
      seasons[activeSeasonEpisode.value.$1].episodes[activeSeasonEpisode
          .value
          .$2],
    );
  }

  void _setSelectedStreamBasedOnPrefs(ZxyStreamResponse streams) {
    final res = settingsBloc.resolutionNotifier.value;
    List<ZxyResolutionItem> streamsFlat = List.empty(growable: true);
    streamsFlat.addAll(streams.uhd);
    streamsFlat.addAll(streams.fhd);
    streamsFlat.addAll(streams.hd);
    final index = streamsFlat.indexWhere((e) => e.resolution == res);
    if (index != -1) {
      selectedStream.value = index;
    } else {
      selectedStream.value = 0;
    }
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
      _setSelectedStreamBasedOnPrefs(cacheStreams);
      return;
    }

    final userHasAddedDebrid =
        userBloc.profileNotifier.value != null &&
        userBloc.profileNotifier.value!.debridType.isNotEmpty;
    if (userHasAddedDebrid) {
      try {
        _episodeStreamsState.value = ItemLoading();
        final streams = await streamUc.getSeriesStreams(
          imdbId!,
          seasons[activeSeasonEpisode.value.$1].seasonNumber,
          seasons[activeSeasonEpisode.value.$1]
              .episodes[activeSeasonEpisode.value.$2]
              .episodeNumber,
        );
        _streams["${activeSeasonEpisode.value.$1}:${activeSeasonEpisode.value.$2}"] =
            streams;
        _episodeStreamsState.value = ItemLoaded(data: streams);
        _setSelectedStreamBasedOnPrefs(streams);
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        _episodeStreamsState.value = ItemError(error: e.toString());
        rethrow;
      }
    }
  }

  Future<void> onMarkWatched(String mediaId) async {
    try {
      scffoldLoading.value = true;
      await progressUc.updateShowToWatched(mediaId);
      await updateShowProgressFromBE();
      scffoldLoading.value = false;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      scffoldLoading.value = false;
      rethrow;
    }
  }

  Future<void> updateShowProgressFromBE() async {
    final Map<String, ValueNotifier<WatchProgress>> progressMap = {};
    final details =
        (_seriesDetailsState.value as ItemLoaded<SeriesDetails>).data;
    final progressRes = await progressUc.getProgressShow(details.id.toString());
    for (var element in progressRes) {
      progressMap[element.mediaId] = ValueNotifier(element);
    }
    _disposeAndClearEachProgress();
    _progressNotifier.value = progressMap;
  }

  void _disposeAndClearEachProgress() {
    for (var item in _progressNotifier.value.values) {
      item.dispose();
    }
  }

  void dispose() {
    _seriesDetailsState.dispose();
    _episodeStreamsState.dispose();
    _disposeAndClearEachProgress();
    _progressNotifier.dispose();
    activeSeasonEpisode.dispose();
    _progressTimer?.cancel();
    scffoldLoading.dispose();
  }

  //----------------------------------Handler Methods--------------------------------------------

  void _resetVideoHandler() {
    _progressTimer?.cancel();
    _progressTimer = null;
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
  ValueListenable<ViewItemState<ZxyStreamResponse>>
  getCurrentStreamsNotifier() => _episodeStreamsState;

  @override
  ValueListenable<WatchProgress> getProgressNotifier() {
    final info = _getCurrentSeasonEpisode();
    final series =
        (_seriesDetailsState.value as ItemLoaded<SeriesDetails>).data;

    final key = "${series.id}:${info.$1.seasonNumber}:${info.$2.episodeNumber}";
    var progressNotifier = _progressNotifier.value[key];
    progressNotifier ??= ValueNotifier(WatchProgress.empty(key));
    _progressNotifier.value[key] = progressNotifier;
    return progressNotifier;
  }

  @override
  ValueNotifier<int> getSelectedStreamNotifier() => selectedStream;

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
    return value.value.progress;
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
  void onStop() {
    _isPaused = true;
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  @override
  void onPlay() {
    _isPaused = false;

    final info = _getCurrentSeasonEpisode();
    final series =
        (_seriesDetailsState.value as ItemLoaded<SeriesDetails>).data;

    final key = "${series.id}:${info.$1.seasonNumber}:${info.$2.episodeNumber}";
    final progressNotifier = _progressNotifier.value[key];
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
      if (progressNotifier == null) {
        _progressNotifier.value[key] = ValueNotifier(
          WatchProgress.empty(key, progress: _lastProgressSent),
        );
      } else {
        progressNotifier.value = progressNotifier.value.copyWith(
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

  @override
  String longTitle() {
    final series =
        (_seriesDetailsState.value as ItemLoaded<SeriesDetails>).data;
    return "Episode ${(activeSeasonEpisode.value.$2 + 1).toString().padLeft(2, '0')}:${series.seasons[activeSeasonEpisode.value.$1].episodes[activeSeasonEpisode.value.$2].name}";
  }

  @override
  String shortTitle() {
    return "S${(activeSeasonEpisode.value.$1 + 1).toString().padLeft(2, '0')}:E${(activeSeasonEpisode.value.$2 + 1).toString().padLeft(2, '0')}";
  }

  @override
  Future<String> getStreamUrl(String tempUrl) async {
    return await streamUc.getStreamUrl(tempUrl);
  }
}
