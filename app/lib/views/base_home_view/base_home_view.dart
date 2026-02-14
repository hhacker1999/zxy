import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/dependencies.dart';
import 'package:zxy_app/main.dart';
import 'package:zxy_app/views/base_home_view/base_home_view_model.dart';
import 'package:zxy_app/views/filter_view/filter_view.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';
import 'package:zxy_app/views/home_view/home_view.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/search_view/search_view.dart';
import 'package:zxy_app/views/search_view/search_view_model.dart';
import 'package:zxy_app/views/settings_view/settings_view.dart';
import 'package:zxy_app/views/settings_view/settings_view_model.dart';
import 'package:zxy_app/views/shared/base_scaffold.dart';
import 'package:zxy_app/views/shared/glass_container.dart';
import 'package:zxy_app/views/top_header.dart';

class BaseHomeView extends StatefulWidget {
  final Dependencies deps;
  const BaseHomeView({super.key, required this.deps});

  @override
  State<BaseHomeView> createState() => _BaseHomeViewState();
}

class _BaseHomeViewState extends State<BaseHomeView> with RouteAware {
  late final BaseHomeViewModel vm;
  late final List<Widget> baseChildren;
  late final List<(String, String)> leftCards;

  @override
  void initState() {
    super.initState();
    vm = context.read<BaseHomeViewModel>();
    vm.initialise();
    baseChildren = [
      HomeView(),
      Provider<FilterViewModel>(
        key: ValueKey<String>("Movie Library"),
        create: (_) => FilterViewModel(
          type: ZxyMediaType.movie,
          mediaUc: widget.deps.mediaUc,
        ),
        dispose: (_, vm) => vm.dispose(),
        builder: (_, _) {
          return FilterView();
        },
      ),
      Provider<SearchViewModel>(
        create: (_) => SearchViewModel(mediaUC: widget.deps.mediaUc),
        dispose: (_, vm) => vm.dispose(),
        builder: (_, _) {
          return SearchView(keyword: "");
        },
      ),
      Provider<FilterViewModel>(
        key: ValueKey<String>("Show Library"),
        create: (_) => FilterViewModel(
          type: ZxyMediaType.shows,
          mediaUc: widget.deps.mediaUc,
        ),
        dispose: (_, vm) => vm.dispose(),
        builder: (_, _) {
          return FilterView();
        },
      ),
      ChangeNotifierProvider<SettingsViewModel>(
        create: (_) => SettingsViewModel(widget.deps.authUc),
        builder: (_, _) {
          return SettingsView();
        },
      ),
    ];
    leftCards = [
      ("Home", AppIcons.home),
      ("Movies", AppIcons.movie),
      ("Search", AppIcons.search),
      ("TV Shows", AppIcons.show),
      ("Settings", AppIcons.settings),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    context.read<HomeViewModel>().initialiseContinueWatching();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenData = Screen.of(context);
    return BaseScaffold(
      loading: vm.scaffoldLoading,
      bottomNavigationBar: screenData.shouldRenderMobile
          ? ZxyNavBar(
              vm: vm,
              cards: leftCards,
              // screenData: screenData,
            )
          : null,
      builder: (_, color) {
        return Column(
          children: [
            // if (!screenData.shouldRenderMobile)
            //   TopHeader(
            //     searchController: searchController,
            //     onSearch: () {
            //       if (searchController.value.text.isNotEmpty) {
            //         Navigator.pushNamed(
            //           context,
            //           AppRoutes.searchView,
            //           arguments: searchController.value.text,
            //         );
            //         searchController.clear();
            //       }
            //     },
            //   ),
            // if (!screenData.shouldRenderMobile) AppTheme.boxHeightM,
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: !screenData.shouldRenderMobile,
                    child: NavigationDrawerBar(
                      vm: vm,
                      leftCards: leftCards,
                      screenData: screenData,
                    ),
                  ),
                  if (!screenData.shouldRenderMobile)
                    SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: vm.selectedIndex,
                      builder: (_, index, _) {
                        return Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).viewPadding.top,
                            ),
                            Expanded(
                              child: ZxyFadeIndexedStack(
                                key: ValueKey("Switcher"),
                                duration: const Duration(milliseconds: 500),
                                index: index,
                                children: baseChildren,
                              ),
                            ),
                            if (screenData.shouldRenderMobile)
                              SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class NavigationDrawerBar extends StatelessWidget {
  const NavigationDrawerBar({
    super.key,
    required this.vm,
    required this.leftCards,
    required this.screenData,
  });

  final BaseHomeViewModel vm;
  final List<(String, String)> leftCards;
  final ScreenData screenData;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: vm.selectedIndex,
      builder: (_, value, _) {
        return ValueListenableBuilder(
          valueListenable: context.read<ImageBloc>().bgGradColor,
          builder: (_, color, _) {
            return GlassContainer(
              borderOpacity: 0.15,
              containerOpacity: 0.15,
              width: 280,
              radius: AppTheme.roundedXXLarge,
              // height: 350,
              padding: EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                spacing: AppTheme.spacingM,
                children: List.generate(leftCards.length, (index) {
                  return ColorAnimatedCard(
                    radius: AppTheme.roundedLarge,
                    onTap: () {
                      vm.selectedIndex.value = index;
                    },
                    isSelected: value == index,
                    baseColor: AppTheme.lightGreyBg,
                    animationSelectedColor: color ?? AppTheme.accentColor,
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          leftCards[index].$2,
                          color: value != index
                              ? AppTheme.textSecondary
                              : AppTheme.backgroundDark,
                          height: 25,
                          width: 25,
                        ),
                        SizedBox(width: AppTheme.spacingS),
                        Text(
                          leftCards[index].$1,
                          style: Theme.of(context).textTheme.titleLarge!
                              .copyWith(
                                color: value != index
                                    ? AppTheme.textSecondary
                                    : AppTheme.backgroundDark,
                              ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}

class ZxyNavBar extends StatelessWidget {
  final List<(String, String)> cards;
  final BaseHomeViewModel vm;
  const ZxyNavBar({super.key, required this.cards, required this.vm});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: vm.selectedIndex,
      builder: (_, selectedIndex, _) {
        return ValueListenableBuilder(
          valueListenable: context.read<ImageBloc>().bgGradColor,
          builder: (_, color, _) {
            return Container(
              height: 70,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundBlack,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3), // Subtle dark color
                    blurRadius: 6, // Keeps the shadow close
                    spreadRadius: 1, // Small spread for definition
                    offset: const Offset(0, -3), // Moves shadow slightly down
                  ),
                ],

                // gradient: LinearGradient(
                //   begin: Alignment.topCenter,
                //   end: Alignment.bottomCenter,
                //   colors: [
                //     Colors.black.withOpacity(0.2),
                //     Colors.black.withOpacity(0.9),
                //   ],
                // ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(cards.length, (index) {
                  final card = cards[index];
                  return InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      vm.selectedIndex.value = index;
                    },
                    child: Column(
                      spacing: AppTheme.spacingXS,
                      children: [
                        SvgPicture.asset(
                          card.$2,
                          color: selectedIndex == index
                              ? color ?? AppTheme.accentColor
                              : AppTheme.textSecondary,
                          height: 25,
                          width: 25,
                        ),
                        Text(
                          card.$1,
                          style: Theme.of(context).textTheme.labelSmall!
                              .copyWith(
                                fontSize: 10,
                                color: selectedIndex == index
                                    ? color ?? AppTheme.accentColor
                                    : AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}
