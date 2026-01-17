import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';

import 'shared/glass_container.dart';

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
        return GlassContainer(
          borderOpacity: 0.15,
          containerOpacity: 0.15,
          width: double.maxFinite,
          height: 80,
          radius: AppTheme.roundedMedium,
          padding: EdgeInsets.all(AppTheme.spacingM),
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
  final EdgeInsets padding;
  final BorderRadiusGeometry? radius;
  final double width;
  const ColorAnimatedCard({
    super.key,
    required this.animationSelectedColor,
    required this.baseColor,
    this.isSelected = false,
    required this.child,
    this.width = double.maxFinite,
    required this.onTap,
    this.radius,
    this.padding = const EdgeInsets.all(AppTheme.spacingM),
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
            width: widget.width,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _colorAnim.value,
              borderRadius: widget.radius ?? AppTheme.roundedMedium,
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
  late List<bool> activated;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Start fully visible
    _controller.value = 1.0;
    intialiseActivateList();
  }

  void intialiseActivateList() {
    activated = List.generate(widget.children.length, (index) {
      return index == widget.index;
    });
  }

  @override
  void didUpdateWidget(covariant ZxyFadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      intialiseActivateList();
    }
    if (oldWidget.index != widget.index) {
      activated[widget.index] = true;
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
      child: IndexedStack(
        index: widget.index,
        children: List.generate(widget.children.length, (index) {
          return activated[index] ? widget.children[index] : const SizedBox();
        }),
      ),
    );
  }
}
