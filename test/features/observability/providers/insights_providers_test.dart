import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/observability/domain/observability_metrics.dart';
import 'package:control_center/features/observability/providers/insights_providers.dart';
import 'package:flutter_test/flutter_test.dart';

AgentRunLog _run({
  required String id,
  required String agentId,
  required DateTime startedAt,
  RunStatus status = RunStatus.completed,
  String? modelId,
  String? adapter,
  AgentRunRole role = AgentRunRole.main,
  RunCost? cost,
}) {
  return AgentRunLog(
    id: id,
    agentId: agentId,
    startedAt: startedAt,
    status: status,
    modelId: modelId,
    adapter: adapter,
    role: role,
    cost: cost,
  );
}

void main() {
  final now = DateTime(2026, 7, 28, 15, 30);

  group('obsRangeStart', () {
    test('subtracts the window; all time is unbounded', () {
      expect(
        obsRangeStart(ObsTimeRange.last24h, now),
        now.subtract(const Duration(hours: 24)),
      );
      expect(
        obsRangeStart(ObsTimeRange.last7d, now),
        now.subtract(const Duration(days: 7)),
      );
      expect(
        obsRangeStart(ObsTimeRange.last30d, now),
        now.subtract(const Duration(days: 30)),
      );
      expect(obsRangeStart(ObsTimeRange.all, now), isNull);
    });
  });

  group('filterRunLogs', () {
    test('a run exactly at the range boundary is included', () {
      final start = now.subtract(const Duration(hours: 24));
      final boundary = _run(id: 'r1', agentId: 'a', startedAt: start);
      final inside = _run(
        id: 'r2',
        agentId: 'a',
        startedAt: start.add(const Duration(seconds: 1)),
      );
      final outside = _run(
        id: 'r3',
        agentId: 'a',
        startedAt: start.subtract(const Duration(seconds: 1)),
      );
      final result = filterRunLogs(
        [boundary, inside, outside],
        start: start,
        filters: const ObsRunFilters(),
      );
      expect(result.map((r) => r.id), ['r1', 'r2']);
    });

    test('null start and empty filters pass every run', () {
      final runs = [
        _run(id: 'r1', agentId: 'a', startedAt: DateTime(2020)),
        _run(id: 'r2', agentId: 'b', startedAt: now),
      ];
      final result = filterRunLogs(
        runs,
        start: null,
        filters: const ObsRunFilters(),
      );
      expect(result, hasLength(2));
    });

    test('two selected agents OR together', () {
      final runs = [
        _run(id: 'r1', agentId: 'a', startedAt: now),
        _run(id: 'r2', agentId: 'b', startedAt: now),
        _run(id: 'r3', agentId: 'c', startedAt: now),
      ];
      final result = filterRunLogs(
        runs,
        filters: const ObsRunFilters(agentIds: {'a', 'b'}),
      );
      expect(result.map((r) => r.id), ['r1', 'r2']);
    });

    test('agent AND status across categories', () {
      final runs = [
        _run(id: 'r1', agentId: 'a', startedAt: now),
        _run(id: 'r2', agentId: 'a', startedAt: now, status: RunStatus.error),
        _run(id: 'r3', agentId: 'b', startedAt: now, status: RunStatus.error),
      ];
      final result = filterRunLogs(
        runs,
        filters: const ObsRunFilters(
          agentIds: {'a'},
          statuses: {RunStatus.error},
        ),
      );
      expect(result.map((r) => r.id), ['r2']);
    });

    test('model key falls back to adapter then empty string', () {
      final runs = [
        _run(id: 'r1', agentId: 'a', startedAt: now, modelId: 'opus'),
        _run(id: 'r2', agentId: 'a', startedAt: now, adapter: 'claude'),
        _run(id: 'r3', agentId: 'a', startedAt: now),
      ];
      expect(
        filterRunLogs(
          runs,
          filters: const ObsRunFilters(modelKeys: {'opus'}),
        ).map((r) => r.id),
        ['r1'],
      );
      expect(
        filterRunLogs(
          runs,
          filters: const ObsRunFilters(modelKeys: {'claude'}),
        ).map((r) => r.id),
        ['r2'],
      );
      expect(
        filterRunLogs(
          runs,
          filters: const ObsRunFilters(modelKeys: {''}),
        ).map((r) => r.id),
        ['r3'],
      );
    });

    test('role facet narrows runs', () {
      final runs = [
        _run(id: 'r1', agentId: 'a', startedAt: now),
        _run(
          id: 'r2',
          agentId: 'a',
          startedAt: now,
          role: AgentRunRole.advisor,
        ),
      ];
      final result = filterRunLogs(
        runs,
        filters: const ObsRunFilters(roles: {AgentRunRole.advisor}),
      );
      expect(result.map((r) => r.id), ['r2']);
    });
  });

  group('foldToWeekly', () {
    test('floors to Monday and sums every field', () {
      // 2026-07-27 is a Monday; 2026-07-29 a Wednesday of the same week.
      final monday = DateTime(2026, 7, 27);
      final wednesday = DateTime(2026, 7, 29);
      final nextWeek = DateTime(2026, 8, 3);
      final folded = foldToWeekly([
        TimeBucket(
          bucketStart: monday,
          runs: 2,
          errors: 1,
          tokens: 100,
          costCents: 50,
        ),
        TimeBucket(
          bucketStart: wednesday,
          runs: 3,
          errors: 0,
          tokens: 200,
          costCents: 70,
        ),
        TimeBucket(
          bucketStart: nextWeek,
          runs: 1,
          errors: 1,
          tokens: 50,
          costCents: 10,
        ),
      ]);
      expect(folded, hasLength(2));
      expect(folded[0].bucketStart, DateTime(2026, 7, 27));
      expect(folded[0].runs, 5);
      expect(folded[0].errors, 1);
      expect(folded[0].tokens, 300);
      expect(folded[0].costCents, 120);
      expect(folded[1].bucketStart, DateTime(2026, 8, 3));
      expect(folded[1].runs, 1);
    });
  });

  group('bucketizeSeries', () {
    const calc = ObservabilityMetricsCalculator();

    test('last 24h buckets hourly', () {
      final result = bucketizeSeries(
        [_run(id: 'r1', agentId: 'a', startedAt: now)],
        ObsTimeRange.last24h,
        calc,
      );
      expect(result.kind, ObsBucketKind.hour);
      expect(result.buckets, hasLength(1));
      expect(result.buckets.single.bucketStart, DateTime(2026, 7, 28, 15));
    });

    test('last 7d buckets daily', () {
      final result = bucketizeSeries(
        [_run(id: 'r1', agentId: 'a', startedAt: now)],
        ObsTimeRange.last7d,
        calc,
      );
      expect(result.kind, ObsBucketKind.day);
      expect(result.buckets.single.bucketStart, DateTime(2026, 7, 28));
    });

    test('last 30d buckets daily', () {
      final result = bucketizeSeries(
        [_run(id: 'r1', agentId: 'a', startedAt: now)],
        ObsTimeRange.last30d,
        calc,
      );
      expect(result.kind, ObsBucketKind.day);
    });

    test('all time folds to weekly beyond 62 days, preserving totals', () {
      // 90 consecutive days of one run each, starting on a Monday.
      final start = DateTime(2026, 4, 27); // a Monday
      final runs = [
        for (var i = 0; i < 90; i++)
          _run(
            id: 'r$i',
            agentId: 'a',
            startedAt: start.add(Duration(days: i, hours: 12)),
            cost: const RunCost(estimatedCostCents: 10, outputTokens: 100),
          ),
      ];
      final result = bucketizeSeries(runs, ObsTimeRange.all, calc);
      expect(result.kind, ObsBucketKind.week);
      expect(result.buckets.length, closeTo(13, 1));
      expect(result.buckets.fold<int>(0, (sum, b) => sum + b.costCents), 900);
      expect(result.buckets.fold<int>(0, (sum, b) => sum + b.runs), 90);
    });

    test('all time with a short history stays daily', () {
      final runs = [
        for (var i = 0; i < 10; i++)
          _run(
            id: 'r$i',
            agentId: 'a',
            startedAt: now.subtract(Duration(days: i)),
          ),
      ];
      final result = bucketizeSeries(runs, ObsTimeRange.all, calc);
      expect(result.kind, ObsBucketKind.day);
      expect(result.buckets, hasLength(10));
    });
  });

  group('ObsRunFilters', () {
    test('equality is set-based, not order-based', () {
      const a = ObsRunFilters(agentIds: {'x', 'y'});
      final b = const ObsRunFilters(
        agentIds: {'x'},
      ).copyWith(agentIds: {'y', 'x'});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('isEmpty only when every facet is empty', () {
      expect(const ObsRunFilters().isEmpty, isTrue);
      expect(const ObsRunFilters(agentIds: {'a'}).isEmpty, isFalse);
      expect(const ObsRunFilters(statuses: {RunStatus.error}).isEmpty, isFalse);
    });
  });
}
