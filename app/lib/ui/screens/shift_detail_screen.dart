import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../core/shift_formatters.dart';
import '../../state/shift_provider.dart';
import '../widgets/confirm_dialog.dart';

class ShiftDetailScreen extends StatelessWidget {
  const ShiftDetailScreen({super.key, this.shiftId});
  final int? shiftId;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showConfirmDialog(context,
        title: 'Delete this shift?',
        message:
            'The record will be hidden locally and marked for future sync.',
        confirmLabel: 'Delete shift',
        cancelLabel: 'Go back',
        destructive: true);
    if (!confirmed || !context.mounted || shiftId == null) return;
    final deleted = await context.read<ShiftProvider>().delete(shiftId!);
    if (!context.mounted || !deleted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Shift deleted.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShiftProvider>();
    final shift = shiftId == null ? null : store.findById(shiftId!);
    return Scaffold(
      appBar: AppBar(title: const Text('Shift details')),
      body: store.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shift == null
              ? const Center(
                  child: Text(
                      'No shift selected. Open a saved shift from History.'))
              : ListView(padding: const EdgeInsets.all(24), children: [
                  Text(shiftDuration(shift.duration),
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 24),
                  _item('Start', shiftDateTime(shift.start)),
                  _item('End', shiftDateTime(shift.end)),
                  _item('Paused', shiftDuration(shift.paused)),
                  _item('Client / project',
                      shift.tags.isEmpty ? 'No tags' : shift.tags.join(' / ')),
                  _item('Note', shift.note.isEmpty ? 'No note' : shift.note),
                  _item(
                      'Reference links',
                      shift.links.isEmpty
                          ? 'No reference links'
                          : shift.links.join('\n')),
                  _item('Storage',
                      'Saved on this device; cloud sync is not connected yet.'),
                  if (store.errorMessage != null)
                    Text(store.errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                      onPressed: store.isSaving
                          ? null
                          : () => Navigator.pushNamed(
                              context, AppRoutes.shiftForm,
                              arguments: shift),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit shift')),
                  TextButton.icon(
                      onPressed: store.isSaving ? null : () => _delete(context),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                          store.isSaving ? 'Deleting...' : 'Delete shift')),
                ]),
    );
  }

  Widget _item(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        SelectableText(value),
      ]));
}
