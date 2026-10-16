import 'package:flutter/material.dart';

/// User preferences. Stored in shared_preferences; the rate and currency are
/// also synced through `GET`/`PUT /api/settings`.
class AppSettings {
  const AppSettings({
    this.hourlyRate = 0,
    this.currencyCode = 'SAR',
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.appLockEnabled = false,
    this.lastSyncAt,
  });

  final double hourlyRate;

  /// ISO 4217 code, e.g. `SAR` or `USD`.
  final String currencyCode;

  final ThemeMode themeMode;
  final bool notificationsEnabled;

  /// Optional biometric lock (O2).
  final bool appLockEnabled;

  /// Shown in Settings as "Synced just now"; null before the first sync.
  final DateTime? lastSyncAt;

  /// False for a new account, which is sent to Rate setup after sign-up.
  bool get hasRate => hourlyRate > 0;
}
