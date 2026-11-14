import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/money.dart';
import '../../core/period_earnings.dart';
import '../../core/routes.dart';
import '../../core/shift_formatters.dart';
import '../../data/models/shift.dart';
import '../../state/settings_provider.dart';
import '../../state/shift_provider.dart';

/// Basic records list for E2. Person 3 can add E5 search/filter/sort here.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShiftProvider>();
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Shift history'), actions: [
        IconButton(
            tooltip: 'Reload shifts',
            onPressed: store.isLoading || store.isSaving ? null : store.load,
            icon: const Icon(Icons.refresh)),
      ]),
      body: Column(children: [
        if (store.isLoading) const LinearProgressIndicator(),
        if (store.errorMessage != null)
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text(store.errorMessage!),
                TextButton(
                    onPressed:
                        store.isLoading || store.isSaving ? null : store.load,
                    child: const Text('Retry'))
              ])),
        Expanded(
            child: store.shifts.isEmpty
                ? Center(
                    child: Text(store.isLoading
                        ? 'Loading saved shifts...'
                        : store.errorMessage != null
                            ? 'Saved shifts are unavailable.'
                            : 'No shifts yet. Add your first shift.'))
                : RefreshIndicator(
                    onRefresh: store.load,
                    child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: store.shifts.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _EarningsTotals(
                              shifts: store.shifts,
                              settings: settings,
                            );
                          }
                          final shift = store.shifts[index - 1];
                          final money = settings.hasRate
                              ? formatMoney(
                                  shift.earnings(settings.hourlyRate),
                                  settings.currencyCode,
                                )
                              : 'Rate not set';
                          return Card(
                              child: ListTile(
                            title: Text(shift.note.isEmpty
                                ? 'Untitled shift'
                                : shift.note),
                            subtitle: Text(
                                '${shiftDateTime(shift.start)}\n${shift.tags.join(' / ')}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(shiftDuration(shift.duration)),
                                const SizedBox(height: 4),
                                Text(money),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.shiftDetail,
                                arguments: shift.id),
                          ));
                        }))),
      ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: store.isLoading || store.isSaving
              ? null
              : () => Navigator.pushNamed(context, AppRoutes.shiftForm),
          icon: const Icon(Icons.add),
          label: const Text('Add manual shift')),
    );
  }
}

class _EarningsTotals extends StatelessWidget {
  const _EarningsTotals({required this.shifts, required this.settings});

  final List<Shift> shifts;
  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    if (!settings.hasRate) {
      return const Card(
        child: ListTile(
          title: Text('Earnings'),
          subtitle: Text('Set an hourly rate in Settings to see totals.'),
        ),
      );
    }
    final totals = periodEarnings(
      shifts: shifts,
      hourlyRate: settings.hourlyRate,
      now: DateTime.now(),
    );
    final currency = settings.currencyCode;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'At ${formatMoney(settings.hourlyRate, currency)} / hour',
              ),
            ),
            const SizedBox(height: 8),
            _row('Today', totals.today, currency, const Key('earnings-today')),
            _row(
                'This week', totals.week, currency, const Key('earnings-week')),
            _row('This month', totals.month, currency,
                const Key('earnings-month')),
            _row('All time', totals.allTime, currency,
                const Key('earnings-all')),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double amount, String currency, Key key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(formatMoney(amount, currency), key: key),
        ],
      ),
    );
  }
}
