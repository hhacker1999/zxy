import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/views/screen.dart';

/// Shows a stream selection picker — bottom sheet on mobile, dialog on desktop.
/// [onStreamSelected] is called with the index of the chosen stream.
/// The picker pops itself after selection.
void showStreamSelectionPicker({
  required BuildContext context,
  required List<ZxyResolutionItem> streams,
  required int currentSelectedIndex,
  required bool showFormatted,
  required ValueChanged<int> onStreamSelected,
}) {
  final isMobile = Screen.of(context).shouldRenderMobile;

  if (isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _StreamPickerSheet(
        streams: streams,
        currentSelectedIndex: currentSelectedIndex,
        showFormatted: showFormatted,
        onStreamSelected: (index) {
          Navigator.pop(context);
          onStreamSelected(index);
        },
      ),
    );
  } else {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StreamPickerDialog(
        streams: streams,
        currentSelectedIndex: currentSelectedIndex,
        showFormatted: showFormatted,
        onStreamSelected: (index) {
          Navigator.pop(context);
          onStreamSelected(index);
        },
      ),
    );
  }
}

// =============================================================================
// DESKTOP DIALOG
// =============================================================================

class _StreamPickerDialog extends StatefulWidget {
  final List<ZxyResolutionItem> streams;
  final int currentSelectedIndex;
  final bool showFormatted;
  final ValueChanged<int> onStreamSelected;

  const _StreamPickerDialog({
    required this.streams,
    required this.currentSelectedIndex,
    required this.showFormatted,
    required this.onStreamSelected,
  });

  @override
  State<_StreamPickerDialog> createState() => _StreamPickerDialogState();
}

class _StreamPickerDialogState extends State<_StreamPickerDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXL,
        vertical: AppTheme.spacingL,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Select Stream',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Choose a stream to start playback.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Stream list
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.streams.length,
                      itemBuilder: (_, index) {
                        return _buildStreamTile(
                          context,
                          widget.streams[index],
                          index,
                          widget.currentSelectedIndex == index,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreamTile(
    BuildContext context,
    ZxyResolutionItem stream,
    int index,
    bool isSelected,
  ) {
    if (widget.showFormatted) {
      return _FormattedStreamTile(
        stream: stream,
        isSelected: isSelected,
        onTap: () => widget.onStreamSelected(index),
      );
    }

    return _DetailedStreamTile(
      stream: stream,
      isSelected: isSelected,
      onTap: () => widget.onStreamSelected(index),
    );
  }
}

// =============================================================================
// MOBILE BOTTOM SHEET
// =============================================================================

class _StreamPickerSheet extends StatelessWidget {
  final List<ZxyResolutionItem> streams;
  final int currentSelectedIndex;
  final bool showFormatted;
  final ValueChanged<int> onStreamSelected;

  const _StreamPickerSheet({
    required this.streams,
    required this.currentSelectedIndex,
    required this.showFormatted,
    required this.onStreamSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar + header
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Text(
                          'Select Stream',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          'Choose a stream to start playback.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stream list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                      ),
                      itemCount: streams.length,
                      itemBuilder: (_, index) {
                        final stream = streams[index];
                        final isSelected =
                            currentSelectedIndex == index;

                        if (showFormatted) {
                          return _FormattedStreamTile(
                            stream: stream,
                            isSelected: isSelected,
                            onTap: () => onStreamSelected(index),
                          );
                        }

                        return _DetailedStreamTile(
                          stream: stream,
                          isSelected: isSelected,
                          onTap: () => onStreamSelected(index),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// SHARED STREAM TILES (matching modern_sidebar.dart formatting)
// =============================================================================

/// Formatted style — shows stream name + description in a row (same as
/// modern sidebar when showFormattedStreams = true).
class _FormattedStreamTile extends StatelessWidget {
  final ZxyResolutionItem stream;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormattedStreamTile({
    required this.stream,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppTheme.accentColor.withOpacity(0.5))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (stream.name.isNotEmpty)
              Flexible(
                flex: 0,
                child: Text(
                  stream.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (stream.name.isNotEmpty && stream.description.isNotEmpty)
              const SizedBox(width: 8),
            if (stream.description.isNotEmpty)
              Expanded(
                child: Text(
                  stream.description,
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.accentColor,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Detailed style — shows resolution, size, visual tags, quality chip (same as
/// modern sidebar _RadioTile style when showFormattedStreams = false).
class _DetailedStreamTile extends StatelessWidget {
  final ZxyResolutionItem stream;
  final bool isSelected;
  final VoidCallback onTap;

  const _DetailedStreamTile({
    required this.stream,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sizeGB = (stream.size ?? 0) / (1024 * 1024 * 1024);
    String subtitle = "${sizeGB.toStringAsFixed(2)} GB";
    if (stream.visualTags.isNotEmpty) {
      subtitle += " • ${stream.visualTags.join(' ')}";
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppTheme.accentColor.withOpacity(0.5))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stream.resolution,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (stream.quality != null && stream.quality!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withOpacity(0.1)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stream.quality!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ],
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
