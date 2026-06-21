import 'package:flutter/material.dart';

class AppColors {
  // Brand / Theme Colors
  static const Color primary = Color(0xFFAEE2FF); // Light blue
  static const Color secondary = Color(0xFF64B5F6); // Medium blue
  static const Color secondaryLight = Color(0xFF90CAF9); // Light blue
  static const Color accentGreen = Color(0xFFD9F9DF); // Light green

  static const Color primaryDark = Color(
    0xFF1E88E5,
  ); // Darker blue for text/icons on white bg
  static const Color primaryLight = Color(0xFFBBDEFB); // Light blue
  static const Color primaryLightest = Color(0xFFE3F2FD); // Lightest blue

  // Gradient Colors for Auth Screens
  static const Color authBgTop = Color(0xFFAEE2FF);
  static const Color authBgBottom = Color(0xFF1E88E5); // Blue gradient bottom

  // Status & Feedback Colors
  // Error
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFDE8E8);
  static const Color errorDark = Color(0xFF9B1C1C);

  // Success
  static const Color success = Color(0xFF10B981); // Emerald Green modern
  static const Color successBg = Color(0xFFDEF7EC);
  static const Color successDark = Color(0xFF059669);

  // Warning
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF8B6914);

  // Layout & Neutral Colors
  static const Color darkSurface = Color(0xFFAEE2FF);
  static const Color surfaceLight = Color(0xFFF3F8FF); // Light blue tint
  static const Color surfaceLightest = Color(0xFFF9FBFF); // Lightest blue tint
  static const Color backgroundDefault = Color(0xFFFCFAFF);

  // Text & Core Neutrals
  static const Color textPrimary = Color(
    0xFF1E293B,
  ); // Dark slate for high contrast on light blue
  static const Color textSecondary = Color(0xFF64748B); // Lighter slate

  static const Color white = Color(0xFFFFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);

  static const Color black = Color(0xFF000000);
  static const Color black12 = Color(0x1F000000);
  static const Color black26 = Color(0x42000000);
  static const Color black38 = Color(0x61000000);
  static const Color black45 = Color(0x73000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black87 = Color(0xDD000000);

  static const Color transparent = Color(0x00000000);

  static const Color grey = Color(0xFF9E9E9E);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey600 = Color(0xFF757575);
  static const Color greyLightest = Color(0xFFF5F9FF);

  // Legacy/Fallback colors mapped
  static const Color red = Color(0xFFF44336);
  static const Color deepPurple = Color(0xFF673AB7);
  static const Color purpleAccent = Color(0xFFE040FB);

  // Gradients
  static const LinearGradient authBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [authBgTop, authBgBottom],
  );

  static LinearGradient splashOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [black.withValues(alpha: 0.15), black.withValues(alpha: 0.35)],
  );
}
