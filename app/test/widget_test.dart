import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spentr/app.dart';

void main() {
  testWidgets('starts on Sign in and reaches every tab', (tester) async {
    await tester.pumpWidget(const SpentrApp());
    expect(find.text('Welcome to Spentr'), findsOneWidget);

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
    await tester.pumpWidget(const SpentrApp());
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start shift'));
    await tester.pumpAndSettle();
    expect(find.text('Current shift'), findsOneWidget);

    await tester.tap(find.text('Cancel shift'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard shift'));
    await tester.pumpAndSettle();
    expect(find.text('Your time, valued.'), findsOneWidget);
  });
}
