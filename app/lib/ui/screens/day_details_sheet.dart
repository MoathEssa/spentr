import 'package:flutter/material.dart';

import '../../core/routes.dart';

/// Bottom sheet opened from a calendar day on Home.
Future<void> showDayDetailsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      void openFromSheet(String route, {Object? arguments}) {
        Navigator.pop(sheetContext);
        Navigator.pushNamed(context, route, arguments: arguments);
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Day details',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              subtitle:
                  const Text('Placeholder · total and shifts for one day'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Open a shift on this day'),
              onTap: () => openFromSheet(AppRoutes.shiftDetail),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add a shift for this day'),
              onTap: () => openFromSheet(AppRoutes.shiftForm),
            ),
          ],
        ),
      );
    },
  );
}
