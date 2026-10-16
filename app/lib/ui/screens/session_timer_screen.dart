import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/placeholder_view.dart';

/// Runs and controls one shift. Pause/continue only toggles a label here;
/// the real timer arrives with SessionProvider in Phase 3.
class SessionTimerScreen extends StatefulWidget {
  const SessionTimerScreen({super.key});

  @override
  State<SessionTimerScreen> createState() => _SessionTimerScreenState();
}

class _SessionTimerScreenState extends State<SessionTimerScreen> {
  bool _paused = false;

  Future<void> _finish() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Ready to finish?',
      message: 'Save this shift to your history.',
      confirmLabel: 'Finish & save shift',
      cancelLabel: 'Keep tracking',
    );
    if (confirmed && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.shiftDetail);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancel this shift?',
      message: 'This tracked time will be discarded. '
          'Your other shifts will stay saved.',
      confirmLabel: 'Discard shift',
      cancelLabel: 'Keep tracking',
      destructive: true,
    );
    if (confirmed && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Current shift')),
      body: PlaceholderView(
        purpose: 'Live elapsed time and earnings for the running shift, '
            'with pause, continue, finish and cancel.',
        states: const [
          'Tracking',
          'Paused',
          'Finish confirmation',
          'Cancel confirmation',
        ],
        actions: [
          PlaceholderAction(
            _paused ? 'Continue shift' : 'Pause shift',
            _paused ? Icons.play_arrow : Icons.pause,
            () => setState(() => _paused = !_paused),
            primary: true,
          ),
          PlaceholderAction('Finish shift', Icons.check, _finish),
          PlaceholderAction('Cancel shift', Icons.close, _cancel),
        ],
      ),
    );
  }
}
