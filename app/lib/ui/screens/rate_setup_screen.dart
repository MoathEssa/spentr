import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../state/settings_provider.dart';
import '../widgets/hourly_rate_form.dart';

/// First-run step after sign-up: hourly rate and currency.
class RateSetupScreen extends StatelessWidget {
  const RateSetupScreen({super.key});

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
        appBar: AppBar(title: const Text('Set your hourly rate')),
        body: HourlyRateForm(
          initialRate: settings.hourlyRate,
          initialCurrency: settings.currencyCode,
          heading: 'Turn your time into earnings.',
          subheading: 'You can change this later in Settings.',
          previewHeading: 'A clear starting point',
          previewDuration: const Duration(hours: 2),
          previewText: (money) => '2 hours of work = $money',
          submitLabel: 'Start using Spentr',
          saving: settings.isSaving,
          saveError: settings.errorMessage,
          onSubmit: (rate, currency) async {
            final navigator = Navigator.of(context);
            final saved = await context.read<SettingsProvider>().saveRate(
                  hourlyRate: rate,
                  currencyCode: currency,
                );
            if (!context.mounted || !saved) return;
            navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
          },
        ),
      ),
    );
  }
}
