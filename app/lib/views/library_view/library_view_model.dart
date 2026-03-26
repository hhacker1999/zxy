import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/bloc/events_bloc.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/views/view_item_state.dart';

class LibraryViewModel {
  final MediaUsecase mediaUc;
  late final StreamSubscription<BaseEvent> _eventSub;

  ValueNotifier<ViewItemState<List<ZxyMedia>>> viewState = ValueNotifier(
    ItemLoading(),
  );

  bool _loading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  List<ZxyMedia> _items = [];

  LibraryViewModel({required this.mediaUc});

  void initialise(BuildContext context) {
    _eventSub = context.read<EventsBloc>().eventStream.listen((event) {
      if (event is UpdatedLibrary) {
        _currentPage = 1;
        _hasMore = true;
        _items = [];
        getItems();
      }
    });

    getItems();
  }

  void loadMore() {
    if (!_hasMore || _loading) return;
    getItems(isLoadMore: true);
  }

  Future<void> getItems({bool isLoadMore = false}) async {
    if (_loading) return;

    try {
      _loading = true;
      if (!isLoadMore) {
        viewState.value = ItemLoading();
      }

      final filter = LibraryFilter.defaultFilter().copyWith(
        type: 'library',
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
        print("Error in library: $e");
      }
    }
  }

  void dispose() {
    viewState.dispose();
    _eventSub.cancel();
  }
}
