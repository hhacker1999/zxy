import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/events_bloc.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/base_home_view/base_home_view_model.dart';
import 'package:zxy_app/views/discover_view/discover_filter_form.dart';
import 'package:zxy_app/views/discover_view/discover_view_model.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/media_grid.dart';
import 'package:zxy_app/views/shared/toast.dart';

class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  late final DiscoverViewModel vm;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    vm = context.read<DiscoverViewModel>();
    vm.setContext(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenData = Screen.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingM,
        right: AppTheme.spacingM,
        top: screenData.shouldRenderMobile
            ? MediaQuery.of(context).padding.top + AppTheme.spacingS
            : AppTheme.spacingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row + action buttons ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Discover',
                  style: GoogleFonts.poppins(
                    fontSize: screenData.shouldRenderMobile ? 24 : 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              // Reset button (visible when a filter is active)
              ValueListenableBuilder<LibraryFilter>(
                valueListenable: vm.filterNotifier,
                builder: (_, filter, __) {
                  final isDefault = _isDefaultFilter(filter);
                  if (isDefault) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingXS),
                    child: _ActionIconButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Reset',
                      onTap: () => vm.resetFilter(),
                    ),
                  );
                },
              ),
              // Save button (visible when a filter is active)
              ValueListenableBuilder<LibraryFilter>(
                valueListenable: vm.filterNotifier,
                builder: (_, filter, __) {
                  final isDefault = _isDefaultFilter(filter);
                  if (isDefault) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingXS),
                    child: _ActionIconButton(
                      icon: Icons.bookmark_add_outlined,
                      tooltip: 'Save to Home',
                      onTap: () => _showSaveDialog(context),
                    ),
                  );
                },
              ),
              _ActionIconButton(
                icon: Icons.tune_rounded,
                tooltip: 'Filters',
                onTap: () => _openFilterForm(context),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),

          // ── Active filter chips ───────────────────────────────────────
          _buildChipRow(),

          // ── Media grid ───────────────────────────────────────────────
          Expanded(
            child: MediaGrid(
              onScrollNearEnd: vm.loadMore,
              showType: true,
              scrollController: _scrollController,
              notifier: vm.viewState,
              initialText: 'Apply a filter to discover media',
            ),
          ),
        ],
      ),
    );
  }

  bool _isDefaultFilter(LibraryFilter filter) {
    final def = LibraryFilter.defaultFilter();
    return filter.type == def.type &&
        filter.traktId == def.traktId &&
        filter.isMovie == def.isMovie &&
        filter.thisWeek == def.thisWeek &&
        filter.thisMonth == def.thisMonth &&
        filter.years.isEmpty &&
        filter.imdbRating == def.imdbRating &&
        filter.language == def.language &&
        filter.includedGenres.isEmpty &&
        filter.excludedGenres.isEmpty &&
        filter.sort == def.sort &&
        filter.isAsc == def.isAsc;
  }

  Widget _buildChipRow() {
    return ValueListenableBuilder<LibraryFilter>(
      valueListenable: vm.filterNotifier,
      builder: (_, filter, __) {
        return ValueListenableBuilder<String?>(
          valueListenable: vm.activeListName,
          builder: (_, listName, __) {
            final chips = _buildFilterChips(filter, listName);
            if (chips.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: chips
                      .map(
                        (chip) => Padding(
                          padding: const EdgeInsets.only(
                            right: AppTheme.spacingXS,
                          ),
                          child: chip,
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openFilterForm(BuildContext context) {
    final profile = context.read<UserBloc>().profileNotifier.value;
    showDiscoverFilterForm(
      context: context,
      currentFilter: vm.filterNotifier.value,
      profile: profile,
      onApply: (filter, {String? listName}) {
        vm.onFilterUpdate(filter, listName: listName);
      },
    );
  }

  // ── Save dialog ──────────────────────────────────────────────────────────

  void _showSaveDialog(BuildContext context) {
    final isMobile = Screen.of(context).shouldRenderMobile;
    final controller = TextEditingController(
      text: vm.activeListName.value ?? '',
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SaveNameSheet(
          controller: controller,
          onSave: (name) {
            Navigator.pop(context);
            _performSave(name);
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => _SaveNameDialog(
          controller: controller,
          onSave: (name) {
            Navigator.pop(context);
            _performSave(name);
          },
        ),
      );
    }
  }

  Future<void> _performSave(String name) async {
    if (name.trim().isEmpty) {
      showToast(context, true, "Name cannot be empty", "");
      return;
    }

    final bvm = context.read<BaseHomeViewModel>();
    bvm.scaffoldLoading.value = true;

    final profile = context.read<UserBloc>().profileNotifier.value;
    final currentItems = profile?.libraryItems ?? [];

    final success = await vm.saveFilterToHomeList(name.trim(), currentItems);

    if (success && mounted) {
      // Refresh profile to pick up the new list item
      final newProfile = await vm.authUc.getUserProfile();
      if (mounted) {
        context.read<UserBloc>().profile = newProfile;
        context.read<EventsBloc>().addEvent(UpdatedHomeList());
        showToast(context, false, "List '$name' added to home", "");
      }
    } else if (mounted) {
      showToast(context, true, "Failed to save list", "");
    }

    if (mounted) {
      bvm.scaffoldLoading.value = false;
    }
  }

  // ── Build summary chips from the current filter ────────────────────────

  List<Widget> _buildFilterChips(LibraryFilter filter, String? listName) {
    final List<Widget> chips = [];

    // Trakt list mode: show a single chip with the list name
    if (filter.type == 'trakt' && listName != null) {
      chips.add(_InfoChip(label: '🔗 $listName'));
      return chips;
    }

    // Internal filter mode
    // Media type
    chips.add(_InfoChip(label: filter.isMovie ? 'Movies' : 'TV Shows'));

    // Time period
    if (filter.thisWeek) {
      chips.add(const _InfoChip(label: 'This Week'));
    } else if (filter.thisMonth) {
      chips.add(const _InfoChip(label: 'This Month'));
    } else if (filter.years.isNotEmpty) {
      if (filter.years.length == 1) {
        chips.add(_InfoChip(label: filter.years.first.toString()));
      } else {
        final decade = (filter.years.first ~/ 10) * 10;
        chips.add(_InfoChip(label: '${decade}s'));
      }
    }

    // IMDB rating
    if (filter.imdbRating > 0) {
      chips.add(_InfoChip(label: 'IMDb ${filter.imdbRating}+'));
    }

    // Language
    if (filter.language.isNotEmpty) {
      final langName =
          AppConstants.isoLanguages[filter.language] ?? filter.language;
      chips.add(_InfoChip(label: langName));
    }

    // Included genres
    final genreMap = filter.isMovie
        ? AppConstants.movieGenre
        : AppConstants.showGenre;
    for (final gId in filter.includedGenres) {
      final genre = genreMap[gId];
      if (genre != null) {
        chips.add(_InfoChip(label: genre.name));
      }
    }

    // Sort
    if (filter.sort != 'popularity') {
      final sortLabel = switch (filter.sort) {
        'imdb_rating' => 'IMDb Rating',
        'date' => 'Release Date',
        _ => filter.sort,
      };
      chips.add(_InfoChip(label: sortLabel));
    }

    return chips;
  }
}

// ── Action icon button (reusable for filter/save/reset) ─────────────────────

class _ActionIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(widget.icon, size: 20, color: AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }
}

// ── Info chip (read-only, small summary chip) ───────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SAVE NAME DIALOG (desktop)
// ═══════════════════════════════════════════════════════════════════════════════

class _SaveNameDialog extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSave;

  const _SaveNameDialog({required this.controller, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXL,
        vertical: AppTheme.spacingL,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Save to Home',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Enter a name for this list on your home page.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Sunday Thrillers',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (val) => onSave(val),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      ElevatedButton(
                        onPressed: () => onSave(controller.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingL,
                            vertical: AppTheme.spacingM,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.roundedMedium,
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
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

// ═══════════════════════════════════════════════════════════════════════════════
// SAVE NAME SHEET (mobile)
// ═══════════════════════════════════════════════════════════════════════════════

class _SaveNameSheet extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSave;

  const _SaveNameSheet({required this.controller, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: const Border(
                top: BorderSide(color: Color(0x1AFFFFFF), width: 1),
              ),
            ),
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Save to Home',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Enter a name for this list on your home page.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Sunday Thrillers',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (val) => onSave(val),
                ),
                const SizedBox(height: AppTheme.spacingL),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => onSave(controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.roundedMedium,
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
