import 'dart:async';

import 'package:cc_domain/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:cc_domain/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/top_performer_hero.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../helpers/test_wrap.dart';

AgentScorecard _scorecard({
  String agentId = 'agent-1',
  String agentName = 'Alice',
  int totalRuns = 42,
  int totalErrored = 3,
  double successRate = 0.93,
  int totalPrsMerged = 12,
  int totalReviews = 28,
  int totalXp = 4500,
  int level = 7,
  double levelProgress = 0.45,
}) {
  return AgentScorecard(
    agentId: agentId,
    agentName: agentName,
    totalRuns: totalRuns,
    totalErrored: totalErrored,
    successRate: successRate,
    avgRunDurationMs: 12000,
    totalPrsCreated: 15,
    totalPrsMerged: totalPrsMerged,
    totalReviews: totalReviews,
    totalBlockingComments: 5,
    totalXp: totalXp,
    level: level,
    levelProgress: levelProgress,
    currentStreaks: const [],
    achievements: const [],
  );
}

AgentDailyStats _dailyStat({required DateTime date, int runsCompleted = 2}) {
  return AgentDailyStats(
    id: 'ds-${date.toIso8601String()}',
    agentId: 'agent-1',
    date: date,
    runsCompleted: runsCompleted,
    runsErrored: 0,
    totalRunDurationMs: 5000,
    prsCreated: 0,
    prsMerged: 0,
    reviewsCompleted: 1,
    blockingComments: 0,
    linesAdded: 20,
    linesDeleted: 5,
    xpEarned: 50,
    createdAt: date,
  );
}

Widget _wrapLoading(Widget child) {
  final completer = Completer<List<AgentScorecard>>();
  return testWrap(
    ProviderScope(
      overrides: [
        allAgentScorecardsProvider.overrideWith((ref) => completer.future),
      ],
      child: child,
    ),
  );
}

Widget _wrapData({
  required Widget child,
  required List<AgentScorecard> scorecards,
  List<AgentDailyStats> dailyStats = const [],
}) {
  return testWrap(
    ProviderScope(
      overrides: [
        allAgentScorecardsProvider.overrideWith(
          (ref) => Future.value(scorecards),
        ),
        dailyStatsByDateRangeProvider.overrideWith(
          (ref, params) => Stream.value(dailyStats),
        ),
      ],
      child: child,
    ),
  );
}

Widget _wrapError(Widget child, Exception error) {
  return testWrap(
    ProviderScope(
      overrides: [
        allAgentScorecardsProvider.overrideWith((ref) => Future.error(error)),
      ],
      child: child,
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
}

void main() {
  group('TopPerformerHero', () {
    // ── Loading state ──

    testWidgets('renders loading indicator while scorecards load',
        (tester) async {
      await tester.pumpWidget(_wrapLoading(const TopPerformerHero()));
      await tester.pump();

      expect(find.byType(CcSpinner), findsOneWidget);
    });

    testWidgets('loading state shows section label', (tester) async {
      await tester.pumpWidget(_wrapLoading(const TopPerformerHero()));
      await tester.pump();

      expect(find.text('TOP PERFORMER'), findsOneWidget);
    });

    // ── Error state ──

    testWidgets('shows section label in error state', (tester) async {
      await _pump(
        tester,
        _wrapError(const TopPerformerHero(), Exception('fail')),
      );
      await tester.pump();

      expect(find.text('TOP PERFORMER'), findsOneWidget);
    });

    testWidgets('renders without crash on provider error', (tester) async {
      await _pump(
        tester,
        _wrapError(const TopPerformerHero(), Exception('DB failure')),
      );
      await tester.pump();

      // Just verify the widget doesn't crash — the error branch renders
      expect(find.byType(TopPerformerHero), findsOneWidget);
    });

    // ── Empty state ──

    testWidgets('renders empty state when no agents', (tester) async {
      await _pump(
        tester,
        _wrapData(child: const TopPerformerHero(), scorecards: const []),
      );

      expect(find.text('No agent activity yet'), findsOneWidget);
      expect(find.byIcon(LucideIcons.trophy), findsOneWidget);
    });

    testWidgets('empty state shows section label', (tester) async {
      await _pump(
        tester,
        _wrapData(child: const TopPerformerHero(), scorecards: const []),
      );

      expect(find.text('TOP PERFORMER'), findsOneWidget);
    });

    // ── Data: basic rendering ──

    testWidgets('renders top agent name and level', (tester) async {
      await _pump(
        tester,
        _wrapData(child: const TopPerformerHero(), scorecards: [_scorecard()]),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('LV 7'), findsOneWidget);
      expect(find.text('TOP PERFORMER'), findsOneWidget);
    });

    testWidgets('renders agent avatar initial', (tester) async {
      await _pump(
        tester,
        _wrapData(child: const TopPerformerHero(), scorecards: [_scorecard()]),
      );

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('renders trophy icon in data state header', (tester) async {
      await _pump(
        tester,
        _wrapData(child: const TopPerformerHero(), scorecards: [_scorecard()]),
      );

      expect(find.byIcon(LucideIcons.trophy), findsOneWidget);
    });

    testWidgets('shows level progress bar', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(levelProgress: 0.6)],
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders all four stat columns', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(totalRuns: 42)],
        ),
      );

      expect(find.text('42'), findsOneWidget);
      expect(find.text('93%'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
    });

    // ── Data: XP selection ──

    testWidgets('selects agent with highest XP from multiple', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [
            _scorecard(agentId: 'low', agentName: 'Bob', totalXp: 500),
            _scorecard(agentId: 'high', agentName: 'Alice', totalXp: 9999),
            _scorecard(agentId: 'mid', agentName: 'Charlie', totalXp: 3000),
          ],
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
      expect(find.text('Charlie'), findsNothing);
    });

    // ── Data: edge values ──

    testWidgets('zero success rate renders 0%', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(successRate: 0.0)],
        ),
      );

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('perfect success rate renders 100%', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(successRate: 1.0)],
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('shows rounded success rate', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(successRate: 0.8765)],
        ),
      );

      expect(find.text('88%'), findsOneWidget);
    });

    testWidgets('shows compact XP for large numbers', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(totalXp: 1500000)],
        ),
      );

      expect(find.text('1.5M XP'), findsOneWidget);
    });

    testWidgets('clamps level progress > 1.0', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(levelProgress: 1.5)],
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('clamps negative level progress', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(levelProgress: -0.5)],
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders without crash for minimum values', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [
            _scorecard(
              totalRuns: 0,
              totalErrored: 0,
              successRate: 0.0,
              totalPrsMerged: 0,
              totalReviews: 0,
              totalXp: 0,
              level: 1,
              levelProgress: 0.0,
            ),
          ],
        ),
      );

      expect(find.text('0'), findsNWidgets(3));
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0 XP'), findsOneWidget);
      expect(find.text('LV 1'), findsOneWidget);
    });

    testWidgets('renders without crash for maximum values', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [
            _scorecard(
              totalRuns: 999999,
              totalPrsMerged: 999999,
              totalReviews: 999999,
              totalXp: 9999999,
              level: 99,
              levelProgress: 1.0,
            ),
          ],
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    // ── Data: name edge cases ──

    testWidgets('handles agent with very long name', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [
            _scorecard(agentName: 'Alexandra Bartholomew Cunningham-Smith'),
          ],
        ),
      );

      expect(find.byType(TopPerformerHero), findsOneWidget);
    });

    testWidgets('handles agent with empty name', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(agentName: '')],
        ),
      );

      expect(find.byType(TopPerformerHero), findsOneWidget);
    });

    // ── Data: sparkline ──

    testWidgets('renders sparkline when daily stats available', (tester) async {
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final yesterday = todayMidnight.subtract(const Duration(days: 1));

      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard()],
          dailyStats: [_dailyStat(date: yesterday, runsCompleted: 3)],
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('sparkline renders with empty daily stats as zero series',
        (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard()],
          dailyStats: const [],
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('sparkline accumulates runs for same day', (tester) async {
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final yesterday = todayMidnight.subtract(const Duration(days: 1));

      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard()],
          dailyStats: [
            _dailyStat(date: yesterday, runsCompleted: 2),
            _dailyStat(date: yesterday, runsCompleted: 3),
          ],
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
    });

    // ── Data: daily stats loading ──

    testWidgets('renders body while daily stats are loading', (tester) async {
      await _pump(
        tester,
        testWrap(
          ProviderScope(
            overrides: [
              allAgentScorecardsProvider.overrideWith(
                (ref) => Future.value([_scorecard()]),
              ),
              dailyStatsByDateRangeProvider.overrideWith(
                (ref, params) =>
                    const Stream<List<AgentDailyStats>>.empty(),
              ),
            ],
            child: const TopPerformerHero(),
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
    });
    // ── Data: tie-breaking ──

    testWidgets('tie on XP shows exactly one agent', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [
            _scorecard(agentId: 'a', agentName: 'Alice', totalXp: 5000),
            _scorecard(agentId: 'b', agentName: 'Bob', totalXp: 5000),
          ],
        ),
      );

      // Stable sort keeps first; only one agent rendered.
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
    });

    // ── Data: large stat numbers ──

    testWidgets('renders total runs 1000000 without crash', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(totalRuns: 1000000)],
        ),
      );

      expect(find.text('1000000'), findsOneWidget);
    });

    // ── Data: level zero ──

    testWidgets('renders agent with level 0', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(level: 0)],
        ),
      );

      expect(find.text('LV 0'), findsOneWidget);
    });

    // ── Data: level very high ──

    testWidgets('renders agent with level 99', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(level: 99)],
        ),
      );

      expect(find.text('LV 99'), findsOneWidget);
    });

    // ── Data: success rate at exactly 50% ──

    testWidgets('renders success rate exactly 50%', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(successRate: 0.5)],
        ),
      );

      expect(find.text('50%'), findsOneWidget);
    });

    // ── Data: level progress at bounds ──

    testWidgets('renders level progress at exactly 0.0', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(levelProgress: 0.0)],
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders level progress at exactly 1.0', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(levelProgress: 1.0)],
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    // ── Data: total reviews zero ──

    testWidgets('renders total reviews as 0', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(totalReviews: 0)],
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    // ── Data: many daily stat data points ──

    testWidgets('renders sparkline with 30 days of data', (tester) async {
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final stats = List.generate(
        30,
        (i) => _dailyStat(
          date: todayMidnight.subtract(Duration(days: 29 - i)),
          runsCompleted: (i % 5) + 1,
        ),
      );

      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard()],
          dailyStats: stats,
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
    });

    // ── Data: agent name with dash ──

    testWidgets('renders agent name containing a dash', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(agentName: 'Alex-Cruz')],
        ),
      );

      expect(find.text('Alex-Cruz'), findsOneWidget);
    });


    // ── Data: success rate rounding down ──

    testWidgets('rounds 0.934 success rate down to 93%', (tester) async {
      await _pump(
        tester,
        _wrapData(
          child: const TopPerformerHero(),
          scorecards: [_scorecard(successRate: 0.934)],
        ),
      );

      expect(find.text('93%'), findsOneWidget);
    });
  });
}
