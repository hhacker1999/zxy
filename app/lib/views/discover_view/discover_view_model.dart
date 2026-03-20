import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/auth/auth.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/view_item_state.dart';

class DiscoverViewModel {
  final MediaUsecase mediaUc;
  final AuthUsecase authUc;
  BuildContext? _context;

  ValueNotifier<LibraryFilter> filterNotifier = ValueNotifier(
    LibraryFilter.defaultFilter(),
  );

  /// Display name of the currently active Trakt list (null when using internal filters).
  ValueNotifier<String?> activeListName = ValueNotifier(null);

  ValueNotifier<ViewItemState<List<ZxyMedia>>> viewState = ValueNotifier(
    ItemLoading(),
  );

  bool _loading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  List<ZxyMedia> _items = [];
  int? index;
  ProfileLibraryItem? libraryItem;

  DiscoverViewModel({required this.mediaUc, required this.authUc}) {
    initialise();
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  void initialise() {
    getItemsFromFilter();
  }

  void onProfileLibraryItem(ProfileLibraryItem item, int idx) {
    index = idx;
    onFilterUpdate(item.filter, listName: item.name);
  }

  void onFilterUpdate(LibraryFilter filter, {String? listName}) {
    filterNotifier.value = filter;
    activeListName.value = listName;
    _currentPage = 1;
    _hasMore = true;
    _items = [];
    getItemsFromFilter();
  }

  /// Resets the discover view to initial default state.
  void resetFilter() {
    activeListName.value = null;
    index = null;
    libraryItem = null;
    _currentPage = 1;
    _hasMore = true;
    _items = [];
    onFilterUpdate(LibraryFilter.defaultFilter());
  }

  /// Saves the current filter as a home-page library item.
  /// If `index` is set (editing an existing item), replaces it; otherwise appends.
  Future<bool> saveFilterToHomeList(
    String name,
    List<ProfileLibraryItem> currentItems,
  ) async {
    try {
      final newItem = ProfileLibraryItem(
        name: name,
        filter: filterNotifier.value,
      );
      final updatedList = List<ProfileLibraryItem>.from(currentItems);
      if (index != null && index! >= 0 && index! < updatedList.length) {
        // Update existing item
        updatedList[index!] = newItem;
      } else {
        // Create new item
        updatedList.add(newItem);
      }
      await authUc.updateProfileList(updatedList);
      // final profile = await authUc.getUserProfile();
      // _context!.read<UserBloc>().profile = profile;
      // _context!.read<HomeViewModel>().reload(_context!);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Error saving filter to home list: $e");
      }
      return false;
    }
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

      final filter = filterNotifier.value.copyWith(
        page: _currentPage,
        items: 20,
      );
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
