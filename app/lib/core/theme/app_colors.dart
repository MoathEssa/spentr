import 'package:flutter/material.dart';

/// Colours from the Figma design system ("Spentr / Design system").
abstract final class AppColors {
  // Light
  static const primary = Color(0xFF145E4F);
  static const background = Color(0xFFF5F7F3);
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF152E28);
  static const onSurfaceMuted = Color(0xFF536A61);
  static const primaryContainer = Color(0xFFD8ECE1);
  static const outline = Color(0xFFDCE5DF);
  static const accent = Color(0xFFDDF29C);
  static const error = Color(0xFFA82E31);

  // Dark
  static const darkPrimary = Color(0xFF8CCFB1);
  static const darkBackground = Color(0xFF10251F);
  static const darkSurface = Color(0xFF19362D);
  static const darkSurfaceHigh = Color(0xFF244C3B);
  static const darkOnSurface = Color(0xFFEEF5F0);
  static const darkOnSurfaceMuted = Color(0xFFB8CCC0);
  static const darkOutline = Color(0xFF365348);
  static const darkError = Color(0xFFFFB4AB);
}
