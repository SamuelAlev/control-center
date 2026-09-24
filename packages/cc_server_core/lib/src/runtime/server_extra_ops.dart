import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_tree_port.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_domain/features/model_routing/domain/ports/models_dev_source.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, WatchQuery;
import 'package:cc_infra/cc_infra.dart'
    show
        FilterListService,
        FontsourceCatalogService,
        ModelCatalogService,
        ServerWeatherService,
        SoundscapeHub;
import 'package:cc_persistence/cc_persistence.dart'
    show DaoAgentRepository, DaoUserRepository, DaoWorkspaceRepository;
import 'package:cc_server_core/src/agents/agent_create_rpc.dart';
import 'package:cc_server_core/src/catalog/pr_merge_conflict_ops.dart';
import 'package:cc_server_core/src/chat/chat_connector.dart';
import 'package:cc_server_core/src/chat/chat_rpc_ops.dart';
import 'package:cc_server_core/src/code_graph/code_graph_rpc.dart';
import 'package:cc_server_core/src/context/context_inspection_service.dart';
import 'package:cc_server_core/src/context/context_rpc_ops.dart';
import 'package:cc_server_core/src/fonts/fonts_rpc.dart';
import 'package:cc_server_core/src/identity/caching_workspace_membership_repository.dart';
import 'package:cc_server_core/src/identity/sso_ops.dart';
import 'package:cc_server_core/src/identity/sso_settings_service.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_github_rpc.dart';
import 'package:cc_server_core/src/identity/workspace_profile_rpc.dart';
import 'package:cc_server_core/src/model_routing/models_dev_rpc.dart';
import 'package:cc_server_core/src/newsfeed/filter_list_rpc.dart';
import 'package:cc_server_core/src/pr_review/pr_merge_conflict_service.dart';
import 'package:cc_server_core/src/soundscape/soundscape_rpc.dart';
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
  required List<RepoOp> fleetOps,
  required List<WatchQuery> fleetWatchQueries,
  required DaoAgentRepository agentRepository,
  required WorkspaceFilesystemPort workspaceFilesystem,
  required DaoWorkspaceRepository workspaceRepository,
  required CachingWorkspaceMembershipRepository membershipRepository,
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
  required Future<bool> Function(String userId) isServerOwner,
  required CodeGraphRepository codeGraphRepository,
  CodeGraphTreePort? codeGraphTree,
  WorkspaceGitHubAppSettings? workspaceGitHubApps,
  PrMergeConflictService? prMergeConflicts,
}) {
  final ops = <RepoOp>[
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
    ...buildContextOps(inspection: contextInspection),
    ...buildWeatherOps(weatherService),
    ...buildFontsOps(fontCatalog),
    ...buildFilterListOps(filterLists),
    ...buildModelsDevOps(source: modelsDevSource, catalog: modelCatalogService),
    ...buildSoundscapeOps(soundscapeHub),
    ...buildChatOps(connector: chatConnector, users: userRepository),
    ...buildSsoOps(settings: ssoSettings, isServerOwner: isServerOwner),
    ...buildIdentityWorkspaceProfileOps(
      users: userRepository,
      members: membershipRepository,
    ),
    ...buildWorkspaceGitHubOps(
      workspaceRepository: workspaceRepository,
      apps: workspaceGitHubApps,
    ),
    ...buildCodeGraphOps(
      workspaceRepository: workspaceRepository,
      codeGraph: codeGraphRepository,
      tree: codeGraphTree,
    ),
    ...buildPrMergeConflictOps(prMergeConflicts),
  ];

  final watches = <WatchQuery>[
    ...fleetWatchQueries,
    ...buildWeatherWatchQueries(weatherService),
    ...buildSoundscapeWatchQueries(soundscapeHub),
    ...buildChatWatchQueries(connector: chatConnector, users: userRepository),
  ];

  return (ops: ops, watches: watches);
}
