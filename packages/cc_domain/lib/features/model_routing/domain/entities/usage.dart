// ignore_for_file: avoid_classes_with_only_static_members

import 'package:collection/collection.dart';

/// Health of a usage limit.
enum UsageStatus {
  /// Plenty of headroom.
  ok,

  /// Approaching the limit.
  warning,

  /// At / over the limit.
  exhausted;

  /// Parses a status string; null for unknown.
  static UsageStatus? fromRaw(String? raw) => switch (raw) {
    'ok' => UsageStatus.ok,
    'warning' => UsageStatus.warning,
    'exhausted' => UsageStatus.exhausted,
    _ => null,
  };

  /// The wire string.
  String get id => name;
}

/// The unit a usage amount is measured in.
enum UsageUnit {
  /// 0–100 percent.
  percent,

  /// Token counts.
  tokens,

  /// Request counts.
  requests,

  /// US dollars.
  usd,

  /// Unknown / opaque unit.
  unknown;

  /// Parses a unit string; [unknown] for unrecognized.
  static UsageUnit fromRaw(String? raw) => switch (raw) {
    'percent' => UsageUnit.percent,
    'tokens' => UsageUnit.tokens,
    'requests' => UsageUnit.requests,
    'usd' => UsageUnit.usd,
    _ => UsageUnit.unknown,
  };
}

/// A rolling limit window (e.g. 5h / 7d / monthly).
class UsageWindow {
  /// Creates a [UsageWindow].
  const UsageWindow({
    required this.id,
    required this.label,
    this.durationMs,
    this.resetsAt,
  });

  /// Stable window id (`5h`, `7d`, `monthly`).
  final String id;

  /// Display label (e.g. `5 hour`).
  final String label;

  /// Window length in ms (for drain-rate maths).
  final int? durationMs;

  /// When the window next resets.
  final DateTime? resetsAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageWindow &&
          id == other.id &&
          label == other.label &&
          durationMs == other.durationMs &&
          resetsAt == other.resetsAt;

  @override
  int get hashCode => Object.hash(id, label, durationMs, resetsAt);
}

/// The quantitative part of a usage limit.
class UsageAmount {
  /// Creates a [UsageAmount].
  const UsageAmount({
    this.used,
    this.limit,
    this.remaining,
    this.usedFraction,
    this.remainingFraction,
    this.unit = UsageUnit.unknown,
  });

  /// Units consumed.
  final num? used;

  /// Total allowance.
  final num? limit;

  /// Units remaining.
  final num? remaining;

  /// Normalized used fraction [0..1] (preferred when present).
  final double? usedFraction;

  /// Normalized remaining fraction [0..1].
  final double? remainingFraction;

  /// The unit.
  final UsageUnit unit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageAmount &&
          used == other.used &&
          limit == other.limit &&
          remaining == other.remaining &&
          usedFraction == other.usedFraction &&
          remainingFraction == other.remainingFraction &&
          unit == other.unit;

  @override
  int get hashCode => Object.hash(
    used,
    limit,
    remaining,
    usedFraction,
    remainingFraction,
    unit,
  );
}

/// Who / what a limit applies to.
class UsageScope {
  /// Creates a [UsageScope].
  const UsageScope({
    required this.provider,
    this.accountId,
    this.projectId,
    this.orgId,
    this.modelId,
    this.tier,
    this.shared = false,
  });

  /// Provider id.
  final String provider;

  /// Account id, if account-scoped.
  final String? accountId;

  /// Project id (GCP-style), if applicable.
  final String? projectId;

  /// Organization id, if applicable.
  final String? orgId;

  /// Model id, if model-tier-scoped.
  final String? modelId;

  /// Pricing tier, if applicable.
  final String? tier;

  /// Whether the limit is shared across the org/accounts.
  final bool shared;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageScope &&
          provider == other.provider &&
          accountId == other.accountId &&
          projectId == other.projectId &&
          orgId == other.orgId &&
          modelId == other.modelId &&
          tier == other.tier &&
          shared == other.shared;

  @override
  int get hashCode =>
      Object.hash(provider, accountId, projectId, orgId, modelId, tier, shared);
}

/// One limit entry: one window of one scope.
class UsageLimit {
  /// Creates a [UsageLimit].
  const UsageLimit({
    required this.id,
    required this.label,
    required this.scope,
    required this.amount,
    this.window,
    this.status,
    this.notes = const [],
  });

  /// Stable identifier.
  final String id;

  /// Display label.
  final String label;

  /// Scope (provider/account/model).
  final UsageScope scope;

  /// The window this limit covers, if any.
  final UsageWindow? window;

  /// The amount data.
  final UsageAmount amount;

  /// Pre-resolved status, if the provider reported one.
  final UsageStatus? status;

  /// Free-form notes.
  final List<String> notes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageLimit &&
          id == other.id &&
          label == other.label &&
          scope == other.scope &&
          window == other.window &&
          amount == other.amount &&
          status == other.status &&
          const ListEquality<String>().equals(notes, other.notes);

  @override
  int get hashCode => Object.hash(
    id,
    label,
    scope,
    window,
    amount,
    status,
    const ListEquality<String>().hash(notes),
  );
}

/// An aggregated usage report for one provider+account, as of [fetchedAt].
class UsageReport {
  /// Creates a [UsageReport].
  const UsageReport({
    required this.provider,
    required this.fetchedAt,
    this.limits = const [],
    this.notes = const [],
  });

  /// Provider id.
  final String provider;

  /// When the report was fetched.
  final DateTime fetchedAt;

  /// All limit windows.
  final List<UsageLimit> limits;

  /// Provider-wide disclaimers.
  final List<String> notes;
}

/// An observed per-request cost (for providers without a usage API).
class UsageCostHistoryEntry {
  /// Creates a [UsageCostHistoryEntry].
  const UsageCostHistoryEntry({
    required this.recordedAt,
    required this.provider,
    required this.accountKey,
    required this.costUsd,
    this.modelId,
  });

  /// When the request happened.
  final DateTime recordedAt;

  /// Provider id.
  final String provider;

  /// Stable credential identity.
  final String accountKey;

  /// Estimated USD cost of the request.
  final double costUsd;

  /// Model id, if known.
  final String? modelId;
}

/// Pure helpers over usage data (status / fraction resolution).
abstract final class UsageMath {
  /// Resolves a used fraction from a limit, trying the most reliable signal
  /// first. The result is NOT
  /// clamped to 1.0 — an over-limit window (e.g. 1.2) keeps its overage so it
  /// ranks strictly worse than a window sitting exactly at the cap. Only the
  /// remaining-fraction path floors at 0 (a remaining > 1 would be nonsensical).
  static double? usedFraction(UsageLimit limit) {
    final a = limit.amount;
    if (a.usedFraction != null) {
      return a.usedFraction!.toDouble();
    }
    if (a.used != null && a.limit != null && a.limit! > 0) {
      return a.used! / a.limit!;
    }
    if (a.unit == UsageUnit.percent && a.used != null) {
      return a.used! / 100;
    }
    if (a.remainingFraction != null) {
      final used = 1 - a.remainingFraction!;
      return used < 0 ? 0.0 : used;
    }
    return null;
  }

  /// Whether a single limit is exhausted.
  static bool isExhausted(UsageLimit limit) {
    if (limit.status == UsageStatus.exhausted) {
      return true;
    }
    final a = limit.amount;
    if (a.remaining != null && a.remaining! <= 0) {
      return true;
    }
    if (a.used != null && a.limit != null && a.used! >= a.limit!) {
      return true;
    }
    final f = usedFraction(limit);
    return f != null && f >= 1.0;
  }

  /// Whether any limit in [limits] is exhausted.
  static bool anyExhausted(Iterable<UsageLimit> limits) =>
      limits.any(isExhausted);

  /// The earliest reset time among [limits] (when the soonest window frees up),
  /// or null if none have a reset time.
  static DateTime? earliestReset(Iterable<UsageLimit> limits) {
    DateTime? best;
    for (final l in limits) {
      final r = l.window?.resetsAt;
      if (r != null && (best == null || r.isBefore(best))) {
        best = r;
      }
    }
    return best;
  }
}
