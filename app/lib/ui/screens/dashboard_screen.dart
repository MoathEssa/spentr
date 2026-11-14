import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/dashboard_summary.dart';
import '../../core/date_labels.dart';
import '../../core/money.dart';
import '../../core/period_earnings.dart';
import '../../core/routes.dart';
import '../../core/shift_formatters.dart';
import '../../core/shift_query.dart';
import '../../data/models/shift.dart';
import '../../state/settings_provider.dart';
import '../../state/shift_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/shift_tile.dart';
import 'day_details_sheet.dart';

/// Home tab (E4): period totals in hours and money, Start shift, the month
/// calendar with each worked day's earnings, and recent shifts.
///
/// Everything is derived from the saved shifts in [ShiftProvider] and the
/// rate in [SettingsProvider], so saving, editing or deleting a shift, or
/// changing the rate, updates this screen immediately. The month being shown
/// is local `setState`, as planned in Phase 2.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onViewAllShifts, this.now});

  /// Switches the shell to the History tab ("View all").
  final VoidCallback onViewAllShifts;

  /// Overridable clock for tests.
  final DateTime Function()? now;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _recentCount = 5;
  late DateTime _month = _monthOf(_now());

  DateTime _now() => (widget.now ?? DateTime.now)();
  static DateTime _monthOf(DateTime value) => DateTime(value.year, value.month);

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShiftProvider>();
    final settings = context.watch<SettingsProvider>();
    final now = _now();
    final shifts = store.shifts;
    final firstLoad = store.isLoading && shifts.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Your time, valued.')),
      body: RefreshIndicator(
        onRefresh: store.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (store.hasLoadError)
              _LoadErrorCard(
                message: store.errorMessage ?? 'Could not load saved shifts.',
                onRetry: store.isLoading ? null : store.load,
              ),
            if (firstLoad)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _PeriodTotals(
                hours: periodHours(shifts: shifts, now: now),
                money: settings.hasRate
                    ? periodEarnings(
                        shifts: shifts,
                        hourlyRate: settings.hourlyRate,
                        now: now)
                    : null,
                settings: settings,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.timer),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start shift'),
              ),
              const SizedBox(height: 16),
              _MonthCalendar(
                month: _month,
                today: dateOnly(now),
                totals: dailyTotals(shifts, _month),
                settings: settings,
                onPrevious: () => _shiftMonth(-1),
                onNext: () => _shiftMonth(1),
                onDayTap: (day) => showDayDetailsSheet(context, day),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Text('Recent shifts',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: widget.onViewAllShifts,
                  child: const Text('View all'),
                ),
              ]),
              if (shifts.isEmpty)
                EmptyState(
                  icon: Icons.work_history_outlined,
                  title: 'No shifts recorded yet',
                  message: 'Start a shift, or add one you worked earlier.',
                  actionLabel: 'Add manual shift',
                  onAction: () =>
                      Navigator.pushNamed(context, AppRoutes.shiftForm),
                )
              else
                for (final shift in shifts.take(_recentCount))
                  ShiftTile(shift: shift, settings: settings),
            ],
          ],
        ),
      ),
    );
  }
}

/// This month as the headline, then today, this week and all time.
/// Hours are always shown; money only once a rate is saved.
class _PeriodTotals extends StatelessWidget {
  const _PeriodTotals({
    required this.hours,
    required this.money,
    required this.settings,
  });

  final PeriodHours hours;
  final PeriodEarnings? money;
  final SettingsProvider settings;

  String _money(double value) => formatMoney(value, settings.currencyCode);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = this.money;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        color: scheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THIS MONTH',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onPrimaryContainer, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              if (money != null)
                Text(_money(money.month),
                    key: const Key('earnings-month'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600)),
              Text(
                money == null
                    ? shiftDuration(hours.month)
                    : '${shiftDuration(hours.month)} worked'
                        ' · ${_money(settings.hourlyRate)} / hour',
                key: const Key('hours-month'),
                style: (money == null
                        ? theme.textTheme.headlineMedium
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(color: scheme.onPrimaryContainer),
              ),
              if (money == null) ...[
                const SizedBox(height: 8),
                Text('Set an hourly rate in Settings to see totals.',
                    style: TextStyle(color: scheme.onPrimaryContainer)),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.rateSettings),
                  child: const Text('Set hourly rate'),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        _StatCard(
            label: 'Today',
            hours: hours.today,
            amount: money == null ? null : _money(money.today),
            moneyKey: const Key('earnings-today')),
        const SizedBox(width: 8),
        _StatCard(
            label: 'This week',
            hours: hours.week,
            amount: money == null ? null : _money(money.week),
            moneyKey: const Key('earnings-week')),
        const SizedBox(width: 8),
        _StatCard(
            label: 'All time',
            hours: hours.allTime,
            amount: money == null ? null : _money(money.allTime),
            moneyKey: const Key('earnings-all')),
      ]),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.hours,
    required this.amount,
    required this.moneyKey,
  });

  final String label;
  final Duration hours;
  final String? amount;
  final Key moneyKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(shiftDuration(hours), style: theme.textTheme.titleMedium),
              if (amount != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(amount!,
                      key: moneyKey,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.primary)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Monday-first month grid. Worked days are filled and show that day's
/// earnings (or hours before a rate is set). Tapping a day opens its sheet.
class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.today,
    required this.totals,
    required this.settings,
    required this.onPrevious,
    required this.onNext,
    required this.onDayTap,
  });

  final DateTime month;
  final DateTime today;
  final Map<DateTime, DayTotal> totals;
  final SettingsProvider settings;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = DateTime(month.year, month.month).weekday - 1;
    final monthWorked =
        totals.values.fold(Duration.zero, (sum, day) => sum + day.worked);
    final monthSummary = settings.hasRate
        ? '${shiftDuration(monthWorked)} · ${formatMoney(Shift.earningsFor(monthWorked.inMilliseconds, settings.hourlyRate), settings.currencyCode)}'
        : shiftDuration(monthWorked);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
        child: Column(children: [
          Row(children: [
            IconButton(
                tooltip: 'Previous month',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Column(children: [
                Text(monthLabel(month),
                    key: const Key('calendar-month'),
                    style: theme.textTheme.titleMedium),
                Text(monthSummary,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ]),
            ),
            IconButton(
                tooltip: 'Next month',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            for (final initial in weekdayInitials)
              Expanded(
                child: Center(
                  child: Text(initial,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ),
              ),
          ]),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 0.95,
            children: [
              for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
              for (var d = 1; d <= daysInMonth; d++)
                _DayCell(
                  day: DateTime(month.year, month.month, d),
                  total: totals[DateTime(month.year, month.month, d)],
                  isToday: DateTime(month.year, month.month, d) == today,
                  settings: settings,
                  onTap: onDayTap,
                ),
            ],
          ),
        ]),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.total,
    required this.isToday,
    required this.settings,
    required this.onTap,
  });

  final DateTime day;
  final DayTotal? total;
  final bool isToday;
  final SettingsProvider settings;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = this.total;
    final worked = total != null;
    final caption = !worked
        ? null
        : settings.hasRate
            ? compactAmount(total.earnings(settings.hourlyRate))
            : compactHours(total.worked);
    return Semantics(
      button: true,
      label:
          '${dayLabel(day)}${!worked ? '' : total.shiftCount == 1 ? ', 1 shift' : ', ${total.shiftCount} shifts'}',
      child: Material(
        color: worked ? scheme.primaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isToday
              ? BorderSide(color: scheme.primary, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          key: Key('calendar-day-${day.day}'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTap(day),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${day.day}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: worked || isToday ? FontWeight.w600 : null,
                      color: worked ? scheme.onPrimaryContainer : null)),
              if (caption != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(caption,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.primary, fontSize: 10)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadErrorCard extends StatelessWidget {
  const _LoadErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.error_outline, color: scheme.onErrorContainer),
        title: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
        trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
      ),
    );
  }
}
