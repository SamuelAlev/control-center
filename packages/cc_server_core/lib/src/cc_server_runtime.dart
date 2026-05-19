import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, UserDto, ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/plan_events.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/services/activity_logger.dart';
import 'package:cc_domain/core/domain/services/memory_access_policy.dart';
import 'package:cc_domain/core/domain/services/user_mention_parser.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/agents/domain/services/budget_policy_service.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_summarizer.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/isolation/path_lock_manager.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_memory_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/evals/domain/services/starter_suites.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_domain/features/governance/domain/services/agent_presence_service.dart';
import 'package:cc_domain/features/governance/domain/services/approval_workflow_service.dart';
import 'package:cc_domain/features/governance/domain/services/budget_evaluation_listener.dart';
import 'package:cc_domain/features/governance/domain/services/budget_governance_service.dart';
import 'package:cc_domain/features/governance/domain/services/runtime_state_gc_sweeper.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/mcp/domain/services/mode_tool_guard.dart';
import 'package:cc_domain/features/memory/domain/services/fact_extraction.dart';
import 'package:cc_domain/features/memory/domain/services/memory_consolidation_service.dart';
import 'package:cc_domain/features/memory/domain/usecases/extract_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/harmonize_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/promote_facts_to_policy_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/record_memory_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/supersede_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/supersede_policy_use_case.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_domain/features/model_routing/domain/services/model_catalog.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_proposal_validator.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_run_listener.dart';
import 'package:cc_domain/features/orchestration/domain/usecases/cancel_orchestration_use_case.dart';
import 'package:cc_domain/features/orchestration/domain/usecases/save_orchestration_revision_use_case.dart';
import 'package:cc_domain/features/pipelines/domain/services/agent_run_task_completer.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_cost_rollup_listener.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_scheduler_service.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_step_resume_listener.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_trigger_dispatcher.dart';
import 'package:cc_domain/features/pipelines/domain/services/sub_pipeline_resume_listener.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_publisher_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_search_query.dart';
import 'package:cc_domain/features/remote_control/domain/services/remote_pairing_lifecycle.dart';
import 'package:cc_domain/features/settings/domain/services/branch_template_resolver.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scanner.dart';
import 'package:cc_domain/features/teams/domain/services/team_routing_service.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/services/project_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_link_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_domain/features/ticketing/domain/sync/multi_vendor_ticket_sync_coordinator.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_engine.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:cc_natives/cc_natives.dart'
    show
        FffFileSearch,
        GrammarManager,
        MeetingDiarizationService,
        NativeDirectoryWatcher,
        Pty,
        RiftClient,
        SherpaOnnxTranscriber,
        kLanguageByExtension,
        nativeLibDirEnvVar,
        nativeLibraryCandidates,
        inferenceLibraryBaseName,
        resolveInferenceLibraryPath,
        platformLibraryFileName,
        ptyLibraryBaseName,
        ptyLibraryEnvVar,
        setPreferredInferenceLibPath,
        tryOpenFirst,
        watcherLibraryBaseName,
        watcherLibraryEnvVar;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/repositories/cron_execution_ledger_impl.dart';
import 'package:cc_persistence/repositories/db_mode_resolver.dart';
import 'package:cc_persistence/repositories/team_activity_repository_impl.dart';
import 'package:cc_persistence/repositories/webhook_delivery_repository_impl.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteControlCrypto;
import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:cc_server_core/src/channel_provisioning_service.dart';
import 'package:cc_server_core/src/chat/chat_connector.dart';
import 'package:cc_server_core/src/chat/chat_provider_plugin.dart';
import 'package:cc_server_core/src/chat/chat_rpc_ops.dart';
import 'package:cc_server_core/src/chat/file_chat_connection_store.dart';
import 'package:cc_server_core/src/chat/slack_chat_provider_plugin.dart';
import 'package:cc_server_core/src/code_graph/pipeline_code_index_run_reporter.dart';
import 'package:cc_server_core/src/code_graph_tree_service.dart';
import 'package:cc_server_core/src/collab/checker_listener.dart';
import 'package:cc_server_core/src/collab/takeover_service.dart';
import 'package:cc_server_core/src/connection/network_runtime.dart';
import 'package:cc_server_core/src/connection/server_descriptor_service.dart';
import 'package:cc_server_core/src/dao_activity_log_reader.dart';
import 'package:cc_server_core/src/dao_code_graph_repository.dart';
import 'package:cc_server_core/src/dao_newsfeed_repository.dart';
import 'package:cc_server_core/src/dao_pr_lifecycle_repository.dart';
import 'package:cc_server_core/src/evals/evals_rpc_ops.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/fleet/fleet_rpc_ops.dart';
import 'package:cc_server_core/src/fleet/remote_execution_registry.dart';
import 'package:cc_server_core/src/fonts/fonts_rpc.dart';
import 'package:cc_server_core/src/github_vcs_provider_factory.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:cc_server_core/src/identity/approval_escalation_sweeper.dart';
import 'package:cc_server_core/src/identity/identity_bootstrap.dart';
import 'package:cc_server_core/src/identity/oidc_service.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_invite_service.dart';
import 'package:cc_server_core/src/local_rpc_server.dart';
import 'package:cc_server_core/src/models/managed_model_control.dart';
import 'package:cc_server_core/src/models/selectable_voice_model_control.dart';
import 'package:cc_server_core/src/native_preflight.dart';
import 'package:cc_server_core/src/notification_feed_recorder.dart';
import 'package:cc_server_core/src/plan_studio/plan_document_approval_service.dart';
import 'package:cc_server_core/src/plan_studio/plan_drift_service.dart';
import 'package:cc_server_core/src/plan_studio/plan_estimate_service.dart';
import 'package:cc_server_core/src/pr_review/open_pr_polling_service.dart';
import 'package:cc_server_core/src/pr_review/review_axis_service.dart';
import 'package:cc_server_core/src/pr_review/review_cohort_service.dart';
import 'package:cc_server_core/src/pr_review/review_diagram_service.dart';
import 'package:cc_server_core/src/presence/agent_presence_synthesizer.dart';
import 'package:cc_server_core/src/relay/remote_relay_host.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:cc_server_core/src/repo_ide_data_service.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:cc_server_core/src/server_mcp_client_control.dart';
import 'package:cc_server_core/src/server_mcp_control.dart';
import 'package:cc_server_core/src/server_mcp_registry.dart';
import 'package:cc_server_core/src/server_pipeline_executor.dart';
import 'package:cc_server_core/src/skill_reverify_service.dart';
import 'package:cc_server_core/src/soundscape/soundscape_rpc.dart';
import 'package:cc_server_core/src/sync/sync_feed_service.dart';
import 'package:cc_server_core/src/ticket_sync_webhook_handler.dart';
import 'package:cc_server_core/src/weather/weather_rpc.dart';
import 'package:cc_server_core/src/webhook_delivery_service.dart';
import 'package:cc_server_core/src/write_ledger_adapter.dart';
import 'package:dio/dio.dart' show InterceptorsWrapper;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// A running headless server instance — holds the database + WS server so a
/// caller (the `cc_server` binary, or a test) can shut it down cleanly.
class CcServer {
  CcServer._(this._globalDb, this._workspaceDbs, this.rpc, this._mcpControl);

  final GlobalDatabase _globalDb;
  final WorkspaceDatabaseManager _workspaceDbs;
  final ServerMcpControl _mcpControl;

  /// Server-hosted code-server processes, torn down (every child killed) on
  /// [shutdown] so a host exit never orphans code-server subprocesses.
  CodeServerService? _codeServer;

  /// The bound WebSocket RPC server.
  final LocalRpcServer rpc;

  /// Periodic newsfeed-refresh timer (cancelled on [shutdown]).
  Timer? _newsfeedRefreshTimer;

  /// The open-PR poller behind the live PR list (null when the server holds
  /// no gh token). Disposed on [shutdown].
  OpenPrPollingService? _openPrPoller;

  /// GitHub notifications poller (review requests / mentions → events +
  /// targeted refreshes). Disposed on [shutdown].
  GitHubNotificationPollingService? _githubNotificationPoller;

  /// Change-signal bus feeding live `pr_review.watch*` streams. Disposed on
  /// [shutdown] so open streams complete.
  PrChangeSignals? _prChangeSignals;

  /// Periodic ticket-sync pull fallback (webhooks may be unreachable — this
  /// server can run without a public URL). Cancelled on [shutdown].
  Timer? _ticketSyncPullTimer;

  /// Periodic runtime-state GC sweep (PRD 09): reaps agent runtime-state rows
  /// stale past the 7-day threshold across all workspaces. Cancelled on
  /// [shutdown].
  Timer? _runtimeStateGcSweepTimer;

  /// The fleet scheduler (PRD 20): places job specs onto workers, holds leases,
  /// reaps expired ones. Cancelled/disposed on [shutdown].
  FleetSchedulerService? _fleetScheduler;

  /// The implicit local worker's executor (PRD 20) — kind→runner registry that
  /// feature services (evals, golden render, code index) register into.
  LocalJobExecutor? _fleetLocalExecutor;

  /// Periodic lease-reap sweep (PRD 20 §8): reclaims jobs whose worker went
  /// silent. Cancelled on [shutdown].
  Timer? _fleetReapTimer;

  /// The fleet scheduler, for feature services that submit jobs (PRD 21 eval
  /// batches, PRD 18 golden renders).
  FleetSchedulerService? get fleetScheduler => _fleetScheduler;

  /// The local worker's executor, so feature services can register their
  /// in-process job runner (e.g. the eval runner registers `evalBatch`).
  LocalJobExecutor? get fleetLocalExecutor => _fleetLocalExecutor;

  /// Meeting-summary finalizer (started after boot; disposed on [shutdown]).
  MeetingSummaryReconciler? _meetingReconciler;

  /// Durable goal supervisor (`/goal`, `/loop`). Disposed on [shutdown] so no
  /// re-dispatch backoff timer outlives the server.
  GoalSupervisor? _goalSupervisor;

  /// Live RPC meeting recorder, when an ASR model is installed (else null).
  /// Open sessions are aborted on [shutdown]; the reconciler recovers them.
  MeetingRecordingService? _meetingRecording;

  /// Live RPC composer dictation, when an ASR model is installed (else null).
  /// In-memory only (a dictation persists nothing), so [shutdown] just drains
  /// any open session's transcriber windows and closes its streams.
  DictationService? _dictationService;

  /// Selectable ASR/voice model control (download + model switching over the
  /// `models.voice*` ops). Cancels any in-flight download on [shutdown].
  SelectableVoiceModelControl? _voiceModelControl;

  /// Embedding + diarization model controls. Boot force-installs both (they
  /// are the fixed, unique on-device models), so [shutdown] must cancel any
  /// in-flight boot download.
  ManagedModelControl? _embeddingModelControl;
  ManagedModelControl? _diarizationModelControl;

  /// Server-side Google Calendar sync sweep, started after boot when a Google
  /// client id is configured (else null). Disposed on [shutdown].
  ServerCalendarSync? _calendarSync;

  /// Per-workspace live weather (Open-Meteo, keyless) feeding the soundscape
  /// engine and the `weather.*` ops. Disposed on [shutdown].
  ServerWeatherService? _weatherService;

  /// Server-side generative soundscape engine: shared `(workspace, mood)`
  /// sessions streamed as MP3 over `/soundscape/*`. Disposed on [shutdown].
  SoundscapeHub? _soundscapeHub;

  /// Relays phone connections through the signaling broker when the server is
  /// not directly reachable (cc_server is the owning peer). Disposed on
  /// [shutdown].
  RemoteRelayHost? _relayHost;

  /// The MCP client (connections to external MCP servers). Bridged tools are
  /// pushed into the shared registry; all connections (and their stdio child
  /// process trees) are torn down on [shutdown].
  McpClientService? _mcpClientService;
  NetworkRuntime? _networkRuntime;
  PresenceHub? _presenceHub;
  CheckerDispatchListener? _checkerListener;
  WorktreeGcListener? _worktreeGcListener;
  NotificationFeedRecorder? _notificationFeedRecorder;
  SyncFeedService? _syncFeed;
  AgentPresenceSynthesizer? _agentPresenceSynthesizer;

  /// Keeps every checkout's code-graph partition current (initial index on
  /// worktree provision, incremental reindex on any file save / PR sync).
  /// Disposed in [shutdown] with the other data-sync listeners.
  CodeGraphWatchService? _codeGraphWatch;

  /// In-flight agent-action approvals. Disposed on [shutdown] so any request
  /// still blocking an agent is denied and its future released.
  PendingConfirmationRegistry? _pendingConfirmations;

  /// Every connected workspace's chat-bridge transports. Closed on [shutdown] so
  /// the provider sees a clean disconnect instead of a dead socket it keeps
  /// delivering to for a while.
  ChatConnector? _chatConnector;

  /// Per-step cap for [shutdown]. Each teardown step is bounded to this so a
  /// single stuck service (a stdio MCP child ignoring SIGTERM, a tunnel
  /// subprocess, drift's background isolate blocked on an in-flight query)
  /// can't hold the whole sequence past the caller's outer backstop.
  static const _stepTimeout = Duration(seconds: 3);

  /// Stops the server and closes the database.
  ///
  /// Streams per-service teardown progress to connected thin clients as
  /// `server/shutdown_progress` JSON-RPC notifications *before* the RPC socket
  /// closes, so a client can render a live "shutting down" overlay. The
  /// teardown sequence and its order are unchanged.
  ///
  /// Every step is best-effort and independently bounded: a service that hangs
  /// past [_stepTimeout] or throws is logged by name and skipped, so one stuck
  /// teardown can NOT starve the steps after it — in particular the DB close.
  /// (This is why shutdown no longer surfaces a bare `TimeoutException` to the
  /// caller: the culprit service is named in the log instead.) The caller
  /// (`_runServer`) still caps the whole sequence as a final backstop.
  Future<void> shutdown() async {
    const services = <String>[
      'approvals',
      'backgroundJobs',
      'scheduler',
      'calendar',
      'weather',
      'soundscape',
      'meetings',
      'voiceModels',
      'networking',
      'presence',
      'dataSync',
      'deviceRelay',
      'chat',
      'mcpConnections',
      'codeEditors',
    ];
    rpc.broadcast('server/shutdown_progress', <String, dynamic>{
      'phase': 'begin',
      'services': services,
    });

    // Run [action] under a per-step cap, isolating failures. A step that
    // exceeds [_stepTimeout] or throws is logged and skipped rather than
    // aborting the rest of teardown. `.timeout` does not cancel the underlying
    // work, but we hard-exit moments later so the abandoned future is moot.
    Future<void> guard(String id, Future<void> Function() action) async {
      try {
        await action().timeout(_stepTimeout);
      } on TimeoutException {
        CcHostLog.warning(
          'shutdown: step "$id" did not finish within '
          '${_stepTimeout.inSeconds}s — skipping',
        );
      } on Object catch (e) {
        CcHostLog.warning('shutdown: step "$id" failed: $e — skipping');
      }
    }

    // A guarded step that also reports progress to connected thin clients.
    Future<void> step(String id, Future<void> Function() action) async {
      await guard(id, action);
      rpc.broadcast('server/shutdown_progress', <String, dynamic>{
        'phase': 'step',
        'service': id,
      });
    }

    await step('approvals', () async => _pendingConfirmations?.dispose());
    await step('backgroundJobs', () async {
      _newsfeedRefreshTimer?.cancel();
      _runtimeStateGcSweepTimer?.cancel();
      _fleetReapTimer?.cancel();
      _ticketSyncPullTimer?.cancel();
      _openPrPoller?.dispose();
      _githubNotificationPoller?.dispose();
      _prChangeSignals?.dispose();
      _goalSupervisor?.dispose();
    });
    await step('scheduler', () async => _fleetScheduler?.dispose());
    await step('calendar', () async => _calendarSync?.dispose());
    await step('weather', () async => _weatherService?.dispose());
    await step('soundscape', () async => _soundscapeHub?.dispose());
    await step('meetings', () async {
      _meetingReconciler?.dispose();
      await _meetingRecording?.dispose();
      // Shares the meeting transcriber, so tear it down in the same step
      // (before `voiceModels`) rather than leaving windows mid-decode.
      await _dictationService?.dispose();
    });
    await step('voiceModels', () async => _voiceModelControl?.dispose());
    await step('models', () async {
      await _embeddingModelControl?.dispose();
      await _diarizationModelControl?.dispose();
    });
    await step('networking', () async => _networkRuntime?.stop());
    await step('presence', () async {
      await _agentPresenceSynthesizer?.stop();
      _presenceHub?.dispose();
    });
    await step('dataSync', () async {
      _syncFeed?.dispose();
      await _checkerListener?.stop();
      _worktreeGcListener?.dispose();
      await _notificationFeedRecorder?.dispose();
      await _codeGraphWatch?.dispose();
    });
    await step('deviceRelay', () async => _relayHost?.stop());
    await step('chat', () async => _chatConnector?.stop());
    await step('mcpConnections', () async => _mcpClientService?.shutdown());
    // Kill every live code-server subprocess so a host exit leaves no orphans.
    await step('codeEditors', () async => _codeServer?.disposeAll());

    // Let the final progress frames flush over the wire before the socket
    // closes — `rpc.stop()` force-closes the listener and can drop in-flight
    // frames otherwise.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    rpc.broadcast('server/shutdown_progress', const <String, dynamic>{
      'phase': 'complete',
    });

    // Critical teardown, each guarded independently so a hang in one still lets
    // the others run — the DB closes in particular flush each WAL and stop
    // drift's background isolates. (A hard exit releases the file locks either
    // way, but a clean close avoids a WAL-recovery pass on the next boot, once
    // per open workspace.)
    await guard('rpc', rpc.stop);
    await guard('mcpControl', _mcpControl.dispose);
    await guard('workspaceDbs', _workspaceDbs.closeAll);
    await guard('globalDb', _globalDb.close);
  }
}

/// Boots the pure-Dart headless server: opens `global.db` over
/// [openGlobalDatabase] (per-workspace databases open lazily through
/// [WorkspaceDatabaseManager]), wires the repository-backed RPC catalog
/// (tickets / messaging / newsfeed) onto a [LocalRpcServer], and starts
/// listening. No Flutter — this links into a `dart build cli` native binary.
///
/// Serializes every log write+flush through one chain. This matters twice:
///  * An [IOSink] throws "StreamSink is bound to a stream" if you `writeln`
///    while a previous `flush()` is still in flight, so overlapping the two
///    (e.g. two log lines back-to-back) crashes the process — the chain
///    guarantees the prior flush finishes before the next write starts.
///  * Flushing each line makes logs stream immediately even over a pipe (the
///    desktop spawns cc_server with piped, block-buffered stdio), instead of
///    batching into one late burst that reads as "the server hung on start".
Future<void> _logTail = Future<void>.value();

/// The rotating on-disk log, installed by [runCcServer] under `<dataDir>/logs`.
/// Null until the server boots (tests and the `pair`/`calendar` subcommands
/// leave it unset, so they log to stdio only).
/// How recently a conversation must have been touched for its worktree to keep
/// a live file watcher. Dormant ones are indexed on demand when they wake.
const Duration _watchActivityWindow = Duration(days: 7);

RotatingFileLogSink? _fileSink;

/// Runs a boot phase, announcing it before and timing it after.
///
/// Boot is a long sequence of awaits with logging only at a few landmarks, so a
/// phase that got slow (the database open on a multi-GB file, a `gh` probe
/// blocked on a keyring) presented as a server hung after its last line with no
/// way to attribute the wait. Announcing BEFORE the await is the point: the
/// phase in flight is the one to blame.
///
/// Completion is ALWAYS logged, not just when slow. With a slow-only rule a fast
/// phase leaves its own start line as the last thing on screen, so the next
/// (unannounced) phase's stall gets blamed on it — which is exactly how a
/// sub-second `gh` probe came to look like the thing hanging boot. The rule now
/// is simple: a `…` line with no matching `✓` is the phase still running.
Future<T> _bootStep<T>(String label, Future<T> Function() action) async {
  _bootMark(label);
  final startedAt = DateTime.now();
  final result = await action();
  _bootDone(label, startedAt);
  return result;
}

/// Announces a boot phase that is about to start. Use directly for a stretch of
/// SYNCHRONOUS construction, which [_bootStep] cannot wrap but which can still
/// take real time (dylib loads, catalog parsing, building the tool registry).
void _bootMark(String label) => CcHostLog.info('cc_server: $label…');

/// Ceiling for a boot phase that reaches the NETWORK.
///
/// Boot must not depend on a remote host answering: the relay's signaling
/// broker and the mDNS/tunnel stack are both best-effort and both retry on
/// their own, so a slow or unreachable one should cost that feature, never the
/// server's startup. On timeout the phase is left running in the background and
/// boot proceeds.
Future<void> _bootStepBounded(
  String label,
  Future<void> Function() action, {
  required String onTimeout,
  Duration limit = const Duration(seconds: 10),
}) async {
  _bootMark(label);
  final startedAt = DateTime.now();
  try {
    // Split the synchronous head from the awaited tail. `.timeout()` cannot arm
    // its timer until `action()` returns a future, so work done synchronously
    // inside it is invisible to the bound AND freezes the event loop — which is
    // exactly how a "10s" timeout was observed firing 56s late. Timing the two
    // halves separately says which one is at fault instead of leaving it to
    // inference.
    final future = action();
    final syncMs = DateTime.now().difference(startedAt).inMilliseconds;
    if (syncMs >= 1000) {
      CcHostLog.warning(
        'cc_server: $label blocked the isolate for ${syncMs}ms BEFORE yielding '
        '— synchronous work on the boot path, not a slow peer',
      );
    }
    await future.timeout(limit);
    _bootDone(label, startedAt);
  } on TimeoutException {
    CcHostLog.warning(
      'cc_server: $label did not finish within ${limit.inSeconds}s — '
      'continuing boot ($onTimeout)',
    );
  } on Object catch (e) {
    CcHostLog.warning('cc_server: $label failed: $e ($onTimeout)');
  }
}

/// Closes a phase opened with [_bootMark]. Slow phases are called out at info
/// with their duration; quick ones only surface at the debug log level, so a
/// normal boot stays readable while still proving the phase finished.
void _bootDone(String label, DateTime startedAt) {
  final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
  if (elapsedMs >= 1000) {
    CcHostLog.info('cc_server: ✓ $label (${elapsedMs}ms)');
  } else if (CcInfraLog.isEnabled(CcInfraLogLevel.debug)) {
    CcHostLog.info('cc_server: ✓ $label (${elapsedMs}ms)');
  }
}

/// Maps each logging façade's severity onto the server's canonical
/// [CcServerLogLevel] so `--log-level` filters every seam uniformly. The
/// switches are exhaustive on purpose: a new façade tier fails to compile
/// here until it is classified.
CcServerLogLevel _hostSeverity(CcHostLogLevel level) => switch (level) {
  CcHostLogLevel.info => CcServerLogLevel.info,
  CcHostLogLevel.warning => CcServerLogLevel.warning,
  CcHostLogLevel.error => CcServerLogLevel.error,
};

CcServerLogLevel _persistenceSeverity(CcPersistenceLogLevel level) =>
    switch (level) {
      CcPersistenceLogLevel.info => CcServerLogLevel.info,
      CcPersistenceLogLevel.warning => CcServerLogLevel.warning,
      CcPersistenceLogLevel.error => CcServerLogLevel.error,
    };

CcServerLogLevel _domainSeverity(CcDomainLogLevel level) => switch (level) {
  CcDomainLogLevel.info => CcServerLogLevel.info,
  CcDomainLogLevel.warning => CcServerLogLevel.warning,
  CcDomainLogLevel.error => CcServerLogLevel.error,
};

CcServerLogLevel _infraSeverity(CcInfraLogLevel level) => switch (level) {
  CcInfraLogLevel.debug => CcServerLogLevel.debug,
  CcInfraLogLevel.info => CcServerLogLevel.info,
  CcInfraLogLevel.warning => CcServerLogLevel.warning,
  CcInfraLogLevel.error => CcServerLogLevel.error,
};

void _emitLog(bool isError, String line, [Object? error]) {
  // Wall-clock prefix on every line. Without it a boot log shows WHICH phase
  // was last but not how long the gap after it was, so "it hangs here" and "it
  // pauses here" are indistinguishable in a pasted log — which cost real time
  // chasing the wrong phase.
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final stamp =
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)}'
      '.${now.millisecond.toString().padLeft(3, '0')}';
  line = '$stamp $line';
  // Persist to the rotating file first — synchronous + flushed — so a line
  // (including a crash record) survives even if the process dies immediately
  // after. Bounded on disk by the sink's size cap + retention (FINDINGS §132).
  _fileSink?.write(error != null ? '$line\n  $error' : line);
  _logTail = _logTail.then((_) async {
    try {
      if (isError) {
        stderr.writeln(line);
        if (error != null) {
          stderr.writeln('  $error');
        }
        await stderr.flush();
      } else {
        stdout.writeln(line);
        await stdout.flush();
      }
    } catch (_) {
      // Broken pipe / closed stdio — drop the line rather than crash boot.
    }
  });
}

/// Records an uncaught top-level server error to stderr **and** the rotating
/// on-disk log, so a crash in an async reconciler/timer that would otherwise
/// vanish leaves a persistent trail (FINDINGS §130). Safe to call before the
/// file sink is installed (it degrades to stderr only). Wire it as the handler
/// of a `runZonedGuarded` around the server run.
void recordUncaughtServerError(Object error, StackTrace stack) {
  _emitLog(true, 'cc_server: uncaught error: $error', stack);
}

/// Diagnostics route through [CcHostLog] (installed to stdout/stderr here).
/// Paired-device PSKs live in a [FileSecretsStore] under the data dir.
///
/// [harnessCredentialStore] resolves LLM provider credentials for the built-in
/// harness transport. Defaults to environment variables; a desktop host can
/// pass a keychain-backed store so GUI users authenticate without exporting
/// env vars.
Future<CcServer> runCcServer({
  List<String> args = const [],
  ProviderCredentialStore? harnessCredentialStore,
}) async {
  final config = CcServerConfig.resolve(args);

  // A rotating on-disk log under the data dir, so a long-lived headless server
  // keeps a bounded, persistent record (and a crash trail) beyond ephemeral
  // stdio (FINDINGS §130/§132). Every log seam below tees into it via _emitLog.
  _fileSink = RotatingFileLogSink(directory: '${config.dataDir}/logs');

  CcHostLog.sink = (level, message, [error, stackTrace]) {
    final severity = _hostSeverity(level);
    if (severity.index < config.logLevel.index) {
      return;
    }
    _emitLog(
      severity == CcServerLogLevel.error,
      '[${level.name}] $message',
      error,
    );
  };

  // The Drift-backed repositories log through their own seam; route it to the
  // same stdout/stderr so server persistence diagnostics are visible.
  CcPersistenceLog.sink = (level, message, [error, stackTrace]) {
    final severity = _persistenceSeverity(level);
    if (severity.index < config.logLevel.index) {
      return;
    }
    _emitLog(
      severity == CcServerLogLevel.error,
      '[${level.name}] $message',
      error,
    );
  };

  // Domain services (reconcilers, listeners, the pipeline engine) log through
  // the shared-kernel seam; route it to the same stdout/stderr.
  CcDomainLog.sink = (level, message, [error, stackTrace]) {
    final severity = _domainSeverity(level);
    if (severity.index < config.logLevel.index) {
      return;
    }
    _emitLog(
      severity == CcServerLogLevel.error,
      '[${level.name}] $message',
      error,
    );
  };

  // Infra adapters (git, dio clients, the credential broker, sandboxing) log
  // through their own façade; on the server it was previously unset, so those
  // diagnostics vanished. Route it to the same tee so infra warnings/errors
  // land in stdio + the rotating file.
  CcInfraLog.sink = (level, message, [error, stackTrace]) {
    final severity = _infraSeverity(level);
    if (severity.index < config.logLevel.index) {
      return;
    }
    _emitLog(
      severity == CcServerLogLevel.error,
      '[${level.name}] $message',
      error,
    );
  };

  // Gates the debug tier the infra façade suppresses below the configured
  // level (dio request/response lines, a code-graph index run that found
  // nothing to do). From `--log-level` / `CC_SERVER_LOG_LEVEL`.
  CcInfraLog.level = switch (config.logLevel) {
    CcServerLogLevel.debug => CcInfraLogLevel.debug,
    CcServerLogLevel.info => CcInfraLogLevel.info,
    CcServerLogLevel.warning => CcInfraLogLevel.warning,
    CcServerLogLevel.error => CcInfraLogLevel.error,
  };

  // First line the moment the sink is live, so the console shows the server is
  // alive immediately — the DB open + model/registry wiring below run silently
  // for a bit, and (piped, block-buffered stdout aside) that used to read as a
  // hung start. Emitted directly, bypassing the level filter (and its `[level]`
  // prefix): the lifecycle lines always print, whatever `--log-level` says.
  _emitLog(false, 'cc_server: booting (data: ${config.dataDir})…');

  // Persistence is two halves. `global.db` holds only server-wide state (the
  // workspace registry, identity, the newsfeed, the fleet queue) and is the ONLY
  // database boot opens — it stays small, so opening it is cheap however much
  // history the workspaces accumulate. Each workspace's own file opens lazily on
  // first touch, through the manager, and pays its own migrations, trigger
  // install and corruption check then.
  //
  // This is also the workspace-isolation boundary: a `WorkspaceDatabase` does
  // not declare another workspace's tables, so a cross-workspace read is a
  // compile error rather than a missing WHERE clause.
  final globalDb = GlobalDatabase(
    openGlobalDatabase(dataDir: config.dataDir),
    onWarn: (tag, message) => CcHostLog.warning('$tag: $message'),
    onError: (tag, message) => CcHostLog.error('$tag: $message'),
  );
  final workspaceDbs = WorkspaceDatabaseManager(
    dataDir: config.dataDir,
    global: globalDb,
    onWarn: (tag, message) => CcHostLog.warning('$tag: $message'),
    onError: (tag, message) => CcHostLog.error('$tag: $message'),
  );
  // Every cross-workspace read in the server goes through this one helper, so
  // the complete list of things that legitimately span workspaces (dashboards,
  // startup reconcilers, retention) is enumerable rather than diffuse.
  final crossWorkspace = CrossWorkspaceQueries(workspaceDbs);
  // ONE secrets store shared by every consumer (bootstrap provisioning, the
  // `pairing.*` ops that MINT new device PSKs, and the LocalRpcServer that
  // AUTHENTICATES them). FileSecretsStore caches the on-disk map in memory, so
  // separate instances would diverge — a PSK minted via the catalog's instance
  // would be invisible to the server's authenticator (auth would silently fail
  // and a freshly-paired client could never connect).
  final secrets = FileSecretsStore(dataDir: config.dataDir);
  final eventBus = DomainEventBus();

  // ── Server identity (PRD 15 §9) ──
  // The Ed25519 keypair + relay room minted at first boot. Its fingerprint is
  // the server's identity across every path (loopback, LAN, tunnel, relay) —
  // clients pin it on first pair (TOFU) and the auth handshake proves it per
  // connection. Loaded before anything advertises the server.
  final serverIdentity = await ServerIdentityStore.load(
    config.dataDir,
    serverName: config.serverName,
  );
  CcHostLog.info(
    'Server identity: ${serverIdentity.serverName} '
    '(${serverIdentity.serverId}) fp=${serverIdentity.fingerprint.substring(0, 12)}…',
  );
  final descriptorService = ServerDescriptorService(
    config: config,
    identity: serverIdentity,
  );
  // The network runtime (mDNS + tunnel + relay usage) starts after the RPC
  // server binds; the catalog's `connectivity.*` ops resolve it lazily
  // through this holder.
  final networkRuntimeHolder = _Late<NetworkRuntime>();
  final takeoverHolder = _Late<TakeoverService>();

  // ── Presence lane (PRD 16 §1) ──
  // The in-memory awareness hub: humans publish via `presence.update`,
  // agents are synthesized below, `presence.watch` fans the roster out per
  // workspace. NEVER persisted (the awareness rule).
  final presenceHub = PresenceHub()..start();

  // ── Identity bootstrap (multi-user identity & access) ──
  // First boot with no users mints the owner (first-user-is-admin; headless
  // seeds from CC_OWNER_HANDLE / CC_OWNER_NAME / CC_OWNER_EMAIL), then the
  // idempotent backfill binds legacy workspaces / devices / sentinel rows to
  // that owner. Runs BEFORE any RPC surface accepts connections so every
  // session resolves a real principal.
  // This is also where `global.db` actually opens: it is lazy, so the first
  // query pays for its migrations + `beforeOpen`. The install id is loaded first
  // because every workspace file created afterwards is stamped with it (that is
  // what lets an exported workspace be recognised as foreign on import).
  final ownerUserId = await _bootStep(
    'opening database + identity bootstrap',
    () async {
      await workspaceDbs.loadInstallId();
      return IdentityBootstrap(
        global: globalDb,
        workspaces: workspaceDbs,
        environment: Platform.environment,
        eventBus: eventBus,
        log: CcHostLog.info,
      ).run();
    },
  );
  // Database files nobody claims are reported, never adopted or deleted: an
  // unclaimed file is either a failed import or a registry that lost a row, and
  // both want a human rather than a silent decision.
  for (final orphan in await workspaceDbs.orphanedDatabaseFiles()) {
    CcHostLog.warning('Orphaned workspace database (no registry row): $orphan');
  }
  final userRepository = DaoUserRepository(globalDb.userDao);
  // Per-user GitHub tokens (PRD 14 §10), namespaced inside the SAME secrets
  // file so there is exactly one on-disk secret map + in-memory cache. Backs
  // both the `credentials.*` ops and the per-run token override in dispatch.
  final userCredentials = UserCredentialsStore(secrets);
  final membershipRepository = DaoWorkspaceMembershipRepository(workspaceDbs);
  final inviteRepository = DaoWorkspaceInviteRepository(
    workspaceDbs,
    globalDb.workspaceRouteDao,
  );
  final userActivityRepository = DaoUserActivityRepository(workspaceDbs);
  final userPreferencesRepository = DaoUserPreferencesRepository(
    globalDb.userPreferenceDao,
  );
  // Workspace-scoped settings (branch naming, agent/model defaults, default
  // sandbox capabilities, data-sharing policy) — the mirror of the per-user
  // store one scope up. Holds the manager, never a resolved DAO.
  final workspaceSettingsRepository = DaoWorkspaceSettingsRepository(
    workspaceDbs,
  );
  // Install-wide settings: what any process on this HOST may do. One scope
  // above the workspace, because one host serves every workspace.
  final serverSettingsRepository = DaoServerSettingsRepository(
    globalDb.serverSettingDao,
  );
  final inviteService = WorkspaceInviteService(
    invites: inviteRepository,
    members: membershipRepository,
    users: userRepository,
    eventBus: eventBus,
  );
  // Approval routing (per-workspace policy + escalation): unanswered gates
  // escalate requesting-user → admins → owner on the policy's timeout, with
  // the escalation attributed in the approval thread.
  final approvalEscalation = ApprovalEscalationSweeper(
    approvals: DaoApprovalRepository(workspaceDbs),
    workspaces: DaoWorkspaceRepository(
      globalDb.workspaceRegistryDao,
      workspaceDbs,
    ),
    members: membershipRepository,
    cache: DaoCacheRepository(workspaceDbs),
    workflow: ApprovalWorkflowService(
      repository: DaoApprovalRepository(workspaceDbs),
    ),
    eventBus: eventBus,
    onError: (message) => CcHostLog.warning('approval routing: $message'),
  )..start();
  // Optional OIDC SSO (CC_OIDC_ISSUER + CC_OIDC_CLIENT_ID): JIT user
  // provisioning + group-claim role mapping; a solo operator never sees it.
  final oidcConfig = OidcConfig.fromEnvironment(Platform.environment);
  final oidcService = !oidcConfig.enabled
      ? null
      : OidcService(
          config: oidcConfig,
          users: userRepository,
          members: membershipRepository,
          workspaces: DaoWorkspaceRepository(
            globalDb.workspaceRegistryDao,
            workspaceDbs,
          ),
          mintDevice: (userId, label) async {
            final deviceId = const Uuid().v4();
            final psk = RemoteControlCrypto.generatePsk();
            await globalDb.pairedDeviceDao.upsert(
              PairedDevicesTableCompanion(
                id: Value(deviceId),
                userId: Value(userId),
                label: Value(label),
                platform: const Value('web'),
                pskRef: const Value('file'),
                status: const Value(PairedDeviceStatus.active),
                expiresAt: Value(
                  DateTime.now().add(RemotePairingLifecycle.credentialLifetime),
                ),
              ),
            );
            await secrets.writePsk(deviceId, psk);
            return (deviceId: deviceId, psk: psk);
          },
        );

  // ── On-device embedding model (semantic search over memory facts, code
  // symbols, and conversation history) ──
  // The headless server hosts the embedding model exactly like the desktop: an
  // on-disk ONNX model managed by [EmbeddingModelManager]. The model is
  // FORCE-INSTALLED at boot (see the model warm-up next to the code-server
  // warm-up below) — models are the ONLY artifacts the server downloads at
  // runtime; the native libraries ship inside the bundle. The
  // [EmbeddingService] is constructed up front and threaded into every
  // consumer (memory / code-graph / conversation repos + the MCP search
  // tools); each guards on `isReady`, which flips on via
  // [EmbeddingService.updatePaths] the moment the boot download finishes — no
  // restart. The `sqlite_vector` extension is already loaded in
  // openServerDatabase, so the KNN queries work once vectors exist on disk.
  final paths = CcPaths(config.dataDir);
  final embeddingModelManager = EmbeddingModelManager(paths: paths);
  // Where THIS pure-Dart process loads the inference native from (no Flutter
  // plugin bundles it here): an explicit `CC_NATIVE_LIB_DIR` override (the
  // desktop hands it its Frameworks dir when it spawns us), else the data dir
  // (a remote/headless deploy can drop the dylib beside its models), else this
  // binary's own bundle layout (a self-contained server shipped with its libs).
  //
  // ONE path covers BOTH ML workloads — semantic embeddings AND the whole
  // speech stack — because `libcc_inference` statically links sherpa-onnx
  // together with a single ONNX Runtime. There is no sibling dylib to locate
  // and no bare-leaf-name open to rescue with an absolute-path override, which
  // is what the two previous loaders existed to do.
  //
  // Resolution is a FILE STAT, never a `DynamicLibrary.open`: probing by open
  // is what used to hang every JIT host at boot (`dart run` / `dart test`
  // wedged indefinitely opening the sherpa dylib, while AOT opened it in
  // milliseconds). The real load happens lazily on the worker isolate that
  // needs it, where a genuine failure surfaces as an actionable `init_error`.
  // A null here refuses boot at the native preflight below.
  final inferenceLibPath = resolveInferenceLibraryPath(
    appSupportRoot: config.dataDir,
  );
  // The preferred path for THIS (main) isolate's users — diarization + VAD.
  // Worker isolates (decode, embedder) are handed it explicitly, since Dart
  // statics do not cross isolate boundaries.
  setPreferredInferenceLibPath(inferenceLibPath);
  final embeddingService = EmbeddingService(
    modelInfo: embeddingModelManager.model,
    libPath: inferenceLibPath,
  );
  // Pick up an already-installed model immediately at boot.
  embeddingService.updatePaths(await embeddingModelManager.resolve());

  final ticketRepository = DaoTicketRepository(
    workspaceDbs,
    globalDb.workspaceRouteDao,
  );
  final projectRepository = DaoProjectRepository(workspaceDbs);
  final ticketWorkflow = TicketWorkflowService(
    repository: ticketRepository,
    eventBus: eventBus,
    onWarn: (m) => CcHostLog.warning('TicketWorkflowService: $m'),
  );
  final messagingRepository = DaoMessagingRepository(workspaceDbs);
  final conversationRepository = DaoConversationRepository(workspaceDbs);

  // ── Deterministic sync feed (PRD 16 §6) ──
  // Tails the trigger-written change feed and emits ordered delta packets;
  // rows load through the SAME wire mappers the snapshot watches use.
  final syncFeed = SyncFeedService(
    workspaces: workspaceDbs,
    loaders: {
      // Each loader receives the workspace the change came from, and that
      // workspace picks the database file — so the "does this row actually
      // belong to `ws`?" checks these loaders used to make are now answered by
      // which file was opened.
      'tickets': (ws, pk, ctx) async {
        final t = await ticketRepository.getById(ws, pk);
        return t == null ? null : ticketToWire(t);
      },
      'channels': (ws, pk, ctx) async {
        final c = await messagingRepository.getChannelById(ws, pk);
        return c == null ? null : channelToWire(c);
      },
      'channel_messages': (ws, pk, ctx) async {
        final m = await messagingRepository.getMessageById(ws, pk);
        return m == null ? null : messageToWireLite(m);
      },
      'channel_participants': (ws, pk, ctx) async {
        if (ctx == null) {
          return null;
        }
        final participants = await messagingRepository.getParticipants(ws, ctx);
        for (final p in participants) {
          if (p.id == pk) {
            return channelParticipantToWire(p);
          }
        }
        return null;
      },
      'channel_notes': (ws, pk, ctx) async {
        if (ctx == null) {
          return null;
        }
        final note = await workspaceDbs
            .of(ws)
            .channelExtrasDao
            .noteForChannel(ws, ctx);
        return (note == null || note.id != pk) ? null : channelNoteToWire(note);
      },
      'message_reactions': (ws, pk, ctx) async {
        final wsDb = workspaceDbs.of(ws);
        final row = await (wsDb.select(
          wsDb.messageReactionsTable,
        )..where((t) => t.id.equals(pk))).getSingleOrNull();
        return row == null ? null : reactionToWire(row);
      },
    },
  )..start();
  // The headless server owns the FULL newsfeed surface (DB reads + RSS
  // fetch/refresh/feed-management) via the same repository the desktop uses,
  // composing the cc_infra RSS fetcher with the cc_persistence RSS DAO.
  final newsfeedRepository = DaoNewsfeedRepository(
    globalDb.rssDao,
    RssFetcherService(createDio()),
    // Feeds without a channel image fall back to the site HTML's
    // <link rel="icon"> (e.g. lea.verou.me).
    siteIcons: SiteIconResolver(createDio()),
  );

  final agentRepository = DaoAgentRepository(workspaceDbs);
  final agentRunLogRepository = DaoAgentRunLogRepository(workspaceDbs);
  // Per-run activity timelines (subagent runs above all). Kept in its own table
  // so the run-log list watches never ship the fat segment payload.
  final runTranscriptRepository = DaoRunTranscriptRepository(workspaceDbs);
  final repoRepository = DaoRepoRepository(workspaceDbs);
  final channelReadRepository = DaoChannelReadRepository(workspaceDbs);
  final memoryDomainRepository = DaoMemoryDomainRepository(workspaceDbs);
  final memoryAccessGrantRepository = DaoMemoryAccessGrantRepository(
    workspaceDbs,
  );
  final agentWorkingMemoryRepository = DaoAgentWorkingMemoryRepository(
    workspaceDbs,
  );
  // PRD 04 memory-intelligence repos (conflict, semantic graph, hot tier,
  // harmonized beliefs).
  final memoryConflictRepository = DaoMemoryConflictRepository(workspaceDbs);
  final episodicEdgeRepository = DaoEpisodicEdgeRepository(workspaceDbs);
  final workingMemoryItemRepository = DaoWorkingMemoryItemRepository(
    workspaceDbs,
  );
  final memoryBeliefRepository = DaoMemoryBeliefRepository(workspaceDbs);
  final memoryFactRepository = DaoMemoryFactRepository(
    workspaceDbs,
    // Facts are embedded on write and searched semantically once the embedding
    // model is installed; until then `SearchMemoryTool` degrades to keyword.
    embeddingService: embeddingService,
  );
  final memoryPolicyRepository = DaoMemoryPolicyRepository(workspaceDbs);
  final providerPolicyRepository = DaoProviderPolicyRepository(workspaceDbs);

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
  final reviewChannelRepository = DaoReviewChannelRepository(workspaceDbs);
  final isolatedRepoRepository = DaoIsolatedRepoRepository(workspaceDbs);
  final voiceProfileRepository = DaoVoiceProfileRepository(workspaceDbs);
  final meetingRepository = DaoMeetingRepository(workspaceDbs);
  final ticketLinkRepository = DaoTicketLinkRepository(workspaceDbs);
  final pipelineRunRepository = PipelineRunRepositoryImpl(
    workspaceDbs,
    globalDb.workspaceRouteDao,
  );
  final pipelineTemplateRepository = PipelineTemplateRepositoryImpl(
    workspaceDbs,
  );
  final pipelineTriggerRepository = PipelineTriggerRepositoryImpl(
    workspaceDbs,
    globalDb.workspaceRouteDao,
  );
  final teamRepository = TeamRepositoryImpl(workspaceDbs);
  final orchestrationRepository = DaoOrchestrationRepository(workspaceDbs);
  final workspaceRepository = DaoWorkspaceRepository(
    globalDb.workspaceRegistryDao,
    workspaceDbs,
  );
  // Calendar (workspace-scoped reads via the workspace clause). Only the READ
  // surface is exposed over RPC; the write path (account connect/disconnect,
  // RSVP, the sync reconciler, the alert sweep, meeting linking) depends on the
  // host-resident OAuth tokens + Google API client, so it is never reached here.
  final calendarRepository = DaoCalendarRepository(workspaceDbs);
  // The server owns the Google Calendar connection: the device-code GUI connect
  // (`calendar.*Connect` ops) + the periodic per-workspace sync, over one shared
  // credential store under the data dir. Clients just READ the synced events.
  final serverCalendar = buildServerCalendar(
    calendarRepository: calendarRepository,
    workspaceRepository: workspaceRepository,
    eventBus: eventBus,
    dataDir: config.dataDir,
    // The OAuth client behind "use Control Center's Google app". Stays inside
    // the server: no RPC response carries it, and a connection made with it
    // stores a marker instead of the pair.
    serverClient: GoogleOAuthClient.fromConfig(config),
  );

  // Live weather (Open-Meteo, keyless) + the server-side generative soundscape
  // engine. The hub reads the workspace's location/conditions from the weather
  // service, folds in the daypart, and streams generated MP3 audio to thin
  // clients over the `/soundscape/*` HTTP routes. No network degrades to a
  // default context. The MP3 encoder dylib does NOT degrade — it is boot-required
  // (the preflight above), so `streamFor` throws on a broken install instead of
  // 404ing a feature the host is supposed to have; the routes still 404 for the
  // behavioural cases (hub disposed, session cap reached).
  final weatherService = ServerWeatherService(
    client: WeatherApiClient(),
    dataDir: config.dataDir,
  );
  // The selectable font catalogue (`fonts.list` + `/proxy/font`). The host owns
  // this because clients cannot: font upstreams pick their format from the
  // request's `User-Agent`, serving browsers `woff2`, which Skia cannot decode —
  // and a browser `fetch()` cannot override that header. Offline or upstream-
  // down leaves an empty catalogue, and the picker keeps its bundled + system
  // fonts.
  final fontCatalog = FontsourceCatalogService(
    cacheFilePath: p.join(config.dataDir, 'font_catalog.json'),
  );
  final soundscapeHub = SoundscapeHub(
    weather: weatherService,
    // Resolve the libmp3lame dylib from the same app-support root the other
    // natives use (dev), falling back to the release bundle — otherwise the
    // encoder is never found in dev and audio silently 404s.
    encoderLibraryPaths: CcPaths(config.dataDir).lameFfiDylibCandidatePaths(),
  );

  // GitHub client authenticated from the server's `gh` CLI (the host owns auth;
  // thin clients hold no token). `gh auth token` is read once at boot via the
  // PATH-robust resolver in [ProcessGitHubCliService] (a GUI-spawned subprocess
  // inherits a minimal PATH; the resolver probes Homebrew/Nix/etc.). When no
  // token is available the client stays token-less and the PR surface degrades
  // to "connect GitHub on the server" rather than failing.
  final ghStatus = await _bootStep(
    'probing gh CLI auth',
    () => ProcessGitHubCliService().probe(),
  );
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
    workspaceDbs,
    serverGitHubClient,
    eventBus: eventBus,
  );

  // Activity log (workspace-scoped audit trail). The headless server owns the
  // Drift `activity_log` DAO, so it serves the `activity.watchForEntity`
  // subscription (the client's entity-timeline view) over this read-only reader.
  final activityLogReader = DaoActivityLogReader(workspaceDbs);

  // The MCP agent-tool surface the server exposes via tools/list + tools/call.
  // Built before the catalog so the SHARED dispatcher backs both the RPC server
  // and the MCP HTTP server (one tool registry, two transports), and the
  // control surface the `mcp.*` catalog ops drive can be wired in.

  // Ticket relation service (blocked_by / sub-issue / duplicate links) backing
  // the typed `link_tickets` / `unlink_tickets` / `list_ticket_relations`
  // tools registered post-construction below.
  final ticketLinkService = TicketLinkService(
    linkRepository: ticketLinkRepository,
    ticketRepository: ticketRepository,
  );

  // Per-conversation mode guard, built ONCE and shared: the dispatcher enforces
  // it, and the discovery tools (`search_tool_bm25`, `list_my_tools`) read it to
  // report which tools are callable in the caller's conversation mode. The
  // conversation is resolved server-side (channel mode, or the agent's active
  // run), so it cannot be spoofed by omitting `channel_id`.
  final mcpModeGuard = ModeToolGuard(
    DbModeResolver(workspaceDbs),
    runLogs: agentRunLogRepository,
  );

  // Per-conversation todo store — shared by the MCP `todo_write` tool (below)
  // and the `todos.*` RPC ops (further down). Constructed once.
  final todoRepository = DaoTodoRepository(workspaceDbs);

  // Durable per-workspace notification feed + per-user read marks. Written
  // ONLY by the recorder below (one bus subscription, one row per event —
  // never per connected device); clients watch it over `notifications.*`.
  final notificationFeedRepository = DaoNotificationFeedRepository(
    workspaceDbs,
  );
  final notificationFeedRecorder = NotificationFeedRecorder(
    eventBus: eventBus,
    repository: notificationFeedRepository,
  )..start();

  final mcpRegistry = buildServerMcpRegistry(
    globalDb: globalDb,
    workspaceDbs: workspaceDbs,
    newsfeedRepository: newsfeedRepository,
    ticketRepository: ticketRepository,
    messagingRepository: messagingRepository,
    todoRepository: todoRepository,
    // Pipeline structured-output contract (submit_output writes outputJson).
    agentRunLogRepository: agentRunLogRepository,
    schemaValidator: const JsonSchemaValidator(),
    // Shared with the dispatcher below so discovery tools report per-mode
    // callability with the exact rules the dispatcher enforces.
    modeGuard: mcpModeGuard,
    // Lets `publish_artifact` announce itself on the event bus alongside the
    // typed `artifact` channel message it posts.
    eventBus: eventBus,
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
      workspaceDbs,
      embeddingService: embeddingService,
    ),
    // Verifies indexed paths against the tree the caller actually reads (the
    // conversation's isolated copy when conversation-scoped), so a drifted
    // index can't hand an agent a path that no longer exists.
    codeGraphTree: CodeGraphTreeService(
      repoRepository: repoRepository,
      workspaceRepository: workspaceRepository,
      isolatedRepoRepository: isolatedRepoRepository,
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
  // Human-in-the-loop approvals for privileged agent actions (destructive
  // shell commands, approval-gated MCP tools). The SERVER has no local GUI, so
  // every request is published to connected clients over
  // `confirmation.watchPending` and resolved by `confirmation.respond`. The
  // registry has NO timeout — an approval-gated action blocks the agent
  // indefinitely until the user approves or denies (never silently auto-denied).
  // The SAME instance backs the MCP dispatcher, the harness/dispatch path, and
  // the RPC catalog, so all pending approvals surface in one place. Without this
  // the fail-closed paths deny every gated action outright.
  final pendingConfirmationRegistry = PendingConfirmationRegistry();
  final confirmationPort = RemoteConfirmationPort(pendingConfirmationRegistry);
  // PRD 24: the unified action-guardrail resolver + gate. Resolves an
  // agent-initiated effect against the workspace/channel/agent policy store
  // (channel > agent > workspace > mode preset > default) and gates it through
  // the SAME ConfirmationPort (fail-closed). Injected into the MCP dispatcher
  // below so external-CLI adapters' tool calls hit the same policy as the
  // harness; the command net + sandbox floor remain the other layers.
  final actionPolicyRepository = DaoActionPolicyRepository(workspaceDbs);
  final actionGuard = ActionGuardService(
    repository: actionPolicyRepository,
    confirmationPort: confirmationPort,
    onAudit: (a) {
      if (a.decision == ActionDecision.deny) {
        CcHostLog.info(
          'guardrail deny [${a.source}] ${a.actionSummary}: ${a.reason}',
        );
      }
    },
  );
  final mcpDispatcher = McpToolDispatcher(
    registry: mcpRegistry,
    confirmationPort: confirmationPort,
    actionGuard: actionGuard,
    // Per-conversation mode enforcement (review / plan / orchestrate tool
    // allow-lists). Without this the headless server would let an agent in
    // plan mode call mutating tools — the gate must run where the tools run.
    // Same instance the registry's discovery tools read, so "can I call this?"
    // and "you can't call this" always agree.
    modeGuard: mcpModeGuard,
    // Re-expose external servers' resources/prompts through CC's MCP server.
    resourceProvider: mcpClientService.resourceProvider,
    promptProvider: mcpClientService.promptProvider,
  );

  // The headless server runs its OWN MCP surface (real desktop/web parity):
  // the `mcp.*` ops the web settings section calls resolve to this control,
  // which owns the MCP request handler over the shared dispatcher and persists
  // its config under the data dir. The handler is mounted on the main RPC
  // listener below (single port), so no separate MCP port is bound.
  final mcpControl = ServerMcpControl(
    dispatcher: mcpDispatcher,
    dataDir: config.dataDir,
  );
  // Make the advertised `tools.listChanged: true` capability real: every
  // registry mutation (external MCP servers bridged in via setDynamicTools,
  // post-boot register() calls like the skill tools below) fans
  // `notifications/tools/list_changed` out to connected SSE clients so they
  // re-list instead of serving a stale cache forever.
  mcpRegistry.onToolsChanged = mcpControl.notifyToolsChanged;

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

  // Content-addressed skill bundles (PRD 10): register the install/verify/pin
  // tools now that the filesystem + GitHub client exist (the registry was built
  // earlier from DB-only deps). `register` is safe post-construction.
  // PRD 23: the mandatory, fail-closed supply-chain scan gate. Layers 1-2 run
  // inline (pure, execution-free); results cache by content hash so identical
  // bytes are never re-scanned. Layer 3 (the budgeted, inert LLM reviewer) is
  // attached below once the harness provider deps exist — it can only TIGHTEN a
  // passing static verdict, and a provider outage fails open for Layer 3 only
  // (Layers 1-2 stay the fail-closed gate). Injected into the bundle service +
  // create_skill so no origin writes unscanned content.
  final skillScanner = SkillScannerAdapter(
    scanner: const SkillScanner(),
    cache: DaoSkillScanRepository(workspaceDbs),
  );
  // PRD 23 §1: the skills.sh registry (server dials it; clients browse over the
  // `skills.*` RPC ops). All metadata is untrusted — only the content hash CC
  // computes over the fetched bytes is trusted, and every install still passes
  // the mandatory scan gate.
  final skillRegistry = SkillsShRegistryAdapter(
    createDio(baseUrl: skillsShApiBaseUrl),
  );
  final skillBundles = SkillBundleService(
    filesystem: workspaceFilesystem,
    scanner: skillScanner,
    registry: skillRegistry,
    // PRD 23 §2 ties PRD 24: resolve a skill's declared capabilities against
    // the workspace action policy at install, before write.
    actionGuard: actionGuard,
    fetchGitHubFile:
        ({
          required String owner,
          required String repo,
          required String path,
          required String ref,
        }) => serverGitHubClient.content.getFileContent(owner, repo, path, ref),
    // PRD 23 §4 update-check: resolve latest upstream commit + default branch.
    latestCommit:
        ({
          required String owner,
          required String repo,
          required String path,
          String? branch,
        }) => serverGitHubClient.content.getLatestCommitSha(
          owner,
          repo,
          path,
          branch: branch,
        ),
    defaultBranch: ({required String owner, required String repo}) =>
        serverGitHubClient.pr.getDefaultBranch(owner, repo),
  );
  mcpRegistry
    ..register(InstallSkillTool(bundles: skillBundles))
    ..register(VerifySkillsTool(bundles: skillBundles))
    ..register(PinSkillTool(bundles: skillBundles))
    // PRD 23 §4 update flow: check for upstream updates (read) + apply one
    // through the FULL scan gate (approval-gated, re-pins with rollback hash).
    ..register(ListSkillUpdatesTool(bundles: skillBundles))
    ..register(UpdateSkillTool(bundles: skillBundles))
    // Previously defined but unregistered — wired now behind the same scan gate
    // (create_skill runs the lighter Layers 1-2 gate on save; list_skills is a
    // read).
    ..register(
      CreateSkillTool(filesystem: workspaceFilesystem, scanner: skillScanner),
    )
    ..register(ListSkillsTool(filesystem: workspaceFilesystem));

  // ── Live PR freshness plumbing ──
  // One shared change-signal bus: the pollers below (and PR mutations) publish
  // into it, and every open `pr_review.watch*` stream re-validates on a signal
  // — that is what pushes GitHub-side changes to connected clients without a
  // refresh button. Webhooks are deliberately not the transport here: this
  // server may run with no public URL/tunnel at all, so polling with
  // conditional requests is the universal baseline.
  final prChangeSignals = PrChangeSignals();
  final openPrFetchAdapter = ghToken.isEmpty
      ? null
      : GitHubOpenPrFetchAdapter(serverGitHubClient);
  final openPrPoller = openPrFetchAdapter == null
      ? null
      : OpenPrPollingService(
          fetchPort: openPrFetchAdapter,
          workspaceRepository: workspaceRepository,
          workspaceDbs: workspaceDbs,
          changeSignals: prChangeSignals,
          prToWire: pullRequestToWire,
          eventBus: eventBus,
        );

  // Authenticated PR-review host: wired only when the server holds a gh token.
  // Lights up the `pr_review.*` detail/diff/comment ops over RPC (a thin client
  // reads them; previously these surfaced an empty repository). The local-git
  // diff source backs the >3000-file fallback and runs `git` on the server's
  // own checkout. A null rift client means "no CoW seeding wired here, use a
  // network clone" — distinct from a rift client whose dylib will not load,
  // which is a broken install and throws (see `PrCloneManager._tryRiftCopy`).
  final serverVcsFactory = ghToken.isEmpty
      ? null
      : GitHubVcsProviderFactory(
          workspaceDbs: workspaceDbs,
          gitHubClient: serverGitHubClient,
          localGitSource: LocalGitPrDiffSource(
            git: const ProcessGitCommandAdapter(),
            filesystem: workspaceFilesystem,
            githubToken: ghToken,
          ),
          eventBus: eventBus,
          changeSignals: prChangeSignals,
        );

  _bootMark('wiring agent executor + tool surface');
  // ── Agent executor (pure-Dart) ──
  // The headless server runs agents itself now that the dispatch engine is
  // Flutter-free: `claude -p` (and the other CLIs) are spawned through the
  // sandboxed dispatch session, and AgentStreamProcessor persists streamed
  // segments onto the message rows connected clients already watch
  // (`messaging.watchMessages`) — so a web/thin client's "send + dispatch"
  // reply streams in with no extra infra. Credentials come from the server's
  // environment (no OS keychain).
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
  // When a GitHub App is configured (GITHUB_APP_ID + GITHUB_APP_PRIVATE_KEY +
  // GITHUB_APP_INSTALLATION_ID), mint fine-grained, repo-scoped, ~1h
  // installation tokens per sandbox launch instead of handing agents the raw
  // PAT (§1.1/1.2). Absent/incomplete config falls back to the plain
  // env-PAT broker — identical to prior behaviour.
  final githubAppConfig = GitHubAppConfig(
    appId: Platform.environment['GITHUB_APP_ID'] ?? '',
    privateKeyPem: Platform.environment['GITHUB_APP_PRIVATE_KEY'] ?? '',
    installationId: Platform.environment['GITHUB_APP_INSTALLATION_ID'] ?? '',
  );
  final CredentialBrokerPort credentialBroker = githubAppConfig.isComplete
      ? GitHubFineGrainedTokenBroker(
          serverCredentials,
          minter: GitHubAppTokenMinter(
            dio: createDio(baseUrl: 'https://api.github.com'),
            config: githubAppConfig,
          ),
        )
      : EnvCredentialBroker(serverCredentials);
  // Server-owned LLM provider credential store (the "brain"): UI-saved API keys
  // and OAuth tokens persist to a 0600 JSON file under the data dir, with the
  // process environment as a read-only fallback. The SAME instance backs both
  // the harness dispatch and the `providers.*` RPC ops so a key saved over RPC
  // is immediately usable by a dispatched agent.
  final harnessCreds =
      harnessCredentialStore ??
      CompositeProviderCredentialStore([
        FileProviderCredentialStore(dataDir: config.dataDir),
        EnvProviderCredentialStore(),
      ]);
  // Server-owned OAuth broker: runs the browser-login flows (PKCE + loopback),
  // persists tokens into the same credential store, and refreshes them before
  // expiry for dispatched harness runs.
  // `dataDir` lets device-code flows (Kimi Code) keep a stable device identity
  // across restarts instead of re-registering as a new device every launch.
  final harnessOAuthBroker = HarnessOAuthBroker(
    store: harnessCreds,
    dataDir: config.dataDir,
  );
  // Bundled models.dev catalog for the built-in harness: supplies per-model
  // reasoning support (effort clamping), USD pricing, and context-window size.
  ModelCatalog harnessModelCatalog;
  final catalogStartedAt = DateTime.now();
  _bootMark('loading harness model catalog');
  try {
    harnessModelCatalog = ModelCatalog.fromModelsDev(
      (await InMemoryModelsDevSource().load())!,
    );
  } on Object catch (e) {
    CcHostLog.warning('cc_server: harness model catalog load failed: $e');
    harnessModelCatalog = ModelCatalog.empty;
  }
  _bootDone('loading harness model catalog', catalogStartedAt);
  // PRD 23 Layer 3: attach the budgeted, inert LLM reviewer to the scan gate now
  // that the provider deps exist. It picks the cheapest recent model, runs one
  // tool-less completion with a hard timeout, and only tightens a passing
  // verdict. A provider outage throws → the adapter keeps the static verdict.
  skillScanner.llmReview = SkillLlmReviewRunner(
    credentials: harnessCreds,
    catalog: harnessModelCatalog,
    refresher: harnessOAuthBroker,
  ).review;
  // fff (Rust) powers every fuzzy file search on this server — the Explorer's
  // search (RepoIdeDataService below) and the harness `read`/`file_search`
  // tools share this one instance, so its per-root scan caches are warm across
  // surfaces. It resolves `libfff_c` from the server's data dir or the
  // bundle's `lib/` (where the build hook ships it). The native is REQUIRED
  // (the boot preflight above refused to start without it); a load failure at
  // search time surfaces as an RPC error, never a silent pure-Dart degrade.
  // The unfiltered Explorer tree still uses the cached Dart walk (fff has no
  // list-all surface — a functional gap, not a fallback).
  final ideFileSearch = FffFileSearch(
    appSupportRoot: () async => Directory(config.dataDir),
    onLog: (tag, message, [error, stackTrace]) => CcHostLog.info(
      'cc_server file-search[$tag]: $message${error == null ? '' : ' ($error)'}',
    ),
  );
  // In-flight transcript lane, shared by channel turns (keyed by message id) and
  // subagent runs (keyed by run id). Constructed here rather than next to the
  // relay wiring below because the dispatch adapter's subagent recorder needs it.
  final streamRegistry = ActiveStreamRegistry();
  final agentDispatch = SandboxedAgentDispatchAdapter(
    sandbox: NoSandboxAdapter(),
    credentialBroker: credentialBroker,
    // The harness `read` (did-you-mean on missing paths) + `file_search`
    // tools run on the same fff engine as the Explorer search.
    fileSearch: CcNativesFileSearchPort(fileSearch: ideFileSearch),
    // UAC approvals for prompt-tier commands + escalations, threaded to the
    // harness/dispatch session. Shares the registry above so the harness path
    // and MCP tools surface approvals through the same client-facing queue;
    // without it the dispatch path fails closed and denies gated actions.
    confirmationPort: confirmationPort,
    // Unified action guardrails (PRD 24 §3): the SAME guard the MCP + repo-op
    // dispatchers use now gates the BUILT-IN harness loop by declared effect
    // class — the path bridged MCP tools take (they bypass the MCP dispatcher).
    actionGuard: actionGuard,
    agentRepository: agentRepository,
    runLogRepository: agentRunLogRepository,
    // `/goal` records the invocation as the conversation's working goal so the
    // General pane shows it as the accordion the todos nest beneath.
    todoRepository: todoRepository,
    // Subagent activity timelines: the child loop's events fold into transcript
    // segments streamed under the CHILD run id (same registry a parent turn
    // uses, so the relay and client renderers work unchanged) and flushed to
    // `run_transcripts` for replay after the run ends.
    runTranscriptRecorder: RunTranscriptRecorder(
      registry: streamRegistry,
      repo: runTranscriptRepository,
      onWarn: (message) => CcHostLog.info('cc_server run-transcript: $message'),
    ),
    eventBus: eventBus,
    // Per-channel autonomy dial (PRD 16 §12): consulted by the harness's
    // approval gate — proposeOnly denies gated tools, actFreely pre-approves,
    // unset/actWithApproval keeps the fail-closed gate.
    autonomyResolver: (workspaceId, channelId, agentId) async {
      final row = await workspaceDbs
          .of(workspaceId)
          .channelExtrasDao
          .autonomyFor(workspaceId, channelId, agentId);
      return row?.autonomyLevel;
    },
    // Built-in harness (AdapterTransport.harness): expose CC's MCP tools to
    // the agent loop as first-class tools, and resolve LLM provider keys from
    // the server-owned credential store (UI-saved keys/OAuth + env fallback).
    mcpRegistry: mcpRegistry,
    harnessCredentialStore: harnessCreds,
    harnessCredentialRefresher: harnessOAuthBroker,
    modelResolver: harnessModelCatalog.resolve,
    // Git authorship (PRD 14 §14): resolve the requesting human's git
    // identity for the commit co-author trailer. A null userId means no
    // acting human was threaded (programmatic dispatch) — attribute to the
    // server owner rather than dropping the credit.
    resolveGitIdentity: (userId) async {
      final user = await userRepository.getById(
        userId == null || userId.isEmpty ? ownerUserId : userId,
      );
      if (user == null) {
        return null;
      }
      return (
        name: user.effectiveGitAuthorName,
        email: user.effectiveGitAuthorEmail,
      );
    },
    // Per-user GitHub credentials (PRD 14 §10): a member-requested run uses
    // the member's own stored token instead of the owner's broker credential.
    resolveUserGitHubToken: userCredentials.gitHubToken,
    // Original repo checkouts become sandbox deny-write rules in every mode:
    // agents only ever write in their per-conversation CoW worktrees, and the
    // registered checkout (`repos.path`) stays untouchable even under macOS
    // Seatbelt's blanket `$HOME` write allowance.
    protectedPathsResolver: (workspaceId) async {
      final repos = await workspaceRepository
          .watchReposForWorkspace(workspaceId)
          .first;
      return [for (final r in repos) r.path];
    },
    // Point the spawned `claude` at THIS server's own loopback MCP HTTP
    // endpoint so server-run agents get the `mcp__*` tool surface — crucially
    // `submit_output`, which writes a pipeline run's structured output so the
    // step resume listener can harvest it and advance. Without this, an
    // agent-dispatching pipeline step ends but fails harvest (no payload). The
    // resolver is per-session (called with the agent's cwd + identity scope):
    // it force-starts the loopback MCP server (idempotent, independent of the
    // user-facing enable toggle) and writes a fresh derived client config into
    // `<cwd>/.mcp.json` so a port/token change is always picked up, each
    // agent's config is isolated to its own overlay cwd, and the `X-CC-*`
    // scope headers pin the session to its workspace server-side.
    mcpConfigPathResolver: (cwd, {workspaceId, agentId, conversationId}) async {
      await mcpControl.ensureRunningForDispatch();
      // `.absolute` guards against a relative cwd reaching the spawned agent:
      // `claude` resolves `--mcp-config` against ITS cwd, so a relative path
      // would double (`<cwd>/<relative>/.mcp.json` → not found).
      return mcpControl.writeAgentMcpConfig(
        File('$cwd/.mcp.json').absolute,
        workspaceId: workspaceId,
        agentId: agentId,
        conversationId: conversationId,
      );
    },
  );
  // Dispatch-time prompt context (memory preamble + conversation history) and
  // the conversation-mode resolver, so server-run agents get the same context
  // on every host that embeds this runtime.
  // The on-device [embeddingService] backs semantic ranking of both the memory
  // shortlist and conversation history once the model is installed; it degrades
  // to keyword/verbatim (guarded by `isReady`) until then.
  final conversationModeResolver = DbModeResolver(workspaceDbs);
  final memoryContextUseCase = BuildMemoryContextUseCase(
    policyRepository: memoryPolicyRepository,
    workingMemoryRepository: agentWorkingMemoryRepository,
    factRepository: memoryFactRepository,
  );
  final conversationContextUseCase = BuildConversationContextUseCase(
    messagingRepository: messagingRepository,
    embeddingPort: embeddingService,
  );
  // ONE rift registry for every managed copy on this host — conversation
  // worktrees and PR worktrees alike. It has to be one file: rift's marker lives
  // in the SOURCE repo (`<repo>/.rift`) and names an entry id, so a second
  // registry looking at the same repo sees a marker it doesn't know
  // (`marker_mismatch` / `unknown_marker`) and every provision for that repo
  // degrades to `git worktree`. Two registries meant whichever surface reached a
  // repo first silently locked the other one out of copy-on-write.
  final riftClient = RiftClient(
    dylibPaths: nativeLibraryCandidates(
      'rift_ffi',
      appSupportRoot: config.dataDir,
    ),
    databasePath: paths.riftRegistryPath(),
  );
  final repoIsolation = RiftRepoIsolationAdapter(
    rift: riftClient,
    git: const ProcessGitCommandAdapter(),
  );
  // Per-conversation worktree + per-agent overlay provisioning. WITHOUT this
  // the dispatch service falls back to the agent's global dir, so no
  // `conversations/<channelId>/agents/<slug>/` overlay is built and the derived
  // `.mcp.json` lands in the wrong place. rift copy-on-write worktrees are
  // ENABLED: the dylib is resolved from the same app-support locations
  // (`CC_NATIVE_LIB_DIR` / data dir / bundle) the other natives use, so CoW
  // engages when `rift_ffi` is present and degrades to a plain `git worktree`
  // fallback only when it is genuinely absent. The Drift `isolatedRepoRepository`
  // is the shared, canonical worktree registry (rows keyed per conversation/PR).
  final conversationProvisioner = RepoWorkspaceProvisioner(
    filesystem: workspaceFilesystem,
    isolation: repoIsolation,
    registry: isolatedRepoRepository,
    workspaces: workspaceRepository,
    githubToken: () async => ghToken.isEmpty ? null : ghToken,
    // The workspace's own branch-name convention, read from its settings
    // store. This used to be hardcoded to the built-in default, so the
    // template configured in the UI had never reached the only code that
    // consumes it — the setting was inert, not merely device-local.
    branchTemplate: (workspaceId) async =>
        await workspaceSettingsRepository.get(workspaceId, 'branch_template') ??
        BranchTemplateResolver.defaultTemplate,
    // Lets the cleanup sweep reclaim worktrees (and conversation folders) whose
    // channel is gone. `ChannelDeleted` handles the live path; this catches the
    // ones it missed — server down at deletion time, or a row removed directly.
    channelExists: (workspaceId, channelId) async =>
        await messagingRepository.getChannelById(workspaceId, channelId) !=
        null,
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
    // Builds the per-agent overlay cwd (AGENTS.md + .agents + repos symlinks)
    // under `conversations/<channelId>/agents/<slug>/`; degrades to the agent
    // dir when no workspace/channel is in play.
    repoProvisioner: conversationProvisioner,
    // Process-global agent registry — tracks live subagents on the headless
    // server so the work-aware roster is populated there too.
    registry: AgentRegistryImpl.global(),
    // Heal the dispatched agent's global skill links at dispatch time so the
    // per-agent overlay's `.agents` symlink resolves the current skill set.
    filesystemPort: workspaceFilesystem,
    // Serialize same-working-directory dispatches (path-lock queue →
    // `waiting_local_directory`); per-conversation worktree isolation means
    // contention is rare, so this acquires instantly in the common case.
    pathLock: PathLockManager(),
    eventBus: eventBus,
    // Per-adapter launch argv + env from the install-wide settings store.
    // This callback existed but was never passed here, so the adapter args and
    // env overrides configured in settings reached nothing — editing them was
    // a no-op. Server-scoped because argv is executed on THIS host.
    adapterLaunchOverrides: (adapterId) async {
      final args = await serverSettingsRepository.get(
        'adapter_args_$adapterId',
      );
      final env = await serverSettingsRepository.get('adapter_env_$adapterId');
      return (
        args: _splitAdapterArgs(args),
        env: _decodeAdapterEnv(env),
      );
    },
  );
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
  // Durable goal supervisor (`/goal`, `/loop`): persists each objective in
  // SQLite and keeps dispatching bounded runs until the agent calls
  // `complete_goal`, a human stops it, or a budget wall hits. Declared `late`
  // because the goal command handler wired into MessagingService routes into
  // it, while its own dispatcher callback is MessagingService's dispatch.
  final agentGoalRunRepository = DaoAgentGoalRunRepository(workspaceDbs);
  late final GoalSupervisor goalSupervisor;
  final messagingService = MessagingService(
    messagingRepository,
    agentRepo: agentRepository,
    agentDispatchService: agentDispatchService,
    streamRegistry: streamRegistry,
    streamProcessor: agentStreamProcessor,
    eventBus: eventBus,
    // Forced out-of-band compaction (`/compact`) routes through the same
    // service the post-turn auto-maintenance uses.
    compactionService: conversationCompactionService,
    // Programmatic "user" messages (pipeline steps, team dispatch) with no
    // acting human are attributed to the server owner — never a sentinel.
    resolveDefaultUserId: () async => ownerUserId,
    // While a human holds a take-over on a conversation, new dispatches into
    // it are refused (PRD 16 §8 — no auto-resume into a half-finished edit).
    dispatchBlocked: (workspaceId, channelId) async =>
        await takeoverHolder.value?.isActive(workspaceId, channelId) ?? false,
    // Human `@handle` mention resolution (PRD 16 §15): joins the workspace's
    // membership rows to their user records so `sendAndDispatch` can match
    // any `@token` that isn't an agent against a real teammate.
    listMembers: (workspaceId) async {
      final members = <MentionableMember>[];
      for (final m in await membershipRepository.getForWorkspace(workspaceId)) {
        final user = await userRepository.getById(m.userId);
        if (user != null) {
          members.add((
            id: user.id,
            handle: user.handle,
            displayName: user.displayName,
          ));
        }
      }
      return members;
    },
    // Durable goals: a `/goal`/`/loop` prompt routes into the supervisor as a
    // persistent objective instead of a one-off dispatch. The slash-token
    // picks the kind; the body after it becomes the objective text.
    goalCommandHandler:
        ({
          required workspaceId,
          required channelId,
          required agentId,
          required prompt,
          conversationId,
          requestedByUserId,
        }) async {
          final trimmed = prompt.trimLeft();
          final kind = trimmed.startsWith('/loop')
              ? AgentGoalKind.loop
              : AgentGoalKind.goal;
          final split = trimmed.indexOf(' ');
          final userText = split < 0 ? '' : trimmed.substring(split + 1).trim();
          if (userText.isEmpty) {
            await messagingRepository.sendMessage(
              workspaceId: workspaceId,
              channelId: channelId,
              content:
                  'A goal needs an objective, e.g. '
                  '"${kind == AgentGoalKind.loop ? '/loop' : '/goal'} '
                  'keep the changelog current".',
              senderId: 'system',
              senderType: 'agent',
              messageType: 'system',
            );
            return null;
          }
          final goal = await goalSupervisor.startGoal(
            workspaceId: workspaceId,
            channelId: channelId,
            conversationId: conversationId ?? channelId,
            agentId: agentId,
            userText: userText,
            kind: kind,
            requestedByUserId: requestedByUserId,
          );
          // The first run's message id; null when the supervisor refused (it
          // narrates the refusal into the channel itself).
          return goal?.activeRunId;
        },
  );
  goalSupervisor = GoalSupervisor(
    goalRepository: agentGoalRunRepository,
    runLogRepository: agentRunLogRepository,
    eventBus: eventBus,
    // dispatchAgentRun, NOT dispatchAgent: the supervisor's first run
    // re-sends the verbatim `/goal ...` prompt, and dispatchAgent would
    // route it straight back into the goal command handler above — an
    // infinite refusal loop.
    dispatcher: messagingService.dispatchAgentRun,
    // Same message shape as the take-over refusal (senderId 'system',
    // senderType 'agent', messageType 'system').
    systemMessageSender:
        ({
          required workspaceId,
          required channelId,
          required content,
          conversationId,
        }) async {
          await messagingService.postSystemMessage(
            workspaceId,
            channelId,
            content,
            conversationId: conversationId,
          );
        },
  );

  // One shared per-pair rate limiter across the peer-messaging tools
  // (`send_to_agent`, `ask_agent`) so a burst that alternates between the two
  // still trips the same ordered-pair window (PRD 22 §3).
  final peerRateLimiter = PairRateLimiter();

  // ── Typed ticket WRITE tools ──
  // These replace the retired `ticket_cli` (CLI-args-in-JSON) surface with a
  // discoverable, schema-typed tool per verb. Registered post-construction
  // because they need the ticket workflow + link services and (for
  // `comment_on_ticket`) the messaging port, none of which exist when the
  // DB-only `buildServerMcpRegistry` runs. `register` fans a
  // `tools/list_changed` out to connected clients, same as the skill/read
  // tools above.
  mcpRegistry
    ..register(
      CreateTicketTool(service: ticketWorkflow, provider: TicketProvider.local),
    )
    ..register(
      UpdateTicketTool(service: ticketWorkflow, repository: ticketRepository),
    )
    ..register(DelegateTicketTool(service: ticketWorkflow))
    ..register(FailTicketTool(service: ticketWorkflow))
    ..register(AssignTicketTool(service: ticketWorkflow))
    ..register(ReassignTicketTool(service: ticketWorkflow))
    ..register(AddTicketCollaboratorTool(service: ticketWorkflow))
    ..register(CloseTicketTool(service: ticketWorkflow))
    ..register(LinkTicketToPrTool(service: ticketWorkflow))
    ..register(UnlinkTicketFromPrTool(service: ticketWorkflow))
    ..register(
      LinkTicketsTool(linkService: ticketLinkService, workflow: ticketWorkflow),
    )
    ..register(
      UnlinkTicketsTool(
        linkService: ticketLinkService,
        workflow: ticketWorkflow,
      ),
    )
    ..register(
      ListTicketRelationsTool(
        linkRepository: ticketLinkRepository,
        ticketRepository: ticketRepository,
      ),
    )
    ..register(
      CommentOnTicketTool(
        repository: ticketRepository,
        messagingPort: messagingService,
      ),
    )
    // ── Peer messaging & delegation (PRD 22) ──
    // Agent↔agent messaging (fire-and-forget + request/reply), guarded task
    // delegation, and the todo read-back half. The two peer-messaging tools
    // share one `PairRateLimiter`. `consult_agent` existed but was never
    // registered — wired in here beside its siblings.
    ..register(
      TodoReadTool(
        todoRepository: todoRepository,
        messagingRepository: messagingRepository,
      ),
    )
    ..register(
      SendToAgentTool(
        agents: agentRepository,
        messaging: messagingRepository,
        messagingPort: messagingService,
        rateLimiter: peerRateLimiter,
        eventBus: eventBus,
      ),
    )
    ..register(
      AskAgentTool(
        agents: agentRepository,
        messaging: messagingRepository,
        messagingPort: messagingService,
        rateLimiter: peerRateLimiter,
        eventBus: eventBus,
      ),
    )
    ..register(DelegateTaskTool(service: ticketWorkflow))
    ..register(
      ConsultAgentTool(
        agents: agentRepository,
        messaging: messagingRepository,
        messagingPort: messagingService,
      ),
    )
    // Durable goals (`/goal`, `/loop`): the agent-facing completion half of
    // the supervisor — `complete_goal` resolves the caller's one active goal
    // (the supervisor enforces one-per-agent) and declares it achieved.
    ..register(CompleteGoalTool(supervisionPort: goalSupervisor));
  // Background-provision a channel's conversation workspace (repo worktrees +
  // per-agent overlay + `.mcp.json`) at creation, so the first agent turn
  // doesn't pay the setup cost and the UI can show a "preparing" state. Runs
  // unawaited off the ChannelCreated event; message dispatch is gated on
  // the channel's provisioningStatus until this flips it to ready/failed.
  final channelProvisioningService = ChannelProvisioningService(
    provisioner: conversationProvisioner,
    writeMcpConfig: (cwd, {workspaceId, agentId, conversationId}) async {
      await mcpControl.ensureRunningForDispatch();
      await mcpControl.writeAgentMcpConfig(
        File('$cwd/.mcp.json').absolute,
        workspaceId: workspaceId,
        agentId: agentId,
        conversationId: conversationId,
      );
    },
    agentRepository: agentRepository,
    messagingRepository: messagingRepository,
    workspaceRepository: workspaceRepository,
    isolatedRepoRepository: isolatedRepoRepository,
    setProvisioningStatus: (workspaceId, channelId, status) => workspaceDbs
        .of(workspaceId)
        .messagingDao
        .updateChannelProvisioningStatus(channelId, status.toDbValue()),
    // Granular progress ("cloning repo X", "setting up agent Y"): written to
    // the channel row, so it rides the same live channel stream clients
    // already watch for the status. The status write clears it on ready/failed.
    setProvisioningStep: (workspaceId, channelId, step) => workspaceDbs
        .of(workspaceId)
        .messagingDao
        .updateChannelProvisioningStep(channelId, step.toDbValue()),
    // PR-review channels provision their repo at the PR head ref so chat /
    // terminal / file-edit all see the PR's proposed tree. Resolved from the
    // channel's review-channel association (newest wins).
    resolvePrContext: (workspaceId, channelId) async {
      final assoc = await reviewChannelRepository
          .watchByChannel(workspaceId, channelId)
          .first;
      if (assoc == null) {
        return null;
      }
      return (
        headRef: 'refs/pull/${assoc.prNumber}/head',
        repoFullName: assoc.repoFullName,
        branch: 'pr/${assoc.prNumber}',
      );
    },
    // Per-channel repo selection recorded at creation (empty → all repos).
    channelRepoIds: (workspaceId, channelId) => workspaceDbs
        .of(workspaceId)
        .channelRepoDao
        .repoIdsForChannel(workspaceId, channelId),
    // The same progress, announced for surfaces that watch events rather than
    // the channel row — the chat bridge reports it on its task card.
    eventBus: eventBus,
  );
  eventBus.on<ChannelCreated>().listen((e) {
    final workspaceId = e.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      // A channel with no workspace has no database file to live in, so there is
      // no row to flip — the event itself is the bug. Say so instead of writing
      // into an arbitrary workspace.
      CcHostLog.warning(
        'channel provisioning: ChannelCreated for ${e.channelId} carries no '
        'workspace; skipping (the channel row cannot be located)',
      );
      return;
    }
    unawaited(
      channelProvisioningService
          .provision(workspaceId: workspaceId, channelId: e.channelId)
          .catchError((Object err, StackTrace st) {
            CcHostLog.error(
              'channel provisioning: failed for ${e.channelId}: $err',
              err,
              st,
            );
            // Mark failed so the UI shows a retry affordance.
            workspaceDbs
                .of(workspaceId)
                .messagingDao
                .updateChannelProvisioningStatus(e.channelId, 'failed');
          }),
    );
  });
  // Channel-provisioning reconciler: re-kick channels a previous session left
  // stranded in `provisioning`. The ready/failed flip only ever comes from the
  // in-flight provisioning future, so a server exit mid-provision would
  // otherwise leave the channel behind an eternal "preparing workspace"
  // spinner — dispatch gated, no retry affordance (retry only shows on
  // `failed`). provision() is idempotent: existing worktrees are reused. One
  // best-effort sweep at boot, mirroring the orphan-run reaper.
  unawaited(() async {
    try {
      // CROSS-WORKSPACE BY DESIGN: a boot reconciler, so it visits every
      // workspace's database once. Each workspace's stranded channels are
      // resumed with that workspace's own id in hand.
      await crossWorkspace.forEachWorkspace((wsDb) async {
        final workspaceId = wsDb.workspaceId;
        final stranded = await wsDb.messagingDao.channelsByProvisioningStatus(
          'provisioning',
        );
        for (final row in stranded) {
          CcHostLog.info(
            'channel provisioning: resuming stranded channel ${row.id}',
          );
          unawaited(
            channelProvisioningService
                .provision(workspaceId: workspaceId, channelId: row.id)
                .catchError((Object err, StackTrace st) {
                  CcHostLog.error(
                    'channel provisioning: resume failed for ${row.id}: $err',
                    err,
                    st,
                  );
                  wsDb.messagingDao.updateChannelProvisioningStatus(
                    row.id,
                    'failed',
                  );
                }),
          );
        }
      });
    } on Object catch (e, st) {
      CcHostLog.error(
        'cc_server: stranded-channel provisioning sweep failed: $e',
        e,
        st,
      );
    }
  }());
  // Interactive terminal over RPC: a connected client runs a REAL shell on this
  // host (libccpty). Defaults to the host shell (no OS sandbox) on the headless
  // server; ownership is validated per op against the bound workspace.
  final terminalSessions = TerminalSessionService(
    manager: sandboxManager,
    filesystem: workspaceFilesystem,
  );

  // code-server (VS Code in the browser) over RPC: spawns/reuses a loopback-
  // bound code-server per conversation worktree, exposed through the
  // `/proxy/vscode/<sid>/` reverse proxy. The worktree is resolved strictly
  // from the caller's workspace via the isolated-repo registry; ownership is
  // validated per op. Managed install + shared extensions live under the data
  // dir; today `code-server` is expected on PATH (surfaced as `unavailable`
  // when absent — vendoring is wired in CI).
  final codeServerSessions = CodeServerService(
    isolatedRepos: isolatedRepoRepository,
    dataRoot: config.dataDir,
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

  _bootMark('resolving speech models');
  // ── Meeting transcription + diarization (server-side speech stack) ──
  // The headless server runs the SAME Flutter-free Whisper/sherpa stack the
  // desktop uses (cc_natives is pure Dart + FFI on a worker isolate). The
  // diarization service + model manager are always constructed — the
  // diarization models are force-installed at boot (see the model warm-up),
  // so diarization only no-ops while that first download is still in flight —
  // and the `meeting_summary` pipeline's `meeting.*` bodies can run. Recording
  // over RPC additionally needs an ASR model: resolve the user's SELECTED
  // model first, then fall back to whichever one is installed under the data
  // dir.
  final diarizationModelManager = DiarizationModelManager(paths: paths);
  MeetingRecordingService? meetingRecording;
  VoiceModelPaths? voicePaths;
  final selectedVoiceModel = VoiceModelInfo.byId(persistedVoiceModelId);
  for (final candidate in [
    selectedVoiceModel,
    ...VoiceModelInfo.all.where((m) => m.id != selectedVoiceModel.id),
  ]) {
    voicePaths = await VoiceModelManager(
      paths: paths,
      model: candidate,
    ).resolve();
    if (voicePaths != null) {
      break;
    }
  }
  // The diarization worker runs on a throwaway isolate that cannot see this
  // isolate's preferred-path static, so hand it the resolved path explicitly.
  final diarizationService = MeetingDiarizationService(
    libPath: inferenceLibPath,
  );
  // ── Agent PTY native (libccpty) ──
  // Backs the sandboxed terminal sessions (the `terminal.spawn` RPC body). Like rift/fff/tree-sitter, libccpty is a loose
  // runtime dylib — no Flutter ffiPlugin bundles it into this pure-Dart binary —
  // so point the PTY loader at the SAME data dir the other natives resolve from.
  // `Pty`'s default resolver only checks `$CC_PTY_DYLIB` + the binary's own
  // bundle layout (`<bundle>/lib`, `@executable_path/../Frameworks`), so on a
  // dev / headless deploy — where libccpty is dropped beside control_center.db
  // rather than embedded in the bundle — `terminal.spawn` would fail with
  // `PtyUnavailable` even though the dylib is present. Adding the data dir as the
  // app-support root closes that gap, mirroring fff/rift wiring.
  Pty.libraryResolver = () => tryOpenFirst(
    nativeLibraryCandidates(
      ptyLibraryBaseName,
      appSupportRoot: config.dataDir,
      envVar: ptyLibraryEnvVar,
    ),
  );
  // ── Native file watcher (libcc_watcher) ──
  // Backs the code-graph watch service's per-checkout watches. REQUIRED, like
  // the other natives: there is no `package:watcher` fallback, because its
  // per-arm full-tree scan (which cannot skip `node_modules`) is the 65s
  // startup freeze this native exists to remove — silently degrading to it
  // would be worse than refusing to boot. Same data-dir resolution as
  // pty/fff/rift; the preflight below fails when it cannot load.
  NativeDirectoryWatcher.libraryResolver = () => tryOpenFirst(
    nativeLibraryCandidates(
      watcherLibraryBaseName,
      appSupportRoot: config.dataDir,
      envVar: watcherLibraryEnvVar,
    ),
  );

  // Loading onnxruntime + probing every bundled dylib: the slowest purely
  // synchronous stretch of boot on a cold page cache.
  _bootMark('loading native libraries');
  // ── Native-library preflight (fail-fast, no degraded mode) ──
  // The natives ship INSIDE the server bundle (`apps/cc_server/hook/build.dart`
  // emits them as DynamicLoadingBundled code assets into `<bundle>/lib/`, the
  // same way libsqlite3 travels), so a miss here is a broken install — refuse
  // to boot rather than run with keyword-only search, dead terminals, an empty
  // code graph, or worktrees that silently stopped being copy-on-write. Only the
  // on-device MODELS are downloaded at runtime; every LIBRARY is required.
  //
  // Declared as a table (see `native_preflight.dart`) rather than inline
  // `Platform.isWindows` branches, because the same matrix is re-stated in
  // `scripts/release/verify_natives.sh` and `cc_server_package.sh` — keeping it
  // in one readable list is what makes those three auditable side by side.
  //
  // Built here (rather than at its use site further down) so a missing grammar
  // is caught at boot instead of on the first index run.
  final grammarManager = GrammarManager(
    dio: createDio(),
    grammarsDir: paths.grammarsRoot,
    onLog: (tag, message, [error, stackTrace]) =>
        CcHostLog.warning('grammar[$tag]: $message'),
  );
  final grammarsRoot = (await paths.grammarsRoot()).path;
  bool Function() dylibProbe(String baseName, {String? envVar}) =>
      () =>
          tryOpenFirst([
            // `build_tree_sitter.sh` installs into a `grammars/` subdir at dev time;
            // harmless for the others (a path that does not exist is skipped).
            p.join(grammarsRoot, platformLibraryFileName(baseName)),
            ...nativeLibraryCandidates(
              baseName,
              appSupportRoot: config.dataDir,
              envVar: envVar,
            ),
          ]) !=
          null;

  final missingNatives = await missingRequiredNatives([
    // ONE requirement for both ML workloads: the two dylibs (sherpa-onnx +
    // its own onnxruntime) and the embedder's SECOND onnxruntime all collapsed
    // into this single statically linked native.
    nativeRequirement(
      '${platformLibraryFileName(inferenceLibraryBaseName)} (semantic '
      'embeddings, meeting transcription, diarization, VAD, dictation)',
      () async => inferenceLibPath != null,
    ),
    nativeRequirement(
      '${platformLibraryFileName(ptyLibraryBaseName)} (sandboxed terminals)',
      () async => Pty.isAvailable,
    ),
    nativeRequirement(
      '${platformLibraryFileName(watcherLibraryBaseName)} (code-graph file '
      'watching)',
      () async => NativeDirectoryWatcher.isAvailable,
    ),
    nativeRequirement(
      '${platformLibraryFileName('fff_c')} (fuzzy file search)',
      () async => dylibProbe('fff_c')(),
    ),
    nativeRequirement(
      '${platformLibraryFileName('lame_ffi')} (soundscape MP3 encoding)',
      () async => dylibProbe('lame_ffi', envVar: 'LAME_FFI_DYLIB')(),
    ),
    // TODO(windows): rift has no MSVC copy-on-write backend, so
    // `scripts/release/windows_natives.sh` deliberately does not build it and
    // `git worktree` is the BACKEND there (not a degradation) — see
    // `RiftRepoIsolationAdapter.missingRiftIsExpected`. Drop this exemption once
    // a Windows CoW backend exists.
    nativeRequirement(
      '${platformLibraryFileName('rift_ffi')} (copy-on-write worktrees)',
      () async => dylibProbe('rift_ffi', envVar: 'RIFT_FFI_DYLIB')(),
      requiredOnWindows: false,
    ),
    nativeRequirement(
      '${platformLibraryFileName('tree-sitter')} (code graph indexing)',
      () async => dylibProbe('tree-sitter')(),
    ),
    // One entry per shipped grammar so the error names the exact missing dylib.
    // `kLanguageByExtension` IS the shipped set (the build script produces the
    // same list), which is why the indexer can treat an unresolvable language as
    // a broken install rather than finite coverage.
    for (final languageId in kLanguageByExtension.values.toSet())
      nativeRequirement(
        '${platformLibraryFileName('tree-sitter-$languageId')} '
        '($languageId code graph grammar)',
        () async => await grammarManager.resolve(languageId) != null,
      ),
  ]);
  if (missingNatives.isNotEmpty) {
    throw StateError(
      'cc_server: required native libraries are missing:\n'
      '  - ${missingNatives.join('\n  - ')}\n'
      'Looked in \$$nativeLibDirEnvVar, ${config.dataDir}, $grammarsRoot, and '
      'the server bundle. Stage them with scripts/natives/build_natives.sh and '
      'rebuild the server (`dart build cli` bundles build/natives into '
      '<bundle>/lib/), or drop the dylibs into the data dir. Refusing to boot '
      'with a degraded feature set.',
    );
  }

  SherpaOnnxTranscriber? meetingTranscriber;
  DictationService? dictationService;
  if (voicePaths != null) {
    // The web meeting recorder streams mic + system PCM16 to this service over
    // `meeting.ingestAudio`; it transcribes + appends segments the client
    // watches, and on stop fires the summary pipeline. Lazy worker-isolate init.
    final transcriber = meetingTranscriber = SherpaOnnxTranscriber(
      paths: voicePaths,
      libPath: inferenceLibPath,
    );
    meetingRecording = MeetingRecordingService(
      repository: meetingRepository,
      transcriber: meetingTranscriber,
      eventBus: eventBus,
      paths: paths,
      // Release the loaded ASR model (hundreds of MB of weights) once the
      // last live recording stops; the next recording reloads it lazily
      // while its first audio window buffers.
      onIdle: () => unawaited(transcriber.unload()),
    );
    // Composer voice dictation (PRD 25 §2) rides the SAME transcriber instance
    // as the meeting recorder — one set of loaded ASR weights for both, and
    // dictation reuses the identical rolling-window tuning. Sharing is safe in
    // both directions: `unload()` no-ops while decodes are pending and leaves
    // the transcriber reusable, so a meeting going idle mid-dictation cannot
    // strand a window (the next chunk re-initializes lazily).
    dictationService = DictationService(transcriber: transcriber);
  } else {
    CcHostLog.warning(
      'cc_server: no speech model installed under ${config.dataDir} — '
      'meeting recording and composer dictation over RPC are unavailable until '
      'a voice model is installed (the `meeting.startRecording`/`ingestAudio`/'
      '`stopRecording` and `dictation.start`/`ingestAudio`/`stop` ops stay '
      'absent).',
    );
  }

  _bootMark('wiring on-device model controls');
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
  // manager (constructed above, so the preflight can resolve every grammar
  // before boot completes), mirroring the desktop `codeIndexerProvider`. Symbols
  // are embedded on index when the embedding model is installed (semantic code
  // search via `search_code`), and fall back to FTS + graph otherwise. The
  // `.scm` queries are embedded in cc_natives (pure Dart), so no Flutter asset
  // bundle is needed. Every language the walker recognises ships a grammar, so
  // the indexer throws on any that fails to resolve rather than skipping it —
  // the natives ride in the bundle, making that a broken install.
  final codeIndexer = DefaultCodeIndexer(
    repository: DaoCodeGraphRepository(
      workspaceDbs,
      embeddingService: embeddingService,
    ),
    grammarManager: grammarManager,
  );

  _bootMark('wiring code graph + pipelines');
  // ── Code graph watch service ──
  // Keeps every checkout's graph partition current: builds a worktree's own
  // partition the moment it is provisioned (so PR-review search sees the PR's
  // tree, not the linked checkout's), and reindexes incrementally on any file
  // save — the built-in code-server IDE, an external editor via "Open in
  // IDE", agent writes, or a `worktree.syncToPrHead` pull — in worktrees AND
  // linked checkouts alike. Stream-driven off the repo + worktree registries;
  // failures are logged, never fatal.
  // NOT started here — see after the READY BANNER at the end of boot.
  // Indexing writes through the same single database connection every other
  // query uses, so starting it mid-boot puts a queue of index writes in front
  // of the rest of boot: the trivial `listing workspaces` query sat behind it
  // for minutes and looked like a hang. It used to start right after the RPC
  // bind, but that still left it competing with the tail of boot — and the
  // desktop parses the ready banner with a 20s kill-timeout
  // (cc_server_process.dart), so anything heavy between the bind and the
  // banner risks the child being killed as "not ready".
  // workspaceId → (fetchedAt, channelId → last message time).
  final channelActivity = <String, MapEntry<DateTime, Map<String, DateTime>>>{};
  // Background reindexes are published as `index_code` runs, so the one
  // long-running background job on this server is visible where every other one
  // is instead of only in this log. Reaped before `resumeAll` at the end of boot.
  final codeIndexRunReporter = PipelineCodeIndexRunReporter(
    pipelineRunRepository,
    onError: (message) => CcHostLog.warning('cc_server: $message'),
  );
  final codeGraphWatch = CodeGraphWatchService(
    indexer: codeIndexer,
    workspaces: workspaceRepository,
    isolatedRepos: isolatedRepoRepository,
    runReporter: codeIndexRunReporter,
    // Hold the first arm/index sweep a little past ready, keeping it out of
    // the desktop's initial RPC burst (workspace list, channel hydration).
    initialDelay: Duration(seconds: config.codeIndexDeferSeconds),
    // Only RECENTLY ACTIVE conversations get a file watcher. Measured here:
    // 117 worktree rows, 15 of them active in the last week and 72 belonging to
    // conversations that never exchanged a message. Arming a watcher costs a
    // full recursive scan, so watching the dormant 100 froze startup for ~65s
    // and served nobody — a conversation nobody is working in is not being
    // edited. Reopening one arms it within a reconcile tick, and the cleanup
    // pipeline reclaims the rows that are genuinely finished.
    shouldWatchChannel: (workspaceId, channelId) async {
      // Last MESSAGE time, not the channel row's `updatedAt` — that is bumped by
      // any write (provisioning included), so it reads as "fresh" for every row
      // and filters nothing. One aggregate query per workspace, cached briefly
      // because the arming pass asks about ~100 channels back to back.
      final cached = channelActivity[workspaceId];
      var activity = cached?.value;
      if (activity == null ||
          DateTime.now().difference(cached!.key) > const Duration(minutes: 2)) {
        final rows = await workspaceDbs
            .of(workspaceId)
            .messagingDao
            .watchChannelActivity(workspaceId)
            .first;
        activity = {
          for (final row in rows)
            if (row.lastMessageAt != null) row.channelId: row.lastMessageAt!,
        };
        channelActivity[workspaceId] = MapEntry(DateTime.now(), activity);
      }
      final lastMessageAt = activity[channelId];
      // Never had a message: an empty conversation nobody worked in.
      if (lastMessageAt == null) {
        return false;
      }
      return DateTime.now().difference(lastMessageAt) < _watchActivityWindow;
    },
  );

  // PR "open in editor" worktree materialization, exposed over
  // `ide.ensureWorktree`: a GUI-attached client (the native desktop app) asks
  // the host to check out the PR branch into a worktree and then launches the
  // returned path in a LOCAL editor itself (the headless host can't pop a GUI
  // editor, but it owns the repo checkout). rift copy-on-write worktrees are
  // ENABLED: the dylib resolves from the same app-support locations as the other
  // natives, so a PR worktree is a fast CoW clone when `rift_ffi` is present and
  // degrades to a plain `git worktree` fallback only when it is absent. Declared
  // before the pipeline executor because that executor consumes it (worktree GC).
  final prWorktree = PrWorktreeService(
    filesystem: workspaceFilesystem,
    isolation: repoIsolation,
    registry: isolatedRepoRepository,
    githubToken: () async => ghToken.isEmpty ? null : ghToken,
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
    // Worktree cleanup (repos.cleanup) for ticket/PR/sweep GC.
    provisioner: conversationProvisioner,
    prWorktrees: prWorktree,
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

  // ── Plan Studio (PRD 17) ──
  // Revision history + operator edits, plan-mode documents, playbooks,
  // honest per-node estimates, and plan-drift detection — all served over
  // `orchestration.*` / `plan.*` / `playbook.*` ops below.
  final orchestrationRevisionRepository = DaoOrchestrationRevisionRepository(
    workspaceDbs,
  );
  final planDocumentRepository = DaoPlanDocumentRepository(workspaceDbs);
  final playbookRepository = DaoPlaybookRepository(workspaceDbs);
  const proposalValidator = OrchestrationProposalValidator(
    schemaValidator: JsonSchemaValidator(),
  );
  final saveOrchestrationRevision = SaveOrchestrationRevisionUseCase(
    orchestrations: orchestrationRepository,
    revisions: orchestrationRevisionRepository,
    validator: proposalValidator,
    eventBus: eventBus,
  );
  final planEstimateService = PlanEstimateService(
    orchestrations: orchestrationRepository,
    planDocuments: planDocumentRepository,
    runLogs: agentRunLogRepository,
    codeGraph: DaoCodeGraphRepository(
      workspaceDbs,
      embeddingService: embeddingService,
    ),
  );
  // One instance shared by the plan snapshot below and the workProduct.* ops.
  final workProductRepo = DaoWorkProductRepository(workspaceDbs);

  final planDocumentApproval = PlanDocumentApprovalService(
    plans: planDocumentRepository,
    orchestrations: orchestrationRepository,
    revisions: orchestrationRevisionRepository,
    validator: proposalValidator,
    approveOrchestration: approveOrchestration.approve,
    // Approving a plan is the operator saying "go", so the plan's own
    // conversation leaves plan mode — parity with `exit_plan_mode`, which flips
    // the mode after its `plan_exit` approval. Previously the two exits were
    // unlinked and an approved plan's room stayed read-only.
    onApproved: (plan, orchestrationId) async {
      await messagingRepository.setChannelMode(
        plan.workspaceId,
        plan.conversationId,
        Mode.chat,
      );
      // An approved plan IS the conversation's goal — the objective its todos
      // work toward. Reusing the goal (rather than inventing a plan surface)
      // means the room already has a home for it: the goal row in the General
      // pane, with the agent's live todo list nested beneath. The goal is
      // deliberately not a todo, so the agent's `todo_write` cannot clobber it.
      await todoRepository.setGoal(
        plan.workspaceId,
        plan.conversationId,
        plan.goal,
      );
      // Say so IN the room. Approval used to be silent here: the operator
      // pressed "approve and run" and the conversation showed nothing until the
      // deliverable landed, with no way to tell "working" from "broken". The
      // work itself now streams into this same conversation (every generated
      // node carries its channel id), so this line is the seam between the plan
      // and its execution.
      final steps = plan.graph.workNodes.length;
      await messagingRepository.sendMessage(
        workspaceId: plan.workspaceId,
        channelId: plan.conversationId,
        conversationId: plan.conversationId,
        content:
            'Plan approved — executing $steps '
            '${steps == 1 ? 'step' : 'steps'} in this conversation.',
        senderId: 'system',
        senderType: 'agent',
        messageType: 'system',
      );
      eventBus.publish(
        PlanDocumentApproved(
          planId: plan.id,
          workspaceId: plan.workspaceId,
          conversationId: plan.conversationId,
          orchestrationId: orchestrationId,
          approvedNodeKeys: const [],
          occurredAt: DateTime.now(),
        ),
      );
    },
  );

  // The orchestrator's proposal verb + the plan-mode output contract + the
  // playbook verbs, registered post-construction like the ticket tools above.
  // (propose_orchestration previously existed but was never registered — the
  // orchestrate-mode allow-list pointed at a dead tool.)
  final proposeOrchestrationTool = ProposeOrchestrationTool(
    orchestrations: orchestrationRepository,
    validator: proposalValidator,
    tickets: ticketRepository,
    ticketWorkflow: ticketWorkflow,
    messaging: messagingRepository,
    eventBus: eventBus,
    revisions: orchestrationRevisionRepository,
  );
  mcpRegistry
    ..register(proposeOrchestrationTool)
    ..register(
      SubmitPlanTool(
        runLogRepository: agentRunLogRepository,
        planDocuments: planDocumentRepository,
        // A submitted plan announces itself in the conversation it was authored
        // in (typed `plan` bubble) and on the event bus, so it is not discoverable
        // only by navigating to Plan Studio and noticing a new card.
        messaging: messagingRepository,
        eventBus: eventBus,
        // Snapshot each submitted plan as a versioned work product so a
        // superseded plan's body survives (the PlanDocument row keeps only the
        // latest) and shows up in the conversation's artifacts panel.
        workProducts: workProductRepo,
        // Resolves unlabelled `symbol` provenance to the real qualified name at
        // write time — the id is an opaque content hash, so without this Plan
        // Studio can only show `symbol:<hash>`.
        codeGraph: DaoCodeGraphRepository(
          workspaceDbs,
          embeddingService: embeddingService,
        ),
      ),
    )
    ..register(
      CreatePlaybookTool(
        playbooks: playbookRepository,
        orchestrations: orchestrationRepository,
      ),
    )
    ..register(
      RunPlaybookTool(
        playbooks: playbookRepository,
        propose: proposeOrchestrationTool,
      ),
    );

  _bootMark('wiring review studio + collaboration');
  // ── Review Studio (PRD 18) ──
  // Semantic cohorts (from the code graph), API-contract diffs, UI visual
  // diffs (golden harness — degraded gracefully without a Flutter SDK), and
  // per-axis results — all served over `review_studio.*` ops below. Compute
  // runs on this host (it owns the code graph + git + PR fetch).
  final reviewCohortRepository = DaoReviewCohortRepository(workspaceDbs);
  final apiContractDiffRepository = DaoApiContractDiffRepository(workspaceDbs);
  final visualDiffRepository = DaoVisualDiffRepository(workspaceDbs);
  final reviewAxisResultRepository = DaoReviewAxisResultRepository(
    workspaceDbs,
  );
  final reviewCohortService = ReviewCohortService(
    workspaceDbs: workspaceDbs,
    cohorts: reviewCohortRepository,
    idFactory: () => const Uuid().v4(),
  );
  final apiContractDiffService = ApiContractDiffService(
    repository: apiContractDiffRepository,
  );
  final visualDiffService = VisualDiffService(
    repository: visualDiffRepository,
    paths: paths,
  );
  final reviewAxisService = ReviewAxisService(
    contractService: apiContractDiffService,
    visualService: visualDiffService,
    axisResults: reviewAxisResultRepository,
  );
  final reviewDiagramService = ReviewDiagramService(workspaceDbs);

  // Resolves the workspace-linked repo for (owner, repo), throwing when the
  // workspace doesn't own it (isolation).
  Future<Repo> resolveLinkedReviewRepo(
    String workspaceId,
    String owner,
    String repo,
  ) async {
    final linked = await workspaceRepository
        .watchReposForWorkspace(workspaceId)
        .first;
    for (final r in linked) {
      if (r.githubOwner.toLowerCase() == owner.toLowerCase() &&
          r.githubRepoName.toLowerCase() == repo.toLowerCase()) {
        return r;
      }
    }
    throw const NotFoundException('Repository is not linked to this workspace');
  }

  // Resolves a PR's REAL GitHub node id — the canonical review-studio key
  // (unified with `review_channels.prNodeId`, migration 46). Association-first
  // (a linked review channel already stores it → pure DB), then a cached GitHub
  // fallback for a studio-only PR that has no review channel yet. Cached per
  // server lifetime keyed by `owner/repo#n`.
  final prNodeIdCache = <String, String>{};
  Future<String> resolvePrNodeId({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
  }) async {
    final cacheKey = '$owner/$repo#$prNumber';
    final cached = prNodeIdCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    final repoFullName = '$owner/$repo';
    final assocs = await reviewChannelRepository
        .watchByWorkspace(workspaceId)
        .first;
    for (final a in assocs) {
      if (a.repoFullName == repoFullName &&
          a.prNumber == prNumber &&
          a.prNodeId.isNotEmpty) {
        return prNodeIdCache[cacheKey] = a.prNodeId;
      }
    }
    final gh = await serverGitHubClient.pr.getPullRequest(
      owner,
      repo,
      prNumber,
    );
    final nodeId = gh != null
        ? pullRequestFromGitHub(gh, repoFullName: repoFullName).nodeId
        : '';
    // Last resort (PR not found): the synthetic key, so the key is never empty.
    return prNodeIdCache[cacheKey] = nodeId.isNotEmpty ? nodeId : cacheKey;
  }

  // The reviewer fan-out + GitHub publish services back the AI-review MCP
  // surface (dispatch_reviewers / publish_review_to_github) and the client
  // publish RPC op.
  final dispatchReviewersService = DispatchReviewersService(
    agents: agentRepository,
    messaging: messagingRepository,
    reviewChannels: reviewChannelRepository,
    messagingPort: messagingService,
    workspaces: workspaceRepository,
    filesystemPort: workspaceFilesystem,
  );
  final reviewPublisherService = ReviewPublisherService(
    githubPrClient: serverGitHubClient.pr,
    messaging: messagingRepository,
    reviewChannels: reviewChannelRepository,
  );

  // Register the agent-facing review MCP tools. The review-node lifecycle
  // (add / confirm / peer-review / submit-verdict / finalize), the reviewer
  // fan-out, the studio annotations (cohort summaries + graph-verified
  // diagrams), and the user-gated GitHub publish. `finalize_review` folds the
  // studio axis results into one authoritative verdict.
  mcpRegistry
    ..register(
      SetCohortSummaryTool(
        cohorts: reviewCohortRepository,
        resolvePrNodeId: resolvePrNodeId,
      ),
    )
    ..register(AddReviewNodeTool(repository: messagingRepository))
    ..register(ConfirmReviewNodeTool(repository: messagingRepository))
    ..register(SubmitReviewerVerdictTool(repository: messagingRepository))
    ..register(RequestPeerReviewTool(messaging: messagingRepository))
    ..register(DispatchReviewersTool(service: dispatchReviewersService))
    ..register(
      FinalizeReviewTool(
        messaging: messagingRepository,
        reviewChannels: reviewChannelRepository,
        reviewAxisResults: reviewAxisResultRepository,
      ),
    )
    ..register(PublishReviewToGithubTool(service: reviewPublisherService))
    ..register(
      AddReviewDiagramTool(
        cohorts: reviewCohortRepository,
        resolvePrNodeId: resolvePrNodeId,
        corroborate:
            ({
              required String workspaceId,
              required String owner,
              required String repo,
              required List<String> filePaths,
            }) async {
              final linked = await resolveLinkedReviewRepo(
                workspaceId,
                owner,
                repo,
              );
              return reviewDiagramService.corroboratedEdgeKeys(
                workspaceId: workspaceId,
                repoId: linked.id,
                filePaths: filePaths,
              );
            },
      ),
    );

  // Compute cohorts + deterministic axes for a PR (PRD 18): resolve the linked
  // repo, fetch the PR's changed files + base/head SHAs, then run the cohort
  // grouper (code graph) + contract axis (spec diff) + visual axis (golden
  // harness, degraded honestly without a Flutter SDK).
  Future<Map<String, dynamic>> computeReviewStudioFn({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String userId,
  }) async {
    final linked = await resolveLinkedReviewRepo(workspaceId, owner, repo);
    final gh = await serverGitHubClient.pr.getPullRequest(
      owner,
      repo,
      prNumber,
    );
    if (gh == null) {
      throw const NotFoundException('Pull request not found');
    }
    final pr = pullRequestFromGitHub(gh, repoFullName: linked.fullName);
    final files = await serverGitHubClient.pr.listPullRequestFiles(
      owner,
      repo,
      prNumber,
    );
    final changedFiles = files.map((f) => f.filename).toList();
    // Canonical key = the real GitHub node id (migration 46). Prime the cache so
    // the read ops resolve it without a second fetch.
    final prNodeId = pr.nodeId.isNotEmpty
        ? pr.nodeId
        : reviewPrNodeKey(owner, repo, prNumber);
    prNodeIdCache['$owner/$repo#$prNumber'] = prNodeId;

    final cohorts = await reviewCohortService.compute(
      workspaceId: workspaceId,
      repoId: linked.id,
      prNodeId: prNodeId,
      headSha: pr.headSha,
      changedFiles: changedFiles,
    );

    final axes = <Map<String, dynamic>>[];
    // API-contract axis (token-free).
    final contract = await reviewAxisService.runContractAxis(
      workspaceId: workspaceId,
      repoId: linked.id,
      prNodeId: prNodeId,
      baseSha: pr.baseSha,
      headSha: pr.headSha,
      changedFiles: changedFiles,
      readContent: ({required String path, required String ref}) =>
          serverGitHubClient.content.getFileContent(owner, repo, path, ref),
    );
    if (contract != null) {
      axes.add(contract.toJson());
    }
    // Visual axis (token-free). Cheap precheck first: no Flutter SDK → honest
    // "unavailable" without provisioning a worktree.
    if (!await visualDiffService.hostHasFlutter()) {
      final result = ReviewAxisService.visualAxisResult(
        VisualDiffOutcome.unavailable('no Flutter SDK on host'),
      );
      await reviewAxisResultRepository.upsert(workspaceId, prNodeId, result);
      axes.add(result.toJson());
    } else {
      try {
        final worktree = await prWorktree.ensureWorktree(
          workspaceId: workspaceId,
          repo: linked,
          prNumber: prNumber,
          prHeadRef: pr.headRef.isEmpty
              ? 'refs/pull/$prNumber/head'
              : pr.headRef,
        );
        final visual = await reviewAxisService.runVisualAxis(
          workspaceId: workspaceId,
          repoId: linked.id,
          prNodeId: prNodeId,
          repoPath: worktree,
          git: const ProcessGitCommandAdapter(),
          baseSha: pr.baseSha,
          headSha: pr.headSha,
        );
        axes.add(visual.toJson());
      } catch (e) {
        CcHostLog.warning('review_studio: visual axis failed: $e');
        final result = ReviewAxisService.visualAxisResult(
          VisualDiffOutcome.unavailable('golden harness error'),
        );
        await reviewAxisResultRepository.upsert(workspaceId, prNodeId, result);
        axes.add(result.toJson());
      }
    }

    return {'cohorts': cohorts.map((x) => x.toJson()).toList(), 'axes': axes};
  }

  // Beyond-the-diff blast radius for a changed file (PRD 18 §6): resolve the
  // file's dominant (largest-span) symbol, then the reverse-dependency
  // subgraph from the code graph.
  Future<Map<String, dynamic>> reviewBlastRadiusFn({
    required String workspaceId,
    required String owner,
    required String repo,
    required String filePath,
    required String userId,
    int depth = 2,
  }) async {
    final linked = await resolveLinkedReviewRepo(workspaceId, owner, repo);
    final symbols = await workspaceDbs
        .of(workspaceId)
        .codeGraphDao
        .getSymbolsByFiles(workspaceId, linked.id, [filePath]);
    if (symbols.isEmpty) {
      return {'nodes': const [], 'edges': const [], 'indexed': false};
    }
    symbols.sort(
      (a, b) => (b.endLine - b.startLine) - (a.endLine - a.startLine),
    );
    final impact = await workspaceDbs
        .of(workspaceId)
        .codeGraphDao
        .getImpactRadius(workspaceId, symbols.first.id, depth: depth);
    return {
      'indexed': true,
      'root': {
        'id': symbols.first.id,
        'name': symbols.first.name,
        'qualifiedName': symbols.first.qualifiedName,
        'filePath': symbols.first.filePath,
      },
      'nodes': [
        for (final n in impact.nodes)
          {
            'id': n.id,
            'name': n.name,
            'qualifiedName': n.qualifiedName,
            'filePath': n.filePath,
            'kind': n.kind,
            'depth': impact.depthById[n.id] ?? 0,
          },
      ],
      'edges': [
        for (final e in impact.edges)
          {
            'source': e.sourceSymbolId,
            'target': e.targetSymbolId,
            'kind': e.kind,
          },
      ],
    };
  }

  // Conversation revert/unrevert (undo/redo): this host owns the DB AND runs the
  // dispatch that created the conversation's worktrees + captured the per-turn
  // git snapshots, so it can roll back BOTH the transcript and the worktree
  // filesystem. The coordinator resolves the worktree from the channel's agent.
  final conversationCheckpoint = ConversationCheckpointCoordinator(
    messaging: messagingRepository,
    agents: agentRepository,
  );

  // Governance (PRD 09) read surface served over RPC: the goal hierarchy, board
  // approvals, and computed agent presence — built from the same DAOs the MCP
  // tools use. Presence composes runtime health + lifecycle + run/queue counts.
  final goalRepository = DaoGoalRepository(workspaceDbs);
  final approvalRepository = DaoApprovalRepository(workspaceDbs);
  final agentPresenceService = AgentPresenceService(
    agentRepository: agentRepository,
    runtimeStateRepository: DaoAgentRuntimeStateRepository(workspaceDbs),
    runLogRepository: agentRunLogRepository,
    ticketRepository: ticketRepository,
  );

  // Messaging IDE repo views (Explorer file tree, Source Control diffs, file
  // viewer, conversation changes) served over RPC. The SERVER owns the linked
  // repo checkouts + per-conversation worktrees; every client (desktop thin +
  // bundled cc_server, web/remote) reads them through the same ops, so the IDE
  // is identical across tiers. Workspace-scoped inside each method.
  final repoIdeData = RepoIdeDataService(
    repoRepository: repoRepository,
    workspaceRepository: workspaceRepository,
    isolatedRepoRepository: isolatedRepoRepository,
    fileSearch: ideFileSearch,
    // For worktree.commitAndPush: the token rides in the git auth header env,
    // never argv (invisible to `ps`).
    githubToken: () async => ghToken.isEmpty ? null : ghToken,
  );

  // ── Take-over / hand-back (PRD 16 §8) ──
  // Pauses runs at turn boundaries (or stops CLI runs), writes the durable
  // marker (a restart comes back paused), and gates dispatch while it stands.
  final takeoverService = TakeoverService(
    workspaceDbs: workspaceDbs,
    runLogs: agentRunLogRepository,
    messaging: messagingRepository,
    pauseRun: agentDispatchService.pauseRun,
    resumeRun: agentDispatchService.resumeRun,
    stopRun: agentDispatchService.stopRun,
    steerRun: agentDispatchService.steerRun,
    conversationChanges: repoIdeData.conversationChanges,
  );
  takeoverHolder.value = takeoverService;

  // ── Plan drift (PRD 17 §6) ──
  // Compares each finished plan node against its declared scope (estimate
  // band + file provenance). Markers land in Caches for the Studio canvas;
  // under `stopAndAsk` the resume listener's drift gate HOLDS the step until
  // `orchestration.continueNode`.
  final planDriftService = PlanDriftService(
    orchestrations: orchestrationRepository,
    runLogs: agentRunLogRepository,
    workspaceDbs: workspaceDbs,
    messaging: messagingRepository,
    conversationChanges: repoIdeData.conversationChanges,
  );

  // ── Checker role (PRD 16 §13) ──
  // A channel's named checker agent reviews every other agent's completed
  // main run, in-thread.
  final checkerListener = CheckerDispatchListener(
    eventBus: eventBus,
    workspaceDbs: workspaceDbs,
    runLogs: agentRunLogRepository,
    dispatchChecker:
        ({
          required String channelId,
          required String agentId,
          required String prompt,
          required String workspaceId,
        }) async {
          await messagingService.dispatchAgent(
            channelId: channelId,
            agentId: agentId,
            prompt: prompt,
            workspaceId: workspaceId,
          );
        },
  )..start();

  // Reclaims isolated worktrees when a unit ends (ticket done/cancelled,
  // conversation deleted, PR merged/closed) and auto-archives a merged PR's
  // workbench conversations. Long-lived; stopped on [shutdown].
  final worktreeGcListener = WorktreeGcListener(
    eventBus: eventBus,
    provisioner: conversationProvisioner,
    reviewChannels: reviewChannelRepository,
    prWorktrees: prWorktree,
    conversations: conversationRepository,
  )..start();

  // §188: bound below (its dio adapters are built later in bootstrap). The
  // `ticketSyncNow` closure passed to the catalog only dereferences it at
  // request time, by which point bootstrap has assigned it.
  TicketSyncEngine? ticketSyncEngineRef;

  // ---- Fleet scaling & remote execution (PRD 20) ----
  // The scheduler places typed JobSpecs onto eligible workers (pin → prefer →
  // spill); the implicit local worker runs jobs in-process (byte-identical to
  // the pre-fleet path); remote `cc_worker`s pull leases and stream events back
  // via the RemoteExecutionRegistry. Built here (where the DB + services live)
  // and its ops spliced into the RPC catalog below.
  final fleetRepository = DaoFleetRepository(globalDb.fleetDao);
  final remoteExecutionRegistry = RemoteExecutionRegistry();
  final localJobExecutor = LocalJobExecutor(<JobKind, JobRunner>{});
  final remoteJobExecutor = RemoteJobExecutor(remoteExecutionRegistry);
  final fleetScheduler = FleetSchedulerService(
    repository: fleetRepository,
    executorResolver: (worker) =>
        worker.id == kLocalWorkerId ? localJobExecutor : remoteJobExecutor,
  );
  // Register the implicit local worker (the server host doubling as a
  // zero-config worker), reflecting the host's detected capabilities.
  unawaited(fleetScheduler.ensureLocalWorker(_detectLocalWorkerCapabilities()));
  // ---- Agent evals, replay & regression (PRD 21) ----
  // The evals repository backs suites/runs/recordings/goldens/config-versions;
  // its ops join the fleet ops in the spliced `extraOps`. Eval-batch execution
  // (the dispatch-backed task executor) is the remaining integration seam —
  // `runnerFactory` is null here, so `evals.runSuite` returns a clear error
  // rather than a fake pass until that executor is wired.
  final evalsRepository = DaoEvalsRepository(workspaceDbs);

  final fleetOps = <RepoOp>[
    ...buildFleetOperatorOps(
      scheduler: fleetScheduler,
      fleetRepository: fleetRepository,
    ),
    ...buildFleetWorkerOps(
      scheduler: fleetScheduler,
      fleetRepository: fleetRepository,
      remoteRegistry: remoteExecutionRegistry,
    ),
    ...buildEvalsOps(repository: evalsRepository),
  ];
  final fleetWatchQueries = <WatchQuery>[
    ...buildFleetWatchQueries(fleetRepository: fleetRepository),
    ...buildEvalsWatchQueries(repository: evalsRepository),
  ];

  // PR workbench: idempotently ensure a PR has a backing channel (mode review),
  // linked via the review-channel association, and kick off provisioning of its
  // repo worktree at the PR head. Reused by chat/terminal/file surfaces so the
  // whole PR page hangs off one channel. Returns {channel_id, provisioning}.
  Future<Map<String, dynamic>> ensurePrChannel({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prNodeId,
    String? createdByUserId,
    String title = '',
  }) async {
    final existing = await reviewChannelRepository
        .watchByPr(workspaceId, prNodeId)
        .first;
    if (existing != null &&
        await messagingRepository.channelExists(
          workspaceId,
          existing.channelId,
        )) {
      final ch = await messagingRepository.getChannelById(
        workspaceId,
        existing.channelId,
      );
      return {
        'channel_id': existing.channelId,
        'provisioning_status':
            (ch?.provisioningStatus ?? ChannelProvisioningStatus.ready)
                .toDbValue(),
      };
    }
    final name = title.trim().isEmpty
        ? 'PR #$prNumber'
        : 'PR #$prNumber ${title.trim()}';
    final channel = await messagingRepository.createChannel(
      workspaceId,
      name.length > 80 ? name.substring(0, 80) : name,
      const <String>[],
      mode: Mode.review,
      createdByUserId: createdByUserId,
      // Workbench channels stay out of the sidebar until someone actually
      // messages in them — opening a PR must not mint visible channels.
      origin: ChannelOrigin.prWorkbench,
    );
    await reviewChannelRepository.create(
      channelId: channel.id,
      workspaceId: workspaceId,
      prNodeId: prNodeId,
      prNumber: prNumber,
      repoFullName: repoFullName,
    );
    // Fire ChannelCreated so the (now PR-aware) provisioning service checks the
    // repo out at the PR head. The Dao createChannel does not publish this.
    eventBus.publish(
      ChannelCreated(
        channelId: channel.id,
        workspaceId: workspaceId,
        occurredAt: DateTime.now(),
      ),
    );
    return {
      'channel_id': channel.id,
      'provisioning_status': ChannelProvisioningStatus.provisioning.toDbValue(),
    };
  }

  // Resolves (creating + provisioning if needed) the on-disk PR-head worktree
  // for a pull request, reusing the SAME channel worktree the in-app workbench
  // edits — there is no separate `pr_worktrees/` checkout anymore. Ensures the
  // PR channel, waits for the background provisioner to check the repo out at
  // the PR head, then returns that worktree's path. Used by the "open in editor"
  // ops and the review-studio visual axis.
  Future<String> ensurePrWorktreePath({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prNodeId,
    String title = '',
    String? repoId,
  }) async {
    final res = await ensurePrChannel(
      workspaceId: workspaceId,
      repoFullName: repoFullName,
      prNumber: prNumber,
      prNodeId: prNodeId,
      title: title,
    );
    final channelId = res['channel_id'] as String;

    // Wait for the (event-driven, idempotent) provisioner to finish the PR-head
    // checkout. An already-ready channel returns on the first poll.
    final deadline = DateTime.now().add(const Duration(seconds: 120));
    while (true) {
      final ch = await messagingRepository.getChannelById(
        workspaceId,
        channelId,
      );
      final status = ch?.provisioningStatus ?? ChannelProvisioningStatus.ready;
      if (status == ChannelProvisioningStatus.ready) {
        break;
      }
      if (status == ChannelProvisioningStatus.failed) {
        throw StateError('PR worktree provisioning failed for #$prNumber');
      }
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('PR worktree provisioning timed out for #$prNumber');
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    final rows = repoId != null && repoId.isNotEmpty
        ? [
            ?await isolatedRepoRepository.forUnitRepo(
              workspaceId,
              channelId,
              repoId,
            ),
          ]
        : await isolatedRepoRepository.forChannel(workspaceId, channelId);
    if (rows.isEmpty) {
      throw StateError('PR worktree not available for #$prNumber');
    }
    return rows.first.path;
  }

  // Re-syncs a PR channel's worktree to the latest PR head (commits pushed after
  // it was provisioned). Resolves the PR number/branch from the channel's review
  // association, then delegates the git work to the IDE data service (which
  // no-ops on a dirty tree).
  Future<Map<String, dynamic>> syncPrWorktree({
    required String workspaceId,
    required String channelId,
    required String repoId,
  }) async {
    final assoc = await reviewChannelRepository
        .watchByChannel(workspaceId, channelId)
        .first;
    if (assoc == null) {
      return {'ok': false, 'error': 'not a PR channel'};
    }
    final res = await repoIdeData.syncToPrHead(
      workspaceId,
      channelId,
      repoId,
      headRef: 'refs/pull/${assoc.prNumber}/head',
      branch: 'pr/${assoc.prNumber}',
    );
    return res ?? {'ok': false, 'error': 'no worktree'};
  }

  // ── Chat bridges (Slack today, one plugin per provider) ──
  // One provider-side app per WORKSPACE, dialed OUTBOUND (Slack: Socket Mode —
  // `apps.connections.open` + a WebSocket), so a server behind NAT with no tunnel
  // receives mentions, DMs and slash commands without any inbound endpoint.
  // Constructed here (the ops below need it) but not started until after the
  // ready banner — a chat app that is slow to answer must never delay boot.
  //
  // The registry is the whole extension point: adding Discord is one more plugin
  // in this list, with no change to the connector, the ops or the client.
  final chatConnector = ChatConnector(
    registry: ChatProviderRegistry([
      SlackChatProviderPlugin(dioFactory: createDio),
    ]),
    store: FileChatConnectionStore(dataDir: config.dataDir),
    // The SAME registry the dispatch stack publishes turn deltas into, so a chat
    // reply streams token-by-token instead of waiting for the DB's 2s
    // crash-insurance write.
    streamRegistry: streamRegistry,
    messaging: messagingService,
    messages: messagingRepository,
    agents: agentRepository,
    channelLinks: DaoChatChannelLinkRepository(workspaceDbs),
    userLinks: DaoChatUserLinkRepository(workspaceDbs),
    users: userRepository,
    members: membershipRepository,
    tickets: ticketWorkflow,
    // CROSS-WORKSPACE BY DESIGN: the boot reconciler needs the workspace
    // registry to know which workspaces to bring up; every step after this
    // works with one workspace id in hand.
    listWorkspaceIds: () async =>
        (await workspaceRepository.watchAll().first).map((w) => w.id).toList(),
    eventBus: eventBus,
    // The "View in Control Center" links on chat task cards. They point at THIS
    // server's `/open/…` bounce page, which is what converts an https link a
    // chat product will accept into the desktop's `control-center://` deep link.
    // A loopback URL is kept deliberately: the solo operator clicks it on the
    // same machine the server runs on.
    deepLinks: ChatDeepLinks.fromServerUrl(config.publicUrl),
  );

  final viewerGitHubIdentity = ghToken.isEmpty
      ? null
      : ViewerGitHubIdentityCache(serverGitHubClient.content);

  final catalog = buildRemoteRpcCatalog(
    ensurePrChannel: ensurePrChannel,
    ensurePrWorktree: ensurePrWorktreePath,
    syncPrWorktree: syncPrWorktree,
    extraOps: [
      ...fleetOps,
      ...buildWeatherOps(weatherService),
      ...buildFontsOps(fontCatalog),
      ...buildSoundscapeOps(soundscapeHub),
      ...buildChatOps(connector: chatConnector, users: userRepository),
    ],
    extraWatchQueries: [
      ...fleetWatchQueries,
      ...buildWeatherWatchQueries(weatherService),
      ...buildSoundscapeWatchQueries(soundscapeHub),
      ...buildChatWatchQueries(connector: chatConnector, users: userRepository),
    ],
    // Identity & membership (multi-user access): the users/members/invites/
    // prefs/activity ops + the invite service, plus the bootstrap owner (the
    // admin of server-global surfaces like the device registry).
    userRepository: userRepository,
    membershipRepository: membershipRepository,
    inviteRepository: inviteRepository,
    userActivityRepository: userActivityRepository,
    userPreferencesRepository: userPreferencesRepository,
    workspaceSettingsRepository: workspaceSettingsRepository,
    serverSettingsRepository: serverSettingsRepository,
    inviteService: inviteService,
    approvalRouting: approvalEscalation,
    serverOwnerUserId: ownerUserId,
    // Per-user GitHub tokens (self-service `credentials.*` ops); the SAME
    // store instance the dispatch adapter reads, so a token saved over RPC is
    // immediately used by the member's next run.
    userCredentials: userCredentials,
    ticketRepository: ticketRepository,
    projectRepository: projectRepository,
    // Read-only sync-health surface (§188): the client watches these to show
    // per-vendor last-sync + error streak. Cheap stateless DAO wrappers over
    // the same ticketSyncDao the sync engine writes to.
    syncConfigRepository: DaoTicketSyncConfigRepository(workspaceDbs),
    syncLogRepository: DaoTicketSyncLogRepository(workspaceDbs),
    // Manual "sync now" trigger (§188). Deferred: the engine is constructed
    // later in bootstrap; this closure is only invoked when an RPC arrives.
    ticketSyncNow: ({required String workspaceId, String? vendor}) =>
        ticketSyncEngineRef!.pullNow(workspaceId: workspaceId, vendor: vendor),
    ticketWorkflow: ticketWorkflow,
    messagingRepository: messagingRepository,
    // Live turn relay: the same registry the dispatch stack publishes into,
    // so `messaging.watchChannelTurns` streams tokens as they arrive — and,
    // keyed by run id, so `agent_run_log.watchRunTranscript` streams a
    // subagent's own activity.
    streamRegistry: streamRegistry,
    // Durable per-run activity timelines, for replaying a finished run.
    runTranscriptRepository: runTranscriptRepository,
    // Server-computed messaging aggregates (SQL projection on the concrete
    // DAO repository): per-channel sidebar signals.
    watchChannelActivity: messagingRepository.watchChannelActivity,
    // Conversations (parallel streams / "parentheses" inside a channel).
    conversationRepository: conversationRepository,
    watchConversationsForChannel: (workspaceId, channelId) =>
        conversationRepository.watchForChannel(
          workspaceId: workspaceId,
          channelId: channelId,
        ),
    // On-demand backup (`server.backupNow`): a timestamped snapshot DIRECTORY
    // under `<dataDir>/backups/` holding global.db, one file per workspace and a
    // manifest. Also backs `workspace.export` / `workspace.import`, which are a
    // single VACUUM INTO each because one workspace is one file. fullClient-only.
    databaseBackup: AppDatabaseBackupService(
      global: globalDb,
      workspaces: workspaceDbs,
      backupsDir: '${config.dataDir}/backups',
      onWarn: CcHostLog.warning,
    ),
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
    providerPolicyRepository: providerPolicyRepository,
    // PRD 24 §4: the same policy store the ActionGuard enforces with, exposed
    // for the agent-permissions matrix/probe RPC ops.
    actionPolicyRepository: actionPolicyRepository,
    // PRD 23 §1: skills registry browse/preview/install ops.
    skillBundles: skillBundles,
    skillRegistry: skillRegistry,
    // Built-in harness provider/credential brain (PRD 13): same store the
    // dispatch path reads, plus the OAuth broker, so a key/login saved over RPC
    // is immediately usable by a dispatched agent.
    harnessCredentialStore: harnessCreds,
    harnessOAuthBroker: harnessOAuthBroker,
    reviewChannelRepository: reviewChannelRepository,
    isolatedRepoRepository: isolatedRepoRepository,
    voiceProfileRepository: voiceProfileRepository,
    // PR "open in editor" resolves the channel worktree (`ide.ensureWorktree`)
    // via `ensurePrWorktree` above; no editorLauncher is wired (the headless host
    // can't launch a GUI editor — the client launches the returned path locally),
    // so only the worktree-path op lights up, not `ide.openPrInEditor`.
    // Messaging IDE repo data ops: the Explorer file tree (`repos.searchFiles`),
    // the Source Control per-repo diff (`repos.changes`), the file viewer
    // (`repos.readFile`), and the aggregate conversation diff
    // (`conversation.changes`). All run on the SERVER over the checkouts +
    // worktrees it owns, so desktop and web get the same IDE.
    repoChanges: repoIdeData.repoChanges,
    repoChangesGrouped: repoIdeData.repoChangesGrouped,
    repoStage: repoIdeData.stageFiles,
    repoUnstage: repoIdeData.unstageFiles,
    repoFileContent: repoIdeData.readFile,
    repoFileSearch: repoIdeData.searchFiles,
    repoContentSearch: repoIdeData.searchContentWithOptions,
    worktreeContentSearch: repoIdeData.searchWorktreeContentWithOptions,
    worktreeFileSearch: repoIdeData.searchFilesInWorktree,
    conversationChanges: repoIdeData.conversationChanges,
    // IDE worktree mutate ops: the "untitled" draft save (⌘S) writes into the
    // conversation's CoW worktree, and the Source Control "Revert" action
    // restores working-tree files to HEAD. Both run SERVER-SIDE over the
    // worktrees the host owns; absent on a host that owns no worktrees.
    worktreeWriteFile:
        ({
          required workspaceId,
          required channelId,
          required repoId,
          required path,
          required content,
        }) async {
          final r = await repoIdeData.writeFile(
            workspaceId,
            channelId,
            repoId,
            path,
            content,
          );
          if (r == null) {
            return null;
          }
          return {'repoId': r.repoId, 'path': r.path};
        },
    worktreeRevertFiles:
        ({
          required workspaceId,
          required channelId,
          required repoId,
          required paths,
        }) async {
          final r = await repoIdeData.revertFiles(
            workspaceId,
            channelId,
            repoId,
            paths,
          );
          if (r == null) {
            return null;
          }
          return {
            'repoId': r.repoId,
            'reverted': r.reverted,
            'skipped': r.skipped,
          };
        },
    worktreeReadFile:
        ({
          required workspaceId,
          required channelId,
          required repoId,
          required path,
        }) async {
          final r = await repoIdeData.readFileFromWorktree(
            workspaceId,
            channelId,
            repoId,
            path,
          );
          if (r == null) {
            return null;
          }
          return {'content': r.content, 'binary': r.binary};
        },
    worktreeCommitAndPush: repoIdeData.commitAndPush,
    worktreePublishBranch: repoIdeData.publishBranch,
    // Remote agent-action approvals: the same registry the dispatch/MCP paths
    // publish to, exposed to clients over `confirmation.watchPending` +
    // `confirmation.respond` so a desktop/web/phone user can approve or deny.
    pendingConfirmationRegistry: pendingConfirmationRegistry,
    meetingRepository: meetingRepository,
    // Live meeting recording over RPC (null when no ASR model is installed →
    // the recording ops stay absent and the web recorder reports unavailable).
    meetingRecording: meetingRecording,
    // Composer voice dictation over RPC (same null-when-no-ASR-model contract →
    // the `dictation.*` ops + `dictation.watchPartials` stay absent).
    dictationService: dictationService,
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
    // Governance (PRD 09) read-only surface.
    goalRepository: goalRepository,
    todoRepository: todoRepository,
    notificationFeedRepository: notificationFeedRepository,
    // Durable supervised goals (`/goal` + `/loop`): the
    // `agentGoalRuns.watchForConversation` query + pause / resume / cancel ops.
    agentGoalRunRepository: agentGoalRunRepository,
    goalSupervisor: goalSupervisor,
    approvalRepository: approvalRepository,
    agentPresenceService: agentPresenceService,
    // Pairing management: a connected first-party (web) client can mint a
    // pairing for a phone that then dials THIS headless server directly. The
    // advertised URL is the server's configured public URL.
    pairedDeviceDao: globalDb.pairedDeviceDao,
    pairedDeviceSecretsPort: secrets,
    pairingServerUrl: config.publicUrl,
    descriptorService: descriptorService,
    networkRuntime: () => networkRuntimeHolder.value,
    presenceHub: presenceHub,
    syncFeed: syncFeed,
    workspaceDbs: workspaceDbs,
    takeoverService: takeoverService,
    // Relay pairing: advertise the broker so a phone that can't reach this
    // server directly rendezvous there. The RemoteRelayHost (built below)
    // watches the device table, so minting an active phone makes the server
    // join the room — no callback needed here.
    relaySignalingUrl: config.signalingUrl,
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
    // Shares the poller's fetch adapter so the one-shot op and the live
    // `pr.watchOpenForWorkspace` snapshot are built by the same code path.
    fetchOpenPrList: openPrFetchAdapter?.fetchGroups,
    // The open-PR poller: `pr.watchOpenForWorkspace` + `pr.refreshOpenForWorkspace`.
    openPrPoller: openPrPoller,
    // The thin client's `login`/avatar resolve from the host's gh user.
    // Teams share the process-lifetime identity cache with the notifications
    // poller so `GET /user/teams` is not fetched twice.
    fetchCurrentGitHubUser: viewerGitHubIdentity == null
        ? null
        : () async => (await viewerGitHubIdentity.user())?.toJson(),
    fetchViewerGitHubTeams: viewerGitHubIdentity == null
        ? null
        : () async => await viewerGitHubIdentity.teams() ?? const {},
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
            final groups = await GitHubPrSearchAdapter(
              serverGitHubClient,
            ).search(query: PrSearchQuery.parse(query), repos: repos);
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
                    .getCollaboratorPermission(owner, repo, ghStatus.username);
              } on Object {
                return 'none';
              }
            },
            userProfile: (login) async =>
                (await serverGitHubClient.graphql.getUserProfile(
                  login: login,
                ))?.toWire(),
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
        ServiceStatusService(createDio()).fetchSummaryJson(),
    // status.claude.com summary (token-less; same Statuspage v2 shape). The
    // thin client parses the raw summary with
    // `GitHubServiceStatus.fromSummaryJson`.
    fetchClaudeServiceStatus: () => ServiceStatusService(
      createDio(),
      summaryUrl: claudeStatusSummaryUrl,
    ).fetchSummaryJson(),
    // status.openai.com summary (token-less; same Statuspage v2 shape).
    fetchOpenAIServiceStatus: () => ServiceStatusService(
      createDio(),
      summaryUrl: openaiStatusSummaryUrl,
    ).fetchSummaryJson(),
    // status.moonshot.cn (Kimi) summary (token-less; same Statuspage v2
    // shape).
    fetchKimiServiceStatus: () => ServiceStatusService(
      createDio(),
      summaryUrl: kimiStatusSummaryUrl,
    ).fetchSummaryJson(),
    // Live subscription-usage quotas (Claude/Codex/z.ai/Kimi Code). Reads the
    // CLIs' own credentials server-side; the z.ai key and the Kimi Code OAuth
    // token are resolved by the op from the harness provider credential store
    // (Settings → Adapters).
    fetchSubscriptionUsage:
        ({
          zaiApiKey,
          zaiBaseUrl,
          kimiAccessToken,
          kimiBaseUrl,
          kimiDeviceId,
        }) async => [
          for (final u
              in await SubscriptionUsageService(dio: createDio()).fetchAll(
                zaiApiKey: zaiApiKey,
                zaiBaseUrl: zaiBaseUrl,
                kimiAccessToken: kimiAccessToken,
                kimiBaseUrl: kimiBaseUrl,
                kimiDeviceId: kimiDeviceId,
              ))
            u.toJson(),
        ],
    // Klipy GIF picker (server-side app key). Null when unconfigured → empty.
    gifSearch: klipy == null
        ? null
        : (query) async => [
            for (final g in await klipy.search(query)) g.toWire(),
          ],
    gifTrending: klipy == null
        ? null
        : () async => [for (final g in await klipy.trending()) g.toWire()],
    // Generic workspace-scoped cache (the messaging IDE editor-layout persists
    // + restores per conversation here, so layouts are shared across clients).
    cacheRepository: DaoCacheRepository(workspaceDbs),
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
    // Conversation revert/unrevert (undo/redo) with worktree filesystem rollback:
    // this host owns the DB + the conversation's checkouts + the per-turn
    // snapshots, so the closures resolve the worktree and roll it back too.
    conversationRevert:
        ({
          required workspaceId,
          required channelId,
          required messageId,
          required inclusive,
        }) async {
          final outcome = await conversationCheckpoint.revertTo(
            workspaceId: workspaceId,
            channelId: channelId,
            messageId: messageId,
            inclusive: inclusive,
          );
          return (
            affectedMessageIds: outcome.affectedMessageIds,
            filesystemRestored: outcome.filesystemRestored,
          );
        },
    conversationUnrevert: ({required workspaceId, required channelId}) async =>
        (await conversationCheckpoint.unrevert(
          workspaceId: workspaceId,
          channelId: channelId,
        )).affectedMessageIds,
    retryChannelProvisioning: channelProvisioningService.provision,
    // Review-fix agent: dispatch a sandboxed/relay agent server-side. The op
    // takes NO working_dir from the client — the working dir is resolved
    // server-side from the bound workspace, so a thin client can't aim the
    // agent at an arbitrary path.
    reviewDispatch:
        ({
          required workspaceId,
          required agentId,
          required prompt,
          required channelId,
          conversationId,
          requestedByUserId,
        }) async {
          final workingDir = await workspaceFilesystem.workspaceDir(
            workspaceId,
          );
          await agentDispatchService.dispatch(
            agentId: agentId,
            prompt: prompt,
            workingDirectory: workingDir,
            workspaceId: workspaceId,
            channelId: channelId,
            // A parenthesis when the fix was branched off a finding; else main
            // (main conversation id == channel id).
            conversationId: conversationId ?? channelId,
            // The human who sent the findings to the fix agent: co-authors the
            // agent's commits and selects their own GitHub token when stored.
            requestedByUserId: requestedByUserId,
          );
        },
    // Interactive terminal over RPC (libccpty): the `terminal.*` ops run a REAL
    // shell on this host, scoped + ownership-checked per the bound workspace.
    terminalSessions: terminalSessions,
    // code-server over RPC: the `codeServer.*` ops spawn/reuse a loopback-bound
    // code-server per conversation worktree, scoped + ownership-checked per the
    // bound workspace; reached through the `/proxy/vscode/<sid>/` reverse proxy.
    codeServer: codeServerSessions,
    // Pipelines + orchestration run headless: the engine drives the relocated
    // dispatch stack, so `pipeline.*` + `orchestration.approve/cancel` are LIVE.
    // (Pipelines using the deferred indexCode/cleanupRepos/meeting bodies still
    // fail with unknown-body until those are wired — see buildServerPipelineExecutor.)
    pipelineEngine: pipeline.engine,
    approveOrchestration: (workspaceId, orchestrationId) => approveOrchestration
        .approve(workspaceId: workspaceId, orchestrationId: orchestrationId),
    cancelOrchestration: (workspaceId, orchestrationId) => cancelOrchestration
        .cancel(workspaceId: workspaceId, orchestrationId: orchestrationId),
    // Plan Studio (PRD 17): revisions, partial approval, plan documents,
    // playbooks, estimates, drift markers — all live on this host (it owns
    // the engine + DB).
    orchestrationRevisionRepository: orchestrationRevisionRepository,
    planDocumentRepository: planDocumentRepository,
    playbookRepository: playbookRepository,
    saveOrchestrationRevision: saveOrchestrationRevision,
    // Work products / artifacts: the client's ONLY path to them (the subsystem
    // was complete server-side and unreachable, so a published artifact could
    // not be rendered). Read-only ops — artifacts are written by the MCP tools.
    workProductRepository: workProductRepo,
    approveOrchestrationScoped: (workspaceId, orchestrationId, nodeKeys) =>
        approveOrchestration.approve(
          workspaceId: workspaceId,
          orchestrationId: orchestrationId,
          approvedNodeKeys: nodeKeys,
        ),
    approveOrchestrationNodes: (workspaceId, orchestrationId, nodeKeys) =>
        approveOrchestration.approveNodes(
          workspaceId: workspaceId,
          orchestrationId: orchestrationId,
          nodeKeys: nodeKeys,
        ),
    planDivergenceMarkers: planDriftService.markers,
    continuePlanNode: (workspaceId, orchestrationId, nodeKey) async {
      final o = await orchestrationRepository.getById(
        workspaceId,
        orchestrationId,
      );
      final runId = o?.pipelineRunId;
      if (o == null || runId == null) {
        throw const NotFoundException(
          'Orchestration not found or not executing',
        );
      }
      await planDriftService.markResumed(workspaceId, orchestrationId, nodeKey);
      await pipeline.engine.resumeStep(
        pipelineRunId: runId,
        stepId: 'sub_$nodeKey',
      );
    },
    estimateOrchestration: planEstimateService.estimateOrchestration,
    estimatePlanDocument: planEstimateService.estimatePlanDocument,
    approvePlanDocument: planDocumentApproval.approve,
    runPlaybook:
        ({
          required String workspaceId,
          required String ticketId,
          required String playbookId,
          required Map<String, String> args,
          String? userId,
        }) async {
          // Reuse the MCP tool's single code path (instantiate → validate →
          // propose). The op adapts its CallResult back to a repo-op payload.
          final result =
              await RunPlaybookTool(
                playbooks: playbookRepository,
                propose: proposeOrchestrationTool,
              ).run({
                'workspace_id': workspaceId,
                'ticket_id': ticketId,
                'playbook_id': playbookId,
                'args': args,
              });
          final text = result.content.isEmpty ? '' : result.content.first.text;
          if (result.isError) {
            throw ValidationException(text);
          }
          final decoded = jsonDecode(text);
          return decoded is Map<String, dynamic> ? decoded : {'result': text};
        },
    // Review Studio (PRD 18): live cohorts / contract / visual / axis reads +
    // decision gates, and the compute + blast-radius closures (host owns the
    // code graph + git + PR fetch).
    reviewCohortRepository: reviewCohortRepository,
    apiContractDiffRepository: apiContractDiffRepository,
    visualDiffRepository: visualDiffRepository,
    reviewAxisResultRepository: reviewAxisResultRepository,
    computeReviewStudio: computeReviewStudioFn,
    reviewBlastRadius: reviewBlastRadiusFn,
    publishReview:
        ({
          required String workspaceId,
          required String channelId,
          required String selection,
          required bool approveOnShip,
        }) async {
          final result = await reviewPublisherService.publish(
            workspaceId: workspaceId,
            channelId: channelId,
            selection: selection == 'all_open'
                ? ReviewPublishSelection.allOpen
                : ReviewPublishSelection.consensus,
            approveOnShip: approveOnShip,
          );
          return {
            'review_id': result.reviewId,
            'event': result.event,
            'finding_count': result.findingCount,
            'inline_count': result.inlineCount,
            'used_body_fallback': result.usedFallback,
            'status': 'published',
          };
        },
    resolveStudioKey: resolvePrNodeId,
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
    await globalDb.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: Value(bootstrapDeviceId),
        // The spawning desktop IS the server owner's machine.
        userId: Value(ownerUserId),
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
  // Membership-scoped picker: a user sees only workspaces they belong to.
  Future<List<RemoteWorkspaceSummary>> listWorkspaces(String userId) async {
    final memberships = await membershipRepository.getForUser(userId);
    final memberOf = {for (final m in memberships) m.workspaceId};
    final rows = await globalDb.workspaceRegistryDao.getAll();
    return [
      for (final w in rows)
        if (memberOf.contains(w.id)) (id: w.id, name: w.name),
    ];
  }

  // The registry existence gate wired into the `repo/call` +
  // `sub/subscribe` chokepoints: an id the registry doesn't know (a stale
  // client-held active workspace, a typo, a probing peer) is refused BEFORE
  // any workspace database is opened — opening CREATES the file, so an
  // ungated id sprays empty ghost `workspace.db` directories on every call.
  Future<bool> workspaceExists(String workspaceId) async =>
      await globalDb.workspaceRegistryDao.getById(workspaceId) != null;

  final initialWorkspaces = await _bootStep(
    'listing workspaces',
    () => listWorkspaces(ownerUserId),
  );

  // Decoded on first audited call that carries an IP (the embedded RIR table
  // is gzip+base64 — building it eagerly would tax every boot for a table
  // most headless runs never query).
  GeoIpLookup? geoIpLookup;
  final repoOps = RepoOpDispatcher(
    registry: catalog.ops,
    mapException: mapAppExceptionToRpc,
    workspaceExists: workspaceExists,
    // The membership chokepoint: every workspace-scoped op resolves the
    // caller's role (non-members are refused; viewers/guests are read-only)
    // and code-bearing ops additionally check the per-repo grant.
    resolveRole: (workspaceId, userId) async =>
        (await membershipRepository.getMember(workspaceId, userId))?.role,
    resolveRepoGrant: (workspaceId, userId, repoId) async =>
        (await membershipRepository.getRepoGrants(
          workspaceId,
          userId,
        ))[repoId] ??
        RepoGrantLevel.none,
    // Audit backbone: every successful mutating op appends who did what,
    // from where. The GeoIP table is decoded lazily on the first audited
    // call that actually carries an IP — never on the boot path.
    recordActivity:
        ({
          required String workspaceId,
          required String userId,
          required String deviceId,
          required String action,
          String? targetType,
          String? targetId,
          String? ip,
        }) => userActivityRepository.append(
          UserActivityEntry(
            id: const Uuid().v4(),
            workspaceId: workspaceId,
            userId: userId,
            deviceId: deviceId,
            action: action,
            targetType: targetType,
            targetId: targetId,
            ip: ip,
            countryCode: ip == null
                ? null
                : (geoIpLookup ??= GeoIpLookup()).countryCodeFor(ip),
            createdAt: DateTime.now(),
          ),
        ),
    // Universal idempotency ledger (PRD 19 §3): a mutating call carrying a
    // logical-action key is deduped here before its handler runs.
    writeLedger: DaoWriteLedger(workspaceDbs),
    // Unified action guardrails (PRD 24 §3): the SAME guard the MCP dispatcher
    // uses now gates the operator's own repo-RPC clicks by declared effect class.
    actionGuard: actionGuard,
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

  // Inbound signed webhooks → pipeline runs. The token in `/webhooks/<token>`
  // resolves the trigger (and its workspace); the HMAC signature is verified
  // against that token, duplicates are dropped, and the delivery is logged.
  final webhookDeliveryService = WebhookDeliveryService(
    triggerRepository: pipelineTriggerRepository,
    deliveryRepository: WebhookDeliveryRepositoryImpl(workspaceDbs),
    startRun:
        ({
          required String templateId,
          required String workspaceId,
          String? triggerEventType,
          Map<String, dynamic>? triggerPayload,
          String? dedupKey,
        }) => pipeline.engine.start(
          templateId,
          workspaceId: workspaceId,
          triggerEventType: triggerEventType,
          triggerPayload: triggerPayload,
          dedupKey: dedupKey,
        ),
  );

  // ── Multi-vendor ticket sync (PRD 11) ──
  // Control Center tickets are primary; enabled vendor connections mirror local
  // changes out (the coordinator pushes on ticket events) and pull vendor
  // changes back in (the webhook handler). Adapters authenticate from the server
  // environment: the gh token for GitHub Issues, LINEAR_API_KEY for Linear, and
  // JIRA_BASE_URL + JIRA_EMAIL + JIRA_API_TOKEN for Jira. Per-workspace, per-
  // vendor connections live in `ticket_sync_configs`.
  final env = Platform.environment;
  final linearSyncDio = createDio(baseUrl: 'https://api.linear.app/graphql');
  final linearSyncKey = env['LINEAR_API_KEY'] ?? '';
  if (linearSyncKey.isNotEmpty) {
    linearSyncDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = linearSyncKey;
          handler.next(options);
        },
      ),
    );
  }
  final githubIssuesDio = createDio(baseUrl: 'https://api.github.com');
  if (ghToken.isNotEmpty) {
    githubIssuesDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Bearer $ghToken';
          handler.next(options);
        },
      ),
    );
  }
  final jiraSyncDio = createDio(baseUrl: env['JIRA_BASE_URL'] ?? '');
  final jiraEmail = env['JIRA_EMAIL'] ?? '';
  final jiraToken = env['JIRA_API_TOKEN'] ?? '';
  if (jiraEmail.isNotEmpty && jiraToken.isNotEmpty) {
    final basic = base64Encode(utf8.encode('$jiraEmail:$jiraToken'));
    jiraSyncDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Basic $basic';
          handler.next(options);
        },
      ),
    );
  }
  final clickupSyncDio = createDio(baseUrl: 'https://api.clickup.com');
  final clickupToken = env['CLICKUP_API_TOKEN'] ?? '';
  if (clickupToken.isNotEmpty) {
    // ClickUp personal tokens go in the Authorization header verbatim (no
    // `Bearer` prefix).
    clickupSyncDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = clickupToken;
          handler.next(options);
        },
      ),
    );
  }
  final ticketSyncConfigRepository = DaoTicketSyncConfigRepository(
    workspaceDbs,
  );
  final ticketSyncEngine = TicketSyncEngine(
    adapters: [
      LinearTicketSyncAdapter(linearSyncDio),
      GitHubIssuesTicketSyncAdapter(githubIssuesDio),
      JiraTicketSyncAdapter(jiraSyncDio),
      ClickUpTicketSyncAdapter(clickupSyncDio),
    ],
    repository: ticketRepository,
    configRepository: ticketSyncConfigRepository,
    linkRepository: DaoTicketSyncLinkRepository(workspaceDbs),
    logRepository: DaoTicketSyncLogRepository(workspaceDbs),
  );
  // §188: bind the deferred ref the catalog's `ticket_sync.syncNow` op reads.
  ticketSyncEngineRef = ticketSyncEngine;
  // Pushes local ticket changes out to every enabled vendor (event-driven).
  MultiVendorTicketSyncCoordinator(
    eventBus: eventBus,
    engine: ticketSyncEngine,
    repository: ticketRepository,
  ).start();
  // Inbound vendor webhooks → CC tickets, behind HMAC verification.
  final ticketSyncWebhookHandler = TicketSyncWebhookHandler(
    engine: ticketSyncEngine,
    configRepository: ticketSyncConfigRepository,
    eventBus: eventBus,
  );

  // One pool across every transport: a user's direct-WSS, web, and relayed
  // phone sessions all draw from the same rate budget.
  final rateLimiterPool = RemoteRateLimiterPool();

  // Pre-auth invite redemption (`POST /invites/redeem`): validates the one-
  // time code, JIT-provisions the user + membership + repo grants, then mints
  // the redeemer's first device credential so the new client can immediately
  // authenticate over the normal PSK handshake.
  Future<Map<String, dynamic>> redeemInvite(Map<String, dynamic> body) async {
    final code = body['code'];
    if (code is! String || code.isEmpty) {
      throw const AuthException('Invite is invalid or expired');
    }
    final redeemed = await inviteService.redeem(
      code: code,
      handle: body['handle'] as String?,
      displayName: body['display_name'] as String?,
      email: body['email'] as String?,
    );
    final platform = switch (body['platform']) {
      final String p when p.isNotEmpty => p,
      _ => 'web',
    };
    final deviceId = const Uuid().v4();
    final psk = RemoteControlCrypto.generatePsk();
    await globalDb.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: Value(deviceId),
        userId: Value(redeemed.user.id),
        workspaceId: Value(redeemed.invite.workspaceId),
        label: Value(switch (body['device_label']) {
          final String l when l.isNotEmpty => l,
          _ => '${redeemed.user.displayName} ($platform)',
        }),
        platform: Value(platform),
        pskRef: const Value('file'),
        status: const Value(PairedDeviceStatus.active),
        expiresAt: Value(
          DateTime.now().add(RemotePairingLifecycle.credentialLifetime),
        ),
      ),
    );
    await secrets.writePsk(deviceId, psk);
    return {
      'device_id': deviceId,
      'psk': psk,
      'workspace_id': redeemed.invite.workspaceId,
      'role': redeemed.member.role.wireName,
      'user': UserDto(
        id: redeemed.user.id,
        handle: redeemed.user.handle,
        displayName: redeemed.user.displayName,
        email: redeemed.user.email,
      ).toJson(),
      if (config.publicUrl.isNotEmpty) 'server_url': config.publicUrl,
      // The full connection descriptor (every reachable path + the identity
      // fingerprint the new client pins) so a redeemed invite works over any
      // topology — LAN box and VPS alike (PRD 15 §6).
      'descriptor': (await descriptorService.describe()).toJson(),
      'signaling_url': config.signalingUrl,
      'room': serverIdentity.relayRoom,
    };
  }

  final server = LocalRpcServer(
    dispatcher: mcpDispatcher,
    devicesDao: globalDb.pairedDeviceDao,
    secrets: secrets,
    workspaceExists: workspaceExists,
    eventBus: eventBus,
    workspaceResolver: listWorkspaces,
    repoOps: repoOps,
    watchQueries: catalog.watch,
    inviteRedeemer: redeemInvite,
    oidc: oidcService,
    identity: serverIdentity,
    rateLimiters: rateLimiterPool,
    // Persistent `/proxy/media` disk cache: avatars/favicons/feed images stop
    // costing an upstream round trip on every repeat render (see MediaCache).
    mediaCacheDir: p.join(config.dataDir, 'media_cache'),
    // Font variants, cached separately so image churn cannot evict the few
    // files the UI is actively rendering with.
    fontCacheDir: p.join(config.dataDir, 'font_cache'),
    fontFile: fontCatalog.resolveFileUrl,
    webhookHandler:
        ({
          required String token,
          required Map<String, String> headers,
          required String body,
        }) async {
          final result = await webhookDeliveryService.handle(
            token: token,
            headers: headers,
            body: body,
          );
          return (status: result.statusCode, body: result.body);
        },
    ticketWebhookHandler:
        ({
          required String vendor,
          required String? workspaceId,
          required Map<String, String> headers,
          required String body,
        }) async {
          final result = await ticketSyncWebhookHandler.handle(
            vendor: vendor,
            workspaceId: workspaceId,
            headers: headers,
            body: body,
          );
          return (status: result.statusCode, body: result.body);
        },
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
      final clip = await loadMeetingAudioClip(
        MeetingAudioRequest(audioDirPath: dir),
      );
      if (clip == null) {
        return null;
      }
      final file = File(clip.playablePath);
      return file.existsSync() ? file : null;
    },
    // Serves a workspace's persisted logo over `/workspace/logo` for thin-
    // clients. Resolves the file only for the signed workspace (getById is
    // id-scoped), so a foreign workspace is simply not found → 404.
    workspaceLogo: ({required workspaceId}) async {
      final ws = await workspaceRepository.getById(workspaceId);
      final path = ws?.logoPath;
      if (path == null || path.isEmpty) {
        return null;
      }
      final file = File(path);
      return file.existsSync() ? file : null;
    },
    // Streams the server-generated soundscape audio over `/soundscape/*`. The
    // hub keys sessions by `(workspaceId, mood)` and shares one generative
    // session across all listeners; the signed URL (`soundscape:<ws>/<mood>`)
    // is verified by the route before these run.
    soundscapeStream: soundscapeHub.streamFor,
    soundscapePlaylist: soundscapeHub.playlistFor,
    soundscapeSegment: soundscapeHub.segmentFor,
    // Authorizes each `/proxy/vscode/<sid>/` request against a live code-server
    // session (capability authz): unknown / expired / foreign-workspace → 403.
    codeServerLookup: codeServerSessions.lookup,
    // /healthz's `codeGraph` block: whether background indexing is watching /
    // indexing / has runs pending. Pure in-memory snapshot, safe to expose —
    // counts only, no paths or workspace data.
    codeGraphStatus: () {
      final s = codeGraphWatch.status;
      return {
        'watching': s.watching,
        'indexing': s.indexing,
        'pending': s.pending,
      };
    },
    // Receives the bridge extension's in-editor open-file reports (POSTed to
    // `/proxy/vscode/<sid>/__cc_open__`) and fans them out to the subscribed
    // client so navigating the editor opens a NEW app tab instead of swapping
    // the current one.
    codeServerReport: (sid, absPath, line) => codeServerSessions.reportOpen(
      sessionId: sid,
      absPath: absPath,
      line: line,
    ),
    // Receives the bridge extension's dirty-state reports (same endpoint,
    // `{type:'dirty'}`) and fans them out so the app can toggle the per-tab
    // unsaved-changes dot.
    codeServerReportDirty: (sid, absPath, dirty) => codeServerSessions
        .reportDirty(sessionId: sid, absPath: absPath, dirty: dirty),
    // Serves the reverse command SSE stream (`/__cc_commands__`) the bridge
    // extension subscribes to for Save-on-close and future editor commands.
    codeServerCommandStream: codeServerSessions.commandStream,
    address: config.bindAddress,
    port: config.port,
    securityContext: securityContext,
    // Permit a plaintext non-loopback bind only when explicitly opted in AND no
    // in-process TLS is configured (TLS always wins). The standard container
    // topology: a TLS-terminating proxy fronts cc_server on a private network.
    allowInsecureBind: config.allowInsecure && securityContext == null,
    allowedOrigins: config.allowedOrigins,
  );

  // Mount the MCP surface on the main listener (single-port topology): the
  // control routes `/mcp` + `/sse` through it from here on. When the listener
  // terminates TLS in-process, start() also binds a plaintext loopback
  // companion for server-spawned agent CLIs.
  mcpControl.attachMainServer(server);

  await _bootStep('starting RPC server', server.start);

  // The descriptor advertises the ACTUAL bound port (differs from config
  // under `--port 0`, the desktop's ephemeral-port spawn).
  descriptorService.boundPort = server.boundPort;

  // Now that the RPC server has bound a port, tell the code-server service where
  // its bundled bridge extension should POST in-editor open-file reports — the
  // server's own loopback base. (The port isn't known when the service is built
  // above, so it's wired here.) The extension runs server-side, co-located with
  // cc_server, so loopback + the bound port always reaches it.
  {
    final proxyScheme = securityContext != null ? 'https' : 'http';
    codeServerSessions.resolveProxyBase = () =>
        Uri.parse('$proxyScheme://127.0.0.1:${server.boundPort}');
  }

  // ── Speech recognizer preflight + dylib diagnostic ──
  // Load the recognizer once (off the ready path, so it never delays boot)
  // when a voice model resolved, then UNLOAD it again. This surfaces — loudly,
  // in the server log the desktop pipes through — whether the inference native
  // actually loaded in THIS pure-Dart process: the #1 cause of "audio captured
  // + WAV retained, but transcript empty" is the dylib failing to resolve here
  // (nothing bundles it into a pure-Dart binary; the desktop must hand us its
  // bundled-dylib dir via CC_NATIVE_LIB_DIR).
  // The model is NOT kept warm: loaded ASR weights are hundreds of MB and most
  // sessions never record, so the first recording pays a one-time reload while
  // its first audio window buffers (capture is never lost — audio queues).
  if (meetingTranscriber != null) {
    final transcriber = meetingTranscriber;
    CcHostLog.info(
      'cc_server: preflighting speech recognizer (inference dylib: '
      '${inferenceLibPath ?? '<unresolved — set $nativeLibDirEnvVar, drop the '
              'dylib in ${config.dataDir}, or ship it beside the binary>'})',
    );
    unawaited(
      transcriber
          .initialize()
          .then((_) async {
            CcHostLog.info(
              'cc_server: speech recognizer verified — meeting transcription '
              'enabled (model unloaded until a recording starts)',
            );
            await transcriber.unload();
          })
          .catchError((Object e) {
            CcHostLog.error(
              'cc_server: speech recognizer FAILED to load — meeting transcripts '
              'will be EMPTY. The cc_inference dylib did not resolve in this '
              'process; ensure $nativeLibDirEnvVar points at a dir containing '
              '${platformLibraryFileName(inferenceLibraryBaseName)}. Cause: $e',
            );
          }),
    );
  }

  // ── code-server (embedded editor) warm-up ──
  // Eagerly download the pinned code-server standalone archive + the curated
  // language extensions, OFF the ready path so the embedded editor is warm by
  // the time a user opens a file — the first `codeServer.open` then only spawns
  // an already-installed binary instead of paying a multi-second download.
  // Best-effort + non-fatal: a failed warm-up degrades to a lazy on-demand
  // download on first open (or `unavailable` if that also fails).
  CcHostLog.info(
    'cc_server: warming code-server (managed dir: ${config.dataDir}/code-server)',
  );
  unawaited(
    codeServerSessions
        .warmUp()
        .then((_) {
          CcHostLog.info(
            'cc_server: code-server ready — embedded editor enabled',
          );
        })
        .catchError((Object e) {
          CcHostLog.warning(
            'cc_server: code-server warm-up failed — the editor will retry on '
            'first open. Cause: $e',
          );
        }),
  );

  // ── On-device model warm-up (embedding + diarization) ──
  // The two FIXED models are force-installed at boot, alongside the
  // code-server warm-up: models are the only artifacts the server fetches at
  // runtime (the native dylibs ship in the bundle), so a fresh deploy lights
  // up semantic search + diarization without any client action. Runs through
  // the same [ManagedModelControl]s the `models.*` RPC ops drive, so install
  // is a no-op when already on disk, a concurrently connected client sees the
  // boot download's live progress over `models.watch*`, and a failed download
  // surfaces as the control's `error` state (retried on next boot or via the
  // client's install button) without blocking the ready path. The ASR voice
  // model stays opt-in — it is SELECTABLE, not unique, and multi-hundred-MB.
  CcHostLog.info(
    'cc_server: ensuring on-device models (embedding + diarization) under '
    '${config.dataDir}/models',
  );
  unawaited(embeddingModelControl.install());
  unawaited(diarizationModelControl.install());

  // ── Client relay (broker rendezvous, PRD 15) ──
  // cc_server OWNS one N-way signaling room: it joins the broker as the room
  // owner, publishes the admission-hash set derived from every active paired
  // device, and serves an authenticated RPC session per relayed client
  // (desktop, web, or phone) over the E2E-encrypted chunked relay — the
  // guaranteed fallback when no direct path exists. Watching the device
  // table covers startup, mint, and revoke uniformly (revocation evicts the
  // live broker connection too).
  final relayHost = RemoteRelayHost(
    signalingUrl: config.signalingUrl,
    identity: serverIdentity,
    dispatcher: mcpDispatcher,
    workspaceExists: workspaceExists,
    devicesDao: globalDb.pairedDeviceDao,
    secrets: secrets,
    eventBus: eventBus,
    workspaceResolver: listWorkspaces,
    repoOps: repoOps,
    watchQueries: catalog.watch,
    rateLimiters: rateLimiterPool,
  );
  // Dials the EXTERNAL signaling broker (`wss://signaling.usectrl.dev` by
  // default). Awaited on the boot path with no bound, it made an unreachable or
  // slow broker look like a hung server: boot simply stopped after the last
  // warm-up line and never reached the MCP server or the ready banner. Bounded
  // and announced — the relay retries on its own, so a timeout costs remote
  // pairing until it reconnects, not the whole server.
  await _bootStepBounded(
    'connecting relay (${config.signalingUrl})',
    relayHost.start,
    onTimeout: 'remote pairing will connect in the background',
  );

  // ── Network runtime (PRD 15 §5/§7) ──
  // mDNS LAN advertisement, the persisted share-this-server tunnel, and
  // relay-usage accounting. Started after the RPC port bound (paths embed it)
  // and after the relay host exists (usage reads its counters).
  final networkRuntime = NetworkRuntime(
    config: config,
    descriptorService: descriptorService,
    boundPort: server.boundPort,
    relayHost: relayHost,
  );
  networkRuntimeHolder.value = networkRuntime;
  // mDNS + tunnel: also network, also previously unbounded on the boot path.
  await _bootStepBounded(
    'starting network runtime (mDNS + tunnel)',
    networkRuntime.start,
    onTimeout: 'LAN discovery / tunnel will come up in the background',
  );

  // Agents appear on the same presence roster as humans, synthesized from
  // run lifecycle + the pending-approval gate (PRD 16 §2/§3).
  _bootMark('starting presence + background listeners');
  final agentPresenceSynthesizer = AgentPresenceSynthesizer(
    hub: presenceHub,
    runLogs: agentRunLogRepository,
    agents: agentRepository,
    confirmations: pendingConfirmationRegistry,
  );
  await agentPresenceSynthesizer.start();

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
  eventBus.on<WorkspaceCreated>().listen(
    (event) => unawaited(workspaceSeeder.seed(event.workspaceId)),
  );

  // Seed the built-in starter eval suites (PRD 21 §5) so the evals feature
  // proves itself on CC's own workflows from day one. Idempotent by name
  // (skips a suite that already exists), self-logging (never throws into the
  // bus). Workspace-scoped writes only.
  eventBus.on<WorkspaceCreated>().listen(
    (event) => unawaited(() async {
      try {
        final suites = buildStarterSuites(
          event.workspaceId,
          now: DateTime.now(),
          newId: () => const Uuid().v4(),
        );
        for (final suite in suites) {
          final existing = await evalsRepository.suiteByName(
            event.workspaceId,
            suite.name,
          );
          if (existing == null) {
            await evalsRepository.upsertSuite(suite);
          }
        }
      } on Object catch (e, st) {
        CcHostLog.error(
          'cc_server: starter eval-suite seeding failed: $e',
          e,
          st,
        );
      }
    }()),
  );

  // Team leader-routing: when a ticket is assigned to a team, dispatch the
  // leader with the operating protocol + skill-surfaced roster; re-wake it when
  // a delegated member finishes (bounded by the no-action dedup guard).
  TeamRoutingService(
    eventBus: eventBus,
    teamRepository: teamRepository,
    agentRepository: agentRepository,
    ticketRepository: ticketRepository,
    runLogRepository: agentRunLogRepository,
    activityRepository: TeamActivityRepositoryImpl(workspaceDbs),
    leaderDispatch: MessagingTeamLeaderDispatch(messagingService),
  ).start();
  PipelineTriggerDispatcher(
    eventBus: eventBus,
    engine: pipeline.engine,
    triggerRepository: pipelineTriggerRepository,
  ).start();
  // Time-based triggers: ticks every minute, fires due cron/interval schedules
  // (CatchUpLatestOnly), and records each fire in the cron_executions ledger so
  // a restart mid-slot never double-starts a run. Evaluated in UTC.
  PipelineSchedulerService(
    triggerRepository: pipelineTriggerRepository,
    engine: pipeline.engine,
    ledger: CronExecutionLedgerImpl(workspaceDbs),
  ).start();
  SubPipelineResumeListener(
    eventBus: eventBus,
    engine: pipeline.engine,
    repository: pipelineRunRepository,
  ).start();
  // Bound the growth of append-only audit/log tables (activity_log,
  // webhook_deliveries, cron_executions) plus finished runs' activity
  // transcripts: daily prune past a generous per-table window.
  DatabaseRetentionService(
    workspaces: workspaceDbs,
    onError: (message) => CcHostLog.warning('retention: $message'),
  ).start();
  // Continuous skill re-verification (PRD 23 §6): periodically re-scan skills
  // whose recorded verdict predates the current rules version, so a tightened
  // rule re-examines already-installed content (clears or quarantines it).
  SkillReVerifyService(
    workspaces: workspaceRepository,
    bundles: skillBundles,
    onError: (message) => CcHostLog.warning('skill re-verify: $message'),
  ).start();
  PipelineCostRollupListener(
    eventBus: eventBus,
    runLogRepository: agentRunLogRepository,
    runRepository: pipelineRunRepository,
  ).start();
  // Budget governance (PRD 09): evaluate an agent's spend the moment each run
  // completes — a soft-threshold crossing records a warning incident, and an
  // exhausted budget records a hard incident AND auto-pauses the agent (its
  // lifecycle flips to `paused`, so it stops being dispatchable).
  BudgetEvaluationListener(
    eventBus: eventBus,
    governance: BudgetGovernanceService(
      agentRepository: agentRepository,
      enforcement: BudgetEnforcementService(
        agentRunLogRepository: agentRunLogRepository,
        agentRepository: agentRepository,
        eventBus: eventBus,
      ),
      budgetRepository: DaoBudgetPolicyRepository(workspaceDbs),
      eventBus: eventBus,
      activityLogger: ActivityLogger(eventBus: eventBus),
    ),
  ).start();
  PipelineStepResumeListener(
    eventBus: eventBus,
    runLogRepository: agentRunLogRepository,
    engine: pipeline.engine,
    // Plan drift (PRD 17 §6): a finished node that diverged from its
    // declared scope under `stopAndAsk` HOLDS here until the operator
    // resumes it via `orchestration.continueNode`.
    driftGate: planDriftService.evaluate,
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
      // BEFORE resumeAll, always: a background-index run row is a projection of
      // work the code-graph watcher owns, not a resumable pipeline. Left in
      // place, `resumeAll` would find its running `index` step and execute the
      // template's own body — a full index of the LINKED checkout (never the
      // worktree partition the row was for) during boot, which is precisely what
      // deferring the watcher until after the ready banner exists to prevent.
      final closed = await codeIndexRunReporter.reapInterrupted();
      if (closed > 0) {
        CcHostLog.info(
          'cc_server: closed $closed interrupted code-index run(s)',
        );
      }
      await pipeline.engine.resumeAll();
    } on Object catch (e, st) {
      CcHostLog.error('cc_server: pipeline resumeAll failed: $e', e, st);
    }
  }());
  // Durable goals: re-dispatch every objective still active when the server
  // stopped — the state lives in SQLite, so `/goal`/`/loop` survive restarts.
  // Best-effort, mirroring the pipeline resume above.
  unawaited(() async {
    try {
      await goalSupervisor.reconcileOnStartup();
    } on Object catch (e, st) {
      CcHostLog.error('cc_server: goal reconciliation failed: $e', e, st);
    }
  }());

  // Start the MCP surface when the persisted config has it enabled. A
  // companion bind failure (TLS topology, port in use) is logged but does not
  // abort the RPC server.
  try {
    await mcpControl.startIfEnabled();
    final mcpStatus = await mcpControl.status();
    if (mcpStatus.running) {
      CcHostLog.info(
        'cc_server MCP surface mounted on the main listener '
        '(/mcp on :${mcpStatus.port})',
      );
    }
  } catch (e) {
    CcHostLog.warning('cc_server MCP surface failed to start: $e');
  }
  // Load the persisted external-MCP approval posture and apply it to the shared
  // dispatcher's tier gate before the first tool call.
  try {
    await mcpClientControl.init();
  } catch (e) {
    CcHostLog.warning(
      'cc_server: external MCP approval posture load failed: $e',
    );
  }
  final ccServer = CcServer._(globalDb, workspaceDbs, server, mcpControl)
    .._meetingReconciler = meetingReconciler
    .._goalSupervisor = goalSupervisor
    .._meetingRecording = meetingRecording
    .._dictationService = dictationService
    .._voiceModelControl = voiceModelControl
    .._embeddingModelControl = embeddingModelControl
    .._diarizationModelControl = diarizationModelControl
    .._relayHost = relayHost
    .._networkRuntime = networkRuntime
    .._presenceHub = presenceHub
    .._agentPresenceSynthesizer = agentPresenceSynthesizer
    .._syncFeed = syncFeed
    .._checkerListener = checkerListener
    .._worktreeGcListener = worktreeGcListener
    .._notificationFeedRecorder = notificationFeedRecorder
    .._codeGraphWatch = codeGraphWatch
    .._mcpClientService = mcpClientService
    .._codeServer = codeServerSessions
    .._pendingConfirmations = pendingConfirmationRegistry
    .._chatConnector = chatConnector;

  // ── External MCP server discovery + connect (PRD 01 phases 1.1–1.3) ──
  // Auto-discover MCP servers the user already configured for other tools
  // (Claude/Codex/Cursor/Gemini/VS Code/Windsurf/OpenCode + standalone
  // `.mcp.json`) and connect the enabled ones, bridging their tools into the
  // registry. Fire-and-forget after boot so a slow/dead server never blocks
  // startup; best-effort — a discovery failure is logged, never fatal.
  unawaited(() async {
    try {
      final home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
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

  // ── Live GitHub PR freshness ──
  // The open-PR poller sweeps every workspace's linked repos: cheap conditional
  // (ETag) probes on a fast cadence for watched workspaces, a slow baseline for
  // the rest, full GraphQL fetch + snapshot diff only when something actually
  // changed. Changes land in the caches table (pushing the live PR list to
  // every subscribed client), publish domain events (new PR / merged / closed
  // → notifications), and signal open PR-detail streams to re-validate.
  openPrPoller?.start();
  ccServer._openPrPoller = openPrPoller;
  ccServer._prChangeSignals = prChangeSignals;

  // The notifications-API poll rides GitHub's own inbox (review requests,
  // mentions, PR activity): one cheap endpoint, `If-Modified-Since`-gated,
  // cadence dictated by GitHub's `X-Poll-Interval`. Review requests become
  // `PrReviewRequested` events (→ client notifications); any PR activity on a
  // linked repo triggers a targeted refresh of that PR's open streams.
  final githubNotificationPoller = ghToken.isEmpty
      ? null
      : GitHubNotificationPollingService(
          githubClient: serverGitHubClient,
          eventBus: eventBus,
          changeSignals: prChangeSignals,
          identityCache: viewerGitHubIdentity,
          workspacesForRepo: (repoFullName) async {
            final wanted = repoFullName.toLowerCase();
            final workspaces = await workspaceRepository.watchAll().first;
            final ids = <String>[];
            for (final w in workspaces) {
              final linked = await workspaceRepository
                  .watchReposForWorkspace(w.id)
                  .first;
              final links = linked.any(
                (r) => r.hasGitHubRemote && r.fullName.toLowerCase() == wanted,
              );
              if (links) {
                ids.add(w.id);
              }
            }
            return ids;
          },
          onWorkspaceTouched: (workspaceId) =>
              unawaited(openPrPoller?.pollSoon(workspaceId) ?? Future.value()),
          // The GitHub inbox is cross-workspace, so the dedupe store lives in
          // global.db's server_meta — not in any workspace file.
          loadDedupeState: () =>
              globalDb.workspaceRouteDao.meta('githubNotificationDedupe'),
          saveDedupeState: (state) => globalDb.workspaceRouteDao.setMeta(
            'githubNotificationDedupe',
            state,
          ),
        );
  githubNotificationPoller?.start();
  ccServer._githubNotificationPoller = githubNotificationPoller;

  // ── Ticket sync pull fallback ──
  // Vendor webhooks require this server to be publicly reachable, which it
  // often is not (no tunnel). A modest periodic pull keeps vendor-side ticket
  // changes flowing in regardless; the sweep skips workspaces with no enabled
  // pull-capable config, and `applyPull` dedupes anything a webhook already
  // delivered.
  ccServer._ticketSyncPullTimer = Timer.periodic(const Duration(minutes: 5), (
    _,
  ) async {
    try {
      final engine = ticketSyncEngineRef;
      if (engine == null) {
        return;
      }
      final workspaces = await workspaceRepository.watchAll().first;
      for (final w in workspaces) {
        final configs = await ticketSyncConfigRepository.enabledForWorkspace(
          w.id,
        );
        if (configs.any((c) => c.direction.allowsPull)) {
          await engine.pullNow(workspaceId: w.id);
        }
      }
    } on Object catch (e) {
      CcHostLog.warning('cc_server: ticket sync pull sweep failed: $e');
    }
  });

  // ── Server-side Google Calendar sync ──
  // The server syncs every workspace's connected calendar into its DB on a fixed
  // cadence (no-op until an account is connected via the GUI `calendar.*Connect`
  // ops or `cc_server calendar connect`); thin clients (web/desktop) just READ
  // the result over the existing `calendar.watch*` RPC surface.
  serverCalendar.sync.start();
  ccServer._calendarSync = serverCalendar.sync;
  ccServer._weatherService = weatherService;
  ccServer._soundscapeHub = soundscapeHub;
  weatherService.start();

  // ── Fleet lease reaping (PRD 20 §8) ──
  // A worker that vanishes mid-run has its lease reaped and the job retried per
  // its policy or surfaced as failed — never silently lost. Short cadence so a
  // dead worker's jobs recover quickly; the reap is cheap (indexed scan).
  ccServer._fleetScheduler = fleetScheduler;
  ccServer._fleetLocalExecutor = localJobExecutor;
  ccServer._fleetReapTimer = Timer.periodic(const Duration(seconds: 30), (
    _,
  ) async {
    try {
      await fleetScheduler.reapExpiredLeases();
    } on Object catch (e) {
      CcHostLog.warning('cc_server: fleet lease reap failed: $e');
    }
  });

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
  ccServer._newsfeedRefreshTimer = Timer.periodic(const Duration(minutes: 30), (
    _,
  ) async {
    try {
      await newsfeedRepository.refreshAll();
    } on Object catch (e) {
      CcHostLog.warning('cc_server: newsfeed refresh failed: $e');
    }
  });

  // Runtime-state GC (PRD 09): reap agent runtime-state rows stale past the
  // 7-day threshold. Mirrors the orphan-run reaper — one best-effort sweep at
  // boot (clearing rows a prior session left behind) plus a periodic sweep.
  final runtimeStateGcSweeper = RuntimeStateGcSweeper(
    repository: DaoAgentRuntimeStateRepository(workspaceDbs),
  );
  unawaited(() async {
    try {
      await runtimeStateGcSweeper.sweep();
    } on Object catch (e) {
      CcHostLog.warning('cc_server: initial runtime-state GC sweep failed: $e');
    }
  }());
  ccServer._runtimeStateGcSweepTimer = Timer.periodic(
    const Duration(hours: 6),
    (_) async {
      try {
        await runtimeStateGcSweeper.sweep();
      } on Object catch (e) {
        CcHostLog.warning('cc_server: runtime-state GC sweep failed: $e');
      }
    },
  );

  // The ready banner the desktop parses (cc_server_process.dart). Emitted
  // directly like the booting line — always printed, no `[level]` prefix.
  _emitLog(
    false,
    'cc_server ready on ${config.bindHost}:${server.boundPort} '
    '(data: ${config.dataDir}, workspaces: ${initialWorkspaces.length})',
  );

  // Background code-graph indexing starts only AFTER the ready banner. The
  // desktop parses that banner with a hard 20s timeout and kills the child on
  // expiry (cc_server_process.dart), so indexing must never compete with the
  // path to it. The service additionally holds its first sweep for
  // `--code-index-defer` seconds so the desktop's initial RPC burst lands on
  // an idle database connection.
  if (config.codeIndexEnabled) {
    codeGraphWatch.start();
    CcHostLog.info(
      'cc_server: code-graph indexing armed '
      '(first sweep in ${config.codeIndexDeferSeconds}s)',
    );
  } else {
    CcHostLog.info('cc_server: code-graph indexing disabled by config');
  }

  // Chat transports dial out after the banner for the same reason indexing does:
  // the desktop kills this process if the banner is late, and an unreachable
  // provider must cost chat connectivity, never the whole server.
  unawaited(() async {
    try {
      await chatConnector.start();
    } on Object catch (e, st) {
      CcHostLog.error('cc_server: chat connector start failed: $e', e, st);
    }
  }());
  return ccServer;
}

/// A late-bound holder for services constructed after the RPC catalog (the
/// catalog's deferred closures read [value] per request).
class _Late<T> {
  /// The held value, once constructed.
  T? value;
}

/// Detects the capabilities of the server host for the implicit local worker
/// (PRD 20 §1). Deliberately lightweight (no subprocess probing) so startup
/// stays fast; a Flutter/ML-capable machine that wants those axes joins the
/// fleet as a dedicated `cc_worker` declaring them.
WorkerCapabilities _detectLocalWorkerCapabilities() {
  final String os;
  if (Platform.isMacOS) {
    os = 'macos';
  } else if (Platform.isLinux) {
    os = 'linux';
  } else if (Platform.isWindows) {
    os = 'windows';
  } else {
    os = 'unknown';
  }
  final version = Platform.version.toLowerCase();
  final arch = version.contains('arm64') || version.contains('aarch64')
      ? 'arm64'
      : 'x64';
  final sandboxBackends = <String>{
    if (Platform.isMacOS) 'native-macos',
    if (Platform.isLinux) 'native-linux',
  };
  return WorkerCapabilities(
    os: os,
    arch: arch,
    cores: Platform.numberOfProcessors,
    ramMb: 0,
    sandboxBackends: sandboxBackends,
    alwaysOn: true,
    acceptsParallel: true,
  );
}

/// Splits a stored per-adapter argv string into arguments.
///
/// Whitespace-separated, honouring single and double quotes so a flag carrying
/// a spaced value survives. Deliberately NOT a shell parse: these arguments are
/// appended to an argv list and executed directly, never through a shell, so
/// interpreting metacharacters here would invent an injection surface that the
/// exec path does not otherwise have.
List<String> _splitAdapterArgs(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const [];
  }
  final out = <String>[];
  final buffer = StringBuffer();
  String? quote;
  for (final rune in raw.trim().runes) {
    final ch = String.fromCharCode(rune);
    if (quote != null) {
      if (ch == quote) {
        quote = null;
      } else {
        buffer.write(ch);
      }
      continue;
    }
    if (ch == '"' || ch == "'") {
      quote = ch;
      continue;
    }
    if (ch.trim().isEmpty) {
      if (buffer.isNotEmpty) {
        out.add(buffer.toString());
        buffer.clear();
      }
      continue;
    }
    buffer.write(ch);
  }
  if (buffer.isNotEmpty) {
    out.add(buffer.toString());
  }
  return out;
}

/// Decodes a stored per-adapter env override map.
///
/// A malformed blob yields an EMPTY map rather than throwing: a corrupt
/// settings row must not take agent dispatch down, and launching without an
/// override is the safe direction.
Map<String, String> _decodeAdapterEnv(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const {};
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return {
        for (final entry in decoded.entries)
          if (entry.value is String) '${entry.key}': entry.value as String,
      };
    }
  } on FormatException {
    // Fall through to the empty map.
  }
  return const {};
}
