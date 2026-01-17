import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/views/base_home_view/base_home_view.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';
import 'package:zxy_app/views/search_view/search_view_model.dart';
import 'package:zxy_app/views/shared/base_scaffold.dart';
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
    searchController = TextEditingController(text: widget.keyword);
    scrollController = ScrollController();
    vm = context.read<SearchViewModel>()..loadResults(widget.keyword);
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      builder: (_, color) {
        return Column(
          children: [
            TopHeader(
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
                    double width = 160 + AppTheme.spacingL;
                    double ct = constr.maxWidth / width;
                    ct = ct.floorToDouble();
                    final widthUtilised = ct * width;
                    if ((constr.maxWidth - widthUtilised) > width / 2) {
                      width = constr.maxWidth / (ct + 1);
                      ct += 1;
                    }
                    final itemAspectRatio = 2 / 3.8;
                    final imageHeight = width / (2.2 / 3);
                    final height = width / itemAspectRatio;
                    return ValueListenableBuilder(
                      valueListenable: vm.itemsState,
                      builder: (_, itemState, _) {
                        if (itemState is ItemLoading ||
                            itemState is ItemInitial) {
                          return Center(child: CupertinoActivityIndicator());
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisSpacing: AppTheme.spacingL,
                                mainAxisSpacing: AppTheme.spacingM,
                                childAspectRatio: itemAspectRatio,
                                crossAxisCount: ct.toInt(),
                              ),
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
                                          : AppRoutes.showView,
                                      arguments: items[index].id,
                                    );
                                  },
                                  width: width,
                                  height: height,
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
        );
      },
    );
  }
}
