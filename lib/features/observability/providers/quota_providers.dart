import 'dart:convert';

import 'package:cc_domain/features/observability/domain/quota.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/observability/providers/observability_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Quota dashboard providers (PRD 06, feature #4) ───────────────────────────
//
// CC has no provider-usage API, so USAGE is computed from run logs (rolling
// 5h / daily / weekly windows) and LIMITS are user-configured (persisted in
// non-sensitive shared preferences). When a limit is set the report shows a
// percentage + status (ok / warning / exhausted) and reset countdown; without
// one it still shows raw usage for the window.

/// The pure-domain quota calculator.
final quotaCalculatorProvider = Provider<QuotaCalculator>(
  (ref) => const QuotaCalculator(),
);

const _quotaLimitsKey = 'observability_quota_limits_v1';

/// User-configured provider quota limits, persisted across launches.
class QuotaLimitsNotifier extends Notifier<List<QuotaLimit>> {
  @override
  List<QuotaLimit> build() {
    final raw = ref.watch(appPreferencesProvider).getString(_quotaLimitsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(_fromJson).whereType<QuotaLimit>().toList();
    } on Object {
      return const [];
    }
  }

  /// Adds or replaces the limit for [limit]'s (provider, window, unit) key.
  Future<void> upsert(QuotaLimit limit) async {
    final next = [
      for (final l in state)
        if (!(l.provider == limit.provider &&
            l.window == limit.window &&
            l.unit == limit.unit))
          l,
      limit,
    ];
    await _persist(next);
  }

  /// Removes [limit].
  Future<void> remove(QuotaLimit limit) async {
    await _persist(state.where((l) => l != limit).toList());
  }

  Future<void> _persist(List<QuotaLimit> limits) async {
    state = limits;
    await ref
        .read(appPreferencesProvider)
        .setString(_quotaLimitsKey, jsonEncode(limits.map(_toJson).toList()));
  }

  static Map<String, dynamic> _toJson(QuotaLimit l) => {
    'provider': l.provider,
    'window': l.window.name,
    'unit': l.unit.name,
    'limit': l.limit,
  };

  static QuotaLimit? _fromJson(Map<String, dynamic> j) {
    final window = QuotaWindow.values
        .where((w) => w.name == j['window'])
        .firstOrNull;
    final unit = QuotaUnit.values.where((u) => u.name == j['unit']).firstOrNull;
    if (window == null || unit == null) {
      return null;
    }
    return QuotaLimit(
      provider: j['provider'] as String? ?? 'all',
      window: window,
      unit: unit,
      limit: (j['limit'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The configured quota limits (editable in the Quota tab).
final quotaLimitsProvider =
    NotifierProvider<QuotaLimitsNotifier, List<QuotaLimit>>(
      QuotaLimitsNotifier.new,
    );

/// Reports for the user-configured limits, worst-status first. Empty when no
/// limits are configured.
final configuredQuotaReportsProvider =
    Provider.autoDispose<List<QuotaUsageReport>>((ref) {
      final limits = ref.watch(quotaLimitsProvider);
      if (limits.isEmpty) {
        return const [];
      }
      final runs = ref.watch(workspaceRunLogsProvider);
      return ref
          .watch(quotaCalculatorProvider)
          .reportAll(runs: runs, now: DateTime.now(), limits: limits);
    });

/// Always-on usage windows (no configured limit) so the dashboard shows real
/// usage out of the box: tokens, requests and cost across the 5h / daily /
/// weekly windows for all providers combined.
final quotaUsageWindowsProvider = Provider.autoDispose<List<QuotaUsageReport>>((
  ref,
) {
  final runs = ref.watch(workspaceRunLogsProvider);
  final calc = ref.watch(quotaCalculatorProvider);
  final now = DateTime.now();
  final reports = <QuotaUsageReport>[];
  for (final window in QuotaWindow.values) {
    for (final unit in QuotaUnit.values) {
      reports.add(
        calc.report(
          runs: runs,
          now: now,
          limit: QuotaLimit(
            provider: 'all',
            window: window,
            unit: unit,
            // Sentinel 0 limit ⇒ the report's fraction/status read as unknown;
            // these rows are usage-only context, not a ceiling.
            limit: 0,
          ),
        ),
      );
    }
  }
  return reports;
});
