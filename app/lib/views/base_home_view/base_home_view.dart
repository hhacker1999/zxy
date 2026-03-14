import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:zxy_app/views/top_header.dart';
import 'package:zxy_app/views/base_home_view/modern_navigation_drawer.dart';

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
        create: (_) =>
            SettingsViewModel(widget.deps.authUc, widget.deps.wsService),
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
      padding: EdgeInsets.zero,
      loading: vm.scaffoldLoading,
      bottomNavigationBar: screenData.shouldRenderMobile
          ? ZxyNavBar(vm: vm, cards: leftCards)
          : null,
      builder: (_, color) {
        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    left: screenData.shouldRenderMobile ? 0 : 108.0,
                    child: ValueListenableBuilder(
                      valueListenable: vm.selectedIndex,
                      builder: (_, index, _) {
                        return ZxyFadeIndexedStack(
                          key: const ValueKey("Switcher"),
                          duration: const Duration(milliseconds: 500),
                          index: index,
                          children: baseChildren,
                        );
                      },
                    ),
                  ),
                  if (!screenData.shouldRenderMobile)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      child: ModernNavigationDrawer(
                        vm: vm,
                        leftCards: leftCards,
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
            return Container(
              // borderOpacity: 0.15,
              // containerOpacity: 0.15,
              margin: EdgeInsets.only(
                top: AppTheme.spacingM,
                bottom: AppTheme.spacingM,
                left: AppTheme.spacingM,
              ),
              width: 280,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),

                borderRadius: AppTheme.roundedXXLarge,
              ),
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
                    animationSelectedColor: AppTheme.accentColor,
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
          builder: (_, accentColor, _) {
            final accent = accentColor ?? Colors.white;
            return _ZxyNavBarShell(
              accent: accent,
              selectedIndex: selectedIndex,
              cards: cards,
              vm: vm,
            );
          },
        );
      },
    );
  }
}

class _ZxyNavBarShell extends StatelessWidget {
  final Color accent;
  final int selectedIndex;
  final List<(String, String)> cards;
  final BaseHomeViewModel vm;

  const _ZxyNavBarShell({
    required this.accent,
    required this.selectedIndex,
    required this.cards,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spacingM,
        right: AppTheme.spacingM,
        bottom: AppTheme.spacingM,
        top: AppTheme.spacingS,
      ),
      child: ClipRRect(
        borderRadius: AppTheme.roundedXLarge,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: AppTheme.roundedXLarge,
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(cards.length, (index) {
                return _ZxyNavItem(
                  label: cards[index].$1,
                  iconPath: cards[index].$2,
                  isSelected: selectedIndex == index,
                  accent: accent,
                  onTap: () => vm.selectedIndex.value = index,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZxyNavItem extends StatefulWidget {
  final String label;
  final String iconPath;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _ZxyNavItem({
    required this.label,
    required this.iconPath,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_ZxyNavItem> createState() => _ZxyNavItemState();
}

class _ZxyNavItemState extends State<_ZxyNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final Color iconColor = isSelected ? Colors.white : AppTheme.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Indicator dot + icon stacked
              Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  // Soft glow bg pill behind icon when selected
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 40,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.accent.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      widget.iconPath,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    ),
                  ),
                  // Indicator dot above icon
                  if (isSelected)
                    Positioned(
                      top: -6,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: isSelected ? 16 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: widget.accent,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: widget.accent.withOpacity(0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: iconColor,
                  letterSpacing: 0.2,
                ),
                child: Text(widget.label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
