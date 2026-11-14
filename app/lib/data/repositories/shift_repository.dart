import '../models/shift.dart';

/// UI/state depend on this contract, so SQLite can be replaced in tests.
abstract class ShiftRepository {
  Future<List<Shift>> getAll();
  Future<Shift> insert(Shift shift);
  Future<void> update(Shift shift);
  Future<void> softDelete(int id);
}
