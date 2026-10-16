import 'package:flutter/material.dart';

import '../widgets/placeholder_view.dart';

/// Statistics tab (optional feature O1).
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your work, in view')),
      body: const PlaceholderView(
        purpose: 'Optional (O1). Totals per period, average, longest and '
            'shortest shift, hours by month and an activity heat map.',
        states: ['Loaded', 'Not enough data'],
      ),
    );
  }
}
