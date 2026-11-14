import '../data/models/shift.dart';

/// Earnings for the local day, week (Monday start), month, and all time.
///
/// Totals are derived from each shift's worked duration and the current
/// hourly rate. They are not stored on the shift.
class PeriodEarnings {
  const PeriodEarnings({
    required this.today,
    required this.week,
    required this.month,
    required this.allTime,
  });

  final double today;
  final double week;
  final double month;
  final double allTime;
}

PeriodEarnings periodEarnings({
  required Iterable<Shift> shifts,
  required double hourlyRate,
  required DateTime now,
}) {
  final today = _dateOnly(now);
  final weekStart =
      today.subtract(Duration(days: today.weekday - DateTime.monday));
  final monthStart = DateTime(today.year, today.month);
  var todayTotal = 0.0;
  var weekTotal = 0.0;
  var monthTotal = 0.0;
  var allTotal = 0.0;
  for (final shift in shifts) {
    if (shift.isDeleted) continue;
    final amount = shift.earnings(hourlyRate);
    allTotal += amount;
    final start = _dateOnly(shift.start);
    if (!start.isBefore(today) && start.isBefore(_nextDay(today))) {
      todayTotal += amount;
    }
    if (!start.isBefore(weekStart) && start.isBefore(_nextDay(weekStart, 7))) {
      weekTotal += amount;
    }
    if (!start.isBefore(monthStart) &&
        start.isBefore(DateTime(monthStart.year, monthStart.month + 1))) {
      monthTotal += amount;
    }
  }
  return PeriodEarnings(
    today: todayTotal,
    week: weekTotal,
    month: monthTotal,
    allTime: allTotal,
  );
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime _nextDay(DateTime day, [int days = 1]) =>
    day.add(Duration(days: days));
