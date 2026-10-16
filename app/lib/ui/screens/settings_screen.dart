import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../widgets/placeholder_view.dart';

/// Settings tab: account, rate, appearance, notifications, sync, export, lock.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: PlaceholderView(
        purpose: 'Account, hourly rate and currency, appearance, shift '
            'notifications, cloud sync status, export and app lock.',
        states: const ['Default', 'Synced', 'Sync error'],
        actions: [
          PlaceholderAction('Hourly rate & currency', Icons.payments_outlined,
              () => Navigator.pushNamed(context, AppRoutes.rateSettings)),
          PlaceholderAction('Export & import (O2)', Icons.ios_share,
              () => Navigator.pushNamed(context, AppRoutes.export)),
          PlaceholderAction('App lock (O2)', Icons.fingerprint,
              () => Navigator.pushNamed(context, AppRoutes.lock)),
          PlaceholderAction(
              'Sign out',
              Icons.logout,
              () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.signIn, (_) => false)),
        ],
      ),
    );
  }
}
