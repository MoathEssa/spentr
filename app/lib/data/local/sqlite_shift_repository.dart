import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/shift.dart';
import '../repositories/shift_repository.dart';

class SqliteShiftRepository implements ShiftRepository {
  SqliteShiftRepository({this.userId = 'local-demo'});

  /// Temporary local identity until the team's real auth flow is integrated.
  /// Construct a fresh repository/provider for the authenticated account.
  final String userId;
  Future<Database>? _opening;

  Future<Database> _database() async {
    try {
      return await (_opening ??= _open());
    } catch (_) {
      _opening = null; // A failed initialization can be retried.
      rethrow;
    }
  }

  Future<Database> _open() async {
    if (userId.trim().isEmpty) throw ArgumentError('userId is required.');
    final folder = await getDatabasesPath();
    return openDatabase(
      p.join(folder, 'spentr_phase3.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE shifts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            server_id TEXT,
            start_time INTEGER NOT NULL,
            end_time INTEGER NOT NULL,
            duration_ms INTEGER NOT NULL,
            note TEXT NOT NULL,
            tags TEXT NOT NULL,
            links TEXT NOT NULL,
            updated_at INTEGER NOT NULL,
            is_synced INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            CHECK(end_time > start_time),
            CHECK(duration_ms >= 0 AND duration_ms <= end_time - start_time)
          )
        ''');
        await db.execute(
            'CREATE INDEX shifts_owner_start ON shifts(user_id, start_time DESC)');
      },
    );
  }

  @override
  Future<List<Shift>> getAll() async {
    final db = await _database();
    final rows = await db.query('shifts',
        where: 'user_id = ? AND is_deleted = 0',
        whereArgs: [userId],
        orderBy: 'start_time DESC, id DESC');
    return rows.map(Shift.fromMap).toList();
  }

  @override
  Future<Shift> insert(Shift shift) async {
    shift.validate();
    if (shift.id != null || shift.isDeleted) {
      throw ArgumentError('A new shift must not have an ID or be deleted.');
    }
    final db = await _database();
    final saved =
        shift.copyWith(updatedAt: DateTime.now().toUtc(), isSynced: false);
    final id = await db.insert('shifts', {...saved.toMap(), 'user_id': userId});
    return saved.copyWith(id: id);
  }

  @override
  Future<void> update(Shift shift) async {
    shift.validate();
    if (shift.id == null || shift.isDeleted) {
      throw ArgumentError('An existing active shift is required.');
    }
    final db = await _database();
    final values = shift.toMap()..remove('id');
    final changed = await db.update('shifts', values,
        where: 'id = ? AND user_id = ? AND is_deleted = 0',
        whereArgs: [shift.id, userId]);
    if (changed != 1) throw StateError('The shift no longer exists.');
  }

  @override
  Future<void> softDelete(int id) async {
    final db = await _database();
    final changed = await db.update(
        'shifts',
        {
          'is_deleted': 1,
          'is_synced': 0,
          'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        },
        where: 'id = ? AND user_id = ? AND is_deleted = 0',
        whereArgs: [id, userId]);
    if (changed != 1) throw StateError('The shift no longer exists.');
  }
}
