import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_provider.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_server_core/src/demo/demo_limits.dart';
import 'package:cc_server_core/src/demo/demo_profile.dart';
import 'package:cc_server_core/src/demo/demo_repo_stats.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/pr_review/open_pr_polling_service.dart';


/// Everything `buildDemoWiring` needs from a half-built server runtime.
///
/// Every field is available early in `runCcServer` (the latest is the open-PR
/// poller), which is what lets the demo be assembled at ONE point rather than
/// threaded through a dozen late-bound closures.
class DemoRuntimeContext {
  /// Creates the context.
  const DemoRuntimeContext({
    required this.limits,
    required this.dataDir,
    required this.publicUrl,
    required this.signalingUrl,
    required this.globalDb,
    required this.workspaceDbs,
    required this.workspaceRepository,
    required this.userRepository,
    required this.membershipRepository,
    required this.secrets,
    required this.eventBus,
    required this.changeSignals,
    required this.pullRequestToWire,
    required this.describeDescriptor,
    required this.relayRoom,
    this.baseSeed,
    this.registerConfirmation,
    this.refreshNewsfeed,
    this.log,
  });

  /// Operational bounds, read from the environment.
  final DemoLimits limits;

  /// The server's data directory.
  final String dataDir;

  /// The public WebSocket URL, echoed in the redeem envelope.
  final String publicUrl;

  /// The signaling broker URL, echoed in the redeem envelope.
  final String signalingUrl;

  /// The global database (users, devices, the registry, the newsfeed).
  final GlobalDatabase globalDb;

  /// Per-workspace database handles.
  final WorkspaceDatabaseManager workspaceDbs;

  /// The workspace registry.
  final WorkspaceRepository workspaceRepository;

  /// User provisioning.
  final UserRepository userRepository;

  /// Workspace membership.
  final WorkspaceMembershipRepository membershipRepository;

  /// Device PSK storage.
  final PairedDeviceSecretsPort secrets;

  /// The domain event bus.
  final DomainEventBus eventBus;

  /// PR change signals, handed to the demo's open-PR poller.
  final PrChangeSignals changeSignals;

  /// The wire encoder the open-PR poller uses for a pull request.
  final Map<String, dynamic> Function(PullRequest pr) pullRequestToWire;

  /// Builds the connection descriptor for the redeem envelope.
  final Future<Map<String, dynamic>> Function() describeDescriptor;

  /// This server's relay room, for the redeem envelope.
  final String Function() relayRoom;

  /// Registers a PENDING approval in the host's live confirmation registry —
  /// the lane the inbox's "agent is waiting on you" strip reads. Null on a
  /// host without the registry; the demo seeder uses it to furnish the inbox.
  final void Function(ConfirmationRequest request)? registerConfirmation;

  /// Kicks a newsfeed refresh for one user at claim time, so a visitor sees
  /// real articles within seconds instead of waiting for the 30-minute
  /// sweep. Null leaves the demo with its seeded fallback articles only.
  final Future<void> Function(String userId)? refreshNewsfeed;

  /// The product's OWN workspace seeder (CEO + specialists + the built-in
  /// pipeline templates), run before the demo's flavour data.
  ///
  /// Late-bound by the runtime: it is constructed long after the demo wiring
  /// is assembled, and the pool only calls this once `start()` runs — well
  /// after the ready banner. Without it a demo workspace has no built-in
  /// templates at all, so the "keep only two" prune had nothing to prune and
  /// the Pipelines screen came up empty.
  final Future<void> Function(String workspaceId)? baseSeed;

  /// Diagnostic sink.
  final void Function(String message)? log;
}

/// Everything the runtime substitutes when it is running as a demo.
///
/// The runtime holds this INTERFACE, never the implementation. That is what
/// keeps the demo — its seeder, its scripts and their compiled-in fixtures —
/// out of the production `cc_server` binary: nothing in `cc_server`'s call
/// graph ever references `buildDemoWiring`, so the whole subtree is
/// tree-shaken away. The demo binary is a separate `dart build cli` target
/// that passes the builder in.
///
/// It is also why the demo cannot be turned on by a runtime flag: a public
/// endpoint whose lockdown depends on an environment variable can be
/// un-demoed by one deployment mistake, whereas a demo-only artifact makes
/// that failure impossible.
abstract interface class DemoWiring {
  /// The op-level lockdown applied to the built catalog.
  DemoProfile get profile;

  /// A credential store that satisfies the harness auth gate with no secret.
  ProviderCredentialStore get credentials;

  /// The scripted loop that replaces the real agent loop, so no tool executes
  /// and no model is called.
  AgentLoop get agentLoop;

  /// Restricted to the built-in harness adapter, so any other `cliName` fails
  /// loudly instead of reaching for a CLI the demo host does not have.
  BackendRegistry get backendRegistry;

  /// Builds inert providers that answer metadata and throw on completion.
  HarnessProviderFactory get harnessProviderFactory;

  /// The cache-backed, structurally offline PR review surface for [userId].
  ForgeProviderRegistry forgeRegistryFor(String? userId);

  /// A poller that never polls, so `pr.watchOpenForWorkspace` follows the
  /// seeded snapshot instead of short-circuiting to a signed-out empty list.
  OpenPrPollingService get openPrPoller;

  /// The project's own GitHub stars, fetched and cached server-side. Backs
  /// the `demo.repoStars` op — the one lane through which the client's
  /// "Star on GitHub" count may arrive (clients never dial GitHub directly).
  DemoRepoStats get repoStats;

  /// Replaces the real invite redemption: claims a warm, pre-seeded workspace
  /// and returns the SAME envelope shape, so the web client needs no changes.
  Future<Map<String, dynamic>> redeemVisitor(
    Map<String, dynamic> body, {
    String? remoteIp,
  });

  /// Warms the workspace pool and arms the reaper.
  ///
  /// Called strictly AFTER the ready banner: the desktop supervisor kills a
  /// child that has not reported readiness within 20 seconds.
  Future<void> start();

  /// Reaps every visitor and stops the reaper.
  Future<void> stop();
}

/// Builds the demo wiring from a half-built runtime.
///
/// `runCcServer` takes one of these rather than a [DemoWiring] directly
/// because the wiring needs runtime internals (databases, repositories, the
/// event bus) that do not exist until the boot is underway.
typedef DemoWiringBuilder =
    Future<DemoWiring> Function(DemoRuntimeContext context);
