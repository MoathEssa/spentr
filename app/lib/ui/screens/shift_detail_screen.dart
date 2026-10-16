import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/placeholder_view.dart';

/// One shift: date, times, duration, earnings, tags, note and link.
class ShiftDetailScreen extends StatelessWidget {
  const ShiftDetailScreen({super.key});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this shift?',
      message: 'This will also remove it after cloud sync.',
      confirmLabel: 'Delete shift',
      cancelLabel: 'Go back',
      destructive: true,
    );
    if (confirmed && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shift details')),
      body: PlaceholderView(
        purpose: 'Date, start and end time, paused time, duration, earnings, '
            'client / project, note and reference link for one shift.',
        states: const ['Default', 'Shift saved', 'Delete confirmation'],
        actions: [
          PlaceholderAction(
              'Edit shift',
              Icons.edit,
              () => Navigator.pushNamed(context, AppRoutes.shiftForm,
                  arguments: true),
              primary: true),
          PlaceholderAction(
              'Delete shift', Icons.delete_outline, () => _delete(context)),
        ],
      ),
    );
  }
}
