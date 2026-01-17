import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:zxy_app/usecase/progress/usecase.dart';
import 'package:zxy_app/usecase/resource/movie_details.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/usecase/stream/stream.dart';
import 'package:zxy_app/views/video_handler.dart';
import 'package:zxy_app/views/view_item_state.dart';

class MovieViewModel implements VideoHandler {
  final MediaUsecase mediaUc;
  final StreamUsecase streamUc;
  final ProgressUsecase progressUc;
  int? _selectedStream;
  String? imdbId;

  int? get selectedStream => _selectedStream;

  MovieViewModel({
    required this.mediaUc,
    required this.streamUc,
    required this.progressUc,
  });

  final ValueNotifier<ViewItemState<MovieDetails>> _movieDetailsState =
      ValueNotifier(ItemLoading());

  ValueListenable<ViewItemState<MovieDetails>> get movieDetailState =>
      _movieDetailsState;

  final ValueNotifier<double> _progressNotifier = ValueNotifier(0);
  ValueListenable<double> get progress => _progressNotifier;

  final ValueNotifier<ViewItemState<List<StreamItem>>> _movieStreamsState =
      ValueNotifier(ItemInitial());

  ValueListenable<ViewItemState<List<StreamItem>>> get movieStreamState =>
      _movieStreamsState;

  Future<void> initialise(int id) async {
    try {
      final details = await mediaUc.getMovieDetails(id);
      imdbId = details.externalIds.imdbId;
      _movieDetailsState.value = ItemLoaded(data: details);
      final progress = await progressUc.getMovieProgress(details.id.toString());
      _progressNotifier.value = progress?.progress ?? 0;
      _getMovieStreams();
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
      final streams = await streamUc.getMovieStreams(imdbId!);
      _movieStreamsState.value = ItemLoaded(data: streams);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _movieStreamsState.value = ItemError(error: e.toString());
      rethrow;
    }
  }

  void onStreamSelect(int index) {
    _selectedStream = index;
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
  double _lastProgressSent = 0;

  @override
  List<StreamItem> getCurrentStreams() {
    if (_movieStreamsState.value is! ItemLoaded) {
      return [];
    }
    return (_movieStreamsState.value as ItemLoaded<List<StreamItem>>).data;
  }

  @override
  int getSelectedStreamIndex() => _selectedStream ?? 0;

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
      _lastProgressSent =
          (_currentProgress.inSeconds / _totalDuration.inSeconds) * 100;
      progressUc.updateWatchProgressMovie(
        (_movieDetailsState.value as ItemLoaded<MovieDetails>).data.id
            .toString(),
        _lastProgressSent,
      );
    });
  }

  @override
  void onProgress(Duration duration) {
    _currentProgress = duration;
  }

  @override
  double getStartingPercentage() {
    return _lastProgressSent != 0 ? _lastProgressSent : _progressNotifier.value;
  }
}
