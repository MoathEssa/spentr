import 'package:flutter/material.dart';

import '../widgets/placeholder_view.dart';

/// Change the hourly rate and currency from Settings.
class RateSettingsScreen extends StatelessWidget {
  const RateSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate & currency')),
      body: PlaceholderView(
        purpose: 'Hourly rate and currency, with an earnings preview.',
        states: const ['Default', 'Invalid rate', 'Saved'],
        actions: [
          PlaceholderAction('Save settings', Icons.save_outlined,
              () => Navigator.pop(context),
              primary: true),
        ],
      ),
    );
  }
}
