import 'package:flutter/foundation.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';
import 'package:zxy_app/views/view_item_state.dart';

class HomeViewListItem {
  final String title;
  final ZxyMediaType type;
  final ValueNotifier<ViewItemState<List<ZxyMedia>>> state;

  const HomeViewListItem({
    required this.title,
    required this.type,
    required this.state,
  });
}

class HomeViewModel {
  final MediaUsecase _mediaUc;
  HomeViewModel({required MediaUsecase tmdbUc}) : _mediaUc = tmdbUc;

  final ValueNotifier<List<HomeViewListItem>> homeViewLists = ValueNotifier([]);

  Future<void> initialise(String token) async {
    if (homeViewLists.value.isNotEmpty) {
      return;
    }

    _mediaUc.setReadAccessToken(token);
    final ValueNotifier<ViewItemState<List<ZxyMedia>>> topMovieState =
        ValueNotifier(ItemLoading<List<ZxyMedia>>());
    final ValueNotifier<ViewItemState<List<ZxyMedia>>> topShowsState =
        ValueNotifier(ItemLoading<List<ZxyMedia>>());
    final ValueNotifier<ViewItemState<List<ZxyMedia>>> trendingShowsState =
        ValueNotifier(ItemLoading<List<ZxyMedia>>());
    final ValueNotifier<ViewItemState<List<ZxyMedia>>> trendingMoviesState =
        ValueNotifier(ItemLoading<List<ZxyMedia>>());
    homeViewLists.value.add(
      HomeViewListItem(
        title: "Trending Shows",
        type: ZxyMediaType.shows,
        state: trendingShowsState,
      ),
    );

    homeViewLists.value.add(
      HomeViewListItem(
        title: "Trending Movies",
        type: ZxyMediaType.movie,
        state: trendingMoviesState,
      ),
    );

    homeViewLists.value.add(
      HomeViewListItem(
        title: "Top Rated Shows",
        type: ZxyMediaType.shows,
        state: topShowsState,
      ),
    );

    homeViewLists.value.add(
      HomeViewListItem(
        title: "Top Rated Movies",
        type: ZxyMediaType.movie,
        state: topMovieState,
      ),
    );
    await Future.wait([
      initialiseTrendingShows(trendingShowsState),
      initialiseTrendingMovies(trendingMoviesState),
      initialiseTopRatedShows(topShowsState),
      initialiseTopRatedMovies(topMovieState),
      initialiseGenre(),
      initialiseConfig(),
    ]);
  }

  Future<void> initialiseGenre() async {
    try {
      final genreRes = await _mediaUc.getGenre();
      final Map<int, Genre> movieGenre = {};
      final Map<int, Genre> showGenre = {};

      for (var element in genreRes.showGenre) {
        showGenre[element.id] = element;
      }
      for (var element in genreRes.movieGenre) {
        movieGenre[element.id] = element;
      }
      AppConstants.movieGenre = movieGenre;
      AppConstants.showGenre = showGenre;
    } catch (e) {
      if (kDebugMode) {
        print("Error getting genre $e");
      }
      rethrow;
    }
  }

  Future<void> initialiseConfig() async {
    try {
      final imageConfig = await _mediaUc.getConfiguration();

      AppConstants.imageConfig = imageConfig;
    } catch (e) {
      if (kDebugMode) {
        print("Error getting image config $e");
      }
      rethrow;
    }
  }

  Future<void> initialiseTopRatedMovies(
    ValueNotifier<ViewItemState> topMovieState,
  ) async {
    try {
      final movieResponse = await _mediaUc.discoverMovies(
        filter: {
          "include_adult": "true",
          "sory_by": "vote_average",
          "without_genres": "99,10755",
          "vote_count.gte": "200",
        },
      );
      final movies = movieResponse.results;
      topMovieState.value = ItemLoaded<List<ZxyMedia>>(data: movies);
    } catch (e) {
      if (kDebugMode) {
        topMovieState.value = ItemError<List<ZxyMedia>>(error: e.toString());
        print(e);
      }
      rethrow;
    }
  }

  Future<void> initialiseTopRatedShows(
    ValueNotifier<ViewItemState> topSeriesState,
  ) async {
    try {
      final seriesResponse = await _mediaUc.discoverShows(
        filter: {
          "include_adult": "true",
          "sory_by": "vote_average",
          "vote_count.gte": "200",
        },
      );
      final series = seriesResponse.results;
      topSeriesState.value = ItemLoaded<List<ZxyMedia>>(data: series);
    } catch (e) {
      if (kDebugMode) {
        topSeriesState.value = ItemError<List<ZxyMedia>>(error: e.toString());
        print(e);
      }
      rethrow;
    }
  }

  Future<void> initialiseTrendingShows(
    ValueNotifier<ViewItemState> trendingSeriesState,
  ) async {
    try {
      final seriesResponse = await _mediaUc.getTrendingShows();
      final series = seriesResponse.results;
      trendingSeriesState.value = ItemLoaded<List<ZxyMedia>>(data: series);
    } catch (e) {
      if (kDebugMode) {
        trendingSeriesState.value = ItemError<List<ZxyMedia>>(
          error: e.toString(),
        );
        print(e);
      }
      rethrow;
    }
  }

  Future<void> initialiseTrendingMovies(
    ValueNotifier<ViewItemState> trendingMoviesState,
  ) async {
    try {
      final seriesResponse = await _mediaUc.getTrendingMovies();
      final movies = seriesResponse.results;
      trendingMoviesState.value = ItemLoaded<List<ZxyMedia>>(data: movies);
    } catch (e) {
      if (kDebugMode) {
        trendingMoviesState.value = ItemError<List<ZxyMedia>>(
          error: e.toString(),
        );
        print(e);
      }
      rethrow;
    }
  }

  void dispose() {
    for (int i = 0; i < homeViewLists.value.length; i++) {
      homeViewLists.value[i].state.dispose();
    }
  }
}
