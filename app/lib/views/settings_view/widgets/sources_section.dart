import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/settings_view/settings_view_model.dart';

// ── Color palette for service cards ───────────────────────────────────────────

const _kServiceColors = [
  Color(0xFF7B61FF),
  Color(0xFF4CAF50),
  Color(0xFF00ACC1),
  Color(0xFFE91E63),
  Color(0xFFFF9800),
  Color(0xFF3F51B5),
  Color(0xFF009688),
  Color(0xFF795548),
];

IconData _iconForService(String id) {
  switch (id.toLowerCase()) {
    case 'ws':
      return Icons.cloud_outlined;
    case 'rd':
    case 'tb':
      return Icons.bolt_outlined;
    default:
      return Icons.extension_outlined;
  }
}

Color _colorForService(String id, int index) {
  switch (id.toLowerCase()) {
    case 'ws':
      return const Color(0xFF7B61FF);
    case 'rd':
      return const Color(0xFF4CAF50);
    case 'tb':
      return const Color(0xFF00ACC1);
    default:
      return _kServiceColors[index % _kServiceColors.length];
  }
}

// ── Section root ──────────────────────────────────────────────────────────────

class SourcesSection extends StatelessWidget {
  final Profile profile;

  const SourcesSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: AppTheme.roundedLarge,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Center(
          child: Text(
            'No services available',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < profile.services.length; i++) ...[
          _ServiceCard(
            service: profile.services[i],
            color: _colorForService(profile.services[i].id, i),
            icon: _iconForService(profile.services[i].id),
          ),
          if (i < profile.services.length - 1)
            const SizedBox(height: AppTheme.spacingM),
        ],
      ],
    );
  }
}

// ── Individual service card ───────────────────────────────────────────────────

class _ServiceCard extends StatefulWidget {
  final Service service;
  final Color color;
  final IconData icon;

  const _ServiceCard({
    required this.service,
    required this.color,
    required this.icon,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _showInput = false;
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.service.enabled;
    final vm = context.read<SettingsViewModel>();
    final color = widget.color;
    final isBoolType = widget.service.inputType == 'bool';

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
                    child: Icon(widget.icon, color: color, size: 20),
                  ),
                  const SizedBox(width: AppTheme.spacingM),

                  // ── Label + status ──────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.name,
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
                        _showInput = false;
                        vm.removeSource(widget.service.id);
                      },
                    )
                  else
                    _ActionChip(
                      label: 'Add',
                      color: color,
                      onTap: () {
                        if (isBoolType) {
                          // Bool type: just enable with empty value
                          vm.addSource(widget.service.id, '');
                        } else {
                          // String type: show text field
                          setState(() => _showInput = !_showInput);
                        }
                      },
                    ),
                ],
              ),

              // ── Text input for string-type services ────────────────────
              if (_showInput && !isBoolType && !enabled) ...[
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '${widget.service.name} API Key',
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
                          if (_inputController.text.trim().isEmpty) return;
                          vm.addSource(
                            widget.service.id,
                            _inputController.text.trim(),
                          );
                          _inputController.clear();
                          setState(() => _showInput = false);
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
