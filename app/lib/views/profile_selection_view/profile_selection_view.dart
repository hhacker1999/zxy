import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/profile_selection_view/profile_selection_view_model.dart';
import 'package:zxy_app/views/screen.dart';

// ── Avatar palette ─────────────────────────────────────────────────────────────
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

// ── View ───────────────────────────────────────────────────────────────────────

class ProfileSelectionView extends StatefulWidget {
  const ProfileSelectionView({super.key});

  @override
  State<ProfileSelectionView> createState() => _ProfileSelectionViewState();
}

class _ProfileSelectionViewState extends State<ProfileSelectionView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserBloc>().userNotifier.value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No User Logged In')));
    }
    final viewModel = context.watch<ProfileSelectionViewModel>();
    final isMobile = Screen.of(context).shouldRenderMobile;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // ── Animated background ───────────────────────────────────────────
          _AnimatedBackground(controller: _bgController),

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: isMobile
                ? _buildMobileLayout(context, user, viewModel)
                : _buildDesktopLayout(context, user, viewModel),
          ),

          // ── PIN overlay ───────────────────────────────────────────────────
          if (viewModel.showPinInput)
            _PinOverlay(viewModel: viewModel, isMobile: isMobile),

          // ── Loading overlay ───────────────────────────────────────────────
          if (viewModel.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accentColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Desktop: centered, generous spacing ────────────────────────────────────
  Widget _buildDesktopLayout(
    BuildContext context,
    User user,
    ProfileSelectionViewModel viewModel,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXL,
          vertical: AppTheme.spacingXXL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo mark
            _LogoMark(size: 48),
            const SizedBox(height: AppTheme.spacingL),

            // Heading
            Text(
              "Who's watching?",
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select your profile to continue',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXXL),

            // Profile grid
            Wrap(
              spacing: AppTheme.spacingXL,
              runSpacing: AppTheme.spacingXL,
              alignment: WrapAlignment.center,
              children: user.profiles.map((profile) {
                return _ProfileTile(
                  profile: profile,
                  isMobile: false,
                  onTap: () => viewModel.selectProfile(context, profile),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile: full-width, left-aligned list ──────────────────────────────────
  Widget _buildMobileLayout(
    BuildContext context,
    User user,
    ProfileSelectionViewModel viewModel,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + heading row
          Row(
            children: [
              _LogoMark(size: 36),
              const SizedBox(width: AppTheme.spacingM),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Who's watching?",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'Select your profile',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Profile grid — 2 per row on mobile
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.spacingM,
              mainAxisSpacing: AppTheme.spacingM,
              childAspectRatio: 0.9,
            ),
            itemCount: user.profiles.length,
            itemBuilder: (context, i) {
              final profile = user.profiles[i];
              return _ProfileTile(
                profile: profile,
                isMobile: true,
                onTap: () => viewModel.selectProfile(context, profile),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Logo mark (reused from login) ─────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.27),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'Z',
        style: GoogleFonts.poppins(
          fontSize: size * 0.5,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          height: 1,
        ),
      ),
    );
  }
}

// ── Profile tile ──────────────────────────────────────────────────────────────

class _ProfileTile extends StatefulWidget {
  final Profile profile;
  final bool isMobile;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.profile,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_ProfileTile> createState() => _ProfileTileState();
}

class _ProfileTileState extends State<_ProfileTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    final avatarSize = isMobile ? 100.0 : 140.0;
    final fontSize = isMobile ? 40.0 : 56.0;
    final color = _avatarColor(widget.profile.name);
    final initial = widget.profile.name.substring(0, 1).toUpperCase();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Avatar ─────────────────────────────────────────────────────
            AnimatedScale(
              scale: _hovered ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
                  border: _hovered
                      ? Border.all(color: Colors.white, width: 3)
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                  boxShadow: _hovered
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
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
                    // Initial letter
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
                    // Lock badge
                    if (widget.profile.isPinProtected)
                      Positioned(
                        bottom: isMobile ? 6 : 8,
                        right: isMobile ? 6 : 8,
                        child: Container(
                          padding: EdgeInsets.all(isMobile ? 5 : 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.lock_rounded,
                            size: isMobile ? 12 : 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ), // AnimatedScale

            const SizedBox(height: AppTheme.spacingS + 4),

            // ── Name ───────────────────────────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: GoogleFonts.inter(
                fontSize: isMobile ? 13 : 14,
                fontWeight: _hovered ? FontWeight.w600 : FontWeight.w500,
                color: _hovered ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
              child: Text(
                widget.profile.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PIN overlay ───────────────────────────────────────────────────────────────

class _PinOverlay extends StatelessWidget {
  final ProfileSelectionViewModel viewModel;
  final bool isMobile;

  const _PinOverlay({required this.viewModel, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: viewModel.cancelPinInput,
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: GestureDetector(
            // Prevent taps inside the dialog from dismissing it
            onTap: () {},
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 380,
              ),
              child: Padding(
                padding: isMobile
                    ? const EdgeInsets.symmetric(horizontal: AppTheme.spacingM)
                    : EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingXL),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusXLarge,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Lock icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: AppTheme.textPrimary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),

                          Text(
                            'Enter PIN',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This profile is PIN protected',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXL),

                          // PIN field
                          TextField(
                            controller: viewModel.pinController,
                            autofocus: true,
                            maxLength: 6,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              letterSpacing: 10,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.07),
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
                              hintText: '• • • • • •',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 18,
                                color: AppTheme.textDisabled,
                                letterSpacing: 6,
                              ),
                            ),
                            onSubmitted: (_) => viewModel.submitPin(context),
                          ),

                          const SizedBox(height: AppTheme.spacingXL),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: viewModel.cancelPinInput,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.textSecondary,
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
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
                                    onPressed: () =>
                                        viewModel.submitPin(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppTheme.roundedMedium,
                                      ),
                                    ),
                                    child: Text(
                                      'Confirm',
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
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated background (same orbs as login) ──────────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox.expand(
          child: CustomPaint(painter: _OrbPainter(controller.value)),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _drawOrb(
      canvas,
      center: Offset(
        size.width * (0.15 + 0.08 * math.sin(t * math.pi)),
        size.height * (0.18 + 0.06 * math.cos(t * math.pi)),
      ),
      radius: size.width * 0.38,
      color: Colors.white.withValues(alpha: 0.035),
    );
    _drawOrb(
      canvas,
      center: Offset(
        size.width * (0.82 + 0.06 * math.cos(t * math.pi + 1)),
        size.height * (0.78 + 0.07 * math.sin(t * math.pi + 1)),
      ),
      radius: size.width * 0.42,
      color: Colors.white.withValues(alpha: 0.025),
    );
    _drawOrb(
      canvas,
      center: Offset(
        size.width * (0.70 + 0.05 * math.sin(t * math.pi + 2)),
        size.height * (0.35 + 0.08 * math.cos(t * math.pi + 2)),
      ),
      radius: size.width * 0.28,
      color: Colors.white.withValues(alpha: 0.02),
    );
  }

  void _drawOrb(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}
