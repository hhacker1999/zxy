import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/settings_view/settings_view_model.dart';

// ── Source definition ─────────────────────────────────────────────────────────

class _SourceDef {
  final String key; // API key sent to addSource / removeSource
  final String label; // UI display name
  final IconData icon;
  final Color color;
  final bool needsApiKey;

  const _SourceDef({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    this.needsApiKey = false,
  });
}

const _sources = [
  _SourceDef(
    key: 'ws',
    label: 'WebStreamr',
    icon: Icons.cloud_outlined,
    color: Color(0xFF7B61FF),
  ),
  _SourceDef(
    key: 'rd',
    label: 'Real Debrid',
    icon: Icons.bolt_outlined,
    color: Color(0xFF4CAF50),
    needsApiKey: true,
  ),
  _SourceDef(
    key: 'tb',
    label: 'Torbox',
    icon: Icons.bolt_outlined,
    color: Color(0xFF00ACC1),
    needsApiKey: true,
  ),
];

// ── Helpers ───────────────────────────────────────────────────────────────────

bool _isEnabled(Profile profile, String key) {
  switch (key) {
    case 'ws':
      return profile.webstreamr;
    case 'rd':
      return profile.realDebrid.isNotEmpty;
    case 'tb':
      return profile.torbox.isNotEmpty;
    default:
      return false;
  }
}

// ── Section root ──────────────────────────────────────────────────────────────

class SourcesSection extends StatelessWidget {
  final Profile profile;

  const SourcesSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _sources.length; i++) ...[
          _SourceCard(source: _sources[i], profile: profile),
          if (i < _sources.length - 1) const SizedBox(height: AppTheme.spacingM),
        ],
      ],
    );
  }
}

// ── Individual source card ────────────────────────────────────────────────────

class _SourceCard extends StatefulWidget {
  final _SourceDef source;
  final Profile profile;

  const _SourceCard({required this.source, required this.profile});

  @override
  State<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<_SourceCard> {
  bool _showKeyInput = false;
  final _keyController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _isEnabled(widget.profile, widget.source.key);
    final vm = context.read<SettingsViewModel>();
    final color = widget.source.color;

    return ClipRRect(
      borderRadius: AppTheme.roundedLarge,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: enabled
                ? color.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: AppTheme.roundedLarge,
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // ── Icon badge ──────────────────────────────────────────
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.source.icon, color: color, size: 20),
                  ),
                  const SizedBox(width: AppTheme.spacingM),

                  // ── Label + status ──────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.source.label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: enabled
                                    ? const Color(0xFF4CAF50)
                                    : AppTheme.textDisabled,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              enabled ? 'Connected' : 'Not connected',
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

                  // ── Action button ───────────────────────────────────────
                  if (enabled)
                    _ActionChip(
                      label: 'Remove',
                      color: AppTheme.errorColor,
                      onTap: () {
                        _showKeyInput = false;
                        vm.removeSource(widget.source.key);
                      },
                    )
                  else
                    _ActionChip(
                      label: 'Add',
                      color: color,
                      onTap: () {
                        if (widget.source.needsApiKey) {
                          setState(() => _showKeyInput = !_showKeyInput);
                        } else {
                          vm.addSource(widget.source.key, 'true');
                        }
                      },
                    ),
                ],
              ),

              // ── API key input (Real Debrid / Torbox only) ──────────────
              if (_showKeyInput && widget.source.needsApiKey && !enabled) ...[
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _keyController,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '${widget.source.label} API Key',
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
                            vertical: 12,
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
                            borderSide: BorderSide(
                              color: color,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_keyController.text.trim().isEmpty) return;
                          vm.addSource(
                            widget.source.key,
                            _keyController.text.trim(),
                          );
                          _keyController.clear();
                          setState(() => _showKeyInput = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
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
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small action chip (Add / Remove) ──────────────────────────────────────────

class _ActionChip extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.18)
                : widget.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.color.withValues(alpha: 0.30)),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
