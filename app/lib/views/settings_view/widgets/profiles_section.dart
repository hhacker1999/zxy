import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/screen.dart';

import 'package:zxy_app/views/settings_view/settings_view_model.dart';

// ── Avatar palette (same as profile_selection_view) ───────────────────────────
const _kAvatarColors = [
  Color(0xFF229ED9),
  Color(0xFFE50914),
  Color(0xFF2E7D32),
  Color(0xFFFFA000),
  Color(0xFF7B1FA2),
  Color(0xFF00ACC1),
];

Color _avatarColor(String name) =>
    _kAvatarColors[name.hashCode.abs() % _kAvatarColors.length];

// ── Profile Management Section ────────────────────────────────────────────────

class ProfileManagementSection extends StatelessWidget {
  final User user;
  final Profile currentProfile;

  const ProfileManagementSection({
    super.key,
    required this.user,
    required this.currentProfile,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SettingsViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Manage Profiles',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            _GlassIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Create Profile',
              onTap: () =>
                  _showProfileDialog(context, currentProfile: currentProfile),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),

        // Profile chips
        Wrap(
          spacing: AppTheme.spacingM,
          runSpacing: AppTheme.spacingM,
          children: [
            ProfileChip(
              profile: currentProfile,
              onEdit: () => _showProfileDialog(
                context,
                profileToEdit: currentProfile,
                currentProfile: currentProfile,
              ),
              onDelete: () => viewModel.deleteProfile(currentProfile.id),
              isCurrent: true,
            ),
            ...user.profiles
                .where((e) => e.id != currentProfile.id)
                .map(
                  (p) => ProfileChip(
                    profile: p,
                    onEdit: () => _showProfileDialog(
                      context,
                      profileToEdit: p,
                      currentProfile: currentProfile,
                    ),
                    onDelete: () => viewModel.deleteProfile(p.id),
                    isCurrent: false,
                  ),
                ),
          ],
        ),
      ],
    );
  }

  void _showProfileDialog(
    BuildContext context, {
    Profile? profileToEdit,
    required Profile currentProfile,
  }) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SettingsViewModel>(),
        child: ProfileDialog(
          profileToEdit: profileToEdit,
          currentProfile: currentProfile,
        ),
      ),
    );
  }
}

// ── Glass icon button ─────────────────────────────────────────────────────────

class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
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

// ── Profile Chip ──────────────────────────────────────────────────────────────

class ProfileChip extends StatefulWidget {
  final Profile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isCurrent;

  const ProfileChip({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onDelete,
    required this.isCurrent,
  });

  @override
  State<ProfileChip> createState() => _ProfileChipState();
}

class _ProfileChipState extends State<ProfileChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Screen.of(context).shouldRenderMobile;
    final avatarColor = _avatarColor(widget.profile.name);
    final showButtons = isMobile || _isHovered;
    final avatarSize = isMobile ? 120.0 : 140.0;
    final fontSize = isMobile ? 48.0 : 56.0;
    final initial = widget.profile.name.isEmpty
        ? '?'
        : widget.profile.name[0].toUpperCase();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: SizedBox(
        width: avatarSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Avatar ───────────────────────────────────────────────────
            Stack(
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.04 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                      border: widget.isCurrent
                          ? Border.all(color: Colors.white, width: 3)
                          : _isHovered
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 2,
                            )
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: avatarColor.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.poppins(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                        // Admin badge
                        if (widget.profile.isAdmin)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Admin',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // PIN lock badge
                        if (widget.profile.isPinProtected)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                size: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Context menu button ───────────────────────────────────
                if (showButtons)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _ProfileContextMenu(
                      onEdit: widget.onEdit,
                      onDelete: widget.isCurrent ? null : widget.onDelete,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingS + 4),

            // ── Name ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: _isHovered
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: _isHovered
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                    child: Text(
                      widget.profile.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                if (widget.isCurrent) ...[
                  const SizedBox(width: 5),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile context menu (themed) ─────────────────────────────────────────────

class _ProfileContextMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ProfileContextMenu({required this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 32),
      color: const Color(0xFF1E1E24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      elevation: 8,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit',
          onTap: onEdit,
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                'Edit',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (onDelete != null)
          PopupMenuItem<String>(
            value: 'delete',
            onTap: onDelete,
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(width: 10),
                Text(
                  'Delete',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: const Icon(Icons.more_horiz, size: 14, color: Colors.white),
      ),
    );
  }
}

// ── Profile Dialog (glass style) ──────────────────────────────────────────────

class ProfileDialog extends StatefulWidget {
  final Profile? profileToEdit;
  final Profile currentProfile;

  const ProfileDialog({
    super.key,
    this.profileToEdit,
    required this.currentProfile,
  });

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _pinController;
  bool _copyDebrid = false;
  bool _pinVisible = false;

  bool get isEditing => widget.profileToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profileToEdit?.name ?? '',
    );
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SettingsViewModel>();
    final hasDebrid = widget.currentProfile.debridType.isNotEmpty;
    final isMobile = Screen.of(context).shouldRenderMobile;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.spacingM : AppTheme.spacingXL,
        vertical: AppTheme.spacingXL,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
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
                  // ── Header ──────────────────────────────────────────────
                  Text(
                    isEditing ? 'Edit Profile' : 'Create Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEditing
                        ? 'Update the profile name or PIN'
                        : 'Set a name and optional PIN for the new profile',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXL),

                  // ── Name field ───────────────────────────────────────────
                  _GlassTextField(
                    controller: _nameController,
                    label: 'Profile Name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // ── PIN field ────────────────────────────────────────────
                  _GlassTextField(
                    controller: _pinController,
                    label: 'PIN (Optional)',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    isVisible: _pinVisible,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    onToggleVisibility: () =>
                        setState(() => _pinVisible = !_pinVisible),
                  ),

                  // ── Copy debrid checkbox ─────────────────────────────────
                  if (!isEditing && hasDebrid) ...[
                    const SizedBox(height: AppTheme.spacingM),
                    _GlassCheckbox(
                      value: _copyDebrid,
                      title: 'Include Debrid Key',
                      subtitle: 'Copy from current profile',
                      onChanged: (val) =>
                          setState(() => _copyDebrid = val ?? false),
                    ),
                  ],

                  const SizedBox(height: AppTheme.spacingXL),

                  // ── Actions ──────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
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
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              if (isEditing) {
                                viewModel.updateProfile(
                                  _nameController.text.isEmpty
                                      ? ''
                                      : _nameController.text,
                                  widget.profileToEdit!.id,
                                  pin: _pinController.text.isNotEmpty
                                      ? _pinController.text
                                      : null,
                                );
                              } else {
                                viewModel.createProfile(
                                  _nameController.text,
                                  _pinController.text.isNotEmpty
                                      ? _pinController.text
                                      : null,
                                  _copyDebrid,
                                );
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.roundedMedium,
                              ),
                            ),
                            child: Text(
                              isEditing ? 'Save' : 'Create',
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

// ── Shared glass text field ───────────────────────────────────────────────────

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool isVisible;
  final TextInputType? keyboardType;
  final int? maxLength;
  final VoidCallback? onToggleVisibility;

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.isVisible = false,
    this.keyboardType,
    this.maxLength,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
        counterText: '',
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: AppTheme.roundedMedium,
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTheme.roundedMedium,
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTheme.roundedMedium,
          borderSide: const BorderSide(color: AppTheme.accentColor, width: 1.5),
        ),
      ),
    );
  }
}

// ── Shared glass checkbox ─────────────────────────────────────────────────────

class _GlassCheckbox extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool?> onChanged;

  const _GlassCheckbox({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: AppTheme.roundedMedium,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: CheckboxListTile(
        checkColor: Colors.black,
        activeColor: Colors.white,
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
        ),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingXS,
        ),
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.roundedMedium),
      ),
    );
  }
}
