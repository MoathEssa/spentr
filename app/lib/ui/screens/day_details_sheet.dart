import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/dashboard_summary.dart';
import '../../core/date_labels.dart';
import '../../core/money.dart';
import '../../core/routes.dart';
import '../../core/shift_formatters.dart';
import '../../data/models/shift.dart';
import '../../state/settings_provider.dart';
import '../../state/shift_provider.dart';
import '../widgets/shift_tile.dart';

/// Bottom sheet opened from a calendar day on Home: that day's total and
/// shifts, read live from [ShiftProvider].
Future<void> showDayDetailsSheet(BuildContext context, DateTime day) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _DayDetails(day: day),
  );
}

class _DayDetails extends StatelessWidget {
  const _DayDetails({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShiftProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final shifts = shiftsOnDay(store.shifts, day);
    final worked =
        shifts.fold(Duration.zero, (sum, shift) => sum + shift.duration);
    final summary = [
      '${shifts.length} ${shifts.length == 1 ? 'shift' : 'shifts'}',
      shiftDuration(worked),
      if (settings.hasRate)
        formatMoney(
            Shift.earningsFor(worked.inMilliseconds, settings.hourlyRate),
            settings.currencyCode),
    ].join(' · ');

    void closeSheet() => Navigator.pop(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(dayLabel(day), style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(summary,
                key: const Key('day-summary'),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            if (shifts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No shifts on this day.'),
              )
            else
              for (final shift in shifts)
                ShiftTile(
                  shift: shift,
                  settings: settings,
                  showDate: false,
                  onOpen: closeSheet,
                ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                final navigator = Navigator.of(context);
                closeSheet();
                navigator.pushNamed(AppRoutes.shiftForm, arguments: day);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add a shift for this day'),
            ),
          ],
        ),
      ),
    );
  }
}
