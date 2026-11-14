import 'package:flutter/foundation.dart';

import '../data/models/shift.dart';
import '../data/repositories/shift_repository.dart';

class ShiftProvider extends ChangeNotifier {
  ShiftProvider(this._repository);
  final ShiftRepository _repository;
  List<Shift> _shifts = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _loadFailed = false;
  bool _disposed = false;

  List<Shift> get shifts => List.unmodifiable(_shifts);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// True when the last [load] failed, so screens can tell "could not read
  /// the database" apart from a failed save or delete.
  bool get hasLoadError => _loadFailed;

  Shift? findById(int id) {
    for (final shift in _shifts) {
      if (shift.id == id) return shift;
    }
    return null;
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (_isLoading || _isSaving) return;
    _isLoading = true;
    _errorMessage = null;
    _emit();
    try {
      _shifts = await _repository.getAll();
      _loadFailed = false;
    } catch (_) {
      _loadFailed = true;
      _errorMessage = 'Could not load saved shifts. Please retry.';
    } finally {
      _isLoading = false;
      _emit();
    }
  }

  /// Null means saving failed; existing state stays unchanged on failure.
  Future<Shift?> save(Shift shift) async {
    if (_isSaving || _isLoading) return null;
    _isSaving = true;
    _errorMessage = null;
    _emit();
    try {
      shift.validate();
      final changed =
          shift.copyWith(updatedAt: DateTime.now().toUtc(), isSynced: false);
      final Shift saved;
      if (changed.id == null) {
        saved = await _repository.insert(changed);
      } else {
        await _repository.update(changed);
        saved = changed;
      }
      _shifts = [..._shifts.where((s) => s.id != saved.id), saved]
        ..sort((a, b) => b.start.compareTo(a.start));
      return saved;
    } on ArgumentError catch (error) {
      _errorMessage = error.message.toString();
      return null;
    } catch (_) {
      _errorMessage =
          'Could not save this shift. Your input has been kept; please retry.';
      return null;
    } finally {
      _isSaving = false;
      _emit();
    }
  }

  Future<bool> delete(int id) async {
    if (_isSaving || _isLoading) return false;
    _isSaving = true;
    _errorMessage = null;
    _emit();
    try {
      await _repository.softDelete(id);
      _shifts = _shifts.where((s) => s.id != id).toList();
      return true;
    } catch (_) {
      _errorMessage = 'Could not delete this shift. Please retry.';
      return false;
    } finally {
      _isSaving = false;
      _emit();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
