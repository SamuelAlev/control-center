import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/file_search_hit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_host/cc_host.dart';
// ignore: implementation_imports
import 'package:cc_infra/src/git/git_diff_z_parser.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart'
    show McpToolDispatcher;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_model_control_io.dart';
import 'package:control_center/core/infrastructure/speech/diarization_model_control_io.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_control_io.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/utils/app_log.dart';
// The analytics cluster + calendar + PR-lifecycle providers collide by name
// between the public binding (`providers.dart`) and the server-side Drift impls
// (`server_providers.dart`). The in-process host must serve the LOCAL Drift
// impls (the public ones stay Drift on desktop, but sourcing them from
// server_providers keeps this catalog consistent with the other `dao*`/
// server-side repos and never recurses), so hide them from the public import.
// The adapter-detection / ACP-model / gh-CLI / process-detection providers
// collide by name the same way (public `providers.dart` seam vs the server-side
// `server_providers.dart` cc_infra impls). On WEB the public seam resolves to
// the cc_data RpcX adapters that talk to THIS host; the catalog must serve the
// LOCAL cc_infra services instead, so hide the public names here and source the
// server-side ones (the in-process host probes the desktop's own machine).
import 'package:control_center/di/server_providers.dart';
import 'package:control_center/features/mcp/providers/mcp_server_provider.dart';
import 'package:control_center/features/messaging/providers/conversation_changes_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_server_providers.dart';
import 'package:control_center/features/orchestration/providers/orchestration_server_providers.dart';
import 'package:control_center/features/pipelines/pipeline_server_providers.dart';
import 'package:control_center/features/pr_review/providers/ide_providers.dart';
import 'package:control_center/features/remote_control/data/services/remote_control_server.dart';
import 'package:control_center/features/remote_control/providers/remote_control_config_provider.dart';
import 'package:control_center/features/remote_control/providers/remote_control_devices_provider.dart';
import 'package:control_center/features/sandboxing/data/adapters/confirmation_port_adapter.dart';
import 'package:control_center/features/sandboxing/data/services/desktop_terminal_session_port.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers_server.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Tracks whether the remote-control listener is currently running.
final remoteControlRunningProvider =
    NotifierProvider<RemoteControlRunningNotifier, bool>(
      RemoteControlRunningNotifier.new,
    );

/// Notifier that reports the remote-control running state.
class RemoteControlRunningNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.keepAlive();
    return false;
  }

  /// Updates the running state to [value].
  // ignore: avoid_positional_boolean_parameters
  void setRunning(bool value) {
    state = value;
  }
}

/// The live repo-RPC + watch-query catalog (the typed, workspace-scoped surface
/// the first-party clients use), built from the real repositories/services.
/// Both transports (WebRTC + WSS) expose the same catalog.
final remoteRpcCatalogProvider = Provider<RemoteRpcCatalog>((ref) {
  // The catalog is the in-process server's data surface. EVERY repo it serves
  // is sourced from the DEDICATED server-side Dao providers (`dao*`) — NOT the
  // public `xRepositoryProvider`s, which now resolve to the cc_data RpcX
  // adapters that talk to THIS server. Reading a public one here would recurse
  // (catalog → Rpc → client → host → catalog). The ticketWorkflow service is
  // rebuilt on the server-side ticket repository so it mutates the DB directly
  // rather than over RPC. With slice 3, messaging + workspace now have RpcX
  // adapters too, so they are served from their dedicated dao* providers here
  // (the public providers resolve to RpcX and would recurse).
  //
  // The desktop in-process host also owns the Google Calendar connection: the
  // device-code GUI connect service + the periodic sync, over a file-backed
  // credential store under the app-support dir. The sync writes into the same
  // Drift calendar repo this host serves reads from.
  final serverCalendar = buildServerCalendar(
    calendarRepository: ref.read(calendarRepositoryProvider),
    workspaceRepository: ref.read(daoWorkspaceRepositoryProvider),
    eventBus: ref.read(domainEventBusProvider),
    dataDir: appCcPaths.appSupportRoot,
  );
  serverCalendar.sync.start();
  ref.onDispose(serverCalendar.sync.dispose);
  return buildRemoteRpcCatalog(
    ticketRepository: ref.read(daoTicketRepositoryProvider),
    projectRepository: ref.read(daoProjectRepositoryProvider),
    ticketWorkflow: TicketWorkflowService(
      repository: ref.read(daoTicketRepositoryProvider),
      eventBus: ref.read(domainEventBusProvider),
      onWarn: (message) => AppLog.w('TicketWorkflowService', message),
    ),
    messagingRepository: ref.read(daoMessagingRepositoryProvider),
    workspaceRepository: ref.read(daoWorkspaceRepositoryProvider),
    newsfeedRepository: ref.read(daoNewsfeedRepositoryProvider),
    agentRepository: ref.read(daoAgentRepositoryProvider),
    agentRunLogRepository: ref.read(daoAgentRunLogRepositoryProvider),
    repoRepository: ref.read(daoRepoRepositoryProvider),
    channelReadRepository: ref.read(daoChannelReadRepositoryProvider),
    memoryDomainRepository: ref.read(daoMemoryDomainRepositoryProvider),
    memoryAccessGrantRepository: ref.read(
      daoMemoryAccessGrantRepositoryProvider,
    ),
    agentWorkingMemoryRepository: ref.read(
      daoAgentWorkingMemoryRepositoryProvider,
    ),
    memoryFactRepository: ref.read(daoMemoryFactRepositoryProvider),
    memoryPolicyRepository: ref.read(daoMemoryPolicyRepositoryProvider),
    reviewChannelRepository: ref.read(daoReviewChannelRepositoryProvider),
    isolatedRepoRepository: ref.read(daoIsolatedRepoRepositoryProvider),
    voiceProfileRepository: ref.read(daoVoiceProfileRepositoryProvider),
    meetingRepository: ref.read(daoMeetingRepositoryProvider),
    ticketLinkRepository: ref.read(daoTicketLinkRepositoryProvider),
    pipelineRunRepository: ref.read(daoPipelineRunRepositoryProvider),
    pipelineTemplateRepository: ref.read(daoPipelineTemplateRepositoryProvider),
    pipelineTriggerRepository: ref.read(daoPipelineTriggerRepositoryProvider),
    teamRepository: ref.read(daoTeamRepositoryProvider),
    orchestrationRepository: ref.read(daoOrchestrationRepositoryProvider),
    // Pairing management: the desktop owns the Drift `paired_devices` DAO + the
    // keychain-backed PSK store, so a connected first-party (web) client can
    // mint / list / rename / revoke pairings over the `pairing.*` ops. The
    // desktop's in-process host serves the UI over a loopback channel, so it
    // advertises NO direct-WS URL — a phone reaches the desktop over WebRTC
    // (the broker-mediated path), and the pairing UI falls back to that when
    // `server_url` is empty. (A desktop running its LAN WSS server could later
    // advertise that reachable URL here so phones connect directly instead.)
    pairedDeviceDao: ref.read(pairedDeviceDaoProvider),
    pairedDeviceSecretsPort: ref.read(pairedDeviceSecretsProvider),
    pairingServerUrl: '',
    // Analytics cluster: the desktop in-process host owns the Drift-backed
    // analytics/achievement/streak repositories (defined in server_providers.dart;
    // they stay local — there is no RpcX adapter for them — so reading the public
    // provider here does NOT recurse). The thin client READS these over the
    // `analytics.*`/`achievements.*`/`streaks.*` ops; the writes (unlock /
    // updateStreak) run in-process via the XpEngine, not over RPC.
    analyticsRepository: ref.read(analyticsRepositoryProvider),
    achievementRepository: ref.read(achievementRepositoryProvider),
    streakRepository: ref.read(streakRepositoryProvider),
    // Calendar: the desktop in-process host owns the Drift-backed calendar
    // repository (defined in server_providers.dart; it stays local — there is no
    // RpcX adapter for it, so reading the hidden public provider here resolves to
    // the server-side one and does NOT recurse). The thin client READS this over
    // the `calendar.*` ops/watches; the writes (account connect/disconnect,
    // RSVP, sync, alerts, meeting linking) run in-process, not over RPC.
    calendarRepository: ref.read(calendarRepositoryProvider),
    calendarConnect: serverCalendar.connect,
    // PR lifecycle: the desktop in-process host owns the Drift-backed
    // PR-lifecycle repository (defined in server_providers.dart; it stays local
    // — there is no RpcX adapter for it, so reading the hidden public provider
    // here resolves to the server-side one and does NOT recurse). The thin client
    // READS the draft list/by-id AND WRITES (create / update / publish / delete)
    // over the `pr_lifecycle.*` ops; publishing runs in-process against the
    // desktop's authenticated GitHub token.
    prLifecycleRepository: ref.read(prLifecycleRepositoryProvider),
    // Activity log: the desktop owns the Drift `activity_log` DAO, so it serves
    // `activity.watchForEntity` (a connected client's entity-timeline view) over
    // a read-only reader built on that DAO. The desktop's OWN timeline view stays
    // in-process (provider_bindings_io's watchEntityActivity) until the boot flip.
    activityLogReader: DaoActivityLogReader(ref.read(activityLogDaoProvider)),
    // Server-host capabilities: the desktop in-process host runs `git` on its
    // own filesystem and drives the event-bus-backed indexing pipeline, so it
    // wires the real inspector + bus (enabling `repos.addFromPath` over RPC).
    gitRepoInspector: ref.read(gitRepoInspectorPortProvider),
    // Folder browser for the web add-repo flow: a connected client navigates the
    // desktop's filesystem (rooted at the user's home) to pick a git checkout.
    directoryBrowser: ref.read(directoryBrowserPortProvider),
    // Server-host adapter / model / gh-CLI probing: the desktop links cc_infra,
    // so it probes the agent-runner CLIs installed on ITS machine for a connected
    // client's Settings → Adapters + auth status. Sourced from the server-side
    // (hidden) providers — the public seam resolves to RpcX on web and would
    // recurse. `github_cli.probe` redacts the resolved token (never shipped).
    adapterDetection: ref.read(adapterRepositoryProvider),
    acpModels: ref.read(acpModelRepositoryProvider),
    githubCli: ref.read(githubCliServiceProvider),
    // Sandbox detection: the desktop links cc_infra, so it probes ITS machine's
    // OS-native sandbox backends for a connected client's Settings → Sandboxing.
    sandboxDetector: ref.read(localSandboxDetectorProvider),
    // Process detection: the desktop scans ITS OS process table for agent
    // processes (the dashboard's cross-workspace "active processes" matrix) and
    // can stop one by pid. Both ops are fullClient-only + cross-workspace.
    processDetection: ref.read(processDetectionServiceProvider),
    eventBus: ref.read(domainEventBusProvider),
    // The desktop is a GUI host: wire the editor launcher + PR-worktree port so
    // `ide.detectEditors` + `ide.openPrInEditor` work over RPC (open a PR's
    // branch in an editor on this machine from a connected web/remote client).
    editorLauncher: ref.read(editorLauncherProvider),
    prWorktreePort: ref.read(prWorktreePortProvider),
    // Conversation working-tree diff: reuse the desktop's local-diff provider
    // (worktree registry + `git diff`) so a connected client can view a
    // conversation's uncommitted changes.
    conversationChanges: (workspaceId, channelId) => ref.read(
      conversationChangesProvider(
        (workspaceId: workspaceId, channelId: channelId),
      ).future,
    ),
    // Repo working-tree diff (vs HEAD, incl. untracked) WITH patches, computed
    // DIRECTLY via git on the owned checkout (no provider chain / recursion).
    // Workspace-scoped: a repo not linked to the workspace yields no files.
    repoChanges: (workspaceId, repoId) async {
      final ws = ref.read(daoWorkspaceRepositoryProvider);
      if (!await ws.isRepoLinkedToWorkspace(workspaceId, repoId)) {
        return const <PrFile>[];
      }
      final repo = await ref.read(daoRepoRepositoryProvider).getById(repoId);
      if (repo == null) {
        return const <PrFile>[];
      }
      final git = ref.read(gitCommandPortProvider);
      final dir = repo.path;

      // Tracked changes vs HEAD (staged + unstaged).
      final nameStatusRes = await git.run(
        ['diff', 'HEAD', '--name-status', '-z', '-M'],
        workdir: dir,
      );
      var files = const <PrFile>[];
      if (nameStatusRes.isSuccess) {
        final numstatRes = await git.run(
          ['diff', 'HEAD', '--numstat', '-z', '-M'],
          workdir: dir,
        );
        final statusMap = parseGitNameStatusZ(nameStatusRes.stdout);
        files = parseGitNumstatZ(numstatRes.stdout, statusMap);
      }

      // Untracked files (status: added, 0/0). ls-files needs no HEAD.
      final untrackedRes = await git.run(
        ['ls-files', '--others', '--exclude-standard', '-z'],
        workdir: dir,
      );
      if (untrackedRes.isSuccess) {
        final untracked = <PrFile>[];
        for (final path in untrackedRes.stdout.split('\x00')) {
          if (path.isEmpty) {
            continue;
          }
          untracked.add(
            PrFile(
              filename: path,
              status: PrFileStatus.added,
              additions: 0,
              deletions: 0,
              patch: '',
            ),
          );
        }
        files = [...files, ...untracked];
      }

      // Patches (one `git diff HEAD -p -M` pass), merged per file by filename.
      if (nameStatusRes.isSuccess) {
        final patchRes = await git.run(['diff', 'HEAD', '-p', '-M'], workdir: dir);
        final patches = _splitGitPatches(patchRes.stdout);
        files = [for (final f in files) _withPatch(f, patches[f.filename])];
      }
      return files;
    },
    // Reads a file from a linked repo checkout SERVER-SIDE (text + binary
    // flag), rejecting traversal outside the repo root.
    repoFileContent: (workspaceId, repoId, path) async {
      final ws = ref.read(daoWorkspaceRepositoryProvider);
      const empty = (content: '', binary: true);
      if (!await ws.isRepoLinkedToWorkspace(workspaceId, repoId)) {
        return empty;
      }
      final repo = await ref.read(daoRepoRepositoryProvider).getById(repoId);
      if (repo == null) {
        return empty;
      }
      final normalized = p.normalize(p.join(repo.path, path));
      if (!p.isWithin(repo.path, normalized)) {
        return empty;
      }
      final file = File(normalized);
      if (!file.existsSync()) {
        return empty;
      }
      final bytes = await file.readAsBytes();
      final isBinary = bytes.any((b) => b == 0);
      return (
        content: isBinary ? '' : utf8.decode(bytes, allowMalformed: true),
        binary: isBinary,
      );
    },
    // Server-side fuzzy file search across the workspace's linked repo roots
    // (returns wire maps; the client rebuilds FileSearchHit). fff runs over the
    // CoW checkouts the SERVER owns.
    repoFileSearch: (workspaceId, query) async {
      final ws = ref.read(daoWorkspaceRepositoryProvider);
      final repos = await ws.watchReposForWorkspace(workspaceId).first;
      final search = ref.read(fileSearchProvider);
      final roots = repos.map((r) => r.path).toList();
      final stream = query.isEmpty
          ? search.listEntries(roots: roots)
          : search.search(roots: roots, query: query, limit: 500);
      final hits = await stream.first;
      final repoIdByRoot = {for (final r in repos) r.path: r.id};
      // Map the native hit to the web-safe domain type and serialize THAT, so
      // the domain `FileSearchHit` is the single source of truth for the wire
      // shape the thin client reconstructs. `repoId` is grouping metadata the
      // server attaches per hit (matched by rootPath → linked repo).
      return hits
          .map(
            (h) => <String, dynamic>{
              ...FileSearchHit(
                absolutePath: h.absolutePath,
                relativePath: h.relativePath,
                rootPath: h.rootPath,
                isDirectory: h.isDirectory,
                score: h.score,
              ).toJson(),
              'repoId': repoIdByRoot[h.rootPath] ?? '',
            },
          )
          .toList();
    },
    // MCP server control: the desktop is a thin client and no longer hosts its
    // own MCP HTTP server — it runs inside the connected `cc_server`. So this
    // host exposes no MCP control (null → the `mcp.*` ops degrade to "managed on
    // the server host"); the settings section drives the server's MCP over RPC.
    mcpControl: null,
    // On-device model control: the desktop owns the cc_natives FFI models, so a
    // connected web/remote client drives each model's status/install/uninstall
    // through these adapters (the same in-process lifecycle controllers the
    // desktop sections read directly). A headless cc_server hosts no models, so
    // it leaves these null and the web sections degrade to "managed on the host".
    embeddingModelControl: DesktopEmbeddingModelControl(ref),
    diarizationModelControl: DesktopDiarizationModelControl(ref),
    voiceModelControl: DesktopVoiceModelControl(ref),
    // Interactive terminal: the desktop links flutter_pty, so it owns the PTY
    // sessions a connected web/remote client drives over the `terminal.*` ops +
    // the `terminal.output` subscription. A headless cc_server links no
    // flutter_pty → it leaves this null and the web terminal degrades to an
    // honest "terminal runs on the server host" state.
    terminalSessions: DesktopTerminalSessionPort(ref),
    // Workspace on-disk layout: the desktop owns the real agents/skills/
    // conversation directory tree (the io-bound WorkspaceFilesystemService), so
    // a connected web/remote client resolves those server-side paths + writes
    // through them over the `fs.*` ops.
    workspaceFilesystem: ref.read(workspaceFilesystemPortProvider),
    // Messaging dispatch: the desktop links the dispatch engine (sandbox / PTY /
    // claude-relay), so it serves the channel-lifecycle + agent-dispatch service
    // over the `dispatch.*` ops. On this (io) build `messagingServiceProvider`
    // resolves to the real DB-owning `MessagingService` (NOT the RPC-flipped
    // port), so reading it here does NOT cycle through the host. A connected
    // web/remote client's composer (send-and-dispatch / retry / refine / open a
    // DM / create a group) then executes server-side; the reply streams back via
    // the existing `messaging.watchMessages` subscription.
    messagingDispatch: ref.read(messagingServiceProvider),
    // Pipeline executor: the desktop constructs the live `PipelineEngine` (it
    // owns run-state persistence + drives the dispatch stack), so it serves the
    // `pipeline.*` ops (start / cancel / retry a run, kill a step). On this (io)
    // build `pipelineEngineServerProvider` resolves to the real DB-owning engine
    // (NOT an RPC-flipped port), so reading it here does NOT cycle through the
    // host. A connected web/remote client then starts/cancels pipelines
    // server-side; live run/step state streams back via the existing
    // `pipeline_run.watch*` subscriptions. A headless cc_server constructs no
    // engine → the ops are absent there.
    pipelineEngine: ref.read(pipelineEngineServerProvider),
    // Orchestration executor: approving/cancelling hires agents + starts/cancels
    // pipelines via the same engine + the orchestration use-cases, so the desktop
    // wires each as a closure over those use-cases. The bound workspace is
    // server-supplied (`ctx.workspaceId`); the use-cases re-validate ownership.
    approveOrchestration: (workspaceId, orchestrationId) =>
        ref.read(approveOrchestrationUseCaseProvider).approve(
          workspaceId: workspaceId,
          orchestrationId: orchestrationId,
        ),
    cancelOrchestration: (workspaceId, orchestrationId) =>
        ref.read(cancelOrchestrationUseCaseProvider).cancel(
          workspaceId: workspaceId,
          orchestrationId: orchestrationId,
        ),
    // Review-fix agent dispatch: spawns a sandboxed agent against the bound
    // workspace's checkout. The working directory is resolved HERE from the
    // server-supplied `workspaceId` (never a client-sent path), so a thin
    // client cannot aim the agent at an arbitrary directory.
    reviewDispatch:
        ({
          required workspaceId,
          required agentId,
          required prompt,
          required channelId,
        }) async {
          final workingDir = await ref
              .read(workspaceFilesystemPortProvider)
              .workspaceDir(workspaceId);
          await ref.read(agentDispatchServiceProvider).dispatch(
            agentId: agentId,
            prompt: prompt,
            workingDirectory: workingDir,
            workspaceId: workspaceId,
            channelId: channelId,
            conversationId: channelId,
          );
        },
    // PR review (per-(workspace, owner, repo)): the catalog resolves cache-backed
    // repositories via the Dao-backed factory, which owns the GitHub client (the
    // desktop holds the token) + the cache/review DAOs. The reference-preview
    // fetchers hit GitHub directly; the catalog SWR-caches their result against
    // the workspace cache.
    vcsProviderFactory: ref.read(daoVcsProviderFactoryProvider),
    prPreviewCache: ref.read(cacheDaoProvider),
    fetchPrPreview: (owner, repo, number) async {
      try {
        final pr = await ref
            .read(githubApiClientProvider)
            .pr
            .getPullRequest(owner, repo, number);
        if (pr == null) {
          return null;
        }
        return {
          'title': pr.title,
          'state': pr.state,
          'is_draft': pr.isDraft,
          'is_merged': pr.mergedAt != null,
          'html_url': pr.htmlUrl,
        };
      } catch (_) {
        return null;
      }
    },
    fetchCommitPreview: (owner, repo, sha) async {
      try {
        final commit = await ref
            .read(githubApiClientProvider)
            .pr
            .getCommit(owner, repo, sha);
        if (commit == null) {
          return null;
        }
        return {'title': commit.title, 'short_sha': commit.shortSha};
      } catch (_) {
        return null;
      }
    },
    pendingConfirmationRegistry:
        ref.read(pendingConfirmationRegistryProvider),
  );
});

/// The desktop self-serve RPC client — the desktop talking to ITS OWN data over
/// a loopback [InProcessRpcHost] (the "composition flip"). Built EXACTLY ONCE
/// (keep-alive singleton): the host owns a long-lived session + workspace
/// binding, so every dependency is `read`, never `watch`.
///
/// This is desktop-only (it transitively pulls the Drift DB + the in-process
/// server stack via `cc_server_core`). The composition root installs it as the
/// override for the platform-neutral `rpcClientProvider` seam when the desktop
/// self-serves; web / desktop-connected-to-remote builds override that seam with
/// a connected [RemoteRpcClient] instead and never read this provider.
///
/// The host binds to the desktop's ACTIVE workspace and re-binds whenever it
/// changes, so scoped reads/writes the flipped feature repos issue resolve to
/// the workspace the user is currently looking at. Cross-workspace surfaces use
/// the catalog's unscoped (`workspaceScoped:false`) ops/queries, which ignore
/// the binding.
final inProcessRpcClientProvider = Provider<RemoteRpcClient>((ref) {
  ref.keepAlive();
  final catalog = ref.read(remoteRpcCatalogProvider);
  final host = InProcessRpcHost(
    dispatcher: ref.read(mcpToolDispatcherProvider),
    workspaceResolver: ref.read(remoteWorkspaceListResolverProvider),
    repoOps: RepoOpDispatcher(
      registry: catalog.ops,
      mapException: mapAppExceptionToRpc,
    ),
    watchQueries: catalog.watch,
    initialWorkspaceId: ref.read(activeWorkspaceIdProvider),
  );
  // Follow the desktop's active workspace so scoped queries re-scope on switch.
  ref.listen<String?>(activeWorkspaceIdProvider, (_, next) {
    host.rebindWorkspace(next);
  });
  ref.onDispose(() => unawaited(host.dispose()));
  return host.client;
});

/// Resolves the workspaces a phone can switch between, as id+name summaries.
///
/// Server-side: this feeds the in-process host (`rpcClientProvider`) and the
/// remote-control server, so it reads the Dao-backed workspace repo directly —
/// reading the UI `workspacesProvider` (now RPC-flipped) would cycle
/// (rpcClient → resolver → workspaces → workspace RPC → rpcClient).
final remoteWorkspaceListResolverProvider = Provider<RemoteWorkspaceResolver>((
  ref,
) {
  return () async {
    final workspaces =
        await ref.read(daoWorkspaceRepositoryProvider).watchAll().first;
    return workspaces.map((Workspace w) => (id: w.id, name: w.name)).toList();
  };
});

/// Builds and manages the lifecycle of the [RemoteControlServer].
///
/// Shares the same [McpToolDispatcher] as the MCP HTTP server — one RPC
/// surface, two transports. The listener auto-starts only when enabled and
/// fully configured; it can also be started/stopped manually from settings.
final remoteControlServerProvider = Provider<RemoteControlServer>((ref) {
  ref.keepAlive();
  // This server is a long-lived stateful singleton: it owns WebSocket signaling
  // connections and one WebRTC peer per device, so it must be built EXACTLY
  // ONCE. Every dependency is therefore `read`, never `watch` — watching a
  // volatile provider (e.g. mcpToolDispatcherProvider → the tool registry, which
  // rebuilds during startup) would dispose+rebuild this provider, spawning a
  // SECOND server that joins the same capacity-2 broker room. Two desktop slots
  // → the phone gets "room full". (These deps are all stable singletons anyway.)
  final config = ref.read(remoteControlConfigProvider);
  final dispatcher = ref.read(mcpToolDispatcherProvider);
  final catalog = ref.read(remoteRpcCatalogProvider);
  final server = RemoteControlServer(
    config: config,
    dispatcher: dispatcher,
    devicesDao: ref.read(pairedDeviceDaoProvider),
    secrets: ref.read(pairedDeviceSecretsProvider),
    eventBus: ref.read(domainEventBusProvider),
    workspaceResolver: ref.read(remoteWorkspaceListResolverProvider),
    repoOps: RepoOpDispatcher(
      registry: catalog.ops,
      mapException: mapAppExceptionToRpc,
    ),
    watchQueries: catalog.watch,
    onRunningChanged: ({required running}) =>
        ref.read(remoteControlRunningProvider.notifier).setRunning(running),
  );
  ref.onDispose(() {
    server.onRunningChanged = null;
    server.stop();
  });
  if (config.enabled && config.isConfigured) {
    Future.microtask(() async {
      try {
        await server.start();
      } catch (e, st) {
        AppLog.e('RemoteControl', 'Failed to start server: $e', e, st);
      }
    });
  }
  return server;
});

/// Emits the set of device ids with a live RPC session (the phones currently
/// connected over WebRTC), for the Devices settings screen's live badge.
final connectedDeviceIdsProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(remoteControlServerProvider).connectedDevices;
});

/// Emits the set of device ids that have authenticated but are still pending
/// confirmation — a phone is waiting for the user to approve it. Drives the
/// "wants to connect" indicator on the Devices settings screen.
final awaitingApprovalDeviceIdsProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(remoteControlServerProvider).awaitingApprovalDevices;
});

/// Splits `git diff -p` output into per-file patch blocks keyed by filename.
///
/// Each block begins with `diff --git `. The new path is taken from the
/// `+++ b/<path>` line (matches a renamed file's post-rename name, which is
/// what [parseGitNumstatZ] records as the filename); pure deletions fall back
/// to `--- a/<path>` (their `+++` is `/dev/null`).
Map<String, String> _splitGitPatches(String raw) {
  final out = <String, String>{};
  // `split` drops the leading delimiter; re-attach it so each segment is a
  // complete, renderable `diff --git …` block.
  for (final segment in raw.split('diff --git ')) {
    if (segment.isEmpty) {
      continue;
    }
    final block = 'diff --git $segment';
    final filename = _extractDiffPath(block);
    if (filename != null && filename.isNotEmpty) {
      out[filename] = block;
    }
  }
  return out;
}

String? _extractDiffPath(String block) {
  String? newPath;
  String? oldPath;
  for (final line in block.split('\n')) {
    if (line.startsWith('+++ ')) {
      final v = line.substring(4);
      if (v.startsWith('b/')) {
        newPath = v.substring(2);
      }
    } else if (line.startsWith('--- ')) {
      final v = line.substring(4);
      if (v.startsWith('a/')) {
        oldPath = v.substring(2);
      }
    }
  }
  // Prefer the new path (renames/modifications); deletions keep the old path.
  return newPath ?? oldPath;
}

/// Returns [file] with its [patch] replaced by [patch] when present.
PrFile _withPatch(PrFile file, String? patch) {
  if (patch == null) {
    return file;
  }
  return PrFile(
    filename: file.filename,
    status: file.status,
    additions: file.additions,
    deletions: file.deletions,
    patch: patch,
    previousFilename: file.previousFilename,
    viewerViewedState: file.viewerViewedState,
  );
}
