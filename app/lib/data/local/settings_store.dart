import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Key-value persistence for [AppSettings]. Shifts stay in SQLite.
abstract class SettingsStore {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class SharedPreferencesSettingsStore implements SettingsStore {
  static const rateKey = 'settings.hourly_rate';
  static const currencyKey = 'settings.currency_code';
  static const themeKey = 'settings.theme_mode';
  static const notificationsKey = 'settings.notifications_enabled';
  static const appLockKey = 'settings.app_lock_enabled';
  static const lastSyncKey = 'settings.last_sync_at';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<AppSettings> load() async {
    final prefs = await _prefs;
    final storedRate = prefs.getDouble(rateKey) ?? 0;
    final currency = prefs.getString(currencyKey) ?? 'SAR';
    final syncMillis = prefs.getInt(lastSyncKey);
    return AppSettings(
      hourlyRate: storedRate.isFinite && storedRate > 0 ? storedRate : 0,
      currencyCode: currency.isEmpty ? 'SAR' : currency,
      themeMode: _themeMode(prefs.getString(themeKey)),
      notificationsEnabled: prefs.getBool(notificationsKey) ?? true,
      appLockEnabled: prefs.getBool(appLockKey) ?? false,
      lastSyncAt: syncMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(syncMillis, isUtc: true),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = await _prefs;
    await prefs.setDouble(rateKey, settings.hourlyRate);
    await prefs.setString(currencyKey, settings.currencyCode);
    await prefs.setString(themeKey, _themeName(settings.themeMode));
    await prefs.setBool(notificationsKey, settings.notificationsEnabled);
    await prefs.setBool(appLockKey, settings.appLockEnabled);
    if (settings.lastSyncAt == null) {
      await prefs.remove(lastSyncKey);
    } else {
      await prefs.setInt(
        lastSyncKey,
        settings.lastSyncAt!.toUtc().millisecondsSinceEpoch,
      );
    }
  }
}

String _themeName(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

ThemeMode _themeMode(String? name) => switch (name) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
