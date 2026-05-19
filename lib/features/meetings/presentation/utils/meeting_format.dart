/// Which day-group a meeting falls into on the list screen.
enum MeetingDayBucket {
  /// Started today.
  today,

  /// Started yesterday.
  yesterday,

  /// Started earlier in the current week (before yesterday).
  earlierThisWeek,

  /// Started in the previous calendar week.
  lastWeek,

  /// Older than the previous week.
  older,
}

/// Pure formatting helpers for meeting durations, transcript timestamps, and
/// day-bucketing. Kept context-free so they can be unit-tested; the localized
/// labels for the buckets live in the widgets that consume them.
abstract final class MeetingFormat {
  const MeetingFormat._();

  /// `MM:SS`, or `H:MM:SS` when an hour or longer — used for the live record
  /// timer and per-segment transcript stamps.
  static String clock(Duration d) {
    final total = d.inSeconds < 0 ? 0 : d.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  /// Transcript-segment timestamp from a millisecond offset.
  static String stamp(int ms) => clock(Duration(milliseconds: ms < 0 ? 0 : ms));

  /// A compact total like `3h 03m`, `48m`, or `0m` — used for aggregate stats.
  static String totalLabel(Duration d) {
    final total = d.inSeconds < 0 ? 0 : d.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m}m';
  }

  /// The recorded duration for a start/end pair, falling back to "now" while a
  /// recording is still in progress.
  static Duration duration(DateTime startedAt, DateTime? endedAt, DateTime now) {
    final end = endedAt ?? now;
    final d = end.difference(startedAt);
    return d.isNegative ? Duration.zero : d;
  }

  /// Classifies [when] relative to [now] into a [MeetingDayBucket].
  static MeetingDayBucket bucketFor(DateTime when, DateTime now) {
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
    // Monday as the first day of the week.
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));

    if (!when.isBefore(startOfToday)) {
      return MeetingDayBucket.today;
    }
    if (!when.isBefore(startOfYesterday)) {
      return MeetingDayBucket.yesterday;
    }
    if (!when.isBefore(startOfWeek)) {
      return MeetingDayBucket.earlierThisWeek;
    }
    if (!when.isBefore(startOfLastWeek)) {
      return MeetingDayBucket.lastWeek;
    }
    return MeetingDayBucket.older;
  }
}
