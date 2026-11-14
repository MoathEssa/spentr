import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes.dart';
import 'core/theme/app_theme.dart';
import 'data/local/settings_store.dart';
import 'data/local/sqlite_shift_repository.dart';
import 'data/repositories/shift_repository.dart';
import 'state/settings_provider.dart';
import 'state/shift_provider.dart';

class SpentrApp extends StatelessWidget {
  const SpentrApp({
    super.key,
    this.shiftRepository,
    this.settingsStore,
    this.settingsProvider,
  });

  // Tests inject an in-memory fake. The actual app defaults to SQLite.
  final ShiftRepository? shiftRepository;

  /// Tests inject an in-memory store. The actual app uses shared_preferences.
  final SettingsStore? settingsStore;

  /// Set when settings were loaded before [runApp].
  final SettingsProvider? settingsProvider;

  @override
  Widget build(BuildContext context) {
    final existingSettings = settingsProvider;
    return MultiProvider(
      providers: [
        if (existingSettings != null)
          ChangeNotifierProvider<SettingsProvider>.value(
            value: existingSettings,
          )
        else
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(
              settingsStore ?? SharedPreferencesSettingsStore(),
            )..load(),
          ),
        ChangeNotifierProvider(
          create: (_) =>
              ShiftProvider(shiftRepository ?? SqliteShiftRepository())..load(),
        ),
      ],
      child: const _ThemedSpentrApp(),
    );
  }
}

class _ThemedSpentrApp extends StatelessWidget {
  const _ThemedSpentrApp();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<SettingsProvider>().themeMode;
    return MaterialApp(
      title: 'Spentr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: AppRoutes.signIn,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
