// ignore_for_file: avoid_classes_with_only_static_members

import 'package:cc_domain/features/model_routing/domain/entities/usage.dart';

/// A spend summary over a time window, computed from observed per-request cost
/// history — the data behind a *"$12.40 spent this week, resets in 40m"*
/// dashboard (feature #12).
class CostSummary {
  /// Creates a [CostSummary].
  const CostSummary({
    required this.totalUsd,
    required this.requestCount,
    required this.windowStart,
    required this.byProvider,
    required this.byModel,
    this.nextResetAt,
  });

  /// Total USD spent in the window.
  final double totalUsd;

  /// Number of costed requests in the window.
  final int requestCount;

  /// The window's start.
  final DateTime windowStart;

  /// Spend per provider id.
  final Map<String, double> byProvider;

  /// Spend per `providerId/modelId`.
  final Map<String, double> byModel;

  /// When the nearest quota window resets (from live usage reports), if known.
  final DateTime? nextResetAt;

  /// Whether anything was spent.
  bool get isEmpty => requestCount == 0;
}

/// Aggregates usage/cost data for dashboards and credential ranking input.
abstract final class UsageTracker {
  /// Summarizes [entries] within `[since, now]`. [reports] (optional live quota
  /// reports) supply the nearest reset time.
  static CostSummary summarize(
    List<UsageCostHistoryEntry> entries, {
    required DateTime since,
    required DateTime now,
    List<UsageReport> reports = const [],
  }) {
    var total = 0.0;
    var count = 0;
    final byProvider = <String, double>{};
    final byModel = <String, double>{};
    for (final e in entries) {
      if (e.recordedAt.isBefore(since) || e.recordedAt.isAfter(now)) {
        continue;
      }
      total += e.costUsd;
      count++;
      byProvider.update(
        e.provider,
        (v) => v + e.costUsd,
        ifAbsent: () => e.costUsd,
      );
      final modelKey = e.modelId == null
          ? e.provider
          : '${e.provider}/${e.modelId}';
      byModel.update(modelKey, (v) => v + e.costUsd, ifAbsent: () => e.costUsd);
    }

    DateTime? nextReset;
    for (final r in reports) {
      final reset = UsageMath.earliestReset(r.limits);
      if (reset != null &&
          reset.isAfter(now) &&
          (nextReset == null || reset.isBefore(nextReset))) {
        nextReset = reset;
      }
    }

    return CostSummary(
      totalUsd: total,
      requestCount: count,
      windowStart: since,
      byProvider: byProvider,
      byModel: byModel,
      nextResetAt: nextReset,
    );
  }

  /// Convenience: spend over the last [window] up to [now].
  static CostSummary summarizeLast(
    List<UsageCostHistoryEntry> entries, {
    required Duration window,
    required DateTime now,
    List<UsageReport> reports = const [],
  }) => summarize(
    entries,
    since: now.subtract(window),
    now: now,
    reports: reports,
  );
}
