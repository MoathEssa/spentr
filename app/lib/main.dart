import 'package:flutter/material.dart';

import 'app.dart';
import 'data/local/settings_store.dart';
import 'state/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider(SharedPreferencesSettingsStore());
  await settings.load();
  runApp(SpentrApp(settingsProvider: settings));
}
