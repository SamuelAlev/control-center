import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/ports/forge_credential_port.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/server_audit_repository.dart';
import 'package:cc_domain/core/domain/repositories/server_notice_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_activity_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_repo_gate.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_tree_port.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_domain/features/mcp/domain/mcp_server_status.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_domain/features/messaging/domain/ports/conversation_title_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/model_routing/domain/ports/models_dev_source.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart'
    show TelemetryConfigRepository;
import 'package:cc_host/cc_host.dart' show RepoOp, WatchQuery;
import 'package:cc_infra/cc_infra.dart'
    show
        ClaudeAccountStore,
        ClaudeSessionSettingsStore,
        FilterListService,
        FontsourceCatalogService,
        ModelCatalogService,
        ServerWeatherService,
        SoundscapeHub;
import 'package:cc_persistence/cc_persistence.dart'
    show DaoAgentRepository, DaoUserRepository, DaoWorkspaceRepository;
import 'package:cc_server_core/src/agents/agent_create_rpc.dart';
import 'package:cc_server_core/src/backup/backup_rpc.dart';
import 'package:cc_server_core/src/catalog/account_pool_ops.dart';
import 'package:cc_server_core/src/catalog/audit_log_ops.dart';
import 'package:cc_server_core/src/catalog/calendar_write_ops.dart';
import 'package:cc_server_core/src/catalog/changelog_ops.dart';
import 'package:cc_server_core/src/catalog/claude_session_settings_ops.dart';
import 'package:cc_server_core/src/catalog/claude_sign_in_ops.dart';
import 'package:cc_server_core/src/catalog/commit_signing_ops.dart';
import 'package:cc_server_core/src/catalog/conversation_outline_ops.dart';
import 'package:cc_server_core/src/catalog/conversation_title_ops.dart';
import 'package:cc_server_core/src/catalog/forge_automation_token_ops.dart';
import 'package:cc_server_core/src/catalog/forge_compose_ops.dart';
import 'package:cc_server_core/src/catalog/gif_ops.dart';
import 'package:cc_server_core/src/catalog/mcp_server_ops.dart';
import 'package:cc_server_core/src/catalog/pr_data_gate.dart';
import 'package:cc_server_core/src/catalog/pr_merge_conflict_ops.dart';
import 'package:cc_server_core/src/catalog/server_notice_ops.dart';
import 'package:cc_server_core/src/catalog/sign_in_ops.dart';
import 'package:cc_server_core/src/catalog/user_profile_ops.dart';
import 'package:cc_server_core/src/catalog/workspace_mcp_server_ops.dart';
import 'package:cc_server_core/src/catalog/workspace_provider_app_ops.dart';
import 'package:cc_server_core/src/chat/chat_connector.dart';
import 'package:cc_server_core/src/chat/chat_rpc_ops.dart';
import 'package:cc_server_core/src/code_graph/code_graph_rpc.dart';
import 'package:cc_server_core/src/connect/klipy_gifs.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/context/context_inspection_service.dart';
import 'package:cc_server_core/src/context/context_rpc_ops.dart';
import 'package:cc_server_core/src/fonts/fonts_rpc.dart';
import 'package:cc_server_core/src/forge/forge_automation_tokens.dart';
import 'package:cc_server_core/src/forge/forge_pr_client_resolver.dart';
import 'package:cc_server_core/src/google_calendar_server.dart'
    show ServerCalendarWrites;
import 'package:cc_server_core/src/identity/caching_workspace_membership_repository.dart';
import 'package:cc_server_core/src/identity/commit_signing_keys.dart';
import 'package:cc_server_core/src/identity/sso_ops.dart';
import 'package:cc_server_core/src/identity/sso_settings_service.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_github_rpc.dart';
import 'package:cc_server_core/src/identity/workspace_profile_rpc.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';
import 'package:cc_server_core/src/mcp_servers/workspace_mcp_servers.dart';
import 'package:cc_server_core/src/model_routing/models_dev_rpc.dart';
import 'package:cc_server_core/src/newsfeed/filter_list_rpc.dart';
import 'package:cc_server_core/src/pr_review/pr_merge_conflict_service.dart';
import 'package:cc_server_core/src/soundscape/soundscape_rpc.dart';
import 'package:cc_server_core/src/telemetry/telemetry_ops.dart';
import 'package:cc_server_core/src/weather/weather_rpc.dart';
import 'package:cc_server_core/src/workspaces/workspace_create_rpc.dart';

/// The `extraOps` and `extraWatchQueries` that are spliced into
/// `buildRemoteRpcCatalog`.
typedef ExtraOpsResult = ({List<RepoOp> ops, List<WatchQuery> watches});

/// Assembles the `extraOps` and `extraWatchQueries` lists that are spliced into
/// the remote RPC catalog. Extracted from `runCcServer` so the composition root
/// reads as "what does the catalog receive?" rather than "how is every
/// list-builder invoked?".
ExtraOpsResult buildServerExtraOps({
  required ChangelogFetcher fetchChangelog,
  required ClaudeAccountStore claudeAccounts,
  required ClaudeSessionSettingsStore claudeSessionSettings,
  required List<RepoOp> fleetOps,
  required List<WatchQuery> fleetWatchQueries,
  required DaoAgentRepository agentRepository,
  required WorkspaceFilesystemPort workspaceFilesystem,
  required DaoWorkspaceRepository workspaceRepository,
  required CachingWorkspaceMembershipRepository membershipRepository,
  required ProviderSignInService? providerSignIn,
  List<RepoOp> connectOps = const [],
  required String pairingServerUrl,
  required DomainEventBus eventBus,
  required ContextInspectionService contextInspection,
  required ServerWeatherService weatherService,
  required FontsourceCatalogService fontCatalog,
  required FilterListService filterLists,
  required ModelsDevSource modelsDevSource,
  required ModelCatalogService modelCatalogService,
  required SoundscapeHub soundscapeHub,
  required ChatConnector chatConnector,
  required DaoUserRepository userRepository,
  required SsoSettingsService ssoSettings,
  required CodeGraphRepository codeGraphRepository,
  CodeGraphTreePort? codeGraphTree,
  required CodeGraphRepoGate codeGraphRepos,
  WorkspaceGitHubAppSettings? workspaceGitHubApps,
  WorkspaceProviderAppSettings? workspaceProviderApps,
  KlipyGifs? klipyGifs,
  ServerCalendarWrites? calendarWrites,
  PrMergeConflictService? prMergeConflicts,
  ForgeReadAccessCheck? forgeReadAccess,
  ForgePrClientResolver? forgeClientFor,
  ForgeConnectionView? forgeConnections,
  ForgeAutomationTokens? forgeAutomationTokens,
  void Function(String workspaceId)? onAutomationTokensChanged,
  CommitSigningKeys? commitSigningKeys,
  required DatabaseBackupPort? databaseBackup,
  required ConversationTitlePort? conversationTitles,
  // The conversation feed's outline and anchored range reads.
  required MessagingRepository messagingRepository,
  required ConversationRepository conversationRepository,
  // The read gate of a conversation's space (derived from the conversation).
  required Future<void> Function(
    String workspaceId,
    String conversationId,
    String userId,
  )
  requireConversationSpace,
  required WorkspaceSettingsRepository? workspaceSettings,
  required TelemetryConfigRepository telemetryConfig,
  ServerAuditRepository? serverAudit,
  required UserActivityRepository userActivity,
  required Future<bool> Function(String userId) isServerOwner,
  required PrDataGate prData,
  McpServerControl? mcpServer,
  WorkspaceMcpServers? workspaceMcpServers,
  McpClientControl? mcpClientControl,
  ServerNoticeRepository? serverNotices,
}) {
  final conversationOutline = buildConversationOutlineOps(
    messaging: messagingRepository,
    conversations: conversationRepository,
    prData: prData,
  );
  final ops = <RepoOp>[
    ...conversationOutline.ops,
    ...fleetOps,
    ...buildAgentCreateOps(
      agentRepository: agentRepository,
      filesystem: workspaceFilesystem,
    ),
    ...buildWorkspaceCreateOps(
      workspaceRepository: workspaceRepository,
      identityMembers: membershipRepository,
      eventBus: eventBus,
    ),
    ...buildContextOps(
      inspection: contextInspection,
      workspaces: workspaceRepository,
    ),
    ...buildWeatherOps(weatherService),
    ...buildChangelogOps(fetchChangelog),
    ...buildClaudeSessionSettingsOps(claudeSessionSettings),
    ...buildClaudeSignInOps(claudeAccounts),
    ...buildFontsOps(fontCatalog),
    ...buildFilterListOps(filterLists),
    ...buildModelsDevOps(source: modelsDevSource, catalog: modelCatalogService),
    ...buildSoundscapeOps(soundscapeHub),
    ...buildChatOps(connector: chatConnector, users: userRepository),
    ...buildSsoOps(settings: ssoSettings),
    ...buildIdentityWorkspaceProfileOps(
      users: userRepository,
      members: membershipRepository,
    ),
    ...buildWorkspaceGitHubOps(
      workspaceRepository: workspaceRepository,
      apps: workspaceGitHubApps,
    ),
    ...buildWorkspaceProviderAppOps(
      apps: workspaceProviderApps,
      pairingServerUrl: pairingServerUrl,
    ),
    ...buildGifOps(klipyGifs),
    ...buildCalendarWriteOps(calendarWrites),
    ...buildSignInOps(
      signIn: providerSignIn,
      workspaces: workspaceRepository,
      members: membershipRepository,
      pairingServerUrl: pairingServerUrl,
    ),
    ...connectOps,
    ...buildCodeGraphOps(
      repoGate: codeGraphRepos,
      codeGraph: codeGraphRepository,
      tree: codeGraphTree,
    ),
    ...buildPrMergeConflictOps(
      prMergeConflicts,
      linkedRepos: (workspaceId) =>
          workspaceRepository.watchReposForWorkspace(workspaceId).first,
      members: membershipRepository,
      forgeAccess: forgeReadAccess,
    ),
    ...buildForgeComposeOps(
      linkedRepos: (workspaceId) =>
          workspaceRepository.watchReposForWorkspace(workspaceId).first,
      members: membershipRepository,
      forgeAccess: forgeReadAccess,
      clientFor: forgeClientFor,
      connections: forgeConnections,
    ),
    ...buildForgeAutomationTokenOps(
      tokens: forgeAutomationTokens,
      linkedRepos: (workspaceId) =>
          workspaceRepository.watchReposForWorkspace(workspaceId).first,
      onChanged: onAutomationTokensChanged,
    ),
    ...buildCommitSigningOps(commitSigningKeys),
    ...buildUserProfileOps(users: userRepository),
    ...buildEmailVouchOps(users: userRepository),
    ...buildBackupOps(databaseBackup: databaseBackup),
    ...buildServerNoticeOps(notices: serverNotices),
    ...buildConversationTitleOps(
      conversationTitles,
      requireConversation: requireConversationSpace,
    ),
    ...buildAccountPoolOps(workspaceSettings),
    ...buildTelemetryOps(config: telemetryConfig),
    ...buildMcpServerOps(mcp: mcpServer),
    ...buildConfiguredMcpServerOps(
      workspaceServers: workspaceMcpServers,
      personal: mcpClientControl,
    ),
  ];

  final watches = <WatchQuery>[
    ...fleetWatchQueries,
    ...buildWeatherWatchQueries(weatherService),
    ...buildSoundscapeWatchQueries(soundscapeHub),
    ...buildChatWatchQueries(connector: chatConnector, users: userRepository),
    ...buildTelemetryWatchQueries(telemetryConfig),
    ...conversationOutline.watches,
    ...buildAuditLogWatchQueries(
      serverAudit: serverAudit,
      activity: userActivity,
      members: membershipRepository,
      workspaces: workspaceRepository,
      isServerOwner: isServerOwner,
      prData: prData,
      eventBus: eventBus,
    ),
  ];

  return (ops: ops, watches: watches);
}
