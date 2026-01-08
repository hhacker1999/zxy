import 'package:flutter/foundation.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/usecase/stream/stream.dart';
import 'package:zxy_app/views/video_player_view/video_player_view.dart';
import 'package:zxy_app/views/view_item_state.dart';

class SeriesViewModel {
  final MediaUsecase mediaUc;
  final StreamUsecase streamUc;

  late final ZxyMedia initialSeriesDetails;
  late final List<SeasonDetails> seasons;
  final Map<String, List<StreamItem>> _streams = {};

  int? _selectedStream = 0;
  String? imdbId;

  int? get selectedStream => _selectedStream;

  SeriesViewModel({required this.mediaUc, required this.streamUc});

  final ValueNotifier<ViewItemState<SeriesDetails>> _seriesDetailsState =
      ValueNotifier(ItemLoading());

  ValueListenable<ViewItemState<SeriesDetails>> get seriesDetailState =>
      _seriesDetailsState;

  final ValueNotifier<ViewItemState<List<StreamItem>>> _episodeStreamsState =
      ValueNotifier(ItemInitial());

  ValueListenable<ViewItemState<List<StreamItem>>> get episodeStreamsState =>
      _episodeStreamsState;

  final ValueNotifier<(int, int?)> activeSeasonEpisode =
      ValueNotifier<(int, int?)>((0, null));

  Future<void> initialise(ZxyMedia series) async {
    initialSeriesDetails = series;
    try {
      final details = await mediaUc.getSeriesDetails(series.id);
      imdbId = details.externalIds.imdbId;
      seasons = List.empty(growable: true);
      final List<Future<SeasonDetails>> seasonFutures = List.empty(
        growable: true,
      );
      for (var element in details.seasons) {
        seasonFutures.add(getSeasonDetails(element));
      }
      final res = await Future.wait(seasonFutures);
      for (var element in res) {
        if (element.seasonNumber == 0 || element.name == "Specials") {
          continue;
        }
        seasons.add(element);
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

  Future<SeasonDetails> getSeasonDetails(Season season) async {
    try {
      final details = await mediaUc.getSeasonDetails(
        initialSeriesDetails.id,
        season.seasonNumber,
      );
      return details;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  void onSeasonSelect(int index) {
    if (activeSeasonEpisode.value.$1 == index) {
      return;
    }
    activeSeasonEpisode.value = (index, null);
    _selectedStream = null;
  }

  Future<void> onEpisodeSelect(int episodeIndex) async {
    if (activeSeasonEpisode.value.$2 == episodeIndex) {
      return;
    }
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

  VideoPlayerInput getPlayerStreams() {
    return VideoPlayerInput(
      streams:
          (_episodeStreamsState.value as ItemLoaded<List<StreamItem>>).data,
      index: _selectedStream ?? 0,
    );
  }

  void dispose() {
    _seriesDetailsState.dispose();
    _episodeStreamsState.dispose();
    activeSeasonEpisode.dispose();
  }
}
