import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/views/base_home_view/base_home_view_model.dart';
import 'package:zxy_app/views/shared/glass_container.dart';

class ModernNavigationDrawer extends StatelessWidget {
  final BaseHomeViewModel vm;
  final List<(String, String)> leftCards;

  const ModernNavigationDrawer({
    super.key,
    required this.vm,
    required this.leftCards,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(
        left: AppTheme.spacingM,
        bottom: AppTheme.spacingM,
        top: AppTheme.spacingM,
      ),
      child: GlassContainer(
        containerOpacity: 0.15,
        borderOpacity: 0.1,
        radius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navigation Items

              // Navigation Items
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: vm.selectedIndex,
                  builder: (_, selectedIndex, __) {
                    return ListView.separated(
                      itemCount: leftCards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = leftCards[index];
                        return _DrawerItem(
                          title: item.$1,
                          iconPath: item.$2,
                          isSelected: selectedIndex == index,
                          onTap: () => vm.selectedIndex.value = index,
                        );
                      },
                    );
                  },
                ),
              ),

              // Optional: Bottom section (Profile, Logout, etc. if needed)
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatefulWidget {
  final String title;
  final String iconPath;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.title,
    required this.iconPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isHovered = _isHovered;

    // Determine styles based on state
    final Color backgroundColor = isSelected
        ? AppTheme.accentColor
        : isHovered
        ? Colors.white.withOpacity(0.08)
        : Colors.transparent;

    final Color contentColor = isSelected
        ? Colors.black
        : isHovered
        ? Colors.white
        : Colors.white60;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 50),
                curve: Curves.easeInOut,
                tween: ColorTween(begin: contentColor, end: contentColor),
                builder: (_, color, __) {
                  return SvgPicture.asset(
                    widget.iconPath,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      color ?? contentColor,
                      BlendMode.srcIn,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 50),
                curve: Curves.easeInOut,
                style: GoogleFonts.inter(
                  color: contentColor,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(widget.title),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
