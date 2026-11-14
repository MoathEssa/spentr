import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentr/app.dart';
import 'package:spentr/core/money.dart';
import 'package:spentr/core/period_earnings.dart';
import 'package:spentr/data/local/settings_store.dart';
import 'package:spentr/data/models/active_session.dart';
import 'package:spentr/data/models/app_settings.dart';
import 'package:spentr/data/models/shift.dart';
import 'package:spentr/state/settings_provider.dart';
import 'package:spentr/state/shift_provider.dart';
import 'package:spentr/ui/screens/session_timer_screen.dart';
import 'package:spentr/ui/widgets/hourly_rate_form.dart';

import 'fake_shift_repository.dart';
import 'memory_settings_store.dart';

Shift workedShift({
  required DateTime start,
  required Duration window,
  required Duration worked,
  String note = 'Shift',
  bool isDeleted = false,
}) {
  return Shift(
    start: start,
    end: start.add(window),
    durationMs: worked.inMilliseconds,
    note: note,
    updatedAt: start,
    isDeleted: isDeleted,
  );
}

void main() {
  group('rate input and money format', () {
    test('rejects missing, invalid, and non-positive rates', () {
      expect(RateInput.validate(null), 'Enter your hourly rate.');
      expect(RateInput.validate('   '), 'Enter your hourly rate.');
      expect(RateInput.validate('0'), 'Hourly rate must be greater than zero.');
      expect(
        RateInput.validate('0.00'),
        'Hourly rate must be greater than zero.',
      );
      expect(
          RateInput.validate('-5'), 'Hourly rate must be greater than zero.');
      expect(
        RateInput.validate('abc'),
        'Enter a valid hourly rate, such as 75.00.',
      );
      expect(
        RateInput.validate('75.555'),
        'Enter a valid hourly rate, such as 75.00.',
      );
      expect(
        RateInput.validate('75.'),
        'Enter a valid hourly rate, such as 75.00.',
      );
      expect(
        RateInput.validate('75,00'),
        'Enter a valid hourly rate, such as 75.00.',
      );
      expect(RateInput.tryParse('abc'), isNull);
    });

    test('accepts a positive rate with at most two decimals', () {
      expect(RateInput.validate('75'), isNull);
      expect(RateInput.validate('75.5'), isNull);
      expect(RateInput.validate(' 75.50 '), isNull);
      expect(RateInput.tryParse('75.50'), 75.5);
      expect(RateInput.tryParse('0.01'), 0.01);
    });

    test('formats every amount as currency code, grouping, and two decimals',
        () {
      expect(formatMoney(0, 'SAR'), 'SAR 0.00');
      expect(formatMoney(37.5, 'SAR'), 'SAR 37.50');
      expect(formatMoney(150, 'SAR'), 'SAR 150.00');
      expect(formatMoney(4725, 'SAR'), 'SAR 4,725.00');
      expect(formatMoney(1234567.8, 'USD'), 'USD 1,234,567.80');
      expect(formatMoney(double.nan, 'SAR'), 'SAR —');
    });
  });

  group('earnings math', () {
    test('uses worked milliseconds and excludes paused time', () {
      expect(Shift.earningsFor(Duration.millisecondsPerHour, 75), 75);
      expect(Shift.earningsFor(const Duration(minutes: 30).inMilliseconds, 75),
          37.5);
      expect(Shift.earningsFor(const Duration(minutes: 90).inMilliseconds, 80),
          120);
      expect(Shift.earningsFor(0, 75), 0);
      expect(Shift.earningsFor(1, 3600000), closeTo(1, 0.000000001));

      final start = DateTime(2026, 11, 14, 9);
      final shift = workedShift(
        start: start,
        window: const Duration(hours: 3),
        worked: const Duration(hours: 2, minutes: 30),
      );
      shift.validate();
      expect(shift.paused, const Duration(minutes: 30));
      expect(shift.earnings(75), 187.5);
      expect(shift.toMap().keys, isNot(contains('earnings')));
    });

    test('zero-duration work inside a longer window earns nothing', () {
      final start = DateTime(2026, 11, 14, 9);
      final shift = workedShift(
        start: start,
        window: const Duration(minutes: 20),
        worked: Duration.zero,
      );
      shift.validate();
      expect(shift.earnings(75), 0);
    });

    test('elapsed session time comes from timestamps', () {
      final start = DateTime(2026, 11, 14, 9);
      final running = ActiveSession(
        start: start,
        status: SessionStatus.running,
        segmentStart: start,
      );
      final later = start.add(const Duration(minutes: 30));
      expect(running.workedAt(later), const Duration(minutes: 30));
      final paused = ActiveSession(
        start: start,
        status: SessionStatus.paused,
        accumulatedMs: const Duration(minutes: 30).inMilliseconds,
      );
      expect(
        paused.workedAt(start.add(const Duration(hours: 3))),
        const Duration(minutes: 30),
      );
      expect(
        Shift.earningsFor(
          paused.workedAt(start.add(const Duration(hours: 3))).inMilliseconds,
          75,
        ),
        37.5,
      );
    });
  });

  group('period totals', () {
    test('day, week, month, and all-time use saved worked time', () {
      final saturday = DateTime(2026, 11, 14, 15);
      expect(saturday.weekday, DateTime.saturday);
      final shifts = [
        workedShift(
          start: saturday,
          window: const Duration(hours: 2),
          worked: const Duration(hours: 1),
        ),
        workedShift(
          start: DateTime(2026, 11, 9, 9),
          window: const Duration(hours: 3),
          worked: const Duration(hours: 2),
        ),
        workedShift(
          start: DateTime(2026, 11, 1, 9),
          window: const Duration(hours: 4),
          worked: const Duration(hours: 3),
        ),
        workedShift(
          start: DateTime(2026, 11, 8, 23),
          window: const Duration(hours: 2),
          worked: const Duration(hours: 1),
        ),
        workedShift(
          start: DateTime(2026, 11, 16),
          window: const Duration(hours: 6),
          worked: const Duration(hours: 5),
        ),
        workedShift(
          start: DateTime(2026, 10, 31, 12),
          window: const Duration(hours: 5),
          worked: const Duration(hours: 4),
        ),
        workedShift(
          start: saturday,
          window: const Duration(hours: 6),
          worked: const Duration(hours: 5),
          isDeleted: true,
        ),
        workedShift(
          start: saturday,
          window: const Duration(minutes: 15),
          worked: Duration.zero,
        ),
      ];

      final totals = periodEarnings(
        shifts: shifts,
        hourlyRate: 10,
        now: saturday,
      );
      expect(totals.today, 10);
      expect(totals.week, 30);
      expect(totals.month, 120);
      expect(totals.allTime, 160);
    });

    test('December totals stop at the next month', () {
      final now = DateTime(2026, 12, 31, 18);
      final totals = periodEarnings(
        shifts: [
          workedShift(
            start: DateTime(2026, 12, 31, 9),
            window: const Duration(hours: 2),
            worked: const Duration(hours: 1),
          ),
          workedShift(
            start: DateTime(2027, 1, 1, 9),
            window: const Duration(hours: 2),
            worked: const Duration(hours: 1),
          ),
        ],
        hourlyRate: 10,
        now: now,
      );
      expect(totals.today, 10);
      expect(totals.month, 10);
      expect(totals.allTime, 20);
    });

    test('editing and deleting shifts changes totals without storing money',
        () async {
      final repo = FakeShiftRepository();
      final store = ShiftProvider(repo);
      final start = DateTime(2026, 11, 14, 9);
      final saved = (await store.save(workedShift(
        start: start,
        window: const Duration(hours: 3),
        worked: const Duration(hours: 2, minutes: 30),
        note: 'Website redesign',
      )))!;
      final stored = Map<String, Object?>.from(repo.records.single.toMap());
      expect(saved.earnings(75), 187.5);
      expect(saved.earnings(100), 250);
      expect(repo.records.single.toMap(), stored);

      await store.save(saved.copyWith(
        durationMs: const Duration(hours: 1).inMilliseconds,
      ));
      expect(store.shifts.single.earnings(75), 75);
      expect(store.shifts.single.note, 'Website redesign');
      expect(
        periodEarnings(shifts: store.shifts, hourlyRate: 75, now: start)
            .allTime,
        75,
      );

      expect(await store.delete(saved.id!), isTrue);
      expect(store.shifts, isEmpty);
      expect(
        periodEarnings(shifts: store.shifts, hourlyRate: 75, now: start)
            .allTime,
        0,
      );
      expect(repo.records.single.isDeleted, isTrue);
      expect(repo.records.single.note, 'Website redesign');
      store.dispose();
    });
  });

  group('settings persistence', () {
    test('a new provider reads the rate saved by the previous one', () async {
      final store = MemorySettingsStore(const AppSettings(
        hourlyRate: 10,
        currencyCode: 'EUR',
        themeMode: ThemeMode.dark,
        notificationsEnabled: false,
        appLockEnabled: true,
      ));
      final first = SettingsProvider(store);
      await first.load();
      expect(
        await first.saveRate(hourlyRate: 12, currencyCode: 'USD'),
        isTrue,
      );
      first.dispose();

      final second = SettingsProvider(store);
      await second.load();
      expect(second.hourlyRate, 12);
      expect(second.currencyCode, 'USD');
      expect(second.themeMode, ThemeMode.dark);
      expect(second.settings.notificationsEnabled, isFalse);
      expect(second.settings.appLockEnabled, isTrue);
      expect(second.hasRate, isTrue);
      second.dispose();
    });

    test('invalid rates and failed writes leave the saved rate in place',
        () async {
      final store = MemorySettingsStore(
        const AppSettings(hourlyRate: 10, currencyCode: 'SAR'),
      );
      final provider = SettingsProvider(store);
      await provider.load();
      expect(
          await provider.saveRate(hourlyRate: 0, currencyCode: 'SAR'), isFalse);
      expect(
        await provider.saveRate(hourlyRate: -3, currencyCode: 'SAR'),
        isFalse,
      );
      expect(
        await provider.saveRate(
          hourlyRate: double.nan,
          currencyCode: 'SAR',
        ),
        isFalse,
      );
      expect(
        await provider.saveRate(hourlyRate: 15, currencyCode: 'XXX'),
        isFalse,
      );
      expect(provider.hourlyRate, 10);
      expect(store.saves, 0);

      store.failSaves = true;
      expect(
        await provider.saveRate(hourlyRate: 20, currencyCode: 'USD'),
        isFalse,
      );
      expect(provider.hourlyRate, 10);
      expect(provider.currencyCode, 'SAR');
      expect(
          provider.errorMessage, 'Could not save your settings. Please retry.');
      provider.dispose();
    });

    test('a failed load keeps defaults and can be reported', () async {
      final store = MemorySettingsStore()..failLoads = true;
      final provider = SettingsProvider(store);
      await provider.load();
      expect(provider.isLoaded, isTrue);
      expect(provider.hasRate, isFalse);
      expect(provider.errorMessage, 'Could not load saved settings.');
      provider.dispose();
    });

    test('shared preferences keeps the rate when the provider is recreated',
        () async {
      SharedPreferences.setMockInitialValues({});
      final first = SettingsProvider(SharedPreferencesSettingsStore());
      await first.load();
      expect(first.hasRate, isFalse);
      expect(
        await first.saveRate(hourlyRate: 10.25, currencyCode: 'GBP'),
        isTrue,
      );
      first.dispose();

      final second = SettingsProvider(SharedPreferencesSettingsStore());
      await second.load();
      expect(second.hourlyRate.toStringAsFixed(2), '10.25');
      expect(second.currencyCode, 'GBP');
      expect(second.themeMode, ThemeMode.system);
      second.dispose();
    });
  });

  group('rate screens', () {
    testWidgets('back returns to create account and an empty rate is rejected',
        (tester) async {
      await tester.pumpWidget(SpentrApp(
        shiftRepository: FakeShiftRepository(),
        settingsStore: MemorySettingsStore(),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New to Spentr? Create an account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Set your hourly rate'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Create your account'), findsOneWidget);

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start using Spentr'));
      await tester.tap(find.text('Start using Spentr'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your hourly rate.'), findsOneWidget);
      expect(find.text('Your time, valued.'), findsNothing);

      await tester.enterText(find.byKey(HourlyRateForm.rateFieldKey), '0');
      await tester.ensureVisible(find.text('Start using Spentr'));
      await tester.tap(find.text('Start using Spentr'));
      await tester.pumpAndSettle();
      expect(find.text('Hourly rate must be greater than zero.'), findsWidgets);
      expect(find.text('Set your hourly rate'), findsOneWidget);
    });

    testWidgets('setup saves the rate and settings edits it', (tester) async {
      await tester.pumpWidget(SpentrApp(
        shiftRepository: FakeShiftRepository(),
        settingsStore: MemorySettingsStore(),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New to Spentr? Create an account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(HourlyRateForm.rateFieldKey), '75');
      await tester.pump();
      expect(find.text('2 hours of work = SAR 150.00'), findsOneWidget);

      await tester.tap(find.byKey(HourlyRateForm.currencyMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD · US Dollar').last);
      await tester.pumpAndSettle();
      expect(find.text('2 hours of work = USD 150.00'), findsOneWidget);

      await tester.ensureVisible(find.text('Start using Spentr'));
      await tester.tap(find.text('Start using Spentr'));
      await tester.pumpAndSettle();
      expect(find.text('Your time, valued.'), findsOneWidget);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
      await tester.pumpAndSettle();
      expect(find.text('USD 75.00 / hour'), findsOneWidget);

      await tester.tap(find.text('Hourly rate & currency'));
      await tester.pumpAndSettle();
      expect(find.text('2h 30m = USD 187.50'), findsOneWidget);
      await tester.enterText(find.byKey(HourlyRateForm.rateFieldKey), '0');
      await tester.ensureVisible(find.text('Save settings'));
      await tester.tap(find.text('Save settings'));
      await tester.pumpAndSettle();
      expect(find.text('Rate & currency'), findsOneWidget);
      expect(find.text('Hourly rate must be greater than zero.'), findsWidgets);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('USD 75.00 / hour'), findsOneWidget);

      await tester.tap(find.text('Hourly rate & currency'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(HourlyRateForm.rateFieldKey), '80');
      await tester.pump();
      expect(find.text('2h 30m = USD 200.00'), findsOneWidget);
      await tester.ensureVisible(find.text('Save settings'));
      await tester.tap(find.text('Save settings'));
      await tester.pumpAndSettle();
      expect(find.text('USD 80.00 / hour'), findsOneWidget);
      expect(find.text('Rate & currency'), findsNothing);
    });
  });

  group('shift earnings on screen', () {
    testWidgets('saved shifts show earnings that follow the current rate',
        (tester) async {
      final repo = FakeShiftRepository();
      final start = DateTime.now();
      await repo.insert(workedShift(
        start: start,
        window: const Duration(hours: 2),
        worked: const Duration(minutes: 90),
        note: 'Partial hour',
      ));
      final before = Map<String, Object?>.from(repo.records.single.toMap());
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(SpentrApp(
        shiftRepository: repo,
        settingsStore: MemorySettingsStore(
          const AppSettings(hourlyRate: 10, currencyCode: 'SAR'),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      // Period totals are on the Home dashboard.
      expect(
        tester.widget<Text>(find.byKey(const Key('earnings-today'))).data,
        'SAR 15.00',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('earnings-week'))).data,
        'SAR 15.00',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('earnings-month'))).data,
        'SAR 15.00',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('earnings-all'))).data,
        'SAR 15.00',
      );

      await tester.tap(find.text('Partial hour'));
      await tester.pumpAndSettle();
      expect(find.text('SAR 15.00 · SAR 10.00 / hour'), findsOneWidget);
      expect(find.text('0h 30m'), findsOneWidget);

      await tester.ensureVisible(find.text('Edit shift'));
      await tester.tap(find.text('Edit shift'));
      await tester.pumpAndSettle();
      expect(find.text('1h 30m × SAR 10.00 = SAR 15.00'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hourly rate & currency'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(HourlyRateForm.rateFieldKey), '20');
      await tester.ensureVisible(find.text('Save settings'));
      await tester.tap(find.text('Save settings'));
      await tester.pumpAndSettle();
      expect(repo.records.single.toMap(), before);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('earnings-all'))).data,
        'SAR 30.00',
      );

      await tester.tap(find.widgetWithText(NavigationDestination, 'History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Partial hour'));
      await tester.pumpAndSettle();
      expect(find.text('SAR 30.00 · SAR 20.00 / hour'), findsOneWidget);
      await tester.ensureVisible(find.text('Delete shift'));
      await tester.tap(find.text('Delete shift'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete shift'));
      await tester.pumpAndSettle();
      expect(find.text('No shifts yet. Add your first shift.'), findsOneWidget);
      expect(repo.records.single.isDeleted, isTrue);
      await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('earnings-all'))).data,
        'SAR 0.00',
      );
    });

    testWidgets('shifts do not show money before a rate is saved',
        (tester) async {
      final repo = FakeShiftRepository();
      final start = DateTime.now();
      await repo.insert(workedShift(
        start: start,
        window: const Duration(hours: 1),
        worked: const Duration(hours: 1),
        note: 'Unpriced',
      ));
      await tester.pumpWidget(SpentrApp(
        shiftRepository: repo,
        settingsStore: MemorySettingsStore(),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(
        find.text('Set an hourly rate in Settings to see totals.'),
        findsOneWidget,
      );
      expect(find.textContaining('SAR'), findsNothing);
      await tester.tap(find.widgetWithText(NavigationDestination, 'History'));
      await tester.pumpAndSettle();
      expect(find.text('Rate not set'), findsOneWidget);
      expect(find.textContaining('SAR'), findsNothing);
    });
  });

  group('timer earnings', () {
    testWidgets('the clock and earnings follow timestamps, including pause',
        (tester) async {
      final start = DateTime(2026, 11, 14, 9);
      var now = start;
      final settings = SettingsProvider(MemorySettingsStore(
        const AppSettings(hourlyRate: 75, currencyCode: 'SAR'),
      ));
      await settings.load();
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: MaterialApp(
            home: SessionTimerScreen(
              now: () => now,
              initialSession: ActiveSession(
                start: start,
                status: SessionStatus.running,
                segmentStart: start,
              ),
            ),
          ),
        ),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });
      expect(find.text('Tracking'), findsOneWidget);
      expect(find.text('00:00:00'), findsOneWidget);
      expect(find.text('SAR 0.00'), findsOneWidget);

      now = start.add(const Duration(minutes: 30));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:30:00'), findsOneWidget);
      expect(find.text('SAR 37.50'), findsOneWidget);

      await tester.tap(find.text('Pause shift'));
      await tester.pump();
      now = start.add(const Duration(hours: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('Continue shift'), findsOneWidget);
      expect(find.text('00:30:00'), findsOneWidget);
      expect(find.text('SAR 37.50'), findsOneWidget);

      now = start.add(const Duration(hours: 2));
      await tester.tap(find.text('Continue shift'));
      await tester.pump();
      now = start.add(const Duration(hours: 2, minutes: 15));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:45:00'), findsOneWidget);
      expect(find.text('SAR 56.25'), findsOneWidget);
      expect(find.text('Tracking'), findsOneWidget);
    });

    testWidgets('timer without a rate shows the duration and asks for a rate',
        (tester) async {
      final start = DateTime(2026, 11, 14, 9);
      final settings = SettingsProvider(MemorySettingsStore());
      await settings.load();
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: MaterialApp(
            home: SessionTimerScreen(
              enableTicker: false,
              now: () => start.add(const Duration(minutes: 10)),
              initialSession: ActiveSession(
                start: start,
                status: SessionStatus.running,
                segmentStart: start,
              ),
            ),
          ),
        ),
      );
      expect(find.text('00:10:00'), findsOneWidget);
      expect(
        find.text('Set an hourly rate in Settings to see earnings.'),
        findsOneWidget,
      );
      expect(find.textContaining('SAR'), findsNothing);
    });
  });
}
