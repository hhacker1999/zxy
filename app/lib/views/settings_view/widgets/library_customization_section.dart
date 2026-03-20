import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/base_home_view/base_home_view_model.dart';
import 'package:zxy_app/views/discover_view/discover_view_model.dart';
import 'package:zxy_app/views/screen.dart';

import 'package:zxy_app/views/settings_view/settings_view_model.dart';

class LibraryCustomizationSection extends StatelessWidget {
  final SettingsViewModel viewModel;

  const LibraryCustomizationSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isMobile = Screen.of(context).shouldRenderMobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Home Page Customization',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
            GlassIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Add List',
              onTap: () => _showLibraryItemForm(context, viewModel, null, -1),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),

        // ── Empty state ───────────────────────────────────────────────────
        if (viewModel.libraryItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: AppTheme.roundedLarge,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.playlist_add_rounded,
                    size: 40,
                    color: AppTheme.textDisabled,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'No custom lists yet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to create your first custom list',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // ── List container ────────────────────────────────────────────
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: AppTheme.roundedLarge,
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: viewModel.libraryItems.length,
              onReorder: (a, b) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  viewModel.reorderLibraryItems(a, b);
                });
              },
              proxyDecorator:
                  (Widget child, int index, Animation<double> animation) {
                    return Material(
                      color: Colors.transparent,
                      elevation: 0, // Prevents shadow layout shifts
                      child: child,
                    );
                  },
              itemBuilder: (context, index) {
                final item = viewModel.libraryItems[index];
                return LibraryItemTile(
                  key: ValueKey(index),
                  item: item,
                  index: index,
                  onEdit: () {
                    context.read<DiscoverViewModel>().onProfileLibraryItem(
                      item,
                      index,
                    );
                    context.read<BaseHomeViewModel>().selectedIndex.value = 1;
                  },
                  onDelete: () =>
                      _showDeleteConfirmation(context, viewModel, index),
                  isMobile: isMobile,
                );
              },
            ),
          ),

        // ── Save button ───────────────────────────────────────────────────
        if (viewModel.hasLibraryChanges) ...[
          const SizedBox(height: AppTheme.spacingM),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: viewModel.saveLibraryItems,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.roundedMedium,
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showLibraryItemForm(
    BuildContext context,
    SettingsViewModel viewModel,
    ProfileLibraryItem? existingItem,
    int index,
  ) {
    final isMobile = Screen.of(context).shouldRenderMobile;

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => LibraryFilterFormSheet(
          existingItem: existingItem,
          onSave: (item) {
            if (index >= 0) {
              viewModel.updateLibraryItem(index, item);
            } else {
              viewModel.addLibraryItem(item);
            }
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => LibraryFilterFormDialog(
          existingItem: existingItem,
          onSave: (item) {
            if (index >= 0) {
              viewModel.updateLibraryItem(index, item);
            } else {
              viewModel.addLibraryItem(item);
            }
          },
        ),
      );
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    SettingsViewModel viewModel,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (_) => GlassConfirmDialog(
        title: 'Delete List',
        message:
            "Are you sure you want to delete '${viewModel.libraryItems[index].name}'?",
        confirmLabel: 'Delete',
        isDestructive: true,
        onConfirm: () {
          viewModel.deleteLibraryItem(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Glass icon button (shared) ────────────────────────────────────────────────

class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
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
            child: Icon(widget.icon, size: 18, color: AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }
}

// ── Library item tile ─────────────────────────────────────────────────────────

class LibraryItemTile extends StatelessWidget {
  final ProfileLibraryItem item;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isMobile;

  const LibraryItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingXS,
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.playlist_play_rounded,
            size: 18,
            color: AppTheme.textSecondary,
          ),
        ),
        title: Text(
          item.name,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          item.filter.isMovie ? 'Movies' : 'TV Shows',
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppTheme.textSecondary,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: AppTheme.errorColor,
              onPressed: onDelete,
            ),
            if (!isMobile) AppTheme.boxWidthM,
          ],
        ),
      ),
    );
  }
}

// ── Glass confirm dialog ──────────────────────────────────────────────────────

class GlassConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;

  const GlassConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Screen.of(context).shouldRenderMobile;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.spacingM : AppTheme.spacingXL,
        vertical: AppTheme.spacingXL,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXL),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.roundedMedium,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDestructive
                                  ? AppTheme.errorColor
                                  : Colors.white,
                              foregroundColor: isDestructive
                                  ? Colors.white
                                  : Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.roundedMedium,
                              ),
                            ),
                            child: Text(
                              confirmLabel,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

// ── Desktop Dialog for Library Filter Form ────────────────────────────────────

class LibraryFilterFormDialog extends StatefulWidget {
  final ProfileLibraryItem? existingItem;
  final void Function(ProfileLibraryItem) onSave;

  const LibraryFilterFormDialog({
    super.key,
    this.existingItem,
    required this.onSave,
  });

  @override
  State<LibraryFilterFormDialog> createState() =>
      _LibraryFilterFormDialogState();
}

class _LibraryFilterFormDialogState extends State<LibraryFilterFormDialog> {
  late TextEditingController _nameController;
  late LibraryFilter _filter;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingItem?.name ?? '',
    );
    _filter = widget.existingItem?.filter ?? LibraryFilter.defaultFilter();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
                            widget.existingItem != null
                                ? 'Edit List'
                                : 'Create List',
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
                          onPressed: () => Navigator.pop(context),
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
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        ElevatedButton(
                          onPressed: _onSave,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'List Name',
            hintText: 'e.g. Top Rated Action Movies',
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingM,
            ),
            border: OutlineInputBorder(
              borderRadius: AppTheme.roundedMedium,
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppTheme.roundedMedium,
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.roundedMedium,
              borderSide: const BorderSide(
                color: AppTheme.accentColor,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
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
          label: 'Items in List',
          value: _filter.items,
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 20, child: Text('20')),
            DropdownMenuItem(value: 30, child: Text('30')),
            DropdownMenuItem(value: 50, child: Text('50')),
          ],
          onChanged: (val) =>
              setState(() => _filter = _filter.copyWith(items: val ?? 20)),
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    final genres = _filter.isMovie
        ? AppConstants.movieGenre
        : AppConstants.showGenre;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
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

  void _onSave() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a list name')));
      return;
    }
    final item = ProfileLibraryItem(
      name: _nameController.text,
      filter: _filter,
    );
    widget.onSave(item);
    Navigator.pop(context);
  }
}

// ── Mobile Bottom Sheet for Library Filter Form ───────────────────────────────

class LibraryFilterFormSheet extends StatefulWidget {
  final ProfileLibraryItem? existingItem;
  final void Function(ProfileLibraryItem) onSave;

  const LibraryFilterFormSheet({
    super.key,
    this.existingItem,
    required this.onSave,
  });

  @override
  State<LibraryFilterFormSheet> createState() => _LibraryFilterFormSheetState();
}

class _LibraryFilterFormSheetState extends State<LibraryFilterFormSheet> {
  late TextEditingController _nameController;
  late LibraryFilter _filter;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingItem?.name ?? '',
    );
    _filter = widget.existingItem?.filter ?? LibraryFilter.defaultFilter();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
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
                          widget.existingItem != null
                              ? 'Edit List'
                              : 'Create List',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
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
                    const SizedBox(height: AppTheme.spacingM),

                    // Form content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [_buildMobileFormContent()],
                      ),
                    ),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _onSave,
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileFormContent() {
    final genres = _filter.isMovie
        ? AppConstants.movieGenre
        : AppConstants.showGenre;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'List Name',
            hintText: 'e.g. Top Rated Action Movies',
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingM,
            ),
            border: OutlineInputBorder(
              borderRadius: AppTheme.roundedMedium,
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppTheme.roundedMedium,
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.roundedMedium,
              borderSide: const BorderSide(
                color: AppTheme.accentColor,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Media Type',
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
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
                DropdownMenuItem(value: 'first', child: Text('First Air Date')),
                DropdownMenuItem(value: 'last', child: Text('Last Air Date')),
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              const DropdownMenuItem(value: null, child: Text('Any Language')),
              ...AppConstants.isoLanguages.entries.map(
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
              ),
            ],
            onChanged: (val) =>
                setState(() => _filter = _filter.copyWith(language: val ?? '')),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Include Genres',
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
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
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
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
          label: 'Items in List',
          child: DropdownButtonFormField<int>(
            initialValue: _filter.items,
            items: const [
              DropdownMenuItem(value: 10, child: Text('10')),
              DropdownMenuItem(value: 20, child: Text('20')),
              DropdownMenuItem(value: 30, child: Text('30')),
              DropdownMenuItem(value: 50, child: Text('50')),
            ],
            onChanged: (val) =>
                setState(() => _filter = _filter.copyWith(items: val ?? 20)),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildMobileDropdown(
          label: 'Sort By',
          child: DropdownButtonFormField<String>(
            initialValue: _filter.sort,
            items: const [
              DropdownMenuItem(value: 'popularity', child: Text('Popularity')),
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Sort Order',
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
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
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
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

  void _onSave() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a list name')));
      return;
    }
    final item = ProfileLibraryItem(
      name: _nameController.text,
      filter: _filter,
    );
    widget.onSave(item);
    Navigator.pop(context);
  }
}
