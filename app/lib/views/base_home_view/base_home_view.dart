import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_routes.dart';
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
  late final TextEditingController searchController;

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
      ("TV Shows", AppIcons.show),
      ("Settings", AppIcons.settings),
    ];
    searchController = TextEditingController();
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
    searchController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenData = Screen.of(context);
    return BaseScaffold(
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
            if (!screenData.shouldRenderMobile)
              TopHeader(
                searchController: searchController,
                onSearch: () {
                  if (searchController.value.text.isNotEmpty) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.searchView,
                      arguments: searchController.value.text,
                    );
                    searchController.clear();
                  }
                },
              ),
            if (!screenData.shouldRenderMobile) AppTheme.boxHeightM,
            Expanded(
              child: Row(
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
                              SizedBox(height: 20),
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
            return Visibility(
              replacement: GlassContainer(
                borderOpacity: 0.15,
                containerOpacity: 0.0,
                radius: AppTheme.roundedXXLarge,
                width: screenData.width,
                height: 80,
                padding: EdgeInsets.all(AppTheme.spacingS),
                margin: EdgeInsets.only(
                  left: AppTheme.spacingL,
                  right: AppTheme.spacingL,
                  bottom: AppTheme.spacingL,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(leftCards.length, (index) {
                    return ColorAnimatedCard(
                      width: 80,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXS,
                        vertical: AppTheme.spacingS,
                      ),
                      radius: AppTheme.roundedXLarge,
                      onTap: () {
                        vm.selectedIndex.value = index;
                      },
                      isSelected: value == index,
                      baseColor: AppTheme.lightGreyBg,
                      animationSelectedColor: color ?? AppTheme.accentColor,
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            leftCards[index].$2,
                            color: AppTheme.textPrimary,
                            height: 18,
                            width: 18,
                          ),
                          SizedBox(height: AppTheme.spacingXS),
                          Text(
                            leftCards[index].$1,
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(
                                  color: AppTheme.textPrimary,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              visible: !screenData.shouldRenderMobile,
              child: GlassContainer(
                borderOpacity: 0.15,
                containerOpacity: 0.15,
                width: 280,
                radius: AppTheme.roundedMedium,
                height: double.maxFinite,
                padding: EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  spacing: AppTheme.spacingM,
                  children: List.generate(leftCards.length, (index) {
                    return ColorAnimatedCard(
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
                            color: AppTheme.textPrimary,
                            height: 25,
                            width: 25,
                          ),
                          SizedBox(width: AppTheme.spacingS),
                          Text(
                            leftCards[index].$1,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3), // Subtle dark color
                    blurRadius: 6, // Keeps the shadow close
                    spreadRadius: 1, // Small spread for definition
                    offset: const Offset(0, -3), // Moves shadow slightly down
                  ),
                ],

                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
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
                              : AppTheme.textPrimary,
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
                                    : AppTheme.textPrimary,
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
