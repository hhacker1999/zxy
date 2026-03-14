import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // -----------------------------------------------------------------------------
  // 1. Color Palette (Purple "Cyber" Aesthetic)
  // -----------------------------------------------------------------------------

  // PRIMARY ACCENT: "Vibrant Violet"
  // Replaces the Plex Gold.
  // static const Color accentColor = Color(0xFF7F5AF0);
  static const Color accentColor = Color(0xFFFFFFFF);

  // Secondary Accent (Optional): Used for subtle highlights or gradients
  static const Color accentVariant = Color(0xFF94a1b2);

  // Backgrounds: Cool, deep grey-blues (Modern "Gunmetal" feel)
  // This differs from Plex's warm greys to match the cool Purple better.
  // static Color backgroundDark = Color(0xFF16161A);
  static const Color darkColor = Color(0xFF16161A);
  static Color backgroundDark = Color(0xFF010101);
  static const Color backgroundBlack = Color(
    0xFF010101,
  ); // Pure black for OLEDs

  // Surfaces (Cards, Sidebars)
  static const Color surfaceColor = Color(0xFF242629);
  static const Color surfaceLight = Color(0xFF383A40); // Hover states

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFE); // Pure White
  // static const Color textPrimary = Color(0xFF010101); // Pure White
  static const Color textSecondary = Color(0xFF94A1B2); // Cool Grey
  static const Color textDisabled = Color(0xFF5F6C7B);
  static const Color textBlack = Color(0xFF010101);

  // Status Colors (Softened for dark mode)
  static const Color errorColor = Color(0xFFEF4565);
  static const Color successColor = Color(0xFF2CB67D);

  static Color lightGreyBg = Colors.grey.withOpacity(0.1);
  static Color cardBgColor = Colors.black.withOpacity(0.2);

  // -----------------------------------------------------------------------------
  // 2. Dimensions & Border Radius
  // -----------------------------------------------------------------------------

  static const double radiusXSmall = 4.0; // Slightly softer than Plex
  static const double radiusSmall = 6.0; // Slightly softer than Plex
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusXXLarge = 32.0;

  static BorderRadius get roundedXSmall => BorderRadius.circular(radiusXSmall);
  static BorderRadius get roundedSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get roundedMedium => BorderRadius.circular(radiusMedium);
  static BorderRadius get roundedLarge => BorderRadius.circular(radiusLarge);
  static BorderRadius get roundedXLarge => BorderRadius.circular(radiusXLarge);
  static BorderRadius get roundedXXLarge => BorderRadius.circular(radiusXXLarge);

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 64.0;
  static const double spacingXXXL = 72.0;

  static const boxWidthXS = SizedBox(width: spacingXS);
  static const boxWidthS = SizedBox(width: spacingS);
  static const boxWidthM = SizedBox(width: spacingM);
  static const boxWidthL = SizedBox(width: spacingL);
  static const boxWidthXL = SizedBox(width: spacingXL);

  static const boxHeightXS = SizedBox(height: spacingXS);
  static const boxHeightS = SizedBox(height: spacingS);
  static const boxHeightM = SizedBox(height: spacingM);
  static const boxHeightL = SizedBox(height: spacingL);
  static const boxHeightXL = SizedBox(height: spacingXL);
  static const boxHeightXXL = SizedBox(height: spacingXXL);
  static const boxHeightXXXL = SizedBox(height: spacingXXXL);

  // -----------------------------------------------------------------------------
  // 3. Text Styles
  // -----------------------------------------------------------------------------

  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.poppins(
        // Switched to Poppins for a more "App" feel
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        height: 1.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.8, // More spacing for "caps" labels
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // 4. ThemeData
  // -----------------------------------------------------------------------------

  static ThemeData get purpleTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: accentColor,

      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundDark,
        error: errorColor,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),

      textTheme: _textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
      ),

      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 4, // Slight elevation adds depth with purple
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),

      // Buttons now pop with the purple
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor, // Links are now purple
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      // Stylish purple focus border for search bars
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight, // Lighter grey input
        hintStyle: const TextStyle(color: textDisabled),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
      ),

      // Progress bars (e.g. video player scrubbing)
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: surfaceLight,
        thumbColor: Colors.white,
        overlayColor: accentColor.withOpacity(0.2),
      ),
    );
  }
}
