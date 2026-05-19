import 'dart:async';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/analytics/data/datasources/xp_engine.dart';
import 'package:control_center/features/analytics/domain/entities/achievement.dart';
import 'package:control_center/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:control_center/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:control_center/features/analytics/domain/entities/leaderboard_entry.dart';
import 'package:control_center/features/analytics/domain/entities/streak.dart';
import 'package:control_center/features/analytics/domain/entities/user_badge.dart';
import 'package:control_center/features/analytics/domain/entities/workspace_health.dart';
import 'package:control_center/features/analytics/domain/repositories/achievement_repository.dart';
import 'package:control_center/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:control_center/features/analytics/domain/repositories/streak_repository.dart';
import 'package:control_center/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// Stub [AnalyticsRepository] that returns empty/neutral values for all
/// methods, keeping tests self-contained without a drift database.
class _StubAnalyticsRepository implements AnalyticsRepository {
  @override
  Stream<List<AgentDailyStats>> watchByAgent(String agentId) =>
      const Stream.empty();

  @override
  Stream<List<AgentDailyStats>> watchByAgentDateRange(
    String agentId,
    DateTime start,
    DateTime end,
  ) =>
      const Stream.empty();

  @override
  Stream<List<AgentDailyStats>> watchAllByDateRange(
    DateTime start,
    DateTime end,
  ) =>
      const Stream.empty();

  @override
  Future<AgentScorecard?> getAgentScorecard(String agentId) async => null;

  @override
  Future<List<AgentScorecard>> getAllAgentScorecards() async => const [];

  @override
  Future<List<LeaderboardEntry>> getLeaderboard(
    DateTime start,
    DateTime end,
  ) async =>
      const [];

  @override
  Future<WorkspaceHealth?> getWorkspaceHealth(String workspaceId) async =>
      null;

  @override
  Future<List<WorkspaceHealth>> getAllWorkspaceHealth() async => const [];

  @override
  Future<void> rebuildDailyStats() async {}

  @override
  Future<void> backfillHistoricalData() async {}
}

/// Stub [AchievementRepository] with no-op / empty returns.
class _StubAchievementRepository implements AchievementRepository {
  @override
  Stream<List<Achievement>> watchByAgent(String agentId) =>
      const Stream.empty();

  @override
  Future<List<Achievement>> getByAgent(String agentId) async => const [];

  @override
  Future<void> unlock(
    String agentId,
    String badgeKey, {
    String? metadata,
  }) async {}

  @override
  Future<bool> isUnlocked(String agentId, String badgeKey) async => false;
}

/// Stub [StreakRepository] with no-op / empty returns.
class _StubStreakRepository implements StreakRepository {
  @override
  Stream<List<Streak>> watchByAgent(String agentId) => const Stream.empty();

  @override
  Future<List<Streak>> getByAgent(String agentId) async => const [];

  @override
  Future<void> updateStreak(
    String agentId,
    String streakType, {
    required bool increment,
  }) async {}

  @override
  Future<int> getCurrentStreak(String agentId, String streakType) async => 0;
}

/// No-op override for [SnapshotAggregatorNotifier]; skips the DB-backed
/// snapshot aggregator so tests don't need a drift database.
class _StubSnapshotAggregatorNotifier extends SnapshotAggregatorNotifier {
  @override
  void build() {}
}

/// Fixed workspace-id notifier for tests; always returns a constant id
/// so widgets that depend on [activeWorkspaceIdProvider] get a non-null value.
class _FixedWorkspaceId extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceId(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

/// Builds the analytics screen with every analytics-backed provider stubbed to
/// empty/neutral values so tests never touch the real database.
Widget _wrap() => ProviderScope(
      overrides: [
        // --- Providers directly watched by AnalyticsScreen ---
        xpEngineProvider.overrideWith(
          (ref) => XpEngine(
            DomainEventBus(),
            _StubAnalyticsRepository(),
            _StubAchievementRepository(),
            _StubStreakRepository(),
          ),
        ),
        snapshotAggregatorProvider
            .overrideWith(_StubSnapshotAggregatorNotifier.new),
        allAgentScorecardsProvider
            .overrideWith((ref) => Future.value(<AgentScorecard>[])),

        // --- Providers watched by child widgets ---
        userBadgesProvider
            .overrideWith((ref) => Future.value(<UserBadge>[])),
        leaderboardProvider
            .overrideWith((ref) => Future.value(<LeaderboardEntry>[])),
        allWorkspaceHealthProvider
            .overrideWith((ref) => Future.value(<WorkspaceHealth>[])),
        dailyStatsByDateRangeProvider
            .overrideWith((ref, params) => const Stream.empty()),
        allDailyStatsByDateRangeProvider
            .overrideWith((ref, params) => const Stream.empty()),
        agentsProvider
            .overrideWith((ref) => const Stream<List<Agent>>.empty()),
        workspaceAgentsProvider
            .overrideWith((ref, workspaceId) => const Stream.empty()),
        activeWorkspaceIdProvider.overrideWith(() => _FixedWorkspaceId('ws1')),
      ],
      child: testWrap(const AnalyticsScreen()),
    );

void main() {
  testWidgets('renders screen', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    await tester.pump();

    // AnalyticsScreen renders a PageWrapper containing TopPerformerHero,
    // AgentsRoster, LeaderboardCard, WorkspacePulseCard, ActivityHeatmapCard,
    // and UserBadgesCard. With empty data the screen shows the shell.
    expect(find.byType(AnalyticsScreen), findsOneWidget);
  });

  testWidgets('renders with title', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    await tester.pump();

    expect(find.text('Analytics'), findsOneWidget);
  });

  testWidgets('renders with subtitle', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Top performers, throughput, and workspace health.'),
      findsOneWidget,
    );
  });
}
