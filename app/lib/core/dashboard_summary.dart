import '../data/models/shift.dart';
import 'shift_query.dart';

/// Worked time and shift count for one local calendar day.
class DayTotal {
  const DayTotal({this.worked = Duration.zero, this.shiftCount = 0});

  final Duration worked;
  final int shiftCount;

  double earnings(double hourlyRate) =>
      Shift.earningsFor(worked.inMilliseconds, hourlyRate);

  DayTotal add(Shift shift) => DayTotal(
        worked: worked + shift.duration,
        shiftCount: shiftCount + 1,
      );
}

/// Worked hours for the local day, week (Monday start), month and all time.
///
/// Uses the same period rules as `periodEarnings`, so the hours and the money
/// shown side by side on the dashboard always describe the same shifts.
class PeriodHours {
  const PeriodHours({
    required this.today,
    required this.week,
    required this.month,
    required this.allTime,
  });

  final Duration today;
  final Duration week;
  final Duration month;
  final Duration allTime;
}

PeriodHours periodHours({
  required Iterable<Shift> shifts,
  required DateTime now,
}) {
  final today = dateOnly(now);
  final weekStart =
      today.subtract(Duration(days: today.weekday - DateTime.monday));
  final weekEnd = weekStart.add(const Duration(days: 7));
  final monthStart = DateTime(today.year, today.month);
  final monthEnd = DateTime(today.year, today.month + 1);
  var day = Duration.zero;
  var week = Duration.zero;
  var month = Duration.zero;
  var all = Duration.zero;
  for (final shift in shifts) {
    if (shift.isDeleted) continue;
    final worked = shift.duration;
    final start = dateOnly(shift.start);
    all += worked;
    if (start == today) day += worked;
    if (!start.isBefore(weekStart) && start.isBefore(weekEnd)) week += worked;
    if (!start.isBefore(monthStart) && start.isBefore(monthEnd)) {
      month += worked;
    }
  }
  return PeriodHours(today: day, week: week, month: month, allTime: all);
}

/// Totals keyed by local date, for the days of [month] only.
/// A shift belongs to the day it started on.
Map<DateTime, DayTotal> dailyTotals(Iterable<Shift> shifts, DateTime month) {
  final totals = <DateTime, DayTotal>{};
  for (final shift in shifts) {
    if (shift.isDeleted) continue;
    final day = dateOnly(shift.start);
    if (day.year != month.year || day.month != month.month) continue;
    totals[day] = (totals[day] ?? const DayTotal()).add(shift);
  }
  return totals;
}

/// Shifts that started on [day] (local), newest first.
List<Shift> shiftsOnDay(Iterable<Shift> shifts, DateTime day) {
  final target = dateOnly(day);
  return shifts
      .where((s) => !s.isDeleted && dateOnly(s.start) == target)
      .toList()
    ..sort((a, b) => b.start.compareTo(a.start));
}
