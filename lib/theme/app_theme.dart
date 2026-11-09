import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme Colors
  static const Color bgPrimaryLight = Color(0xFFFFFFFF);       // Pure Crisp White
  static const Color surfaceCardLight = Color(0xFFFFF0F2);     // Soft Blush Pink (#FFF0F2)
  
  // Dark Theme Colors (Celestial Navy)
  static const Color bgPrimaryDark = Color(0xFF0B132B);        // Celestial Navy
  static const Color surfaceCardDark = Color(0xFF1C2541);      // Deep Slate Navy Card

  // Shared Brand Accents
  static const Color shiningRed = Color(0xFFD90429);          // Radiant Ruby / Crimson Red
  static const Color primaryRed = Color(0xFFEF233C);          // Vivid Crimson Highlight
  static const Color goldAccent = Color(0xFFB8860B);          // Dark Warm Gold (#B8860B)
  static const Color goldSecondary = Color(0xFFC5A059);       // Warm Champagne Gold
  static const Color polishedGold = Color(0xFFFFD700);        // Polished Metallic Gold (#FFD700)
  static const Color cyanSecondary = Color(0xFFD90429);       // Active Red Highlight Accent
  
  // Text Colors
  static const Color textDark = Color(0xFF000000);            // Pure High-Contrast Deep Black (#000000)
  static const Color textLight = Color(0xFFFFFFFF);           // High-Contrast Pure White (Dark Theme)
  static const Color textMuted = Color(0xFF222222);           // Solid Charcoal (#222222) Subtitles & Captions
  static const Color textMutedDark = Color(0xFFE0E0E0);       // High-Contrast Light Silver Subtitles & Captions
  static const Color statusGreen = Color(0xFF2ECC71);         // Live Status Green
  static const Color errorRed = Color(0xFFD90429);            // Alert Crimson Red


  // Backward compatibility getters
  static Color get bgPrimary => bgPrimaryLight;
  static Color get surfaceCard => surfaceCardLight;

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgPrimaryLight,
      primaryColor: shiningRed,
      colorScheme: const ColorScheme.light(
        primary: shiningRed,
        secondary: goldAccent,
        surface: surfaceCardLight,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: textDark,
        onSurface: textDark,
      ),
      cardTheme: CardThemeData(
        color: surfaceCardLight,
        elevation: 0,
        shadowColor: shiningRed.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
          side: BorderSide(color: goldAccent.withValues(alpha: 0.35), width: 1.2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cinzel(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: goldAccent),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgPrimaryLight,
        selectedItemColor: shiningRed,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cinzel(color: goldAccent, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.cinzel(color: textDark, fontSize: 22, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.inter(color: textDark, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: textDark, fontSize: 15, fontWeight: FontWeight.normal),
        bodyMedium: GoogleFonts.inter(color: textMuted, fontSize: 13),
        labelLarge: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimaryDark,
      primaryColor: shiningRed,
      colorScheme: const ColorScheme.dark(
        primary: shiningRed,
        secondary: goldAccent,
        surface: surfaceCardDark,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: textLight,
        onSurface: textLight,
      ),
      cardTheme: CardThemeData(
        color: surfaceCardDark,
        elevation: 4,
        shadowColor: Colors.black.withAlpha(80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
          side: BorderSide(color: goldAccent.withAlpha(100), width: 1.0),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cinzel(
          color: goldAccent,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: goldAccent),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgPrimaryDark,
        selectedItemColor: shiningRed,
        unselectedItemColor: textMutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cinzel(color: goldAccent, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.cinzel(color: textLight, fontSize: 22, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.inter(color: textLight, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: textLight, fontSize: 15, fontWeight: FontWeight.normal),
        bodyMedium: GoogleFonts.inter(color: textMutedDark, fontSize: 13),
        labelLarge: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  static TextStyle getScriptTextStyle({
    required bool isTelugu,
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = textDark,
    double height = 1.4,
  }) {
    if (isTelugu) {
      return GoogleFonts.notoSansTelugu(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    }
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}
