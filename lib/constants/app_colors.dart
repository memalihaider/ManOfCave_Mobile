import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryDark = Color(0xFF1A1A1A);
  static const Color primaryGold = Color(0xFF695A2D);
  static const Color white = Color(0xFFFFFFFF);

  // Secondary Colors
  static const Color secondaryGold = Color(0xFF5A4A20);
  static const Color darkGold = Color(0xFF4A3A18);
  static Color grey=Colors.grey.shade700;

  // Background & Surface
  static const Color backgroundBlack = Color(0xFF1A1A1A);
  static const Color backgroundWhite = Colors.white;
  /// Soft app canvas — less “website white”, more native mobile.
  static const Color scaffoldSoft = Color(0xFFF6F5F3);
  static const Color surfaceMuted = Color(0xFFEEEBE6);
  static const Color surface = Color(0xFF242424);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  static const Color textMuted = Color(0xFF8A8580);
  static const Color textInk = Color(0xFF1C1917);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textHint = Color(0xFF888888);
  static const Color textDisabled = Color(0xFF666666);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Border Colors
  static const Color border = Color(0xFF3A3A3A);
  static const Color borderGold = Color(0xFF695A2D);

  // Gradient Colors
  static const Gradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF695A2D), Color(0xFF5A4A20)],
  );

  static const Gradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xFF151515)],
  );

  static const Gradient radialBackground = RadialGradient(
    center: Alignment.center,
    radius: 1.5,
    colors: [Color(0xFF1A1A1A), Color(0xFF151515)],
    stops: [0.3, 1.0],
  );
}