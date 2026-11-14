const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _two(int n) => n.toString().padLeft(2, '0');

/// `November 2026`
String monthLabel(DateTime value) =>
    '${_months[value.month - 1]} ${value.year}';

/// `Sat, 14 Nov 2026`
String dayLabel(DateTime value) {
  final d = value.toLocal();
  return '${_weekdays[d.weekday - 1]}, ${d.day} '
      '${_months[d.month - 1].substring(0, 3)} ${d.year}';
}

/// `14 Nov 2026`
String shortDate(DateTime value) {
  final d = value.toLocal();
  return '${d.day} ${_months[d.month - 1].substring(0, 3)} ${d.year}';
}

/// `09:00`
String clockTime(DateTime value) {
  final d = value.toLocal();
  return '${_two(d.hour)}:${_two(d.minute)}';
}

/// Monday-first single-letter weekday headers for the month grid.
const weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// A short amount for a calendar cell: `75`, `1.2k`.
String compactAmount(double value) {
  if (value >= 1000) {
    final k = value / 1000;
    return '${k >= 10 ? k.round() : k.toStringAsFixed(1)}k';
  }
  return value.round().toString();
}

/// A short duration for a calendar cell: `2.5h`, `45m`.
String compactHours(Duration value) {
  if (value.inMinutes < 60) return '${value.inMinutes}m';
  final hours = value.inMinutes / 60;
  return hours == hours.roundToDouble()
      ? '${hours.round()}h'
      : '${hours.toStringAsFixed(1)}h';
}
