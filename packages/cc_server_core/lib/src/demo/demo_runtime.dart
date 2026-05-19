import 'dart:convert';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_provider.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/demo/demo_forge_provider_factory.dart';
import 'package:cc_server_core/src/demo/demo_hooks.dart';
import 'package:cc_server_core/src/demo/demo_open_pr_poller.dart';
import 'package:cc_server_core/src/demo/demo_profile.dart';
import 'package:cc_server_core/src/demo/demo_provider.dart';
import 'package:cc_server_core/src/demo/demo_repo_stats.dart';
import 'package:cc_server_core/src/demo/demo_script.dart';
import 'package:cc_server_core/src/demo/demo_seeder.dart';
import 'package:cc_server_core/src/demo/demo_visitor_service.dart';
import 'package:cc_server_core/src/demo/fixtures/demo_fixtures.g.dart';
import 'package:cc_server_core/src/demo/scripted_agent_loop.dart';
import 'package:cc_server_core/src/pr_review/open_pr_polling_service.dart';

/// The identity a visitor's own PR comments and reviews are authored as.
///
/// Deliberately generic: a demo visitor is anonymous, and "You" reads better in
/// a review thread than a generated guest handle would.
const PrUser kDemoVisitorAuthor = PrUser(
  login: 'you',
  avatarUrl: '',
  name: 'You',
);

/// Assembles the demo from a half-built server runtime.
///
/// This is the ONE entry point `apps/cc_demo_server` passes to `runCcServer`,
/// and the only thing that references the rest of this subtree — which is what
/// lets the production `cc_server` binary tree-shake the demo, its seeder and
/// its compiled-in fixtures away entirely.
Future<DemoWiring> buildDemoWiring(DemoRuntimeContext context) async {
  final log = context.log ?? (_) {};

  final scripts = [
    for (final raw in jsonDecode(kDemoRunScriptsJson) as List)
      DemoRunScript.fromJson(Map<String, dynamic>.from(raw as Map)),
  ];
  log('demo: loaded ${scripts.length} run scripts');

  final seeder = DemoSeeder(
    globalDb: context.globalDb,
    workspaceDbs: context.workspaceDbs,
    dataDir: context.dataDir,
    userRepository: context.userRepository,
    membershipRepository: context.membershipRepository,
    workspaceRepository: context.workspaceRepository,
    agentRepository: DaoAgentRepository(context.workspaceDbs),
    repoRepository: DaoRepoRepository(context.workspaceDbs),
    messagingRepository: DaoMessagingRepository(context.workspaceDbs),
    ticketRepository: DaoTicketRepository(
      context.workspaceDbs,
      context.globalDb.workspaceRouteDao,
    ),
    projectRepository: DaoProjectRepository(context.workspaceDbs),
    todoRepository: DaoTodoRepository(context.workspaceDbs),
    runLogRepository: DaoAgentRunLogRepository(context.workspaceDbs),
    pipelineRunRepository: PipelineRunRepositoryImpl(
      context.workspaceDbs,
      context.globalDb.workspaceRouteDao,
    ),
    pipelineTemplateRepository: PipelineTemplateRepositoryImpl(
      context.workspaceDbs,
    ),
    syncLogRepository: DaoTicketSyncLogRepository(context.workspaceDbs),
    workProductRepository: DaoWorkProductRepository(context.workspaceDbs),
    reviewCohortRepository: DaoReviewCohortRepository(context.workspaceDbs),
    reviewSpaceRepository: DaoReviewSpaceRepository(context.workspaceDbs),
    reviewAxisResultRepository: DaoReviewAxisResultRepository(
      context.workspaceDbs,
    ),
    baseSeed: context.baseSeed,
    registerConfirmation: context.registerConfirmation,
    refreshNewsfeed: context.refreshNewsfeed,
    log: log,
  );

  final visitors = DemoVisitorService(
    limits: context.limits,
    dataDir: context.dataDir,
    globalDb: context.globalDb,
    workspaceDbs: context.workspaceDbs,
    workspaceRepository: context.workspaceRepository,
    userRepository: context.userRepository,
    membershipRepository: context.membershipRepository,
    secrets: context.secrets,
    eventBus: context.eventBus,
    seedWorkspace: seeder.seedWorkspace,
    seedUser: seeder.seedUser,
    describeDescriptor: context.describeDescriptor,
    relayRoom: context.relayRoom,
    publicUrl: context.publicUrl,
    signalingUrl: context.signalingUrl,
    log: log,
  );

  return _DemoWiring(
    scripts: scripts,
    visitors: visitors,
    repoStats: DemoRepoStats(onLog: log),
    poller: DemoOpenPrPoller(
      workspaceRepository: context.workspaceRepository,
      workspaceDbs: context.workspaceDbs,
      changeSignals: context.changeSignals,
      prToWire: context.pullRequestToWire,
      eventBus: context.eventBus,
    ),
    forgeRegistry: buildDemoForgeRegistry(
      workspaceDbs: context.workspaceDbs,
      visitor: kDemoVisitorAuthor,
    ),
  );
}

class _DemoWiring implements DemoWiring {
  _DemoWiring({
    required List<DemoRunScript> scripts,
    required DemoVisitorService visitors,
    required this.repoStats,
    required this.poller,
    required ForgeProviderRegistry forgeRegistry,
  }) : _visitors = visitors,
       _forgeRegistry = forgeRegistry,
       agentLoop = ScriptedAgentLoop(scripts: scripts);

  final DemoVisitorService _visitors;
  final ForgeProviderRegistry _forgeRegistry;

  /// The poller, exposed by the interface.
  final DemoOpenPrPoller poller;

  /// The star count, exposed by the interface.
  @override
  final DemoRepoStats repoStats;

  @override
  final AgentLoop agentLoop;

  @override
  final DemoProfile profile = const DemoProfile();

  @override
  final ProviderCredentialStore credentials = const DemoCredentialStore();

  @override
  final HarnessProviderFactory harnessProviderFactory =
      const DemoHarnessProviderFactory();

  /// Only the built-in harness. Any other `cliName` resolves to null and the
  /// run fails with "No execution backend" — a demo host has no CLIs, and
  /// failing loudly beats reaching for one that is not there.
  @override
  final BackendRegistry backendRegistry = BackendRegistry({
    'cc-harness': const HarnessBackend(),
  });

  @override
  OpenPrPollingService get openPrPoller => poller;

  /// One registry for everyone: the demo's PR repository holds no client and
  /// no token, so there is no "as whom" decision to make.
  @override
  ForgeProviderRegistry forgeRegistryFor(String? userId) => _forgeRegistry;

  @override
  Future<Map<String, dynamic>> redeemVisitor(
    Map<String, dynamic> body, {
    String? remoteIp,
  }) => _visitors.redeem(body, remoteIp: remoteIp);

  @override
  Future<void> start() => _visitors.start();

  @override
  Future<void> stop() async {
    poller.dispose();
    await _visitors.stop();
  }
}
