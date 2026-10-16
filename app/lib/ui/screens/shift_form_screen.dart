import 'package:flutter/material.dart';

import '../widgets/placeholder_view.dart';

/// Add manual shift and Edit shift share this form.
class ShiftFormScreen extends StatelessWidget {
  const ShiftFormScreen({super.key, this.editing = false});

  final bool editing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit shift' : 'Add manual shift')),
      body: PlaceholderView(
        purpose: 'Date, start time, end time, client / project, note and an '
            'optional reference link, with a live earnings preview.',
        states: const ['Default', 'End before start', 'Saved'],
        actions: [
          PlaceholderAction(
            editing ? 'Save changes' : 'Save shift',
            Icons.save_outlined,
            () => Navigator.pop(context),
            primary: true,
          ),
        ],
      ),
    );
  }
}
