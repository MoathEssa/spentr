String shiftDateTime(DateTime value) {
  final date = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}';
}

String shiftDuration(Duration duration) {
  final minutes = duration.inMinutes;
  return '${minutes ~/ 60}h ${minutes % 60}m';
}
