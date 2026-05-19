/// Shared formatting helpers for pipeline run/step timing.
///
/// Durations render as compact `1h 2m` / `3m 4s` / `5s` / `120ms` strings and
/// absolute timestamps as `yyyy-MM-dd HH:mm:ss`, matching the run list, the run
/// header and the step detail panel. Everything here is locale-neutral except
/// [formatPipelineRelative], which needs the localized "N ago" phrasings.
library;

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
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

/// Queue position of every `queued` run in [runs], keyed by run id, where 1 is
/// the run that will be admitted next.
///
/// A capped template (`index_code` is capped at one) admits its queued runs
/// oldest-first, but the list they are shown in is NEWEST-first — so the run
/// about to start is the one at the BOTTOM of a queued block, which reads as
/// last when it is next. That is what this labels.
///
/// Position is derived from [runs]' ORDER rather than from `startedAt` because
/// that timestamp has one-second resolution: adding six repos at once stamps
/// all six runs identically, and nothing here could separate them. The server
/// orders them (`PipelineDao.watchForWorkspace`, newest first with an insert-
/// order tiebreak), so reversing within a template's queued rows recovers the
/// admission order exactly. Pass the UNFILTERED list — a status filter that
/// hides part of a queue would otherwise renumber the rest.
///
/// The cap is per `(workspace, template)`, so queues are counted per template;
/// runs of other templates never share a position.
Map<String, int> pipelineQueuePositions(List<PipelineRun> runs) {
  final queuedByTemplate = <String, List<String>>{};
  for (final run in runs) {
    if (run.status != PipelineRunStatus.queued) {
      continue;
    }
    (queuedByTemplate['${run.workspaceId}|${run.templateId}'] ??= <String>[])
        .add(run.id);
  }
  return {
    for (final ids in queuedByTemplate.values)
      for (var i = 0; i < ids.length; i++) ids[i]: ids.length - i,
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
