import 'package:flutter/foundation.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/views/view_item_state.dart';

class DiscoverViewModel {
  final MediaUsecase mediaUc;

  ValueNotifier<LibraryFilter?> filterNotifier = ValueNotifier(null);
  ValueNotifier<ViewItemState> viewState = ValueNotifier(ItemInitial());

  DiscoverViewModel({required this.mediaUc});

  Future<void> getItemsFromFilter() async {
    if (filterNotifier.value == null) {
      return;
    }
    try {
      viewState.value = ItemLoading();
      final items = await mediaUc.discoverLibrary(
        filter: filterNotifier.value!,
      );
      viewState.value = ItemLoaded(data: items);
    } catch (e) {
      viewState.value = ItemError(error: e.toString());
    }
  }

  void onFilterUpdate(LibraryFilter filter) {
    filterNotifier.value = filter;
    getItemsFromFilter();
  }

  void dispose() {
    filterNotifier.dispose();
    viewState.dispose();
  }
}
