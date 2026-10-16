enum SessionStatus { running, paused }

/// The shift currently being timed. Saved to shared_preferences on every
/// change so it survives the app being closed or the phone rebooting.
///
/// Elapsed time is always derived from the stored timestamps, never counted
/// by a ticker.
class ActiveSession {
  const ActiveSession({
    required this.start,
    required this.status,
    this.accumulatedMs = 0,
    this.segmentStart,
    this.note = '',
    this.tags = const [],
  });

  final DateTime start;
  final SessionStatus status;

  /// Worked milliseconds from segments that ended with a pause.
  final int accumulatedMs;

  /// Start of the current running segment; null while paused.
  final DateTime? segmentStart;

  final String note;
  final List<String> tags;

  bool get isRunning => status == SessionStatus.running;

  /// Worked time at [now]: banked segments plus the live one.
  Duration workedAt(DateTime now) {
    final live = isRunning && segmentStart != null
        ? now.difference(segmentStart!).inMilliseconds
        : 0;
    return Duration(milliseconds: accumulatedMs + live);
  }
}
