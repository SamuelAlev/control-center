/// Shared formatting helpers for pipeline run/step timing.
///
/// Durations render as compact `1h 2m` / `3m 4s` / `5s` / `120ms` strings and
/// absolute timestamps as `yyyy-MM-dd HH:mm:ss`, matching the run list, the run
/// header and the step detail panel. Everything here is locale-neutral except
/// [formatPipelineRelative], which needs the localized "N ago" phrasings.
library;

import 'package:control_center/l10n/app_localizations.dart';

/// Formats [d] as a compact human duration (e.g. `1h 2m`, `3m 4s`, `5s`).
String formatPipelineDuration(Duration d) {
  if (d.inHours > 0) {
    final m = d.inMinutes.remainder(60);
    return '${d.inHours}h ${m}m';
  }
  if (d.inMinutes > 0) {
    final s = d.inSeconds.remainder(60);
    return '${d.inMinutes}m ${s}s';
  }
  if (d.inSeconds > 0) {
    return '${d.inSeconds}s';
  }
  return '${d.inMilliseconds}ms';
}

/// Formats [d] as a coarse human duration that never reads as `0ms`.
///
/// Mirrors [formatPipelineDuration] but floors anything below one second to
/// `<1s`, so an instant run on the run list reads as "fast" rather than as a
/// glitch. Use this in scanning surfaces (run cards, run header); keep
/// [formatPipelineDuration] where millisecond precision matters (step detail).
String formatPipelineDurationCoarse(Duration d) {
  if (d.inHours > 0) {
    final m = d.inMinutes.remainder(60);
    return '${d.inHours}h ${m}m';
  }
  if (d.inMinutes > 0) {
    final s = d.inSeconds.remainder(60);
    return '${d.inMinutes}m ${s}s';
  }
  if (d.inSeconds > 0) {
    return '${d.inSeconds}s';
  }
  return '<1s';
}

/// Coarse relative-time bucket for "started N ago" labels.
///
/// Kept locale-neutral: the widget maps the unit and count onto the matching
/// localized string (`relativeJustNow`, `relativeMinutesAgo`, ...).
enum RelativeTimeUnit {
  /// Within the last minute.
  justNow,

  /// Whole minutes ago (1–59).
  minutes,

  /// Whole hours ago (1–23).
  hours,

  /// Whole days ago (1+).
  days,
}

/// A bucketed relative time: a [unit] and the [count] of that unit.
class RelativeTime {
  /// Creates a [RelativeTime].
  const RelativeTime(this.unit, this.count);

  /// The coarsest applicable unit.
  final RelativeTimeUnit unit;

  /// How many of [unit] have elapsed (0 for [RelativeTimeUnit.justNow]).
  final int count;
}

/// Buckets the gap between [from] and [now] into a [RelativeTime].
RelativeTime relativePipelineTime(DateTime from, DateTime now) {
  final diff = now.difference(from);
  if (diff.inMinutes < 1) {
    return const RelativeTime(RelativeTimeUnit.justNow, 0);
  }
  if (diff.inMinutes < 60) {
    return RelativeTime(RelativeTimeUnit.minutes, diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return RelativeTime(RelativeTimeUnit.hours, diff.inHours);
  }
  return RelativeTime(RelativeTimeUnit.days, diff.inDays);
}

/// Formats the gap between [from] and [now] as a localized "N ago" label.
///
/// Replaced the former `HH:mm` run-header stamp.
///
/// The one place pipeline surfaces render a start time: "12 min ago" answers
/// "is this recent?" at a glance, which a bare `14:32` does not. Pair it with an
/// `AppTimestamp` when the exact instant still has to be reachable.
String formatPipelineRelative(
  DateTime from,
  DateTime now,
  AppLocalizations l10n,
) {
  final r = relativePipelineTime(from, now);
  return switch (r.unit) {
    RelativeTimeUnit.justNow => l10n.relativeJustNow,
    RelativeTimeUnit.minutes => l10n.relativeMinutesAgo(r.count),
    RelativeTimeUnit.hours => l10n.relativeHoursAgo(r.count),
    RelativeTimeUnit.days => l10n.relativeDaysAgo(r.count),
  };
}

/// Formats [dt] (converted to local time) as `yyyy-MM-dd HH:mm:ss`.
String formatPipelineDateTime(DateTime dt) {
  final local = dt.toLocal();
  final mo = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final mi = local.minute.toString().padLeft(2, '0');
  final s = local.second.toString().padLeft(2, '0');
  return '${local.year}-$mo-$d $h:$mi:$s';
}
