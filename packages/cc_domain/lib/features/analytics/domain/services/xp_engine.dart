import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/features/analytics/domain/repositories/achievement_repository.dart';
import 'package:cc_domain/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:cc_domain/features/analytics/domain/repositories/streak_repository.dart';

/// Xp engine.
class XpEngine {
  /// Creates a new [XpEngine].
  XpEngine(
    this._eventBus,
    this._analyticsRepo,
    this._achievementRepo,
    this._streakRepo,
  ) {
    _init();
  }

  final DomainEventBus _eventBus;
  final AnalyticsRepository _analyticsRepo;
  final AchievementRepository _achievementRepo;
  final StreakRepository _streakRepo;

  StreamSubscription<PrMerged>? _prMergedSub;

  void _init() {
    _prMergedSub = _eventBus.on<PrMerged>().listen(_onPrMerged);
  }

  /// Cancels event subscriptions and releases resources.
  void dispose() {
    _prMergedSub?.cancel();
  }

  Future<void> _onPrMerged(PrMerged event) async {
    // The PrMerged event carries the owning workspaceId, so the engine never
    // needs a separate agent lookup — it threads it into the now
    // workspace-scoped repository calls.
    final workspaceId = event.workspaceId;
    final agentId = event.agentId;

    await _streakRepo.updateStreak(workspaceId, agentId, 'pr_merged', increment: true);
    await _streakRepo.updateStreak(workspaceId, agentId, 'daily_active', increment: true);

    await _achievementRepo.unlock(workspaceId, agentId, 'first_merge');
    await _checkLifetimeAchievements(workspaceId, agentId);
  }

  Future<void> _checkLifetimeAchievements(
    String workspaceId,
    String agentId,
  ) async {
    try {
      final scorecard =
          await _analyticsRepo.getAgentScorecard(workspaceId, agentId);
      if (scorecard == null) {
        return;
      }

      if (scorecard.totalRuns >= 100) {
        await _achievementRepo.unlock(workspaceId, agentId, 'centurion');
      }
      if (scorecard.totalPrsCreated >= 10) {
        await _achievementRepo.unlock(workspaceId, agentId, 'pr_machine');
      }
      if (scorecard.totalPrsMerged >= 10) {
        await _achievementRepo.unlock(workspaceId, agentId, 'merge_master');
      }
      if (scorecard.totalBlockingComments >= 10) {
        await _achievementRepo.unlock(workspaceId, agentId, 'sharpshooter');
      }
    } catch (_) {}
  }
}
