import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/series_view/series_view.dart';
import 'package:zxy_app/views/shared/drop_down.dart';
import 'package:zxy_app/views/shared/library_card.dart';

class FilterView extends StatefulWidget {
  const FilterView({super.key});

  @override
  State<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<FilterView> {
  static const _posterAspectRatio = (2 / 3);
  late final FilterViewModel vm;
  late final ScrollController _controller;
  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    vm = context.read<FilterViewModel>();
    vm.loadItems();
  }

  @override
  void dispose() {
    _controller.dispose();
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
          ValueListenableBuilder(
            valueListenable: vm.cFilter,
            builder: (_, value, _) {
              return Row(
                children: [
                  ModernDropdown<String>(
                    initialSelection: value.$1.type.toString(),
                    onSelected: (value) {
                      if (value == null) {
                        if (kDebugMode) {
                          print("Null value in filter");
                        }
                        return;
                      }
                      vm.onMainFilterChange(value);
                    },
                    entries: List.generate(vm.filters.length, (index) {
                      return DropdownMenuEntry(
                        value: vm.filters[index].type.toString(),
                        label: vm.filters[index].showValue,
                      );
                    }),
                  ),
                  if (value.$1.type != FilterType.trending) ...[
                    AppTheme.boxWidthM,
                    ModernDropdown<String>(
                      initialSelection: value.$2 == null
                          ? (value.$1.type == FilterType.year
                                ? value.$1.possibleValues.first.sendValue
                                : "None")
                          : value.$2!.sendValue,
                      onSelected: (value) {
                        if (value == null) {
                          if (kDebugMode) {
                            print("Null value in filter");
                          }
                          return;
                        }
                        vm.onSecondaryFilterChange(value);
                      },
                      entries: List.generate(
                        value.$1.type != FilterType.year
                            ? value.$1.possibleValues.length + 1
                            : value.$1.possibleValues.length,
                        (index) {
                          if (index == 0 && value.$1.type != FilterType.year) {
                            return DropdownMenuEntry(
                              value: "None",
                              label: "None",
                            );
                          }
                          final newIndex = value.$1.type != FilterType.year
                              ? index - 1
                              : index;
                          return DropdownMenuEntry(
                            value: value.$1.possibleValues[newIndex].sendValue,
                            label: value.$1.possibleValues[newIndex].showValue,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          screenData.shouldRenderMobile
              ? AppTheme.boxHeightS
              : AppTheme.boxHeightM,
          Expanded(
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (noti) {
                if (_controller.position.maxScrollExtent == 0) {
                  vm.loadItems();
                  return false;
                }
                final currOffset = _controller.offset;
                final maxOffset = _controller.position.maxScrollExtent;
                if ((currOffset) / maxOffset > 0.5) {
                  vm.loadItems();
                }
                return false;
              },
              child: LayoutBuilder(
                builder: (_, constr) {
                  final ScreenData screenData = Screen.of(context);
                  final double width = screenData.shouldRenderMobile
                      ? 120
                      : 160;
                  final double imageHeight = width / _posterAspectRatio;
                  final double itemHeight =
                      imageHeight + (screenData.shouldRenderMobile ? 50 : 58);
                  return ValueListenableBuilder(
                    valueListenable: vm.mediaItems,
                    builder: (_, items, _) {
                      if (items.isEmpty) {
                        return Center(child: CupertinoActivityIndicator());
                      }
                      return GridView.builder(
                        padding: EdgeInsets.zero,
                        controller: _controller,
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
                        itemBuilder: (_, index) {
                          return Center(
                            child: LibraryCard(
                              updateColorOnHover: true,
                              key: ValueKey(index),
                              resource: items[index],
                              onTap: (_) {
                                Navigator.pushNamed(
                                  context,
                                  vm.type == ZxyMediaType.shows
                                      ? AppRoutes.seriesView
                                      : AppRoutes.movieView,
                                  arguments: vm.type == ZxyMediaType.shows
                                      ? SeriesViewData(id: items[index].id)
                                      : items[index].id,
                                );
                              },
                              width: width,
                              imageHeight: imageHeight,
                              height: itemHeight,
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
