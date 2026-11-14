import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spentr/app.dart';
import 'package:spentr/core/theme/app_colors.dart';
import 'package:spentr/data/models/app_settings.dart';
import 'fake_shift_repository.dart';
import 'memory_settings_store.dart';

void main() {
  testWidgets('starts on Sign in and reaches every tab', (tester) async {
    await tester.pumpWidget(SpentrApp(
      shiftRepository: FakeShiftRepository(),
      settingsStore: MemorySettingsStore(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Spentr'), findsOneWidget);
    final theme = Theme.of(tester.element(find.text('Welcome to Spentr')));
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.brightness, Brightness.light);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Your time, valued.'), findsOneWidget);

    for (final tab in ['History', 'Statistics', 'Settings']) {
      await tester.tap(find.widgetWithText(NavigationDestination, tab));
      await tester.pumpAndSettle();
    }
    expect(find.text('Hourly rate & currency'), findsOneWidget);
  });

  testWidgets('Start shift opens the timer and Cancel returns home',
      (tester) async {
    await tester.pumpWidget(SpentrApp(
      shiftRepository: FakeShiftRepository(),
      settingsStore: MemorySettingsStore(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start shift'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Current shift'), findsOneWidget);
    expect(find.text('Tracking'), findsOneWidget);

    await tester.tap(find.text('Cancel shift'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Discard shift'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Your time, valued.'), findsOneWidget);
  });

  testWidgets('a saved dark theme is applied at startup', (tester) async {
    await tester.pumpWidget(SpentrApp(
      shiftRepository: FakeShiftRepository(),
      settingsStore: MemorySettingsStore(
        const AppSettings(themeMode: ThemeMode.dark),
      ),
    ));
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.text('Welcome to Spentr')));
    expect(theme.brightness, Brightness.dark);
    expect(theme.useMaterial3, isTrue);
  });
}
