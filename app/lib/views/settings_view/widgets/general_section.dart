import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/bloc/settings_bloc.dart';
import 'package:zxy_app/views/screen.dart';

class GeneralSection extends StatelessWidget {
  final SettingsBloc settingsBloc;

  const GeneralSection({super.key, required this.settingsBloc});

  @override
  Widget build(BuildContext context) {
    final isMobile = Screen.of(context).shouldRenderMobile;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: AppTheme.roundedLarge,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (!isMobile) ...[
            ModernSettingTile(
              title: 'Dynamic Theme',
              subtitle: 'Extract color info from context image',
              icon: Icons.dark_mode_outlined,
              valueNotifier: settingsBloc.isDynamic,
              onChanged: (value) => settingsBloc.isDynamic = value,
              isFirst: true,
              isLast: false,
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
          ],
          ModernSettingTile(
            title: 'Show Poster Ratings',
            subtitle: 'Display ratings on movie and TV show posters',
            icon: Icons.star_outline_rounded,
            valueNotifier: settingsBloc.showPosterRatings,
            onChanged: (value) => settingsBloc.showPosterRatings = value,
            isFirst: isMobile,
            isLast: false,
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
          ModernDropdownTile<String>(
            title: 'Default Audio Language',
            subtitle: 'Preferred language for media playback',
            icon: Icons.language_rounded,
            valueNotifier: settingsBloc.langNotifier,
            items: LanguageMapper.nameToCodes.keys.toList()..sort(),
            onChanged: (value) {
              if (value != null) {
                settingsBloc.language = value;
              }
            },
            itemToString: (String val) => val,
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
          ModernDropdownTile<String>(
            title: 'Default Resolution',
            subtitle: 'Preferred video resolution for media',
            icon: Icons.hd_outlined,
            valueNotifier: settingsBloc.resolutionNotifier,
            items: AppConstants.resolutionMap.keys.toList(),
            onChanged: (value) {
              if (value != null) {
                settingsBloc.resolution = value;
              }
            },
            itemToString: (String val) => val,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class ModernSettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueNotifier<bool> valueNotifier;
  final ValueChanged<bool> onChanged;
  final bool isFirst;
  final bool isLast;

  const ModernSettingTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.valueNotifier,
    required this.onChanged,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: value
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: value ? AppTheme.textPrimary : AppTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Switch
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.white.withValues(alpha: 0.3),
                inactiveThumbColor: AppTheme.textSecondary,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModernDropdownTile<T> extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueNotifier<T> valueNotifier;
  final List<T> items;
  final void Function(T?) onChanged;
  final String Function(T) itemToString;
  final bool isFirst;
  final bool isLast;

  const ModernDropdownTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.valueNotifier,
    required this.items,
    required this.onChanged,
    required this.itemToString,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<ModernDropdownTile<T>> createState() => _ModernDropdownTileState<T>();
}

class _ModernDropdownTileState<T> extends State<ModernDropdownTile<T>> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown(BuildContext context, T currentValue) {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _showDropdown(context, currentValue);
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  void _showDropdown(BuildContext context, T currentValue) {
    final RenderBox renderBox =
        _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
                child: Container(),
              ),
            ),
            Positioned(
              top: offset.dy + size.height + 8,
              left: offset.dx - (250 - size.width),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 250,
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: AppTheme.darkColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        final isSelected = item == currentValue;

                        return InkWell(
                          onTap: () {
                            widget.onChanged(item);
                            _closeDropdown();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.transparent,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.itemToString(item),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isSelected
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: AppTheme.textPrimary,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: widget.valueNotifier,
      builder: (context, value, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: AppTheme.textPrimary, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                focusColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () => _toggleDropdown(context, value),
                child: Container(
                  key: _key,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _isOpen
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.itemToString(value),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
