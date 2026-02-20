import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/settings_bloc.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/auth/user.dart';

import 'package:zxy_app/views/settings_view/settings_view_model.dart';
import 'widgets/debrid_section.dart';
import 'widgets/general_section.dart';
import 'widgets/library_customization_section.dart';
import 'widgets/profiles_section.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final userBloc = context.read<UserBloc>();
        final settingsVm = context.watch<SettingsViewModel>()
          ..context = context;

        return Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppTheme.spacingM,
                  right: AppTheme.spacingM,
                  top: MediaQuery.of(context).padding.top + AppTheme.spacingM,
                  bottom: AppTheme.spacingXXL,
                ),
                child: ValueListenableBuilder<Profile?>(
                  valueListenable: userBloc.profileNotifier,
                  builder: (_, profile, _) {
                    if (profile == null) return const SizedBox();
                    return ValueListenableBuilder<User?>(
                      valueListenable: userBloc.userNotifier,
                      builder: (_, user, _) {
                        final settingsBloc = context.read<SettingsBloc>();
                        settingsVm.init(profile);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Page heading ──────────────────────────────
                            Text(
                              'Settings',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingXL),

                            // ── Account section ───────────────────────────
                            _SectionLabel(label: 'Account'),
                            const SizedBox(height: AppTheme.spacingM),
                            _AccountCard(
                              profile: profile,
                              onSwitchProfile: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.profileSelectionView),
                              onLogout: settingsVm.logout,
                            ),
                            const SizedBox(height: AppTheme.spacingXL),

                            // ── Profile management (admin only) ───────────
                            if (profile.isAdmin && user != null) ...[
                              _SectionLabel(label: 'Profiles'),
                              const SizedBox(height: AppTheme.spacingM),
                              ProfileManagementSection(
                                user: user,
                                currentProfile: profile,
                              ),
                              const SizedBox(height: AppTheme.spacingXL),
                            ],

                            // ── General section ───────────────────────────
                            _SectionLabel(label: 'General'),
                            const SizedBox(height: AppTheme.spacingM),
                            GeneralSection(settingsBloc: settingsBloc),
                            const SizedBox(height: AppTheme.spacingXL),

                            // ── Library customization ─────────────────────
                            LibraryCustomizationSection(viewModel: settingsVm),
                            const SizedBox(height: AppTheme.spacingXL),

                            // ── Debrid integration ────────────────────────
                            _SectionLabel(label: 'Debrid Integration'),
                            const SizedBox(height: AppTheme.spacingM),
                            DebridSection(profile: profile),
                            const SizedBox(height: AppTheme.spacingXXL),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),

          ],
        );
      },
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Account card ──────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onSwitchProfile;
  final VoidCallback onLogout;

  const _AccountCard({
    required this.profile,
    required this.onSwitchProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: AppTheme.roundedLarge,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // ── Profile info row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                _ProfileAvatar(name: profile.name, size: 48),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (profile.isAdmin)
                        Text(
                          'Admin',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),

          // ── Switch Profile ────────────────────────────────────────
          _AccountActionRow(
            icon: Icons.people_outline_rounded,
            label: 'Switch Profile',
            onTap: onSwitchProfile,
          ),

          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),

          // ── Log Out ───────────────────────────────────────────────
          _AccountActionRow(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            onTap: onLogout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _AccountActionRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _AccountActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_AccountActionRow> createState() => _AccountActionRowState();
}

class _AccountActionRowState extends State<_AccountActionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.textPrimary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hovered
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: color),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: color.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile avatar (small, for account card) ──────────────────────────────────

const _kAvatarColors = [
  Color(0xFF229ED9),
  Color(0xFFE50914),
  Color(0xFF2E7D32),
  Color(0xFFFFA000),
  Color(0xFF7B1FA2),
  Color(0xFF00ACC1),
];

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _ProfileAvatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = _kAvatarColors[name.hashCode.abs() % _kAvatarColors.length];
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
