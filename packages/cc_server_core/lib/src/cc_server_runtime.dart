import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/core/domain/services/memory_access_policy.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_summarizer.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_memory_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/memory/domain/services/fact_extraction.dart';
import 'package:cc_domain/features/memory/domain/services/memory_consolidation_service.dart';
import 'package:cc_domain/features/memory/domain/usecases/extract_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/harmonize_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/promote_facts_to_policy_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/record_memory_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/supersede_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/supersede_policy_use_case.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_run_listener.dart';
import 'package:cc_domain/features/orchestration/domain/usecases/cancel_orchestration_use_case.dart';
import 'package:cc_domain/features/pipelines/domain/services/agent_run_task_completer.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_cost_rollup_listener.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_step_resume_listener.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_trigger_dispatcher.dart';
import 'package:cc_domain/features/pipelines/domain/services/sub_pipeline_resume_listener.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_search_query.dart';
import 'package:cc_domain/features/ticketing/domain/services/project_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/src/code_graph/code_indexer.dart';
import 'package:cc_infra/src/detection/acp_models_repository_impl.dart';
import 'package:cc_infra/src/detection/acp_models_service.dart';
import 'package:cc_infra/src/detection/adapter_detection_repository.dart';
import 'package:cc_infra/src/detection/adapter_detection_service.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/dispatch/agent_registry_impl.dart';
import 'package:cc_infra/src/dispatch/sandboxed_agent_dispatch_adapter.dart';
import 'package:cc_infra/src/embedding/embedding_model_manager.dart';
import 'package:cc_infra/src/embedding/embedding_service.dart';
import 'package:cc_infra/src/git/git_repo_inspector.dart';
import 'package:cc_infra/src/git/github_cli_service.dart';
import 'package:cc_infra/src/git/github_pr_search_adapter.dart';
import 'package:cc_infra/src/git/github_status_service.dart';
import 'package:cc_infra/src/git/process_git_command_adapter.dart';
import 'package:cc_infra/src/git/process_git_snapshot_adapter.dart';
import 'package:cc_infra/src/meetings/meeting_audio_loader.dart';
import 'package:cc_infra/src/meetings/meeting_recording_session.dart';
import 'package:cc_infra/src/meetings/meeting_summary_reconciler.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/agent_stream_processor.dart';
import 'package:cc_infra/src/messaging/conversation_compaction_service.dart';
import 'package:cc_infra/src/messaging/messaging_service.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_infra/src/network/klipy_api_client.dart';
import 'package:cc_infra/src/network/pr_review_mapper.dart';
import 'package:cc_infra/src/newsfeed/rss_fetcher_service.dart';
import 'package:cc_infra/src/pr_review/local_git_pr_diff_source.dart';
import 'package:cc_infra/src/pr_review/pr_worktree_service.dart';
import 'package:cc_infra/src/process/process_detection_service.dart';
import 'package:cc_infra/src/repos/filesystem_directory_browser.dart';
import 'package:cc_infra/src/repos/rift_repo_isolation_adapter.dart';
import 'package:cc_infra/src/sandboxing/env_credential_broker.dart';
import 'package:cc_infra/src/sandboxing/env_credentials_repository.dart';
import 'package:cc_infra/src/sandboxing/native_sandbox_adapter.dart';
import 'package:cc_infra/src/sandboxing/no_sandbox_adapter.dart';
import 'package:cc_infra/src/sandboxing/sandbox_backend_detector.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/terminal_session_service.dart';
import 'package:cc_infra/src/speech/diarization_model_manager.dart';
import 'package:cc_infra/src/speech/voice_model_manager.dart';
import 'package:cc_infra/src/usecases/approve_orchestration_use_case.dart';
import 'package:cc_infra/src/usecases/hire_agent_use_case.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:cc_infra/src/util/json_schema_validator.dart';
import 'package:cc_infra/src/workspaces/workspace_filesystem_service.dart';
import 'package:cc_infra/src/workspaces/workspace_seeder.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:cc_natives/cc_natives.dart'
    show
        GrammarManager,
        MeetingDiarizationService,
        Pty,
        RiftClient,
        SherpaOnnxTranscriber,
        ensureOnnxRuntimeLoaded,
        nativeLibDirEnvVar,
        nativeLibraryCandidates,
        ptyLibraryBaseName,
        ptyLibraryEnvVar,
        resolveSherpaLibraryDir,
        setPreferredSherpaLibDir,
        tryOpenFirst;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/repositories/db_conversation_mode_resolver.dart';
import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:cc_server_core/src/dao_activity_log_reader.dart';
import 'package:cc_server_core/src/dao_code_graph_repository.dart';
import 'package:cc_server_core/src/dao_newsfeed_repository.dart';
import 'package:cc_server_core/src/dao_pr_lifecycle_repository.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/github_vcs_provider_factory.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:cc_server_core/src/local_rpc_server.dart';
import 'package:cc_server_core/src/models/managed_model_control.dart';
import 'package:cc_server_core/src/models/selectable_voice_model_control.dart';
import 'package:cc_server_core/src/relay/remote_relay_host.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:cc_server_core/src/server_mcp_client_control.dart';
import 'package:cc_server_core/src/server_mcp_control.dart';
import 'package:cc_server_core/src/server_mcp_registry.dart';
import 'package:cc_server_core/src/server_pipeline_executor.dart';
import 'package:dio/dio.dart' show InterceptorsWrapper;
import 'package:drift/drift.dart' show Value;

/// A running headless server instance — holds the database + WS server so a
/// caller (the `cc_server` binary, or a test) can shut it down cleanly.
class CcServer {
  CcServer._(this._db, this.rpc, this._mcpControl);

  final AppDatabase _db;
  final ServerMcpControl _mcpControl;

  /// The bound WebSocket RPC server.
  final LocalRpcServer rpc;

  /// Periodic newsfeed-refresh timer (cancelled on [shutdown]).
  Timer? _newsfeedRefreshTimer;

  /// Meeting-summary finalizer (started after boot; disposed on [shutdown]).
  MeetingSummaryReconciler? _meetingReconciler;

  /// Live RPC meeting recorder, when an ASR model is installed (else null).
  /// Open sessions are aborted on [shutdown]; the reconciler recovers them.
  MeetingRecordingService? _meetingRecording;

  /// Selectable ASR/voice model control (download + model switching over the
  /// `models.voice*` ops). Cancels any in-flight download on [shutdown].
  SelectableVoiceModelControl? _voiceModelControl;

  /// Server-side Google Calendar sync sweep, started after boot when a Google
  /// client id is configured (else null). Disposed on [shutdown].
  ServerCalendarSync? _calendarSync;

  /// Relays phone connections through the signaling broker when the server is
  /// not directly reachable (cc_server is the owning peer). Disposed on
  /// [shutdown].
  RemoteRelayHost? _relayHost;

  /// The MCP client (connections to external MCP servers). Bridged tools are
  /// pushed into the shared registry; all connections (and their stdio child
  /// process trees) are torn down on [shutdown].
  McpClientService? _mcpClientService;

  /// Stops the server and closes the database.
  Future<void> shutdown() async {
    _newsfeedRefreshTimer?.cancel();
    _calendarSync?.dispose();
    _meetingReconciler?.dispose();
    await _meetingRecording?.dispose();
    await _voiceModelControl?.dispose();
    await _relayHost?.stop();
    await _mcpClientService?.shutdown();
    await rpc.stop();
    await _mcpControl.dispose();
    await _db.close();
  }
}

/// Boots the pure-Dart headless server: opens the database over
/// [openServerDatabase], wires the repository-backed RPC catalog
/// (tickets / messaging / newsfeed) onto a [LocalRpcServer], and starts
/// listening. No Flutter — this links into a `dart build cli` native binary.
///
/// Diagnostics route through [CcHostLog] (installed to stdout/stderr here).
/// Paired-device PSKs live in a [FileSecretsStore] under the data dir.
Future<CcServer> runCcServer({List<String> args = const []}) async {
  final config = CcServerConfig.resolve(args);

  CcHostLog.sink = (level, message, [error, stackTrace]) {
    final line = '[${level.name}] $message';
    if (level == CcHostLogLevel.error) {
      stderr.writeln(line);
      if (error != null) {
        stderr.writeln('  $error');
      }
    } else {
      stdout.writeln(line);
    }
  };

  // The Drift-backed repositories log through their own seam; route it to the
  // same stdout/stderr so server persistence diagnostics are visible.
  CcPersistenceLog.sink = (level, message, [error, stackTrace]) {
    final line = '[${level.name}] $message';
    if (level == CcPersistenceLogLevel.error) {
      stderr.writeln(line);
      if (error != null) {
        stderr.writeln('  $error');
      }
    } else {
      stdout.writeln(line);
    }
  };

  // Domain services (reconcilers, listeners, the pipeline engine) log through
  // the shared-kernel seam; route it to the same stdout/stderr.
  CcDomainLog.sink = (level, message, [error, stackTrace]) {
    final line = '[${level.name}] $message';
    if (level == CcDomainLogLevel.error) {
      stderr.writeln(line);
      if (error != null) {
        stderr.writeln('  $error');
      }
    } else {
      stdout.writeln(line);
    }
  };

  final db = AppDatabase(
    openServerDatabase(dataDir: config.dataDir),
    onWarn: (tag, message) => CcHostLog.warning('$tag: $message'),
    onError: (tag, message) => CcHostLog.error('$tag: $message'),
  );
  // ONE secrets store shared by every consumer (bootstrap provisioning, the
  // `pairing.*` ops that MINT new device PSKs, and the LocalRpcServer that
  // AUTHENTICATES them). FileSecretsStore caches the on-disk map in memory, so
  // separate instances would diverge — a PSK minted via the catalog's instance
  // would be invisible to the server's authenticator (auth would silently fail
  // and a freshly-paired client could never connect).
  final secrets = FileSecretsStore(dataDir: config.dataDir);
  final eventBus = DomainEventBus();

  // ── On-device embedding model (semantic search over memory facts, code
  // symbols, and conversation history) ──
  // The headless server hosts the embedding model exactly like the desktop: an
  // on-disk ONNX model managed by [EmbeddingModelManager] and downloaded over
  // the `models.install` (embedding) RPC. The [EmbeddingService] is constructed
  // up front and threaded into every consumer (memory / code-graph /
  // conversation repos + the MCP search tools); each guards on `isReady`, so it
  // degrades to keyword/FTS until the model is installed, then lights up via
  // [EmbeddingService.updatePaths] the moment a download finishes — no restart.
  // The `sqlite_vector` extension is already loaded in openServerDatabase, so
  // the KNN queries work once vectors exist on disk.
  final paths = CcPaths(config.dataDir);
  final embeddingModelManager = EmbeddingModelManager(paths: paths);
  final embeddingService = EmbeddingService(
    modelInfo: embeddingModelManager.model,
  );
  // Best-effort: pick up an already-installed model at boot.
  embeddingService.updatePaths(await embeddingModelManager.resolve());

  final ticketRepository = DaoTicketRepository(db.ticketDao);
  final projectRepository = DaoProjectRepository(db.projectDao);
  final ticketWorkflow = TicketWorkflowService(
    repository: ticketRepository,
    eventBus: eventBus,
    onWarn: (m) => CcHostLog.warning('TicketWorkflowService: $m'),
  );
  final messagingRepository = DaoMessagingRepository(db.messagingDao);
  // The headless server owns the FULL newsfeed surface (DB reads + RSS
  // fetch/refresh/feed-management) via the same repository the desktop uses,
  // composing the cc_infra RSS fetcher with the cc_persistence RSS DAO.
  final newsfeedRepository = DaoNewsfeedRepository(
    db.rssDao,
    RssFetcherService(createDio()),
  );

  final agentRepository = DaoAgentRepository(db.agentDao);
  final agentRunLogRepository = DaoAgentRunLogRepository(db.agentDao);
  final repoRepository = DaoRepoRepository(db.repoDao);
  final channelReadRepository = DaoChannelReadRepository(db.messagingDao);
  final memoryDomainRepository = DaoMemoryDomainRepository(db.memoryDomainDao);
  final memoryAccessGrantRepository = DaoMemoryAccessGrantRepository(
    db.memoryAccessGrantDao,
  );
  final agentWorkingMemoryRepository = DaoAgentWorkingMemoryRepository(
    db.agentWorkingMemoryDao,
  );
  // PRD 04 memory-intelligence repos (conflict, semantic graph, hot tier,
  // harmonized beliefs).
  final memoryConflictRepository = DaoMemoryConflictRepository(
    db.memoryConflictDao,
  );
  final episodicEdgeRepository = DaoEpisodicEdgeRepository(db.episodicEdgeDao);
  final workingMemoryItemRepository = DaoWorkingMemoryItemRepository(
    db.workingMemoryItemDao,
    db.memoryConsolidationLogDao,
  );
  final memoryBeliefRepository = DaoMemoryBeliefRepository(db.memoryBeliefDao);
  final memoryFactRepository = DaoMemoryFactRepository(
    db.memoryFactDao,
    // Facts are embedded on write and searched semantically once the embedding
    // model is installed; until then `SearchMemoryTool` degrades to keyword.
    embeddingService: embeddingService,
    // Powers the polyphonic recall graph voice.
    edgeDao: db.episodicEdgeDao,
  );
  final memoryPolicyRepository = DaoMemoryPolicyRepository(db.memoryPolicyDao);

  // ── Memory use cases (shared by MCP registry + RPC catalog) ──
  final resolveDomainUseCase = ResolveOrCreateDomainUseCase(
    domainRepository: memoryDomainRepository,
    grantRepository: memoryAccessGrantRepository,
  );
  // Shared deterministic writer (propose_fact + harvest + consolidation), wired
  // with conflict detection + episodic linking + memory-stream events.
  final recordMemoryFactUseCase = RecordMemoryFactUseCase(
    factRepository: memoryFactRepository,
    resolveDomainUseCase: resolveDomainUseCase,
    conflictRepository: memoryConflictRepository,
    edgeRepository: episodicEdgeRepository,
    eventBus: eventBus,
  );
  // Passive heuristic extraction → durable facts (no host LLM port today).
  final extractMemoryUseCase = ExtractMemoryUseCase(
    extractor: const MemoryExtractor(),
    recordFact: recordMemoryFactUseCase,
  );
  // Two-tier working→episodic consolidation `sleep()` job.
  final memoryConsolidationService = MemoryConsolidationService(
    workingMemory: workingMemoryItemRepository,
    recordFact: recordMemoryFactUseCase,
    eventBus: eventBus,
  );
  // Cross-agent SHMR belief harmonization.
  final harmonizeMemoryUseCase = HarmonizeMemoryUseCase(
    factRepository: memoryFactRepository,
    beliefRepository: memoryBeliefRepository,
    conflictRepository: memoryConflictRepository,
    eventBus: eventBus,
  );
  final promoteFactsUseCase = PromoteFactsToPolicyUseCase(
    factRepository: memoryFactRepository,
    policyRepository: memoryPolicyRepository,
    grantRepository: memoryAccessGrantRepository,
    accessPolicy: const MemoryAccessPolicy(),
  );
  final supersedeFactUseCase = SupersedeFactUseCase(
    factRepository: memoryFactRepository,
  );
  final supersedePolicyUseCase = SupersedePolicyUseCase(
    policyRepository: memoryPolicyRepository,
  );
  final reviewChannelRepository = DaoReviewChannelRepository(
    db.reviewChannelDao,
  );
  final isolatedRepoRepository = DaoIsolatedRepoRepository(db.isolatedRepoDao);
  final voiceProfileRepository = DaoVoiceProfileRepository(db.voiceProfileDao);
  final meetingRepository = DaoMeetingRepository(db.meetingDao);
  final ticketLinkRepository = DaoTicketLinkRepository(db.ticketLinkDao);
  final pipelineRunRepository = PipelineRunRepositoryImpl(db.pipelineDao);
  final pipelineTemplateRepository =
      PipelineTemplateRepositoryImpl(db.pipelineTemplateDao);
  final pipelineTriggerRepository = PipelineTriggerRepositoryImpl(
    db.pipelineTriggerDao,
  );
  final teamRepository = TeamRepositoryImpl(db.teamDao);
  final orchestrationRepository = DaoOrchestrationRepository(db.orchestrationDao);
  final workspaceRepository = DaoWorkspaceRepository(db.workspaceDao);
  // Analytics cluster (workspace-scoped reads via an Agents JOIN). The
  // achievement/streak impls also take an [AgentDao] used to validate
  // agent-in-workspace on writes; only the READ surface is exposed over RPC, so
  // the write path (driven server-side by the XpEngine) is never reached here.
  final analyticsRepository = AnalyticsRepositoryImpl(
    db.analyticsDao,
    db.agentDao,
    db.pullRequestDao,
    db.workspaceDao,
  );
  final achievementRepository = AchievementRepositoryImpl(
    db.achievementDao,
    db.agentDao,
    eventBus: eventBus,
  );
  final streakRepository = StreakRepositoryImpl(db.streakDao, db.agentDao);
  // Calendar (workspace-scoped reads via the workspace clause). Only the READ
  // surface is exposed over RPC; the write path (account connect/disconnect,
  // RSVP, the sync reconciler, the alert sweep, meeting linking) depends on the
  // host-resident OAuth tokens + Google API client, so it is never reached here.
  final calendarRepository = DaoCalendarRepository(db.calendarDao);
  // The server owns the Google Calendar connection: the device-code GUI connect
  // (`calendar.*Connect` ops) + the periodic per-workspace sync, over one shared
  // credential store under the data dir. Clients just READ the synced events.
  final serverCalendar = buildServerCalendar(
    calendarRepository: calendarRepository,
    workspaceRepository: workspaceRepository,
    eventBus: eventBus,
    dataDir: config.dataDir,
  );

  // GitHub client authenticated from the server's `gh` CLI (the host owns auth;
  // thin clients hold no token). `gh auth token` is read once at boot via the
  // PATH-robust resolver in [ProcessGitHubCliService] (a GUI-spawned subprocess
  // inherits a minimal PATH; the resolver probes Homebrew/Nix/etc.). When no
  // token is available the client stays token-less and the PR surface degrades
  // to "connect GitHub on the server" rather than failing.
  final ghStatus = await ProcessGitHubCliService().probe();
  final ghToken = ghStatus.token;
  if (ghToken.isEmpty) {
    CcHostLog.warning(
      'cc_server: no GitHub token from `gh auth token` on PATH — the PR list '
      'and authenticated PR review will be empty until the server can run gh.',
    );
  }
  final githubDio = createDio();
  // Cap the SERVER's GitHub calls well below the RPC client's 30s timeout
  // (RemoteRpcClient._timeout): a dashboard-startup op (github.currentUser /
  // pr.listOpenForWorkspace / searchReviewRequested) that hits a slow or
  // unavailable GitHub must fail server-side and let the handler degrade
  // (empty/null) so the thin client gets a prompt response — rather than both
  // sides racing the same 30s deadline and the client throwing "RPC repo/call
  // timed out". Only this GitHub client is shortened; createDio's 30s default
  // stays for everything else.
  githubDio.options
    ..connectTimeout = const Duration(seconds: 12)
    ..receiveTimeout = const Duration(seconds: 12)
    ..sendTimeout = const Duration(seconds: 12);
  if (ghToken.isNotEmpty) {
    githubDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Bearer $ghToken';
          handler.next(options);
        },
      ),
    );
  }
  final serverGitHubClient = GitHubApiClient(githubDio);

  // The composer's GIF picker runs on the host's Klipy app key (the thin client
  // holds none). Null when unconfigured → the `gif.*` ops return empty.
  final klipy = config.klipyAppKey.isEmpty
      ? null
      : KlipyApiClient(appKey: config.klipyAppKey);

  // PR lifecycle (workspace-scoped at the `PullRequests` table). The thin client
  // reads + writes its draft → publish → created records over RPC. Publishing
  // (`createOnGitHub`) drives the GitHub client; on this headless server that is
  // the token-less client above, so a publish surfaces the GitHub failure (a web
  // client connected to a desktop GUI host gets the host's authenticated token —
  // matching the PR-review server-token follow-up).
  final prLifecycleRepository = DaoPrLifecycleRepository(
    db.pullRequestDao,
    serverGitHubClient,
    eventBus: eventBus,
  );

  // Activity log (workspace-scoped audit trail). The headless server owns the
  // Drift `activity_log` DAO, so it serves the `activity.watchForEntity`
  // subscription (the client's entity-timeline view) over this read-only reader.
  final activityLogReader = DaoActivityLogReader(db.activityLogDao);

  // The MCP agent-tool surface the server exposes via tools/list + tools/call.
  // Built before the catalog so the SHARED dispatcher backs both the RPC server
  // and the MCP HTTP server (one tool registry, two transports), and the
  // control surface the `mcp.*` catalog ops drive can be wired in.
  final mcpRegistry = buildServerMcpRegistry(
    db: db,
    newsfeedRepository: newsfeedRepository,
    ticketRepository: ticketRepository,
    messagingRepository: messagingRepository,
    // Pipeline structured-output contract (submit_output writes outputJson).
    agentRunLogRepository: agentRunLogRepository,
    schemaValidator: const JsonSchemaValidator(),
    // Memory cluster.
    memoryFactRepository: memoryFactRepository,
    memoryPolicyRepository: memoryPolicyRepository,
    memoryDomainRepository: memoryDomainRepository,
    memoryAccessGrantRepository: memoryAccessGrantRepository,
    agentWorkingMemoryRepository: agentWorkingMemoryRepository,
    resolveDomainUseCase: resolveDomainUseCase,
    promoteFactsUseCase: promoteFactsUseCase,
    supersedeFactUseCase: supersedeFactUseCase,
    supersedePolicyUseCase: supersedePolicyUseCase,
    // PRD 04 memory intelligence (typed/decay/conflict/consolidation/SHMR).
    recordFactUseCase: recordMemoryFactUseCase,
    memoryConflictRepository: memoryConflictRepository,
    workingMemoryItemRepository: workingMemoryItemRepository,
    extractMemoryUseCase: extractMemoryUseCase,
    consolidationService: memoryConsolidationService,
    harmonizeMemoryUseCase: harmonizeMemoryUseCase,
    // On-device embedder for semantic memory + code search (degrades to keyword
    // until the embedding model is installed; guarded by `isReady`).
    embeddingService: embeddingService,
    // Code graph (nullable — nil when the code graph DAO is unavailable).
    codeGraphRepository: DaoCodeGraphRepository(
      db.codeGraphDao,
      embeddingService: embeddingService,
    ),
  );
  // MCP CLIENT (PRD 01): connect to EXTERNAL MCP servers and bridge their
  // tools into the registry's dynamic layer. Headless, so OAuth tokens persist
  // to a file (no keychain) and there is no interactive browser launcher —
  // stdio, static-header HTTP/SSE, and already-authorized OAuth servers all
  // work; first-time interactive OAuth is desktop-driven. Discovery + connect
  // runs fire-and-forget after boot (see below).
  final mcpClientService = McpClientService(
    registry: mcpRegistry,
    tokenStore: FileOAuthTokenStore('${config.dataDir}/mcp_oauth_tokens.json'),
    log: (level, message, {Object? error}) =>
        CcHostLog.info('mcp-client[$level]: $message'),
  );
  final mcpDispatcher = McpToolDispatcher(
    registry: mcpRegistry,
    // Re-expose external servers' resources/prompts through CC's MCP server.
    resourceProvider: mcpClientService.resourceProvider,
    promptProvider: mcpClientService.promptProvider,
  );

  // The headless server runs its OWN MCP HTTP server (real desktop/web parity):
  // the `mcp.*` ops the web settings section calls resolve to this control,
  // which owns the McpHttpServer over the shared dispatcher and persists its
  // config under the data dir.
  final mcpControl = ServerMcpControl(
    dispatcher: mcpDispatcher,
    dataDir: config.dataDir,
  );

  // PRD 01: the host-side control for the EXTERNAL MCP client subsystem — backs
  // the `mcp.client.*` ops so a connected web/thin client can list the
  // discovered servers + steer the standing approval posture (which re-points
  // this dispatcher's tier gate). Persisted approval posture is loaded at boot
  // (below). This is a HEADLESS host: it has no browser launcher, so
  // `mcp.client.authorize` rejects — interactive OAuth is desktop-driven.
  final mcpClientControl = ServerMcpClientControl(
    service: mcpClientService,
    dispatcher: mcpDispatcher,
    dataDir: config.dataDir,
  );

  // The headless server owns a real filesystem, so it hosts the workspace
  // on-disk layout (agents / skills / conversation dirs) rooted at its data dir
  // — the same CcPaths layout the desktop uses (`paths` is constructed above
  // with the embedding model manager). A connected web/thin client resolves
  // these server-side paths + writes through them over the `fs.*` ops.
  final workspaceFilesystem = WorkspaceFilesystemService(paths);

  // Authenticated PR-review host: wired only when the server holds a gh token.
  // Lights up the `pr_review.*` detail/diff/comment ops over RPC (a thin client
  // reads them; previously these surfaced an empty repository). The local-git
  // diff source backs the >3000-file fallback and runs `git` on the server's
  // own checkout (rift CoW is optional → null falls back to plain git).
  final serverVcsFactory = ghToken.isEmpty
      ? null
      : GitHubVcsProviderFactory(
          cacheDao: db.cacheDao,
          draftDao: db.reviewDao,
          gitHubClient: serverGitHubClient,
          localGitSource: LocalGitPrDiffSource(
            git: const ProcessGitCommandAdapter(),
            filesystem: workspaceFilesystem,
            githubToken: ghToken,
          ),
          eventBus: eventBus,
        );

  // ── Agent executor (pure-Dart, on libccpty) ──
  // The headless server runs agents itself now that the dispatch engine is
  // Flutter-free: ClaudeRelay drives `claude` through the vendored PTY
  // (libccpty), and AgentStreamProcessor persists streamed segments onto the
  // message rows connected clients already watch (`messaging.watchMessages`) —
  // so a web/thin client's "send + dispatch" reply streams in with no extra
  // infra. Credentials come from the server's environment (no OS keychain).
  // Claude runs via the relay regardless of sandbox backend, so the headless
  // server uses the no-isolation adapter (the `pi` CLI path would be
  // unsandboxed here; claude-relay never touches it).
  final sandboxManager = SandboxManager();
  // Sandbox DETECTION reports this host's real OS-native capabilities (which
  // backends are available + the recommended one) so a connected web/thin
  // client's Settings → Sandboxing page reflects the SERVER host, not the
  // browser. This is independent of the no-isolation EXECUTION path above —
  // detection only describes what the host could do.
  final sandboxDetector = SandboxBackendDetector([
    NoSandboxAdapter(),
    NativeSandboxAdapter(manager: sandboxManager),
  ]);
  final serverCredentials = EnvCredentialsRepository();
  final credentialBroker = EnvCredentialBroker(serverCredentials);
  final agentDispatch = SandboxedAgentDispatchAdapter(
    sandbox: NoSandboxAdapter(),
    credentialBroker: credentialBroker,
    agentRepository: agentRepository,
    runLogRepository: agentRunLogRepository,
    eventBus: eventBus,
    // Point the spawned `claude` at THIS server's own loopback MCP HTTP
    // endpoint so server-run agents get the `mcp__*` tool surface — crucially
    // `submit_output`, which writes a pipeline run's structured output so the
    // step resume listener can harvest it and advance. Without this, an
    // agent-dispatching pipeline step ends but fails harvest (no payload). The
    // resolver is lazy (called per dispatch): it force-starts the loopback MCP
    // server (idempotent, independent of the user-facing enable toggle) and
    // writes a fresh client config so a port/token change is picked up.
    mcpConfigPathResolver: () async {
      await mcpControl.ensureRunningForDispatch();
      return mcpControl.writeAgentMcpConfig(
        File('${config.dataDir}/agent_mcp.json'),
      );
    },
  );
  // Dispatch-time prompt context (memory preamble + conversation history) and
  // the conversation-mode resolver — mirrors the desktop composition root
  // (lib/di/server_providers.dart) so server-run agents get the same context.
  // The on-device [embeddingService] backs semantic ranking of both the memory
  // shortlist and conversation history once the model is installed; it degrades
  // to keyword/verbatim (guarded by `isReady`) until then.
  final conversationModeResolver = DbConversationModeResolver(db.messagingDao);
  final memoryContextUseCase = BuildMemoryContextUseCase(
    policyRepository: memoryPolicyRepository,
    workingMemoryRepository: agentWorkingMemoryRepository,
    factRepository: memoryFactRepository,
  );
  final conversationContextUseCase = BuildConversationContextUseCase(
    messagingRepository: messagingRepository,
    embeddingPort: embeddingService,
  );
  final agentDispatchService = AgentDispatchService(
    agentDispatch: agentDispatch,
    dispatchUseCase: DispatchAgentUseCase(
      agentRepo: agentRepository,
      memoryContextUseCase: memoryContextUseCase,
      conversationContextUseCase: conversationContextUseCase,
      modeResolver: conversationModeResolver,
    ),
    runLogRepo: agentRunLogRepository,
    // Process-global agent registry — tracks live subagents on the headless
    // server so the work-aware roster is populated there too.
    registry: AgentRegistryImpl.global(),
  );
  final streamRegistry = ActiveStreamRegistry();
  // Anchored compaction + tool-output pruning maintenance after each turn.
  // Defaults to the deterministic structural summarizer (LLM-free, lossless of
  // decisions); swap in an LLM/vision-backed [ConversationSummarizerPort] to
  // upgrade to true anchored summaries.
  final conversationCompactionService = ConversationCompactionService(
    repo: messagingRepository,
    summarizer: const StructuralConversationSummarizer(),
    embeddingPort: embeddingService,
  );
  final agentStreamProcessor = AgentStreamProcessor(
    agentDispatchService: agentDispatchService,
    repo: messagingRepository,
    streamRegistry: streamRegistry,
    eventBus: eventBus,
    compactionService: conversationCompactionService,
    // Per-turn git snapshots so a conversation revert can roll back the
    // worktree filesystem, not just the transcript.
    snapshotPort: const ProcessGitSnapshotAdapter(),
  );
  final messagingService = MessagingService(
    messagingRepository,
    agentRepo: agentRepository,
    agentDispatchService: agentDispatchService,
    streamRegistry: streamRegistry,
    streamProcessor: agentStreamProcessor,
    eventBus: eventBus,
  );
  // Interactive terminal over RPC: a connected client runs a REAL shell on this
  // host (libccpty). Defaults to the host shell (no OS sandbox) on the headless
  // server; ownership is validated per op against the bound workspace.
  final terminalSessions = TerminalSessionService(
    manager: sandboxManager,
    filesystem: workspaceFilesystem,
  );

  // Persisted ASR model selection (HOST-GLOBAL; a model is a device-local
  // asset, not workspace data). The web/thin client picks the active model via
  // `models.selectVoice`; we persist the choice to `<dataDir>/voice_model.json`
  // so it survives a restart AND so the meeting-recording stack below resolves
  // the SELECTED model first.
  final voiceSelectionFile = File('${config.dataDir}/voice_model.json');
  String? persistedVoiceModelId;
  if (voiceSelectionFile.existsSync()) {
    try {
      final decoded = jsonDecode(await voiceSelectionFile.readAsString());
      if (decoded is Map && decoded['selected_id'] is String) {
        persistedVoiceModelId = decoded['selected_id'] as String;
      }
    } catch (_) {
      // Ignore a corrupt selection file — fall back to the default model.
    }
  }

  // ── Meeting transcription + diarization (server-side speech stack) ──
  // The headless server runs the SAME Flutter-free Whisper/sherpa stack the
  // desktop uses (cc_natives is pure Dart + FFI on a worker isolate). The
  // diarization service + model manager are always constructed (diarization
  // degrades to a no-op when its models aren't on disk), so the `meeting_summary`
  // pipeline's `meeting.*` bodies can run. Recording over RPC additionally needs
  // an ASR model: resolve the user's SELECTED model first, then fall back to
  // whichever one is installed under the data dir.
  final diarizationModelManager = DiarizationModelManager(paths: paths);
  const diarizationService = MeetingDiarizationService();
  MeetingRecordingService? meetingRecording;
  VoiceModelPaths? voicePaths;
  final selectedVoiceModel = VoiceModelInfo.byId(persistedVoiceModelId);
  for (final candidate in [
    selectedVoiceModel,
    ...VoiceModelInfo.all.where((m) => m.id != selectedVoiceModel.id),
  ]) {
    voicePaths =
        await VoiceModelManager(paths: paths, model: candidate).resolve();
    if (voicePaths != null) {
      break;
    }
  }
  // Where THIS pure-Dart process loads the sherpa/onnx dylibs from (no Flutter
  // plugin bundles them here): an explicit `CC_NATIVE_LIB_DIR` override (the
  // desktop hands it its Frameworks dir when it spawns us), else the data dir
  // (a remote/headless deploy can drop the dylibs beside its models), else this
  // binary's own bundle layout (a self-contained server shipped with its libs).
  // Null → the recognizer can't load and transcripts will be empty. We set it as
  // the preferred dir for this (main) isolate's sherpa users — diarization + VAD
  // — and forward it explicitly to the transcriber's decode worker isolate.
  final sherpaLibDir = resolveSherpaLibraryDir(appSupportRoot: config.dataDir);
  setPreferredSherpaLibDir(sherpaLibDir);
  // Pre-load the EMBEDDER's onnxruntime by full path now, so the lazy
  // bare-leaf-name open inside `onnxruntime_v2` (which this hardened dart-built
  // binary would otherwise reject) dedupes to the already-loaded image when the
  // first agent dispatch / search embeds text. Without it, semantic memory +
  // code + conversation search silently degrade to keyword even with the model
  // installed. Best-effort (logs nothing on miss — embeddings just degrade).
  final onnxLoaded = ensureOnnxRuntimeLoaded(appSupportRoot: config.dataDir);
  if (!onnxLoaded) {
    CcHostLog.warning(
      'cc_server: onnxruntime dylib not found (looked in '
      '$nativeLibDirEnvVar / ${config.dataDir} / bundle) — semantic embeddings '
      'degrade to keyword until libonnxruntime is bundled beside the server.',
    );
  }
  // ── Agent PTY native (libccpty) ──
  // Backs the agent's claude-relay + sandboxed terminal sessions (the
  // `terminal.spawn` RPC body). Like rift/fff/tree-sitter, libccpty is a loose
  // runtime dylib — no Flutter ffiPlugin bundles it into this pure-Dart binary —
  // so point the PTY loader at the SAME data dir the other natives resolve from.
  // `Pty`'s default resolver only checks `$CC_PTY_DYLIB` + the binary's own
  // `@executable_path/../Frameworks` (the signed release server bundle), so on a
  // dev / headless deploy — where libccpty is dropped beside control_center.db
  // rather than embedded in the bundle — `terminal.spawn` fails with
  // `PtyUnavailable` even though the dylib is present. Adding the data dir as the
  // app-support root closes that gap, mirroring fff/rift wiring.
  Pty.libraryResolver = () => tryOpenFirst(
        nativeLibraryCandidates(
          ptyLibraryBaseName,
          appSupportRoot: config.dataDir,
          envVar: ptyLibraryEnvVar,
        ),
      );

  SherpaOnnxTranscriber? meetingTranscriber;
  if (voicePaths != null) {
    // The web meeting recorder streams mic + system PCM16 to this service over
    // `meeting.ingestAudio`; it transcribes + appends segments the client
    // watches, and on stop fires the summary pipeline. Lazy worker-isolate init.
    meetingTranscriber =
        SherpaOnnxTranscriber(paths: voicePaths, libDir: sherpaLibDir);
    meetingRecording = MeetingRecordingService(
      repository: meetingRepository,
      transcriber: meetingTranscriber,
      eventBus: eventBus,
      paths: paths,
    );
  } else {
    CcHostLog.warning(
      'cc_server: no speech model installed under ${config.dataDir} — '
      'meeting recording over RPC is unavailable until a voice model is '
      'installed (the `meeting.startRecording`/`ingestAudio`/`stopRecording` '
      'ops stay absent).',
    );
  }

  // ── On-device model download (server-hosted) ──
  // The headless server HOSTS the three on-device models, so a connected
  // web/thin client triggers a download IN-APP and the SERVER performs the fetch
  // + unarchive under its data dir (`<dataDir>/models/`). Each control owns the
  // lifecycle state and streams progress over `models.watch*`; install is
  // non-blocking (the `models.install*` op returns a `downloading` snapshot
  // immediately rather than holding the RPC call open for the whole transfer).
  // The voice control is SELECTABLE: the client picks the active ASR build from
  // `VoiceModelInfo.all` over `models.selectVoice` (the other two models are
  // fixed). The choice is persisted so it survives a restart, and the meeting-
  // recording stack above resolves the SELECTED model AT BOOT, so a voice model
  // installed via the client lights up recording on the next server restart.
  final voiceModelControl = SelectableVoiceModelControl(
    paths: paths,
    initialId: persistedVoiceModelId,
    persistSelection: (id) {
      try {
        voiceSelectionFile.writeAsStringSync(jsonEncode({'selected_id': id}));
      } catch (e) {
        CcHostLog.warning('voice model: failed to persist selection: $e');
      }
    },
    onLog: (m) => CcHostLog.warning('voice model: $m'),
  );
  // Keep the live [EmbeddingService] paths in lock-step with the on-disk model
  // lifecycle: probe/install resolve the paths and push them into the service
  // (so semantic search lights up the instant a download finishes, no restart),
  // and uninstall clears them (back to keyword/FTS).
  final embeddingModelControl = ManagedModelControl(
    probeInstalled: () async {
      final resolved = await embeddingModelManager.resolve();
      embeddingService.updatePaths(resolved);
      return resolved != null;
    },
    runInstall: ({onProgress, cancelToken}) async {
      final resolved = await embeddingModelManager.install(
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      embeddingService.updatePaths(resolved);
    },
    runUninstall: () async {
      await embeddingModelManager.uninstall();
      embeddingService.updatePaths(null);
    },
    onLog: (m) => CcHostLog.warning('embedding model: $m'),
  );
  final diarizationModelControl = ManagedModelControl(
    probeInstalled: () async =>
        (await diarizationModelManager.resolve()) != null,
    runInstall: diarizationModelManager.install,
    runUninstall: diarizationModelManager.uninstall,
    onLog: (m) => CcHostLog.warning('diarization model: $m'),
  );

  // ── Code graph indexer (the `code.index` body of the `index_code` pipeline,
  // fired by `RepoAdded`) ──
  // Built from the workspace-scoped code-graph repo + the tree-sitter grammar
  // manager, mirroring the desktop `codeIndexerProvider`. Symbols are embedded
  // on index when the embedding model is installed (semantic code search via
  // `search_code`), and fall back to FTS + graph otherwise. The `.scm` queries
  // are embedded in cc_natives
  // (pure Dart), so no Flutter asset bundle is needed. The indexer skips any
  // language whose grammar natives aren't installed and returns a skipped
  // result, so the body completes cleanly rather than hard-failing.
  final grammarManager = GrammarManager(
    dio: createDio(),
    grammarsDir: paths.grammarsRoot,
    onLog: (tag, message, [error, stackTrace]) =>
        CcHostLog.warning('grammar[$tag]: $message'),
  );
  final codeIndexer = DefaultCodeIndexer(
    repository: DaoCodeGraphRepository(
      db.codeGraphDao,
      embeddingService: embeddingService,
    ),
    grammarManager: grammarManager,
  );

  // ── Pipeline executor (pure-Dart) ──
  // The headless server owns the pipeline engine + its step bodies (the same
  // ones the desktop registers), driving the relocated dispatch stack. The
  // common/core + PR-review + meeting + code-index bodies are wired; the
  // remaining heavier body (cleanupRepos) needs the rift stack and is a
  // follow-up (see buildServerPipelineExecutor).
  final pipeline = buildServerPipelineExecutor(
    templateRepository: pipelineTemplateRepository,
    runRepository: pipelineRunRepository,
    agentRunLogRepository: agentRunLogRepository,
    agentRepository: agentRepository,
    teamRepository: teamRepository,
    credentials: serverCredentials,
    messagingPort: messagingService,
    messagingRepository: messagingRepository,
    agentDispatchPort: agentDispatch,
    githubPrClient: serverGitHubClient.pr,
    orchestrationRepository: orchestrationRepository,
    ticketWorkflow: ticketWorkflow,
    codeIndexer: codeIndexer,
    eventBus: eventBus,
    schemaValidator: const JsonSchemaValidator(),
    runDirPath: (runId) async => (await paths.pipelineRunDir(runId)).path,
    // Meeting summary bodies (diarize → identifySpeakers → save/items/decisions).
    meetingRepository: meetingRepository,
    voiceProfileRepository: voiceProfileRepository,
    diarizationModelManager: diarizationModelManager,
    diarizationService: diarizationService,
  );

  // ── Orchestration approve/cancel ──
  // Approving hires agents, builds teams and starts the generated pipeline on
  // the engine above; cancelling tears it down. Both use-cases are pure-Dart
  // (ApproveOrchestrationUseCase was relocated to cc_infra).
  final hireAgent = HireAgentUseCase(
    repository: agentRepository,
    filesystem: workspaceFilesystem,
  );
  final projectService = ProjectService(repository: projectRepository);
  final approveOrchestration = ApproveOrchestrationUseCase(
    orchestrations: orchestrationRepository,
    hireAgent: hireAgent,
    teams: teamRepository,
    projects: projectService,
    ticketWorkflow: ticketWorkflow,
    templates: pipelineTemplateRepository,
    engine: pipeline.engine,
    eventBus: eventBus,
  );
  final cancelOrchestration = CancelOrchestrationUseCase(
    orchestrations: orchestrationRepository,
    engine: pipeline.engine,
    ticketWorkflow: ticketWorkflow,
    eventBus: eventBus,
  );

  // PR "open in editor" worktree materialization, exposed over
  // `ide.ensureWorktree`: a GUI-attached client (the native desktop app) asks
  // the host to check out the PR branch into a worktree and then launches the
  // returned path in a LOCAL editor itself (the headless host can't pop a GUI
  // editor, but it owns the repo checkout). rift CoW is disabled here (empty
  // dylib paths) so it always uses the plain `git worktree` fallback — no native
  // FFI in the headless server; PR worktrees don't need copy-on-write.
  final prWorktree = PrWorktreeService(
    filesystem: workspaceFilesystem,
    isolation: RiftRepoIsolationAdapter(
      rift: RiftClient(
        dylibPaths: const <String>[],
        databasePath: '${config.dataDir}/pr_worktrees_rift.sqlite',
      ),
      git: const ProcessGitCommandAdapter(),
    ),
    registry: isolatedRepoRepository,
    githubToken: () async => ghToken.isEmpty ? null : ghToken,
  );

  final catalog = buildRemoteRpcCatalog(
    ticketRepository: ticketRepository,
    projectRepository: projectRepository,
    ticketWorkflow: ticketWorkflow,
    messagingRepository: messagingRepository,
    workspaceRepository: workspaceRepository,
    newsfeedRepository: newsfeedRepository,
    agentRepository: agentRepository,
    agentRunLogRepository: agentRunLogRepository,
    repoRepository: repoRepository,
    channelReadRepository: channelReadRepository,
    memoryDomainRepository: memoryDomainRepository,
    memoryAccessGrantRepository: memoryAccessGrantRepository,
    agentWorkingMemoryRepository: agentWorkingMemoryRepository,
    memoryFactRepository: memoryFactRepository,
    memoryPolicyRepository: memoryPolicyRepository,
    reviewChannelRepository: reviewChannelRepository,
    isolatedRepoRepository: isolatedRepoRepository,
    voiceProfileRepository: voiceProfileRepository,
    // PR "open in editor" worktree materialization (`ide.ensureWorktree`); no
    // editorLauncher is wired (the headless host can't launch a GUI editor — the
    // client launches the returned path locally), so only the worktree-path op
    // lights up, not `ide.openPrInEditor`.
    prWorktreePort: prWorktree,
    meetingRepository: meetingRepository,
    // Live meeting recording over RPC (null when no ASR model is installed →
    // the recording ops stay absent and the web recorder reports unavailable).
    meetingRecording: meetingRecording,
    // On-device model download, handled by the SERVER: a connected web/thin
    // client drives status/install/cancel/uninstall over `models.*` and watches
    // live progress over `models.watch*`; the server performs the download +
    // unarchive under its data dir. (The desktop wires its in-process controllers
    // here instead — same `ModelControl` surface, different backing.)
    embeddingModelControl: embeddingModelControl,
    diarizationModelControl: diarizationModelControl,
    voiceModelControl: voiceModelControl,
    ticketLinkRepository: ticketLinkRepository,
    pipelineRunRepository: pipelineRunRepository,
    pipelineTemplateRepository: pipelineTemplateRepository,
    pipelineTriggerRepository: pipelineTriggerRepository,
    teamRepository: teamRepository,
    orchestrationRepository: orchestrationRepository,
    // Pairing management: a connected first-party (web) client can mint a
    // pairing for a phone that then dials THIS headless server directly. The
    // advertised URL is the server's configured public URL.
    pairedDeviceDao: db.pairedDeviceDao,
    pairedDeviceSecretsPort: secrets,
    pairingServerUrl: config.publicUrl,
    // Relay pairing: advertise the broker so a phone that can't reach this
    // server directly rendezvous there. The RemoteRelayHost (built below)
    // watches the device table, so minting an active phone makes the server
    // join the room — no callback needed here.
    relaySignalingUrl: config.signalingUrl,
    analyticsRepository: analyticsRepository,
    achievementRepository: achievementRepository,
    streakRepository: streakRepository,
    calendarRepository: calendarRepository,
    calendarConnect: serverCalendar.connect,
    calendarRsvp: serverCalendar.rsvp.respond,
    calendarRefresh: serverCalendar.sync.syncWorkspace,
    calendarEnsureRange: serverCalendar.sync.ensureRangeLoaded,
    // PR lifecycle (workspace-scoped reads + writes; publish drives the
    // token-less server GitHub client here — see the note at its construction).
    prLifecycleRepository: prLifecycleRepository,
    // Activity log (workspace-scoped audit trail): the headless server owns the
    // Drift `activity_log` DAO, so it serves `activity.watchForEntity`.
    activityLogReader: activityLogReader,
    // Server-host capabilities: the headless server runs `git` on its own
    // filesystem to inspect + register repos via `repos.addFromPath`. The event
    // bus carries `RepoAdded` (a server-side indexing pipeline can pick it up).
    gitRepoInspector: const GitRepoInspector(),
    // Folder browser for the web add-repo flow: lets a connected client navigate
    // the server's filesystem (scoped to the configured `--repo-roots`, default
    // the OS user's home) and pick a git checkout to register.
    directoryBrowser: FilesystemDirectoryBrowser(
      allowedRoots: config.repoRoots,
    ),
    // Server-host adapter / model / gh-CLI probing: the headless server links
    // cc_infra, so it probes the agent-runner CLIs installed on ITS machine for
    // a connected client's Settings → Adapters + auth status. `github_cli.probe`
    // redacts the resolved token (never shipped to a client).
    adapterDetection: const AdapterDetectionRepository(
      AdapterDetectionService(),
    ),
    acpModels: AcpModelRepositoryImpl(AcpModelsService()),
    githubCli: ProcessGitHubCliService(),
    // Sandbox detection: report THIS host's OS-native sandbox capabilities so a
    // connected web/thin client's Settings → Sandboxing reflects the server.
    sandboxDetector: sandboxDetector,
    // Process detection: the server scans ITS OS process table for agent
    // processes (the dashboard's cross-workspace "active processes" matrix) and
    // can stop one by pid. Both ops are fullClient-only + cross-workspace.
    processDetection: ProcessDetectionService(
      runLogRepo: agentRunLogRepository,
      agentRepo: agentRepository,
      workspaceRepo: workspaceRepository,
    ),
    eventBus: eventBus,
    // PR review over RPC: when the server has a `gh` token (see [serverVcsFactory]
    // above) the authenticated detail/diff/comment surface is LIVE — a thin
    // client reads `pr_review.watch*`/mutations against this gh-backed host.
    // Token-less, it stays null and those ops surface an empty repository.
    vcsProviderFactory: serverVcsFactory,
    // The PR-list screen's data: fetched server-side on the gh client across the
    // bound workspace's linked repos. Null (→ `authenticated:false`) when the
    // server holds no token, so the client shows "connect GitHub on the server".
    fetchOpenPrList: ghToken.isEmpty
        ? null
        : (repos) async {
            final specs = [
              for (final r in repos) (owner: r.githubOwner, name: r.githubRepoName),
            ];
            final batch = await serverGitHubClient.graphql
                .fetchOpenPullRequestsBatch(specs);
            var checks = <int, Map<int, String?>>{};
            try {
              checks = await serverGitHubClient.graphql
                  .fetchOpenPullRequestsChecks(specs);
            } on Object {
              // Checks are best-effort; rows keep checksStatus.none on failure.
            }
            final groups =
                <({Repo repo, List<PullRequest> prs, bool hasMore})>[];
            for (var i = 0; i < repos.length; i++) {
              final repo = repos[i];
              final repoResult = batch.byIndex[i];
              if (repoResult == null) {
                continue;
              }
              final repoChecks = checks[i];
              final prs = <PullRequest>[];
              for (final node in repoResult.nodes) {
                final number = (node['number'] as num?)?.toInt() ?? 0;
                final title = node['title'] as String? ?? '';
                if (number <= 0 || title.isEmpty) {
                  continue;
                }
                var pr = pullRequestFromGraphQlNode(
                  node,
                  repoFullName: repo.fullName,
                );
                if (repoChecks != null && repoChecks.containsKey(pr.number)) {
                  pr = pr.copyWith(
                    checksStatus: prChecksStatusFromRollup(repoChecks[pr.number]),
                  );
                }
                prs.add(pr);
              }
              if (prs.isEmpty) {
                continue;
              }
              groups.add((repo: repo, prs: prs, hasMore: repoResult.hasMore));
            }
            return groups;
          },
    // The thin client's `login`/avatar resolve from the host's gh user.
    fetchCurrentGitHubUser: ghToken.isEmpty
        ? null
        : () async =>
              (await serverGitHubClient.content.getAuthenticatedUser())?.toJson(),
    // The dashboard's "review-requested:@me" search, run as the server user.
    fetchReviewRequested: ghToken.isEmpty || ghStatus.username.isEmpty
        ? null
        : (repos) async {
            final nodes = await serverGitHubClient.graphql
                .searchReviewRequestedPullRequests(
                  reviewerLogin: ghStatus.username,
                  repos: [
                    for (final r in repos)
                      (owner: r.githubOwner, name: r.githubRepoName),
                  ],
                );
            final byFullName = {
              for (final r in repos) r.fullName.toLowerCase(): r,
            };
            final out = <({Repo repo, PullRequest pr})>[];
            for (final node in nodes) {
              final mapped = priorityReviewFromSearchNode(node);
              if (mapped == null) {
                continue;
              }
              final repo = byFullName[mapped.repoFullName.toLowerCase()];
              if (repo == null) {
                continue;
              }
              out.add((repo: repo, pr: mapped.pr));
            }
            return out;
          },
    // The PR-list "reviewed by me" key set, resolved as the server user.
    fetchReviewedBy: ghToken.isEmpty || ghStatus.username.isEmpty
        ? null
        : (repos) async {
            final pairs = await serverGitHubClient.graphql
                .searchReviewedByPullRequests(
                  reviewerLogin: ghStatus.username,
                  repos: [
                    for (final r in repos)
                      (owner: r.githubOwner, name: r.githubRepoName),
                  ],
                );
            return {for (final p in pairs) '${p.repoFullName}#${p.number}'};
          },
    // The PR-queue free-text search, parsed + executed server-side.
    fetchPrSearch: ghToken.isEmpty
        ? null
        : (repos, query) async {
            final groups = await GitHubPrSearchAdapter(serverGitHubClient).search(
              query: PrSearchQuery.parse(query),
              repos: repos,
            );
            return [for (final g in groups) (repo: g.repo, prs: g.prs)];
          },
    // Per-author PR counts for the profile rail.
    fetchPrCountsByAuthor: ghToken.isEmpty
        ? null
        : (repos, login) => serverGitHubClient.graphql.prCountsByAuthor(
            login: login,
            repos: [
              for (final r in repos)
                (owner: r.githubOwner, name: r.githubRepoName),
            ],
          ),
    // Per-author merged/closed PR history (first page per repo). Fails soft per
    // repo so one inaccessible repo never sinks the rest.
    fetchClosedByAuthor: ghToken.isEmpty
        ? null
        : (repos, login) async {
            final groups =
                <({Repo repo, List<PullRequest> prs, bool hasMore})>[];
            for (final repo in repos) {
              try {
                final result = await serverGitHubClient.pr
                    .searchClosedPullRequestsByAuthor(
                      repo.githubOwner,
                      repo.githubRepoName,
                      login,
                    );
                if (result.items.isEmpty) {
                  continue;
                }
                final prs = [
                  for (final gh in result.items)
                    pullRequestFromGitHub(gh, repoFullName: repo.fullName),
                ];
                groups.add((repo: repo, prs: prs, hasMore: result.hasMore));
              } on Object {
                // skip this repo
              }
            }
            return groups;
          },
    // GitHub org members across the workspace's repo owners (deduped by login).
    fetchOrgMembers: ghToken.isEmpty
        ? null
        : (owners) async {
            final byLogin = <String, Map<String, dynamic>>{};
            for (final org in owners) {
              try {
                final members = await serverGitHubClient.content
                    .getOrganizationMembers(org);
                for (final m in members) {
                  byLogin[m.login] = m.toJson();
                }
              } on Object {
                // skip this org
              }
            }
            return byLogin.values.toList();
          },
    // Bundled GitHub read fetchers for the compose-PR / peek / `#` search / repo
    // permission / profile / pagination surfaces a thin client can no longer
    // fetch itself (it holds no gh token). Null when token-less so those ops
    // degrade to empty. Workspace ownership of (owner, repo) is enforced in each
    // op handler before these run.
    githubRead: ghToken.isEmpty
        ? null
        : (
            repoBranches: (owner, repo) async {
              final branches = await serverGitHubClient.graphql
                  .listBranchesWithActivity(owner, repo);
              final me = ghStatus.username.toLowerCase();
              // Most-recent commit first; unknown dates sort last (a/b inferred
              // as GitHubBranchActivity from the list element type).
              final sorted = branches.toList()
                ..sort((a, b) {
                  final da = a.committedDate;
                  final db = b.committedDate;
                  if (da == null && db == null) {
                    return 0;
                  }
                  if (da == null) {
                    return 1;
                  }
                  if (db == null) {
                    return -1;
                  }
                  return db.compareTo(da);
                });
              final mine = <String>[];
              final others = <String>[];
              for (final b in sorted) {
                if (me.isNotEmpty && b.authorLogin?.toLowerCase() == me) {
                  mine.add(b.name);
                } else {
                  others.add(b.name);
                }
              }
              return [...mine, ...others];
            },
            defaultBranch: serverGitHubClient.pr.getDefaultBranch,
            prTemplates: (owner, repo) async {
              final templates = await serverGitHubClient.graphql
                  .fetchPullRequestTemplates(owner, repo);
              return [
                for (final t in templates)
                  (name: t.name, body: t.body, isDefault: t.isDefault),
              ];
            },
            compareBranches: (owner, repo, base, head) async {
              final c = await serverGitHubClient.pr.compareBranches(
                owner,
                repo,
                base: base,
                head: head,
              );
              return (
                files: c.files.map(prFileFromGitHub).toList(growable: false),
                commits: c.commits
                    .map(prCommitFromGitHub)
                    .toList(growable: false),
                additions: c.additions,
                deletions: c.deletions,
                totalCommits: c.totalCommits,
              );
            },
            prContent: (owner, repo, number) async {
              final gh = await serverGitHubClient.pr.getPullRequest(
                owner,
                repo,
                number,
              );
              if (gh == null) {
                return null;
              }
              return (
                body: gh.body,
                bodyHtml: gh.bodyHtml,
                changedFiles: gh.changedFiles,
                commitsCount: gh.commitsCount,
              );
            },
            searchIssues: serverGitHubClient.pr.searchIssues,
            repoPermission: (owner, repo) async {
              if (ghStatus.username.isEmpty) {
                return 'none';
              }
              try {
                return await serverGitHubClient.content
                    .getCollaboratorPermission(
                      owner,
                      repo,
                      ghStatus.username,
                    );
              } on Object {
                return 'none';
              }
            },
            userProfile: (login) async =>
                (await serverGitHubClient.graphql.getUserProfile(login: login))
                    ?.toWire(),
            openPrPage: (owner, repo, page) async {
              final result = await serverGitHubClient.pr
                  .listOpenPullRequestsPage(owner, repo, page: page);
              return (
                prs: [
                  for (final gh in result.items)
                    pullRequestFromGitHub(gh, repoFullName: '$owner/$repo'),
                ],
                hasMore: result.hasMore,
              );
            },
            closedByAuthorPage: (owner, repo, login, page) async {
              final result = await serverGitHubClient.pr
                  .searchClosedPullRequestsByAuthor(
                    owner,
                    repo,
                    login,
                    page: page,
                  );
              return (
                prs: [
                  for (final gh in result.items)
                    pullRequestFromGitHub(gh, repoFullName: '$owner/$repo'),
                ],
                hasMore: result.hasMore,
              );
            },
          ),
    // githubstatus.com summary (token-less; always available). The thin client
    // parses the raw summary with `GitHubServiceStatus.fromSummaryJson`.
    fetchGitHubServiceStatus: () =>
        GitHubStatusService(createDio()).fetchSummaryJson(),
    // Klipy GIF picker (server-side app key). Null when unconfigured → empty.
    gifSearch: klipy == null
        ? null
        : (query) async => [
            for (final g in await klipy.search(query)) g.toWire(),
          ],
    gifTrending: klipy == null
        ? null
        : () async => [for (final g in await klipy.trending()) g.toWire()],
    prPreviewCache: db.cacheDao,
    fetchPrPreview: (owner, repo, number) async {
      try {
        final pr = await serverGitHubClient.pr.getPullRequest(
          owner,
          repo,
          number,
        );
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
        final commit = await serverGitHubClient.pr.getCommit(owner, repo, sha);
        if (commit == null) {
          return null;
        }
        return {'title': commit.title, 'short_sha': commit.shortSha};
      } catch (_) {
        return null;
      }
    },
    // The headless server hosts its own MCP HTTP server; the `mcp.*` ops drive
    // this control so a connected web/thin client can start/stop/reconfigure it.
    mcpControl: mcpControl,
    // The `mcp.client.*` ops drive the external-MCP client subsystem (list
    // discovered servers, steer the approval posture, reconnect).
    mcpClientControl: mcpClientControl,
    // The headless server owns its filesystem, so it serves the `fs.*` ops over
    // the workspace on-disk layout rooted at its data dir.
    workspaceFilesystem: workspaceFilesystem,
    // Agent dispatch + channel lifecycle: the headless server now runs agents
    // itself (the dispatch engine is Flutter-free, on libccpty), so the
    // `dispatch.*` ops are LIVE. Streamed replies land on message rows the
    // client already watches via `messaging.watchMessages`.
    messagingDispatch: messagingService,
    // Review-fix agent: dispatch a sandboxed/relay agent server-side. The op
    // takes NO working_dir from the client — the working dir is resolved
    // server-side from the bound workspace, so a thin client can't aim the
    // agent at an arbitrary path.
    reviewDispatch: ({
      required workspaceId,
      required agentId,
      required prompt,
      required channelId,
    }) async {
      final workingDir = await workspaceFilesystem.workspaceDir(workspaceId);
      await agentDispatchService.dispatch(
        agentId: agentId,
        prompt: prompt,
        workingDirectory: workingDir,
        workspaceId: workspaceId,
        channelId: channelId,
        conversationId: channelId,
      );
    },
    // Interactive terminal over RPC (libccpty): the `terminal.*` ops run a REAL
    // shell on this host, scoped + ownership-checked per the bound workspace.
    terminalSessions: terminalSessions,
    // Pipelines + orchestration run headless: the engine drives the relocated
    // dispatch stack, so `pipeline.*` + `orchestration.approve/cancel` are LIVE.
    // (Pipelines using the deferred indexCode/cleanupRepos/meeting bodies still
    // fail with unknown-body until those are wired — see buildServerPipelineExecutor.)
    pipelineEngine: pipeline.engine,
    approveOrchestration: (workspaceId, orchestrationId) =>
        approveOrchestration.approve(
          workspaceId: workspaceId,
          orchestrationId: orchestrationId,
        ),
    cancelOrchestration: (workspaceId, orchestrationId) =>
        cancelOrchestration.cancel(
          workspaceId: workspaceId,
          orchestrationId: orchestrationId,
        ),
  );

  // Bootstrap device provisioning: a desktop that SPAWNS this server as a local
  // subprocess passes a one-time device id + PSK via env (it can no longer
  // pre-seed the DB it doesn't open). Provision them as an active paired device
  // so the loopback RPC handshake authenticates. No env → no bootstrap device
  // (a remote server is paired the normal way through the devices UI).
  final bootstrapDeviceId = Platform.environment['CC_BOOTSTRAP_DEVICE_ID'];
  final bootstrapPsk = Platform.environment['CC_BOOTSTRAP_PSK'];
  if (bootstrapDeviceId != null &&
      bootstrapDeviceId.isNotEmpty &&
      bootstrapPsk != null &&
      bootstrapPsk.isNotEmpty) {
    await db.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: Value(bootstrapDeviceId),
        label: const Value('Desktop (local)'),
        platform: const Value('desktop'),
        pskRef: const Value('file'),
        status: const Value(PairedDeviceStatus.active),
      ),
    );
    await secrets.writePsk(bootstrapDeviceId, bootstrapPsk);
    CcHostLog.info(
      'cc_server: provisioned bootstrap device $bootstrapDeviceId',
    );
  }

  // The default workspace bound to a new session (first workspace, if any).
  Future<List<RemoteWorkspaceSummary>> listWorkspaces() async {
    final rows = await db.workspaceDao.getAll();
    return [for (final w in rows) (id: w.id, name: w.name)];
  }

  final initialWorkspaces = await listWorkspaces();

  final repoOps = RepoOpDispatcher(
    registry: catalog.ops,
    mapException: mapAppExceptionToRpc,
  );
  // In-process TLS when a cert + key are configured (a public bind otherwise
  // needs it). A real deployment behind a TLS-terminating reverse proxy leaves
  // these unset and opts into a plaintext non-loopback bind via `--insecure`.
  SecurityContext? securityContext;
  if (config.tlsConfigured) {
    securityContext = SecurityContext()
      ..useCertificateChain(config.tlsCertPath)
      ..usePrivateKey(config.tlsKeyPath);
    CcHostLog.info('cc_server: TLS enabled (cert ${config.tlsCertPath})');
  }

  final server = LocalRpcServer(
    dispatcher: mcpDispatcher,
    devicesDao: db.pairedDeviceDao,
    secrets: secrets,
    eventBus: eventBus,
    workspaceResolver: listWorkspaces,
    repoOps: repoOps,
    watchQueries: catalog.watch,
    // Serves a recorded meeting's mixed audio over `/meeting/audio` for thin-
    // client playback. Resolves the file only for a meeting that belongs to the
    // signed workspace (getById is workspace-scoped), and assembles `mixed.wav`
    // on demand if the summary pipeline hasn't yet.
    meetingAudio: ({required workspaceId, required meetingId}) async {
      final meeting = await meetingRepository.getById(workspaceId, meetingId);
      final dir = meeting?.audioPath;
      if (meeting == null || dir == null || dir.isEmpty) {
        return null;
      }
      final clip =
          await loadMeetingAudioClip(MeetingAudioRequest(audioDirPath: dir));
      if (clip == null) {
        return null;
      }
      final file = File(clip.playablePath);
      return file.existsSync() ? file : null;
    },
    address: config.bindAddress,
    port: config.port,
    securityContext: securityContext,
    // Permit a plaintext non-loopback bind only when explicitly opted in AND no
    // in-process TLS is configured (TLS always wins). The standard container
    // topology: a TLS-terminating proxy fronts cc_server on a private network.
    allowInsecureBind: config.allowInsecure && securityContext == null,
    allowedOrigins: config.allowedOrigins,
  );

  await server.start();

  // ── Speech recognizer warm-up + dylib diagnostic ──
  // Eagerly load the recognizer (off the ready path, so it never delays boot)
  // when a voice model resolved. This surfaces — loudly, in the server log the
  // desktop pipes through — whether the sherpa-onnx native library actually
  // loaded in THIS pure-Dart process: the #1 cause of "audio captured + WAV
  // retained, but transcript empty" is the dylib failing to resolve here
  // (no Flutter plugin bundles it; the desktop must hand us its bundled-dylib
  // dir via CC_NATIVE_LIB_DIR — see ensureSherpaInitialized). It also warms the
  // model so the first window decodes immediately instead of paying init then.
  if (meetingTranscriber != null) {
    CcHostLog.info(
      'cc_server: warming speech recognizer (sherpa dylib dir: '
      '${sherpaLibDir ?? '<unresolved — set $nativeLibDirEnvVar, drop the '
          'dylibs in ${config.dataDir}, or ship them beside the binary>'})',
    );
    unawaited(
      meetingTranscriber.initialize().then((_) {
        CcHostLog.info(
          'cc_server: speech recognizer ready — meeting transcription enabled',
        );
      }).catchError((Object e) {
        CcHostLog.error(
          'cc_server: speech recognizer FAILED to load — meeting transcripts '
          'will be EMPTY. The sherpa-onnx dylib did not resolve in this '
          'process; ensure $nativeLibDirEnvVar points at a dir containing '
          'libsherpa-onnx-c-api + libonnxruntime. Cause: $e',
        );
      }),
    );
  }

  // ── Phone relay (broker rendezvous) ──
  // cc_server is the OWNER of each phone's connection: it dials the signaling
  // broker as a peer, joins the room named by the device id, authenticates the
  // phone with the pairing PSK, and serves its RPC over an E2E-encrypted relay —
  // so phone pairing works even when the server is not directly reachable. The
  // web/desktop app only mints the pairing + shows the QR (pure passthrough).
  // Watching the device table covers startup, mint, and revoke uniformly.
  final relayHost = RemoteRelayHost(
    signalingUrl: config.signalingUrl,
    dispatcher: mcpDispatcher,
    devicesDao: db.pairedDeviceDao,
    secrets: secrets,
    eventBus: eventBus,
    workspaceResolver: listWorkspaces,
    repoOps: repoOps,
    watchQueries: catalog.watch,
  );
  await relayHost.start();

  // ── Server-side keep-alive reconcilers ──
  // The pipeline/orchestration lifecycle listeners that the desktop used to run
  // in-process now run here, so a thin client connected to this server keeps
  // pipelines resuming, scheduled triggers firing and orchestration runs mapping
  // to terminal states. (CEO seeding, memory harvest, calendar sync, newsfeed
  // seed and embedding backfill are not yet relocated — documented follow-ups.)
  // Workspace bootstrap: when a workspace is created (the `workspace.upsert` op
  // publishes `WorkspaceCreated` for a new id), seed its CEO + specialist agents
  // and the built-in pipeline templates/triggers. The desktop used to do this
  // in-process; on a thin client the server owns the DB + agent files, so it
  // runs here. Idempotent + self-logging (never throws into the bus).
  final workspaceSeeder = WorkspaceSeeder(
    agentRepository: agentRepository,
    filesystem: workspaceFilesystem,
    templateRepository: pipelineTemplateRepository,
    triggerRepository: pipelineTriggerRepository,
  );
  eventBus
      .on<WorkspaceCreated>()
      .listen((event) => unawaited(workspaceSeeder.seed(event.workspaceId)));

  PipelineTriggerDispatcher(
    eventBus: eventBus,
    engine: pipeline.engine,
    triggerRepository: pipelineTriggerRepository,
  ).start();
  SubPipelineResumeListener(
    eventBus: eventBus,
    engine: pipeline.engine,
    repository: pipelineRunRepository,
  ).start();
  PipelineCostRollupListener(
    eventBus: eventBus,
    runLogRepository: agentRunLogRepository,
    runRepository: pipelineRunRepository,
  ).start();
  PipelineStepResumeListener(
    eventBus: eventBus,
    runLogRepository: agentRunLogRepository,
    engine: pipeline.engine,
  ).start();
  AgentRunTaskCompleter(
    eventBus: eventBus,
    runLogRepository: agentRunLogRepository,
    messagingRepository: messagingRepository,
  ).start();
  OrchestrationRunListener(
    eventBus: eventBus,
    orchestrations: orchestrationRepository,
    ticketWorkflow: ticketWorkflow,
  ).start();
  // Meeting-summary finalizer: drives a meeting `processing → done` on its
  // summary run's terminal event (and sweeps meetings stranded `recording` /
  // `processing` by a previous session). The desktop ran this in-process; on a
  // thin-client topology the server owns the meeting + pipeline-run DAOs, so it
  // runs here.
  final meetingReconciler = MeetingSummaryReconciler(
    eventBus: eventBus,
    runRepository: pipelineRunRepository,
    meetingRepository: meetingRepository,
  )..start();
  // Resume any in-flight pipelines from the last run (best-effort).
  unawaited(() async {
    try {
      await pipeline.engine.resumeAll();
    } on Object catch (e, st) {
      CcHostLog.error('cc_server: pipeline resumeAll failed: $e', e, st);
    }
  }());

  // Start the MCP HTTP server when the persisted config has it enabled. A bind
  // failure (e.g. port in use) is logged but does not abort the RPC server.
  try {
    await mcpControl.startIfEnabled();
    final mcpStatus = await mcpControl.status();
    if (mcpStatus.running) {
      CcHostLog.info('cc_server MCP HTTP server listening on :${mcpStatus.port}');
    }
  } catch (e) {
    CcHostLog.warning('cc_server MCP HTTP server failed to start: $e');
  }
  // Load the persisted external-MCP approval posture and apply it to the shared
  // dispatcher's tier gate before the first tool call.
  try {
    await mcpClientControl.init();
  } catch (e) {
    CcHostLog.warning('cc_server: external MCP approval posture load failed: $e');
  }
  final ccServer = CcServer._(db, server, mcpControl)
    .._meetingReconciler = meetingReconciler
    .._meetingRecording = meetingRecording
    .._voiceModelControl = voiceModelControl
    .._relayHost = relayHost
    .._mcpClientService = mcpClientService;

  // ── External MCP server discovery + connect (PRD 01 phases 1.1–1.3) ──
  // Auto-discover MCP servers the user already configured for other tools
  // (Claude/Codex/Cursor/Gemini/VS Code/Windsurf/OpenCode + standalone
  // `.mcp.json`) and connect the enabled ones, bridging their tools into the
  // registry. Fire-and-forget after boot so a slow/dead server never blocks
  // startup; best-effort — a discovery failure is logged, never fatal.
  unawaited(() async {
    try {
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'];
      if (home == null || home.isEmpty) {
        return;
      }
      final discovered = await mcpClientService.discoverAndStart(homeDir: home);
      CcHostLog.info(
        'cc_server: discovered ${discovered.length} external MCP server(s)',
      );
    } on Object catch (e) {
      CcHostLog.warning('cc_server: external MCP discovery failed: $e');
    }
  }());

  // ── Server-side Google Calendar sync ──
  // The server syncs every workspace's connected calendar into its DB on a fixed
  // cadence (no-op until an account is connected via the GUI `calendar.*Connect`
  // ops or `cc_server calendar connect`); thin clients (web/desktop) just READ
  // the result over the existing `calendar.watch*` RPC surface.
  serverCalendar.sync.start();
  ccServer._calendarSync = serverCalendar.sync;

  // ── Newsfeed seed + periodic refresh ──
  // The newsfeed is global (not workspace-scoped) and fetched SERVER-SIDE only —
  // the thin clients (web / desktop) just read the synced articles, they never
  // fetch RSS themselves. So the server owns the schedule: seed the default
  // feeds on first run, fetch once now so a freshly-connected client sees
  // articles immediately, then refresh on a fixed cadence. Relocated here from
  // the old desktop bootstrap (which no longer opens the DB). Best-effort: a
  // network failure is logged, never fatal.
  unawaited(() async {
    try {
      await newsfeedRepository.seedDefaultFeedsIfEmpty();
      await newsfeedRepository.refreshAll();
    } on Object catch (e, st) {
      CcHostLog.error('cc_server: newsfeed seed/refresh failed: $e', e, st);
    }
  }());
  ccServer._newsfeedRefreshTimer = Timer.periodic(
    const Duration(minutes: 30),
    (_) async {
      try {
        await newsfeedRepository.refreshAll();
      } on Object catch (e) {
        CcHostLog.warning('cc_server: newsfeed refresh failed: $e');
      }
    },
  );

  CcHostLog.info(
    'cc_server ready on ${config.bindHost}:${server.boundPort} '
    '(data: ${config.dataDir}, workspaces: ${initialWorkspaces.length})',
  );
  return ccServer;
}
