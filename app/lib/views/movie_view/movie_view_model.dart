import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:zxy_app/bloc/settings_bloc.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/progress/model.dart';
import 'package:zxy_app/usecase/progress/usecase.dart';
import 'package:zxy_app/usecase/resource/movie_details.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/usecase/stream/stream.dart';
import 'package:zxy_app/views/video_handler.dart';
import 'package:zxy_app/views/view_item_state.dart';

class MovieViewModel implements VideoHandler {
  final MediaUsecase mediaUc;
  final StreamUsecase streamUc;
  final ProgressUsecase progressUc;
  final UserBloc userBloc;
  final SettingsBloc settingsBloc;

  ValueNotifier<int> selectedStream = ValueNotifier(0);

  MovieViewModel({
    required this.mediaUc,
    required this.streamUc,
    required this.progressUc,
    required this.userBloc,
    required this.settingsBloc,
  });

  final ValueNotifier<ViewItemState<MovieDetails>> _movieDetailsState =
      ValueNotifier(ItemLoading());

  ValueListenable<ViewItemState<MovieDetails>> get movieDetailState =>
      _movieDetailsState;

  final ValueNotifier<WatchProgress> _progressNotifier = ValueNotifier(
    WatchProgress.empty(""),
  );
  ValueListenable<WatchProgress> get progress => _progressNotifier;

  final ValueNotifier<ViewItemState<ZxyStreamResponse>> _movieStreamsState =
      ValueNotifier(ItemInitial());

  ValueListenable<ViewItemState<ZxyStreamResponse>> get movieStreamState =>
      _movieStreamsState;

  Future<void> initialise(int id) async {
    try {
      final details = await mediaUc.getMovieDetails(id);
      _movieDetailsState.value = ItemLoaded(data: details);
      final progress = await progressUc.getMovieProgress(details.id.toString());
      _progressNotifier.value =
          progress ?? WatchProgress.empty(details.id.toString());
      final userHasAddedDebrid =
          userBloc.profileNotifier.value != null &&
          userBloc.profileNotifier.value!.debridType.isNotEmpty;
      if (userHasAddedDebrid) {
        _getMovieStreams();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _movieDetailsState.value = ItemError(error: e.toString());
      rethrow;
    }
  }

  Future<void> _getMovieStreams() async {
    try {
      _movieStreamsState.value = ItemLoading();
      final details =
          (_movieDetailsState.value as ItemLoaded<MovieDetails>).data;
      final streams = await streamUc.getMovieStreams(
        details.externalIds.imdbId ?? "",
      );
      _movieStreamsState.value = ItemLoaded(data: streams);
      _setSelectedStreamBasedOnPrefs(streams);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _movieStreamsState.value = ItemError(error: e.toString());
      rethrow;
    }
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

  void onStreamSelect(int index) {
    selectedStream.value = index;
  }

  void dispose() {
    _movieDetailsState.dispose();
    _movieStreamsState.dispose();
    _progressNotifier.dispose();
    _progressTimer?.cancel();
  }

  //----------------------------------Handler Methods--------------------------------------------

  Timer? _progressTimer;
  Duration _totalDuration = Duration.zero;
  Duration _currentProgress = Duration.zero;
  bool _isPaused = false;

  @override
  ValueListenable<ViewItemState<ZxyStreamResponse>>
  getCurrentStreamsNotifier() => _movieStreamsState;

  @override
  ValueListenable<WatchProgress> getProgressNotifier() => _progressNotifier;

  @override
  ValueNotifier<int> getSelectedStreamNotifier() => selectedStream;

  @override
  bool isMovie() => true;

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
    if (_progressTimer == null) {
      progressUc.updateWatchProgressMovie(
        (_movieDetailsState.value as ItemLoaded<MovieDetails>).data.id
            .toString(),
        0,
      );
    }
    _progressTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (_totalDuration == Duration.zero || _isPaused) {
        return;
      }
      _progressNotifier.value = _progressNotifier.value.copyWith(
        progress: (_currentProgress.inSeconds / _totalDuration.inSeconds) * 100,
      );
      progressUc.updateWatchProgressMovie(
        (_movieDetailsState.value as ItemLoaded<MovieDetails>).data.id
            .toString(),
        _progressNotifier.value.progress,
      );
    });
  }

  @override
  void onProgress(Duration duration) {
    _currentProgress = duration;
  }

  @override
  double getStartingPercentage() {
    return _progressNotifier.value.progress;
  }

  @override
  String longTitle() {
    final details = (_movieDetailsState.value as ItemLoaded<MovieDetails>).data;
    return details.title;
  }

  @override
  String shortTitle() {
    final details = (_movieDetailsState.value as ItemLoaded<MovieDetails>).data;
    return details.title;
  }
}
