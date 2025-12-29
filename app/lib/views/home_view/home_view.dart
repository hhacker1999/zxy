import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/shared/library_card.dart';
import 'package:zxy_app/views/view_item_state.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel homeViewModel;
  @override
  void initState() {
    super.initState();
    homeViewModel = context.read<HomeViewModel>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ValueListenableBuilder(
        valueListenable: homeViewModel.homeViewLists,
        builder: (_, list, _) {
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) {
              return SizedBox(height: AppTheme.spacingXL);
            },
            itemBuilder: (_, index) {
              return ValueListenableBuilder<ViewItemState>(
                valueListenable: list[index].state,
                builder: (_, value, _) {
                  if (value is ItemLoading) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (value is ItemError) {
                    return Center(child: Text(value.error));
                  }
                  final List<ZxyMedia> resourceList =
                      (value as ItemLoaded<List<ZxyMedia>>).value;
                  return LibraryList(
                    resource: resourceList,
                    title: list[index].title,
                    onTap: (res) {
                      if (list[index].type == ZxyMediaType.movie) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.movieView,
                          arguments: res,
                        );
                      } else {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.showView,
                          arguments: res,
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class LibraryList extends StatelessWidget {
  final String title;
  final void Function(ZxyMedia) onTap;
  const LibraryList({
    super.key,
    required this.resource,
    required this.title,
    required this.onTap,
  });

  final List<ZxyMedia> resource;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: AppTheme.spacingS),
        LibraryListItem(resource: resource, onTap: onTap),
      ],
    );
  }
}
