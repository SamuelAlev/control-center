import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/achievement_dao.dart';
import 'package:control_center/core/database/daos/agent_dao.dart';
import 'package:control_center/core/database/daos/agent_working_memory_dao.dart';
import 'package:control_center/core/database/daos/analytics_dao.dart';
import 'package:control_center/core/database/daos/cache_dao.dart';
import 'package:control_center/core/database/daos/code_graph_dao.dart';
import 'package:control_center/core/database/daos/isolated_repo_dao.dart';
import 'package:control_center/core/database/daos/memory_access_grant_dao.dart';
import 'package:control_center/core/database/daos/memory_domain_dao.dart';
import 'package:control_center/core/database/daos/memory_fact_dao.dart';
import 'package:control_center/core/database/daos/memory_policy_dao.dart';
import 'package:control_center/core/database/daos/messaging_dao.dart';
import 'package:control_center/core/database/daos/project_dao.dart';
import 'package:control_center/core/database/daos/pull_request_dao.dart';
import 'package:control_center/core/database/daos/repo_dao.dart';
import 'package:control_center/core/database/daos/review_channel_dao.dart';
import 'package:control_center/core/database/daos/review_dao.dart';
import 'package:control_center/core/database/daos/rss_dao.dart';
import 'package:control_center/core/database/daos/streak_dao.dart';
import 'package:control_center/core/database/daos/ticket_dao.dart';
import 'package:control_center/core/database/daos/ticket_link_dao.dart';
import 'package:control_center/core/database/daos/workspace_dao.dart';
import 'package:control_center/core/database/repositories/dao_cache_repository.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/repositories/cache_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the application database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provides the [WorkspaceDao].
final workspaceDaoProvider = Provider<WorkspaceDao>((ref) {
  return ref.watch(databaseProvider).workspaceDao;
});

/// Provides the [RepoDao].
final repoDaoProvider = Provider<RepoDao>((ref) {
  return ref.watch(databaseProvider).repoDao;
});

/// Provides the [IsolatedRepoDao].
final isolatedRepoDaoProvider = Provider<IsolatedRepoDao>((ref) {
  return ref.watch(databaseProvider).isolatedRepoDao;
});

/// Provides the [AgentDao].
final agentDaoProvider = Provider<AgentDao>((ref) {
  return ref.watch(databaseProvider).agentDao;
});


/// Provides the [MessagingDao].
final messagingDaoProvider = Provider<MessagingDao>((ref) {
  return ref.watch(databaseProvider).messagingDao;
});

/// Provides the [TicketDao].
final ticketDaoProvider = Provider<TicketDao>((ref) {
  return ref.watch(databaseProvider).ticketDao;
});

/// Provides the [TicketLinkDao].
final ticketLinkDaoProvider = Provider<TicketLinkDao>((ref) {
  return ref.watch(databaseProvider).ticketLinkDao;
});

/// Provides the [ProjectDao].
final projectDaoProvider = Provider<ProjectDao>((ref) {
  return ref.watch(databaseProvider).projectDao;
});

/// Provides the [ReviewDao].
final reviewDaoProvider = Provider<ReviewDao>((ref) {
  return ref.watch(databaseProvider).reviewDao;
});

/// Provides the [ReviewChannelDao].
final reviewChannelDaoProvider = Provider<ReviewChannelDao>((ref) {
  return ref.watch(databaseProvider).reviewChannelDao;
});

/// Provides the [PullRequestDao].
final pullRequestDaoProvider = Provider<PullRequestDao>((ref) {
  return ref.watch(databaseProvider).pullRequestDao;
});


/// Provides the generic [CacheDao].
final cacheDaoProvider = Provider<CacheDao>((ref) {
  return ref.watch(databaseProvider).cacheDao;
});

/// Provides the [CacheRepository] port backed by [CacheDao].
final cacheRepositoryProvider = Provider<CacheRepository>((ref) {
  return DaoCacheRepository(ref.watch(cacheDaoProvider));
});

/// Provides the [RssDao].
final rssDaoProvider = Provider<RssDao>((ref) {
  return ref.watch(databaseProvider).rssDao;
});

/// Provides the [AnalyticsDao].
final analyticsDaoProvider = Provider<AnalyticsDao>((ref) {
  return ref.watch(databaseProvider).analyticsDao;
});

/// Provides the [AchievementDao].
final achievementDaoProvider = Provider<AchievementDao>((ref) {
  return ref.watch(databaseProvider).achievementDao;
});

/// Provides the [StreakDao].
final streakDaoProvider = Provider<StreakDao>((ref) {
  return ref.watch(databaseProvider).streakDao;
});

final memoryAccessGrantDaoProvider = Provider<MemoryAccessGrantDao>((ref) {
  return ref.watch(databaseProvider).memoryAccessGrantDao;
});

/// Provides the application-wide [DomainEventBus].
final domainEventBusProvider = Provider<DomainEventBus>((ref) {
  final bus = DomainEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final agentWorkingMemoryDaoProvider = Provider<AgentWorkingMemoryDao>((ref) {
  return ref.watch(databaseProvider).agentWorkingMemoryDao;
});

final memoryFactDaoProvider = Provider<MemoryFactDao>((ref) {
  return ref.watch(databaseProvider).memoryFactDao;
});

final codeGraphDaoProvider = Provider<CodeGraphDao>((ref) {
  return ref.watch(databaseProvider).codeGraphDao;
});

final memoryPolicyDaoProvider = Provider<MemoryPolicyDao>((ref) {
  return ref.watch(databaseProvider).memoryPolicyDao;
});

final memoryDomainDaoProvider = Provider<MemoryDomainDao>((ref) {
  return ref.watch(databaseProvider).memoryDomainDao;
});

