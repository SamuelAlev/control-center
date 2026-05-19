/// Compact formatters for the observability surfaces, mirroring the reference
/// `format.ts` helpers (tokens as k/M, cost as $, durations as ms/s/m/h).
library;

/// Formats a US-cents integer as a dollar string. Sub-dollar amounts show three
/// decimals ($0.004) so small per-run costs stay legible; larger amounts use
/// two ($4.20).
String fmtCents(int cents) {
  final dollars = cents / 100.0;
  if (dollars == 0) {
    return r'$0.00';
  }
  if (dollars.abs() < 1) {
    return '\$${dollars.toStringAsFixed(3)}';
  }
  return '\$${dollars.toStringAsFixed(2)}';
}

/// Formats a token count compactly: `950`, `12.3k`, `1.2M`.
String fmtTokens(int n) {
  if (n < 1000) {
    return '$n';
  }
  if (n < 1000000) {
    final k = n / 1000.0;
    return '${_trim1(k)}k';
  }
  final m = n / 1000000.0;
  return '${_trim1(m)}M';
}

/// Formats a count compactly (same scale as [fmtTokens]).
String fmtCount(int n) => fmtTokens(n);

/// Formats a millisecond duration: `847ms`, `12.3s`, `4m05s`, `1h12m`.
String fmtDuration(int ms) {
  if (ms < 1000) {
    return '${ms}ms';
  }
  final seconds = ms / 1000.0;
  // Guard the boundary: _trim1 rounds to one decimal, so a value in
  // [59.95, 60) would render as "60s"; promote those to the minutes branch.
  if (seconds < 59.95) {
    return '${_trim1(seconds)}s';
  }
  final totalSeconds = ms ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  if (minutes < 60) {
    final rem = totalSeconds % 60;
    return '${minutes}m${rem.toString().padLeft(2, '0')}s';
  }
  final hours = minutes ~/ 60;
  final remMin = minutes % 60;
  return '${hours}h${remMin.toString().padLeft(2, '0')}m';
}

/// Formats a [Duration] with [fmtDuration].
String fmtDurationOf(Duration d) => fmtDuration(d.inMilliseconds);

/// Formats a 0..1 fraction as a whole-number percent (`92%`).
String fmtPercent(double fraction) => '${(fraction * 100).round()}%';

/// A short relative-time label: `now`, `42s ago`, `5m ago`, `3h ago`, `2d ago`.
String relTime(DateTime when, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final diff = ref.difference(when);
  final s = diff.inSeconds;
  if (s < 5) {
    return 'now';
  }
  if (s < 60) {
    return '${s}s ago';
  }
  final m = diff.inMinutes;
  if (m < 60) {
    return '${m}m ago';
  }
  final h = diff.inHours;
  if (h < 24) {
    return '${h}h ago';
  }
  return '${diff.inDays}d ago';
}

String _trim1(double v) {
  // One decimal place, but drop a trailing `.0` so 12.0k renders as 12k.
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// Formats an hour bucket start as `14:00`.
String fmtHourBucket(DateTime when) =>
    '${when.hour.toString().padLeft(2, '0')}:00';

/// Formats a day bucket start as `month/day` (e.g. `6/29`).
String fmtDayBucket(DateTime when) => '${when.month}/${when.day}';

/// Formats a week bucket (Monday-floored) as its week-start day label
/// (same shape as [fmtDayBucket]).
String fmtWeekBucket(DateTime weekStart) => fmtDayBucket(weekStart);
