import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../widgets/placeholder_view.dart';

/// Export a period to PDF, CSV or JSON (optional feature O2).
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export your hours')),
      body: PlaceholderView(
        purpose: 'Optional (O2). Choose a period, client and file format, '
            'then share the report.',
        states: const ['Default', 'Report is ready'],
        actions: [
          PlaceholderAction(
            'Create & share report',
            Icons.ios_share,
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report is ready (placeholder)')),
            ),
            primary: true,
          ),
          PlaceholderAction('Import JSON backup', Icons.upload_file,
              () => Navigator.pushNamed(context, AppRoutes.importReview)),
        ],
      ),
    );
  }
}
