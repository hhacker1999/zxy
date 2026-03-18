import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/discover_view/discover_filter_form.dart';
import 'package:zxy_app/views/discover_view/discover_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/media_grid.dart';

class DiscoverView extends StatefulWidget {
  final LibraryFilter? filter;
  const DiscoverView({super.key, this.filter});

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
    vm.init(widget.filter);
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
          // ── Title row + filter button ─────────────────────────────────
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
              _FilterIconButton(
                onTap: () => _openFilterForm(context),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),

          // ── Active filter chips ───────────────────────────────────────
          ValueListenableBuilder<LibraryFilter>(
            valueListenable: vm.filterNotifier,
            builder: (_, filter, _) {
              final chips = _buildFilterChips(filter);
              if (chips.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding:
                    const EdgeInsets.only(bottom: AppTheme.spacingS),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: chips
                        .map(
                          (chip) => Padding(
                            padding: const EdgeInsets.only(
                                right: AppTheme.spacingXS),
                            child: chip,
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),

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

  void _openFilterForm(BuildContext context) {
    showDiscoverFilterForm(
      context: context,
      currentFilter: vm.filterNotifier.value,
      onApply: vm.onFilterUpdate,
    );
  }

  // ── Build summary chips from the current filter ────────────────────────

  List<Widget> _buildFilterChips(LibraryFilter filter) {
    final List<Widget> chips = [];

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
    final genreMap =
        filter.isMovie ? AppConstants.movieGenre : AppConstants.showGenre;
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

// ── Filter icon button ──────────────────────────────────────────────────────

class _FilterIconButton extends StatefulWidget {
  final VoidCallback onTap;
  const _FilterIconButton({required this.onTap});

  @override
  State<_FilterIconButton> createState() => _FilterIconButtonState();
}

class _FilterIconButtonState extends State<_FilterIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Filters',
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
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 20,
              color: AppTheme.textPrimary,
            ),
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
