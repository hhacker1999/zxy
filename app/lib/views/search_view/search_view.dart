import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/search_view/search_view_model.dart';
import 'package:zxy_app/views/shared/media_grid.dart';
import 'package:zxy_app/views/top_header.dart';

class SearchView extends StatefulWidget {
  final String keyword;
  const SearchView({super.key, required this.keyword});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late final TextEditingController searchController;
  late final ScrollController scrollController;
  late final SearchViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = context.read<SearchViewModel>();
    searchController = TextEditingController(text: widget.keyword);
    if (widget.keyword.isNotEmpty) {
      vm.loadResults(widget.keyword);
    }
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenData = Screen.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: screenData.shouldRenderMobile
            ? MediaQuery.of(context).padding.top
            : AppTheme.spacingM,
      ),
      child: Column(
        children: [
          TopHeader(
            onChanged: (val) {
              if (val.isEmpty) {
                vm.reset();
              }
            },
            showBack: true,
            searchController: searchController,
            onSearch: () {
              if (searchController.value.text.isNotEmpty) {
                vm.loadResults(searchController.value.text);
              }
            },
          ),
          AppTheme.boxHeightM,
          Expanded(
            child: MediaGrid(
              showType: true,
              onScrollNearEnd: () {
                vm.loadMoreResults();
              },
              notifier: vm.itemsState,
              scrollController: scrollController,
            ),
          ),
        ],
      ),
    );
  }
}

