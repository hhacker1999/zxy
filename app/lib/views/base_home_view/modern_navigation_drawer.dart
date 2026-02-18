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
const double _kCollapsedWidth = 72.0;
const double _kExpandedWidth = 230.0;
const Duration _kExpandDuration = Duration(milliseconds: 300);
const Curve _kExpandCurve = Curves.easeInOutCubic;

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
          begin: _expanded ? _kCollapsedWidth : _kExpandedWidth,
          end: _expanded ? _kExpandedWidth : _kCollapsedWidth,
        ),
        duration: _kExpandDuration,
        curve: _kExpandCurve,
        builder: (context, width, _) {
          // Show labels once the drawer is meaningfully open
          final showLabels = width > (_kCollapsedWidth + 40);
          return SizedBox(
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

                          const SizedBox(height: 24),

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
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.08),
                              thickness: 1,
                              height: 1,
                            ),
                          ),

                          const SizedBox(height: 4),

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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            border: Border(
              right: BorderSide(
                color: Colors.white.withOpacity(0.07),
                width: 1,
              ),
            ),
          ),
          child: child,
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
      height: 72,
      // Overflow.clip so the wordmark never bleeds out during animation
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        maxWidth: _kExpandedWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  duration: _kExpandDuration,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
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
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        'Z',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 1,
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
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.4);

    final Color bgColor = isSelected
        ? widget.accent.withValues(alpha: 0.15)
        : isHovered
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            // Clip so nothing bleeds outside the pill during animation
            clipBehavior: Clip.hardEdge,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                // ── Active indicator bar ────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 3,
                  height: isSelected ? 24 : 0,
                  margin: const EdgeInsets.only(left: 2, right: 11),
                  decoration: BoxDecoration(
                    color: widget.accent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: widget.accent.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                ),

                // ── Icon ───────────────────────────────────────────────
                SvgPicture.asset(
                  widget.iconPath,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
                ),

                // ── Label — Expanded fills remaining width so the
                //    background pill always stretches edge-to-edge.
                //    Only inserted into tree when expanded.
                if (widget.expanded)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: contentColor,
                          letterSpacing: 0.1,
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
    );
  }
}
