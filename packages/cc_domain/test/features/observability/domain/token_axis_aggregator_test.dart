import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/observability/domain/token_axis_aggregator.dart';
import 'package:test/test.dart';

/// Builds an [AgentRunLog] with only the fields the aggregator reads.
AgentRunLog _run({
  String id = 'run',
  RunCost cost = RunCost.zero,
  AgentRunRole role = AgentRunRole.main,
  String? adapter,
  String? modelId,
  DateTime? startedAt,
}) {
  return AgentRunLog(
    id: id,
    agentId: 'agent-1',
    startedAt: startedAt ?? DateTime(2026, 1, 1, 12),
    status: RunStatus.completed,
    cost: cost,
    role: role,
    adapter: adapter,
    modelId: modelId,
  );
}

RunCost _cost({
  int input = 0,
  int output = 0,
  int reasoning = 0,
  int cacheRead = 0,
  int cacheWrite = 0,
  int cents = 0,
}) {
  return RunCost(
    inputTokens: input,
    outputTokens: output,
    thoughtTokens: reasoning,
    cachedReadTokens: cacheRead,
    cachedWriteTokens: cacheWrite,
    estimatedCostCents: cents,
  );
}

void main() {
  const aggregator = TokenAxisAggregator();

  group('TokenAxisTotals', () {
    test('zero is all zeros', () {
      const zero = TokenAxisTotals.zero;
      expect(zero.input, 0);
      expect(zero.output, 0);
      expect(zero.reasoning, 0);
      expect(zero.cacheRead, 0);
      expect(zero.cacheWrite, 0);
      expect(zero.costCents, 0);
      expect(zero.total, 0);
    });

    test('total sums the five token axes but excludes cost', () {
      const t = TokenAxisTotals(
        input: 1,
        output: 2,
        reasoning: 4,
        cacheRead: 8,
        cacheWrite: 16,
        costCents: 999,
      );
      expect(t.total, 31);
    });

    test(
      'fromRunCost maps thoughtTokens to reasoning and cached* to cache axes',
      () {
        final t = TokenAxisTotals.fromRunCost(
          _cost(
            input: 10,
            output: 20,
            reasoning: 30,
            cacheRead: 40,
            cacheWrite: 50,
            cents: 7,
          ),
        );
        expect(t.input, 10);
        expect(t.output, 20);
        expect(t.reasoning, 30);
        expect(t.cacheRead, 40);
        expect(t.cacheWrite, 50);
        expect(t.costCents, 7);
        expect(t.total, 150);
      },
    );

    test('operator + sums every axis and cost', () {
      const a = TokenAxisTotals(
        input: 1,
        output: 2,
        reasoning: 3,
        cacheRead: 4,
        cacheWrite: 5,
        costCents: 6,
      );
      const b = TokenAxisTotals(
        input: 10,
        output: 20,
        reasoning: 30,
        cacheRead: 40,
        cacheWrite: 50,
        costCents: 60,
      );
      final sum = a + b;
      expect(sum.input, 11);
      expect(sum.output, 22);
      expect(sum.reasoning, 33);
      expect(sum.cacheRead, 44);
      expect(sum.cacheWrite, 55);
      expect(sum.costCents, 66);
    });

    test('== and hashCode are structural', () {
      const a = TokenAxisTotals(input: 1, costCents: 2);
      const b = TokenAxisTotals(input: 1, costCents: 2);
      const c = TokenAxisTotals(input: 1, costCents: 3);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('RoleCostBreakdown', () {
    test('cost getters read each role bucket and total sums them', () {
      const breakdown = RoleCostBreakdown(
        main: TokenAxisTotals(costCents: 100),
        sub: TokenAxisTotals(costCents: 30),
        advisor: TokenAxisTotals(costCents: 5),
      );
      expect(breakdown.mainCostCents, 100);
      expect(breakdown.subCostCents, 30);
      expect(breakdown.advisorCostCents, 5);
      expect(breakdown.totalCostCents, 135);
    });

    test('defaults to zero buckets', () {
      const breakdown = RoleCostBreakdown();
      expect(breakdown.main, TokenAxisTotals.zero);
      expect(breakdown.sub, TokenAxisTotals.zero);
      expect(breakdown.advisor, TokenAxisTotals.zero);
      expect(breakdown.totalCostCents, 0);
    });

    test('== and hashCode are structural', () {
      const a = RoleCostBreakdown(main: TokenAxisTotals(costCents: 1));
      const b = RoleCostBreakdown(main: TokenAxisTotals(costCents: 1));
      const c = RoleCostBreakdown(main: TokenAxisTotals(costCents: 2));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('ModelUsage / DayUsage value semantics', () {
    test('ModelUsage == and hashCode are structural', () {
      const a = ModelUsage(
        model: 'claude',
        runs: 2,
        tokens: TokenAxisTotals(input: 5),
      );
      const b = ModelUsage(
        model: 'claude',
        runs: 2,
        tokens: TokenAxisTotals(input: 5),
      );
      const c = ModelUsage(
        model: 'codex',
        runs: 2,
        tokens: TokenAxisTotals(input: 5),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('DayUsage == and hashCode are structural', () {
      final a = DayUsage(
        day: DateTime(2026, 1, 1),
        runs: 1,
        tokens: const TokenAxisTotals(output: 3),
      );
      final b = DayUsage(
        day: DateTime(2026, 1, 1),
        runs: 1,
        tokens: const TokenAxisTotals(output: 3),
      );
      final c = DayUsage(
        day: DateTime(2026, 1, 2),
        runs: 1,
        tokens: const TokenAxisTotals(output: 3),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('TokenAxisAggregator.aggregate — empty', () {
    test('empty iterable returns the canonical empty aggregation', () {
      final result = aggregator.aggregate(const <AgentRunLog>[]);
      expect(result, TokenAggregation.empty);
      expect(result.totals, TokenAxisTotals.zero);
      expect(result.byRole, const RoleCostBreakdown());
      expect(result.byModel, isEmpty);
      expect(result.byDay, isEmpty);
      expect(result.medianRunTokens, 0);
      expect(result.runCount, 0);
    });
  });

  group('TokenAxisAggregator.aggregate — totals', () {
    test('grand totals sum every axis and cost across all runs', () {
      final result = aggregator.aggregate([
        _run(id: 'a', cost: _cost(input: 10, output: 5, cents: 3)),
        _run(id: 'b', cost: _cost(reasoning: 7, cacheRead: 2, cents: 4)),
        _run(id: 'c', cost: _cost(cacheWrite: 9, cents: 1)),
      ]);
      expect(result.runCount, 3);
      expect(result.totals.input, 10);
      expect(result.totals.output, 5);
      expect(result.totals.reasoning, 7);
      expect(result.totals.cacheRead, 2);
      expect(result.totals.cacheWrite, 9);
      expect(result.totals.costCents, 8);
      expect(result.totals.total, 33);
    });
  });

  group('TokenAxisAggregator.aggregate — byRole', () {
    test('attributes tokens and cost to the run role', () {
      final result = aggregator.aggregate([
        _run(
          id: 'm1',
          role: AgentRunRole.main,
          cost: _cost(input: 100, cents: 50),
        ),
        _run(
          id: 'm2',
          role: AgentRunRole.main,
          cost: _cost(input: 10, cents: 5),
        ),
        _run(
          id: 's1',
          role: AgentRunRole.sub,
          cost: _cost(output: 20, cents: 8),
        ),
        _run(
          id: 'adv',
          role: AgentRunRole.advisor,
          cost: _cost(reasoning: 3, cents: 2),
        ),
      ]);

      expect(result.byRole.main.input, 110);
      expect(result.byRole.mainCostCents, 55);
      expect(result.byRole.sub.output, 20);
      expect(result.byRole.subCostCents, 8);
      expect(result.byRole.advisor.reasoning, 3);
      expect(result.byRole.advisorCostCents, 2);
      expect(result.byRole.totalCostCents, 65);
    });

    test('a role with no runs stays at zero', () {
      final result = aggregator.aggregate([
        _run(role: AgentRunRole.main, cost: _cost(input: 1, cents: 1)),
      ]);
      expect(result.byRole.sub, TokenAxisTotals.zero);
      expect(result.byRole.advisor, TokenAxisTotals.zero);
    });
  });

  group('TokenAxisAggregator.aggregate — byModel', () {
    test(
      'groups by modelId (with adapter fallback) and sorts by cost descending',
      () {
        final result = aggregator.aggregate([
          _run(id: 'a', modelId: 'cheap-m', cost: _cost(input: 1, cents: 5)),
          _run(id: 'b', modelId: 'pricey-m', cost: _cost(input: 1, cents: 40)),
          _run(id: 'c', modelId: 'cheap-m', cost: _cost(input: 1, cents: 5)),
          _run(id: 'd', modelId: 'mid-m', cost: _cost(input: 1, cents: 20)),
        ]);

        expect(result.byModel.map((m) => m.model).toList(), [
          'pricey-m',
          'mid-m',
          'cheap-m',
        ]);
        expect(result.byModel[0].runs, 1);
        expect(result.byModel[0].tokens.costCents, 40);
        // cheap-m appears twice -> 2 runs, summed cost 10.
        final cheap = result.byModel.firstWhere((m) => m.model == 'cheap-m');
        expect(cheap.runs, 2);
        expect(cheap.tokens.costCents, 10);
        expect(cheap.tokens.input, 2);
      },
    );

    test('prefers modelId over adapter when both are present', () {
      final result = aggregator.aggregate([
        // Both set: modelId wins.
        _run(
          id: 'a',
          adapter: 'claude',
          modelId: 'claude-opus-4-5',
          cost: _cost(input: 1, cents: 10),
        ),
        // No modelId: falls back to adapter.
        _run(id: 'b', adapter: 'claude', cost: _cost(input: 1, cents: 3)),
      ]);

      final models = result.byModel.map((m) => m.model).toSet();
      expect(models, {'claude-opus-4-5', 'claude'});
      final byModel = result.byModel.firstWhere(
        (m) => m.model == 'claude-opus-4-5',
      );
      expect(byModel.runs, 1);
      expect(byModel.tokens.costCents, 10);
      final byAdapter = result.byModel.firstWhere((m) => m.model == 'claude');
      expect(byAdapter.runs, 1);
      expect(byAdapter.tokens.costCents, 3);
    });

    test('a missing adapter and modelId is grouped under "unknown"', () {
      final result = aggregator.aggregate([
        _run(id: 'a', cost: _cost(input: 1, cents: 1)),
        _run(id: 'b', adapter: 'claude', cost: _cost(input: 1, cents: 2)),
        _run(id: 'c', cost: _cost(input: 1, cents: 1)),
      ]);
      final unknown = result.byModel.firstWhere(
        (m) => m.model == TokenAxisAggregator.unknownModel,
      );
      expect(unknown.runs, 2);
      expect(unknown.tokens.costCents, 2);
      expect(unknown.model, 'unknown');
    });
  });

  group('TokenAxisAggregator.aggregate — byDay', () {
    test('groups by date-only and sorts ascending', () {
      final result = aggregator.aggregate([
        _run(
          id: 'late',
          startedAt: DateTime(2026, 3, 5, 23, 59),
          cost: _cost(input: 2, cents: 2),
        ),
        _run(
          id: 'early',
          startedAt: DateTime(2026, 3, 1, 0, 1),
          cost: _cost(input: 1, cents: 1),
        ),
        // Same calendar day as 'late' but a different time of day.
        _run(
          id: 'sameDay',
          startedAt: DateTime(2026, 3, 5, 8),
          cost: _cost(input: 3, cents: 3),
        ),
      ]);

      expect(result.byDay.length, 2);
      expect(result.byDay[0].day, DateTime(2026, 3, 1));
      expect(result.byDay[1].day, DateTime(2026, 3, 5));

      expect(result.byDay[0].runs, 1);
      expect(result.byDay[0].tokens.input, 1);

      // March 5 collapses the two runs (different times, same day).
      expect(result.byDay[1].runs, 2);
      expect(result.byDay[1].tokens.input, 5);
      expect(result.byDay[1].tokens.costCents, 5);
      // The day key carries no time component.
      expect(result.byDay[1].day.hour, 0);
      expect(result.byDay[1].day.minute, 0);
    });
  });

  group('TokenAxisAggregator.aggregate — medianRunTokens', () {
    test('single run median equals that run total', () {
      final result = aggregator.aggregate([
        _run(cost: _cost(input: 4, output: 6)),
      ]);
      expect(result.medianRunTokens, 10.0);
    });

    test('odd count returns the middle value', () {
      final result = aggregator.aggregate([
        _run(id: 'a', cost: _cost(input: 10)),
        _run(id: 'b', cost: _cost(input: 30)),
        _run(id: 'c', cost: _cost(input: 20)),
      ]);
      // Sorted totals: 10, 20, 30 -> median 20.
      expect(result.medianRunTokens, 20.0);
    });

    test('even count averages the two middle values (no truncation)', () {
      final result = aggregator.aggregate([
        _run(id: 'a', cost: _cost(input: 10)),
        _run(id: 'b', cost: _cost(input: 20)),
        _run(id: 'c', cost: _cost(input: 30)),
        _run(id: 'd', cost: _cost(input: 41)),
      ]);
      // Sorted: 10, 20, 30, 41 -> (20 + 30) / 2 = 25.0.
      expect(result.medianRunTokens, 25.0);
    });

    test('even count produces a fractional half median', () {
      final result = aggregator.aggregate([
        _run(id: 'a', cost: _cost(input: 1)),
        _run(id: 'b', cost: _cost(input: 2)),
      ]);
      // (1 + 2) / 2 = 1.5 — must not truncate to 1.
      expect(result.medianRunTokens, 1.5);
    });

    test('median counts every token axis via RunCost.totalTokens', () {
      final result = aggregator.aggregate([
        _run(
          cost: _cost(
            input: 1,
            output: 1,
            reasoning: 1,
            cacheRead: 1,
            cacheWrite: 1,
          ),
        ),
      ]);
      expect(result.medianRunTokens, 5.0);
    });

    test('median is unaffected by input ordering (sorts a copy)', () {
      final ascending = aggregator.aggregate([
        _run(id: 'a', cost: _cost(input: 1)),
        _run(id: 'b', cost: _cost(input: 100)),
        _run(id: 'c', cost: _cost(input: 50)),
      ]);
      final descending = aggregator.aggregate([
        _run(id: 'a', cost: _cost(input: 100)),
        _run(id: 'b', cost: _cost(input: 50)),
        _run(id: 'c', cost: _cost(input: 1)),
      ]);
      expect(ascending.medianRunTokens, 50.0);
      expect(descending.medianRunTokens, 50.0);
    });
  });

  group('TokenAxisAggregator.aggregate — combined invariants', () {
    test(
      'per-role costs and per-model costs both reconcile to grand total',
      () {
        final runs = [
          _run(
            id: '1',
            role: AgentRunRole.main,
            modelId: 'claude-opus-4-5',
            startedAt: DateTime(2026, 2, 1, 9),
            cost: _cost(input: 100, output: 50, cents: 25),
          ),
          _run(
            id: '2',
            role: AgentRunRole.sub,
            modelId: 'claude-opus-4-5',
            startedAt: DateTime(2026, 2, 1, 18),
            cost: _cost(input: 10, reasoning: 5, cents: 7),
          ),
          _run(
            id: '3',
            role: AgentRunRole.advisor,
            modelId: 'codex-1',
            startedAt: DateTime(2026, 2, 2, 9),
            cost: _cost(output: 20, cacheRead: 8, cents: 3),
          ),
          _run(
            id: '4',
            role: AgentRunRole.main,
            startedAt: DateTime(2026, 2, 2, 11),
            cost: _cost(cacheWrite: 4, cents: 1),
          ),
        ];
        final result = aggregator.aggregate(runs);

        expect(result.runCount, 4);
        expect(result.totals.costCents, 36);

        // Role attribution reconciles to the grand total.
        expect(result.byRole.totalCostCents, result.totals.costCents);

        // Model attribution reconciles to the grand total.
        final modelCost = result.byModel.fold<int>(
          0,
          (sum, m) => sum + m.tokens.costCents,
        );
        expect(modelCost, result.totals.costCents);
        final modelRuns = result.byModel.fold<int>(0, (sum, m) => sum + m.runs);
        expect(modelRuns, result.runCount);

        // Day attribution reconciles to the grand total.
        final dayCost = result.byDay.fold<int>(
          0,
          (sum, d) => sum + d.tokens.costCents,
        );
        expect(dayCost, result.totals.costCents);
        final dayRuns = result.byDay.fold<int>(0, (sum, d) => sum + d.runs);
        expect(dayRuns, result.runCount);

        // claude-opus-4-5 (25 + 7 = 32) outranks codex-1 (3) and unknown (1).
        expect(result.byModel.first.model, 'claude-opus-4-5');
        expect(result.byModel.first.tokens.costCents, 32);
        expect(result.byModel.first.runs, 2);

        // Two distinct days, ascending.
        expect(result.byDay.map((d) => d.day).toList(), [
          DateTime(2026, 2, 1),
          DateTime(2026, 2, 2),
        ]);
      },
    );
  });
}
