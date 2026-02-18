import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/views/login_view/login_view_model.dart';
import 'package:zxy_app/views/screen.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  late final LoginViewModel viewModel;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late final AnimationController _bgController;
  late final AnimationController _cardController;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    viewModel = context.read<LoginViewModel>();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _cardController.forward();

    viewModel.isLoginMode.addListener(_onModeChange);
  }

  void _onModeChange() {
    _cardController.forward(from: 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bgController.dispose();
    _cardController.dispose();
    viewModel.isLoginMode.removeListener(_onModeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Screen.of(context).shouldRenderMobile;
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // ── Animated background orbs ─────────────────────────────────────
          _AnimatedBackground(controller: _bgController),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
        ],
      ),
    );
  }

  // ── Desktop: centered floating glass card ──────────────────────────────────
  Widget _buildDesktopLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingXL,
        ),
        child: ValueListenableBuilder<bool>(
          valueListenable: viewModel.isLoginMode,
          builder: (context, isLogin, _) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: FadeTransition(
                opacity: _cardFade,
                child: SlideTransition(
                  position: _cardSlide,
                  child: _GlassCard(
                    child: _buildFormContent(isLogin, isMobile: false),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Mobile: full-screen scroll, no card border ─────────────────────────────
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingL,
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: viewModel.isLoginMode,
        builder: (context, isLogin, _) {
          return FadeTransition(
            opacity: _cardFade,
            child: SlideTransition(
              position: _cardSlide,
              child: _buildFormContent(isLogin, isMobile: true),
            ),
          );
        },
      ),
    );
  }

  // ── Shared form content ────────────────────────────────────────────────────
  Widget _buildFormContent(bool isLogin, {required bool isMobile}) {
    final fieldGap = isMobile
        ? const SizedBox(height: AppTheme.spacingS + 4)
        : const SizedBox(height: AppTheme.spacingM);
    final sectionGap = isMobile
        ? const SizedBox(height: AppTheme.spacingL)
        : const SizedBox(height: AppTheme.spacingXL);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Logo mark ────────────────────────────────────────────────────
        _buildLogoMark(isMobile: isMobile),
        SizedBox(height: isMobile ? AppTheme.spacingM : AppTheme.spacingL),

        // ── Heading ──────────────────────────────────────────────────────
        _buildHeading(isLogin, isMobile: isMobile),
        sectionGap,

        // ── Error banner ─────────────────────────────────────────────────
        _buildErrorBanner(),

        // ── Fields ───────────────────────────────────────────────────────
        if (!isLogin) ...[
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            isMobile: isMobile,
          ),
          fieldGap,
        ],
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          isMobile: isMobile,
        ),
        fieldGap,
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          isVisible: _passwordVisible,
          isMobile: isMobile,
          onToggleVisibility: () =>
              setState(() => _passwordVisible = !_passwordVisible),
        ),
        if (!isLogin) ...[
          fieldGap,
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            isVisible: _confirmPasswordVisible,
            isMobile: isMobile,
            onToggleVisibility: () => setState(
              () => _confirmPasswordVisible = !_confirmPasswordVisible,
            ),
          ),
        ],

        sectionGap,

        // ── Primary action button ─────────────────────────────────────────
        _buildActionButton(isLogin, isMobile: isMobile),

        const SizedBox(height: AppTheme.spacingM),

        // ── Mode toggle ───────────────────────────────────────────────────
        _buildModeToggle(isLogin),

        // Extra bottom breathing room on mobile (keyboard safe area)
        if (isMobile) const SizedBox(height: AppTheme.spacingXL),
      ],
    );
  }

  Widget _buildLogoMark({bool isMobile = false}) {
    final size = isMobile ? 44.0 : 52.0;
    final fontSize = isMobile ? 22.0 : 26.0;
    final radius = isMobile ? 12.0 : 14.0;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'Z',
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildHeading(bool isLogin, {bool isMobile = false}) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          isLogin ? 'Welcome back' : 'Create account',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            height: 1.2,
          ),
          textAlign: isMobile ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          isLogin
              ? 'Sign in to continue to ZXY'
              : 'Join ZXY and start watching',
          style: GoogleFonts.inter(
            fontSize: isMobile ? 13 : 14,
            color: AppTheme.textSecondary,
          ),
          textAlign: isMobile ? TextAlign.left : TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return ValueListenableBuilder<String?>(
      valueListenable: viewModel.error,
      builder: (context, error, _) {
        if (error == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS + 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.08),
              borderRadius: AppTheme.roundedMedium,
              border: Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.errorColor,
                  size: 18,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    error,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    bool isMobile = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    final vertPad = isMobile ? AppTheme.spacingS + 4.0 : AppTheme.spacingM;
    // On mobile use a slightly more opaque fill so fields pop against the
    // plain dark background (no glass card behind them).
    final fillColor = isMobile
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.05);
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
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
        fillColor: fillColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: vertPad,
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

  Widget _buildActionButton(bool isLogin, {bool isMobile = false}) {
    final buttonHeight = isMobile ? 50.0 : 52.0;
    return ValueListenableBuilder<bool>(
      valueListenable: viewModel.isLoading,
      builder: (context, isLoading, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  height: buttonHeight,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  key: const ValueKey('button'),
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLogin) {
                        viewModel.login(
                          context,
                          _emailController.text,
                          _passwordController.text,
                        );
                      } else {
                        viewModel.signup(
                          context,
                          _nameController.text,
                          _emailController.text,
                          _passwordController.text,
                          _confirmPasswordController.text,
                        );
                      }
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
                      isLogin ? 'Sign In' : 'Create Account',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildModeToggle(bool isLogin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? "Don't have an account?" : 'Already have an account?',
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
        ),
        TextButton(
          onPressed: viewModel.toggleMode,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            isLogin ? 'Sign Up' : 'Sign In',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Glassmorphism card ────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Animated background ───────────────────────────────────────────────────────

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return SizedBox.expand(child: CustomPaint(painter: _OrbPainter(t)));
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Orb 1 — top-left, warm white
    _drawOrb(
      canvas,
      center: Offset(
        size.width * (0.15 + 0.08 * math.sin(t * math.pi)),
        size.height * (0.18 + 0.06 * math.cos(t * math.pi)),
      ),
      radius: size.width * 0.38,
      color: Colors.white.withValues(alpha: 0.035),
    );

    // Orb 2 — bottom-right, slightly larger
    _drawOrb(
      canvas,
      center: Offset(
        size.width * (0.82 + 0.06 * math.cos(t * math.pi + 1)),
        size.height * (0.78 + 0.07 * math.sin(t * math.pi + 1)),
      ),
      radius: size.width * 0.42,
      color: Colors.white.withValues(alpha: 0.025),
    );

    // Orb 3 — center-right, subtle
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
