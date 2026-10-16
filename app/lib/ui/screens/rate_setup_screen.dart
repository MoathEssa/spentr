import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../widgets/placeholder_view.dart';

/// First-run step after sign-up: hourly rate and currency.
class RateSetupScreen extends StatelessWidget {
  const RateSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set your hourly rate')),
      body: PlaceholderView(
        purpose: 'Set the hourly rate and currency used to turn time into '
            'earnings. Can be changed later in Settings.',
        states: const ['Default', 'Invalid rate', 'Earnings preview'],
        actions: [
          PlaceholderAction(
            'Start using Spentr',
            Icons.arrow_forward,
            () => Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.home, (_) => false),
            primary: true,
          ),
        ],
      ),
    );
  }
}
