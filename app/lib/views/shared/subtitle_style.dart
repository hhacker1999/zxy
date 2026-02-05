import 'dart:ui';

class SubtitleFontStyle {
  SubtitleFontStyle copyWith({
    double? fontSize,
    Color? color,
    double? fontPadding,
    Color? bgColor,
  }) {
    return SubtitleFontStyle(
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      fontPadding: fontPadding ?? this.fontPadding,
      bgColor: bgColor ?? this.bgColor,
    );
  }

  final double fontSize;
  final double fontPadding;
  final Color color;
  final Color bgColor;

  const SubtitleFontStyle({
    required this.fontSize,
    required this.fontPadding,
    required this.color,
    required this.bgColor,
  });
}
