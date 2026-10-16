import 'package:flutter/material.dart';

/// Bottom sheet opened from History: date range, tag and sort order.
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filter shifts',
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Placeholder · date range, client / project tag, '
                'and sort by date, duration or earnings'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Apply filters'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    ),
  );
}
