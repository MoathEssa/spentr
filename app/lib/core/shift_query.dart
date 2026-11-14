import '../data/models/shift.dart';

/// Sort orders offered on History (E5).
enum ShiftSort {
  newest('Newest first'),
  oldest('Oldest first'),
  longest('Longest duration'),
  highestEarnings('Highest earnings');

  const ShiftSort(this.label);
  final String label;
}

/// A local calendar date range, inclusive at both ends.
class DayRange {
  DayRange(DateTime start, DateTime end)
      : start = dateOnly(start),
        end = dateOnly(end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) {
    final day = dateOnly(value);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  @override
  bool operator ==(Object other) =>
      other is DayRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Search text, date range, tags and sort order chosen on History.
///
/// History owns this value with `setState`, as planned in the Phase 2
/// state design; the shift list itself comes from `ShiftProvider`.
class ShiftFilter {
  const ShiftFilter({
    this.query = '',
    this.range,
    this.tags = const {},
    this.sort = ShiftSort.newest,
  });

  final String query;
  final DayRange? range;
  final Set<String> tags;
  final ShiftSort sort;

  /// Date range and tag choices from the Filter sheet (not search or sort).
  int get activeFilterCount => (range == null ? 0 : 1) + tags.length;

  bool get isDefault =>
      query.trim().isEmpty &&
      activeFilterCount == 0 &&
      sort == ShiftSort.newest;

  ShiftFilter copyWith({
    String? query,
    DayRange? range,
    bool clearRange = false,
    Set<String>? tags,
    ShiftSort? sort,
  }) =>
      ShiftFilter(
        query: query ?? this.query,
        range: clearRange ? null : (range ?? this.range),
        tags: tags ?? this.tags,
        sort: sort ?? this.sort,
      );

  /// Keeps the search text and sort; clears the sheet's filters.
  ShiftFilter withoutFilters() => ShiftFilter(query: query, sort: sort);

  bool matches(Shift shift) {
    if (shift.isDeleted) return false;
    final text = query.trim().toLowerCase();
    if (text.isNotEmpty && !shift.note.toLowerCase().contains(text)) {
      return false;
    }
    if (range != null && !range!.contains(shift.start)) return false;
    if (tags.isNotEmpty && !shift.tags.any(tags.contains)) return false;
    return true;
  }

  /// Matching shifts in the chosen order. [hourlyRate] is only used for the
  /// earnings sort; ties fall back to the newest start time.
  List<Shift> apply(Iterable<Shift> shifts, {double hourlyRate = 0}) {
    final result = shifts.where(matches).toList();
    int newestFirst(Shift a, Shift b) => b.start.compareTo(a.start);
    int Function(Shift, Shift) compare = switch (sort) {
      ShiftSort.newest => newestFirst,
      ShiftSort.oldest => (a, b) => a.start.compareTo(b.start),
      ShiftSort.longest => (a, b) => b.durationMs.compareTo(a.durationMs),
      ShiftSort.highestEarnings => (a, b) =>
          b.earnings(hourlyRate).compareTo(a.earnings(hourlyRate)),
    };
    result.sort((a, b) {
      final order = compare(a, b);
      return order != 0 ? order : newestFirst(a, b);
    });
    return result;
  }
}

/// Every distinct client / project tag, sorted case-insensitively.
List<String> allTags(Iterable<Shift> shifts) {
  final tags = <String>{
    for (final shift in shifts)
      if (!shift.isDeleted) ...shift.tags,
  }.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return tags;
}

DateTime dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
