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
  required void Function(LibraryFilter, {String? listName}) onApply,
  Profile? profile,
}) {
  final isMobile = Screen.of(context).shouldRenderMobile;

  if (isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterTypeChooserSheet(
        currentFilter: currentFilter,
        onApply: onApply,
        profile: profile,
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (_) => _FilterTypeChooserDialog(
        currentFilter: currentFilter,
        onApply: onApply,
        profile: profile,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESKTOP TYPE CHOOSER DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class _FilterTypeChooserDialog extends StatefulWidget {
  final LibraryFilter currentFilter;
  final void Function(LibraryFilter, {String? listName}) onApply;
  final Profile? profile;

  const _FilterTypeChooserDialog({
    required this.currentFilter,
    required this.onApply,
    this.profile,
  });

  @override
  State<_FilterTypeChooserDialog> createState() =>
      _FilterTypeChooserDialogState();
}

class _FilterTypeChooserDialogState extends State<_FilterTypeChooserDialog> {
  // null = chooser, 'internal' = filter form, 'trakt' = list picker
  String? _selectedType;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXL,
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
              child: Visibility(
                visible: _selectedType != null,
                replacement: _buildChooser(),
                child: _selectedType == 'internal'
                    ? _DesktopInternalFilterForm(
                        key: const ValueKey('internal'),
                        initialFilter: widget.currentFilter,
                        onApply: (filter) {
                          widget.onApply(filter);
                          Navigator.pop(context);
                        },
                        onBack: () => setState(() => _selectedType = null),
                      )
                    : _DesktopTraktListPicker(
                        key: const ValueKey('trakt'),
                        profile: widget.profile,
                        onSelect: (filter, name) {
                          widget.onApply(filter, listName: name);
                          Navigator.pop(context);
                        },
                        onBack: () => setState(() => _selectedType = null),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChooser() {
    return Column(
      key: const ValueKey('chooser'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
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
                  'Choose Filter Type',
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
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),

        // Cards
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Row(
            children: [
              Expanded(
                child: _TypeCard(
                  icon: Icons.tune_rounded,
                  title: 'Internal',
                  subtitle: 'TMDB-based genre, year, rating filters',
                  onTap: () => setState(() => _selectedType = 'internal'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _TypeCard(
                  icon: Icons.list_alt_rounded,
                  title: 'Trakt',
                  subtitle: 'Trending lists & your Trakt lists',
                  onTap: () => setState(() => _selectedType = 'trakt'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE TYPE CHOOSER SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _FilterTypeChooserSheet extends StatefulWidget {
  final LibraryFilter currentFilter;
  final void Function(LibraryFilter, {String? listName}) onApply;
  final Profile? profile;

  const _FilterTypeChooserSheet({
    required this.currentFilter,
    required this.onApply,
    this.profile,
  });

  @override
  State<_FilterTypeChooserSheet> createState() =>
      _FilterTypeChooserSheetState();
}

class _FilterTypeChooserSheetState extends State<_FilterTypeChooserSheet> {
  String? _selectedType;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
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
              child: Visibility(
                visible: _selectedType != null,
                replacement: _buildMobileChooser(scrollController),
                child: _selectedType == 'internal'
                    ? _MobileInternalFilterSheet(
                        key: const ValueKey('internal_sheet'),
                        scrollController: scrollController,
                        initialFilter: widget.currentFilter,
                        onApply: (filter) {
                          widget.onApply(filter);
                          Navigator.pop(context);
                        },
                        onBack: () => setState(() => _selectedType = null),
                      )
                    : _MobileTraktListPicker(
                        key: const ValueKey('trakt_sheet'),
                        scrollController: scrollController,
                        profile: widget.profile,
                        onSelect: (filter, name) {
                          widget.onApply(filter, listName: name);
                          Navigator.pop(context);
                        },
                        onBack: () => setState(() => _selectedType = null),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileChooser(ScrollController scrollController) {
    return Padding(
      key: const ValueKey('chooser_mobile'),
      padding: EdgeInsets.only(
        left: AppTheme.spacingM,
        right: AppTheme.spacingM,
        top: AppTheme.spacingM,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingM,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                'Choose Filter Type',
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
          const SizedBox(height: AppTheme.spacingL),

          // Cards — full width
          SizedBox(
            width: double.infinity,
            child: _TypeCard(
              icon: Icons.tune_rounded,
              title: 'Internal',
              subtitle: 'TMDB-based genre, year, rating filters',
              onTap: () => setState(() => _selectedType = 'internal'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          SizedBox(
            width: double.infinity,
            child: _TypeCard(
              icon: Icons.list_alt_rounded,
              title: 'Trakt',
              subtitle: 'Trending lists & your Trakt lists',
              onTap: () => setState(() => _selectedType = 'trakt'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED TYPE CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _TypeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_TypeCard> createState() => _TypeCardState();
}

class _TypeCardState extends State<_TypeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 32, color: AppTheme.textPrimary),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESKTOP TRAKT LIST PICKER
// ═══════════════════════════════════════════════════════════════════════════════

class _DesktopTraktListPicker extends StatelessWidget {
  final Profile? profile;
  final void Function(LibraryFilter filter, String name) onSelect;
  final VoidCallback onBack;

  const _DesktopTraktListPicker({
    super.key,
    required this.profile,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingM,
            AppTheme.spacingXL,
            AppTheme.spacingM,
            AppTheme.spacingM,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textSecondary,
                ),
                onPressed: onBack,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  'Trakt Lists',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),

        // List items
        Flexible(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section label
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppTheme.spacingS,
                      bottom: AppTheme.spacingS,
                    ),
                    child: Text(
                      'TRENDING',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _TraktListTile(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.orangeAccent,
                    name: 'Trending Movies',
                    description: 'Most popular movies right now',
                    onTap: () => onSelect(
                      LibraryFilter.defaultFilter().copyWith(
                        type: 'trakt',
                        traktId: 'trending',
                        isMovie: true,
                      ),
                      'Trending Movies',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  _TraktListTile(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.orangeAccent,
                    name: 'Trending Shows',
                    description: 'Most popular TV shows right now',
                    onTap: () => onSelect(
                      LibraryFilter.defaultFilter().copyWith(
                        type: 'trakt',
                        traktId: 'trending',
                        isMovie: false,
                      ),
                      'Trending Shows',
                    ),
                  ),

                  // User lists
                  if (profile != null &&
                      profile!.isTraktValid &&
                      profile!.profileTraktLists.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingL),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppTheme.spacingS,
                        bottom: AppTheme.spacingS,
                      ),
                      child: Text(
                        'YOUR LISTS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...profile!.profileTraktLists.map(
                      (list) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacingS,
                        ),
                        child: _TraktListTile(
                          icon: Icons.bookmark_rounded,
                          iconColor: Colors.blueAccent,
                          name: list.name,
                          description: list.description.isNotEmpty
                              ? list.description
                              : 'Trakt list',
                          onTap: () => onSelect(
                            LibraryFilter.defaultFilter().copyWith(
                              type: 'trakt',
                              traktId: list.ids.slug,
                            ),
                            list.name,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE TRAKT LIST PICKER
// ═══════════════════════════════════════════════════════════════════════════════

class _MobileTraktListPicker extends StatelessWidget {
  final ScrollController scrollController;
  final Profile? profile;
  final void Function(LibraryFilter filter, String name) onSelect;
  final VoidCallback onBack;

  const _MobileTraktListPicker({
    super.key,
    required this.scrollController,
    required this.profile,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingM,
        right: AppTheme.spacingM,
        top: AppTheme.spacingM,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingM,
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

          // Header with back
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  'Trakt Lists',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
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
          const SizedBox(height: AppTheme.spacingM),

          // List
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                // Trending section
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppTheme.spacingS,
                    bottom: AppTheme.spacingS,
                  ),
                  child: Text(
                    'TRENDING',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _TraktListTile(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.orangeAccent,
                  name: 'Trending Movies',
                  description: 'Most popular movies right now',
                  onTap: () => onSelect(
                    LibraryFilter.defaultFilter().copyWith(
                      type: 'trakt',
                      traktId: 'trending',
                      isMovie: true,
                    ),
                    'Trending Movies',
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                _TraktListTile(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.orangeAccent,
                  name: 'Trending Shows',
                  description: 'Most popular TV shows right now',
                  onTap: () => onSelect(
                    LibraryFilter.defaultFilter().copyWith(
                      type: 'trakt',
                      traktId: 'trending',
                      isMovie: false,
                    ),
                    'Trending Shows',
                  ),
                ),

                // User lists
                if (profile != null &&
                    profile!.isTraktValid &&
                    profile!.profileTraktLists.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingL),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppTheme.spacingS,
                      bottom: AppTheme.spacingS,
                    ),
                    child: Text(
                      'YOUR LISTS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...profile!.profileTraktLists.map(
                    (list) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                      child: _TraktListTile(
                        icon: Icons.bookmark_rounded,
                        iconColor: Colors.blueAccent,
                        name: list.name,
                        description: list.description.isNotEmpty
                            ? list.description
                            : 'Trakt list',
                        onTap: () => onSelect(
                          LibraryFilter.defaultFilter().copyWith(
                            type: 'trakt',
                            traktId: list.ids.slug,
                          ),
                          list.name,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TRAKT LIST TILE
// ═══════════════════════════════════════════════════════════════════════════════

class _TraktListTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String description;
  final VoidCallback onTap;

  const _TraktListTile({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.description,
    required this.onTap,
  });

  @override
  State<_TraktListTile> createState() => _TraktListTileState();
}

class _TraktListTileState extends State<_TraktListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 20, color: widget.iconColor),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESKTOP INTERNAL FILTER FORM (existing form, wrapped with back button)
// ═══════════════════════════════════════════════════════════════════════════════

class _DesktopInternalFilterForm extends StatefulWidget {
  final LibraryFilter initialFilter;
  final void Function(LibraryFilter) onApply;
  final VoidCallback onBack;

  const _DesktopInternalFilterForm({
    super.key,
    required this.initialFilter,
    required this.onApply,
    required this.onBack,
  });

  @override
  State<_DesktopInternalFilterForm> createState() =>
      _DesktopInternalFilterFormState();
}

class _DesktopInternalFilterFormState
    extends State<_DesktopInternalFilterForm> {
  late LibraryFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter.type == 'trakt'
        ? LibraryFilter.defaultFilter()
        : widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingM,
            AppTheme.spacingXL,
            AppTheme.spacingM,
            AppTheme.spacingM,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textSecondary,
                ),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  'Internal Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),

        // Form content
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

        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),

        // Actions
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
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
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
                onPressed: () =>
                    widget.onApply(_filter.copyWith(type: 'internal')),
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
    );
  }

  // ── Desktop form content ─────────────────────────────────────────────────

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

  // ── Shared form-building helpers ─────────────────────────────────────────

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
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOBILE INTERNAL FILTER SHEET (existing form, wrapped with back button)
// ═══════════════════════════════════════════════════════════════════════════════

class _MobileInternalFilterSheet extends StatefulWidget {
  final ScrollController scrollController;
  final LibraryFilter initialFilter;
  final void Function(LibraryFilter) onApply;
  final VoidCallback onBack;

  const _MobileInternalFilterSheet({
    super.key,
    required this.scrollController,
    required this.initialFilter,
    required this.onApply,
    required this.onBack,
  });

  @override
  State<_MobileInternalFilterSheet> createState() =>
      _MobileInternalFilterSheetState();
}

class _MobileInternalFilterSheetState
    extends State<_MobileInternalFilterSheet> {
  late LibraryFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter.type == 'trakt'
        ? LibraryFilter.defaultFilter()
        : widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingM,
        right: AppTheme.spacingM,
        top: AppTheme.spacingM,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingM,
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

          // Header with back
          Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  'Internal Filters',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
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
              controller: widget.scrollController,
              children: [_buildMobileFormContent()],
            ),
          ),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () =>
                  widget.onApply(_filter.copyWith(type: 'internal')),
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
    );
  }

  // ── Mobile form content ──────────────────────────────────────────────────

  Widget _buildMobileFormContent() {
    final genres = _filter.isMovie
        ? AppConstants.movieGenre
        : AppConstants.showGenre;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
}
