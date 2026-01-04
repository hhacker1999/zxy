import 'package:flutter/foundation.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/usecase/stream/stream.dart';
import 'package:zxy_app/views/video_player_view/video_player_view.dart';
import 'package:zxy_app/views/view_item_state.dart';

class MovieViewModel {
  final MediaUsecase mediaUc;
  final StreamUsecase streamUc;
  late final ZxyMedia initialMovieDetails;
  int? _selectedStream;

  int? get selectedStream => _selectedStream;

  MovieViewModel({required this.mediaUc, required this.streamUc});

  final ValueNotifier<ViewItemState<MovieDetails>> _movieDetailsState =
      ValueNotifier(ItemLoading());

  ValueListenable<ViewItemState<MovieDetails>> get movieDetailState =>
      _movieDetailsState;

  final ValueNotifier<ViewItemState<List<StreamItem>>> _movieStreamsState =
      ValueNotifier(ItemInitial());

  ValueListenable<ViewItemState<List<StreamItem>>> get movieStreamState =>
      _movieStreamsState;

  Future<void> initialise(ZxyMedia movie) async {
    initialMovieDetails = movie;
    try {
      _getMovieStreams();
      final details = await mediaUc.getMovieDetails(initialMovieDetails.id);
      _movieDetailsState.value = ItemLoaded(data: details);
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
      final streams = await streamUc.getMovieStreams(initialMovieDetails.id);
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

  VideoPlayerInput getPlayerStreams() {
    return VideoPlayerInput(
      streams: (_movieStreamsState.value as ItemLoaded<List<StreamItem>>).data,
      index: _selectedStream ?? 0,
    );
  }

  void dispose() {
    _movieDetailsState.dispose();
    _movieStreamsState.dispose();
  }
}
