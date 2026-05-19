import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/observability/domain/usage_stats.dart';
import 'package:test/test.dart';

/// Builds an [AgentRunLog] with just the fields the calculator reads.
AgentRunLog _run({
  String id = 'r',
  required DateTime startedAt,
  int tokens = 0,
  String? modelId,
  String? adapter,
  int? durationMs,
}) => AgentRunLog(
  id: id,
  agentId: 'a',
  startedAt: startedAt,
  status: RunStatus.completed,
  modelId: modelId,
  adapter: adapter,
  cost: RunCost(inputTokens: tokens, durationMs: durationMs),
);

void main() {
  const calc = UsageStatsCalculator();

  group('dailyTotals', () {
    test('folds runs into local days and sorts ascending', () {
      final totals = calc.dailyTotals([
        _run(id: '1', startedAt: DateTime(2026, 8, 3, 9), tokens: 10),
        _run(id: '2', startedAt: DateTime(2026, 8, 1, 23), tokens: 5),
        _run(id: '3', startedAt: DateTime(2026, 8, 3, 21), tokens: 7),
      ]);

      expect(totals, hasLength(2));
      expect(totals.first.day, DateTime(2026, 8));
      expect(totals.first.tokens, 5);
      expect(totals.first.runs, 1);
      expect(totals.last.day, DateTime(2026, 8, 3));
      expect(totals.last.tokens, 17);
      expect(totals.last.runs, 2);
    });

    test('is empty for no runs', () {
      expect(calc.dailyTotals(const []), isEmpty);
    });
  });

  group('denseDailyTotals', () {
    test('zero-fills the gaps so the axis stays evenly spaced', () {
      final dense = calc.denseDailyTotals(
        [_run(startedAt: DateTime(2026, 8, 3), tokens: 4)],
        start: DateTime(2026, 8),
        end: DateTime(2026, 8, 4),
      );

      expect(dense.map((d) => d.tokens), [0, 0, 4, 0]);
      expect(dense.map((d) => d.day), [
        DateTime(2026, 8),
        DateTime(2026, 8, 2),
        DateTime(2026, 8, 3),
        DateTime(2026, 8, 4),
      ]);
    });
  });

  group('summarize', () {
    test('reports totals, the peak day and the longest session', () {
      final summary = calc.summarize([
        _run(id: '1', startedAt: DateTime(2026, 8, 1), tokens: 10),
        _run(id: '2', startedAt: DateTime(2026, 8, 2), tokens: 30),
        _run(
          id: '3',
          startedAt: DateTime(2026, 8, 2),
          tokens: 5,
          durationMs: 90000,
        ),
      ], today: DateTime(2026, 8, 2, 18));

      expect(summary.totalTokens, 45);
      expect(summary.peakDayTokens, 35);
      expect(summary.longestSessionMs, 90000);
      expect(summary.activeDays, 2);
    });

    test('is fully zeroed for no runs', () {
      expect(
        calc.summarize(const [], today: DateTime(2026, 8, 2)),
        UsageSummary.empty,
      );
    });

    test('counts a streak ending today', () {
      final summary = calc.summarize([
        _run(id: '1', startedAt: DateTime(2026, 8, 1), tokens: 1),
        _run(id: '2', startedAt: DateTime(2026, 8, 2), tokens: 1),
        _run(id: '3', startedAt: DateTime(2026, 8, 3), tokens: 1),
      ], today: DateTime(2026, 8, 3, 10));

      expect(summary.currentStreakDays, 3);
      expect(summary.longestStreakDays, 3);
    });

    test('a still-quiet today does not break the streak', () {
      final summary = calc.summarize([
        _run(id: '1', startedAt: DateTime(2026, 8, 1), tokens: 1),
        _run(id: '2', startedAt: DateTime(2026, 8, 2), tokens: 1),
      ], today: DateTime(2026, 8, 3, 10));

      expect(summary.currentStreakDays, 2);
    });

    test('a two-day gap does break the streak', () {
      final summary = calc.summarize([
        _run(id: '1', startedAt: DateTime(2026, 8, 1), tokens: 1),
        _run(id: '2', startedAt: DateTime(2026, 8, 2), tokens: 1),
      ], today: DateTime(2026, 8, 4, 10));

      expect(summary.currentStreakDays, 0);
      expect(summary.longestStreakDays, 2);
    });

    test('the longest streak is the longest run anywhere in the window', () {
      final summary = calc.summarize([
        for (final day in [1, 2, 3, 4, 8, 9])
          _run(id: 'r$day', startedAt: DateTime(2026, 8, day), tokens: 1),
      ], today: DateTime(2026, 8, 9));

      expect(summary.longestStreakDays, 4);
      expect(summary.currentStreakDays, 2);
    });
  });

  group('activityGrid', () {
    final today = DateTime(2026, 8, 26);

    test('columns are whole Monday-first ISO weeks covering the window', () {
      final grid = calc.activityGrid(
        const [],
        today: today,
        mode: UsageActivityMode.daily,
      );

      final firstCell = grid.weeks.first.whereType<UsageActivityCell>().first;
      expect(firstCell.day.weekday, DateTime.monday);

      final lastCell = grid.weeks.last.whereType<UsageActivityCell>().last;
      expect(lastCell.day, today);

      // Every column holds seven slots; only the last may be partly null.
      expect(grid.weeks.every((week) => week.length == 7), isTrue);
      for (final week in grid.weeks.take(grid.weeks.length - 1)) {
        expect(week.whereType<UsageActivityCell>(), hasLength(7));
      }
    });

    test('never plots a day past today', () {
      final grid = calc.activityGrid(
        const [],
        today: today,
        mode: UsageActivityMode.daily,
      );
      final days = [
        for (final week in grid.weeks) ...week.whereType<UsageActivityCell>(),
      ].map((c) => c.day);

      expect(days.every((d) => !d.isAfter(today)), isTrue);
    });

    test('daily mode carries each day its own total', () {
      final grid = calc.activityGrid(
        [_run(startedAt: DateTime(2026, 8, 25), tokens: 100)],
        today: today,
        mode: UsageActivityMode.daily,
      );

      final cells = {
        for (final week in grid.weeks)
          for (final cell in week.whereType<UsageActivityCell>())
            cell.day: cell,
      };
      expect(cells[DateTime(2026, 8, 25)]!.value, 100);
      expect(cells[DateTime(2026, 8, 24)]!.value, 0);
      expect(grid.maxValue, 100);
    });

    test('weekly mode gives every day in a column the week total', () {
      final grid = calc.activityGrid(
        [
          _run(id: '1', startedAt: DateTime(2026, 8, 24), tokens: 10),
          _run(id: '2', startedAt: DateTime(2026, 8, 26), tokens: 30),
        ],
        today: today,
        mode: UsageActivityMode.weekly,
      );

      final lastWeek = grid.weeks.last.whereType<UsageActivityCell>();
      expect(lastWeek.every((c) => c.value == 40), isTrue);
      expect(grid.maxValue, 40);
    });

    test('cumulative mode is monotonically non-decreasing', () {
      final grid = calc.activityGrid(
        [
          _run(id: '1', startedAt: DateTime(2026, 8, 20), tokens: 10),
          _run(id: '2', startedAt: DateTime(2026, 8, 25), tokens: 30),
        ],
        today: today,
        mode: UsageActivityMode.cumulative,
      );

      final values = [
        for (final week in grid.weeks) ...week.whereType<UsageActivityCell>(),
      ].map((c) => c.value).toList();

      for (var i = 1; i < values.length; i++) {
        expect(values[i], greaterThanOrEqualTo(values[i - 1]));
      }
      expect(values.last, 40);
      expect(grid.maxValue, 40);
    });

    test('an untouched day stays at level 0 while the peak reaches 4', () {
      final grid = calc.activityGrid(
        [
          _run(id: '1', startedAt: DateTime(2026, 8, 25), tokens: 1),
          _run(id: '2', startedAt: DateTime(2026, 8, 26), tokens: 100),
        ],
        today: today,
        mode: UsageActivityMode.daily,
      );

      final cells = {
        for (final week in grid.weeks)
          for (final cell in week.whereType<UsageActivityCell>())
            cell.day: cell,
      };
      expect(cells[DateTime(2026, 8, 24)]!.level, 0);
      expect(cells[DateTime(2026, 8, 25)]!.level, 1);
      expect(cells[DateTime(2026, 8, 26)]!.level, 4);
    });

    test('month labels are ordered and in range', () {
      final grid = calc.activityGrid(
        const [],
        today: today,
        mode: UsageActivityMode.daily,
      );

      expect(grid.monthLabels, isNotEmpty);
      for (final label in grid.monthLabels) {
        expect(label.column, inInclusiveRange(0, grid.weeks.length - 1));
      }
      final columns = grid.monthLabels.map((l) => l.column).toList();
      expect(columns, orderedEquals([...columns]..sort()));
      // A trailing year touches every month exactly once.
      expect(grid.monthLabels.map((l) => l.monthStart.month).toSet(), hasLength(12));
    });
  });

  group('byModel', () {
    test('sums per model, sorts by tokens and computes shares', () {
      final slices = calc.byModel([
        _run(id: '1', startedAt: DateTime(2026, 8), tokens: 10, modelId: 'a'),
        _run(id: '2', startedAt: DateTime(2026, 8), tokens: 30, modelId: 'b'),
        _run(id: '3', startedAt: DateTime(2026, 8), tokens: 10, modelId: 'a'),
      ]);

      expect(slices.map((s) => s.model), ['b', 'a']);
      expect(slices.first.tokens, 30);
      expect(slices.first.runs, 1);
      expect(slices.first.share, closeTo(0.6, 1e-9));
      expect(slices.last.share, closeTo(0.4, 1e-9));
    });

    test('falls back through adapter to the unknown bucket', () {
      final slices = calc.byModel([
        _run(id: '1', startedAt: DateTime(2026, 8), tokens: 5, adapter: 'cli'),
        _run(id: '2', startedAt: DateTime(2026, 8), tokens: 5),
      ]);

      expect(slices.map((s) => s.model).toSet(), {
        'cli',
        UsageStatsCalculator.unknownModel,
      });
    });

    test('drops a model that spent no tokens', () {
      final slices = calc.byModel([
        _run(id: '1', startedAt: DateTime(2026, 8), tokens: 0, modelId: 'a'),
      ]);

      expect(slices, isEmpty);
    });
  });

  group('trend', () {
    test('produces one dense series per model over the window', () {
      final series = calc.trend(
        [
          _run(
            id: '1',
            startedAt: DateTime(2026, 8, 2),
            tokens: 10,
            modelId: 'a',
          ),
          _run(
            id: '2',
            startedAt: DateTime(2026, 8, 3),
            tokens: 20,
            modelId: 'b',
          ),
        ],
        start: DateTime(2026, 8),
        end: DateTime(2026, 8, 3),
      );

      expect(series, hasLength(2));
      expect(series.map((s) => s.model), ['b', 'a']);
      for (final entry in series) {
        expect(entry.points, hasLength(3));
        expect(entry.points.first.day, DateTime(2026, 8));
        expect(entry.points.last.day, DateTime(2026, 8, 3));
      }
      expect(series.firstWhere((s) => s.model == 'a').points[1].tokens, 10);
      expect(series.firstWhere((s) => s.model == 'a').points[2].tokens, 0);
    });

    test('folds models past the cap into one bucket rather than dropping '
        'them', () {
      final series = calc.trend(
        [
          for (var i = 0; i < 5; i++)
            _run(
              id: 'r$i',
              startedAt: DateTime(2026, 8),
              tokens: 100 - i,
              modelId: 'm$i',
            ),
        ],
        start: DateTime(2026, 8),
        end: DateTime(2026, 8),
        maxSeries: 2,
      );

      expect(series.map((s) => s.model), [
        'm0',
        'm1',
        UsageStatsCalculator.otherModels,
      ]);
      // 98 + 97 + 96 — nothing is lost off the bottom of the ranking.
      expect(series.last.points.single.tokens, 291);
    });

    test('is empty for no runs', () {
      expect(
        calc.trend(
          const [],
          start: DateTime(2026, 8),
          end: DateTime(2026, 8, 3),
        ),
        isEmpty,
      );
    });
  });
}
