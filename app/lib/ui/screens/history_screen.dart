import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../widgets/placeholder_view.dart';
import 'filter_sheet.dart';

/// History tab: every shift grouped by month, with search, filter and sort.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shift history')),
      body: PlaceholderView(
        purpose: 'All shifts grouped by month, with text search over notes, '
            'a filter by date and tag, and sorting.',
        states: const ['Loaded', 'No matching shifts', 'Empty'],
        actions: [
          PlaceholderAction('Add manual shift', Icons.add,
              () => Navigator.pushNamed(context, AppRoutes.shiftForm),
              primary: true),
          PlaceholderAction('Open a shift', Icons.receipt_long,
              () => Navigator.pushNamed(context, AppRoutes.shiftDetail)),
          PlaceholderAction(
              'Filter shifts', Icons.tune, () => showFilterSheet(context)),
        ],
      ),
    );
  }
}
