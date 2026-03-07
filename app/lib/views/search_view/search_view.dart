import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/search_view/search_view_model.dart';
import 'package:zxy_app/views/series_view/series_view.dart';
import 'package:zxy_app/views/shared/library_card.dart';
import 'package:zxy_app/views/top_header.dart';
import 'package:zxy_app/views/view_item_state.dart';

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
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (noti) {
                if (scrollController.position.maxScrollExtent == 0) {
                  vm.loadMoreResults();
                  return false;
                }
                final currOffset = scrollController.offset;
                final maxOffset = scrollController.position.maxScrollExtent;
                if ((maxOffset - currOffset) < 200) {
                  vm.loadMoreResults();
                }
                return false;
              },
              child: LayoutBuilder(
                builder: (_, constr) {
                  // double width = 160 + AppTheme.spacingL;
                  // double ct = constr.maxWidth / width;
                  // ct = ct.floorToDouble();
                  // final widthUtilised = ct * width;
                  // if ((constr.maxWidth - widthUtilised) > width / 2) {
                  //   width = constr.maxWidth / (ct + 1);
                  //   ct += 1;
                  // }
                  // final itemAspectRatio = 2 / 3.8;
                  // final imageHeight = width / (2.2 / 3);
                  // final height = width / itemAspectRatio;

                  final ScreenData screenData = Screen.of(context);
                  final double width = screenData.shouldRenderMobile
                      ? 120
                      : 160;
                  final double imageHeight = width / AppConstants.posterAspectRatio;
                  final double itemHeight =
                      imageHeight + (screenData.shouldRenderMobile ? 50 : 58);
                  return ValueListenableBuilder(
                    valueListenable: vm.itemsState,
                    builder: (_, itemState, _) {
                      if (itemState is ItemLoading) {
                        return Center(child: CupertinoActivityIndicator());
                      }
                      if (itemState is ItemInitial) {
                        return Center(
                          child: Text("Search movie or show by name"),
                        );
                      }
                      if (itemState is ItemError) {
                        return Center(
                          child: Text((itemState as ItemError).error),
                        );
                      }
                      final List<ZxyMedia> items =
                          (itemState as ItemLoaded<List<ZxyMedia>>).data;
                      if (items.isEmpty) {
                        return Center(child: Text("No Items found"));
                      }

                      return GridView.builder(
                        clipBehavior: Clip.hardEdge,
                        padding: EdgeInsets.zero,
                        controller: scrollController,
                        itemCount: items.length,

                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: width,
                          crossAxisSpacing: screenData.shouldRenderMobile
                              ? AppTheme.spacingS
                              : AppTheme.spacingL,
                          mainAxisSpacing: screenData.shouldRenderMobile
                              ? AppTheme.spacingXS
                              : AppTheme.spacingM,
                          childAspectRatio: width / itemHeight,
                        ),
                        // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        //   crossAxisSpacing: AppTheme.spacingL,
                        //   mainAxisSpacing: AppTheme.spacingM,
                        //   childAspectRatio: itemAspectRatio,
                        //   crossAxisCount: ct.toInt(),
                        // ),
                        itemBuilder: (_, index) {
                          return ClipRect(
                            key: ValueKey(items[index].id),
                            child: Banner(
                              message: items[index].type == ZxyMediaType.movie
                                  ? "Movie"
                                  : "Show",
                              color: items[index].type == ZxyMediaType.movie
                                  ? Colors.red
                                  : Colors.blue,
                              location: BannerLocation.topEnd,
                              child: LibraryCard(
                                updateColorOnHover: true,
                                resource: items[index],
                                onTap: (_) {
                                  Navigator.pushNamed(
                                    context,
                                    items[index].type == ZxyMediaType.movie
                                        ? AppRoutes.movieView
                                        : AppRoutes.seriesView,
                                    arguments:
                                        items[index].type == ZxyMediaType.movie
                                        ? items[index].id
                                        : SeriesViewData(id: items[index].id),
                                  );
                                },
                                width: width,
                                height: itemHeight,
                                imageHeight: imageHeight,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
