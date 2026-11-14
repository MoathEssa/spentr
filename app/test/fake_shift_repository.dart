import 'package:spentr/data/models/shift.dart';
import 'package:spentr/data/repositories/shift_repository.dart';

class FakeShiftRepository implements ShiftRepository {
  final List<Shift> records = [];
  bool failReads = false;
  bool failWrites = false;
  int nextId = 1;

  @override
  Future<List<Shift>> getAll() async {
    if (failReads) throw Exception('Simulated read failure');
    return records.where((s) => !s.isDeleted).toList();
  }

  @override
  Future<Shift> insert(Shift shift) async {
    if (failWrites) throw Exception('Simulated write failure');
    final saved = shift.copyWith(id: nextId++);
    records.add(saved);
    return saved;
  }

  @override
  Future<void> update(Shift shift) async {
    if (failWrites) throw Exception('Simulated write failure');
    final index = records.indexWhere((s) => s.id == shift.id && !s.isDeleted);
    if (index == -1) throw StateError('Missing record');
    records[index] = shift;
  }

  @override
  Future<void> softDelete(int id) async {
    if (failWrites) throw Exception('Simulated write failure');
    final index = records.indexWhere((s) => s.id == id && !s.isDeleted);
    if (index == -1) throw StateError('Missing record');
    records[index] = records[index].copyWith(isDeleted: true, isSynced: false);
  }
}
