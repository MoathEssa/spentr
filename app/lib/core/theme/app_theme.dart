import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Material 3 light and dark themes built from the Figma design system.
///
/// Type scale: Display 36, Title 24, Body 14, Label 12.
/// Main controls are at least 48 px high; radius 12 / 16 / 24.
abstract final class AppTheme {
  static ThemeData get light => _build(
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryContainer,
          secondary: AppColors.primary,
          secondaryContainer: AppColors.accent,
          onSecondaryContainer: AppColors.onSurface,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceMuted,
          outlineVariant: AppColors.outline,
          error: AppColors.error,
        ),
        AppColors.background,
      );

  static ThemeData get dark => _build(
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.darkPrimary,
          onPrimary: AppColors.darkBackground,
          primaryContainer: AppColors.darkSurfaceHigh,
          secondary: AppColors.darkPrimary,
          secondaryContainer: AppColors.accent,
          onSecondaryContainer: AppColors.onSurface,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkOnSurface,
          onSurfaceVariant: AppColors.darkOnSurfaceMuted,
          outlineVariant: AppColors.darkOutline,
          error: AppColors.darkError,
        ),
        AppColors.darkBackground,
      );

  static ThemeData _build(ColorScheme scheme, Color background) {
    const minButtonSize = Size(64, 48);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 14),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: minButtonSize, shape: shape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(minimumSize: minButtonSize, shape: shape),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
