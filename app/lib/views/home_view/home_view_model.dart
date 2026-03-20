import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/bloc/events_bloc.dart';
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

class HomeViewListItemDetails {
  final ProfileLibraryItem item;
  final ValueNotifier<ViewItemState<List<ZxyMedia>>> state;

  const HomeViewListItemDetails({required this.state, required this.item});
}

class HomeViewModel {
  bool _initialised = false;
  final MediaUsecase _mediaUc;
  final ProgressUsecase _progressUc;
  late BuildContext _context;
  late StreamSubscription<BaseEvent> _eventSub;
  HomeViewModel({required MediaUsecase tmdbUc, required ProgressUsecase pguc})
    : _mediaUc = tmdbUc,
      _progressUc = pguc;

  late ValueNotifier<List<HomeViewListItemDetails>> homeViewLists;
  late ValueNotifier<ViewItemState<List<ContinueWatchingItem>>>
  continueWatchingState;

  late ValueNotifier<ViewItemState<List<ZxyMedia>>> topBannerState;

  Future<void> initialise(BuildContext context) async {
    if (_initialised) {
      dispose();
    }
    _eventSub = context.read<EventsBloc>().eventStream.listen((event) {
      _eventHandler(event);
    });
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
          HomeViewListItemDetails(item: item, state: notifier),
        );
      }
    }

    await Future.wait(futures);
  }

  void _eventHandler(BaseEvent event) {
    if (event is UpdatedHomeList) {
      _reload();
    }
  }

  Future<void> _getMediaForBanner(
    ValueNotifier<ViewItemState<List<ZxyMedia>>> notifier,
  ) async {
    try {
      const items = 3;
      var filter = LibraryFilter.defaultFilter();
      filter = filter.copyWith(
        traktId: "trending",
        isMovie: true,
        type: "trakt",
        items: items,
      );
      var showFilter = LibraryFilter.defaultFilter();
      showFilter = filter.copyWith(
        traktId: "trending",
        isMovie: false,
        type: "trakt",
        items: items,
      );
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
    if (notifier.value is ItemLoaded) {
      return;
    }
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

  void _reload() async {
    for (int i = 0; i < homeViewLists.value.length; i++) {
      homeViewLists.value[i].state.dispose();
    }
    List<HomeViewListItemDetails> detailItems = [];

    final profile = _context.read<UserBloc>().profileNotifier.value;
    if (profile != null) {
      for (var item in profile.libraryItems) {
        final ValueNotifier<ViewItemState<List<ZxyMedia>>> notifier =
            ValueNotifier(ItemLoading<List<ZxyMedia>>());
        detailItems.add(HomeViewListItemDetails(item: item, state: notifier));
      }
    }

    homeViewLists.value = detailItems;
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
    _eventSub.cancel();
  }
}
