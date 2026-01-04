import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/dependencies.dart';
import 'package:zxy_app/views/base_home_view/base_home_view_model.dart';
import 'package:zxy_app/views/filter_view/filter_view.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';
import 'package:zxy_app/views/home_view/home_view.dart';

class BaseHomeView extends StatefulWidget {
  final Dependencies deps;
  const BaseHomeView({super.key, required this.deps});

  @override
  State<BaseHomeView> createState() => _BaseHomeViewState();
}

class _BaseHomeViewState extends State<BaseHomeView> {
  late final BaseHomeViewModel vm;
  late final List<Widget> baseChildren;
  late final List<(String, String)> leftCards;
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    vm = context.read<BaseHomeViewModel>();
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
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ValueListenableBuilder(
        valueListenable: context.read<ImageBloc>().bgGradColor,
        builder: (_, color, _) {
          return AnimatedContainer(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            duration: const Duration(seconds: 1),
            height: double.maxFinite,
            width: double.maxFinite,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: color != null
                    ? [color.withOpacity(0.3), AppTheme.backgroundDark]
                    : [AppTheme.backgroundDark, AppTheme.backgroundDark],
                stops: color != null ? [0.0, 1.0] : [0.0, 1.0],
              ),
            ),
            child: Column(
              children: [
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
                AppTheme.boxHeightM,
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ValueListenableBuilder(
                          valueListenable: vm.selectedIndex,
                          builder: (_, value, _) {
                            return ValueListenableBuilder(
                              valueListenable: context
                                  .read<ImageBloc>()
                                  .bgGradColor,
                              builder: (_, color, _) {
                                return Container(
                                  width: double.maxFinite,
                                  height: double.maxFinite,
                                  padding: EdgeInsets.all(AppTheme.spacingM),
                                  decoration: BoxDecoration(
                                    borderRadius: AppTheme.roundedMedium,
                                    color: AppTheme.cardBgColor,
                                  ),
                                  child: Column(
                                    spacing: AppTheme.spacingM,
                                    children: List.generate(leftCards.length, (
                                      index,
                                    ) {
                                      return ColorAnimatedCard(
                                        onTap: () {
                                          vm.selectedIndex.value = index;
                                        },
                                        isSelected: value == index,
                                        baseColor: AppTheme.lightGreyBg,
                                        animationSelectedColor:
                                            color ?? AppTheme.accentColor,
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
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
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
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        flex: 13,
                        child: ValueListenableBuilder(
                          valueListenable: vm.selectedIndex,
                          builder: (_, index, _) {
                            return ZxyFadeIndexedStack(
                              key: ValueKey("Switcher"),
                              duration: const Duration(milliseconds: 500),
                              index: index,
                              children: baseChildren,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TopHeader extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final bool showBack;
  const TopHeader({
    super.key,
    required this.searchController,
    required this.onSearch,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: context.read<ImageBloc>().bgGradColor,
      builder: (_, color, _) {
        return Container(
          width: double.maxFinite,
          height: 80,
          padding: EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            borderRadius: AppTheme.roundedMedium,
            color: AppTheme.cardBgColor,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showBack)
                InkWell(
                  hoverColor: Colors.transparent,
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios, size: 34),
                      Text(
                        "Back",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      AppTheme.boxWidthXL,
                    ],
                  ),
                ),
              Image.asset(AppIcons.logo),
              AppTheme.boxWidthL,
              SizedBox(
                width: 400,
                child: TextField(
                  enabled: true,
                  onSubmitted: (_) {
                    onSearch();
                  },
                  controller: searchController,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: color ?? AppTheme.accentColor,
                      ),
                      borderRadius: AppTheme.roundedMedium,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.roundedMedium,
                    ),
                    fillColor: AppTheme.lightGreyBg,
                    hintText: "Search Movies and Shows",
                    hintStyle: Theme.of(context).textTheme.labelLarge,
                    prefixIcon: Icon(Icons.search),
                  ),
                  cursorColor: color ?? AppTheme.accentColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ColorAnimatedCard extends StatefulWidget {
  final Color animationSelectedColor;
  final Color baseColor;
  final bool isSelected;
  final Widget child;
  final VoidCallback onTap;
  const ColorAnimatedCard({
    super.key,
    required this.animationSelectedColor,
    required this.baseColor,
    this.isSelected = false,
    required this.child,
    required this.onTap,
  });

  @override
  State<ColorAnimatedCard> createState() => _ColorAnimatedCardState();
}

class _ColorAnimatedCardState extends State<ColorAnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _colorAnimationController;
  late final Animation<Color?> _colorAnim;
  late final ColorTween _colorTween;

  @override
  void initState() {
    super.initState();
    _colorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _colorTween = ColorTween(
      begin: widget.isSelected
          ? widget.animationSelectedColor
          : widget.baseColor,
      end: widget.isSelected ? widget.baseColor : widget.animationSelectedColor,
    );
    _colorAnim = _colorTween.animate(_colorAnimationController);
  }

  @override
  void didUpdateWidget(covariant ColorAnimatedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      _colorTween.begin = widget.isSelected
          ? widget.animationSelectedColor
          : widget.baseColor;
      _colorTween.end = widget.isSelected
          ? widget.baseColor
          : widget.animationSelectedColor;
      _colorAnimationController.reset();
    }
    if (oldWidget.animationSelectedColor != widget.animationSelectedColor) {
      _colorTween.begin = _colorAnim.value;
      _colorTween.end = widget.animationSelectedColor;
      _colorAnimationController.reset();
      if (widget.isSelected) {
        _colorAnimationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnim,
      child: widget.child,
      builder: (_, child) {
        return GestureDetector(
          onTap: () {
            widget.onTap();
          },
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: _colorAnim.value,
              borderRadius: AppTheme.roundedMedium,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class ZxyFadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const ZxyFadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ZxyFadeIndexedStack> createState() => _ZxyFadeIndexedStackState();
}

class _ZxyFadeIndexedStackState extends State<ZxyFadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Start fully visible
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant ZxyFadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: IndexedStack(index: widget.index, children: widget.children),
    );
  }
}
