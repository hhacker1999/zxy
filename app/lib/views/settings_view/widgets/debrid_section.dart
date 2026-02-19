import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/screen.dart';

import 'package:zxy_app/views/settings_view/settings_view_model.dart';

class DebridSection extends StatelessWidget {
  final Profile profile;

  const DebridSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final isConnected = profile.debridType.isNotEmpty;
    final isMobile = Screen.of(context).shouldRenderMobile;

    if (isConnected) {
      return _ConnectedCard(profile: profile, viewModel: viewModel);
    }

    // Disconnected state
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Provider selection
        if (isMobile)
          Column(
            children: [
              _DebridProviderCard(
                title: 'Real Debrid',
                isSelected: viewModel.selectedDebridType == 'rd',
                onTap: () => viewModel.selectDebridType('rd'),
              ),
              const SizedBox(height: AppTheme.spacingM),
              _DebridProviderCard(
                title: 'Torbox',
                isSelected: viewModel.selectedDebridType == 'tb',
                onTap: () => viewModel.selectDebridType('tb'),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _DebridProviderCard(
                  title: 'Real Debrid',
                  isSelected: viewModel.selectedDebridType == 'rd',
                  onTap: () => viewModel.selectDebridType('rd'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _DebridProviderCard(
                  title: 'Torbox',
                  isSelected: viewModel.selectedDebridType == 'tb',
                  onTap: () => viewModel.selectDebridType('tb'),
                ),
              ),
            ],
          ),

        // API key input
        if (viewModel.selectedDebridType.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingL),
          TextField(
            controller: viewModel.apiKeyController,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText:
                  '${viewModel.selectedDebridType == 'rd' ? 'Real Debrid' : 'Torbox'} API Key',
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              hintText: 'Enter your API key here',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textDisabled,
              ),
              prefixIcon: const Icon(
                Icons.vpn_key_outlined,
                color: AppTheme.textSecondary,
                size: 20,
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
          const SizedBox(height: AppTheme.spacingM),
          Align(
            alignment: Alignment.centerRight,
            child: _PrimaryButton(
              label: 'Add API Key',
              onTap: viewModel.storeDebridKey,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Connected card ────────────────────────────────────────────────────────────

class _ConnectedCard extends StatelessWidget {
  final Profile profile;
  final SettingsViewModel viewModel;

  const _ConnectedCard({required this.profile, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final providerName = profile.debridType == 'rd' ? 'Real Debrid' : 'Torbox';
    return ClipRRect(
      borderRadius: AppTheme.roundedLarge,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.06),
            borderRadius: AppTheme.roundedLarge,
            border: Border.all(
              color: AppTheme.successColor.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppTheme.successColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                    Text(
                      providerName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _DestructiveButton(
                label: 'Disconnect',
                onTap: viewModel.removeDebridKey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Provider selection card ───────────────────────────────────────────────────

class _DebridProviderCard extends StatefulWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DebridProviderCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DebridProviderCard> createState() => _DebridProviderCardState();
}

class _DebridProviderCardState extends State<_DebridProviderCard> {
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacingM,
            horizontal: AppTheme.spacingM,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.white.withValues(alpha: 0.07)
                : _hovered
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: AppTheme.roundedLarge,
            border: Border.all(
              color: widget.isSelected
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.10),
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.cloud_download_outlined,
                size: 36,
                color: widget.isSelected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isSelected
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared buttons ────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.roundedMedium),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _DestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DestructiveButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.errorColor,
          side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.roundedMedium),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.errorColor,
          ),
        ),
      ),
    );
  }
}
