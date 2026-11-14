import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes.dart';
import 'core/theme/app_theme.dart';
import 'data/local/sqlite_shift_repository.dart';
import 'data/repositories/shift_repository.dart';
import 'state/shift_provider.dart';

class SpentrApp extends StatelessWidget {
  const SpentrApp({super.key, this.shiftRepository});
  // Tests inject an in-memory fake. The actual app defaults to SQLite.
  final ShiftRepository? shiftRepository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ShiftProvider(shiftRepository ?? SqliteShiftRepository())..load(),
      child: MaterialApp(
        title: 'Spentr',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.signIn,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
