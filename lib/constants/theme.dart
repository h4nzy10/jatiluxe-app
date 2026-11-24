import 'package:flutter/material.dart';

class AppColors {
  // Canvases - Warm, organic dark wood obsidian (eliminates sterile flat pitch black)
  static const Color obsidianBlack = Color(0xFF0D0C0A); // Deep warm teak obsidian
  static const Color charcoalVelvet = Color(0xFF171513); // Velvet dark walnut surface
  static const Color surfaceElevated = Color(0xFF201E1A); // Slightly raised card canvas
  static const Color surfaceBorder = Color(0xFF2C2720); // Quiet luxury hairline border

  // Accents - Silky, artisanal brushed champagne & aged teak brass (not brassy/yellow neon)
  static const Color champagneGold = Color(0xFFC5A059); // Primary warm champagne gold
  static const Color champagneGoldLight = Color(0xFFDFBA75); // Luminous gold highlight
  static const Color warmBronze = Color(0xFF8A6C3E); // Aged teak brass / secondary accent
  static const Color bronzeHairline = Color(0xFF3F3526); // Subtle borders and dividers

  // Typography - Warm, natural, and legible
  static const Color ivorySilk = Color(0xFFF7F5EE); // Warm natural ivory
  static const Color ashGrey = Color(0xFF9E978E); // Warm stone/driftwood muted grey
  static const Color ashGreySubtle = Color(0xFF6B655D); // Delicate metadata / placeholder

  // Status Colors - Muted luxury tones
  static const Color success = Color(0xFF5B9279);
  static const Color warning = Color(0xFFD49B48);
  static const Color error = Color(0xFFC25450);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.obsidianBlack,
      primaryColor: AppColors.champagneGold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.champagneGold,
        secondary: AppColors.warmBronze,
        surface: AppColors.charcoalVelvet,
        error: AppColors.error,
        onPrimary: AppColors.obsidianBlack,
        onSecondary: AppColors.ivorySilk,
        onSurface: AppColors.ivorySilk,
        onError: AppColors.ivorySilk,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.obsidianBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.ivorySilk,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        iconTheme: IconThemeData(color: AppColors.champagneGold),
      ),
      cardTheme: CardThemeData(
        color: AppColors.charcoalVelvet,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.champagneGold,
          foregroundColor: AppColors.obsidianBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.charcoalVelvet,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.ashGreySubtle, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.ashGrey, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.champagneGold, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
      ),
    );
  }
}
