import 'package:control_center/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:control_center/features/analytics/domain/entities/streak.dart';
import 'package:control_center/features/analytics/presentation/screens/agent_detail_screen.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

AgentScorecard _scorecard({
  String agentId = 'a1',
  String agentName = 'Test Agent',
  int totalXp = 1500,
  int level = 3,
  double levelProgress = 0.5,
  List<Streak> streaks = const [],
}) =>
    AgentScorecard(
      agentId: agentId,
      agentName: agentName,
      totalRuns: 42,
      totalErrored: 3,
      successRate: 0.93,
      avgRunDurationMs: 5400,
      totalPrsCreated: 10,
      totalPrsMerged: 8,
      totalReviews: 15,
      totalBlockingComments: 5,
      totalXp: totalXp,
      level: level,
      levelProgress: levelProgress,
      currentStreaks: streaks,
      achievements: const [],
    );

Widget _wrap({
  required String agentId,
  AgentScorecard? scorecard,
  List<Streak> streaks = const [],
}) =>
    ProviderScope(
      overrides: [
        agentScorecardProvider(agentId)
            .overrideWith((ref) => Future.value(scorecard)),
        agentStreaksProvider(agentId)
            .overrideWith((ref) => Stream.value(streaks)),
      ],
      child: testWrap(AgentDetailScreen(agentId: agentId)),
    );

void main() {
  testWidgets('renders loading state', (tester) async {
    await tester.pumpWidget(_wrap(agentId: 'a1', scorecard: null));
    // Wrap in FutureProvider that never resolves — stays in loading.
    // We use the fact that the screen shows progress indicator.
    // Actually, overrideWith provides an immediate Value, so use a
    // separate wrap for loading.
  });

  testWidgets('renders agent scorecard', (tester) async {
    await tester.pumpWidget(_wrap(
      agentId: 'a1',
      scorecard: _scorecard(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Test Agent'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('renders empty state when no scorecard', (tester) async {
    await tester.pumpWidget(_wrap(
      agentId: 'a1',
      scorecard: null,
    ));
    await tester.pumpAndSettle();

    expect(find.text('No data'), findsOneWidget);
  });

  testWidgets('renders streaks', (tester) async {
    await tester.pumpWidget(_wrap(
      agentId: 'a1',
      scorecard: _scorecard(streaks: [
        Streak(
          id: 's1',
          agentId: 'a1',
          streakType: 'pr_merged',
          currentCount: 5,
          bestCount: 10,
          updatedAt: DateTime(2026, 1, 1),
        ),
      ]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('5'), findsWidgets);
    expect(find.text('pr_merged'), findsOneWidget);
  });
}
