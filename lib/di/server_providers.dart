// VM-ONLY composition root (server-side execution half of `di/providers.dart`).
//
// This file holds every provider backed by a VM-only service or package —
// the Drift-backed `dao*` repositories (cc_persistence), the cc_infra-backed
// services (git command / git repo inspector / pr-worktree / repo provisioner /
// worktree-gc / sandbox-backend-detector / process-control / filesystem ports'
// concrete impls), cc_natives (rift / fff / tree-sitter / grammar), cc_server_core
// (the VCS catalog factory), the embedding service, the sandboxing dispatch
// adapter, the plugin audio capture, doctor, the cost tracker, the calendar
// OAuth/Google services, the desktop notification delivery, and all the
// memory/dispatch/seeding use-cases that own the database directly.
//
// It is reachable ONLY from the VM-only callers — `lib/bootstrap/bootstrap_io.dart`,
// the RPC catalog (`features/remote_control/providers/remote_control_server_provider.dart`),
// the MCP tool wiring (`features/mcp/**`), and the VM-only `*_server.dart`
// halves of the feature provider files. It MUST NOT be reachable from the web
// graph: importing it would drag cc_infra/cc_natives/cc_persistence/cc_server_core
// (dart:io + dart:ffi) into `flutter build web` and break it.
//
// It re-exports the web-safe `providers.dart` so the VM-only callers get the
// full provider surface (web-safe RpcX repos + these server-side providers) from
// a single import.
library;

import 'package:cc_domain/core/domain/ports/conversation_mode_resolver.dart';
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart';
import 'package:cc_domain/core/domain/ports/git_command_port.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/ports/notification_port.dart';
import 'package:cc_domain/core/domain/ports/pr_worktree_port.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/ports/system_audio_capture_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/services/activity_logger.dart';
import 'package:cc_domain/core/domain/services/domain_event_audit_bridge.dart';
import 'package:cc_domain/core/domain/value_objects/app_locale.dart';
import 'package:cc_domain/features/agents/domain/ports/doctor_port.dart';
import 'package:cc_domain/features/analytics/domain/repositories/achievement_repository.dart';
import 'package:cc_domain/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:cc_domain/features/analytics/domain/repositories/streak_repository.dart';
import 'package:cc_domain/features/analytics/domain/services/xp_engine.dart';
import 'package:cc_domain/features/auth/domain/ports/github_cli_port.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_domain/features/code_graph/domain/services/code_indexer.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_memory_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/episodic_edge_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_belief_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_conflict_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/working_memory_item_repository.dart';
import 'package:cc_domain/features/memory/domain/services/fact_extraction.dart';
import 'package:cc_domain/features/memory/domain/services/memory_consolidation_service.dart';
import 'package:cc_domain/features/memory/domain/usecases/extract_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/harmonize_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/memory_cleanup_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/promote_facts_to_policy_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/record_memory_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/supersede_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/supersede_policy_use_case.dart';
import 'package:cc_domain/features/messaging/domain/repositories/channel_read_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/usecases/backfill_message_embeddings_use_case.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_validator.dart';
import 'package:cc_domain/features/pr_review/domain/providers/vcs_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/repos/domain/usecases/add_repo_from_path.dart';
import 'package:cc_domain/features/settings/domain/repositories/acp_model_repository.dart';
import 'package:cc_domain/features/settings/domain/repositories/adapter_repository.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_infra/src/pr_review/pr_worktree_service.dart';
import 'package:cc_infra/src/repos/repo_workspace_provisioner.dart';
import 'package:cc_infra/src/repos/worktree_gc_listener.dart';
import 'package:cc_infra/src/sandboxing/sandbox_backend_detector.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:cc_persistence/repositories/achievement_repository_impl.dart';
import 'package:cc_persistence/repositories/analytics_repository_impl.dart';
import 'package:cc_persistence/repositories/dao_agent_repository.dart';
import 'package:cc_persistence/repositories/dao_agent_run_log_repository.dart';
import 'package:cc_persistence/repositories/dao_agent_working_memory_repository.dart';
import 'package:cc_persistence/repositories/dao_calendar_repository.dart';
import 'package:cc_persistence/repositories/dao_channel_read_repository.dart';
import 'package:cc_persistence/repositories/dao_episodic_edge_repository.dart';
import 'package:cc_persistence/repositories/dao_isolated_repo_repository.dart';
import 'package:cc_persistence/repositories/dao_meeting_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_access_grant_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_belief_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_conflict_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_domain_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_fact_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_policy_repository.dart';
import 'package:cc_persistence/repositories/dao_working_memory_item_repository.dart';
import 'package:cc_persistence/repositories/dao_messaging_repository.dart';
import 'package:cc_persistence/repositories/dao_orchestration_repository.dart';
import 'package:cc_persistence/repositories/dao_project_repository.dart';
import 'package:cc_persistence/repositories/dao_repo_repository.dart';
import 'package:cc_persistence/repositories/dao_review_channel_repository.dart';
import 'package:cc_persistence/repositories/dao_ticket_link_repository.dart';
import 'package:cc_persistence/repositories/dao_ticket_repository.dart';
import 'package:cc_persistence/repositories/dao_voice_profile_repository.dart';
import 'package:cc_persistence/repositories/dao_workspace_repository.dart';
import 'package:cc_persistence/repositories/db_conversation_mode_resolver.dart';
import 'package:cc_persistence/repositories/pipeline_run_repository_impl.dart';
import 'package:cc_persistence/repositories/pipeline_template_repository_impl.dart';
import 'package:cc_persistence/repositories/pipeline_trigger_repository_impl.dart';
import 'package:cc_persistence/repositories/streak_repository_impl.dart';
import 'package:cc_persistence/repositories/team_repository_impl.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:cc_server_core/src/github_vcs_provider_factory.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_providers.dart';
import 'package:control_center/core/notifications/desktop_notification_delivery.dart';
import 'package:control_center/core/notifications/notification_center.dart';
import 'package:control_center/core/notifications/notification_service.dart';
import 'package:control_center/core/notifications/recording_notification_port.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/data/services/cost_tracker.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/meetings/data/adapters/plugin_system_audio_capture.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers_server.dart';
import 'package:control_center/features/sandboxing/data/adapters/confirmation_port_adapter.dart'
    show confirmationPortProvider;
import 'package:control_center/features/settings/providers/adapter_preferences_providers.dart';
import 'package:control_center/features/settings/providers/branch_template_provider.dart';
import 'package:control_center/features/shell/providers/current_route_provider.dart';
import 'package:control_center/features/workspaces/domain/usecases/seed_ceo_agent_use_case.dart';
import 'package:control_center/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:control_center/di/providers.dart';

// ── Server-side Dao repositories (composition-flip slice 1) ──────────────────
//
// These Drift-backed repositories are the data the IN-PROCESS RPC server
// (`rpcClientProvider` → `InProcessRpcHost`) serves. They are DECOUPLED from the
// feature providers of the same name (`ticketRepositoryProvider`, …), which now
// resolve to the cc_data `RpcX` adapters that talk to this server — so flipping
// a feature provider to RPC does not recurse back into the catalog. The
// in-process server is the SOLE DB owner for these repos; the UI reaches them
// only over RPC. (The catalog provider in remote_control wires these into
// `buildRemoteRpcCatalog`.)

/// Server-side Drift [TicketRepository] backing the RPC catalog.
final daoTicketRepositoryProvider = Provider<TicketRepository>((ref) {
  return DaoTicketRepository(ref.watch(ticketDaoProvider));
});

/// Server-side Drift [ProjectRepository] backing the RPC catalog.
final daoProjectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return DaoProjectRepository(ref.watch(projectDaoProvider));
});

/// Server-side Drift [TicketLinkRepository] backing the RPC catalog.
final daoTicketLinkRepositoryProvider = Provider<TicketLinkRepository>((ref) {
  return DaoTicketLinkRepository(ref.watch(ticketLinkDaoProvider));
});

/// Server-side Drift [PipelineRunRepository] backing the RPC catalog.
final daoPipelineRunRepositoryProvider = Provider<PipelineRunRepository>((ref) {
  return PipelineRunRepositoryImpl(ref.watch(databaseProvider).pipelineDao);
});

/// Server-side Drift [PipelineTemplateRepository] backing the RPC catalog.
///
/// Keeps the save-time output-schema validation the desktop provider used to do
/// (the validation now lives on the write path, server-side).
final daoPipelineTemplateRepositoryProvider =
    Provider<PipelineTemplateRepository>((ref) {
      return PipelineTemplateRepositoryImpl(
        ref.watch(databaseProvider).pipelineTemplateDao,
        validator: PipelineValidator(
          schemaValidator: ref.watch(schemaValidatorProvider),
        ),
      );
    });

/// Server-side Drift [PipelineTriggerRepository] backing the RPC catalog.
final daoPipelineTriggerRepositoryProvider =
    Provider<PipelineTriggerRepository>((ref) {
      return PipelineTriggerRepositoryImpl(
        ref.watch(databaseProvider).pipelineTriggerDao,
      );
    });

/// Server-side Drift [TeamRepository] backing the RPC catalog.
final daoTeamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepositoryImpl(ref.watch(databaseProvider).teamDao);
});

/// Server-side Drift [OrchestrationRepository] backing the RPC catalog.
final daoOrchestrationRepositoryProvider = Provider<OrchestrationRepository>((
  ref,
) {
  return DaoOrchestrationRepository(ref.watch(orchestrationDaoProvider));
});

// ── Server-side Dao repositories (composition-flip slice 2) ──────────────────

/// Server-side Drift [AgentRepository] backing the RPC catalog + tools.
final daoAgentRepositoryProvider = Provider<AgentRepository>((ref) {
  return DaoAgentRepository(ref.watch(agentDaoProvider));
});

/// Server-side Drift [AgentRunLogRepository] backing the RPC catalog + tools.
final daoAgentRunLogRepositoryProvider = Provider<AgentRunLogRepository>((ref) {
  return DaoAgentRunLogRepository(ref.watch(agentDaoProvider));
});

/// Server-side Drift [RepoRepository] backing the RPC catalog + tools.
final daoRepoRepositoryProvider = Provider<RepoRepository>((ref) {
  return DaoRepoRepository(ref.watch(repoDaoProvider));
});

/// Server-side Drift [ChannelReadRepository] backing the RPC catalog.
final daoChannelReadRepositoryProvider = Provider<ChannelReadRepository>((ref) {
  return DaoChannelReadRepository(ref.watch(messagingDaoProvider));
});

/// Server-side [LocalGitPrDiffSource] — the local blobless-clone diff source for
/// PRs that exceed GitHub's 3 000-file API cap. Host-neutral (no rpcClient dep),
/// so the catalog can read it without recursing through the in-process server.
final localGitDiffSourceProvider = Provider<LocalGitPrDiffSource>((ref) {
  return LocalGitPrDiffSource(
    git: ref.watch(gitCommandPortProvider),
    filesystem: ref.watch(workspaceFilesystemPortProvider),
    githubToken: ref.watch(githubAuthTokenProvider),
    rift: ref.watch(riftClientProvider),
  );
});

/// Server-side Dao-backed [VcsProviderFactory] backing the PR-review RPC
/// catalog.
final daoVcsProviderFactoryProvider = Provider<VcsProviderFactory>((ref) {
  return GitHubVcsProviderFactory(
    cacheDao: ref.watch(cacheDaoProvider),
    draftDao: ref.watch(reviewDaoProvider),
    gitHubClient: ref.watch(githubApiClientProvider),
    localGitSource: ref.watch(localGitDiffSourceProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Server-side Drift [WorkspaceRepository] backing the RPC catalog + tools +
/// the seeders/reconcilers/provisioning that own the DB directly.
final daoWorkspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return DaoWorkspaceRepository(ref.watch(workspaceDaoProvider));
});

/// Server-side Drift [MessagingRepository] backing the RPC catalog + tools +
/// the dispatch/stream/embedding/orchestration execution that owns the DB
/// directly (channel lifecycle, agent message posting, compaction, backfill).
final daoMessagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return DaoMessagingRepository(ref.watch(messagingDaoProvider));
});

/// Provides the [ConversationModeResolver] implementation.
final conversationModeResolverProvider = Provider<ConversationModeResolver>((
  ref,
) {
  return DbConversationModeResolver(ref.watch(messagingDaoProvider));
});

/// Provides the [GitRepoInspectorPort] implementation.
final gitRepoInspectorPortProvider = Provider<GitRepoInspectorPort>((ref) {
  return const GitRepoInspector();
});

/// Provides the [DirectoryBrowserPort] backing the web add-repo folder browser
/// (`fs.browseDirectory`). Rooted at the desktop user's home directory; a
/// connected client can navigate within it but never above it.
final directoryBrowserPortProvider = Provider<DirectoryBrowserPort>((ref) {
  return FilesystemDirectoryBrowser.forHome();
});

/// Provides the [GitCommandPort] implementation.
final gitCommandPortProvider = Provider<GitCommandPort>((ref) {
  return const ProcessGitCommandAdapter();
});

/// Provides the bundled rift copy-on-write client. Degrades to unavailable
/// (triggering the git-worktree fallback) when the native lib can't load.
final riftClientProvider = Provider<RiftClient>((ref) {
  var paths = const <String>[];
  var dbPath = 'rift.sqlite';
  try {
    paths = riftDylibCandidatePaths();
    dbPath = riftRegistryPath();
  } catch (_) {
    // App-support dir not resolvable yet — leave empty so RiftClient reports
    // unavailable and the git-worktree fallback kicks in.
  }
  return RiftClient(dylibPaths: paths, databasePath: dbPath);
});

/// Provides the [RepoIsolationPort] (rift CoW with a git-worktree fallback).
final repoIsolationPortProvider = Provider<RepoIsolationPort>((ref) {
  return RiftRepoIsolationAdapter(
    rift: ref.watch(riftClientProvider),
    git: ref.watch(gitCommandPortProvider),
  );
});

/// Server-side Drift [IsolatedRepoRepository] backing the RPC catalog +
/// provisioning/worktree execution.
final daoIsolatedRepoRepositoryProvider = Provider<IsolatedRepoRepository>((
  ref,
) {
  return DaoIsolatedRepoRepository(ref.watch(isolatedRepoDaoProvider));
});

/// Provides the [RepoWorkspaceProvisionerPort] implementation (server-side
/// execution — owns the worktree registry DB directly via dao*).
final repoWorkspaceProvisionerProvider =
    Provider<RepoWorkspaceProvisionerPort>((ref) {
  return RepoWorkspaceProvisioner(
    filesystem: ref.watch(workspaceFilesystemPortProvider),
    isolation: ref.watch(repoIsolationPortProvider),
    registry: ref.watch(daoIsolatedRepoRepositoryProvider),
    workspaces: ref.watch(daoWorkspaceRepositoryProvider),
    githubToken: () async => ref.read(githubAuthTokenProvider),
    branchTemplate: () => ref.read(branchTemplateProvider),
    mcpConfigPath: () async => (await mcpConfigFile()).path,
  );
});

/// Lazily materializes (on click) and tears down (on PR merge/close) the
/// ephemeral CoW worktree used by the PR "open in editor" button.
/// Server-side execution — owns the worktree registry DB directly via dao*.
final prWorktreePortProvider = Provider<PrWorktreePort>((ref) {
  return PrWorktreeService(
    filesystem: ref.watch(workspaceFilesystemPortProvider),
    isolation: ref.watch(repoIsolationPortProvider),
    registry: ref.watch(daoIsolatedRepoRepositoryProvider),
    githubToken: () async => ref.read(githubAuthTokenProvider),
  );
});

/// Tears down isolated worktrees when a unit ends (ticket done/won't-do,
/// conversation deleted, PR merged/closed). Kept alive via `main.dart`.
/// Global keep-alive listener — owns the DB directly via dao*.
final worktreeGcListenerProvider = Provider<WorktreeGcListener>((ref) {
  final listener = WorktreeGcListener(
    eventBus: ref.watch(domainEventBusProvider),
    provisioner: ref.watch(repoWorkspaceProvisionerProvider),
    reviewChannels: ref.watch(daoReviewChannelRepositoryProvider),
    prWorktrees: ref.watch(prWorktreePortProvider),
  );
  listener.start();
  ref.onDispose(listener.dispose);
  return listener;
});

/// Provides the [DispatchAgentUseCase] instance.
final dispatchAgentUseCaseProvider = Provider<DispatchAgentUseCase>((ref) {
  // Convert the desktop's Flutter Locale to the domain AppLocale at the
  // composition root (the use-case is now Flutter-free in cc_domain).
  final locale = ref.watch(localeProvider);
  return DispatchAgentUseCase(
    // Server-side dispatch owns the DB directly (dao*), never the RPC path.
    agentRepo: ref.watch(daoAgentRepositoryProvider),
    memoryContextUseCase: ref.watch(buildMemoryContextUseCaseProvider),
    conversationContextUseCase: ref.watch(buildConversationContextUseCaseProvider),
    modeResolver: ref.watch(conversationModeResolverProvider),
    locale: locale != null ? AppLocale(locale.languageCode) : null,
  );
});

/// Provides the [AgentDispatchService] instance.
final agentDispatchServiceProvider = Provider<AgentDispatchService>((ref) {
  return AgentDispatchService(
    agentDispatch: ref.watch(agentDispatchPortProvider),
    dispatchUseCase: ref.watch(dispatchAgentUseCaseProvider),
    // Server-side dispatch owns the DB directly (dao*), never the RPC path.
    runLogRepo: ref.watch(daoAgentRunLogRepositoryProvider),
    repoProvisioner: ref.watch(repoWorkspaceProvisionerProvider),
    // Process-global agent registry — populates the work-aware roster. Shared
    // with the UI via agentRegistryProvider, which returns the same instance.
    registry: AgentRegistryImpl.global(),
    // Resolve per-adapter argv (YOLO flags, from prefs) + env (API keys, from
    // the secure store) for the resolved adapter at dispatch time.
    adapterLaunchOverrides: (adapterId) async {
      final prefs = ref.read(adapterPreferencesProvider);
      final argsStr = prefs.getAdapterArgs(adapterId);
      final env = await ref
          .read(adapterEnvOverridesRepositoryProvider)
          .getFor(adapterId);
      final args = argsStr == null || argsStr.isEmpty
          ? const <String>[]
          : argsStr.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      return (args: args, env: env);
    },
  );
});

/// Server-side Drift [ReviewChannelRepository] backing the RPC catalog + tools
/// + the worktree GC listener.
final daoReviewChannelRepositoryProvider = Provider<ReviewChannelRepository>((
  ref,
) {
  return DaoReviewChannelRepository(ref.watch(reviewChannelDaoProvider));
});

/// Provides the [PrLifecycleRepository] implementation.
final prLifecycleRepositoryProvider = Provider<PrLifecycleRepository>((ref) {
  return DaoPrLifecycleRepository(
    ref.watch(pullRequestDaoProvider),
    ref.watch(githubApiClientProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Provides the [AgentDispatchPort] implementation.
///
/// Always routes through `SandboxPort`. The "no isolation" path is just the
/// `NoSandboxAdapter` — same call-site, no branching here. Falls back to the
/// legacy [AgentProcessDataSource] only if the sandbox subsystem failed to
/// initialise (defensive — should not happen in production).
final agentDispatchPortProvider = Provider<AgentDispatchPort>((ref) {
  try {
    return SandboxedAgentDispatchAdapter(
      sandbox: ref.watch(sandboxPortProvider),
      credentialBroker: ref.watch(credentialBrokerProvider),
      // Server-side dispatch owns the DB directly (dao*), never the RPC path.
      agentRepository: ref.watch(daoAgentRepositoryProvider),
      runLogRepository: ref.watch(daoAgentRunLogRepositoryProvider),
      defaultCapabilities: ref.watch(defaultCapabilitiesProvider),
      eventBus: ref.watch(domainEventBusProvider),
      confirmationPort: ref.watch(confirmationPortProvider),
      // The adapter is now in cc_infra (Flutter-free), so the host-specific MCP
      // config path is injected rather than reached via control_center_paths.
      mcpConfigPathResolver: () async {
        final f = await mcpConfigFile();
        return f.existsSync() ? f.path : null;
      },
    );
  } catch (_) {
    return AgentProcessDataSource(eventBus: ref.watch(domainEventBusProvider));
  }
});

/// Server-side Drift [AgentWorkingMemoryRepository] backing the RPC catalog +
/// memory use-cases + tools.
final daoAgentWorkingMemoryRepositoryProvider =
    Provider<AgentWorkingMemoryRepository>((ref) {
  return DaoAgentWorkingMemoryRepository(
    ref.watch(agentWorkingMemoryDaoProvider),
  );
});

/// Server-side Drift [MemoryFactRepository] backing the RPC catalog + memory
/// use-cases + tools. Keeps the embedding service so server-side writes/search
/// stay vector-aware (the RPC adapter only forwards ops and has no embedder).
final daoMemoryFactRepositoryProvider = Provider<MemoryFactRepository>((ref) {
  return DaoMemoryFactRepository(
    ref.watch(memoryFactDaoProvider),
    embeddingService: ref.watch(embeddingServiceProvider),
    // Powers the polyphonic recall graph voice.
    edgeDao: ref.watch(episodicEdgeDaoProvider),
  );
});

/// Server-side Drift [MemoryConflictRepository] (PRD 04 conflict detection).
final daoMemoryConflictRepositoryProvider =
    Provider<MemoryConflictRepository>((ref) {
  return DaoMemoryConflictRepository(ref.watch(memoryConflictDaoProvider));
});

/// Server-side Drift [EpisodicEdgeRepository] (semantic memory graph).
final daoEpisodicEdgeRepositoryProvider = Provider<EpisodicEdgeRepository>((
  ref,
) {
  return DaoEpisodicEdgeRepository(ref.watch(episodicEdgeDaoProvider));
});

/// Server-side Drift [WorkingMemoryItemRepository] (hot working-memory tier +
/// consolidation log).
final daoWorkingMemoryItemRepositoryProvider =
    Provider<WorkingMemoryItemRepository>((ref) {
  return DaoWorkingMemoryItemRepository(
    ref.watch(workingMemoryItemDaoProvider),
    ref.watch(memoryConsolidationLogDaoProvider),
  );
});

/// Server-side Drift [MemoryBeliefRepository] (harmonized cross-agent beliefs).
final daoMemoryBeliefRepositoryProvider = Provider<MemoryBeliefRepository>((
  ref,
) {
  return DaoMemoryBeliefRepository(ref.watch(memoryBeliefDaoProvider));
});

/// Provides the [MeetingRepository] implementation.
///
/// NOT flipped: meetings have no cc_data RpcX adapter.
final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return DaoMeetingRepository(ref.watch(meetingDaoProvider));
});

/// Server-side Drift [VoiceProfileRepository] backing the RPC catalog + the
/// pipeline meeting/speaker-identify node.
final daoVoiceProfileRepositoryProvider = Provider<VoiceProfileRepository>((
  ref,
) {
  return DaoVoiceProfileRepository(ref.watch(voiceProfileDaoProvider));
});

/// Server-side Drift [MeetingRepository] backing the RPC catalog's
/// `meeting.*` ops + watches. NOT flipped here (this is the dao* surface the
/// in-process host serves from); the public `meetingRepositoryProvider` resolves
/// to the RpcX adapter on web.
final daoMeetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  return DaoMeetingRepository(ref.watch(meetingDaoProvider));
});

/// Provides the [CalendarRepository] implementation.
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return DaoCalendarRepository(ref.watch(calendarDaoProvider));
});

/// Provides the [SystemAudioCapturePort] implementation (loopback capture).
final systemAudioCapturePortProvider = Provider<SystemAudioCapturePort>((ref) {
  return PluginSystemAudioCapture();
});

/// Provides the [CodeGraphRepository] implementation.
final codeGraphRepositoryProvider = Provider<CodeGraphRepository>((ref) {
  return DaoCodeGraphRepository(
    ref.watch(codeGraphDaoProvider),
    embeddingService: ref.watch(embeddingServiceProvider),
  );
});

/// Provides the singleton [GrammarManager] for tree-sitter grammar loading.
final grammarManagerProvider = Provider<GrammarManager>(
  (ref) => GrammarManager(
    dio: createDio(),
    grammarsDir: grammarsRootDir,
    onLog: ccNativesLog,
  ),
);

/// Provides the singleton [FileSearch] implementation.
///
/// Backed by [FffFileSearch] (Rust native via FFI) when `libfff_c` is
/// installed (see `scripts/natives/build_fff.sh`). Degrades transparently to
/// [DartFileSearch] when absent.
final fileSearchProvider = Provider<FileSearch>((ref) {
  final search = FffFileSearch(
    appSupportRoot: controlCenterRootDir,
    onLog: ccNativesLog,
  );
  ref.onDispose(search.dispose);
  return search;
});

/// Provides the [CodeIndexer] implementation.
final codeIndexerProvider = Provider<CodeIndexer>((ref) {
  return DefaultCodeIndexer(
    repository: ref.watch(codeGraphRepositoryProvider),
    grammarManager: ref.watch(grammarManagerProvider),
    // Queries are embedded in cc_natives (pure Dart), shared with the headless
    // server — no Flutter asset / rootBundle dependency. DefaultCodeIndexer
    // defaults its queryLoader to those, so none is passed here.
  );
});

/// Provides the [AddRepoFromPathUseCase] instance.
///
/// A write use-case that also fires `RepoAdded` (triggering server-side code
/// indexing), so it owns the DB directly via dao* rather than routing the write
/// over RPC.
final addRepoFromPathUseCaseProvider = Provider<AddRepoFromPathUseCase>((ref) {
  return AddRepoFromPathUseCase(
    repository: ref.watch(daoRepoRepositoryProvider),
    inspector: ref.watch(gitRepoInspectorPortProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Server-side Drift [MemoryPolicyRepository] backing the RPC catalog + memory
/// use-cases + tools.
final daoMemoryPolicyRepositoryProvider = Provider<MemoryPolicyRepository>((
  ref,
) {
  return DaoMemoryPolicyRepository(ref.watch(memoryPolicyDaoProvider));
});

/// Server-side Drift [MemoryDomainRepository] backing the RPC catalog + memory
/// use-cases + tools.
final daoMemoryDomainRepositoryProvider = Provider<MemoryDomainRepository>((
  ref,
) {
  return DaoMemoryDomainRepository(ref.watch(memoryDomainDaoProvider));
});

/// Server-side Drift [MemoryAccessGrantRepository] backing the RPC catalog +
/// memory use-cases.
final daoMemoryAccessGrantRepositoryProvider =
    Provider<MemoryAccessGrantRepository>((ref) {
  return DaoMemoryAccessGrantRepository(
    ref.watch(memoryAccessGrantDaoProvider),
  );
});

// Memory use-cases are server-side EXECUTION (driven by MCP tools, the dispatch
// memory-context path, and the harvest listener), so they own the DB directly
// via the dao* memory repositories rather than routing through the RPC path.

/// Provides the [ResolveOrCreateDomainUseCase] instance.
final resolveOrCreateDomainUseCaseProvider = Provider<ResolveOrCreateDomainUseCase>((ref) {
  return ResolveOrCreateDomainUseCase(
    domainRepository: ref.watch(daoMemoryDomainRepositoryProvider),
    grantRepository: ref.watch(daoMemoryAccessGrantRepositoryProvider),
  );
});

/// Shared deterministic memory-fact writer (agent tool + harvest paths).
/// Wires conflict detection, episodic linking, and memory-stream events.
final recordMemoryFactUseCaseProvider = Provider<RecordMemoryFactUseCase>((ref) {
  return RecordMemoryFactUseCase(
    factRepository: ref.watch(daoMemoryFactRepositoryProvider),
    resolveDomainUseCase: ref.watch(resolveOrCreateDomainUseCaseProvider),
    conflictRepository: ref.watch(daoMemoryConflictRepositoryProvider),
    edgeRepository: ref.watch(daoEpisodicEdgeRepositoryProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Heuristic-backed fact extractor (no host LLM port wired today → the
/// deterministic regex fallback runs). Stateless, so a const instance.
final memoryExtractorProvider = Provider<MemoryExtractor>((ref) {
  return const MemoryExtractor();
});

/// Passive fact extraction → durable facts (PRD 04 phase 4.4).
final extractMemoryUseCaseProvider = Provider<ExtractMemoryUseCase>((ref) {
  return ExtractMemoryUseCase(
    extractor: ref.watch(memoryExtractorProvider),
    recordFact: ref.watch(recordMemoryFactUseCaseProvider),
  );
});

/// Two-tier working→episodic consolidation `sleep()` job (PRD 04 phase 4.2).
final memoryConsolidationServiceProvider =
    Provider<MemoryConsolidationService>((ref) {
  return MemoryConsolidationService(
    workingMemory: ref.watch(daoWorkingMemoryItemRepositoryProvider),
    recordFact: ref.watch(recordMemoryFactUseCaseProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Cross-agent SHMR belief harmonization (PRD 04 phase 4.6).
final harmonizeMemoryUseCaseProvider = Provider<HarmonizeMemoryUseCase>((ref) {
  return HarmonizeMemoryUseCase(
    factRepository: ref.watch(daoMemoryFactRepositoryProvider),
    beliefRepository: ref.watch(daoMemoryBeliefRepositoryProvider),
    conflictRepository: ref.watch(daoMemoryConflictRepositoryProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Provides the [MemoryCleanupUseCase] instance.
final memoryCleanupUseCaseProvider = Provider<MemoryCleanupUseCase>((ref) {
  return MemoryCleanupUseCase(
    factRepository: ref.watch(daoMemoryFactRepositoryProvider),
    workingMemoryRepository: ref.watch(daoAgentWorkingMemoryRepositoryProvider),
  );
});

/// Provides the [PromoteFactsToPolicyUseCase] instance.
final promoteFactsToPolicyUseCaseProvider = Provider<PromoteFactsToPolicyUseCase>((ref) {
  return PromoteFactsToPolicyUseCase(
    factRepository: ref.watch(daoMemoryFactRepositoryProvider),
    policyRepository: ref.watch(daoMemoryPolicyRepositoryProvider),
    grantRepository: ref.watch(daoMemoryAccessGrantRepositoryProvider),
    accessPolicy: ref.watch(memoryAccessPolicyProvider),
  );
});

/// Provides the [SupersedeFactUseCase] instance.
final supersedeFactUseCaseProvider = Provider<SupersedeFactUseCase>((ref) {
  return SupersedeFactUseCase(
    factRepository: ref.watch(daoMemoryFactRepositoryProvider),
  );
});

/// Provides the [SupersedePolicyUseCase] instance.
final supersedePolicyUseCaseProvider = Provider<SupersedePolicyUseCase>((ref) {
  return SupersedePolicyUseCase(
    policyRepository: ref.watch(daoMemoryPolicyRepositoryProvider),
  );
});

/// Provides the [BackfillEmbeddingsUseCase] instance.
final backfillEmbeddingsUseCaseProvider = Provider<BackfillEmbeddingsUseCase>((ref) {
  return BackfillEmbeddingsUseCase(
    database: ref.watch(databaseProvider),
    embeddingService: ref.watch(embeddingServiceProvider),
  );
});

/// Provides the [BuildMemoryContextUseCase] instance (server-side dispatch
/// path — owns the DB directly via dao*).
final buildMemoryContextUseCaseProvider = Provider<BuildMemoryContextUseCase>((ref) {
  return BuildMemoryContextUseCase(
    policyRepository: ref.watch(daoMemoryPolicyRepositoryProvider),
    workingMemoryRepository: ref.watch(daoAgentWorkingMemoryRepositoryProvider),
    factRepository: ref.watch(daoMemoryFactRepositoryProvider),
  );
});

/// Provides the [BuildConversationContextUseCase] instance.
final buildConversationContextUseCaseProvider = Provider<BuildConversationContextUseCase>((ref) {
  return BuildConversationContextUseCase(
    // Server-side dispatch path (assembles an agent's conversation context) —
    // owns the DB directly via dao*.
    messagingRepository: ref.watch(daoMessagingRepositoryProvider),
    embeddingPort: ref.watch(embeddingServiceProvider),
  );
});

/// Provides the [BackfillMessageEmbeddingsUseCase] instance.
final backfillMessageEmbeddingsUseCaseProvider = Provider<BackfillMessageEmbeddingsUseCase>((ref) {
  return BackfillMessageEmbeddingsUseCase(
    // Server-side embedding backfill (reads/writes embedding columns directly,
    // not exposed over RPC) — owns the DB directly via dao*.
    messagingRepository: ref.watch(daoMessagingRepositoryProvider),
    embeddingService: ref.watch(embeddingServiceProvider),
  );
});

/// Provides the [AdapterRepository] implementation.
final adapterRepositoryProvider = Provider<AdapterRepository>((ref) {
  return const AdapterDetectionRepository(AdapterDetectionService());
});

/// Provides the [AcpModelRepository] implementation.
final acpModelRepositoryProvider = Provider<AcpModelRepository>((ref) {
  return AcpModelRepositoryImpl(AcpModelsService());
});

/// Provides the [ProcessDetectionService] instance.
///
/// Shared by the dashboard UI and the `kill_agent` MCP tool (server-side), so
/// it owns the DB directly via dao* to avoid cycling through the RPC path.
final processDetectionServiceProvider = Provider<ProcessDetectionService>((
  ref,
) {
  return ProcessDetectionService(
    runLogRepo: ref.watch(daoAgentRunLogRepositoryProvider),
    agentRepo: ref.watch(daoAgentRepositoryProvider),
    workspaceRepo: ref.watch(daoWorkspaceRepositoryProvider),
  );
});

/// Provides the [SeedCeoAgentUseCase] instance (server-side seeder — owns the
/// DB directly via dao*, never the active-workspace-bound RPC path).
final seedCeoAgentUseCaseProvider = Provider<SeedCeoAgentUseCase>((ref) {
  return SeedCeoAgentUseCase(
    agentRepository: ref.watch(daoAgentRepositoryProvider),
    filesystemService: ref.watch(workspaceFilesystemPortProvider),
  );
});

/// Provides the [GitHubCliPort] implementation.
final githubCliServiceProvider = Provider<GitHubCliPort>(
  (ref) => ProcessGitHubCliService(),
);

/// Provides the [AnalyticsRepository] implementation.
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(
    ref.watch(analyticsDaoProvider),
    ref.watch(agentDaoProvider),
    ref.watch(pullRequestDaoProvider),
    ref.watch(workspaceDaoProvider),
  );
});

/// Provides the [AchievementRepository] implementation.
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepositoryImpl(
    ref.watch(achievementDaoProvider),
    ref.watch(agentDaoProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Provides the [StreakRepository] implementation.
final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return StreakRepositoryImpl(
    ref.watch(streakDaoProvider),
    ref.watch(agentDaoProvider),
  );
});

/// Provides the [XpEngine] instance.
final xpEngineProvider = Provider<XpEngine>((ref) {
  final engine = XpEngine(
    ref.watch(domainEventBusProvider),
    ref.watch(analyticsRepositoryProvider),
    ref.watch(achievementRepositoryProvider),
    ref.watch(streakRepositoryProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

/// Notifier that manages the lifecycle of a [SnapshotAggregator].
class SnapshotAggregatorNotifier extends Notifier<void> {
  SnapshotAggregator? _aggregator;

  @override
  void build() {
    final analyticsRepo = ref.watch(analyticsRepositoryProvider);
    _aggregator = SnapshotAggregator(analyticsRepo);
    _aggregator!.start();
    ref.onDispose(() => _aggregator?.dispose());
  }
}

/// Provides the [SnapshotAggregatorNotifier] instance.
final snapshotAggregatorProvider = NotifierProvider<SnapshotAggregatorNotifier, void>(
  SnapshotAggregatorNotifier.new,
);

/// Keep-alive persister that writes `ActivityLogged` events into the audit
/// table (the single write path for the audit trail).
final activityLogPersisterProvider = Provider<ActivityLogPersister>((ref) {
  final persister = ActivityLogPersister(
    eventBus: ref.watch(domainEventBusProvider),
    dao: ref.watch(activityLogDaoProvider),
  )..start();
  ref.onDispose(persister.dispose);
  return persister;
});

/// Keep-alive bridge that turns selected workspace-scoped domain events into
/// audit-log entries via [ActivityLogger].
final domainEventAuditBridgeProvider =
    Provider<DomainEventAuditBridge>((ref) {
  final bridge = DomainEventAuditBridge(
    eventBus: ref.watch(domainEventBusProvider),
    logger: ref.watch(activityLoggerProvider),
  )..start();
  ref.onDispose(bridge.dispose);
  return bridge;
});

/// Provides the [CostTracker] instance (global keep-alive listener that writes
/// run-log costs — owns the DB directly via dao*).
final costTrackerProvider = Provider<CostTracker>((ref) {
  return CostTracker(
    runLogRepo: ref.watch(daoAgentRunLogRepositoryProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Provides the [DoctorPort] implementation.
final doctorServiceProvider = Provider<DoctorPort>((ref) {
  return DoctorService(
    sandboxDetector: SandboxBackendDetector(
      ref.watch(sandboxAdaptersPoolProvider),
    ),
  );
});

/// Provides the [NotificationPort] implementation.
///
/// Wires route-awareness, channel-level suppression, and click-through
/// navigation by reading from the [routerProvider] and
/// [selectedChannelIdProvider] at call time (not at construction time),
/// keeping the service decoupled from the router lifecycle.
final notificationServiceProvider = Provider<NotificationPort>((ref) {
  final preferences = ref.watch(notificationPreferencesProvider);
  final router = ref.watch(routerProvider);
  final soundService = ref.watch(notificationSoundServiceProvider);

  final inner = LocalNotificationService(
    preferences: preferences,
    delivery: createDesktopNotificationDelivery(onNavigate: router.go),
    isRouteActive: (route) => isRouteActive(router, route),
    isFocusModeActive: () => ref.read(focusModeProvider).active,
    soundService: soundService,
    isChannelActive: (channelId) =>
        ref.read(selectedChannelIdProvider) == channelId,
  );

  // Record every produced notification into the in-app notification center
  // (before OS-level suppression) so the top-bar bell shows a durable history.
  return RecordingNotificationPort(
    inner: inner,
    onRecord: (notification) =>
        ref.read(notificationCenterProvider.notifier).add(notification),
  );
});
