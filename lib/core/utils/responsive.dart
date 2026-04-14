import 'package:flutter/material.dart';

class Responsive {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double responsivePadding(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) return 12;
    if (width < 400) return 16;
    if (width < 600) return 20;
    if (width < 900) return 32;
    return 48;
  }

  static double responsiveFontSize(
    BuildContext context, {
    required double min,
    required double max,
  }) {
    final width = screenWidth(context);
    if (width < 360) return min;
    if (width > 600) return max;
    return min + (max - min) * ((width - 360) / (600 - 360));
  }

  static double responsiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}
