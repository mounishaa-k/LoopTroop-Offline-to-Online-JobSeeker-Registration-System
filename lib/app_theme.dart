import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core palette - dark with beige/cream reference
  static const Color primaryColor = Color(0xFFEFD5C3); // Beige/cream
  static const Color secondaryColor = Color(0xFFC8BFF0); // Pastel purple
  static const Color accentColor = Color(0xFFD0D0D0); // Light stone grey
  static const Color backgroundColor = Color(0xFF000000); // Pure pitch black
  static const Color surfaceColor = Color(0xFF111111); // True dark neutral
  static const Color cardColor = Color(0xFF1E1E1E); // Standard neutral card
  static const Color cardBorderColor =
      Color(0xFF333333); // Subtle neutral border

  // Confidence colours
  static const Color highConfidence = Color(0xFFA5CFA8); // Pastel green
  static const Color mediumConfidence = Color(0xFFE8C288); // Pastel amber
  static const Color lowConfidence = Color(0xFFE89288); // Pastel red

  static Color confidenceColor(double c) {
    if (c >= 0.8) return highConfidence;
    if (c >= 0.55) return mediumConfidence;
    return lowConfidence;
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: Color(0xFFE89288),
        onPrimary: Colors.black87,
        onSecondary: Colors.black87,
        onSurface: Color(0xFFEAEAEA),
        outline: cardBorderColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: cardBorderColor,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFFCDC8C3),
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -0.2),
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: cardBorderColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF908D8A)),
        hintStyle: const TextStyle(color: Color(0xFF6B6966)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: primaryColor,
        labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
        secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
        side: const BorderSide(color: cardBorderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black87,
        elevation: 4,
      ),
    );
  }
}
