import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../widgets/placeholder_view.dart';
import 'day_details_sheet.dart';

/// Home tab: period totals, Start shift, month calendar, recent shifts.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onViewAllShifts});

  /// Switches the shell to the History tab ("View all →").
  final VoidCallback onViewAllShifts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your time, valued.')),
      body: PlaceholderView(
        purpose: 'Totals for today, this week, this month and all time, a '
            'one-tap Start shift button, the month calendar and recent shifts.',
        states: const [
          'Loaded',
          'Shift running',
          'Empty',
          'Loading',
          'Offline',
          'Sync error',
        ],
        actions: [
          PlaceholderAction('Start shift', Icons.play_arrow,
              () => Navigator.pushNamed(context, AppRoutes.timer),
              primary: true),
          PlaceholderAction('Open a calendar day', Icons.calendar_month,
              () => showDayDetailsSheet(context)),
          PlaceholderAction('Open a recent shift', Icons.receipt_long,
              () => Navigator.pushNamed(context, AppRoutes.shiftDetail)),
          PlaceholderAction(
              'View all shifts', Icons.arrow_forward, onViewAllShifts),
        ],
      ),
    );
  }
}
