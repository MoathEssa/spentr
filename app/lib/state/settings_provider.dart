import 'package:flutter/material.dart';

import '../core/money.dart';
import '../data/local/settings_store.dart';
import '../data/models/app_settings.dart';

/// Owns the saved hourly rate, currency, and the other [AppSettings] fields.
///
/// Earnings are not cached here. Screens recalculate them from the current
/// rate and each shift's worked duration.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._store);

  final SettingsStore _store;
  AppSettings _settings = const AppSettings();
  bool _loaded = false;
  bool _loading = false;
  bool _saving = false;
  bool _disposed = false;
  String? _errorMessage;
  Future<void> _tail = Future<void>.value();

  AppSettings get settings => _settings;
  double get hourlyRate => _settings.hourlyRate;
  String get currencyCode => _settings.currencyCode;
  ThemeMode get themeMode => _settings.themeMode;
  bool get hasRate => _settings.hasRate;
  bool get isLoaded => _loaded;
  bool get isSaving => _saving;
  String? get errorMessage => _errorMessage;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _emit();
  }

  Future<void> load() => _enqueue(_load);

  Future<void> _load() async {
    if (_loaded || _loading) return;
    _loading = true;
    _errorMessage = null;
    _emit();
    try {
      _settings = await _store.load();
    } catch (_) {
      _errorMessage = 'Could not load saved settings.';
    } finally {
      _loading = false;
      _loaded = true;
      _emit();
    }
  }

  /// Persists a positive rate and a supported currency. Shift rows are not
  /// rewritten; open screens recompute earnings from this rate.
  Future<bool> saveRate({
    required double hourlyRate,
    required String currencyCode,
  }) {
    return _enqueue(() => _saveRate(hourlyRate, currencyCode));
  }

  Future<bool> _saveRate(double hourlyRate, String currencyCode) async {
    if (_saving) return false;
    if (!hourlyRate.isFinite || hourlyRate <= 0) {
      _errorMessage = 'Hourly rate must be greater than zero.';
      _emit();
      return false;
    }
    if (!isSupportedCurrency(currencyCode)) {
      _errorMessage = 'Choose a currency.';
      _emit();
      return false;
    }
    _saving = true;
    _errorMessage = null;
    _emit();
    try {
      final next = _settings.copyWith(
        hourlyRate: hourlyRate,
        currencyCode: currencyCode,
      );
      await _store.save(next);
      _settings = next;
      return true;
    } catch (_) {
      _errorMessage = 'Could not save your settings. Please retry.';
      return false;
    } finally {
      _saving = false;
      _emit();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
