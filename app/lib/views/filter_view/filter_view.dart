import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';
import 'package:zxy_app/views/shared/drop_down.dart';
import 'package:zxy_app/views/shared/library_card.dart';

class FilterView extends StatefulWidget {
  const FilterView({super.key});

  @override
  State<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<FilterView> {
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
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
          AppTheme.boxHeightM,
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
                  double width = 160;
                  double ct = constr.maxWidth / width;
                  ct = ct.floorToDouble();
                  final widthUtilised = ct * width;
                  if ((constr.maxWidth - widthUtilised) > width / 2) {
                    width = constr.maxWidth / (ct + 1);
                    ct += 1;
                  }
                  return ValueListenableBuilder(
                    valueListenable: vm.mediaItems,
                    builder: (_, items, _) {
                      if (items.isEmpty) {
                        return Center(child: CupertinoActivityIndicator());
                      }
                      return GridView.builder(
                        controller: _controller,
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisSpacing: AppTheme.spacingL,
                          mainAxisSpacing: AppTheme.spacingL,
                          childAspectRatio: 2 / 3,
                          crossAxisCount: ct.toInt(),
                        ),
                        itemBuilder: (_, index) {
                          return LibraryCard(
                            resource: items[index],
                            onTap: (_) {
                              Navigator.pushNamed(
                                context,
                                vm.type == ZxyMediaType.shows
                                    ? AppRoutes.showView
                                    : AppRoutes.movieView,
                                arguments: items[index],
                              );
                            },
                            // width: width,
                            // height: width / (2 / 3),
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
