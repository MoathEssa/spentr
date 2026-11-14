import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spentr/app.dart';
import 'package:spentr/core/dashboard_summary.dart';
import 'package:spentr/core/shift_query.dart';
import 'package:spentr/data/models/app_settings.dart';
import 'package:spentr/data/models/shift.dart';

import 'fake_shift_repository.dart';
import 'memory_settings_store.dart';

/// A shift that starts at [start] (local time) and is worked for [worked].
Shift shiftAt(
  DateTime start,
  Duration worked, {
  String note = '',
  List<String> tags = const [],
  bool isDeleted = false,
}) =>
    Shift(
      start: start,
      end: start.add(worked),
      durationMs: worked.inMilliseconds,
      note: note,
      tags: tags,
      updatedAt: start,
      isDeleted: isDeleted,
    );

final _sample = [
  shiftAt(DateTime(2026, 11, 3, 9), const Duration(hours: 2),
      note: 'Website redesign', tags: const ['Acme']),
  shiftAt(DateTime(2026, 11, 10, 13), const Duration(hours: 5),
      note: 'API bug fixes', tags: const ['Globex']),
  shiftAt(DateTime(2026, 10, 28, 8), const Duration(minutes: 45),
      note: 'Client call about the website', tags: const ['Acme', 'Calls']),
  shiftAt(DateTime(2026, 11, 12, 9), const Duration(hours: 9),
      note: 'Deleted record', isDeleted: true),
];

List<String> notes(List<Shift> shifts) => [for (final s in shifts) s.note];

void main() {
  group('history search, filter and sort', () {
    test('default filter lists active shifts newest first', () {
      expect(notes(const ShiftFilter().apply(_sample)), [
        'API bug fixes',
        'Website redesign',
        'Client call about the website',
      ]);
    });

    test('note search is case-insensitive and ignores surrounding spaces', () {
      expect(notes(const ShiftFilter(query: '  WEBSITE ').apply(_sample)), [
        'Website redesign',
        'Client call about the website',
      ]);
      expect(const ShiftFilter(query: 'nothing like this').apply(_sample),
          isEmpty);
    });

    test('date range includes both end days', () {
      final filter = ShiftFilter(
          range: DayRange(DateTime(2026, 11, 3), DateTime(2026, 11, 10)));
      expect(
          notes(filter.apply(_sample)), ['API bug fixes', 'Website redesign']);
    });

    test('tag filter keeps shifts with any selected tag', () {
      expect(notes(const ShiftFilter(tags: {'Calls'}).apply(_sample)),
          ['Client call about the website']);
      expect(
          const ShiftFilter(tags: {'Acme', 'Globex'}).apply(_sample).length, 3);
    });

    test('search, range and tag combine', () {
      final filter = ShiftFilter(
        query: 'website',
        tags: const {'Acme'},
        range: DayRange(DateTime(2026, 11, 1), DateTime(2026, 11, 30)),
      );
      expect(notes(filter.apply(_sample)), ['Website redesign']);
    });

    test('sorts by date, duration and earnings', () {
      expect(notes(const ShiftFilter(sort: ShiftSort.oldest).apply(_sample)), [
        'Client call about the website',
        'Website redesign',
        'API bug fixes',
      ]);
      expect(notes(const ShiftFilter(sort: ShiftSort.longest).apply(_sample)), [
        'API bug fixes',
        'Website redesign',
        'Client call about the website',
      ]);
      expect(
          notes(const ShiftFilter(sort: ShiftSort.highestEarnings)
              .apply(_sample, hourlyRate: 50)),
          [
            'API bug fixes',
            'Website redesign',
            'Client call about the website',
          ]);
    });

    test('tags are listed once, sorted, without deleted shifts', () {
      expect(allTags(_sample), ['Acme', 'Calls', 'Globex']);
    });

    test('filter count and reset keep the search text', () {
      final filter = ShiftFilter(
        query: 'api',
        tags: const {'Acme', 'Globex'},
        range: DayRange(DateTime(2026, 11, 1), DateTime(2026, 11, 2)),
        sort: ShiftSort.longest,
      );
      expect(filter.activeFilterCount, 3);
      final reset = filter.withoutFilters();
      expect(reset.query, 'api');
      expect(reset.sort, ShiftSort.longest);
      expect(reset.activeFilterCount, 0);
    });
  });

  group('dashboard totals', () {
    test('period hours use the Monday week and skip deleted shifts', () {
      final now = DateTime(2026, 11, 12, 18); // Thursday
      final hours = periodHours(shifts: _sample, now: now);
      expect(hours.today, Duration.zero); // the 12th's shift was deleted
      expect(hours.week, const Duration(hours: 5)); // Mon 9th – Sun 15th
      expect(hours.month, const Duration(hours: 7));
      expect(hours.allTime, const Duration(hours: 7, minutes: 45));
    });

    test('daily totals cover one month and add shifts on the same day', () {
      final shifts = [
        ..._sample,
        shiftAt(DateTime(2026, 11, 3, 15), const Duration(minutes: 30)),
      ];
      final totals = dailyTotals(shifts, DateTime(2026, 11));
      expect(
          totals.keys.toSet(), {DateTime(2026, 11, 3), DateTime(2026, 11, 10)});
      final third = totals[DateTime(2026, 11, 3)]!;
      expect(third.shiftCount, 2);
      expect(third.worked, const Duration(hours: 2, minutes: 30));
      expect(third.earnings(40), 100);
    });

    test('shifts on a day are newest first', () {
      final shifts = [
        shiftAt(DateTime(2026, 11, 3, 8), const Duration(hours: 1), note: 'a'),
        shiftAt(DateTime(2026, 11, 3, 17), const Duration(hours: 1), note: 'b'),
        shiftAt(DateTime(2026, 11, 4, 9), const Duration(hours: 1), note: 'c'),
      ];
      expect(notes(shiftsOnDay(shifts, DateTime(2026, 11, 3))), ['b', 'a']);
    });
  });

  group('history and dashboard screens', () {
    Future<FakeShiftRepository> pumpApp(WidgetTester tester,
        {double rate = 50}) async {
      final repo = FakeShiftRepository();
      final today = DateTime.now();
      final day = DateTime(today.year, today.month, today.day, 9);
      await repo.insert(shiftAt(day, const Duration(hours: 2),
          note: 'Website redesign', tags: const ['Acme']));
      await repo.insert(shiftAt(
          day.subtract(const Duration(days: 40)), const Duration(hours: 4),
          note: 'API bug fixes', tags: const ['Globex']));
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(SpentrApp(
        shiftRepository: repo,
        settingsStore: MemorySettingsStore(
            AppSettings(hourlyRate: rate, currencyCode: 'SAR')),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      return repo;
    }

    Future<void> openHistory(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(NavigationDestination, 'History'));
      await tester.pumpAndSettle();
    }

    String summary(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('history-summary'))).data!;

    testWidgets('search narrows the list and no-results can be cleared',
        (tester) async {
      await pumpApp(tester);
      await openHistory(tester);
      expect(summary(tester), '2 shifts · 6h 0m · SAR 300.00');

      await tester.enterText(find.byKey(const Key('history-search')), 'api');
      await tester.pumpAndSettle();
      expect(find.text('API bug fixes'), findsOneWidget);
      expect(find.text('Website redesign'), findsNothing);
      expect(summary(tester), '1 shift · 4h 0m · SAR 200.00');

      await tester.enterText(
          find.byKey(const Key('history-search')), 'no such note');
      await tester.pumpAndSettle();
      expect(find.text('No shifts match'), findsOneWidget);

      await tester.tap(find.text('Clear search & filters'));
      await tester.pumpAndSettle();
      expect(find.text('No shifts match'), findsNothing);
      expect(summary(tester), '2 shifts · 6h 0m · SAR 300.00');
    });

    testWidgets('filter sheet applies a tag and a sort order', (tester) async {
      await pumpApp(tester);
      await openHistory(tester);

      await tester.tap(find.byTooltip('Filter shifts'));
      await tester.pumpAndSettle();
      expect(find.text('Filter shifts'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Globex'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();
      expect(find.text('API bug fixes'), findsOneWidget);
      expect(find.text('Website redesign'), findsNothing);
      expect(find.widgetWithText(InputChip, 'Globex'), findsOneWidget);

      // Removing the chip brings every shift back.
      await tester.tap(find.descendant(
          of: find.widgetWithText(InputChip, 'Globex'),
          matching: find.byIcon(Icons.clear)));
      await tester.pumpAndSettle();
      expect(find.text('Website redesign'), findsOneWidget);

      await tester.tap(find.byTooltip('Filter shifts'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Longest duration'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();
      final longest = tester.getTopLeft(find.text('API bug fixes')).dy;
      final shorter = tester.getTopLeft(find.text('Website redesign')).dy;
      expect(longest, lessThan(shorter));
    });

    testWidgets('dashboard reads saved shifts and opens a calendar day',
        (tester) async {
      await pumpApp(tester);
      expect(tester.widget<Text>(find.byKey(const Key('earnings-today'))).data,
          'SAR 100.00');
      expect(tester.widget<Text>(find.byKey(const Key('earnings-all'))).data,
          'SAR 300.00');
      expect(find.text('Website redesign'), findsOneWidget); // recent shifts

      final today = DateTime.now().day;
      await tester.ensureVisible(find.byKey(Key('calendar-day-$today')));
      await tester.tap(find.byKey(Key('calendar-day-$today')));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.byKey(const Key('day-summary'))).data,
          '1 shift · 2h 0m · SAR 100.00');

      await tester.tap(find.text('Website redesign').last);
      await tester.pumpAndSettle();
      expect(find.text('Shift details'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Your time, valued.'), findsOneWidget);
    });

    testWidgets('a shift added from History updates the dashboard',
        (tester) async {
      final repo = await pumpApp(tester);
      await openHistory(tester);
      await tester.tap(find.text('Add manual shift'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Note (optional)'), 'Fresh entry');
      await tester.ensureVisible(find.text('Save shift'));
      await tester.tap(find.text('Save shift'));
      await tester.pumpAndSettle();
      expect(repo.records, hasLength(3));
      expect(find.text('Fresh entry'), findsOneWidget);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
      await tester.pumpAndSettle();
      expect(find.text('Fresh entry'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('earnings-all'))).data,
          'SAR 350.00');
    });
  });
}
