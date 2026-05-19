import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:flutter/widgets.dart';

/// The run duration of a check: `completedAt - startedAt` when finished, the
/// elapsed time so far while it runs, null when it never reported a start
/// (queued, skipped, external checks without timing).
Duration? checkRunDuration(CheckRun run, {DateTime? now}) {
  final started = run.startedAt;
  if (started == null) {
    return null;
  }
  final completed = run.completedAt;
  if (completed != null) {
    return completed.difference(started);
  }
  if (run.isComplete) {
    return null;
  }
  return (now ?? DateTime.now()).difference(started);
}

/// Formats [dt] as a short relative-time string ("just now", "3m ago",
/// "2 days ago", ...).
String formatRelative(DateTime? dt, {DateTime? now}) {
  if (dt == null) {
    return '';
  }

  final reference = now ?? DateTime.now();
  final diff = reference.difference(dt);
  if (diff.isNegative) {
    return 'just now';
  }

  if (diff.inSeconds < 30) {
    return 'just now';
  }

  if (diff.inMinutes < 1) {
    return '${diff.inSeconds}s ago';
  }

  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  }

  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }

  if (diff.inDays == 1) {
    return 'yesterday';
  }

  if (diff.inDays < 30) {
    return '${diff.inDays} days ago';
  }

  if (diff.inDays < 365) {
    return '${(diff.inDays / 30).floor()} months ago';
  }

  return '${(diff.inDays / 365).floor()} years ago';
}

/// Returns a color that progressively warms with the age of [dt].
///
/// Thresholds:
/// - < 12 hours → [neutral]
/// - 12 hours – 2 days → yellow (caution)
/// - 2 – 5 days → orange (warning)
/// - > 5 days → red (urgent)
Color ageColor(
  DateTime? dt, {
  DateTime? now,
  Color neutral = const Color(0xFF8C8578),
}) {
  if (dt == null) {
    return neutral;
  }

  final reference = now ?? DateTime.now();
  final diff = reference.difference(dt);

  if (diff.isNegative || diff.inHours < 12) {
    return neutral;
  }

  if (diff.inDays <= 2) {
    return DesignSystemPalette.yellow600;
  }

  if (diff.inDays <= 5) {
    return DesignSystemPalette.orange500;
  }

  return DesignSystemPalette.red500;
}

/// Whether [dt] is stale (older than 30 days) — the threshold at which the PR
/// age label flips to a flat dark red so a long-unreviewed PR stands out.
bool isStaleAge(DateTime? dt, {DateTime? now}) {
  if (dt == null) {
    return false;
  }
  final reference = now ?? DateTime.now();
  return reference.difference(dt).inDays > 30;
}
