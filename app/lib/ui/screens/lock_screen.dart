import 'package:flutter/material.dart';

import '../widgets/placeholder_view.dart';

/// Biometric unlock (optional feature O2).
class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your time is private')),
      body: PlaceholderView(
        purpose: 'Optional (O2). Unlock Spentr with fingerprint, Face ID or '
            'the device passcode.',
        states: const ['Locked'],
        actions: [
          PlaceholderAction('Unlock with biometrics', Icons.fingerprint,
              () => Navigator.pop(context),
              primary: true),
          PlaceholderAction('Use device passcode', Icons.pin_outlined,
              () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
