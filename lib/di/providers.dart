
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/domain/ports/conversation_mode_resolver.dart';
import 'package:control_center/core/domain/ports/git_command_port.dart';
import 'package:control_center/core/domain/ports/git_repo_inspector_port.dart';
import 'package:control_center/core/domain/ports/notification_port.dart';
import 'package:control_center/core/domain/ports/notification_preferences_port.dart';
import 'package:control_center/core/domain/ports/pr_worktree_port.dart';
import 'package:control_center/core/domain/ports/process_control_port.dart';
import 'package:control_center/core/domain/ports/repo_isolation_port.dart';
import 'package:control_center/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:control_center/core/domain/ports/system_audio_capture_port.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/repositories/isolated_repo_repository.dart';
import 'package:control_center/core/domain/repositories/repo_repository.dart';
import 'package:control_center/core/domain/repositories/review_channel_repository.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/core/domain/services/activity_logger.dart';
import 'package:control_center/core/domain/services/agent_mention_parser.dart';
import 'package:control_center/core/domain/services/memory_access_policy.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/core/infrastructure/code_index/grammar_manager.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_providers.dart';
import 'package:control_center/core/infrastructure/file_search/dart_file_search.dart' show DartFileSearch;
import 'package:control_center/core/infrastructure/file_search/fff_file_search.dart';
import 'package:control_center/core/infrastructure/file_search/file_search.dart';
import 'package:control_center/core/infrastructure/rift/rift_client.dart';
import 'package:control_center/core/network/app_network.dart';
import 'package:control_center/core/network/github_api_client.dart';
import 'package:control_center/core/network/google_calendar_api_client.dart';
import 'package:control_center/core/network/models/github_user.dart';
import 'package:control_center/core/notifications/notification_center.dart';
import 'package:control_center/core/notifications/notification_preferences.dart';
import 'package:control_center/core/notifications/notification_service.dart';
import 'package:control_center/core/notifications/notification_sound_service.dart';
import 'package:control_center/core/notifications/recording_notification_port.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/agents/data/repositories/dao_agent_repository.dart';
import 'package:control_center/features/agents/data/repositories/dao_agent_run_log_repository.dart';
import 'package:control_center/features/agents/data/services/cost_tracker.dart';
import 'package:control_center/features/agents/data/services/doctor_service.dart';
import 'package:control_center/features/agents/data/services/process_control_service.dart';
import 'package:control_center/features/agents/domain/ports/doctor_port.dart';
import 'package:control_center/features/analytics/data/datasources/snapshot_aggregator.dart';
import 'package:control_center/features/analytics/data/datasources/xp_engine.dart';
import 'package:control_center/features/analytics/data/repositories/achievement_repository_impl.dart';
import 'package:control_center/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:control_center/features/analytics/data/repositories/streak_repository_impl.dart';
import 'package:control_center/features/analytics/domain/repositories/achievement_repository.dart';
import 'package:control_center/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:control_center/features/analytics/domain/repositories/streak_repository.dart';
import 'package:control_center/features/auth/data/github_cli_service.dart';
import 'package:control_center/features/auth/data/repositories/secure_credentials_repository.dart';
import 'package:control_center/features/auth/domain/ports/github_cli_port.dart';
import 'package:control_center/features/auth/domain/repositories/credentials_repository.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/calendar/data/repositories/dao_calendar_repository.dart';
import 'package:control_center/features/calendar/data/repositories/google_credentials_repository.dart';
import 'package:control_center/features/calendar/data/services/google_oauth_redirect_channel.dart';
import 'package:control_center/features/calendar/data/services/google_oauth_service.dart';
import 'package:control_center/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/features/code_graph/data/repositories/dao_code_graph_repository.dart';
import 'package:control_center/features/code_graph/data/services/code_indexer.dart';
import 'package:control_center/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:control_center/features/code_graph/domain/services/code_indexer.dart';
import 'package:control_center/features/dashboard/data/services/process_detection_service.dart';
import 'package:control_center/features/dashboard/domain/services/agent_process_matcher.dart';
import 'package:control_center/features/dispatch/data/datasources/agent_process_data_source.dart';
import 'package:control_center/features/dispatch/data/services/agent_dispatch_service.dart';
import 'package:control_center/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:control_center/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:control_center/features/dispatch/domain/usecases/build_memory_context_use_case.dart';
import 'package:control_center/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/meetings/data/adapters/plugin_system_audio_capture.dart';
import 'package:control_center/features/meetings/data/repositories/dao_meeting_repository.dart';
import 'package:control_center/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:control_center/features/memory/data/repositories/dao_agent_working_memory_repository.dart';
import 'package:control_center/features/memory/data/repositories/dao_memory_access_grant_repository.dart';
import 'package:control_center/features/memory/data/repositories/dao_memory_domain_repository.dart';
import 'package:control_center/features/memory/data/repositories/dao_memory_fact_repository.dart';
import 'package:control_center/features/memory/data/repositories/dao_memory_policy_repository.dart';
import 'package:control_center/features/memory/data/usecases/backfill_embeddings_use_case.dart';
import 'package:control_center/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:control_center/features/memory/domain/usecases/memory_cleanup_use_case.dart';
import 'package:control_center/features/memory/domain/usecases/promote_facts_to_policy_use_case.dart';
import 'package:control_center/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:control_center/features/memory/domain/usecases/supersede_fact_use_case.dart';
import 'package:control_center/features/messaging/data/repositories/dao_messaging_repository.dart';
import 'package:control_center/features/messaging/data/services/db_conversation_mode_resolver.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:control_center/features/messaging/domain/usecases/backfill_message_embeddings_use_case.dart';
import 'package:control_center/features/messaging/domain/usecases/send_channel_message_use_case.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/data/repositories/dao_pr_lifecycle_repository.dart';
import 'package:control_center/features/pr_review/data/repositories/dao_review_channel_repository.dart';
import 'package:control_center/features/pr_review/data/services/pr_worktree_service.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:control_center/features/repos/data/adapters/rift_repo_isolation_adapter.dart';
import 'package:control_center/features/repos/data/datasources/git_repo_inspector.dart';
import 'package:control_center/features/repos/data/datasources/process_git_command_adapter.dart';
import 'package:control_center/features/repos/data/repositories/dao_isolated_repo_repository.dart';
import 'package:control_center/features/repos/data/repositories/dao_repo_repository.dart';
import 'package:control_center/features/repos/data/services/repo_workspace_provisioner.dart';
import 'package:control_center/features/repos/data/services/worktree_gc_listener.dart';
import 'package:control_center/features/repos/domain/usecases/add_repo_from_path.dart';
import 'package:control_center/features/sandboxing/data/adapters/sandboxed_agent_dispatch_adapter.dart';
import 'package:control_center/features/sandboxing/data/services/sandbox_backend_detector.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/settings/data/privacy_preferences.dart';
import 'package:control_center/features/settings/data/repositories/acp_models_repository_impl.dart';
import 'package:control_center/features/settings/data/repositories/adapter_detection_repository.dart';
import 'package:control_center/features/settings/data/services/acp_models_service.dart';
import 'package:control_center/features/settings/data/services/adapter_detection_service.dart';
import 'package:control_center/features/settings/domain/repositories/acp_model_repository.dart';
import 'package:control_center/features/settings/domain/repositories/adapter_repository.dart';
import 'package:control_center/features/settings/providers/branch_template_provider.dart';
import 'package:control_center/features/shell/providers/current_route_provider.dart';
import 'package:control_center/features/workspaces/data/repositories/dao_workspace_repository.dart';
import 'package:control_center/features/workspaces/data/services/workspace_filesystem_service.dart';
import 'package:control_center/features/workspaces/domain/usecases/seed_ceo_agent_use_case.dart';
import 'package:control_center/router/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [AgentRepository] implementation.
final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return DaoAgentRepository(ref.watch(agentDaoProvider));
});

/// Provides the [AgentRunLogRepository] implementation.
final agentRunLogRepositoryProvider = Provider<AgentRunLogRepository>((ref) {
  return DaoAgentRunLogRepository(ref.watch(agentDaoProvider));
});

/// Provides the [WorkspaceRepository] implementation.
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return DaoWorkspaceRepository(ref.watch(workspaceDaoProvider));
});

/// Provides the [RepoRepository] implementation.
final repoRepositoryProvider = Provider<RepoRepository>((ref) {
  return DaoRepoRepository(ref.watch(repoDaoProvider));
});

/// Provides the [MessagingRepository] implementation.
final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return DaoMessagingRepository(ref.watch(messagingDaoProvider));
});

/// Provides the [ConversationModeResolver] implementation.
final conversationModeResolverProvider = Provider<ConversationModeResolver>((
  ref,
) {
  return DbConversationModeResolver(ref.watch(messagingDaoProvider));
});

/// Provides the [WorkspaceFilesystemPort] implementation.
final workspaceFilesystemPortProvider = Provider<WorkspaceFilesystemPort>((
  ref,
) {
  return WorkspaceFilesystemService();
});

/// Provides the [GitRepoInspectorPort] implementation.
final gitRepoInspectorPortProvider = Provider<GitRepoInspectorPort>((ref) {
  return const GitRepoInspector();
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

/// Provides the [IsolatedRepoRepository] implementation.
final isolatedRepoRepositoryProvider = Provider<IsolatedRepoRepository>((ref) {
  return DaoIsolatedRepoRepository(ref.watch(isolatedRepoDaoProvider));
});

/// Provides the [RepoWorkspaceProvisionerPort] implementation.
final repoWorkspaceProvisionerProvider =
    Provider<RepoWorkspaceProvisionerPort>((ref) {
  return RepoWorkspaceProvisioner(
    filesystem: ref.watch(workspaceFilesystemPortProvider),
    isolation: ref.watch(repoIsolationPortProvider),
    registry: ref.watch(isolatedRepoRepositoryProvider),
    workspaces: ref.watch(workspaceRepositoryProvider),
    githubToken: () async => ref.read(githubAuthTokenProvider),
    branchTemplate: () => ref.read(branchTemplateProvider),
  );
});

/// Lazily materializes (on click) and tears down (on PR merge/close) the
/// ephemeral CoW worktree used by the PR "open in editor" button.
final prWorktreePortProvider = Provider<PrWorktreePort>((ref) {
  return PrWorktreeService(
    filesystem: ref.watch(workspaceFilesystemPortProvider),
    isolation: ref.watch(repoIsolationPortProvider),
    registry: ref.watch(isolatedRepoRepositoryProvider),
    githubToken: () async => ref.read(githubAuthTokenProvider),
  );
});

/// Tears down isolated worktrees when a unit ends (ticket done/won't-do,
/// conversation deleted, PR merged/closed). Kept alive via `main.dart`.
final worktreeGcListenerProvider = Provider<WorktreeGcListener>((ref) {
  final listener = WorktreeGcListener(
    eventBus: ref.watch(domainEventBusProvider),
    provisioner: ref.watch(repoWorkspaceProvisionerProvider),
    reviewChannels: ref.watch(reviewChannelRepositoryProvider),
    prWorktrees: ref.watch(prWorktreePortProvider),
  );
  listener.start();
  ref.onDispose(listener.dispose);
  return listener;
});

/// Provides the [ProcessControlPort] implementation.
final processControlPortProvider = Provider<ProcessControlPort>((ref) {
  return const ProcessControlService();
});

/// Provides the [DispatchAgentUseCase] instance.
final dispatchAgentUseCaseProvider = Provider<DispatchAgentUseCase>((ref) {
  return DispatchAgentUseCase(
    agentRepo: ref.watch(agentRepositoryProvider),
    memoryContextUseCase: ref.watch(buildMemoryContextUseCaseProvider),
    conversationContextUseCase: ref.watch(buildConversationContextUseCaseProvider),
    modeResolver: ref.watch(conversationModeResolverProvider),
    locale: ref.watch(localeProvider),
  );
});

/// Provides the [AgentDispatchService] instance.
final agentDispatchServiceProvider = Provider<AgentDispatchService>((ref) {
  return AgentDispatchService(
    agentDispatch: ref.watch(agentDispatchPortProvider),
    dispatchUseCase: ref.watch(dispatchAgentUseCaseProvider),
    runLogRepo: ref.watch(agentRunLogRepositoryProvider),
    repoProvisioner: ref.watch(repoWorkspaceProvisionerProvider),
  );
});

/// Provides the [ReviewChannelRepository] implementation.
final reviewChannelRepositoryProvider = Provider<ReviewChannelRepository>((ref) {
  return DaoReviewChannelRepository(ref.watch(reviewChannelDaoProvider));
});

/// Provides the [PrLifecycleRepository] implementation.
final prLifecycleRepositoryProvider = Provider<PrLifecycleRepository>((ref) {
  return DaoPrLifecycleRepository(
    ref.watch(pullRequestDaoProvider),
    /// Creates a new [Ref.watch].
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
      agentRepository: ref.watch(agentRepositoryProvider),
      runLogRepository: ref.watch(agentRunLogRepositoryProvider),
      defaultCapabilities: ref.watch(defaultCapabilitiesProvider),
      eventBus: ref.watch(domainEventBusProvider),
    );
  } catch (_) {
    return AgentProcessDataSource(eventBus: ref.watch(domainEventBusProvider));
  }
});

/// Provides the [AgentWorkingMemoryRepository] implementation.
final agentWorkingMemoryRepositoryProvider = Provider<AgentWorkingMemoryRepository>((ref) {
  return DaoAgentWorkingMemoryRepository(ref.watch(agentWorkingMemoryDaoProvider));
});
 
/// Provides the [MemoryFactRepository] implementation.
final memoryFactRepositoryProvider = Provider<MemoryFactRepository>((ref) {
  return DaoMemoryFactRepository(
    ref.watch(memoryFactDaoProvider),
    embeddingService: ref.watch(embeddingServiceProvider),
  );
});

/// Provides the [MeetingRepository] implementation.
final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
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
  (ref) => GrammarManager(),
);

/// Provides the singleton [FileSearch] implementation.
///
/// Backed by [FffFileSearch] (Rust native via FFI) when `libfff_c` is
/// installed (see `scripts/build_fff.sh`). Degrades transparently to
/// [DartFileSearch] when absent.
final fileSearchProvider = Provider<FileSearch>((ref) {
  final search = FffFileSearch();
  ref.onDispose(search.dispose);
  return search;
});

/// Provides the [CodeIndexer] implementation.
final codeIndexerProvider = Provider<CodeIndexer>((ref) {
  return DefaultCodeIndexer(
    repository: ref.watch(codeGraphRepositoryProvider),
    grammarManager: ref.watch(grammarManagerProvider),
  );
});
 
/// Provides the [AddRepoFromPathUseCase] instance.
final addRepoFromPathUseCaseProvider = Provider<AddRepoFromPathUseCase>((ref) {
  return AddRepoFromPathUseCase(
    repository: ref.watch(repoRepositoryProvider),
    inspector: ref.watch(gitRepoInspectorPortProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});
 
 
/// Provides the [MemoryPolicyRepository] implementation.
final memoryPolicyRepositoryProvider = Provider<MemoryPolicyRepository>((ref) {
  return DaoMemoryPolicyRepository(ref.watch(memoryPolicyDaoProvider));
});
 
/// Provides the [MemoryDomainRepository] implementation.
final memoryDomainRepositoryProvider = Provider<MemoryDomainRepository>((ref) {
  return DaoMemoryDomainRepository(ref.watch(memoryDomainDaoProvider));
});
 
/// Provides the [MemoryAccessGrantRepository] implementation.
final memoryAccessGrantRepositoryProvider = Provider<MemoryAccessGrantRepository>((ref) {
  return DaoMemoryAccessGrantRepository(ref.watch(memoryAccessGrantDaoProvider));
});
 
/// Provides the [MemoryAccessPolicy] instance.
final memoryAccessPolicyProvider = Provider<MemoryAccessPolicy>((ref) {
  return const MemoryAccessPolicy();
});


/// Provides the [ResolveOrCreateDomainUseCase] instance.
final resolveOrCreateDomainUseCaseProvider = Provider<ResolveOrCreateDomainUseCase>((ref) {
  return ResolveOrCreateDomainUseCase(
    domainRepository: ref.watch(memoryDomainRepositoryProvider),
    grantRepository: ref.watch(memoryAccessGrantRepositoryProvider),
  );
});

/// Provides the [MemoryCleanupUseCase] instance.
final memoryCleanupUseCaseProvider = Provider<MemoryCleanupUseCase>((ref) {
  return MemoryCleanupUseCase(
    factRepository: ref.watch(memoryFactRepositoryProvider),
    workingMemoryRepository: ref.watch(agentWorkingMemoryRepositoryProvider),
  );
});

/// Provides the [PromoteFactsToPolicyUseCase] instance.
final promoteFactsToPolicyUseCaseProvider = Provider<PromoteFactsToPolicyUseCase>((ref) {
  return PromoteFactsToPolicyUseCase(
    factRepository: ref.watch(memoryFactRepositoryProvider),
    policyRepository: ref.watch(memoryPolicyRepositoryProvider),
    grantRepository: ref.watch(memoryAccessGrantRepositoryProvider),
    accessPolicy: ref.watch(memoryAccessPolicyProvider),
  );
});

/// Provides the [SupersedeFactUseCase] instance.
final supersedeFactUseCaseProvider = Provider<SupersedeFactUseCase>((ref) {
  return SupersedeFactUseCase(
    factRepository: ref.watch(memoryFactRepositoryProvider),
  );
});

/// Provides the [BackfillEmbeddingsUseCase] instance.
final backfillEmbeddingsUseCaseProvider = Provider<BackfillEmbeddingsUseCase>((ref) {
  return BackfillEmbeddingsUseCase(
    database: ref.watch(databaseProvider),
    embeddingService: ref.watch(embeddingServiceProvider),
  );
});

/// Provides the [BuildMemoryContextUseCase] instance.
final buildMemoryContextUseCaseProvider = Provider<BuildMemoryContextUseCase>((ref) {
  return BuildMemoryContextUseCase(
    policyRepository: ref.watch(memoryPolicyRepositoryProvider),
    workingMemoryRepository: ref.watch(agentWorkingMemoryRepositoryProvider),
  );
});

/// Provides the [BuildConversationContextUseCase] instance.
final buildConversationContextUseCaseProvider = Provider<BuildConversationContextUseCase>((ref) {
  return BuildConversationContextUseCase(
    messagingRepository: ref.watch(messagingRepositoryProvider),
    embeddingPort: ref.watch(embeddingServiceProvider),
  );
});

/// Provides the [BackfillMessageEmbeddingsUseCase] instance.
final backfillMessageEmbeddingsUseCaseProvider = Provider<BackfillMessageEmbeddingsUseCase>((ref) {
  return BackfillMessageEmbeddingsUseCase(
    messagingRepository: ref.watch(messagingRepositoryProvider),
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
final processDetectionServiceProvider = Provider<ProcessDetectionService>((
  ref,
) {
  return ProcessDetectionService(
    runLogRepo: ref.watch(agentRunLogRepositoryProvider),
    agentRepo: ref.watch(agentRepositoryProvider),
    workspaceRepo: ref.watch(workspaceRepositoryProvider),
  );
});

/// Provides the [AgentMentionParser] instance.
final agentMentionParserProvider = Provider<AgentMentionParser>((ref) {
  return const AgentMentionParser();
});

/// Provides the [SendChannelMessageUseCase] instance.
final sendChannelMessageUseCaseProvider = Provider<SendChannelMessageUseCase>((
  ref,
) {
  return SendChannelMessageUseCase(
    ref.watch(messagingServiceProvider),
  );
});

/// Provides the [SeedCeoAgentUseCase] instance.
final seedCeoAgentUseCaseProvider = Provider<SeedCeoAgentUseCase>((ref) {
  return SeedCeoAgentUseCase(
    agentRepository: ref.watch(agentRepositoryProvider),
    filesystemService: ref.watch(workspaceFilesystemPortProvider),
  );
});

/// Provides the [AgentProcessMatcher] instance.
final agentProcessMatcherProvider = Provider<AgentProcessMatcher>((ref) {
  return AgentProcessMatcher();
});

/// Provides the [CredentialsRepository] implementation.
final credentialsRepositoryProvider = Provider<CredentialsRepository>((ref) {
  return SecureCredentialsRepository(
    ref.watch(secureStorageProvider),
    ref.watch(sharedPreferencesProvider),
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
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Provides the [StreakRepository] implementation.
final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return StreakRepositoryImpl(ref.watch(streakDaoProvider));
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

/// Provides the [ActivityLogger] instance.
final activityLoggerProvider = Provider<ActivityLogger>((ref) {
  return ActivityLogger(eventBus: ref.watch(domainEventBusProvider));
});
 
/// Provides the [CostTracker] instance.
final costTrackerProvider = Provider<CostTracker>((ref) {
  return CostTracker(
    runLogRepo: ref.watch(agentRunLogRepositoryProvider),
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

/// Provides a [Dio] instance configured for GitHub API calls.
/// Auth token is read lazily on each request so it picks up gh CLI tokens
/// that resolve asynchronously after app start.
final githubDioProvider = Provider<Dio>((ref) {
  final dio = createDio();
  // Mutable holder so the interceptor reads the latest token at request time,
  // not the value captured when this provider was first built.
  final tokenRef = _MutableString();
  ref.listen(githubAuthTokenProvider, (_, next) => tokenRef.value = next);
  tokenRef.value = ref.read(githubAuthTokenProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = tokenRef.value;
        if (t.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $t';
        }
        handler.next(options);
      },
    ),
  );
  // Dio lifecycle is tied to app lifetime — closing it would break
  // long-lived handlers that hold references (e.g. PrProtocolHandler).
  return dio;
});

/// Mutable string holder used by dio interceptors to read the current
/// auth token at request time instead of capture-at-build time.
class _MutableString {
  String value = '';
}

/// Provides a [GitHubApiClient] backed by [githubDioProvider].
final githubApiClientProvider = Provider<GitHubApiClient>((ref) {
  return GitHubApiClient(ref.watch(githubDioProvider));
});

// ── Google Calendar ──

/// Per-workspace Google OAuth token store (keychain-backed).
final googleCredentialsRepositoryProvider =
    Provider<GoogleCredentialsRepository>((ref) {
  return GoogleCredentialsRepository(ref.watch(secureStorageProvider));
});

/// App-scoped bus that delivers the OAuth redirect deep link (captured by the
/// startup URL handler in `main.dart`) to the in-flight authorization flow.
final googleOAuthRedirectChannelProvider =
    Provider<GoogleOAuthRedirectChannel>((ref) {
  final channel = GoogleOAuthRedirectChannel();
  ref.onDispose(channel.dispose);
  return channel;
});

/// The Google OAuth PKCE flow service for a public iOS-type client (no secret;
/// reversed-client-id custom-scheme redirect captured via the channel above).
final googleOAuthServiceProvider = Provider<GoogleOAuthService>((ref) {
  final channel = ref.watch(googleOAuthRedirectChannelProvider);
  return GoogleOAuthService(
    clientId: ref.watch(googleClientIdProvider),
    awaitRedirect: channel.next,
  );
});

/// Dio for the Google Calendar API, carrying the OAuth Bearer + auto-refresh
/// interceptor. Auth state is read lazily per request so a workspace switch /
/// token refresh is picked up without rebuilding the client.
final googleCalendarDioProvider = Provider<Dio>((ref) {
  final dio = createDio(baseUrl: googleCalendarApiBaseUrl);
  // Added after createDio's built-in interceptors so retry/backoff still
  // covers 429/5xx; this interceptor only handles auth (bearer + 401 refresh).
  dio.interceptors.add(_GoogleAuthInterceptor(ref, dio));
  return dio;
});

/// Provides a [GoogleCalendarApiClient] backed by [googleCalendarDioProvider].
final googleCalendarApiClientProvider = Provider<GoogleCalendarApiClient>((ref) {
  return GoogleCalendarApiClient(ref.watch(googleCalendarDioProvider));
});

/// Injects the per-account Bearer token (refreshing proactively when within the
/// skew window of expiring), and reactively retries once on a 401. Refreshes
/// are single-flighted per account inside [GoogleTokenManager].
class _GoogleAuthInterceptor extends QueuedInterceptor {
  _GoogleAuthInterceptor(this._ref, this._dio);

  final Ref _ref;
  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accountId = options.extra[googleAccountIdExtraKey] as String?;
    if (accountId != null) {
      try {
        final token =
            await _ref.read(googleTokenManagerProvider).accessTokenFor(accountId);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        AppLog.w('GoogleAuth', 'Could not attach Google token: $e');
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final accountId = err.requestOptions.extra[googleAccountIdExtraKey] as String?;
    final alreadyRetried = err.requestOptions.extra['googleAuthRetried'] == true;
    if (status == 401 && accountId != null && !alreadyRetried) {
      final token =
          await _ref.read(googleTokenManagerProvider).forceRefresh(accountId);
      if (token != null && token.isNotEmpty) {
        final request = err.requestOptions;
        request.extra['googleAuthRetried'] = true;
        request.headers['Authorization'] = 'Bearer $token';
        try {
          final response = await _dio.fetch<dynamic>(request);
          handler.resolve(response);
          return;
        } on DioException catch (retryError) {
          handler.next(retryError);
          return;
        }
      }
    }
    handler.next(err);
  }
}

/// Fetches the authenticated GitHub user profile.
final githubUserProvider = FutureProvider<GitHubUser?>((ref) async {
  if (!ref.watch(isGitHubAuthenticatedProvider)) {
    return null;
  }
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  try {
    final client = ref.watch(githubApiClientProvider);
    return await client.content.getAuthenticatedUser(cancelToken: cancelToken);
  } on NetworkException catch (_) {
    return null;
  }
});

// ── Notifications ──────────────────────────────────────────────────────

/// Provides the [NotificationPreferencesPort] implementation.
final notificationPreferencesProvider = Provider<NotificationPreferencesPort>((ref) {
  return SharedPreferencesNotificationPreferences(ref.watch(sharedPreferencesProvider));
});

/// Provides [PrivacyPreferences].
final privacyPreferencesProvider = Provider<PrivacyPreferences>((ref) {
  return PrivacyPreferences(ref.watch(sharedPreferencesProvider));
});

/// Provides the [NotificationSoundService] singleton.
final notificationSoundServiceProvider = Provider<NotificationSoundService>((ref) {
  return NotificationSoundService();
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
    onNavigate: router.go,
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
