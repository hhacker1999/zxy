import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/screen.dart';

// ── Helper: show whichever surface fits the platform ──────────────────────────

void showDiscoverFilterForm({
  required BuildContext context,
  required LibraryFilter currentFilter,
  required void Function(LibraryFilter) onApply,
}) {
  final isMobile = Screen.of(context).shouldRenderMobile;

  if (isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DiscoverFilterSheet(
        initialFilter: currentFilter,
        onApply: onApply,
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (_) => _DiscoverFilterDialog(
        initialFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESKTOP DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class _DiscoverFilterDialog extends StatefulWidget {
  final LibraryFilter initialFilter;
  final void Function(LibraryFilter) onApply;

  const _DiscoverFilterDialog({
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<_DiscoverFilterDialog> createState() => _DiscoverFilterDialogState();
}

class _DiscoverFilterDialogState extends State<_DiscoverFilterDialog> {
  late LibraryFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Screen.of(context).shouldRenderMobile;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.spacingM : AppTheme.spacingXL,
        vertical: AppTheme.spacingL,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingXL,
                      AppTheme.spacingXL,
                      AppTheme.spacingM,
                      AppTheme.spacingM,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filters',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),

                  // ── Form content ────────────────────────────────────────
                  Flexible(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spacingXL),
                        child: _buildFormContent(),
                      ),
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),

                  // ── Actions ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _filter = LibraryFilter.defaultFilter();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingL,
                              vertical: AppTheme.spacingM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.roundedMedium,
                            ),
                          ),
                          child: Text(
                            'Reset',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        ElevatedButton(
                          onPressed: _onApply,
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
                            'Apply',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
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

  // ── Desktop form content ──────────────────────────────────────────────────

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSwitchField(
          label: 'Media Type',
          value: _filter.isMovie,
          trueLabel: 'Movies',
          falseLabel: 'TV Shows',
          onChanged: (val) =>
              setState(() => _filter = _filter.copyWith(isMovie: val)),
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildTimePeriodSelector(),
        const SizedBox(height: AppTheme.spacingM),
        if (!_filter.isMovie)
          _buildDropdownField(
            label: 'Date Type',
            value: _filter.isFirstAir ? 'first' : 'last',
            items: const [
              DropdownMenuItem(value: 'first', child: Text('First Air Date')),
              DropdownMenuItem(value: 'last', child: Text('Last Air Date')),
            ],
            onChanged: (val) => setState(
              () => _filter = _filter.copyWith(isFirstAir: val == 'first'),
            ),
          ),
        if (!_filter.isMovie) const SizedBox(height: AppTheme.spacingM),
        _buildDropdownField(
          label: 'Min IMDB Rating',
          value: _filter.imdbRating,
          items: List.generate(
            10,
            (i) =>
                DropdownMenuItem(value: i, child: Text(i == 0 ? 'Any' : '$i+')),
          ),
          onChanged: (val) => setState(
            () => _filter = _filter.copyWith(
              imdbRating: val ?? 0,
              minVotes: (val ?? 0) == 0 ? 0 : null,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        if (_filter.imdbRating > 0)
          _buildDropdownField(
            label: 'Min Votes',
            value: _filter.minVotes,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Any')),
              DropdownMenuItem(
                value: 1000,
                child: Text('1,000+  ·  Indie / Niche'),
              ),
              DropdownMenuItem(
                value: 10000,
                child: Text('10,000+  ·  Regional Hits'),
              ),
              DropdownMenuItem(
                value: 50000,
                child: Text('50,000+  ·  Blockbusters'),
              ),
            ],
            onChanged: (val) =>
                setState(() => _filter = _filter.copyWith(minVotes: val ?? 0)),
          ),
        if (_filter.imdbRating > 0) const SizedBox(height: AppTheme.spacingM),
        _buildDropdownField(
          label: 'Language',
          value: _filter.language.isEmpty ? null : _filter.language,
          items: [
            const DropdownMenuItem(value: null, child: Text('Any Language')),
            ...AppConstants.isoLanguages.entries.map(
              (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
            ),
          ],
          onChanged: (val) =>
              setState(() => _filter = _filter.copyWith(language: val ?? '')),
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildGenreSelector(
          label: 'Include Genres',
          selectedGenres: _filter.includedGenres,
          onChanged: (genres) => setState(
            () => _filter = _filter.copyWith(includedGenres: genres),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildGenreSelector(
          label: 'Exclude Genres',
          selectedGenres: _filter.excludedGenres,
          onChanged: (genres) => setState(
            () => _filter = _filter.copyWith(excludedGenres: genres),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildDropdownField(
          label: 'Sort By',
          value: _filter.sort,
          items: const [
            DropdownMenuItem(value: 'popularity', child: Text('Popularity')),
            DropdownMenuItem(value: 'imdb_rating', child: Text('IMDB Rating')),
            DropdownMenuItem(value: 'date', child: Text('Release Date')),
          ],
          onChanged: (val) => setState(
            () => _filter = _filter.copyWith(sort: val ?? 'popularity'),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildSwitchField(
          label: 'Sort Order',
          value: _filter.isAsc,
          trueLabel: 'Ascending',
          falseLabel: 'Descending',
          onChanged: (val) =>
              setState(() => _filter = _filter.copyWith(isAsc: val)),
        ),
      ],
    );
  }

  // ── Shared form-building helpers ──────────────────────────────────────────

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required String trueLabel,
    required String falseLabel,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(trueLabel)),
            ButtonSegment(value: false, label: Text(falseLabel)),
          ],
          selected: {value},
          onSelectionChanged: (set) => onChanged(set.first),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePeriodSelector() {
    String currentPeriod = 'all';
    if (_filter.thisWeek) {
      currentPeriod = 'week';
    } else if (_filter.thisMonth) {
      currentPeriod = 'month';
    } else if (_filter.years.isNotEmpty) {
      if (_filter.years.length == 1) {
        currentPeriod = _filter.years.first.toString();
      } else {
        final decade = (_filter.years.first ~/ 10) * 10;
        currentPeriod = '${decade}s';
      }
    }

    final currentYear = DateTime.now().year;
    final currentDecade = (currentYear ~/ 10) * 10;

    final List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem(value: 'all', child: Text('All Time')),
      const DropdownMenuItem(value: 'week', child: Text('This Week')),
      const DropdownMenuItem(value: 'month', child: Text('This Month')),
      ...List.generate(currentYear - currentDecade + 1, (i) {
        final year = currentYear - i;
        return DropdownMenuItem(
          value: year.toString(),
          child: Text(year.toString()),
        );
      }),
      ...List.generate(4, (i) {
        final decade = currentDecade - ((i + 1) * 10);
        return DropdownMenuItem(value: '${decade}s', child: Text('${decade}s'));
      }),
    ];

    return _buildDropdownField(
      label: 'Time Period',
      value: currentPeriod,
      items: items,
      onChanged: (val) {
        setState(() {
          if (val == 'week') {
            _filter = _filter.copyWith(
              thisWeek: true,
              thisMonth: false,
              years: [],
            );
          } else if (val == 'month') {
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: true,
              years: [],
            );
          } else if (val == 'all') {
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: false,
              years: [],
            );
          } else if (val != null && val.endsWith('s')) {
            final decade = int.parse(val.replaceAll('s', ''));
            final years = List.generate(10, (i) => decade + i);
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: false,
              years: years,
            );
          } else if (val != null) {
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: false,
              years: [int.parse(val)],
            );
          }
        });
      },
    );
  }

  Widget _buildGenreSelector({
    required String label,
    required List<int> selectedGenres,
    required ValueChanged<List<int>> onChanged,
  }) {
    final genres =
        _filter.isMovie ? AppConstants.movieGenre : AppConstants.showGenre;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: genres.entries.map((entry) {
            final isSelected = selectedGenres.contains(entry.key);
            return FilterChip(
              label: Text(entry.value.name),
              selected: isSelected,
              onSelected: (selected) {
                final newList = List<int>.from(selectedGenres);
                if (selected) {
                  newList.add(entry.key);
                } else {
                  newList.remove(entry.key);
                }
                onChanged(newList);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _onApply() {
    widget.onApply(_filter);
    Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _DiscoverFilterSheet extends StatefulWidget {
  final LibraryFilter initialFilter;
  final void Function(LibraryFilter) onApply;

  const _DiscoverFilterSheet({
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<_DiscoverFilterSheet> createState() => _DiscoverFilterSheetState();
}

class _DiscoverFilterSheetState extends State<_DiscoverFilterSheet> {
  late LibraryFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return ClipRRect(
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
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppTheme.spacingM,
                  right: AppTheme.spacingM,
                  top: AppTheme.spacingM,
                  bottom: MediaQuery.of(context).viewInsets.bottom +
                      AppTheme.spacingM,
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _filter = LibraryFilter.defaultFilter();
                                });
                              },
                              child: Text(
                                'Reset',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // Form content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [_buildMobileFormContent()],
                      ),
                    ),

                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _onApply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.roundedMedium,
                          ),
                        ),
                        child: Text(
                          'Apply',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Mobile form content ───────────────────────────────────────────────────

  Widget _buildMobileFormContent() {
    final genres =
        _filter.isMovie ? AppConstants.movieGenre : AppConstants.showGenre;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media Type',
          style:
              GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingS),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Movies')),
            ButtonSegment(value: false, label: Text('TV Shows')),
          ],
          selected: {_filter.isMovie},
          onSelectionChanged: (set) =>
              setState(() => _filter = _filter.copyWith(isMovie: set.first)),
        ),
        const SizedBox(height: AppTheme.spacingL),
        _buildMobileDropdown(
          label: 'Time Period',
          child: _buildTimePeriodDropdown(),
        ),
        const SizedBox(height: AppTheme.spacingM),
        if (!_filter.isMovie) ...[
          _buildMobileDropdown(
            label: 'Date Type',
            child: DropdownButtonFormField<String>(
              initialValue: _filter.isFirstAir ? 'first' : 'last',
              items: const [
                DropdownMenuItem(
                    value: 'first', child: Text('First Air Date')),
                DropdownMenuItem(
                    value: 'last', child: Text('Last Air Date')),
              ],
              onChanged: (val) => setState(
                () => _filter = _filter.copyWith(isFirstAir: val == 'first'),
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
        ],
        _buildMobileDropdown(
          label: 'Min IMDB Rating',
          child: DropdownButtonFormField<int>(
            initialValue: _filter.imdbRating,
            items: List.generate(
              10,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(i == 0 ? 'Any' : '$i+'),
              ),
            ),
            onChanged: (val) => setState(
              () => _filter = _filter.copyWith(imdbRating: val ?? 0),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        if (_filter.imdbRating > 0) ...[
          _buildMobileDropdown(
            label: 'Min Votes',
            child: DropdownButtonFormField<int>(
              initialValue: _filter.minVotes,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Any')),
                DropdownMenuItem(
                  value: 1000,
                  child: Text('1,000+  ·  Indie / Niche'),
                ),
                DropdownMenuItem(
                  value: 10000,
                  child: Text('10,000+  ·  Regional Hits'),
                ),
                DropdownMenuItem(
                  value: 50000,
                  child: Text('50,000+  ·  Blockbusters'),
                ),
              ],
              onChanged: (val) => setState(
                () => _filter = _filter.copyWith(minVotes: val ?? 0),
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
        ],
        _buildMobileDropdown(
          label: 'Language',
          child: DropdownButtonFormField<String?>(
            initialValue: _filter.language.isEmpty ? null : _filter.language,
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('Any Language')),
              ...AppConstants.isoLanguages.entries.map(
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
              ),
            ],
            onChanged: (val) => setState(
                () => _filter = _filter.copyWith(language: val ?? '')),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Include Genres',
          style:
              GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: genres.entries.map((entry) {
            final isSelected = _filter.includedGenres.contains(entry.key);
            return FilterChip(
              label: Text(entry.value.name),
              selected: isSelected,
              onSelected: (selected) {
                final newList = List<int>.from(_filter.includedGenres);
                if (selected) {
                  newList.add(entry.key);
                } else {
                  newList.remove(entry.key);
                }
                setState(
                  () => _filter = _filter.copyWith(includedGenres: newList),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Exclude Genres',
          style:
              GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: genres.entries.map((entry) {
            final isSelected = _filter.excludedGenres.contains(entry.key);
            return FilterChip(
              label: Text(entry.value.name),
              selected: isSelected,
              onSelected: (selected) {
                final newList = List<int>.from(_filter.excludedGenres);
                if (selected) {
                  newList.add(entry.key);
                } else {
                  newList.remove(entry.key);
                }
                setState(
                  () => _filter = _filter.copyWith(excludedGenres: newList),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spacingL),
        _buildMobileDropdown(
          label: 'Sort By',
          child: DropdownButtonFormField<String>(
            initialValue: _filter.sort,
            items: const [
              DropdownMenuItem(
                  value: 'popularity', child: Text('Popularity')),
              DropdownMenuItem(
                value: 'imdb_rating',
                child: Text('IMDB Rating'),
              ),
              DropdownMenuItem(value: 'date', child: Text('Release Date')),
            ],
            onChanged: (val) => setState(
              () => _filter = _filter.copyWith(sort: val ?? 'popularity'),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Sort Order',
          style:
              GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingS),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Descending')),
            ButtonSegment(value: true, label: Text('Ascending')),
          ],
          selected: {_filter.isAsc},
          onSelectionChanged: (set) =>
              setState(() => _filter = _filter.copyWith(isAsc: set.first)),
        ),
        const SizedBox(height: AppTheme.spacingXL),
      ],
    );
  }

  Widget _buildMobileDropdown({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.spacingS),
        child,
      ],
    );
  }

  Widget _buildTimePeriodDropdown() {
    String currentPeriod = 'all';
    if (_filter.thisWeek) {
      currentPeriod = 'week';
    } else if (_filter.thisMonth) {
      currentPeriod = 'month';
    } else if (_filter.years.isNotEmpty) {
      if (_filter.years.length == 1) {
        currentPeriod = _filter.years.first.toString();
      } else {
        final decade = (_filter.years.first ~/ 10) * 10;
        currentPeriod = '${decade}s';
      }
    }

    final currentYear = DateTime.now().year;
    final currentDecade = (currentYear ~/ 10) * 10;

    final List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem(value: 'all', child: Text('All Time')),
      const DropdownMenuItem(value: 'week', child: Text('This Week')),
      const DropdownMenuItem(value: 'month', child: Text('This Month')),
      ...List.generate(currentYear - currentDecade + 1, (i) {
        final year = currentYear - i;
        return DropdownMenuItem(
          value: year.toString(),
          child: Text(year.toString()),
        );
      }),
      ...List.generate(4, (i) {
        final decade = currentDecade - ((i + 1) * 10);
        return DropdownMenuItem(value: '${decade}s', child: Text('${decade}s'));
      }),
    ];

    return DropdownButtonFormField<String>(
      initialValue: currentPeriod,
      items: items,
      onChanged: (val) {
        setState(() {
          if (val == 'week') {
            _filter = _filter.copyWith(
              thisWeek: true,
              thisMonth: false,
              years: [],
            );
          } else if (val == 'month') {
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: true,
              years: [],
            );
          } else if (val == 'all') {
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: false,
              years: [],
            );
          } else if (val != null && val.endsWith('s')) {
            final decade = int.parse(val.replaceAll('s', ''));
            final years = List.generate(10, (i) => decade + i);
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: false,
              years: years,
            );
          } else if (val != null) {
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: false,
              years: [int.parse(val)],
            );
          }
        });
      },
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  void _onApply() {
    widget.onApply(_filter);
    Navigator.pop(context);
  }
}
