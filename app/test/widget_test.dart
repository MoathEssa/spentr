import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spentr/app.dart';
import 'package:spentr/core/theme/app_colors.dart';
import 'package:spentr/data/models/app_settings.dart';
import 'package:spentr/ui/screens/sign_in_screen.dart';
import 'fake_shift_repository.dart';
import 'memory_settings_store.dart';
import 'sign_in_helpers.dart';

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

    await signIn(tester);
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
    await signIn(tester);

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

  testWidgets('sign in and sign up reject missing or invalid input',
      (tester) async {
    await tester.pumpWidget(SpentrApp(
      shiftRepository: FakeShiftRepository(),
      settingsStore: MemorySettingsStore(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(find.text('Welcome to Spentr'), findsOneWidget);

    await tester.enterText(find.byKey(SignInScreen.emailFieldKey), 'not-email');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email, such as name@example.com.'),
        findsOneWidget);

    await tester.tap(find.text('New to Spentr? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(SignInScreen.emailFieldKey), 'me@example.com');
    await tester.enterText(find.byKey(SignInScreen.passwordFieldKey), 'short');
    await tester.enterText(find.byKey(SignInScreen.confirmFieldKey), 'other');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(find.text('Create your account'), findsOneWidget);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('Finish shift saves the timed shift and opens its details',
      (tester) async {
    final repo = FakeShiftRepository();
    await tester.pumpWidget(SpentrApp(
      shiftRepository: repo,
      settingsStore: MemorySettingsStore(),
    ));
    await tester.pumpAndSettle();
    await signIn(tester);

    await tester.tap(find.text('Start shift'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Finish shift'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Finish & save shift'));
    await tester.pumpAndSettle();

    expect(repo.records, hasLength(1));
    expect(find.text('Shift details'), findsOneWidget);
    expect(find.text('No shift selected. Open a saved shift from History.'),
        findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Your time, valued.'), findsOneWidget);
    await tester.tap(find.widgetWithText(NavigationDestination, 'History'));
    await tester.pumpAndSettle();
    expect(find.text('Untitled shift'), findsOneWidget);
  });
}
