import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'MontserratArabic',

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryRed,
        brightness: Brightness.light,
        primary: AppColors.primaryRed,
        secondary: AppColors.luxuryGold,
        tertiary: AppColors.primaryPink,
        surface: AppColors.luxurySurface,
        background: AppColors.luxuryBackground,
        error: AppColors.errorColor,
        onPrimary: Colors.white,
        onSecondary: AppColors.luxuryTextPrimary,
        onTertiary: Colors.white,
        onSurface: AppColors.luxuryTextPrimary,
        onBackground: AppColors.luxuryTextPrimary,
        onError: Colors.white,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.luxurySurface,
        foregroundColor: AppColors.luxuryTextPrimary,
        titleTextStyle: TextStyle(
          fontFamily: 'MontserratArabic',
          color: AppColors.luxuryTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.luxuryShadowMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryRed,
          side: const BorderSide(color: AppColors.luxuryBorderRose, width: 2.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.luxuryTextGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.luxuryBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.luxuryBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        filled: true,
        fillColor: AppColors.luxurySurface,
        hintStyle: const TextStyle(
          fontFamily: 'MontserratArabic',
          color: AppColors.luxuryTextHint,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 8,
        shadowColor: AppColors.luxuryShadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        color: AppColors.luxurySurface,
        margin: EdgeInsets.all(8),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.luxurySurface,
        selectedItemColor: AppColors.luxuryGold,
        unselectedItemColor: AppColors.luxuryTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.luxuryGold,
        foregroundColor: AppColors.luxuryTextPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.luxuryGold,
        linearTrackColor: AppColors.luxurySurfaceVariant,
        circularTrackColor: AppColors.luxurySurfaceVariant,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.luxuryBorderLight,
        thickness: 1,
        space: 1,
      ),

      // Typography Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.luxuryTextPrimary,
          letterSpacing: 0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.luxuryTextPrimary,
          letterSpacing: 0.5,
        ),
        displaySmall: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.luxuryTextPrimary,
          letterSpacing: 0.5,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.luxuryTextPrimary,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.luxuryTextPrimary,
          letterSpacing: 0.5,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.luxuryTextPrimary,
          letterSpacing: 0.5,
        ),
        titleLarge: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.luxuryTextPrimary,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.luxuryTextPrimary,
          letterSpacing: 0.5,
        ),
        titleSmall: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.luxuryTextPrimary,
          letterSpacing: 0.5,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.luxuryTextPrimary,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.luxuryTextSecondary,
          letterSpacing: 0.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.luxuryTextHint,
          letterSpacing: 0.5,
        ),
        labelLarge: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.luxuryTextPrimary,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.luxuryTextSecondary,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.luxuryTextHint,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'MontserratArabic',

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryRed,
        brightness: Brightness.dark,
        primary: AppColors.primaryRed,
        secondary: AppColors.luxuryGold,
        tertiary: AppColors.luxuryRoseGold,
        surface: AppColors.luxuryCharcoal,
        background: const Color(0xFF121212),
        error: AppColors.errorColor,
        onPrimary: Colors.white,
        onSecondary: AppColors.luxuryTextPrimary,
        onTertiary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.luxuryCharcoal,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontFamily: 'MontserratArabic',
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.luxuryShadowMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.luxuryGold,
          side: const BorderSide(color: AppColors.luxuryBorderGold, width: 2.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.luxuryGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'MontserratArabic',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.luxuryBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.luxuryBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        filled: true,
        fillColor: AppColors.luxuryCharcoal,
        hintStyle: const TextStyle(
          fontFamily: 'MontserratArabic',
          color: AppColors.luxuryTextHint,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 8,
        shadowColor: AppColors.luxuryShadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        color: AppColors.luxuryCharcoal,
        margin: EdgeInsets.all(8),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.luxuryCharcoal,
        selectedItemColor: AppColors.luxuryGold,
        unselectedItemColor: AppColors.luxuryTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.luxuryGold,
        foregroundColor: AppColors.luxuryTextPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.luxuryGold,
        linearTrackColor: AppColors.luxuryCharcoal,
        circularTrackColor: AppColors.luxuryCharcoal,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.luxuryBorderLight,
        thickness: 1,
        space: 1,
      ),

      // Typography Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        displaySmall: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        titleLarge: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        titleSmall: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.luxuryTextSecondary,
          letterSpacing: 0.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.luxuryTextHint,
          letterSpacing: 0.5,
        ),
        labelLarge: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.luxuryTextSecondary,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontFamily: 'MontserratArabic',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.luxuryTextHint,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
