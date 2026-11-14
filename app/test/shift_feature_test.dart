import 'package:flutter_test/flutter_test.dart';
import 'package:spentr/data/models/shift.dart';
import 'package:spentr/state/shift_provider.dart';

import 'fake_shift_repository.dart';

Shift example({int? id}) {
  final start = DateTime.utc(2026, 11, 14, 9);
  return Shift(
      id: id,
      start: start,
      end: start.add(const Duration(hours: 3)),
      durationMs: const Duration(hours: 2, minutes: 30).inMilliseconds,
      note: 'Website redesign',
      tags: const ['Acme', 'Website'],
      links: const ['https://github.com/example/project/pull/1'],
      updatedAt: start);
}

void main() {
  test('SQLite map preserves timestamps, tags, links and pause duration', () {
    final saved = Shift.fromMap(example(id: 7).toMap());
    expect(saved.id, 7);
    expect(saved.start, example().start);
    expect(saved.tags, ['Acme', 'Website']);
    expect(saved.links, example().links);
    expect(saved.paused, const Duration(minutes: 30));
  });

  test('invalid time window is rejected before storage', () {
    final bad = example().copyWith(end: example().start);
    expect(bad.validate, throwsArgumentError);
  });

  test('URLs require http/https and a host', () {
    expect(Shift.isValidReference('https://example.com/task/1'), isTrue);
    expect(Shift.isValidReference('not a url'), isFalse);
    expect(Shift.isValidReference('javascript:alert(1)'), isFalse);
  });

  test('save, edit, reload and soft-delete update shared state', () async {
    final repo = FakeShiftRepository();
    final store = ShiftProvider(repo);
    await store.load();
    final saved = (await store.save(example()))!;
    expect(saved.id, isNotNull);
    expect(store.shifts.single.note, 'Website redesign');
    await store.save(saved.copyWith(note: 'Reviewed work'));
    await store.load();
    expect(store.shifts.single.note, 'Reviewed work');
    expect(await store.delete(saved.id!), isTrue);
    expect(store.shifts, isEmpty);
    expect(repo.records.single.isDeleted, isTrue);
    await store.load();
    expect(store.shifts, isEmpty);
    store.dispose();
  });

  test('failed writes leave existing state unchanged and expose an error',
      () async {
    final repo = FakeShiftRepository();
    final store = ShiftProvider(repo);
    final saved = (await store.save(example()))!;
    repo.failWrites = true;
    expect(await store.save(saved.copyWith(note: 'Should not appear')), isNull);
    expect(store.shifts.single.note, 'Website redesign');
    expect(store.errorMessage, isNotNull);
    expect(store.isSaving, isFalse);
    expect(await store.delete(saved.id!), isFalse);
    expect(store.shifts, hasLength(1));
    store.dispose();
  });

  test('a failed read can be retried without losing previous cached records',
      () async {
    final repo = FakeShiftRepository();
    final store = ShiftProvider(repo);
    await store.save(example());
    repo.failReads = true;
    await store.load();
    expect(store.errorMessage, isNotNull);
    expect(store.shifts, hasLength(1));
    repo.failReads = false;
    await store.load();
    expect(store.errorMessage, isNull);
    expect(store.isLoading, isFalse);
    store.dispose();
  });
}
