import 'package:flutter/material.dart';

import 'core/routes.dart';
import 'core/theme/app_theme.dart';

/// Root widget. Phase 2 starter: theme and placeholder navigation only.
///
/// In Phase 3 a `MultiProvider` (AuthProvider, SettingsProvider,
/// ShiftProvider, SessionProvider) will wrap this widget, and `themeMode`
/// will come from SettingsProvider.
class SpentrApp extends StatelessWidget {
  const SpentrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spentr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.signIn,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
