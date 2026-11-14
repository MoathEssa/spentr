import 'dart:convert';

/// One finished work period. Times are serialized as UTC epoch milliseconds.
class Shift {
  const Shift(
      {this.id,
      this.serverId,
      required this.start,
      required this.end,
      required this.durationMs,
      this.note = '',
      this.tags = const [],
      this.links = const [],
      required this.updatedAt,
      this.isSynced = false,
      this.isDeleted = false});

  final int? id;
  final String? serverId;
  final DateTime start;
  final DateTime end;
  final int durationMs;
  final String note;
  final List<String> tags;
  final List<String> links;
  final DateTime updatedAt;
  final bool isSynced;
  final bool isDeleted;

  Duration get duration => Duration(milliseconds: durationMs);
  Duration get paused => end.difference(start) - duration;
  double earnings(double hourlyRate) =>
      durationMs / Duration.millisecondsPerHour * hourlyRate;

  void validate() {
    if (!end.isAfter(start)) {
      throw ArgumentError('End must be after start.');
    }
    if (durationMs < 0 || durationMs > end.difference(start).inMilliseconds) {
      throw ArgumentError('Worked duration must fit within the shift.');
    }
    for (final link in links) {
      if (!isValidReference(link)) {
        throw ArgumentError('Reference links must be full http/https URLs.');
      }
    }
  }

  static bool isValidReference(String value) {
    final uri = Uri.tryParse(value);
    return !RegExp(r'\s').hasMatch(value) &&
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'server_id': serverId,
        'start_time': start.toUtc().millisecondsSinceEpoch,
        'end_time': end.toUtc().millisecondsSinceEpoch,
        'duration_ms': durationMs,
        'note': note,
        'tags': jsonEncode(tags),
        'links': jsonEncode(links),
        'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
        'is_synced': isSynced ? 1 : 0,
        'is_deleted': isDeleted ? 1 : 0,
      };

  factory Shift.fromMap(Map<String, Object?> map) => Shift(
        id: map['id'] as int?,
        serverId: map['server_id'] as String?,
        start: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int,
            isUtc: true),
        end: DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int,
            isUtc: true),
        durationMs: map['duration_ms'] as int,
        note: map['note'] as String,
        tags: List<String>.from(jsonDecode(map['tags'] as String) as List),
        links: List<String>.from(jsonDecode(map['links'] as String) as List),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int,
            isUtc: true),
        isSynced: map['is_synced'] == 1,
        isDeleted: map['is_deleted'] == 1,
      );

  Shift copyWith(
          {int? id,
          DateTime? start,
          DateTime? end,
          int? durationMs,
          String? note,
          List<String>? tags,
          List<String>? links,
          DateTime? updatedAt,
          bool? isSynced,
          bool? isDeleted}) =>
      Shift(
        id: id ?? this.id,
        serverId: serverId,
        start: start ?? this.start,
        end: end ?? this.end,
        durationMs: durationMs ?? this.durationMs,
        note: note ?? this.note,
        tags: tags ?? this.tags,
        links: links ?? this.links,
        updatedAt: updatedAt ?? this.updatedAt,
        isSynced: isSynced ?? this.isSynced,
        isDeleted: isDeleted ?? this.isDeleted,
      );
}
