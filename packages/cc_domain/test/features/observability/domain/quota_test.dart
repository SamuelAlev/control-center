import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/observability/domain/quota.dart';
import 'package:test/test.dart';

/// A fixed clock reference for deterministic window math.
final DateTime _now = DateTime.utc(2026, 6, 29, 12);

int _runSeq = 0;

AgentRunLog _run({
  required DateTime startedAt,
  String? adapter,
  int inputTokens = 0,
  int outputTokens = 0,
  int thoughtTokens = 0,
  int cachedReadTokens = 0,
  int cachedWriteTokens = 0,
  int costCents = 0,
}) {
  _runSeq++;
  return AgentRunLog(
    id: 'run-$_runSeq',
    agentId: 'agent-1',
    startedAt: startedAt,
    status: RunStatus.completed,
    adapter: adapter,
    cost: RunCost(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      thoughtTokens: thoughtTokens,
      cachedReadTokens: cachedReadTokens,
      cachedWriteTokens: cachedWriteTokens,
      estimatedCostCents: costCents,
    ),
  );
}

void main() {
  const calc = QuotaCalculator();

  group('QuotaWindow', () {
    test('durations are 5h / 24h / 7d', () {
      expect(QuotaWindow.fiveHour.duration, const Duration(hours: 5));
      expect(QuotaWindow.daily.duration, const Duration(hours: 24));
      expect(QuotaWindow.weekly.duration, const Duration(days: 7));
    });

    test('labels are distinct and non-empty', () {
      final labels = QuotaWindow.values.map((w) => w.label).toSet();
      expect(labels.length, QuotaWindow.values.length);
      expect(labels.any((l) => l.isEmpty), isFalse);
    });
  });

  group('QuotaUsageReport.fraction & status thresholds', () {
    QuotaUsageReport reportWith({required int used, int? limit}) =>
        QuotaUsageReport(
          provider: 'anthropic',
          window: QuotaWindow.daily,
          unit: QuotaUnit.tokens,
          used: used,
          limit: limit,
          windowStart: _now.subtract(const Duration(hours: 24)),
          resetsAt: _now,
        );

    test('null limit -> fraction null, status unknown', () {
      final r = reportWith(used: 50, limit: null);
      expect(r.fraction, isNull);
      expect(r.status, QuotaStatus.unknown);
    });

    test('zero limit -> fraction null, status unknown', () {
      final r = reportWith(used: 50, limit: 0);
      expect(r.fraction, isNull);
      expect(r.status, QuotaStatus.unknown);
    });

    test('negative limit treated as no usable limit -> unknown', () {
      final r = reportWith(used: 50, limit: -10);
      expect(r.fraction, isNull);
      expect(r.status, QuotaStatus.unknown);
    });

    test('0.79 -> ok (just below warning)', () {
      final r = reportWith(used: 79, limit: 100);
      expect(r.fraction, closeTo(0.79, 1e-9));
      expect(r.status, QuotaStatus.ok);
    });

    test('exactly 0.8 -> warning (inclusive boundary)', () {
      final r = reportWith(used: 80, limit: 100);
      expect(r.fraction, closeTo(0.8, 1e-9));
      expect(r.status, QuotaStatus.warning);
    });

    test('between 0.8 and 1.0 -> warning', () {
      final r = reportWith(used: 95, limit: 100);
      expect(r.status, QuotaStatus.warning);
    });

    test('just below 1.0 -> warning', () {
      final r = reportWith(used: 99, limit: 100);
      expect(r.status, QuotaStatus.warning);
    });

    test('exactly 1.0 -> exhausted (inclusive boundary)', () {
      final r = reportWith(used: 100, limit: 100);
      expect(r.fraction, closeTo(1.0, 1e-9));
      expect(r.status, QuotaStatus.exhausted);
    });

    test('over 1.0 -> exhausted', () {
      final r = reportWith(used: 250, limit: 100);
      expect(r.fraction, closeTo(2.5, 1e-9));
      expect(r.status, QuotaStatus.exhausted);
    });

    test('zero usage with a limit -> ok', () {
      final r = reportWith(used: 0, limit: 100);
      expect(r.fraction, 0.0);
      expect(r.status, QuotaStatus.ok);
    });
  });

  group('QuotaUsageReport.resetsIn', () {
    test('positive time remaining returned as-is', () {
      final r = QuotaUsageReport(
        provider: 'anthropic',
        window: QuotaWindow.fiveHour,
        unit: QuotaUnit.requests,
        used: 1,
        limit: 10,
        windowStart: _now.subtract(const Duration(hours: 5)),
        resetsAt: _now.add(const Duration(minutes: 40)),
      );
      expect(r.resetsIn(_now), const Duration(minutes: 40));
    });

    test('past reset clamps to zero (never negative)', () {
      final r = QuotaUsageReport(
        provider: 'anthropic',
        window: QuotaWindow.fiveHour,
        unit: QuotaUnit.requests,
        used: 1,
        limit: 10,
        windowStart: _now.subtract(const Duration(hours: 5)),
        resetsAt: _now.subtract(const Duration(minutes: 10)),
      );
      expect(r.resetsIn(_now), Duration.zero);
    });

    test('exactly now -> zero', () {
      final r = QuotaUsageReport(
        provider: 'anthropic',
        window: QuotaWindow.daily,
        unit: QuotaUnit.tokens,
        used: 0,
        limit: 10,
        windowStart: _now.subtract(const Duration(hours: 24)),
        resetsAt: _now,
      );
      expect(r.resetsIn(_now), Duration.zero);
    });
  });

  group('QuotaCalculator.report — metric counting', () {
    test('tokens unit sums all five token axes', () {
      final runs = [
        _run(
          startedAt: _now.subtract(const Duration(hours: 1)),
          adapter: 'anthropic',
          inputTokens: 10,
          outputTokens: 20,
          thoughtTokens: 5,
          cachedReadTokens: 3,
          cachedWriteTokens: 2,
          costCents: 999, // must be ignored for tokens unit
        ),
      ];
      final r = calc.report(
        runs: runs,
        now: _now,
        limit: const QuotaLimit(
          provider: 'anthropic',
          window: QuotaWindow.daily,
          unit: QuotaUnit.tokens,
          limit: 1000,
        ),
      );
      expect(r.used, 40); // 10+20+5+3+2
    });

    test('requests unit counts runs regardless of tokens/cost', () {
      final runs = [
        _run(
          startedAt: _now.subtract(const Duration(hours: 1)),
          adapter: 'anthropic',
          inputTokens: 5000,
          costCents: 5000,
        ),
        _run(
          startedAt: _now.subtract(const Duration(hours: 2)),
          adapter: 'anthropic',
        ),
        _run(
          startedAt: _now.subtract(const Duration(hours: 3)),
          adapter: 'anthropic',
        ),
      ];
      final r = calc.report(
        runs: runs,
        now: _now,
        limit: const QuotaLimit(
          provider: 'anthropic',
          window: QuotaWindow.daily,
          unit: QuotaUnit.requests,
          limit: 100,
        ),
      );
      expect(r.used, 3);
    });

    test('costCents unit sums estimatedCostCents only', () {
      final runs = [
        _run(
          startedAt: _now.subtract(const Duration(hours: 1)),
          adapter: 'anthropic',
          inputTokens: 9999, // ignored for cost unit
          costCents: 120,
        ),
        _run(
          startedAt: _now.subtract(const Duration(hours: 2)),
          adapter: 'anthropic',
          costCents: 80,
        ),
      ];
      final r = calc.report(
        runs: runs,
        now: _now,
        limit: const QuotaLimit(
          provider: 'anthropic',
          window: QuotaWindow.daily,
          unit: QuotaUnit.costCents,
          limit: 500,
        ),
      );
      expect(r.used, 200);
    });
  });

  group('QuotaCalculator.report — window filtering', () {
    test('runs before windowStart are excluded; in-window included', () {
      const limit = QuotaLimit(
        provider: 'anthropic',
        window: QuotaWindow.fiveHour,
        unit: QuotaUnit.requests,
        limit: 100,
      );
      final runs = [
        // Outside the 5h window (6h ago) -> excluded.
        _run(
          startedAt: _now.subtract(const Duration(hours: 6)),
          adapter: 'anthropic',
        ),
        // Inside (4h ago) -> included.
        _run(
          startedAt: _now.subtract(const Duration(hours: 4)),
          adapter: 'anthropic',
        ),
        // Inside (1h ago) -> included.
        _run(
          startedAt: _now.subtract(const Duration(hours: 1)),
          adapter: 'anthropic',
        ),
      ];
      final r = calc.report(runs: runs, now: _now, limit: limit);
      expect(r.used, 2);
      expect(r.windowStart, _now.subtract(const Duration(hours: 5)));
    });

    test('a run exactly at windowStart is included (>= boundary)', () {
      const limit = QuotaLimit(
        provider: 'anthropic',
        window: QuotaWindow.fiveHour,
        unit: QuotaUnit.requests,
        limit: 100,
      );
      final runs = [
        _run(
          startedAt: _now.subtract(const Duration(hours: 5)),
          adapter: 'anthropic',
        ),
      ];
      final r = calc.report(runs: runs, now: _now, limit: limit);
      expect(r.used, 1);
    });

    test('a run one microsecond before windowStart is excluded', () {
      const limit = QuotaLimit(
        provider: 'anthropic',
        window: QuotaWindow.fiveHour,
        unit: QuotaUnit.requests,
        limit: 100,
      );
      final runs = [
        _run(
          startedAt: _now
              .subtract(const Duration(hours: 5))
              .subtract(const Duration(microseconds: 1)),
          adapter: 'anthropic',
        ),
      ];
      final r = calc.report(runs: runs, now: _now, limit: limit);
      expect(r.used, 0);
    });
  });

  group('QuotaCalculator.report — provider matching', () {
    test('matches adapter case-insensitively', () {
      const limit = QuotaLimit(
        provider: 'Anthropic',
        window: QuotaWindow.daily,
        unit: QuotaUnit.requests,
        limit: 100,
      );
      final runs = [
        _run(
          startedAt: _now.subtract(const Duration(hours: 1)),
          adapter: 'anthropic',
        ),
        _run(
          startedAt: _now.subtract(const Duration(hours: 2)),
          adapter: 'ANTHROPIC',
        ),
        // Different provider -> excluded.
        _run(
          startedAt: _now.subtract(const Duration(hours: 3)),
          adapter: 'openai',
        ),
      ];
      final r = calc.report(runs: runs, now: _now, limit: limit);
      expect(r.used, 2);
    });

    test("provider 'all' matches every run including null adapters", () {
      const limit = QuotaLimit(
        provider: 'all',
        window: QuotaWindow.daily,
        unit: QuotaUnit.requests,
        limit: 100,
      );
      final runs = [
        _run(
          startedAt: _now.subtract(const Duration(hours: 1)),
          adapter: 'anthropic',
        ),
        _run(
          startedAt: _now.subtract(const Duration(hours: 2)),
          adapter: 'openai',
        ),
        _run(startedAt: _now.subtract(const Duration(hours: 3))),
      ];
      final r = calc.report(runs: runs, now: _now, limit: limit);
      expect(r.used, 3);
    });

    test("provider '*' wildcard matches every run", () {
      const limit = QuotaLimit(
        provider: '*',
        window: QuotaWindow.daily,
        unit: QuotaUnit.requests,
        limit: 100,
      );
      final runs = [
        _run(
          startedAt: _now.subtract(const Duration(hours: 1)),
          adapter: 'anthropic',
        ),
        _run(
          startedAt: _now.subtract(const Duration(hours: 2)),
          adapter: 'google',
        ),
      ];
      final r = calc.report(runs: runs, now: _now, limit: limit);
      expect(r.used, 2);
    });

    test('null adapter does not match a concrete provider', () {
      const limit = QuotaLimit(
        provider: 'anthropic',
        window: QuotaWindow.daily,
        unit: QuotaUnit.requests,
        limit: 100,
      );
      final runs = [_run(startedAt: _now.subtract(const Duration(hours: 1)))];
      final r = calc.report(runs: runs, now: _now, limit: limit);
      expect(r.used, 0);
    });
  });

  group('QuotaCalculator.report — resetsAt computation', () {
    test('resetsAt is oldest in-window run startedAt + window duration', () {
      const limit = QuotaLimit(
        provider: 'all',
        window: QuotaWindow.fiveHour,
        unit: QuotaUnit.requests,
        limit: 100,
      );
      final oldest = _now.subtract(const Duration(hours: 3));
      final runs = [
        _run(startedAt: _now.subtract(const Duration(hours: 1))),
        _run(startedAt: oldest),
        _run(startedAt: _now.subtract(const Duration(hours: 2))),
      ];
      final r = calc.report(runs: runs, now: _now, limit: limit);
      expect(r.resetsAt, oldest.add(const Duration(hours: 5)));
      // The oldest run is 3h old in a 5h window -> resets in 2h.
      expect(r.resetsIn(_now), const Duration(hours: 2));
    });

    test(
      'oldest matching run is used even when a newer non-match precedes it',
      () {
        const limit = QuotaLimit(
          provider: 'anthropic',
          window: QuotaWindow.fiveHour,
          unit: QuotaUnit.requests,
          limit: 100,
        );
        final oldestAnthropic = _now.subtract(const Duration(hours: 4));
        final runs = [
          // Older but a different provider -> must not drive resetsAt.
          _run(
            startedAt: _now.subtract(const Duration(hours: 4, minutes: 30)),
            adapter: 'openai',
          ),
          _run(startedAt: oldestAnthropic, adapter: 'anthropic'),
          _run(
            startedAt: _now.subtract(const Duration(hours: 1)),
            adapter: 'anthropic',
          ),
        ];
        final r = calc.report(runs: runs, now: _now, limit: limit);
        expect(r.resetsAt, oldestAnthropic.add(const Duration(hours: 5)));
      },
    );

    test('no in-window runs -> resetsAt is now + window duration', () {
      const limit = QuotaLimit(
        provider: 'anthropic',
        window: QuotaWindow.daily,
        unit: QuotaUnit.requests,
        limit: 100,
      );
      // Run exists but is outside the window.
      final runs = [
        _run(
          startedAt: _now.subtract(const Duration(days: 2)),
          adapter: 'anthropic',
        ),
      ];
      final r = calc.report(runs: runs, now: _now, limit: limit);
      expect(r.used, 0);
      expect(r.resetsAt, _now.add(const Duration(hours: 24)));
      expect(r.resetsIn(_now), const Duration(hours: 24));
    });
  });

  group('QuotaCalculator.report — empty input', () {
    test('empty runs yields zero usage and full-window reset', () {
      const limit = QuotaLimit(
        provider: 'anthropic',
        window: QuotaWindow.weekly,
        unit: QuotaUnit.tokens,
        limit: 1000,
      );
      final r = calc.report(runs: const [], now: _now, limit: limit);
      expect(r.used, 0);
      expect(r.fraction, 0.0);
      expect(r.status, QuotaStatus.ok);
      expect(r.windowStart, _now.subtract(const Duration(days: 7)));
      expect(r.resetsAt, _now.add(const Duration(days: 7)));
    });
  });

  group('QuotaCalculator.reportAll', () {
    test('returns one report per limit', () {
      final runs = [
        _run(
          startedAt: _now.subtract(const Duration(hours: 1)),
          adapter: 'anthropic',
          inputTokens: 10,
        ),
      ];
      final reports = calc.reportAll(
        runs: runs,
        now: _now,
        limits: const [
          QuotaLimit(
            provider: 'anthropic',
            window: QuotaWindow.daily,
            unit: QuotaUnit.tokens,
            limit: 1000,
          ),
          QuotaLimit(
            provider: 'openai',
            window: QuotaWindow.daily,
            unit: QuotaUnit.requests,
            limit: 50,
          ),
        ],
      );
      expect(reports, hasLength(2));
    });

    test('sorts by status severity (exhausted first), then provider', () {
      final runs = [
        // anthropic: 100/100 tokens -> exhausted
        _run(
          startedAt: _now.subtract(const Duration(hours: 1)),
          adapter: 'anthropic',
          inputTokens: 100,
        ),
        // openai: 85/100 requests would need 85 runs; instead make it warning
        // via a single run against a tiny limit.
        _run(
          startedAt: _now.subtract(const Duration(hours: 1)),
          adapter: 'openai',
        ),
        // google: 1/100 requests -> ok
        _run(
          startedAt: _now.subtract(const Duration(hours: 1)),
          adapter: 'google',
        ),
      ];
      final reports = calc.reportAll(
        runs: runs,
        now: _now,
        limits: const [
          // ok (zoom: 0 used, big limit)
          QuotaLimit(
            provider: 'zoom',
            window: QuotaWindow.daily,
            unit: QuotaUnit.requests,
            limit: 100,
          ),
          // exhausted: anthropic tokens 100/100
          QuotaLimit(
            provider: 'anthropic',
            window: QuotaWindow.daily,
            unit: QuotaUnit.tokens,
            limit: 100,
          ),
          // unknown: limit 0
          QuotaLimit(
            provider: 'mistral',
            window: QuotaWindow.daily,
            unit: QuotaUnit.requests,
            limit: 0,
          ),
          // warning: openai 1/1 request -> exhausted actually; use limit such
          // that 1 used is >=0.8 but <1.0 is impossible with ints, so make
          // warning via google 4/5.
          QuotaLimit(
            provider: 'openai',
            window: QuotaWindow.daily,
            unit: QuotaUnit.requests,
            limit: 1,
          ),
        ],
      );

      // Order: exhausted group first (anthropic, openai both exhausted ->
      // alphabetical), then ok (zoom), then unknown (mistral).
      final statuses = reports.map((r) => r.status).toList();
      // exhausted entries lead.
      expect(statuses.first, QuotaStatus.exhausted);
      // unknown is last.
      expect(statuses.last, QuotaStatus.unknown);

      // Within the exhausted group, provider order is alphabetical.
      final exhausted = reports
          .where((r) => r.status == QuotaStatus.exhausted)
          .map((r) => r.provider)
          .toList();
      expect(exhausted, ['anthropic', 'openai']);
    });

    test('full severity ordering: exhausted > warning > ok > unknown', () {
      // One run per provider, all in-window, so request counts are
      // deterministic and we can hit each status with a tailored limit.
      final runs = [
        _run(
          startedAt: _now.subtract(const Duration(hours: 1)),
          adapter: 'exhaust',
        ),
        // Four runs for the warning provider so 4/5 == 0.8 exactly.
        for (var i = 0; i < 4; i++)
          _run(
            startedAt: _now.subtract(const Duration(hours: 1)),
            adapter: 'warn',
          ),
        _run(
          startedAt: _now.subtract(const Duration(hours: 1)),
          adapter: 'okp',
        ),
      ];
      final reports = calc.reportAll(
        runs: runs,
        now: _now,
        // Deliberately supplied out of severity order; the calculator sorts.
        limits: const [
          // ok: 1/100 requests.
          QuotaLimit(
            provider: 'okp',
            window: QuotaWindow.daily,
            unit: QuotaUnit.requests,
            limit: 100,
          ),
          // unknown: no usable limit.
          QuotaLimit(
            provider: 'unk',
            window: QuotaWindow.daily,
            unit: QuotaUnit.requests,
            limit: 0,
          ),
          // warning: 4/5 == 0.8 requests.
          QuotaLimit(
            provider: 'warn',
            window: QuotaWindow.daily,
            unit: QuotaUnit.requests,
            limit: 5,
          ),
          // exhausted: 1/1 requests.
          QuotaLimit(
            provider: 'exhaust',
            window: QuotaWindow.daily,
            unit: QuotaUnit.requests,
            limit: 1,
          ),
        ],
      );

      expect(reports.map((r) => r.status).toList(), [
        QuotaStatus.exhausted,
        QuotaStatus.warning,
        QuotaStatus.ok,
        QuotaStatus.unknown,
      ]);
      // Sanity-check the warning provider really is at fraction 0.8.
      final warn = reports.firstWhere((r) => r.provider == 'warn');
      expect(warn.fraction, closeTo(0.8, 1e-9));
    });

    test('ties within same status sort by provider, case-insensitively', () {
      final reports = calc.reportAll(
        runs: const [],
        now: _now,
        limits: const [
          QuotaLimit(
            provider: 'Zeta',
            window: QuotaWindow.daily,
            unit: QuotaUnit.requests,
            limit: 100,
          ),
          QuotaLimit(
            provider: 'alpha',
            window: QuotaWindow.daily,
            unit: QuotaUnit.requests,
            limit: 100,
          ),
          QuotaLimit(
            provider: 'Mid',
            window: QuotaWindow.daily,
            unit: QuotaUnit.requests,
            limit: 100,
          ),
        ],
      );
      // All ok (0 usage). Provider order should be alpha, Mid, Zeta.
      expect(reports.map((r) => r.provider).toList(), ['alpha', 'Mid', 'Zeta']);
    });

    test('empty limits yields empty report list', () {
      final reports = calc.reportAll(
        runs: const [],
        now: _now,
        limits: const [],
      );
      expect(reports, isEmpty);
    });
  });

  group('value object equality', () {
    test('QuotaLimit == and hashCode are structural', () {
      const a = QuotaLimit(
        provider: 'anthropic',
        window: QuotaWindow.daily,
        unit: QuotaUnit.tokens,
        limit: 1000,
      );
      const b = QuotaLimit(
        provider: 'anthropic',
        window: QuotaWindow.daily,
        unit: QuotaUnit.tokens,
        limit: 1000,
      );
      const c = QuotaLimit(
        provider: 'anthropic',
        window: QuotaWindow.daily,
        unit: QuotaUnit.tokens,
        limit: 2000,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('QuotaUsageReport == and hashCode are structural', () {
      final start = _now.subtract(const Duration(hours: 24));
      final a = QuotaUsageReport(
        provider: 'anthropic',
        window: QuotaWindow.daily,
        unit: QuotaUnit.tokens,
        used: 100,
        limit: 1000,
        windowStart: start,
        resetsAt: _now,
      );
      final b = QuotaUsageReport(
        provider: 'anthropic',
        window: QuotaWindow.daily,
        unit: QuotaUnit.tokens,
        used: 100,
        limit: 1000,
        windowStart: start,
        resetsAt: _now,
      );
      final c = QuotaUsageReport(
        provider: 'anthropic',
        window: QuotaWindow.daily,
        unit: QuotaUnit.tokens,
        used: 101,
        limit: 1000,
        windowStart: start,
        resetsAt: _now,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
