import 'package:flutter/foundation.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/views/view_item_state.dart';

class DiscoverViewModel {
  final MediaUsecase mediaUc;

  ValueNotifier<LibraryFilter> filterNotifier =
      ValueNotifier(LibraryFilter.defaultFilter());

  /// Display name of the currently active Trakt list (null when using internal filters).
  ValueNotifier<String?> activeListName = ValueNotifier(null);

  ValueNotifier<ViewItemState<List<ZxyMedia>>> viewState =
      ValueNotifier(ItemLoading());

  bool _loading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  List<ZxyMedia> _items = [];

  DiscoverViewModel({required this.mediaUc});

  /// Called when the view first loads.
  void init([LibraryFilter? filter]) {
    if (filter != null) {
      filterNotifier.value = filter;
    }
    getItemsFromFilter();
  }

  void onFilterUpdate(LibraryFilter filter, {String? listName}) {
    filterNotifier.value = filter;
    activeListName.value = listName;
    _currentPage = 1;
    _hasMore = true;
    _items = [];
    getItemsFromFilter();
  }

  void loadMore() {
    if (!_hasMore || _loading) return;
    getItemsFromFilter(isLoadMore: true);
  }

  Future<void> getItemsFromFilter({bool isLoadMore = false}) async {
    if (_loading) return;

    try {
      _loading = true;
      if (!isLoadMore) {
        viewState.value = ItemLoading();
      }

      final filter = filterNotifier.value.copyWith(page: _currentPage);
      final response = await mediaUc.discoverLibrary(filter: filter);

      if (isLoadMore) {
        _items.addAll(response.results);
      } else {
        _items = List.from(response.results);
      }

      _currentPage = response.page + 1;
      _hasMore = response.results.isNotEmpty;
      viewState.value = ItemLoaded(data: List.from(_items));
      _loading = false;
    } catch (e) {
      _loading = false;
      if (!isLoadMore) {
        viewState.value = ItemError(error: e.toString());
      }
      if (kDebugMode) {
        print("Error in discover: $e");
      }
    }
  }

  void dispose() {
    filterNotifier.dispose();
    activeListName.dispose();
    viewState.dispose();
  }
}
