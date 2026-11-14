import 'package:spentr/data/local/settings_store.dart';
import 'package:spentr/data/models/app_settings.dart';

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([this.settings = const AppSettings()]);

  AppSettings settings;
  bool failLoads = false;
  bool failSaves = false;
  int saves = 0;

  @override
  Future<AppSettings> load() async {
    if (failLoads) throw Exception('Simulated settings load failure');
    return settings;
  }

  @override
  Future<void> save(AppSettings value) async {
    if (failSaves) throw Exception('Simulated settings save failure');
    saves += 1;
    settings = value;
  }
}
