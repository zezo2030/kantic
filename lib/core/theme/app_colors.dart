import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Orange-to-Red Gradient Theme
  static const Color primaryOrange = Color(0xFFFF8A00); // Bright orange
  static const Color primaryRed = Color(0xFFFF5E00); // Orange-red (Primary)
  static const Color deepRed = Color(0xFFE10000); // Deep red
  static const Color darkRed = Color(0xFFB30000); // Dark red
  static const Color primaryPink = Color(
    0xFFFFCDD2,
  ); // Keeping as a tint if needed
  static const Color lightRed = Color(0xFFFFEBEE); // Light tint
  static const Color accentRed = Color(0xFFEF5350); // Red 400

  // Luxury Colors - Red Theme
  static const Color luxuryGold = Color(0xFFFFB74D); // Amber 300
  static const Color luxuryRoseGold = Color(0xFFF8BBD9); // Light Pink 200
  static const Color luxuryDeepRed = Color(0xFFB71C1C); // Red 900
  static const Color luxuryPlatinum = Color(0xFFF5F5F5); // Grey 100
  static const Color luxuryCharcoal = Color(0xFF424242); // Grey 800
  static const Color luxurySilver = Color(0xFFE0E0E0); // Grey 300

  // Premium Gradients - Orange-to-Red Theme (Matching Map/Branches Toggle)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryOrange, primaryRed, deepRed, darkRed],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightRed, primaryRed],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, accentRed],
  );

  // Luxury Gradients - Red Theme
  static const LinearGradient luxuryGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [luxuryGold, Color(0xFFFF8A65)],
  );

  static const LinearGradient luxuryRoseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [luxuryRoseGold, primaryPink],
  );

  static const LinearGradient luxuryRedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryOrange, primaryRed, deepRed, darkRed],
    stops: [0.0, 0.3, 0.6, 1.0],
  );

  static const LinearGradient luxuryPlatinumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [luxuryPlatinum, Color(0xFFEEEEEE)],
  );

  static const LinearGradient luxuryCharcoalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [luxuryCharcoal, Color(0xFF616161)],
  );

  // Glass Effect Colors
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBlack = Color(0x1A000000);
  static const Color glassPrimary = Color(0x1AE57373);
  static const Color glassGold = Color(0x1AFFB74D);

  // Status Colors (using red theme)
  static const Color successColor = Color(0xFF66BB6A); // Light Green 400
  static const Color errorColor = Color(0xFFE57373); // Light Red 300
  static const Color warningColor = Color(0xFFFFB74D); // Amber 300
  static const Color infoColor = Color(0xFF42A5F5); // Blue 400

  // Status Colors with Red Theme
  static const Color availableColor = Color(
    0xFF66BB6A,
  ); // Light Green for available
  static const Color maintenanceColor = Color(
    0xFFFFB74D,
  ); // Amber for maintenance
  static const Color reservedColor = Color(
    0xFFE57373,
  ); // Light Red for reserved
  static const Color closedColor = Color(0xFFD32F2F); // Red for closed

  // Language Indicator Colors
  static const Color arabicColor = Color(0xFFE57373); // Light Red for Arabic
  static const Color englishColor = Color(0xFFF8BBD9); // Light Pink for English

  // Rating Colors
  static const Color starColor = Color(0xFFFFB74D); // Amber for stars
  static const Color starEmptyColor = Color(
    0xFFE0E0E0,
  ); // Light grey for empty stars

  // Neutral Colors
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyMedium = Color(0xFF9E9E9E);
  static const Color greyDark = Color(0xFF424242);

  // Background Colors
  static const Color backgroundColor = Color(0xFFFEFEFE);
  static const Color surfaceColor = Color(0xFFFFFFFF);

  // Luxury Background Colors
  static const Color luxuryBackground = Color(0xFFFEFEFE);
  static const Color luxurySurface = Color(0xFFFFFFFF);
  static const Color luxurySurfaceVariant = Color(0xFFF8F8F8);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Luxury Text Colors
  static const Color luxuryTextPrimary = Color(0xFF2C2C2C);
  static const Color luxuryTextSecondary = Color(0xFF6B6B6B);
  static const Color luxuryTextHint = Color(0xFFB0B0B0);
  static const Color luxuryTextGold = Color(0xFFE65100);

  // Shadow Colors
  static const Color shadowColor = Color(0x1A000000);
  static const Color shadowColorLight = Color(0x0D000000);

  // Luxury Shadow Colors
  static const Color luxuryShadowLight = Color(0x0A000000);
  static const Color luxuryShadowMedium = Color(0x15000000);
  static const Color luxuryShadowDark = Color(0x20000000);
  static const Color luxuryShadowGold = Color(0x20FFB74D);

  // Glow Colors
  static const Color glowPrimary = Color(0x40E57373);
  static const Color glowGold = Color(0x40FFB74D);
  static const Color glowPink = Color(0x40F8BBD9);
  static const Color glowRed = Color(0x40D32F2F);

  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);
  static const Color borderDark = Color(0xFF757575);

  // Luxury Border Colors
  static const Color luxuryBorderLight = Color(0xFFF0F0F0);
  static const Color luxuryBorderGold = Color(0xFFFFB74D);
  static const Color luxuryBorderRose = Color(0xFFF8BBD9);
}
