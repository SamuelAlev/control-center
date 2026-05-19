import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_domain/features/remote_control/domain/repositories/paired_device_repository.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/achievement_dao.dart';
import 'package:cc_persistence/database/daos/activity_log_dao.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/database/daos/agent_working_memory_dao.dart';
import 'package:cc_persistence/database/daos/analytics_dao.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/daos/calendar_dao.dart';
import 'package:cc_persistence/database/daos/code_graph_dao.dart';
import 'package:cc_persistence/database/daos/episodic_edge_dao.dart';
import 'package:cc_persistence/database/daos/isolated_repo_dao.dart';
import 'package:cc_persistence/database/daos/meeting_dao.dart';
import 'package:cc_persistence/database/daos/memory_access_grant_dao.dart';
import 'package:cc_persistence/database/daos/memory_belief_dao.dart';
import 'package:cc_persistence/database/daos/memory_conflict_dao.dart';
import 'package:cc_persistence/database/daos/memory_consolidation_log_dao.dart';
import 'package:cc_persistence/database/daos/memory_domain_dao.dart';
import 'package:cc_persistence/database/daos/memory_fact_dao.dart';
import 'package:cc_persistence/database/daos/memory_policy_dao.dart';
import 'package:cc_persistence/database/daos/messaging_dao.dart';
import 'package:cc_persistence/database/daos/orchestration_dao.dart';
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_persistence/database/daos/project_dao.dart';
import 'package:cc_persistence/database/daos/pull_request_dao.dart';
import 'package:cc_persistence/database/daos/repo_dao.dart';
import 'package:cc_persistence/database/daos/review_channel_dao.dart';
import 'package:cc_persistence/database/daos/review_dao.dart';
import 'package:cc_persistence/database/daos/rss_dao.dart';
import 'package:cc_persistence/database/daos/streak_dao.dart';
import 'package:cc_persistence/database/daos/ticket_dao.dart';
import 'package:cc_persistence/database/daos/ticket_link_dao.dart';
import 'package:cc_persistence/database/daos/voice_profile_dao.dart';
import 'package:cc_persistence/database/daos/working_memory_item_dao.dart';
import 'package:cc_persistence/database/daos/workspace_dao.dart';
import 'package:cc_persistence/repositories/dao_cache_repository.dart';
import 'package:cc_persistence/repositories/dao_paired_device_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The desktop is a THIN CLIENT: it spawns a local `cc_server` (which owns the
/// database) and talks to it over RPC, so it never opens a Drift connection
/// itself. Reading [databaseProvider] is therefore a bug — every UI/data path
/// must go through `rpcClientProvider` (overridden at boot with the connected
/// client). This throws loudly rather than silently opening a second DB handle.
///
/// The `dao*` providers below remain only so the (kept-for-reference) in-process
/// composition still type-checks; they are never read on the thin client (the
/// in-process host is not constructed and the server-side services run inside
/// the spawned `cc_server`).
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnsupportedError(
    'The desktop is a thin client and does not open a database. All data flows '
    'through rpcClientProvider (the spawned cc_server owns the DB). Reaching '
    'databaseProvider means a provider bypassed the RPC path.',
  );
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

/// Provides the [OrchestrationDao].
final orchestrationDaoProvider = Provider<OrchestrationDao>((ref) {
  return ref.watch(databaseProvider).orchestrationDao;
});

/// Provides the [ActivityLogDao].
final activityLogDaoProvider = Provider<ActivityLogDao>((ref) {
  return ref.watch(databaseProvider).activityLogDao;
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

/// Provides the [MemoryAccessGrantDao].
final memoryAccessGrantDaoProvider = Provider<MemoryAccessGrantDao>((ref) {
  return ref.watch(databaseProvider).memoryAccessGrantDao;
});

/// Provides the [AgentWorkingMemoryDao].
final agentWorkingMemoryDaoProvider = Provider<AgentWorkingMemoryDao>((ref) {
  return ref.watch(databaseProvider).agentWorkingMemoryDao;
});

/// Provides the [MemoryFactDao].
final memoryFactDaoProvider = Provider<MemoryFactDao>((ref) {
  return ref.watch(databaseProvider).memoryFactDao;
});

/// Provides the [MeetingDao].
final meetingDaoProvider = Provider<MeetingDao>((ref) {
  return ref.watch(databaseProvider).meetingDao;
});

/// Provides the [CalendarDao].
final calendarDaoProvider = Provider<CalendarDao>((ref) {
  return ref.watch(databaseProvider).calendarDao;
});

/// Provides the [VoiceProfileDao].
final voiceProfileDaoProvider = Provider<VoiceProfileDao>((ref) {
  return ref.watch(databaseProvider).voiceProfileDao;
});

/// Provides the [CodeGraphDao].
final codeGraphDaoProvider = Provider<CodeGraphDao>((ref) {
  return ref.watch(databaseProvider).codeGraphDao;
});

/// Provides the [MemoryPolicyDao].
final memoryPolicyDaoProvider = Provider<MemoryPolicyDao>((ref) {
  return ref.watch(databaseProvider).memoryPolicyDao;
});

/// Provides the [MemoryDomainDao].
final memoryDomainDaoProvider = Provider<MemoryDomainDao>((ref) {
  return ref.watch(databaseProvider).memoryDomainDao;
});

/// Provides the [MemoryConflictDao] (PRD 04 memory intelligence).
final memoryConflictDaoProvider = Provider<MemoryConflictDao>((ref) {
  return ref.watch(databaseProvider).memoryConflictDao;
});

/// Provides the [EpisodicEdgeDao] (semantic memory graph).
final episodicEdgeDaoProvider = Provider<EpisodicEdgeDao>((ref) {
  return ref.watch(databaseProvider).episodicEdgeDao;
});

/// Provides the [WorkingMemoryItemDao] (hot working-memory tier).
final workingMemoryItemDaoProvider = Provider<WorkingMemoryItemDao>((ref) {
  return ref.watch(databaseProvider).workingMemoryItemDao;
});

/// Provides the [MemoryConsolidationLogDao] (consolidation pass audit).
final memoryConsolidationLogDaoProvider =
    Provider<MemoryConsolidationLogDao>((ref) {
  return ref.watch(databaseProvider).memoryConsolidationLogDao;
});

/// Provides the [MemoryBeliefDao] (harmonized cross-agent beliefs).
final memoryBeliefDaoProvider = Provider<MemoryBeliefDao>((ref) {
  return ref.watch(databaseProvider).memoryBeliefDao;
});

/// Provides the [PairedDeviceDao] (paired remote-control devices).
final pairedDeviceDaoProvider = Provider<PairedDeviceDao>((ref) {
  return ref.watch(databaseProvider).pairedDeviceDao;
});

/// Provides the [PairedDeviceRepository] port backed by [PairedDeviceDao]. The
/// remote-control UI reads paired devices through this domain interface (no
/// drift in the presentation/provider layer).
final pairedDeviceRepositoryProvider = Provider<PairedDeviceRepository>((ref) {
  return DaoPairedDeviceRepository(ref.watch(pairedDeviceDaoProvider));
});

