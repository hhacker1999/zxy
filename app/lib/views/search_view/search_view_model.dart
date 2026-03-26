// ignore_for_file: prefer_interpolation_to_compose_strings
import 'package:flutter/foundation.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/views/view_item_state.dart';

class SearchViewModel {
  final MediaUsecase mediaUC;
  int _showPage = 0;
  int _moviePage = 0;
  int _totalMoviePages = 0;
  int _totalShowPages = 0;
  late String _keyword;
  bool _isLoadingMoreResults = false;

  SearchViewModel({required this.mediaUC});

  ValueNotifier<ViewItemState<List<ZxyMedia>>> itemsState = ValueNotifier(
    ItemInitial(),
  );

  Future<void> loadResults(String keyword) async {
    _keyword = keyword;
    itemsState.value = ItemLoading();
    try {
      final List<Future<ZxyPaginatedResponse>> futures = List.empty(
        growable: true,
      );
      futures.add(mediaUC.searchShows(1, keyword));
      futures.add(mediaUC.searchMovies(1, keyword));
      final res = await Future.wait(futures);
      final showsRes = res[0];
      final moviesRes = res[1];
      _showPage = showsRes.page;
      _totalShowPages = showsRes.totalPages;
      _moviePage = moviesRes.page;
      _totalMoviePages = moviesRes.totalPages;
      final List<ZxyMedia> intermixedList = List.empty(growable: true);
      int iterations = showsRes.results.length;
      if (moviesRes.results.length > iterations) {
        iterations = moviesRes.results.length;
      }
      for (var i = 0; i < iterations; i++) {
        if (i < showsRes.results.length) {
          intermixedList.add(showsRes.results[i]);
        }
        if (i < moviesRes.results.length) {
          intermixedList.add(moviesRes.results[i]);
        }
      }
      itemsState.value = ItemLoaded(data: intermixedList);
    } catch (e) {
      if (kDebugMode) {
        print("Error getting search results " + e.toString());
      }
      itemsState.value = ItemError(error: e.toString());
      rethrow;
    }
  }

  void reset() {
    itemsState.value = ItemInitial();
  }

  Future<void> loadMoreResults() async {
    if (_isLoadingMoreResults) return;
    try {
      _isLoadingMoreResults = true;
      final oldItems = (itemsState.value as ItemLoaded<List<ZxyMedia>>);
      final List<Future<ZxyPaginatedResponse<ZxyMedia>>> futures = List.empty(
        growable: true,
      );
      if (_showPage < _totalShowPages) {
        futures.add(mediaUC.searchShows(_showPage + 1, _keyword));
      }
      if (_moviePage < _totalMoviePages) {
        futures.add(mediaUC.searchMovies(_moviePage + 1, _keyword));
      }
      if (futures.isEmpty) {
        if (kDebugMode) {
          print("We dont have anymore items to load");
        }
        return;
      }
      final res = await Future.wait(futures);
      if (res.length != 2) {
        if (res.first.results.first.type == ZxyMediaType.movie) {
          _moviePage = res.first.page;
          _totalMoviePages = res.first.totalPages;
        } else {
          _showPage = res.first.page;
          _totalShowPages = res.first.totalPages;
        }
        itemsState.value = ItemLoaded(
          data: [...oldItems.data, ...res.first.results],
        );
        return;
      }

      // NOTE: Intermixing is only required when we have result from both movies and shows
      final showsRes = res[0];
      final moviesRes = res[1];
      _showPage = showsRes.page;
      _totalShowPages = showsRes.totalPages;
      _moviePage = moviesRes.page;
      _totalMoviePages = moviesRes.totalPages;
      final List<ZxyMedia> intermixedList = List.empty(growable: true);
      int iterations = showsRes.results.length;
      if (moviesRes.results.length > iterations) {
        iterations = moviesRes.results.length;
      }
      for (var i = 0; i < iterations; i++) {
        if (i <= showsRes.results.length) {
          intermixedList.add(showsRes.results[i]);
        }
        if (i <= moviesRes.results.length) {
          intermixedList.add(moviesRes.results[i]);
        }
      }
      itemsState.value = ItemLoaded(
        data: [...oldItems.data, ...intermixedList],
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error getting search results " + e.toString());
      }
      // itemsState.value = ItemError(error: e.toString());
      rethrow;
    } finally {
      _isLoadingMoreResults = false;
    }
  }

  void dispose() {
    itemsState.dispose();
  }
}
