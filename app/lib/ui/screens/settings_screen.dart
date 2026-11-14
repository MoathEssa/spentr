import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/money.dart';
import '../../core/routes.dart';
import '../../state/settings_provider.dart';
import '../widgets/confirm_dialog.dart';

/// Settings tab: saved rate, and the screens owned by other members.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'You will return to the sign-in screen.',
      confirmLabel: 'Sign out',
      cancelLabel: 'Cancel',
    );
    if (!confirmed || !context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signIn, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final rateLabel = settings.hasRate
        ? '${formatMoney(settings.hourlyRate, settings.currencyCode)} / hour'
        : 'Not set';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Make Spentr work for you.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          if (settings.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                settings.errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Hourly rate & currency'),
            subtitle: Text(rateLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.rateSettings),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Export & import (O2)'),
            subtitle: const Text('Optional'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.export),
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('App lock (O2)'),
            subtitle: const Text('Optional'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoutes.lock),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
