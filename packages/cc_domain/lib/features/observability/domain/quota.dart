import 'package:cc_domain/core/domain/entities/agent_run_log.dart'
    show AgentRunLog;

/// The metric a quota is measured in.
///
/// Control Center has no provider usage API, so a quota is always evaluated
/// against locally-observed [AgentRunLog]s rather than a billing endpoint.
enum QuotaUnit {
  /// Total tokens consumed (sum of all five token axes per run).
  tokens,

  /// Number of agent runs (requests) issued.
  requests,

  /// Estimated spend in US cents.
  costCents,
}

/// Health of a quota relative to its configured ceiling.
///
/// At or above the full limit is [exhausted], at or above 80% is [warning], otherwise [ok]. When no limit is configured the fraction is undefined and the status is [unknown].
enum QuotaStatus {
  /// Usage is comfortably below the warning threshold.
  ok,

  /// Usage has reached the warning threshold (>= 80% of the limit).
  warning,

  /// Usage has reached or exceeded the limit (>= 100%).
  exhausted,

  /// No limit is configured, so utilization cannot be computed.
  unknown,
}

/// A rolling time window a quota is enforced over.
enum QuotaWindow {
  /// A five-hour rolling window.
  fiveHour,

  /// A 24-hour rolling window.
  daily,

  /// A seven-day rolling window.
  weekly;

  /// The wall-clock span this window covers.
  Duration get duration => switch (this) {
    QuotaWindow.fiveHour => const Duration(hours: 5),
    QuotaWindow.daily => const Duration(hours: 24),
    QuotaWindow.weekly => const Duration(days: 7),
  };

  /// A short human-readable label for the window.
  String get label => switch (this) {
    QuotaWindow.fiveHour => '5h',
    QuotaWindow.daily => 'Daily',
    QuotaWindow.weekly => 'Weekly',
  };
}

/// A user-configured usage ceiling for one provider, window, and metric.
///
/// The [provider] is matched against [AgentRunLog.adapter] case-insensitively;
/// the sentinel values `all` and `*` match every run regardless of adapter.
class QuotaLimit {
  /// Creates a [QuotaLimit].
  const QuotaLimit({
    required this.provider,
    required this.window,
    required this.unit,
    required this.limit,
  });

  /// Provider (adapter) this limit applies to, or `all` / `*` for every run.
  final String provider;

  /// Rolling window the limit is enforced over.
  final QuotaWindow window;

  /// Metric the [limit] is denominated in.
  final QuotaUnit unit;

  /// The configured ceiling, in [unit]s.
  final int limit;

  /// Whether this limit applies to runs from every provider.
  bool get matchesAllProviders {
    final p = provider.trim().toLowerCase();
    return p == 'all' || p == '*';
  }

  /// Whether [adapter] (an [AgentRunLog.adapter]) falls under this limit.
  bool matchesProvider(String? adapter) {
    if (matchesAllProviders) {
      return true;
    }
    if (adapter == null) {
      return false;
    }
    return adapter.toLowerCase() == provider.toLowerCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuotaLimit &&
          provider == other.provider &&
          window == other.window &&
          unit == other.unit &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(provider, window, unit, limit);
}

/// A computed snapshot of usage for one provider/window/metric.
class QuotaUsageReport {
  /// Creates a [QuotaUsageReport].
  const QuotaUsageReport({
    required this.provider,
    required this.window,
    required this.unit,
    required this.used,
    required this.limit,
    required this.windowStart,
    required this.resetsAt,
  });

  /// Provider (or `all` / `*`) this report covers.
  final String provider;

  /// Rolling window the usage was summed over.
  final QuotaWindow window;

  /// Metric [used] is denominated in.
  final QuotaUnit unit;

  /// Observed usage within the window, in [unit]s.
  final int used;

  /// Configured ceiling, in [unit]s, or null if none is set.
  final int? limit;

  /// Inclusive lower bound of the window (`now - window.duration`).
  final DateTime windowStart;

  /// When the window's oldest in-window run ages out and capacity frees up.
  final DateTime resetsAt;

  /// Fraction of the limit consumed (`used / limit`), or null when there is no
  /// usable limit (null or zero).
  double? get fraction {
    final l = limit;
    if (l == null || l <= 0) {
      return null;
    }
    return used / l;
  }

  /// Health of the quota given [fraction].
  QuotaStatus get status {
    final f = fraction;
    if (f == null) {
      return QuotaStatus.unknown;
    }
    if (f >= 1.0) {
      return QuotaStatus.exhausted;
    }
    if (f >= 0.8) {
      return QuotaStatus.warning;
    }
    return QuotaStatus.ok;
  }

  /// Time remaining until [resetsAt] from [now], clamped to be non-negative.
  Duration resetsIn(DateTime now) {
    final remaining = resetsAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuotaUsageReport &&
          provider == other.provider &&
          window == other.window &&
          unit == other.unit &&
          used == other.used &&
          limit == other.limit &&
          windowStart == other.windowStart &&
          resetsAt == other.resetsAt;

  @override
  int get hashCode =>
      Object.hash(provider, window, unit, used, limit, windowStart, resetsAt);
}

/// Computes [QuotaUsageReport]s from observed agent run logs.
///
/// Usage is derived entirely from [AgentRunLog]s; limits come from
/// user-configured [QuotaLimit]s.
class QuotaCalculator {
  /// Creates a [QuotaCalculator].
  const QuotaCalculator();

  /// Severity ordering used to sort reports — most urgent first.
  static int _severity(QuotaStatus status) => switch (status) {
    QuotaStatus.exhausted => 0,
    QuotaStatus.warning => 1,
    QuotaStatus.ok => 2,
    QuotaStatus.unknown => 3,
  };

  /// Extracts the metric [unit] contributes for a single run.
  static int _metricFor(AgentRunLog run, QuotaUnit unit) => switch (unit) {
    QuotaUnit.tokens => run.cost.totalTokens,
    QuotaUnit.requests => 1,
    QuotaUnit.costCents => run.cost.estimatedCostCents,
  };

  /// Builds a [QuotaUsageReport] for [limit] from [runs] evaluated at [now].
  ///
  /// Only runs whose [AgentRunLog.startedAt] is at or after the window start
  /// (`now - limit.window.duration`) and whose adapter matches the limit's
  /// provider contribute. `used` is the summed metric for [QuotaLimit.unit].
  /// `resetsAt` is the oldest in-window run's `startedAt` plus the window
  /// duration, or `now + window.duration` when no run falls in the window.
  QuotaUsageReport report({
    required Iterable<AgentRunLog> runs,
    required DateTime now,
    required QuotaLimit limit,
  }) {
    final windowDuration = limit.window.duration;
    final windowStart = now.subtract(windowDuration);

    var used = 0;
    DateTime? oldestInWindow;
    for (final run in runs) {
      if (run.startedAt.isBefore(windowStart)) {
        continue;
      }
      if (!limit.matchesProvider(run.adapter)) {
        continue;
      }
      used += _metricFor(run, limit.unit);
      if (oldestInWindow == null || run.startedAt.isBefore(oldestInWindow)) {
        oldestInWindow = run.startedAt;
      }
    }

    final resetsAt = oldestInWindow == null
        ? now.add(windowDuration)
        : oldestInWindow.add(windowDuration);

    return QuotaUsageReport(
      provider: limit.provider,
      window: limit.window,
      unit: limit.unit,
      used: used,
      limit: limit.limit,
      windowStart: windowStart,
      resetsAt: resetsAt,
    );
  }

  /// Builds one [QuotaUsageReport] per configured limit in [limits], sorted by
  /// status severity (exhausted first) and then provider name.
  List<QuotaUsageReport> reportAll({
    required Iterable<AgentRunLog> runs,
    required DateTime now,
    required Iterable<QuotaLimit> limits,
  }) {
    final runList = runs.toList(growable: false);
    final reports = [
      for (final limit in limits) report(runs: runList, now: now, limit: limit),
    ];
    reports.sort((a, b) {
      final bySeverity = _severity(a.status).compareTo(_severity(b.status));
      if (bySeverity != 0) {
        return bySeverity;
      }
      return a.provider.toLowerCase().compareTo(b.provider.toLowerCase());
    });
    return reports;
  }
}
