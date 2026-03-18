import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/usecase/progress/model.dart';
import 'package:zxy_app/usecase/progress/usecase.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/views/base_home_view/base_home_view_model.dart';
import 'package:zxy_app/views/view_item_state.dart';

class ContinueWatchingCardInfo {
  final WatchProgress progress;
  final bool isShow;
  final dynamic media;

  const ContinueWatchingCardInfo({
    required this.progress,
    required this.isShow,
    required this.media,
  });
}

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
  bool _initialised = false;
  final MediaUsecase _mediaUc;
  final ProgressUsecase _progressUc;
  late BuildContext _context;
  HomeViewModel({required MediaUsecase tmdbUc, required ProgressUsecase pguc})
    : _mediaUc = tmdbUc,
      _progressUc = pguc;

  late ValueNotifier<List<HomeViewListItem>> homeViewLists;
  late ValueNotifier<ViewItemState<List<ContinueWatchingItem>>>
  continueWatchingState;

  late ValueNotifier<ViewItemState<List<ZxyMedia>>> topBannerState;

  Future<void> initialise(BuildContext context) async {
    if (_initialised) {
      dispose();
    }
    _initialised = true;
    homeViewLists = ValueNotifier([]);
    continueWatchingState = ValueNotifier(
      ItemLoading<List<ContinueWatchingItem>>(),
    );
    topBannerState = ValueNotifier(ItemLoading<List<ZxyMedia>>());
    final List<Future> futures = [
      initialiseContinueWatching(),
      _getMediaForBanner(topBannerState),
    ];
    _context = context;

    final profile = context.read<UserBloc>().profileNotifier.value;
    if (profile != null) {
      for (var item in profile.libraryItems) {
        final ValueNotifier<ViewItemState<List<ZxyMedia>>> notifier =
            ValueNotifier(ItemLoading<List<ZxyMedia>>());
        homeViewLists.value.add(
          HomeViewListItem(
            title: item.name,
            type: item.filter.isMovie ? ZxyMediaType.movie : ZxyMediaType.shows,
            state: notifier,
          ),
        );
        futures.add(initialiseLibraryItem(notifier, item.filter));
      }
    }

    await Future.wait(futures);
  }

  Future<void> _getMediaForBanner(
    ValueNotifier<ViewItemState<List<ZxyMedia>>> notifier,
  ) async {
    try {
      const items = 3;
      var filter = LibraryFilter.defaultFilter();
      filter = filter.copyWith(traktUrl: "trending", isMovie: true);
      var showFilter = LibraryFilter.defaultFilter();
      showFilter = filter.copyWith(traktUrl: "trending", isMovie: false);
      final res = await Future.wait([
        _mediaUc.discoverLibrary(filter: filter),
        _mediaUc.discoverLibrary(filter: showFilter),
      ]);
      final movies = res[0].results;
      final shows = res[1].results;
      final List<ZxyMedia> jumbled = List.empty(growable: true);
      for (int i = 0; i < items; i++) {
        final tempMovie = movies[i];
        tempMovie.type = ZxyMediaType.movie;
        jumbled.add(tempMovie);
        final tempShow = shows[i];
        tempShow.type = ZxyMediaType.shows;
        jumbled.add(tempShow);
      }
      notifier.value = ItemLoaded(data: jumbled);
    } catch (e) {
      if (kDebugMode) {
        print("Error getting top banner items ${e.toString()}");
      }
      notifier.value = ItemError(error: e.toString());
      rethrow;
    }
  }

  Future<void> initialiseContinueWatching() async {
    try {
      final res = await _progressUc.getContinueWatching();
      continueWatchingState.value = ItemLoaded(data: res);
    } catch (e) {
      continueWatchingState.value = ItemError(error: e.toString());
      rethrow;
    }
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
        print("Error getting genre ${e.toString()}");
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

  Future<void> initialiseLibraryItem(
    ValueNotifier<ViewItemState> notifier,
    LibraryFilter filter,
  ) async {
    try {
      final response = await _mediaUc.discoverLibrary(filter: filter);
      final results = response.results;
      notifier.value = ItemLoaded<List<ZxyMedia>>(data: results);
    } catch (e) {
      if (kDebugMode) {
        notifier.value = ItemError<List<ZxyMedia>>(error: e.toString());
        print(e);
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

  Future<void> reload(BuildContext context) async {
    final List<Future> futures = [];
    for (int i = 0; i < homeViewLists.value.length; i++) {
      homeViewLists.value[i].state.dispose();
    }
    homeViewLists.value = [];

    final profile = context.read<UserBloc>().profileNotifier.value;
    if (profile != null) {
      for (var item in profile.libraryItems) {
        final ValueNotifier<ViewItemState<List<ZxyMedia>>> notifier =
            ValueNotifier(ItemLoading<List<ZxyMedia>>());
        homeViewLists.value.add(
          HomeViewListItem(
            title: item.name,
            type: item.filter.isMovie ? ZxyMediaType.movie : ZxyMediaType.shows,
            state: notifier,
          ),
        );
        futures.add(initialiseLibraryItem(notifier, item.filter));
      }
    }

    await Future.wait(futures);
  }

  Future<void> removeFromContinue(String mediaId) async {
    final bvm = _context.read<BaseHomeViewModel>();
    try {
      bvm.scaffoldLoading.value = true;
      await _progressUc.removeContinueWatching(mediaId);
      await initialiseContinueWatching();
      bvm.scaffoldLoading.value = false;
    } catch (e) {
      bvm.scaffoldLoading.value = false;
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  Future<void> markMediaWatched(String mediaId, bool isMovie) async {
    final bvm = _context.read<BaseHomeViewModel>();
    try {
      bvm.scaffoldLoading.value = true;
      if (isMovie) {
        await _progressUc.updateMovieToWatched(mediaId);
      } else {
        await _progressUc.updateShowToWatched(mediaId);
      }
      await initialiseContinueWatching();
      bvm.scaffoldLoading.value = false;
    } catch (e) {
      bvm.scaffoldLoading.value = false;
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  void dispose() {
    for (int i = 0; i < homeViewLists.value.length; i++) {
      homeViewLists.value[i].state.dispose();
    }
    homeViewLists.dispose();
    continueWatchingState.dispose();
    topBannerState.dispose();
  }
}
