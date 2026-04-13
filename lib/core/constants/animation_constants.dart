import 'package:flutter/material.dart';

class AnimationConstants {
  // Animation Durations
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration verySlowDuration = Duration(milliseconds: 800);

  // Stagger Animation Delays
  static const Duration staggerDelay = Duration(milliseconds: 100);
  static const Duration staggerDelayLong = Duration(milliseconds: 150);

  // Parallax Animation Settings
  static const double parallaxFactor = 0.5;
  static const double parallaxFactorSlow = 0.3;
  static const double parallaxFactorFast = 0.7;

  // Animation Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;
  static const Curve sharpCurve = Curves.easeInOutCubic;
  static const Curve luxuryCurve = Curves.easeOutQuart;

  // Floating Animation Settings
  static const Duration floatingDuration = Duration(seconds: 2);
  static const double floatingAmplitude = 8.0;
  static const double floatingAmplitudeSmall = 4.0;

  // Pulse Animation Settings
  static const Duration pulseDuration = Duration(milliseconds: 1500);
  static const double pulseScale = 1.05;

  // Glow Animation Settings
  static const Duration glowDuration = Duration(milliseconds: 2000);
  static const double glowIntensity = 0.8;

  // Shimmer Animation Settings
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Duration shimmerDelay = Duration(milliseconds: 500);

  // Counting Animation Settings
  static const Duration countingDuration = Duration(milliseconds: 2000);
  static const Duration countingDelay = Duration(milliseconds: 300);

  // Page Transition Settings
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);
  static const Curve pageTransitionCurve = Curves.easeInOutCubic;

  // Micro-interaction Settings
  static const Duration microInteractionDuration = Duration(milliseconds: 150);
  static const double microInteractionScale = 0.95;

  // Hero Animation Settings
  static const Duration heroDuration = Duration(milliseconds: 600);
  static const Curve heroCurve = Curves.easeInOutCubic;

  // Glass Effect Settings
  static const double glassOpacity = 0.1;
  static const double glassBlur = 10.0;
  static const double glassBorderOpacity = 0.2;

  // 3D Transform Settings
  static const double perspective = 0.001;
  static const double rotationAngle = 0.1;
  static const Duration transformDuration = Duration(milliseconds: 300);

  // Hover Animation Settings
  static const Duration hoverDuration = Duration(milliseconds: 200);
  static const double hoverScale = 1.02;
  static const double hoverElevation = 8.0;

  // Slide Animation Settings
  static const Duration slideDuration = Duration(milliseconds: 400);
  static const Offset slideOffset = Offset(0, 50);

  // Fade Animation Settings
  static const Duration fadeDuration = Duration(milliseconds: 300);
  static const Duration fadeDelay = Duration(milliseconds: 100);

  // Scale Animation Settings
  static const Duration scaleDuration = Duration(milliseconds: 250);
  static const double scaleStart = 0.8;
  static const double scaleEnd = 1.0;

  // Rotation Animation Settings
  static const Duration rotationDuration = Duration(milliseconds: 600);
  static const double rotationAngleSmall = 0.05;
  static const double rotationAngleLarge = 0.2;
}

