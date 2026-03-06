import 'dart:ui';

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
                              onDeleteAccount: profile.isAdmin
                                  ? () => _showDeleteAccountDialog(
                                      context,
                                      settingsVm,
                                    )
                                  : null,
                              onTraktLogin: settingsVm.loginTrakt,
                              onTraktLogout: settingsVm.deleteTrakt,
                              waitingTraktLogin: userBloc.waitingTraktLogin,
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

void _showDeleteAccountDialog(BuildContext context, SettingsViewModel vm) {
  showDialog(
    context: context,
    builder: (_) => _DeleteAccountDialog(onConfirm: vm.deleteAccount),
  );
}

class _AccountCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onSwitchProfile;
  final VoidCallback onLogout;
  final VoidCallback? onDeleteAccount;
  final VoidCallback onTraktLogin;
  final VoidCallback onTraktLogout;
  final ValueNotifier<bool> waitingTraktLogin;

  const _AccountCard({
    required this.profile,
    required this.onSwitchProfile,
    required this.onLogout,
    required this.onTraktLogin,
    required this.onTraktLogout,
    required this.waitingTraktLogin,
    this.onDeleteAccount,
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

          // ── Trakt ─────────────────────────────────────────────────
          _TraktRow(
            profile: profile,
            onLogin: onTraktLogin,
            onLogout: onTraktLogout,
            waitingTraktLogin: waitingTraktLogin,
          ),

          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),

          // ── Log Out ───────────────────────────────────────────────
          _AccountActionRow(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            onTap: onLogout,
            isDestructive: true,
          ),

          // ── Delete Account (admin only) ───────────────────────────
          if (onDeleteAccount != null) ...[
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
            _AccountActionRow(
              icon: Icons.delete_forever_rounded,
              label: 'Delete Account',
              onTap: onDeleteAccount!,
              isDestructive: true,
            ),
          ],
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

// ── Trakt row (inside Account card) ──────────────────────────────────────────

const _kTraktRed = Color(0xFFED1C24);

class _TraktRow extends StatelessWidget {
  final Profile profile;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final ValueNotifier<bool> waitingTraktLogin;

  const _TraktRow({
    required this.profile,
    required this.onLogin,
    required this.onLogout,
    required this.waitingTraktLogin,
  });

  /// Compact Trakt «t» logo drawn with Canvas.
  Widget _traktLogo({double size = 20}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TraktLogoPainter()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: waitingTraktLogin,
      builder: (_, isWaiting, _) {
        // ── Waiting ──────────────────────────────────────────────────
        if (isWaiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingM,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kTraktRed,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  'Waiting for Trakt login…',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // ── Connected ────────────────────────────────────────────────
        if (profile.isTraktValid) {
          return _TraktConnectedRow(
            traktLogo: _traktLogo(),
            onLogout: onLogout,
          );
        }

        // ── Login / Re-login ─────────────────────────────────────────
        final isRelogin = profile.traktExpiry != null;
        return _TraktLoginRow(
          traktLogo: _traktLogo(),
          label: isRelogin ? 'Re-login with Trakt' : 'Login with Trakt',
          onTap: onLogin,
        );
      },
    );
  }
}

class _TraktConnectedRow extends StatefulWidget {
  final Widget traktLogo;
  final VoidCallback onLogout;
  const _TraktConnectedRow({required this.traktLogo, required this.onLogout});

  @override
  State<_TraktConnectedRow> createState() => _TraktConnectedRowState();
}

class _TraktConnectedRowState extends State<_TraktConnectedRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingM,
      ),
      child: Row(
        children: [
          // Logo badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _kTraktRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kTraktRed.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: widget.traktLogo,
          ),
          const SizedBox(width: AppTheme.spacingM),
          // Label + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trakt',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Connected',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Logout button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: widget.onLogout,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _hovered
                      ? _kTraktRed.withValues(alpha: 0.18)
                      : _kTraktRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kTraktRed.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTraktRed,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TraktLoginRow extends StatefulWidget {
  final Widget traktLogo;
  final String label;
  final VoidCallback onTap;
  const _TraktLoginRow({
    required this.traktLogo,
    required this.label,
    required this.onTap,
  });

  @override
  State<_TraktLoginRow> createState() => _TraktLoginRowState();
}

class _TraktLoginRowState extends State<_TraktLoginRow> {
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
          color: _hovered
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          child: Row(
            children: [
              // Logo badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kTraktRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kTraktRed.withValues(alpha: 0.2)),
                ),
                alignment: Alignment.center,
                child: widget.traktLogo,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppTheme.textPrimary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Trakt logo painter ────────────────────────────────────────────────────────

class _TraktLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kTraktRed
      ..style = PaintingStyle.fill;

    // Draw a filled circle background
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, paint);

    // Draw the "T" letter in white
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'T',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.65,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_TraktLogoPainter oldDelegate) => false;
}

// ── Delete Account confirmation dialog ────────────────────────────────────────

class _DeleteAccountDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _DeleteAccountDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

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
                  // ── Warning icon ───────────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.errorColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: AppTheme.errorColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // ── Title ──────────────────────────────────────────────────
                  Text(
                    'Delete Account',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Body ───────────────────────────────────────────────────
                  Text(
                    'This will permanently delete your account and all associated data. This action cannot be undone.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXL),

                  // ── Actions ────────────────────────────────────────────────
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
                              Navigator.pop(context);
                              onConfirm();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppTheme.roundedMedium,
                              ),
                            ),
                            child: Text(
                              'Delete',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
