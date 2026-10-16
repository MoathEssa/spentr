import 'package:flutter/material.dart';

import '../widgets/placeholder_view.dart';

/// Choose a JSON backup and review it before importing (optional O2).
class ImportReviewScreen extends StatelessWidget {
  const ImportReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import a backup')),
      body: PlaceholderView(
        purpose: 'Optional (O2). Pick a Spentr JSON file, see how many shifts '
            'it holds and which duplicates will be skipped.',
        states: const ['Choose file', 'Review backup'],
        actions: [
          PlaceholderAction('Import shifts', Icons.download_done,
              () => Navigator.pop(context),
              primary: true),
          PlaceholderAction(
              'Cancel', Icons.close, () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
