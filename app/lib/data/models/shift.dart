/// One finished work period. Stored in the local SQLite `shifts` table and
/// mirrored to the API's `Shifts` table by sync.
class Shift {
  const Shift({
    this.id,
    this.serverId,
    required this.start,
    required this.end,
    required this.durationMs,
    this.note = '',
    this.tags = const [],
    this.links = const [],
    required this.updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
  });

  /// Local SQLite row id; null until the shift is first saved.
  final int? id;

  /// Id assigned by the API; null until the shift has been synced once.
  final String? serverId;

  final DateTime start;
  final DateTime end;

  /// Worked time with pauses removed, in milliseconds.
  final int durationMs;

  final String note;

  /// Client or project labels, e.g. `['Acme', 'Website']`.
  final List<String> tags;

  /// Reference links such as a pull request or ticket URL.
  final List<String> links;

  /// Last local change; the newer value wins when sync finds a conflict.
  final DateTime updatedAt;

  final bool isSynced;

  /// Soft delete, so a deletion syncs like any other change.
  final bool isDeleted;

  Duration get duration => Duration(milliseconds: durationMs);

  Duration get paused => end.difference(start) - duration;

  double earnings(double hourlyRate) =>
      durationMs / Duration.millisecondsPerHour * hourlyRate;
}
