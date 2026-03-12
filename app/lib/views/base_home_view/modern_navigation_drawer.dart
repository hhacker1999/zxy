import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/views/base_home_view/base_home_view_model.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const double _kCollapsedWidth = 76.0;
const double _kExpandedWidth = 240.0;
const Duration _kExpandDuration = Duration(milliseconds: 300);
const Curve _kExpandCurve = Curves.easeOutCubic;

// ---------------------------------------------------------------------------
// ModernNavigationDrawer
// ---------------------------------------------------------------------------

class ModernNavigationDrawer extends StatefulWidget {
  final BaseHomeViewModel vm;
  final List<(String, String)> leftCards;

  const ModernNavigationDrawer({
    super.key,
    required this.vm,
    required this.leftCards,
  });

  @override
  State<ModernNavigationDrawer> createState() => _ModernNavigationDrawerState();
}

class _ModernNavigationDrawerState extends State<ModernNavigationDrawer> {
  bool _expanded = false;

  List<(String, String)> get _mainItems =>
      widget.leftCards.sublist(0, widget.leftCards.length - 1);

  (String, String) get _bottomItem =>
      widget.leftCards[widget.leftCards.length - 1];

  int get _bottomItemIndex => widget.leftCards.length - 1;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _expanded = true),
      onExit: (_) => setState(() => _expanded = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: _kCollapsedWidth,
          end: _expanded ? _kExpandedWidth : _kCollapsedWidth,
        ),
        duration: _kExpandDuration,
        curve: _kExpandCurve,
        builder: (context, width, _) {
          // Show labels once the drawer is meaningfully open
          final showLabels = width > (_kCollapsedWidth + 40);
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: width,
              child: ValueListenableBuilder<int>(
                valueListenable: widget.vm.selectedIndex,
                builder: (_, selectedIndex, _) {
                  return ValueListenableBuilder<Color?>(
                    valueListenable: context.read<ImageBloc>().bgGradColor,
                    builder: (_, accentColor, _) {
                      final accent = accentColor ?? Colors.white;
                      return _DrawerShell(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Logo ────────────────────────────────────────
                            _LogoHeader(expanded: showLabels),

                            const SizedBox(height: 16),

                            // ── Main nav items ───────────────────────────
                            ...List.generate(_mainItems.length, (i) {
                              return _NavItem(
                                title: _mainItems[i].$1,
                                iconPath: _mainItems[i].$2,
                                isSelected: selectedIndex == i,
                                expanded: showLabels,
                                accent: accent,
                                onTap: () => widget.vm.selectedIndex.value = i,
                              );
                            }),

                            const Spacer(),

                            // ── Divider ────────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Divider(
                                color: Colors.white.withOpacity(0.08),
                                thickness: 1,
                                height: 1,
                              ),
                            ),

                            // ── Settings (pinned bottom) ───────────────────
                            _NavItem(
                              title: _bottomItem.$1,
                              iconPath: _bottomItem.$2,
                              isSelected: selectedIndex == _bottomItemIndex,
                              expanded: showLabels,
                              accent: accent,
                              onTap: () => widget.vm.selectedIndex.value =
                                  _bottomItemIndex,
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drawer shell — frosted glass background
// ---------------------------------------------------------------------------

class _DrawerShell extends StatelessWidget {
  final Widget child;

  const _DrawerShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 4,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo header
// ---------------------------------------------------------------------------

class _LogoHeader extends StatelessWidget {
  final bool expanded;

  const _LogoHeader({required this.expanded});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        maxWidth: _kExpandedWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon mark — always visible
              _ZxyIconMark(),

              // Wordmark — only inserted into tree when expanded
              if (expanded)
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Text(
                      'ZXY',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZxyIconMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'Z',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 1.1,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual nav item
// ---------------------------------------------------------------------------

class _NavItem extends StatefulWidget {
  final String title;
  final String iconPath;
  final bool isSelected;
  final bool expanded;
  final Color accent;
  final VoidCallback onTap;

  const _NavItem({
    required this.title,
    required this.iconPath,
    required this.isSelected,
    required this.expanded,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isHovered = _hovered;

    final Color contentColor = isSelected
        ? Colors.white
        : isHovered
            ? Colors.white.withOpacity(0.9)
            : Colors.white.withOpacity(0.45);

    final Color bgColor = isSelected
        ? widget.accent.withOpacity(0.15)
        : isHovered
            ? Colors.white.withOpacity(0.08)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.hardEdge,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                // ── Fixed width container for icon & active indicator ──
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Active indicator bar
                      Positioned(
                        left: 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          width: 4,
                          height: isSelected ? 24 : 0,
                          decoration: BoxDecoration(
                            color: widget.accent,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: widget.accent.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                      ),
                      // Icon
                      SvgPicture.asset(
                        widget.iconPath,
                        width: 24,
                        height: 24,
                        colorFilter:
                            ColorFilter.mode(contentColor, BlendMode.srcIn),
                      ),
                    ],
                  ),
                ),

                // ── Label ──
                if (widget.expanded)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6, right: 12),
                      child: Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: contentColor,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
