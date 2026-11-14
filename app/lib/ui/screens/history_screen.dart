import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../core/shift_formatters.dart';
import '../../state/shift_provider.dart';

/// Basic records list for E2. Person 3 can add E5 search/filter/sort here.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShiftProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Shift history'), actions: [
        IconButton(
            tooltip: 'Reload shifts',
            onPressed: store.isLoading || store.isSaving ? null : store.load,
            icon: const Icon(Icons.refresh)),
      ]),
      body: Column(children: [
        if (store.isLoading) const LinearProgressIndicator(),
        if (store.errorMessage != null)
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text(store.errorMessage!),
                TextButton(
                    onPressed:
                        store.isLoading || store.isSaving ? null : store.load,
                    child: const Text('Retry'))
              ])),
        Expanded(
            child: store.shifts.isEmpty
                ? Center(
                    child: Text(store.isLoading
                        ? 'Loading saved shifts...'
                        : store.errorMessage != null
                            ? 'Saved shifts are unavailable.'
                            : 'No shifts yet. Add your first shift.'))
                : RefreshIndicator(
                    onRefresh: store.load,
                    child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: store.shifts.length,
                        itemBuilder: (context, index) {
                          final shift = store.shifts[index];
                          return Card(
                              child: ListTile(
                            title: Text(shift.note.isEmpty
                                ? 'Untitled shift'
                                : shift.note),
                            subtitle: Text(
                                '${shiftDateTime(shift.start)}\n${shift.tags.join(' / ')}'),
                            trailing: Text(shiftDuration(shift.duration)),
                            isThreeLine: true,
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.shiftDetail,
                                arguments: shift.id),
                          ));
                        }))),
      ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: store.isLoading || store.isSaving
              ? null
              : () => Navigator.pushNamed(context, AppRoutes.shiftForm),
          icon: const Icon(Icons.add),
          label: const Text('Add manual shift')),
    );
  }
}
