import 'package:flutter/material.dart';

class AppColors {
  // Brand / Theme Colors
  static const Color primary = Color(0xFF6558A5);
  static const Color primaryDark = Color(0xFF4C457A);
  static const Color primaryLight = Color(0xFFC4BCE6);
  static const Color primaryLightest = Color(0xFFEBE8F6);

  // Gradient Colors for Auth Screens
  static const Color gradientStart = Color(0xFF8672C8);
  static const Color gradientEnd = Color(0xFFD4C9F7);
  static const Color authBgTop = Color(0xFF1A1245);
  static const Color authBgBottom = Color(0xFFD5CDF3);

  // Status & Feedback Colors
  // Error
  static const Color error = Color(0xFFC53030);
  static const Color errorBg = Color(0xFFFDE8E8);
  static const Color errorMain = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFF9B1C1C);
  static const Color errorLight = Color(0xFFFFE0E0);

  // Success
  static const Color success = Color(0xFF10B981); // Emerald Green modern
  static const Color successBg = Color(0xFFDEF7EC);
  static const Color successMain = Color(0xFF22C55E);
  static const Color successDark = Color(0xFF059669);
  static const Color successDarkest = Color(0xFF03543F);
  static const Color successLight = Color(0xFFD1FAE5);

  // Warning
  static const Color warning = Color(0xFFD97706);
  static const Color warningMain = Color(0xFFD4AA70);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF8B6914);

  // Layout & Neutral Colors
  static const Color darkSurface = Color(0xFFAEE2FF);
  static const Color surfaceLight = Color(0xFFF3F1FA);
  static const Color surfaceLightest = Color(0xFFF9F7FD);
  static const Color backgroundDefault = Color(0xFFFCFAFF);

  // Core Neutrals
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
  static const Color greyLightest = Color(0xFFEDE9F6);

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
