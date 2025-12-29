import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';

class ModernDropdown<T> extends StatelessWidget {
  final List<DropdownMenuEntry<T>> entries;
  final String hintText;
  final IconData? prefixIcon;
  final void Function(T?) onSelected;
  final T? initialSelection;
  final double height;

  const ModernDropdown({
    super.key,
    required this.entries,
    required this.onSelected,
    this.hintText = 'Select',
    this.prefixIcon,
    this.initialSelection,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: context.read<ImageBloc>().bgGradColor,
      builder: (_, bgColor, _) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(canvasColor: AppTheme.surfaceColor.withOpacity(0.2)),
          child: DropdownMenu<T>(
            initialSelection: initialSelection,
            requestFocusOnTap: false,
            enableFilter: false,
            width: 200,
            textStyle: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            inputDecorationTheme: InputDecorationTheme(
              isDense: true,
              constraints: BoxConstraints.tight(Size.fromHeight(height)),
              filled: true,
              fillColor: AppTheme.backgroundDark.withOpacity(0.3),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.accentColor,
                  width: 1.5,
                ),
              ),
            ),
            menuStyle: MenuStyle(
              backgroundColor: WidgetStateProperty.all(
                bgColor != null
                    ? bgColor.withOpacity(0.80)
                    : AppTheme.surfaceColor.withOpacity(0.90),
              ),
              surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
              elevation: WidgetStateProperty.all(10),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            dropdownMenuEntries: entries,
            onSelected: onSelected,
          ),
        );
      },
    );
  }
}
