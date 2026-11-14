import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/settings_provider.dart';
import '../widgets/hourly_rate_form.dart';

/// Change the hourly rate and currency from Settings.
class RateSettingsScreen extends StatelessWidget {
  const RateSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return PopScope(
      canPop: !settings.isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && context.mounted) {
          context.read<SettingsProvider>().clearError();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Rate & currency')),
        body: HourlyRateForm(
          initialRate: settings.hourlyRate,
          initialCurrency: settings.currencyCode,
          previewHeading: 'Earnings preview',
          previewDuration: const Duration(hours: 2, minutes: 30),
          previewText: (money) => '2h 30m = $money',
          footnote: 'This rate is used to calculate your earnings.',
          submitLabel: 'Save settings',
          saving: settings.isSaving,
          saveError: settings.errorMessage,
          onSubmit: (rate, currency) async {
            final navigator = Navigator.of(context);
            final saved = await context.read<SettingsProvider>().saveRate(
                  hourlyRate: rate,
                  currencyCode: currency,
                );
            if (!context.mounted || !saved) return;
            navigator.pop();
          },
        ),
      ),
    );
  }
}
