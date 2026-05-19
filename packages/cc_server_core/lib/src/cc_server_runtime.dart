import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, UserDto, ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart'
    show reviewSpaceName;
import 'package:cc_domain/core/domain/entities/role_definition.dart';
import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/core/domain/services/activity_logger.dart';
import 'package:cc_domain/core/domain/services/memory_access_policy.dart';
import 'package:cc_domain/core/domain/services/user_mention_parser.dart';
import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/agents/domain/services/budget_policy_service.dart';
import 'package:cc_domain/features/agents/domain/services/orphan_run_reaper.dart';
import 'package:cc_domain/features/dispatch/domain/context/conversation_summarizer.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/isolation/path_lock_manager.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_memory_context_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/evals/domain/services/starter_suites.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart'
    show canonicalHash;
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_domain/features/governance/domain/services/agent_presence_service.dart';
import 'package:cc_domain/features/governance/domain/services/approval_workflow_service.dart';
import 'package:cc_domain/features/governance/domain/services/budget_evaluation_listener.dart';
import 'package:cc_domain/features/governance/domain/services/budget_governance_service.dart';
import 'package:cc_domain/features/governance/domain/services/runtime_state_gc_sweeper.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart';
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
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';
import 'package:cc_domain/features/memory/domain/value_objects/system_memory_domains.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/messaging/domain/services/space_factory.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
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
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart'
    show BuiltInBodyKeys;
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_publisher_port.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_domain/features/pr_review/domain/services/review_guidelines.dart';
import 'package:cc_domain/features/pr_review/domain/services/review_suppression_matcher.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_search_query.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_domain/features/remote_control/domain/services/remote_pairing_lifecycle.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_egress_settings.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_image_settings.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/sandboxing/domain/services/sandbox_exec_grant_service.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_domain/features/settings/domain/services/branch_template_resolver.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scanner.dart';
import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_domain/features/teams/domain/services/team_routing_service.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/services/project_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/stranded_ticket_reconciler.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_link_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_domain/features/ticketing/domain/sync/multi_vendor_ticket_sync_coordinator.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_engine.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:cc_natives/cc_natives.dart'
    show
        CcSaml,
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
        samlLibraryBaseName,
        samlLibraryEnvVar,
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
import 'package:cc_server_core/src/activity_log_persister.dart';
import 'package:cc_server_core/src/backup_archive.dart';
import 'package:cc_server_core/src/cc_server_config.dart';
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
import 'package:cc_server_core/src/context/context_inspection_service.dart';
import 'package:cc_server_core/src/context/context_rpc_ops.dart';
import 'package:cc_server_core/src/dao_activity_log_reader.dart';
import 'package:cc_server_core/src/dao_code_graph_repository.dart';
import 'package:cc_server_core/src/dao_newsfeed_repository.dart';
import 'package:cc_server_core/src/dao_pr_lifecycle_repository.dart';
import 'package:cc_server_core/src/demo/demo_hooks.dart';
import 'package:cc_server_core/src/demo/demo_limits.dart';
import 'package:cc_server_core/src/demo/demo_world.dart' show kDemoPipelineTemplateIds;
import 'package:cc_server_core/src/dotenv.dart';
import 'package:cc_server_core/src/evals/evals_rpc_ops.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/fleet/fleet_rpc_ops.dart';
import 'package:cc_server_core/src/fleet/remote_execution_registry.dart';
import 'package:cc_server_core/src/fonts/fonts_rpc.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/forge_provider_factories.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:cc_server_core/src/harness_model_override_cache.dart';
import 'package:cc_server_core/src/identity/approval_escalation_sweeper.dart';
import 'package:cc_server_core/src/identity/audit_stream_sink.dart';
import 'package:cc_server_core/src/identity/caching_workspace_membership_repository.dart';
import 'package:cc_server_core/src/identity/github_login_directory.dart';
import 'package:cc_server_core/src/identity/identity_bootstrap.dart';
import 'package:cc_server_core/src/identity/managed_policy_service.dart';
import 'package:cc_server_core/src/identity/oidc_service.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_oauth_service.dart';
import 'package:cc_server_core/src/identity/saml_service.dart';
import 'package:cc_server_core/src/identity/scim_service.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:cc_server_core/src/identity/sso_ops.dart';
import 'package:cc_server_core/src/identity/sso_settings_service.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_invite_service.dart';
import 'package:cc_server_core/src/local_rpc_server.dart';
import 'package:cc_server_core/src/models/managed_model_control.dart';
import 'package:cc_server_core/src/models/selectable_voice_model_control.dart';
import 'package:cc_server_core/src/native_preflight.dart';
import 'package:cc_server_core/src/notification_feed_recorder.dart';
import 'package:cc_server_core/src/paired_device_registry_watch.dart';
import 'package:cc_server_core/src/plan_studio/plan_document_approval_service.dart';
import 'package:cc_server_core/src/plan_studio/plan_drift_service.dart';
import 'package:cc_server_core/src/plan_studio/plan_estimate_service.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_bridge.dart';
import 'package:cc_server_core/src/pr_review/github_pr_conversation_gateway.dart';
import 'package:cc_server_core/src/pr_review/multi_forge_open_pr_fetch.dart';
import 'package:cc_server_core/src/pr_review/open_pr_polling_service.dart';
import 'package:cc_server_core/src/pr_review/pr_conversation_polling_service.dart';
import 'package:cc_server_core/src/pr_review/review_axis_service.dart';
import 'package:cc_server_core/src/pr_review/review_cohort_service.dart';
import 'package:cc_server_core/src/pr_review/review_diagram_service.dart';
import 'package:cc_server_core/src/pr_review/stale_review_watcher.dart';
import 'package:cc_server_core/src/presence/agent_presence_synthesizer.dart';
import 'package:cc_server_core/src/relay/remote_relay_host.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart';
import 'package:cc_server_core/src/repo_ide_data_service.dart';
import 'package:cc_server_core/src/repo_workspace_index.dart';
import 'package:cc_server_core/src/review_fix_dispatch.dart';
import 'package:cc_server_core/src/rig_event_listener.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:cc_server_core/src/run_log_reader.dart';
import 'package:cc_server_core/src/server_mcp_client_control.dart';
import 'package:cc_server_core/src/server_mcp_control.dart';
import 'package:cc_server_core/src/server_mcp_registry.dart';
import 'package:cc_server_core/src/server_pipeline_executor.dart';
import 'package:cc_server_core/src/skill_analysis_run_reporter.dart';
import 'package:cc_server_core/src/skill_analysis_service.dart';
import 'package:cc_server_core/src/skill_quarantine_guard.dart';
import 'package:cc_server_core/src/skill_reverify_service.dart';
import 'package:cc_server_core/src/soundscape/soundscape_rpc.dart';
import 'package:cc_server_core/src/space_provisioning_service.dart';
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

  /// Live enclosures (rigs), destroyed on [shutdown]. Leaking one costs
  /// gigabytes of host RAM and a disk overlay that nothing will ever reclaim.
  RigService? _rigs;

  /// Periodic approval-escalation sweeper. Stopped on [shutdown] — it had a
  /// `stop()` with no caller, so its timer outlived the "stopped" server (the
  /// headless binary hides this behind `exit(0)`; the DESKTOP embeds
  /// `CcServer` in-process, where it is a real leak across a server switch).
  ApprovalEscalationSweeper? _approvalEscalation;

  /// Optional SIEM stream for the authorization audit trail. Drained on
  /// shutdown so a clean stop does not lose the last batch.
  AuditStreamSink? _auditStream;

  /// Native skills-dir watchers across every workspace. Disposed on [shutdown].
  SkillWatchService? _skillWatch;

  /// Per-minute cron evaluator for pipeline triggers. Disposed on [shutdown].
  PipelineSchedulerService? _pipelineScheduler;

  /// Daily audit/log retention prune. Stopped on [shutdown].
  DatabaseRetentionService? _databaseRetention;

  /// Daily harness-transcript prune. Cancelled on [shutdown].
  Timer? _transcriptRetention;

  /// Live debug adapters. Torn down on [shutdown] — an orphaned adapter holds
  /// a stopped debuggee and answers to nobody.
  DebugSessionSupervisor? _debugSupervisor;

  /// The shared tree-sitter parser for structural search. Its native handles
  /// are allocations the isolate's death does NOT reclaim, so it is disposed
  /// explicitly on [shutdown].
  AstParserProvider? _astParsers;

  /// Every domain-event listener started at boot, in start order.
  ///
  /// Each holds a `StreamSubscription` on the process-wide `DomainEventBus`
  /// and each had a `dispose()` with no caller — so on the desktop, which
  /// embeds `CcServer`, a server switch left the OLD server's listeners
  /// attached to the bus, still reacting to events and still holding their
  /// repositories (and, for the dispatching ones, still able to start work).
  final List<void Function()> _eventListenerStops = [];

  /// The bound WebSocket RPC server.
  final LocalRpcServer rpc;

  /// Periodic newsfeed-refresh timer (cancelled on [shutdown]).
  Timer? _newsfeedRefreshTimer;

  /// The open-PR poller behind the live PR list (null when the server holds
  /// no gh token). Disposed on [shutdown].
  OpenPrPollingService? _openPrPoller;

  /// The demo wiring, when this process is a public demo server. Its teardown
  /// reaps every live visitor, so a restart never leaves an orphaned workspace
  /// whose owner can no longer reach it.
  DemoWiring? _demo;

  /// GitHub viewer-activity poller (review requests / mentions / merges →
  /// events + targeted refreshes). Disposed on [shutdown].
  GitHubViewerActivityPollingService? _githubActivityPoller;

  /// GitHub PR-conversation poller: discovers bot @mentions / review-label
  /// requests on GitHub and bridges them into PR review spaces (the bot
  /// identity's inbound lane — no webhook, no public URL). Disposed on
  /// [shutdown].
  PrConversationPollingService? _prConversationPoller;

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

  /// Picks up `paired_devices` rows written by another process (`cc_server
  /// pair` against a live data dir), which drift's in-process update
  /// notifications cannot see. Disposed on [shutdown].
  PairedDeviceRegistryWatch? _pairedDeviceWatch;

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
  /// The host's language-server pool; every server is shut down on [shutdown].
  LspSupervisor? _lspSupervisor;
  NetworkRuntime? _networkRuntime;
  PresenceHub? _presenceHub;
  CheckerDispatchListener? _checkerListener;
  WorktreeGcListener? _worktreeGcListener;

  /// Steers the agent driving a rig when the machine is taken over or
  /// reclaimed. Disposed with the other long-lived listeners.
  RigEventListener? _rigEventListener;
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
      'rigs',
      'demo',
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

    // First: a visitor's workspace must be reaped while its database is still
    // open, and their session dropped before the socket layer goes away.
    await step('demo', () async => _demo?.stop());
    await step('approvals', () async {
      _pendingConfirmations?.dispose();
      _approvalEscalation?.stop();
    });
    // Flush whatever is buffered before the process goes away. The rows are
    // durable locally either way; this just avoids a gap in the SIEM.
    await step('auditStream', () async => _auditStream?.stop());
    await step('backgroundJobs', () async {
      _newsfeedRefreshTimer?.cancel();
      _runtimeStateGcSweepTimer?.cancel();
      _fleetReapTimer?.cancel();
      _ticketSyncPullTimer?.cancel();
      _openPrPoller?.dispose();
      _githubActivityPoller?.dispose();
      await _prConversationPoller?.dispose();
      _prChangeSignals?.dispose();
      _goalSupervisor?.dispose();
      _pipelineScheduler?.dispose();
      _databaseRetention?.stop();
      _transcriptRetention?.cancel();
      unawaited(_debugSupervisor?.dispose());
      _astParsers?.dispose();
      _pairedDeviceWatch?.dispose();
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
      await _rigEventListener?.dispose();
      await _notificationFeedRecorder?.dispose();
      await _codeGraphWatch?.dispose();
      // Native watchers over every workspace's skills dir: arming is O(1) but
      // each one holds a kernel watch for the process lifetime.
      await _skillWatch?.dispose();
      for (final stop in _eventListenerStops) {
        stop();
      }
      _eventListenerStops.clear();
    });
    await step('deviceRelay', () async => _relayHost?.stop());
    await step('chat', () async => _chatConnector?.stop());
    await step('mcpConnections', () async => _mcpClientService?.shutdown());
    // Language servers are long-lived child processes that index a whole
    // project; an orphaned analyzer outlives this process holding hundreds of
    // megabytes and answering to nobody.
    await step('languageServers', () async => _lspSupervisor?.dispose());
    // Kill every live code-server subprocess so a host exit leaves no orphans.
    await step('codeEditors', () async => _codeServer?.disposeAll());
    // Destroy every live VM. An orphaned hypervisor process outlives this one,
    // holds gigabytes of RAM and a disk overlay, and nothing left running
    // knows it exists — so unlike a PTY, leaking one is expensive and silent.
    await step('rigs', () async => _rigs?.disposeAll());

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
    // The rotating file sink is a module global with no handle to close (it
    // appends+flushes per line), but it still POINTS at this server's data
    // dir. Detach it: the desktop embeds `CcServer` and a server switch would
    // otherwise keep writing the new server's log lines into the old
    // instance's directory.
    _fileSink = null;
  }
}

/// Boots the pure-Dart headless server: opens `global.db` over
/// [openGlobalDatabase] (per-workspace databases open lazily through
/// [WorkspaceDatabaseManager]), wires the repository-backed RPC catalog
/// (tickets / messaging / newsfeed) onto a [LocalRpcServer] and starts
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
/// phase that got slow (the database open on a multi-GB file, a credential
/// probe blocked on a keyring) presented as a server hung after its last line
/// with no way to attribute the wait. Announcing BEFORE the await is the point:
/// the phase in flight is the one to blame.
///
/// Completion is ALWAYS logged, not just when slow. With a slow-only rule a fast
/// phase leaves its own start line as the last thing on screen, so the next
/// (unannounced) phase's stall gets blamed on it. The rule now is simple: a
/// `…` line with no matching `✓` is the phase still running.
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

/// The resolved `--log-level`, mirrored at file scope so [_announce] can honour
/// it without threading the config through every warm-up closure.
CcServerLogLevel _logLevel = CcServerLogLevel.warning;

/// Emits a headline lifecycle line that is visible at the DEFAULT log level.
///
/// `--log-level` defaults to `warning`, so every [CcHostLog.info] line — the
/// whole `_bootMark`/`_bootDone` narration included — is dropped unless the
/// operator opts into `info`. That is the right default for per-phase chatter,
/// but it also silenced the one thing a FIRST boot most needs to explain: the
/// several minutes it spends fetching multi-hundred-megabyte on-device models
/// over the network. With nothing on the log for that stretch, a slow link and
/// a hung server are indistinguishable.
///
/// So a handful of rare, high-value events use this lane instead. It is not a
/// bypass: `--log-level error` still silences it, and callers must only use it
/// for events that fire when real work happens (a model already on disk logs
/// nothing), never per-request or per-phase.
void _announce(String line) {
  if (_logLevel.index > CcServerLogLevel.warning.index) {
    return;
  }
  _emitLog(false, line);
}

/// Routes one on-device model's install lifecycle to the right log lane:
/// [ModelLogLevel.notice] onto [_announce] (visible on a default-verbosity
/// first boot, which is the whole point — see [_announce]), failures onto the
/// normal warning seam. [what] names the model family, e.g. `'embedding model'`.
void _modelLog(ModelLogLevel level, String what, String message) =>
    switch (level) {
      ModelLogLevel.notice => _announce('cc_server: $what: $message'),
      ModelLogLevel.warning => CcHostLog.warning('$what: $message'),
    };

/// Records an uncaught top-level server error to stderr **and** the rotating
/// on-disk log, so a crash in an async reconciler/timer that would otherwise
/// vanish leaves a persistent trail (FINDINGS §130). Safe to call before the
/// file sink is installed (it degrades to stderr only). Wire it as the handler
/// of a `runZonedGuarded` around the server run.
void recordUncaughtServerError(Object error, StackTrace stack) {
  _emitLog(true, 'cc_server: uncaught error: $error', stack);
}

/// Diagnostics route through [CcHostLog] (installed to stdout/stderr here).
/// Device PSKs, the provider app identity, per-user credentials and the SSO
/// secrets share one [FileSecretsStore] (`secrets.json`) under the data dir.
///
/// [harnessCredentialStore] resolves LLM provider credentials for the built-in
/// harness transport. Defaults to environment variables; a desktop host can
/// pass a keychain-backed store so GUI users authenticate without exporting
/// env vars.
/// [demoBuilder] turns this boot into a public DEMO server: provider-free,
/// execution-free and seeded with fictional data. It is a builder rather than a
/// ready [DemoWiring] because the wiring needs runtime internals (databases,
/// repositories, the event bus) that do not exist until the boot is underway.
///
/// Passing it is the ONLY way to enter demo mode — there is deliberately no
/// `--demo` flag. Two reasons: the demo's fixtures compile into the binary, so
/// a runtime branch here would ship them to every desktop install forever; and
/// a public endpoint whose lockdown depends on an environment variable can be
/// un-demoed by one deployment mistake. `apps/cc_demo_server` is a separate
/// `dart build cli` target that passes this in; `apps/cc_server` never
/// references the builder, so the whole demo subtree is tree-shaken out of it.
Future<CcServer> runCcServer({
  List<String> args = const [],
  ProviderCredentialStore? harnessCredentialStore,
  DemoWiringBuilder? demoBuilder,
}) async {
  // The process environment with the working directory's `.env` layered under
  // it, resolved ONCE: every credential the boot reads comes from this map, so
  // a value set in the file behaves exactly like an exported one. A real
  // environment variable always wins over the file.
  final serverEnv = environmentWithDotenv();
  final config = CcServerConfig.resolve(args, environment: serverEnv);
  _logLevel = config.logLevel;

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
  // for a bit and (piped, block-buffered stdout aside) that used to read as a
  // hung start. Emitted directly, bypassing the level filter (and its `[level]`
  // prefix): the lifecycle lines always print, whatever `--log-level` says.
  _emitLog(false, 'cc_server: booting (data: ${config.dataDir})…');

  // Persistence is two halves. `global.db` holds only server-wide state (the
  // workspace registry, identity, the newsfeed, the fleet queue) and is the ONLY
  // database boot opens — it stays small, so opening it is cheap however much
  // history the workspaces accumulate. Each workspace's own file opens lazily on
  // first touch, through the manager and pays its own migrations, trigger
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
  // `pairing.*` ops that MINT new device PSKs and the LocalRpcServer that
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
    // Known from the signature, long before the wiring itself is assembled —
    // and the descriptor is built here, so this is the only place it can come
    // from.
    isDemo: demoBuilder != null,
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
  // takes the OS account name as its handle), then the
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
        environment: serverEnv,
        eventBus: eventBus,
        log: CcHostLog.info,
      ).run();
    },
  );
  // Database files nobody claims are reported, never adopted or deleted: an
  // unclaimed file is either a failed import or a registry that lost a row and
  // both want a human rather than a silent decision.
  //
  // CROSS-WORKSPACE BY DESIGN: this is a boot-time sweep of the workspaces
  // DIRECTORY against the registry — it is looking for files that belong to no
  // workspace, which is the one question CrossWorkspaceQueries cannot answer
  // (it fans out over REGISTERED ids, so an orphan is invisible to it).
  for (final orphan in await workspaceDbs.orphanedDatabaseFiles()) {
    CcHostLog.warning('Orphaned workspace database (no registry row): $orphan');
  }
  final userRepository = DaoUserRepository(globalDb.userDao);
  // Per-user GitHub tokens (PRD 14 §10), namespaced inside the SAME secrets
  // file so there is exactly one on-disk secret map + in-memory cache. Backs
  // both the `credentials.*` ops and the per-run token override in dispatch.
  final userCredentials = UserCredentialsStore(secrets);
  // Wrapped in a read-through cache: membership is resolved on the hot path of
  // every workspace-scoped call (role gate on `repo/call`, again on
  // `sub/subscribe`, again on `tools/call`) and per emission of every
  // membership-scoped stream, all serialized on the one shared DB connection.
  // The wrapper is also the mutation chokepoint, so invalidation is exact —
  // see its doc for why that is structural rather than event-based.
  final membershipRepository = CachingWorkspaceMembershipRepository(
    DaoWorkspaceMembershipRepository(workspaceDbs),
  );
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
    // Durable policy home (a `caches` row was retention-pruned after 21
    // quiet days — a security control must not garbage-collect itself).
    policies: DaoApprovalRoutingPolicyRepository(workspaceDbs),
    workflow: ApprovalWorkflowService(
      repository: DaoApprovalRepository(workspaceDbs),
    ),
    eventBus: eventBus,
    onError: (message) => CcHostLog.warning('approval routing: $message'),
  )..start();
  // Optional OIDC SSO, configured in Settings → Server: JIT user
  // provisioning + group-claim role mapping; a solo operator never sees it.
  //
  // SSO services are ALWAYS constructed (an admin can enable them from the
  // settings UI without a restart); `SsoSettingsService.loadAndApply` below
  // is what decides whether they are live — DB row first, `CC_*` env seed
  // on first boot.
  Future<({String deviceId, String psk})> ssoMintDevice(
    String userId,
    String label,
  ) async {
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
  }

  final oidcService = OidcService(
    // Boots disabled; `ssoSettings.loadAndApply` pushes the saved row in.
    config: const OidcConfig(
      issuer: '',
      clientId: '',
      defaultRole: WorkspaceRole.member,
      groupRoleMap: {},
      groupsClaim: 'groups',
    ),
    users: userRepository,
    members: membershipRepository,
    workspaces: DaoWorkspaceRepository(
      globalDb.workspaceRegistryDao,
      workspaceDbs,
    ),
    mintDevice: ssoMintDevice,
    eventBus: eventBus,
  );
  final samlService = SamlService(
    // Boots disabled; `ssoSettings.loadAndApply` pushes the saved row in.
    config: const SamlConfig(
      idpMetadataXml: '',
      defaultRole: WorkspaceRole.member,
      groupRoleMap: {},
    ),
    users: userRepository,
    members: membershipRepository,
    workspaces: DaoWorkspaceRepository(
      globalDb.workspaceRegistryDao,
      workspaceDbs,
    ),
    mintDevice: ssoMintDevice,
    eventBus: eventBus,
  );
  final ssoSettings = SsoSettingsService(
    connections: DaoSsoConnectionRepository(globalDb.ssoConnectionDao),
    secrets: secrets,
    settings: globalDb.serverSettingDao,
    saml: samlService,
    oidc: oidcService,
    // Tunnel origin > publicUrl > loopback — the canonical HTTP origin the
    // settings screen shows SCIM/SP-metadata URLs under.
    canonicalOrigin: () async =>
        descriptorService.describe().then((d) => d.bulkHttpBase),
  );
  await ssoSettings.loadAndApply();
  // The SERVER's own app identity (GitHub App, Linear app) and the browser
  // sign-in that mints a USER's own credential. Same split as SSO: the app
  // credentials say how this server authenticates as itself, the sign-in says
  // how a human authenticates as themself, and neither is the other's
  // fallback.
  final providerApps = ProviderAppSettings(
    secrets: secrets,
    settings: globalDb.serverSettingDao,
  );
  await providerApps.loadAndApply(env: serverEnv);
  final providerOAuth = ProviderOAuthService(
    apps: providerApps,
    users: userCredentials,
  );
  // Server-owner gate for the `sso.*` ops. SSO decides who may authenticate
  // to the whole server, so it carries the SAME authority as every other
  // install-wide setting (`requireServerAdmin` in the catalog): the recorded
  // server owner, nobody else. This used to be a second, looser definition —
  // "owns at least one live workspace" — which let anyone who could create a
  // workspace rewrite who may sign in to the entire install and regenerate
  // the SCIM token. One install, one operator identity, one definition.
  Future<bool> isServerOwner(String userId) async => userId == ownerUserId;

  // SCIM 2.0 (RFC 7644): the IdP-driven lifecycle half of SSO — user pushes
  // and, critically, DEPROVISIONING (device revocation + membership removal,
  // live within seconds via the existing device watch). Bearer-token gated;
  // unreachable-behind-NAT deployments simply never receive pushes (JIT
  // provisioning still works — that is the documented split).
  final scimService = ScimService(
    verifyScimToken: ssoSettings.verifyScimToken,
    users: userRepository,
    members: membershipRepository,
    devices: globalDb.pairedDeviceDao,
    secrets: secrets,
    eventBus: eventBus,
  );

  // ── On-device embedding model (semantic search over memory facts, code
  // symbols and conversation history) ──
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
    // The two guards that used to be declared-but-unwired (TODO(prd22)):
    // the delegate's effective autonomy must not exceed the delegator's and
    // an exhausted delegator budget refuses new delegation.
    resolveEffectiveAutonomy:
        ({required String workspaceId, required String agentId, String? spaceId}) async {
          if (spaceId == null || spaceId.isEmpty) {
            return AutonomyLevel.actWithApproval;
          }
          final stored = await workspaceDbs
              .of(workspaceId)
              .spaceExtrasDao
              .autonomyFor(workspaceId, spaceId, agentId);
          return AutonomyLevel.tryFromWire(stored?.autonomyLevel) ??
              AutonomyLevel.actWithApproval;
        },
    resolveRemainingBudgetCents:
        ({required String workspaceId, required String agentId}) async {
          final policy = await DaoBudgetPolicyRepository(
            workspaceDbs,
          ).getPolicyForScope(workspaceId, 'agent', agentId);
          if (policy == null || policy.isUnlimited || !policy.hardStopEnabled) {
            return null;
          }
          return policy.monthlyBudgetCents - policy.spentCents;
        },
  );
  final messagingRepository = DaoMessagingRepository(workspaceDbs);
  final conversationRepository = DaoConversationRepository(workspaceDbs);

  // ── ask_user: the agent's structured question to a human ──
  // ONE instance, shared by the two halves that have to meet: the dispatch
  // path (where `ask_user` calls `ask()` and the run blocks on a Completer)
  // and the RPC catalog (where `messaging.updateMessage` carries the client's
  // answer back and completes it). Two instances would mean the agent waits on
  // a completer nobody can reach — which is the state this subsystem was in.
  //
  // The timeout is generous but finite: a question nobody answers must end as
  // a tool error the agent can act on, not as a run pinned forever.
  final agentQuestions = AgentQuestionService(
    messagingRepository,
    timeout: const Duration(minutes: 30),
  );

  // ── Tool-result images ──
  // Content-addressed storage for the screenshots `browser_use` /
  // `computer_use` / `mobile_use` return. Lives under the WORKSPACE's own
  // directory (beside its database) so it is deleted with the workspace and
  // cannot be read across the isolation boundary — the same rule the database
  // split enforces structurally. The layout comes from `workspaceDirPath` so
  // there is one definition of where a workspace's files live.
  final blobStore = BlobStore(
    workspaceDir: (workspaceId) =>
        workspaceDirPath(config.dataDir, workspaceId),
  );
  // ── Harness transcripts ──
  // The conversation's real history, so the next run continues it instead of
  // reading a `<context>` summary of it — and so a `checkpoint` label survives
  // a restart, which is the only way `rewind` means anything across one. Beside
  // the workspace's own database and blobs, so deleting the workspace deletes
  // its transcripts with everything else.
  final transcriptStore = FileHarnessTranscriptStore(
    workspaceDir: (workspaceId) =>
        workspaceDirPath(config.dataDir, workspaceId),
  );

  // ── Language servers ──
  // ONE pool for the whole host, shared across runs: a language server's cost
  // is its indexing pass, so a per-run supervisor would re-index every project
  // on every dispatch. Servers start LAZILY — on the first request that needs
  // one, which is almost always the first edit to a file it claims — so a host
  // that never touches Dart never starts an analyzer. Idle ones are swept.
  final lspSupervisor = LspSupervisor();

  // Bound below, where the rig service is constructed. Late rather than
  // moved: the enclosure stack needs half the runtime's wiring, while the
  // dispatch adapter is assembled before it — and the only reader is a closure
  // that runs when a model runs a cell, long after boot.
  RigService? enclosureService;

  // ── Debug adapters ──
  // Bounded like a rig, and for the same reason: an adapter owns a STOPPED
  // process holding whatever that process holds (a port, a lock, a database
  // connection), so it gets a hard TTL and is torn down on shutdown. An
  // orphaned adapter outlives the server and answers to nobody.
  final debugSupervisor = DebugSessionSupervisor();

  // ── tree-sitter grammars ──
  // Built here rather than at the indexer's use site so a missing grammar is
  // caught at boot instead of on the first index run, and so the structural
  // tools (which are wired into the dispatch adapter a few hundred lines
  // below) can share the same resolver rather than growing a second one.
  final grammarManager = GrammarManager(
    dio: createDio(),
    grammarsDir: paths.grammarsRoot,
    onLog: (tag, message, [error, stackTrace]) =>
        CcHostLog.warning('grammar[$tag]: $message'),
  );
  // One tree-sitter parser for the whole host, shared by `ast_grep` /
  // `ast_edit`. Warmed after the ready banner rather than here: resolving
  // grammars touches the filesystem, and the desktop parses that banner under
  // a hard 20s timeout and KILLS the child on expiry.
  final astParsers = AstParserProvider(resolve: grammarManager.resolve);

  // ── Deterministic sync feed (PRD 16 §6) ──
  // Tails the trigger-written change feed and emits ordered delta packets;
  // rows load through the SAME wire mappers the snapshot watches use.
  final syncFeed = SyncFeedService(
    workspaces: workspaceDbs,
    loaders: {
      // Each loader receives the workspace the change came from and that
      // workspace picks the database file — so the "does this row actually
      // belong to `ws`?" checks these loaders used to make are now answered by
      // which file was opened.
      'tickets': (ws, pk, ctx) async {
        final t = await ticketRepository.getById(ws, pk);
        return t == null ? null : ticketToWire(t);
      },
      'spaces': (ws, pk, ctx) async {
        final c = await messagingRepository.getSpaceById(ws, pk);
        return c == null ? null : spaceToWire(c);
      },
      'conversation_messages': (ws, pk, ctx) async {
        final m = await messagingRepository.getMessageById(ws, pk);
        return m == null ? null : messageToWireLite(m);
      },
      'space_participants': (ws, pk, ctx) async {
        if (ctx == null) {
          return null;
        }
        final participants = await messagingRepository.getParticipants(ws, ctx);
        for (final p in participants) {
          if (p.id == pk) {
            return spaceParticipantToWire(p);
          }
        }
        return null;
      },
      'space_notes': (ws, pk, ctx) async {
        if (ctx == null) {
          return null;
        }
        final note = await workspaceDbs
            .of(ws)
            .spaceExtrasDao
            .noteForSpace(ws, ctx);
        return (note == null || note.id != pk) ? null : spaceNoteToWire(note);
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
    // Feeds without a space image fall back to the site HTML's
    // <link rel="icon"> (e.g. lea.verou.me).
    siteIcons: SiteIconResolver(createDio()),
  );

  final agentRepository = DaoAgentRepository(workspaceDbs);
  final agentRunLogRepository = DaoAgentRunLogRepository(workspaceDbs);
  // Per-run activity timelines (subagent runs above all). Kept in its own table
  // so the run-log list watches never ship the fat segment payload.
  final runTranscriptRepository = DaoRunTranscriptRepository(workspaceDbs);
  final repoRepository = DaoRepoRepository(workspaceDbs);
  final spaceReadRepository = DaoSpaceReadRepository(workspaceDbs);
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
  );
  // Cross-agent SHMR belief harmonization.
  final harmonizeMemoryUseCase = HarmonizeMemoryUseCase(
    factRepository: memoryFactRepository,
    beliefRepository: memoryBeliefRepository,
    conflictRepository: memoryConflictRepository,
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
  final reviewSpaceRepository = DaoReviewSpaceRepository(workspaceDbs);
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
  // `owner/name` → workspace ids, for the notification poller's per-repo
  // lookup (see [RepoWorkspaceIndex] for why it is an index and not a scan).
  final repoWorkspaceIndex = RepoWorkspaceIndex(workspaceRepository);
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
    // the server: no RPC response carries it and a connection made with it
    // stores a marker instead of the pair.
    serverClient: GoogleOAuthClient.fromConfig(config),
    // Google credentials are `google_*` keys in the same secrets file as the
    // device PSKs, so hand over the shared store rather than a second instance
    // with its own cache of the same map.
    secrets: secrets,
  );

  // Live weather (Open-Meteo, keyless) + the server-side generative soundscape
  // engine. The hub reads the workspace's location/conditions from the weather
  // service, folds in the daypart and streams generated MP3 audio to thin
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
  // down leaves an empty catalogue and the picker keeps its bundled + system
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

  // Per-forge credentials. GitHub, GitLab and Bitbucket each resolve their own
  // token, so a workspace holding repos on several forges authenticates to
  // each independently and one missing credential never blanks another forge's
  // PRs. With no calling user — which is what the server's own background work
  // is — resolution runs app identity → the owner's own credential →
  // environment.
  final forgeCredentials = ForgeCredentials(
    env: (name) => serverEnv[name],
    users: userCredentials,
    apps: providerApps,
    serverOwnerUserId: () async => ownerUserId,
  );
  // Renews an expiring user credential in place rather than surfacing a 401.
  // Assigned after construction because each service needs the other: the
  // store reads the credential the OAuth service refreshes.
  forgeCredentials.refreshUserToken = providerOAuth.refresh;
  final forgeDioFactory = ForgeDioFactory(
    tokenLookup: forgeCredentials.tokenFor,
    bitbucketUsername: () => forgeCredentials.bitbucketEmail,
  );
  // A SECOND factory, pinned to the server owner's own credential.
  //
  // `tokenFor` with no caller resolves the server's app identity FIRST — right
  // for background work (it must not ride a human's token), wrong for the
  // handful of endpoints that are inherently per-user. `GET /notifications` and
  // `GET /user` are user-only: GitHub answers an installation token with 403
  // "Resource not accessible by integration", forever, because no App
  // permission grants either. Naming the owner takes the user lane instead, and
  // resolves null when nobody has signed in — which is the honest answer, not a
  // fallback to a token that cannot work.
  final ownerForgeDioFactory = ForgeDioFactory(
    tokenLookup: (forge) =>
        forgeCredentials.tokenFor(forge, userId: ownerUserId),
    bitbucketUsername: () => forgeCredentials.bitbucketEmail,
  );
  final forgeConnections = await _bootStep(
    'resolving forge credentials',
    forgeCredentials.connections,
  );
  // The server's own GitHub credential, snapshotted for the surfaces built
  // around a captured token (the GraphQL dashboard queries, the local-git diff
  // source). Everything that goes through `forgeDioFactory` resolves per
  // request instead, so a credential added later needs no restart.
  final ghToken = await forgeCredentials.tokenFor(ForgeHost.github) ?? '';
  final ghUsername = ghToken.isEmpty
      ? ''
      : await forgeCredentials.viewerLogin(ForgeHost.github);
  final connectedForges = {
    for (final c in forgeConnections)
      if (c.authenticated) c.forge,
  };
  if (connectedForges.isEmpty) {
    CcHostLog.warning(
      'cc_server: no forge credential found — the PR list and authenticated '
      'PR review stay empty until a forge is connected in settings, or '
      'GITHUB_TOKEN / GITLAB_TOKEN / BITBUCKET_API_TOKEN is set.',
    );
  } else {
    CcHostLog.info(
      'cc_server: forges connected — '
      '${connectedForges.map((f) => f.displayName).join(', ')}',
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
  // Resolved per request, like every other server-side GitHub call: a
  // credential that arrives after boot (an app installed, a token pasted, the
  // owner signing in) has to work without a restart.
  githubDio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await forgeCredentials.tokenFor(ForgeHost.github);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  // The GitHub client now rides the per-forge factory so a token pasted into
  // Settings applies to the next request instead of the next restart.
  final serverGitHubClient = GitHubApiClient(
    forgeDioFactory.of(ForgeHost.github),
  );

  // The composer's GIF picker runs on the host's Klipy app key (the thin client
  // holds none). Null when unconfigured → the `gif.*` ops return empty.
  final klipy = config.klipyAppKey.isEmpty
      ? null
      : KlipyApiClient(appKey: config.klipyAppKey);

  // A THIRD family of factories, one per acting user.
  //
  // Everything a human drives from the UI — approving a review, posting a
  // comment, opening a pull request — must be authored on the forge by THAT
  // human. `forgeDioFactory` cannot do it: with no caller its lookup resolves
  // the server's app identity first, so every review Control Center submitted
  // arrived on GitHub as the app rather than as the person who clicked. The
  // per-actor factory names the caller, so their own credential wins (a GitHub
  // App user-to-server token acts as them, bounded by the app's permissions)
  // and the app is only the FALLBACK, for a member who has not connected that
  // forge.
  //
  // One factory per user, memoized: the token itself is still read per request
  // inside the interceptor, so signing in — or out — applies to the next call
  // without rebuilding anything. Bounded by the number of users who have made a
  // forge-touching call.
  final actorDioFactories = <String, ForgeDioFactory>{};
  ForgeDioFactory forgeDioFactoryForActor(String? userId) {
    if (userId == null || userId.isEmpty) {
      return forgeDioFactory;
    }
    return actorDioFactories.putIfAbsent(
      userId,
      () => ForgeDioFactory(
        tokenLookup: (forge) => forgeCredentials.tokenForActor(forge, userId),
        bitbucketUsername: () => forgeCredentials.bitbucketEmail,
      ),
    );
  }

  // GitHub read surfaces whose ANSWER DEPENDS ON WHO IS ASKING — "who am I",
  // "what teams am I in", "what wants my review", "what have I reviewed".
  //
  // These cannot be served by one process-wide client. `review-requested:` and
  // `reviewed-by:` need a login to put in the qualifier, and `GET /user` only
  // answers a user token: an installation token gets a permanent 403, so a
  // server-wide client resolves an EMPTY login and every one of these surfaces
  // silently returns nothing. Pinning them to the server owner instead fixes
  // the solo case and breaks the multiplayer one — the server would be
  // asserting which human it belongs to, and a second member asking "who am I"
  // would be told they are the first.
  //
  // So each is keyed by the ACTING PRINCIPAL (`RepoOpContext.userId`, the
  // authenticated session's user — never a client-supplied id, which would be
  // an impersonation hole). Memoized per user and bounded by the number of
  // users who have made a GitHub-touching call; the token is still read per
  // request inside the interceptor, so signing in applies to the next call.
  final actorGitHubClients = <String, GitHubApiClient>{};
  GitHubApiClient githubClientForActor(String userId) =>
      actorGitHubClients.putIfAbsent(
        userId,
        () => GitHubApiClient(
          forgeDioFactoryForActor(userId).of(ForgeHost.github),
        ),
      );

  // One identity cache per acting user. The cache holds a login and an org →
  // teams map, which are that person's, so a single shared instance would hand
  // one member's identity to another.
  final actorGitHubIdentities = <String, ViewerGitHubIdentityCache>{};
  ViewerGitHubIdentityCache githubIdentityForActor(String userId) =>
      actorGitHubIdentities.putIfAbsent(
        userId,
        () => ViewerGitHubIdentityCache(githubClientForActor(userId).content),
      );

  // One repo's forge client: its forge picks both the adapter and the
  // authenticated HTTP client, and [actingUserId] picks whose name the calls
  // carry. Omitting it is the background identity (app → owner → environment)
  // and is only correct for work with no human behind it.
  ForgePrClient forgePrClientForRepo(Repo repo, {String? actingUserId}) =>
      forgePrClientBuilder(
        repo.forge,
        forgeDioFactoryForActor(actingUserId).of(repo.forge),
      )(owner: repo.remoteOwner, repo: repo.remoteName);

  // Resolves the forge client for a repo coordinate in a workspace, by looking
  // the repo up and using ITS forge. This is what lets a publish land on
  // whichever forge the repo actually lives on rather than assuming GitHub.
  // Null when the coordinate names no registered repo — the caller turns that
  // into "no forge is connected for this repo" rather than a wrong-forge call.
  Future<ForgePrClient?> forgeClientForCoord(
    String workspaceId,
    String owner,
    String repo, {
    String? actingUserId,
  }) async {
    final repos = await repoRepository.getAll(workspaceId);
    for (final r in repos) {
      if (r.remoteOwner.toLowerCase() == owner.toLowerCase() &&
          r.remoteName.toLowerCase() == repo.toLowerCase() &&
          r.hasForgeRemote) {
        return forgePrClientForRepo(r, actingUserId: actingUserId);
      }
    }
    return null;
  }

  // PR lifecycle (workspace-scoped at the `PullRequests` table). The thin client
  // reads + writes its draft → publish → created records over RPC. Publishing
  // goes through the repo's own forge, so the same composer creates a GitHub
  // pull request, a GitLab merge request or a Bitbucket pull request without
  // the client knowing which.
  //
  // Resolved per acting user for the same reason the PR-review repositories
  // are: opening a pull request is a human's action, so it must carry their
  // name on the forge. The draft rows it reads and writes live in the workspace
  // database either way — only the outbound client differs.
  final actorPrLifecycleRepositories = <String, PrLifecycleRepository>{};
  PrLifecycleRepository prLifecycleRepositoryForActor(String? userId) =>
      actorPrLifecycleRepositories.putIfAbsent(
        userId ?? '',
        () => DaoPrLifecycleRepository(
          workspaceDbs,
          (workspaceId, owner, repo) => forgeClientForCoord(
            workspaceId,
            owner,
            repo,
            actingUserId: userId,
          ),
          eventBus: eventBus,
        ),
      );

  // Activity log (workspace-scoped audit trail). The headless server owns the
  // Drift `activity_log` DAO, so it serves the `activity.watchForEntity`
  // subscription (the client's entity-timeline view) over this read-only reader.
  final activityLogReader = DaoActivityLogReader(workspaceDbs);

  // The MCP agent-tool surface the server exposes via tools/list + tools/call.
  // Built before the catalog so the SHARED dispatcher backs both the RPC server
  // and the MCP HTTP server (one tool registry, two transports) and the
  // control surface the `mcp.*` catalog ops drive can be wired in.

  // Ticket relation service (blocked_by / sub-issue / duplicate links) backing
  // the typed `ticket_relation` / `list_ticket_relations`
  // tools registered post-construction below.
  final ticketLinkService = TicketLinkService(
    linkRepository: ticketLinkRepository,
    ticketRepository: ticketRepository,
  );

  // Per-conversation mode guard, built ONCE and shared: the dispatcher enforces
  // it and the discovery tools (`search_tool_bm25`, `list_my_tools`) read it to
  // report which tools are callable in the caller's conversation mode. The
  // conversation is resolved server-side (space mode, or the agent's active
  // run), so it cannot be spoofed by omitting `space_id`.
  final mcpModeGuard = ModeToolGuard(
    DbModeResolver(workspaceDbs),
    runLogs: agentRunLogRepository,
  );

  // Per-space todo store — shared by the MCP `todo_write` tool (below)
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
    newsfeedOwnerUserId: ownerUserId,
    ticketRepository: ticketRepository,
    messagingRepository: messagingRepository,
    todoRepository: todoRepository,
    // Pipeline structured-output contract (submit_output writes outputJson).
    agentRunLogRepository: agentRunLogRepository,
    schemaValidator: const JsonSchemaValidator(),
    // Shared with the dispatcher below so discovery tools report per-mode
    // callability with the exact rules the dispatcher enforces.
    modeGuard: mcpModeGuard,
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
  // stdio, static-header HTTP/SSE and already-authorized OAuth servers all
  // work; first-time interactive OAuth is desktop-driven. Discovery + connect
  // runs fire-and-forget after boot (see below).
  final mcpClientService = McpClientService(
    registry: mcpRegistry,
    tokenStore: FileOAuthTokenStore('${config.dataDir}/mcp_oauth_tokens.json'),
    // Remembering each server's tool list means a run that starts while a slow
    // server is still dialling still sees that server's tools; the first CALL
    // waits for the connection instead. Server-wide (not workspace-scoped) —
    // an MCP server is a host-level process, and the file holds tool names and
    // schemas only, never a credential.
    toolCachePath: '${config.dataDir}/mcp_tool_cache.json',
    log: (level, message, {Object? error}) =>
        CcHostLog.info('mcp-client[$level]: $message'),
  );
  // Human-in-the-loop approvals for privileged agent actions (destructive
  // shell commands, approval-gated MCP tools). The SERVER has no local GUI, so
  // every request is published to connected clients over
  // `confirmation.watchPending` and resolved by `confirmation.respond`. The
  // The SAME instance backs the MCP dispatcher, the harness/dispatch path and
  // the RPC catalog, so all pending approvals surface in one place. Without this
  // the fail-closed paths deny every gated action outright.
  //
  // There IS a ceiling, deliberately generous. The registry's own default is
  // "wait forever", which reads as "never silently auto-denied" — but on a
  // headless host reached only by `RemoteConfirmationPort`, an approval nobody
  // is connected to see parks a completer, a run slot and a sandbox handle for
  // the process lifetime. An hour is far longer than any human decision loop
  // and still bounded; the timeout path fails CLOSED (deny), matching the
  // action guard's "prompt with no approver ⇒ deny" posture.
  // Forward-declared: the dispatch deps below close over it for the credential
  // gate's sign-in probe, while its own construction needs the usage cache that
  // is built further down. `late final` rather than a reorder — the probe only
  // runs while a run is parked, long after every one of these is assigned.
  late final ClaudeAccountStore claudeAccountStore;
  final pendingConfirmationRegistry = PendingConfirmationRegistry(
    timeout: const Duration(hours: 1),
  );
  final confirmationPort = RemoteConfirmationPort(pendingConfirmationRegistry);
  // Runs parked on a credential that cannot serve them. Same bridge shape as
  // the approvals registry above and a deliberately different deadline: an
  // approval is a decision someone makes in seconds, while fixing a credential
  // means opening a terminal, signing in and coming back. `--credential-gate=0`
  // turns it off entirely, which restores the pre-gate behaviour exactly — a
  // missing or spent credential ends the turn where it always did.
  final credentialGateRegistry = config.credentialGateSeconds <= 0
      ? null
      : PendingCredentialBlockRegistry(
          deadline: Duration(seconds: config.credentialGateSeconds),
        );
  final credentialGate = credentialGateRegistry == null
      ? null
      : RemoteRunCredentialGate(credentialGateRegistry);
  // The sandbox exec-grant prompt is asked BEFORE a run's Seatbelt profile is
  // written and HOLDS the dispatch until it resolves, so it gets its own,
  // far shorter deadline over the same registry: an hour of a parked run slot
  // is the wrong trade for a question whose fallback ("keep it blocked") is
  // both safe and the pre-existing behaviour. Resolving through the registry
  // rather than a local timer is what clears the entry, so no stale prompt is
  // left on the operator's phone.
  final execGrantConfirmationPort = RemoteConfirmationPort(
    pendingConfirmationRegistry,
    timeout: const Duration(seconds: 90),
  );
  final sandboxExecGrantRepository = DaoSandboxExecGrantRepository(workspaceDbs);
  final execGrantService = SandboxExecGrantService(
    repository: sandboxExecGrantRepository,
    confirmationPort: execGrantConfirmationPort,
    idFactory: () => const Uuid().v4(),
  );
  // PRD 24: the unified action-guardrail resolver + gate. Resolves an
  // agent-initiated effect against the workspace/space/agent policy store
  // (space > agent > workspace > mode preset > default) and gates it through
  // the SAME ConfirmationPort (fail-closed). Injected into the MCP dispatcher
  // below so external-CLI adapters' tool calls hit the same policy as the
  // harness; the command net + sandbox floor remain the other layers.
  final actionPolicyRepository = DaoActionPolicyRepository(workspaceDbs);
  // The tamper-evident authorization audit spine. Every guard verdict —
  // allow AND deny — is appended to the workspace's hash-chained
  // `guard_decisions` chain, carrying the attribution chain (agent → the
  // human it acts for → the rule that decided). This replaced a callback that
  // wrote one stdout line on deny and nothing else, which meant a refusal was
  // invisible to any query and an allow left no record at all.
  final guardDecisionRepository = DaoGuardDecisionRepository(workspaceDbs);
  // Optional SIEM streaming: a copy of every authorization decision shipped
  // to the operator's log pipeline. Configured in server settings (owner
  // only); absent by default. The LOCAL hash-chained copy is the source of
  // truth — this never gates a decision and never blocks a tool call.
  final auditStreamEndpoint =
      (await serverSettingsRepository.get('audit_stream_endpoint')) ?? '';
  final auditStream = auditStreamEndpoint.isEmpty
      ? null
      : (AuditStreamSink(
          endpoint: auditStreamEndpoint,
          token: await serverSettingsRepository.get('audit_stream_token'),
          onWarn: (m) => CcHostLog.warning('audit stream: $m'),
        )..start());
  // Custom (subtractive) roles, resolved per call by
  // `resolveRoleDefinition` below and edited through the `roles.*` ops.
  final workspaceRoleRepository = DaoWorkspaceRoleRepository(workspaceDbs);
  // The install-wide managed tier: an operator clamp merged MOST-RESTRICTIVE
  // with each workspace's own chain, so it can tighten what a workspace
  // decided and never loosen it. A `CC_SERVER_MANAGED_POLICY` file outranks
  // the stored rows, which is what lets an operator pin a posture no admin UI
  // can flip.
  final managedPolicy = ManagedPolicyService(
    global: globalDb,
    policyFilePath: serverEnv[ManagedPolicyService.envVar],
    onWarn: (m) => CcHostLog.warning('managed policy: $m'),
  );
  final actionGuard = ActionGuardService(
    repository: actionPolicyRepository,
    confirmationPort: confirmationPort,
    managedRules: managedPolicy.rules,
    onAudit: (a) {
      if (a.decision == ActionDecision.deny) {
        CcHostLog.info(
          'guardrail deny [${a.source}] ${a.actionSummary}: ${a.reason}',
        );
      }
      // Fire-and-forget: this runs on the hot path of every gated tool call,
      // so a slow append must never delay the agent — and a failed append is
      // logged, never raised into the caller's verdict.
      final decision = GuardDecision(
        id: const Uuid().v4(),
        workspaceId: a.workspaceId,
        occurredAt: DateTime.now(),
        // The guard's callers are agents; the repo-op dispatcher records its
        // own human-lane rows with actorType 'user'.
        actorType: a.agentId == null ? 'system' : 'agent',
        actorId: a.agentId ?? 'server',
        onBehalfOfUserId: a.onBehalfOfUserId,
        spaceId: a.spaceId,
        runId: a.runId,
        surface: GuardSurface.harness,
        actionName: a.actionSummary.isEmpty
            ? (a.command ?? 'action')
            : a.actionSummary,
        actionClasses: a.actionClasses,
        decision: a.decision,
        sourceScope: a.source,
        ruleId: a.ruleId,
        prompted: a.prompted,
        argsDigest: a.command == null
            ? null
            : canonicalHash({'command': a.command}),
      );
      unawaited(
        guardDecisionRepository
            .append(decision)
            .catchError(
              (Object e) =>
                  CcHostLog.warning('guard audit append failed: $e'),
            ),
      );
      // A COPY to the operator's SIEM, when one is configured. Never gates
      // the decision: the durable, verifiable record is the local chain.
      auditStream?.add(decision);
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
  // passing static verdict and a provider outage fails open for Layer 3 only
  // (Layers 1-2 stay the fail-closed gate). Injected into the bundle service +
  // create_skill so no origin writes unscanned content.
  // The shared scan cache/audit (per-workspace `skill_scan_results`): the
  // adapter's cache-by-hash fast path AND the status lookups the settings UI's
  // installed-skills verdicts read — one repository, two consumers.
  final skillScanCache = DaoSkillScanRepository(workspaceDbs);
  final skillScanner = SkillScannerAdapter(
    scanner: const SkillScanner(),
    cache: skillScanCache,
  );
  // Skill sources: the GitHub repositories the operator registers as skill
  // catalogs (the skills.sh registry replacement). The server dials GitHub;
  // clients browse over the `skills.source*` RPC ops. All repository metadata
  // is untrusted — only the content hash CC computes over the fetched bytes is
  // trusted and every install still passes the mandatory scan gate.
  final skillSourceStore = DaoSkillSourceRepository(workspaceDbs);
  final skillSourceCatalog = GitHubSkillSourceAdapter(serverGitHubClient);
  final skillBundles = SkillBundleService(
    filesystem: workspaceFilesystem,
    scanner: skillScanner,
    scanCache: skillScanCache,
    // Publishes SkillUpdated after every gated write: the seeded
    // `skill_analysis` pipeline trigger (and any user-authored trigger)
    // re-scans the new bytes without the write path knowing about pipelines.
    eventBus: eventBus,
    // PRD 23 §2 ties PRD 24: resolve a skill's declared capabilities against
    // the workspace action policy at install, before write.
    actionGuard: actionGuard,
    // Multi-file resolve: the full directory of the named SKILL.md, pinned to
    // the latest commit touching it when the caller names no ref.
    fetchGitHubSkill:
        ({
          required String owner,
          required String repo,
          required String path,
          String? ref,
        }) => skillSourceCatalog.resolve(owner, repo, path, ref: ref),
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
  // PRD 23 §6 enforcement: quarantined skills are refused agent links. The
  // filter is attached here (not in the constructor) because its verdict source
  // is `skillBundles` itself, which is built over `workspaceFilesystem`.
  final skillQuarantineGuard = SkillQuarantineGuard(
    agents: agentRepository,
    bundles: skillBundles,
    filesystem: workspaceFilesystem,
  );
  workspaceFilesystem.linkFilter = skillQuarantineGuard.isQuarantined;
  // The skills antivirus as a pipeline (PRD 23 §2/§6): the analysis service is
  // the workhorse both the pipeline body (engine runs) and the settings UI's
  // synchronous scan ops (projection runs recorded by the reporter) drive.
  // The template's isEnabled switch governs recording — disabled means no run
  // rows, never no scanning.
  final skillAnalysisReporter = SkillAnalysisRunReporter(
    pipelineRunRepository,
    onError: (message) => CcHostLog.warning('skill analysis: $message'),
  );
  final skillAnalysis = SkillAnalysisService(
    bundles: skillBundles,
    quarantineGuard: skillQuarantineGuard,
    reporter: skillAnalysisReporter,
    templates: pipelineTemplateRepository,
    runs: pipelineRunRepository,
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
  // into it and every open `pr_review.watch*` stream re-validates on a signal
  // — that is what pushes GitHub-side changes to connected clients without a
  // refresh button. Webhooks are deliberately not the transport here: this
  // server may run with no public URL/tunnel at all, so polling with
  // conditional requests is the universal baseline.
  final prChangeSignals = PrChangeSignals();

  // The poller fans out per forge: GitHub keeps its batched GraphQL adapter
  // (one round trip for N repos), and the others go through the generic
  // per-repo client adapter. A workspace mixing forges therefore polls all of
  // them into ONE snapshot, and a forge that is down or unauthenticated is
  // isolated to its own repos.
  // Every supported forge gets a delegate, for the same reason the registry
  // does: membership must not freeze at boot. A forge is only ever called about
  // repos that live on it, so an unconnected one with no repos costs nothing,
  // and one with repos fails in isolation rather than emptying the inbox.
  //
  // The GitHub adapter resolves its client PER REPO OWNER, not from
  // `serverGitHubClient`: the no-caller credential is a token for whichever
  // app installation answered first, and GitHub answers such a token with 404
  // for every repo under an owner the app is not installed on — so a
  // workspace's repos in a second org polled as permanently missing. Each
  // owner's client resolves the installation covering that owner (falling
  // back to the server owner's credential, then the environment) per request,
  // so an app installed after boot works without a restart. The cache is
  // bounded by the number of distinct owners among registered repos.
  final ownerScopedGitHubClients = <String, GitHubApiClient>{};
  GitHubApiClient githubClientForOwner(String owner) =>
      ownerScopedGitHubClients.putIfAbsent(
        owner.toLowerCase(),
        () => GitHubApiClient(
          ForgeDioFactory(
            tokenLookup: (forge) =>
                forgeCredentials.tokenForRepoOwner(forge, owner),
          ).of(ForgeHost.github),
        ),
      );
  final openPrFetchAdapter = MultiForgeOpenPrFetchAdapter({
    for (final forge in ForgeHost.supported)
      forge: forge == ForgeHost.github
          ? GitHubOpenPrFetchAdapter(githubClientForOwner)
          : ForgeClientOpenPrFetchAdapter(forgePrClientForRepo),
  });
  final openPrPoller = OpenPrPollingService(
    fetchPort: openPrFetchAdapter,
    workspaceRepository: workspaceRepository,
    workspaceDbs: workspaceDbs,
    changeSignals: prChangeSignals,
    prToWire: pullRequestToWire,
    eventBus: eventBus,
    // The author gate for the merge-readiness / review-decision / checks
    // lanes. This poller sweeps EVERY open PR in every linked repo, so without
    // a viewer login it would announce strangers' work; with no owner signed
    // in the resolver answers empty and those lanes stay silent.
    viewerLoginFor: (forge) =>
        forgeCredentials.viewerLogin(forge, userId: ownerUserId),
    forUserId: ownerUserId,
  );

  // ── Demo wiring ──
  // Assembled at ONE point, which is possible because everything it needs
  // (databases, the registry, identity, the event bus, blobs, the poller) is
  // already built above. Below, ~14 substitution sites read `demo?.x ?? realX`
  // or `demo == null ? realX : null`; there are no `if (demo)` branches, so the
  // demo's whole policy stays one object a test can enumerate.
  // Filled in below, where `WorkspaceSeeder` is actually constructed (~5.4k
  // lines further down). The demo's pool only calls it from `start()`, which
  // runs after the ready banner, so the late binding is never observed unset —
  // the same shape as `networkRuntimeHolder`.
  WorkspaceSeeder? demoBaseSeeder;
  final demo = demoBuilder == null
      ? null
      : await demoBuilder(
          DemoRuntimeContext(
            limits: DemoLimits.fromEnvironment(serverEnv),
            dataDir: config.dataDir,
            publicUrl: config.publicUrl,
            signalingUrl: config.signalingUrl,
            globalDb: globalDb,
            workspaceDbs: workspaceDbs,
            workspaceRepository: workspaceRepository,
            userRepository: userRepository,
            membershipRepository: membershipRepository,
            secrets: secrets,
            eventBus: eventBus,
            changeSignals: prChangeSignals,
            pullRequestToWire: pullRequestToWire,
            describeDescriptor: () async =>
                (await descriptorService.describe()).toJson(),
            relayRoom: () => serverIdentity.relayRoom,
            // The product's own seeder, so a demo workspace starts as a
            // NORMAL workspace (CEO, specialists, the built-in pipeline
            // templates) that the demo then furnishes and prunes.
            baseSeed: (workspaceId) async =>
                demoBaseSeeder?.seed(workspaceId),
            // The inbox's "agent is waiting on you" lane reads the LIVE
            // confirmation registry; the demo seeder furnishes it with one
            // pending approval per workspace. No timeout: it stays pending
            // until a visitor resolves it through `confirmation.respond`.
            registerConfirmation: (request) =>
                pendingConfirmationRegistry.register(
                  request,
                  timeoutOverride: null,
                ),
            // Real newsfeed articles within seconds of a claim, not on the
            // next 30-minute sweep. Best-effort inside; failures are logged
            // there, never surfaced to the visitor.
            refreshNewsfeed: (userId) => newsfeedRepository
                .refreshAll(userId)
                .timeout(const Duration(seconds: 20))
                .then((_) {}, onError: (Object e) {
                  CcHostLog.warning(
                    'demo: newsfeed refresh for $userId failed: $e',
                  );
                }),
            log: (message) => _announce('cc_server: $message'),
          ),
        );
  if (demo != null) {
    _announce('cc_server: DEMO MODE — ${demo.profile.runtimeType} lockdown, '
        'no provider credentials, no execution surface');
  }

  // The CALLER's merged history, asked of each forge under that caller's own
  // per-forge identity — the same human is `octocat` on GitHub and something
  // else on GitLab, so there is no single login to search by, and the server's
  // viewer identity is not the member's. Both tear-offs already take the
  // acting user, so the per-actor threading is the op handler's one argument.
  final mergedHistory = MultiForgeMergedHistory(
    clientFor: forgePrClientForRepo,
    viewerLoginFor: forgeCredentials.viewerLogin,
  );

  // Authenticated PR-review host, one factory per connected forge. Lights up
  // the `pr_review.*` detail/diff/comment ops over RPC for every repo whose
  // forge has a credential; repos on an unconnected forge resolve to the empty
  // repository and their surface reads "connect <forge>" rather than failing.
  //
  // The local-git diff source backs the >3000-file fallback and runs `git` on
  // the server's own checkout. A null rift client means "no CoW seeding wired
  // here, use a network clone" — distinct from a rift client whose dylib will
  // not load, which is a broken install and throws (see
  // `PrCloneManager._tryRiftCopy`).
  final localGitPrDiffSource = LocalGitPrDiffSource(
    git: const ProcessGitCommandAdapter(),
    filesystem: workspaceFilesystem,
    githubToken: ghToken,
  );
  // One registry per acting user. Every `pr_review.*` mutation — approve,
  // comment, reply, react, merge, assign, request reviewers — goes out on the
  // client this registry built, so the registry is where "as whom" is decided.
  // A single shared registry (what this was) authored all of them as the
  // server's app identity, whoever clicked.
  //
  // Memoized per user rather than per call: each registry holds three Dio
  // clients whose interceptors read the credential per request, so this caches
  // plumbing and never a token.
  final actorForgeRegistries = <String, ForgeProviderRegistry>{};
  ForgeProviderRegistry forgeRegistryForActor(String? userId) =>
      actorForgeRegistries.putIfAbsent(
        userId ?? '',
        () =>
            // A demo's PR surface is cache-backed and holds no client at all,
            // so there is nothing to author writes as and nothing to dial.
            demo?.forgeRegistryFor(userId) ??
            buildForgeProviderRegistry(
          workspaceDbs: workspaceDbs,
          dioFactory: forgeDioFactoryForActor(userId),
          localGitSource: localGitPrDiffSource,
          eventBus: eventBus,
          changeSignals: prChangeSignals,
        ),
      );

  _bootMark('wiring agent executor + tool surface');
  // ── Agent executor (pure-Dart) ──
  // The headless server runs agents itself now that the dispatch engine is
  // Flutter-free: `claude -p` (and the other CLIs) are spawned through the
  // sandboxed dispatch session and AgentStreamProcessor persists streamed
  // segments onto the message rows connected clients already watch
  // (`messaging.watchMessages`) — so a web/thin client's "send + dispatch"
  // reply streams in with no extra infra. Credentials come from the server's
  // environment (no OS keychain).
  final sandboxManager = SandboxManager();
  final nativeSandbox = NativeSandboxAdapter(manager: sandboxManager);
  // Sandbox DETECTION reports this host's real OS-native capabilities (which
  // backends are available + the recommended one) so a connected web/thin
  // client's Settings → Sandboxing page reflects the SERVER host, not the
  // browser.
  final sandboxDetector = SandboxBackendDetector([
    NoSandboxAdapter(),
    nativeSandbox,
  ]);
  // …and EXECUTION now follows that detection instead of ignoring it. The
  // probe is the gate because `SandboxManager.wrap` throws `UnsupportedError`
  // on a host with no backend (Windows) and `LinuxSandbox` needs `bwrap` +
  // `socat` present — so wiring the sandbox unconditionally would fail every
  // bash call there rather than sandbox it. Probing is cheap: a const on
  // macOS, two PATH lookups on Linux.
  //
  // Both seams have to be fed, because the transports do not share one:
  //   * `sandbox` (the SandboxPort) wraps the structuredCli / claudeCli
  //     transports via launch/exec — that is Pi and Claude Code only. Codex is
  //     `AdapterTransport.acp`, so it rides the manager below.
  //   * `sandboxManager` wraps the ACP transport and the built-in harness
  //     `bash` tool via `wrap()`.
  // Passing only one leaves the other transport unsandboxed. Every wrapped
  // path populates `SandboxSpec.protectedPaths` for itself (the ACP config
  // builder and the harness command runner both call the resolver), so the
  // deny-write rules over the operator's registered checkouts apply on all
  // three — but only once a backend is actually attached here.
  final sandboxProbe = await nativeSandbox.probe();
  final useNativeSandbox = config.sandboxEnabled && sandboxProbe.available;
  if (useNativeSandbox) {
    CcHostLog.info('cc_server: agent sandbox ON — ${sandboxProbe.note}');
  } else if (!config.sandboxEnabled) {
    CcHostLog.warning(
      'cc_server: agent sandbox DISABLED by --sandbox off. Agent runs are '
      'bounded by env sanitization, the command policy and the action '
      'guardrails only.',
    );
  } else {
    CcHostLog.warning(
      'cc_server: no OS-native agent sandbox on this host '
      '(${sandboxProbe.note ?? Platform.operatingSystem})'
      '${sandboxProbe.installHint == null ? '' : ' — ${sandboxProbe.installHint}'}. '
      'Agent runs are bounded by env sanitization, the command policy and the '
      'action guardrails only.',
    );
  }
  // The process environment with the working directory's `.env` layered under
  // it — one map for every credential the boot reads, so a value configured in
  // the file behaves exactly like an exported one.
  final serverCredentials = EnvCredentialsRepository(environment: serverEnv);
  // With a GitHub App configured, mint fine-grained, repo-scoped, ~1h
  // installation tokens per sandbox launch instead of handing agents a broad
  // token (§1.1/1.2). The installation is resolved from the run's repo OWNER at
  // mint time — the app may be installed on several accounts, and which one
  // matters is only known once a repo is in hand.
  //
  // The SAME app the rest of the server uses (`providerApps.githubApp()`),
  // resolved per mint so configuring it in Settings needs no restart. No app →
  // the broker falls back to the plain env-PAT path, as before.
  final CredentialBrokerPort credentialBroker = GitHubFineGrainedTokenBroker(
    serverCredentials,
    app: providerApps.githubApp,
    // So the raw-PAT fallback is withheld from a run acting for a member who
    // is not the operator — that PAT is the server's credential, not theirs.
    serverOwnerUserId: () async => ownerUserId,
  );
  // Server-owned LLM provider credential store (the "brain"): UI-saved API keys
  // and OAuth tokens persist to a 0600 JSON file under the data dir, with the
  // process environment as a read-only fallback. The SAME instance backs both
  // the harness dispatch and the `providers.*` RPC ops so a key saved over RPC
  // is immediately usable by a dispatched agent.
  final harnessCreds =
      // The demo satisfies the auth gate with a `method: none` credential, so a
      // scripted run reaches the loop with no key anywhere on the box.
      demo?.credentials ??
      harnessCredentialStore ??
      CompositeProviderCredentialStore([
        FileProviderCredentialStore(
          dataDir: config.dataDir,
          onWarning: (message) => CcHostLog.warning('credentials: $message'),
        ),
        EnvProviderCredentialStore(),
      ]);
  // Server-owned OAuth broker: runs the browser-login flows (PKCE + loopback),
  // persists tokens into the same credential store and refreshes them before
  // expiry for dispatched harness runs.
  // `dataDir` lets device-code flows (Kimi Code) keep a stable device identity
  // across restarts instead of re-registering as a new device every launch.
  final harnessOAuthBroker = HarnessOAuthBroker(
    store: harnessCreds,
    dataDir: config.dataDir,
  );
  // Bundled models.dev catalog for the built-in harness: supplies per-model
  // reasoning support (effort clamping), USD pricing and context-window size.
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
  // Per-model overrides (Settings → Model providers → edit model): the sync
  // in-memory view the dispatch modelResolver consults, refreshed from the
  // credential store once here and kept current by the providers.* ops.
  final harnessModelOverrides = HarnessModelOverrideCache(
    credentials: harnessCreds,
  );
  await harnessModelOverrides.refresh();
  // PRD 23 Layer 3: attach the budgeted, inert LLM reviewer to the scan gate now
  // that the provider deps exist. It picks the cheapest recent model, runs one
  // tool-less completion with a hard timeout and only tightens a passing
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
  // In-flight transcript lane, shared by space turns (keyed by message id) and
  // subagent runs (keyed by run id). Constructed here rather than next to the
  // relay wiring below because the dispatch adapter's subagent recorder needs it.
  final streamRegistry = ActiveStreamRegistry();
  // Original repo checkouts, resolved per workspace: sandbox deny-write rules
  // for every dispatch AND the protected-paths input the context-inspection
  // service rebuilds the harness tool surface with. One closure, so the run
  // and the explorer can never disagree about what is protected.
  Future<List<String>> protectedPathsResolver(String workspaceId) async {
    final repos = await workspaceRepository
        .watchReposForWorkspace(workspaceId)
        .first;
    return [for (final r in repos) r.path];
  }

  final agentDispatch = SandboxedAgentDispatchAdapter(
    // ── The demo's execution boundary ──
    // Injecting the LOOP (not a fake dispatch port, and not just a scripted
    // provider) is what makes a public demo safe: the dispatch path builds its
    // REAL tool surface, so a scripted model emitting a `bash` call would
    // really run bash. A scripted loop ignores the tools and the provider
    // entirely — zero tools execute — while every persistence path around it
    // (run logs, transcript segments, the live stream, cost accounting,
    // `AgentRunCompleted`) behaves exactly as on a real run.
    agentLoop: demo?.agentLoop ?? const AgentLoopRunner(),
    // Belt: harness-only, so any other `cliName` resolves to null and fails
    // with "No execution backend" rather than reaching for a CLI.
    backendRegistry: demo?.backendRegistry,
    harnessProviderFactory:
        demo?.harnessProviderFactory ?? const HarnessProviderFactory(),
    // See the sandbox probe above: `sandbox` covers structuredCli/claudeCli,
    // `sandboxManager` covers ACP + the harness `bash` tool. Both fall back to
    // the previous unsandboxed behaviour on a host that cannot sandbox.
    sandbox: useNativeSandbox ? nativeSandbox : NoSandboxAdapter(),
    sandboxManager: useNativeSandbox ? sandboxManager : null,
    credentialBroker: credentialBroker,
    // Asks once per worktree whether agents may run the tools a repo installs
    // for itself, then re-opens exec for exactly that tree.
    execGrantService: execGrantService,
    // Lets `terminate()` and the silence watchdog actually STOP the agent's
    // child process (they used to only stamp the run row failed, leaving the
    // CLI running and its sandbox handle held forever).
    processControl: const ProcessControlService(),
    // The harness `read` (did-you-mean on missing paths) + `file_search`
    // tools run on the same fff engine as the Explorer search.
    fileSearch: CcNativesFileSearchPort(fileSearch: ideFileSearch),
    // Two-tier tool surface: a small resident set plus a name index of the
    // rest, which load on first use. `--tool-deferral=off` restores the
    // pre-deferral request byte for byte.
    toolDeferralEnabled: config.toolDeferralEnabled,
    // UAC approvals for prompt-tier commands + escalations, threaded to the
    // harness/dispatch session. Shares the registry above so the harness path
    // and MCP tools surface approvals through the same client-facing queue;
    // without it the dispatch path fails closed and denies gated actions.
    confirmationPort: confirmationPort,
    // The `ask_user` tool: a structured question rendered in the conversation,
    // blocking the run until a human answers. Same instance the RPC catalog
    // resolves the answer through.
    agentQuestionPort: agentQuestions,
    // Externalizes tool-result screenshots so the transcript carries a
    // reference the `/blob` route resolves, not megabytes of base64 in a
    // message row.
    blobStore: blobStore,
    // Diagnostics, navigation and rename. The real payoff is that `write` and
    // `edit` come back carrying the compiler's opinion, so an agent finds out
    // it broke the build at the moment it broke it.
    lspSupervisor: lspSupervisor,
    // Structural search and rewrite over the tree-sitter we already link.
    astParsers: astParsers,
    // True resume: the next run reads the model's own earlier reasoning and
    // the actual bytes its tools returned.
    transcriptStore: transcriptStore,
    // The `debug` tool: a stopped frame answers every question about that
    // moment at once, where a print statement answers one and costs a run.
    debugSupervisor: debugSupervisor,
    // Where an `eval` kernel runs. THE ENCLOSURE WHEN THE CONVERSATION HAS
    // ONE: a persistent interpreter driven by a model reading an untrusted
    // repo is precisely the shape the enclosure-only rule exists for — a
    // one-shot `bash` call at least ends, while a kernel is a shell that
    // remembers. It does NOT boot a rig to get there, for the same reason a
    // rig tab never auto-starts: an expensive surprise is worse than running
    // on the host, and this way the fallback is a decision made in the open.
    kernelLauncherFactory:
        ({
          required String workingDirectory,
          String? workspaceId,
          String? conversationId,
        }) async {
          if (workspaceId != null && conversationId != null) {
            final transport = enclosureService?.execTransportFor(
              workspaceId: workspaceId,
              conversationId: conversationId,
            );
            if (transport != null) {
              return RigKernelLauncher(
                transport: transport,
                guestWorkingDirectory: kSmolvmGuestWorkdir,
              );
            }
          }
          return HostKernelLauncher(workingDirectory: workingDirectory);
        },
    // Unified action guardrails (PRD 24 §3): the SAME guard the MCP + repo-op
    // dispatchers use now gates the BUILT-IN harness loop by declared effect
    // class — the path bridged MCP tools take (they bypass the MCP dispatcher).
    actionGuard: actionGuard,
    // The same fail-closed gate the install path uses, so a repo's own skills
    // pass a verdict before they are projected into an agent's overlay: they
    // are cloned content whose frontmatter is autoloaded into a prompt.
    skillScanner: skillScanner,
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
    // Per-space autonomy dial (PRD 16 §12): consulted by the harness's
    // approval gate — proposeOnly denies gated tools, actFreely pre-approves,
    // unset/actWithApproval keeps the fail-closed gate.
    autonomyResolver: (workspaceId, spaceId, agentId) async {
      final row = await workspaceDbs
          .of(workspaceId)
          .spaceExtrasDao
          .autonomyFor(workspaceId, spaceId, agentId);
      return row?.autonomyLevel;
    },
    // Built-in harness (AdapterTransport.harness): expose CC's MCP tools to
    // the agent loop as first-class tools and resolve LLM provider keys from
    // the server-owned credential store (UI-saved keys/OAuth + env fallback).
    mcpRegistry: mcpRegistry,
    harnessCredentialStore: harnessCreds,
    harnessCredentialRefresher: harnessOAuthBroker,
    // Parks a harness run with no credential for its provider instead of
    // ending the turn, and re-mirrors a Claude Code account's Keychain
    // credential so the sign-in probe can see a `claude auth login` that
    // happened in a terminal.
    credentialGate: credentialGate,
    syncClaudeCredential: (accountId) =>
        claudeAccountStore.syncCredentialFromKeychain(accountId),
    modelResolver: (qualified) =>
        harnessModelOverrides.resolve(harnessModelCatalog.resolve, qualified),
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
    // Resolves the run worktree's origin coordinates so the broker mints a
    // repo-scoped GitHub App installation token for exactly that repo. Agent
    // runs never carry a member's personal GitHub token: agent work is
    // authored on the forge as the App (the human is credited via the commit
    // co-author trailer); only the per-actor RPC lane acts as a person.
    repoInspector: const GitRepoInspector(),
    // Original repo checkouts become sandbox deny-write rules in every mode:
    // agents only ever write in their per-conversation CoW worktrees and the
    // registered checkout (`repos.path`) stays untouchable even under macOS
    // Seatbelt's blanket `$HOME` write allowance.
    protectedPathsResolver: protectedPathsResolver,
    // Point the spawned `claude` at THIS server's own loopback MCP HTTP
    // endpoint so server-run agents get the `mcp__*` tool surface — crucially
    // `submit_output`, which writes a pipeline run's structured output so the
    // step resume listener can harvest it and advance. Without this, an
    // agent-dispatching pipeline step ends but fails harvest (no payload). The
    // resolver is per-session (called with the agent's cwd + identity scope):
    // it force-starts the loopback MCP server (idempotent, independent of the
    // user-facing enable toggle) and writes a fresh derived client config into
    // `<cwd>/.mcp.json` so a port/token change is always picked up, each
    // agent's config is isolated to its own overlay cwd and the `X-CC-*`
    // scope headers pin the session to its workspace server-side.
    mcpConfigPathResolver:
        (cwd, {workspaceId, agentId, conversationId, spaceId}) async {
          await mcpControl.ensureRunningForDispatch();
          // `.absolute` guards against a relative cwd reaching the spawned agent:
          // `claude` resolves `--mcp-config` against ITS cwd, so a relative path
          // would double (`<cwd>/<relative>/.mcp.json` → not found).
          return mcpControl.writeAgentMcpConfig(
            File('$cwd/.mcp.json').absolute,
            workspaceId: workspaceId,
            agentId: agentId,
            conversationId: conversationId,
            spaceId: spaceId,
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
    conversationRepository: conversationRepository,
    embeddingPort: embeddingService,
  );
  // ONE rift registry for every managed copy on this host — conversation
  // worktrees and PR worktrees alike. It has to be one file: rift's marker lives
  // in the SOURCE repo (`<repo>/.rift`) and names an entry id, so a second
  // registry looking at the same repo sees a marker it doesn't know
  // (`marker_mismatch` / `unknown_marker`) and every provision for that repo
  // fails. Two registries meant whichever surface reached a repo first silently
  // locked the other one out of copy-on-write.
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
    // Uncommitted work found on the teardown path is captured HERE, as a
    // patch plus a copy of the untracked files — under the data dir, never in
    // a checkout. It used to be committed inside the worktree and labelled
    // with a `rescue/*` branch, which is a write into the operator's own repo
    // for every backend that shares its object store.
    wipRescueDir: p.join(config.dataDir, 'wip_rescues'),
  );
  // Per-conversation worktree + per-agent overlay provisioning. WITHOUT this
  // the dispatch service falls back to the agent's global dir, so no
  // `conversations/<spaceId>/agents/<slug>/` overlay is built and the derived
  // `.mcp.json` lands in the wrong place. rift copy-on-write worktrees are
  // ENABLED: the dylib is resolved from the same app-support locations
  // (`CC_NATIVE_LIB_DIR` / data dir / bundle) the other natives use, and it is
  // the SOLE backend: a CoW failure fails the provision rather than writing a
  // `git worktree` into the operator's own checkout. The Drift
  // `isolatedRepoRepository` is the shared, canonical worktree registry (rows
  // keyed per conversation/PR).
  // Per-repo lifecycle scripts (setup/archive): persisted as columns on the
  // repos rows, executed by the server against a space's worktree at
  // provision/teardown time. Runs are recorded in `repo_script_runs`, which
  // the Settings scripts dialog reads back for its history + output tail.
  final repoScriptRepository = DaoRepoScriptRepository(workspaceDbs);
  final repoScriptService = RepoScriptService(
    scripts: repoScriptRepository,
    runs: repoScriptRepository,
    repos: repoRepository,
    spaceNameResolver: (workspaceId, spaceId) async =>
        (await messagingRepository.getSpaceById(workspaceId, spaceId))?.name,
    // Test runs (the scripts dialog's Test button) execute in a throwaway
    // rift clone under the workspace's own tmp dir — same volume as the data
    // root, so the CoW copy stays cheap — and are swept when stale.
    repoIsolation: repoIsolation,
    testCloneParentDir: (workspaceId) async {
      final dir = p.join(config.dataDir, workspaceId, 'tmp', 'script_tests');
      await workspaceFilesystem.ensureDir(dir);
      return dir;
    },
  );
  final conversationProvisioner = RepoWorkspaceProvisioner(
    filesystem: workspaceFilesystem,
    isolation: repoIsolation,
    registry: isolatedRepoRepository,
    // Setup runs right after a fresh worktree is registered (a failure fails
    // the provision); archive runs before one is destroyed (best-effort).
    scripts: repoScriptService,
    workspaces: workspaceRepository,
    githubToken: () => forgeCredentials.tokenFor(ForgeHost.github),
    // The workspace's own branch-name convention, read from its settings
    // store. This used to be hardcoded to the built-in default, so the
    // template configured in the UI had never reached the only code that
    // consumes it — the setting was inert, not merely device-local.
    branchTemplate: (workspaceId) async =>
        await workspaceSettingsRepository.get(workspaceId, 'branch_template') ??
        BranchTemplateResolver.defaultTemplate,
    // Lets the cleanup sweep reclaim worktrees (and conversation folders) whose
    // space is gone. `SpaceDeleted` handles the live path; this catches the
    // ones it missed — server down at deletion time, or a row removed directly.
    spaceExists: (workspaceId, spaceId) async =>
        await messagingRepository.getSpaceById(workspaceId, spaceId) != null,
    // What this space is SUPPOSED to check out, resolved from the space rather
    // than from whichever call site happens to be provisioning it.
    //
    // `SpaceProvisioningService` passed a scope at creation; `AgentDispatchService`
    // passes none on every dispatch, and "none" used to mean "every repo in the
    // workspace, on its default branch". So a PR review space scoped to one repo
    // at the PR head grew a full clone of every OTHER workspace repo the moment
    // an agent was sent into it — three reviewers, three times over.
    spaceCheckoutScope: (workspaceId, spaceId) async {
      final assoc = await reviewSpaceRepository
          .watchBySpace(workspaceId, spaceId)
          .first;
      if (assoc != null) {
        // A PR space checks out exactly the repo under review, at the PR head.
        final linked = await workspaceRepository
            .watchReposForWorkspace(workspaceId)
            .first;
        return SpaceCheckoutScope(
          repoIds: {
            for (final r in linked)
              if ('${r.remoteOwner}/${r.remoteName}' == assoc.repoFullName)
                r.id,
          },
          prHeadRef: 'refs/pull/${assoc.prNumber}/head',
          prHeadRepoFullName: assoc.repoFullName,
          prBranch: 'pr/${assoc.prNumber}',
        );
      }
      final db = workspaceDbs.of(workspaceId);
      final row = await db.messagingDao.getSpaceById(spaceId);
      // `noRepos` is "explicitly none" and must not read as "no selection".
      if (row?.noRepos ?? false) {
        return const SpaceCheckoutScope(repoIds: <String>{});
      }
      final selected = await db.spaceRepoDao.repoIdsForSpace(
        workspaceId,
        spaceId,
      );
      if (selected.isEmpty) {
        return null;
      }
      // The base each repo's worktree is cut from, for the repos that pin one.
      // A pipeline node names it per repo (`repoId@branch`); everything else
      // leaves it absent and takes the repo's own default branch.
      final branches = await db.spaceRepoDao.repoBranchesForSpace(
        workspaceId,
        spaceId,
      );
      return SpaceCheckoutScope(
        repoIds: selected.toSet(),
        repoBranches: branches,
      );
    },
  );
  // Claude Code logins, one directory each under `<dataDir>/claude-accounts/`.
  //
  // The bootstrap is what keeps this change invisible on an installed machine.
  // Runs used to reach the operator's keychain credential — or rather, they
  // tried: every sandbox profile denies reads under `~/Library/Keychains`, and
  // a denied keychain lookup returns "item not found" rather than an error, so
  // Claude Code reported `Not logged in` on a machine where the operator was
  // signed in. Now that runs read a config dir instead, seeding the first
  // account from that same keychain item is the difference between the fix
  // landing silently and the fix logging everyone out on upgrade.
  // Which harness credentials are out of quota. Persisted so a rotation does
  // not re-enter a spent key on every dispatch and pay a 429 to relearn it.
  final credentialCooldowns = CredentialCooldownStore(dataDir: config.dataDir);
  // ONE cache in front of the usage endpoint, shared by every reader.
  //
  // `/api/oauth/usage` rate-limits callers hard (the service says so, and it
  // returned 429s once this fan-out went per-account). Reading it once per
  // account instead of once per machine multiplies the traffic by the number
  // of accounts, and two independent readers — the title-bar pill and the
  // dispatch-time headroom check — would double it again. Going through one
  // cache keeps the fan-out from throttling itself, which is the failure that
  // reads to an operator as "no usage reported" on every account at once.
  final claudeUsageCache = ClaudeUsageCache(
    fetch: (configDir) => SubscriptionUsageService(
      dio: createDio(),
    ).fetchClaudeForConfigDir(configDir),
  );
  claudeAccountStore = ClaudeAccountStore(
    dataDir: config.dataDir,
    // The tightest window decides: whichever of the 5-hour and weekly limits
    // is closest to spent is the one that will stop a run first, so it is the
    // one the rotation must skip on.
    probeUsage: (configDir) async {
      final usage = await claudeUsageCache.get(configDir);
      // A per-token account has no windows, only a credit cap — and a cap that
      // is spent stops runs exactly like a closed window does, so it has to be
      // part of the same headroom answer or the rotation would keep choosing
      // an account that can no longer pay.
      final spend = usage.spend;
      var worst = spend != null && spend.hasLimit ? spend.usedFraction : null;
      DateTime? resetsAt;
      for (final w in usage.windows) {
        if (worst == null || w.usedFraction > worst) {
          worst = w.usedFraction;
          resetsAt = w.resetsAt;
        }
      }
      if (worst == null) {
        return null;
      }
      return (usedFraction: worst, resetsAt: resetsAt);
    },
  );
  unawaited(
    claudeAccountStore.bootstrapFromKeychain().catchError((Object e) {
      // Never fatal: a host with no keychain item simply starts with no
      // accounts, and the operator signs one in from Settings.
      _emitLog(false, 'cc_server: Claude Code account bootstrap skipped ($e)');
      return null;
    }),
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
    // under `conversations/<spaceId>/agents/<slug>/`; degrades to the agent
    // dir when no workspace/space is in play.
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
      return (args: _splitAdapterArgs(args), env: _decodeAdapterEnv(env));
    },
    // Which Claude Code login a run signs in as. Server-scoped like the launch
    // overrides above — the account directories are on THIS host.
    //
    // Reading the conversation's pin HERE rather than at each call site is
    // what makes the composer's choice apply to every way a run can start:
    // a chat turn, a ticket, a pipeline step, the goal supervisor. None of
    // them has to know the feature exists.
    // The harness half of account pools. Same vocabulary as the Claude Code
    // lane — an ordered set plus a strategy, resolved agent-then-workspace —
    // but a different mechanism underneath: the harness owns the LLM call, so
    // `FallbackProvider` swaps credential mid-stream and all this decides is
    // which one LEADS the chain.
    resolveHarnessRotation:
        ({workspaceId, agentId, required providerId, required credentialIds}) =>
            resolveHarnessRotationOrder(
              settings: workspaceSettingsRepository,
              cooldowns: credentialCooldowns,
              workspaceId: workspaceId,
              agentId: agentId,
              providerId: providerId,
              credentialIds: credentialIds,
            ),
    onHarnessCredentialExhausted:
        ({required providerId, required credentialId}) =>
            credentialCooldowns.mark(providerId, credentialId),
    // Parks a run whose Claude Code accounts are all out of headroom (or all
    // signed out) and re-resolves the plan once one is usable again, so the
    // resumed run reaches the sandbox with a directory the profile allows.
    credentialGate: credentialGate,
    resolveClaudeConfigDir:
        ({
          workspaceId,
          conversationId,
          agentId,
          accountId,
          workingDirectory,
        }) async {
          // Most-specific scope wins, the same order guardrails resolve in:
          // the agent's own pool, then the workspace's. An explicit
          // `accountId` is more specific than either and short-circuits both.
          final pool = workspaceId == null
              ? const AccountPool()
              : await _readClaudeAccountPool(
                  workspaceSettingsRepository,
                  workspaceId,
                  agentId,
                );
          final cursorKey = claudeAccountCursorKey(agentId);
          final cursor = workspaceId == null
              ? 0
              : int.tryParse(
                      await workspaceSettingsRepository.get(
                            workspaceId,
                            cursorKey,
                          ) ??
                          '',
                    ) ??
                    0;
          final plan = await claudeAccountStore.resolveForDispatch(
            pool: pool,
            pinnedAccountId: accountId,
            cursor: cursor,
          );
          if (plan.allSpent != null) {
            return ClaudeAccountPlan(
              accounts: const [],
              refusal: plan.allSpent,
            );
          }
          // Persist the round-robin position BEFORE the run, so two dispatches
          // racing still land on different accounts — writing it after would
          // let both read the same cursor and pick the same one.
          final next = plan.nextCursor;
          if (next != null && workspaceId != null && next != cursor) {
            await workspaceSettingsRepository.set(
              workspaceId,
              cursorKey,
              '$next',
            );
          }
          // Answer Claude Code's interactive gates before the run needs them.
          // Every candidate, not just the first: the fallback chain switches
          // accounts mid-run, and an unprepared fallback fails exactly like the
          // account it replaced. See [ClaudeAccountStore.prepareForRun].
          if (workingDirectory != null && workingDirectory.isNotEmpty) {
            for (final candidate in plan.candidates) {
              await claudeAccountStore.prepareForRun(
                accountId: candidate.accountId,
                workingDirectory: workingDirectory,
              );
            }
          }
          return ClaudeAccountPlan(
            accounts: plan.candidates,
            onExhausted: ({required accountId, resetsAt}) =>
                claudeAccountStore.markRateLimited(accountId, until: resetsAt),
            onAuthFailed: ({required accountId, reason}) =>
                claudeAccountStore.markAuthFailed(accountId, reason: reason),
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
  // One tool-less prompt on any adapter, with none of a dispatch's machinery
  // (no agent, no worktree, no run log, no sandbox). Titling is its only
  // caller today; anything else wanting a single short completion on the
  // workspace's chosen runner belongs here rather than in DispatchSession.
  final adapterOneShotRunner = AdapterOneShotRunner(
    credentials: harnessCreds,
    refresher: harnessOAuthBroker,
  );
  // Automatic conversation titling: the WORKSPACE's chosen runner (an
  // admin-gated adapter + model pair, read per send) names a conversation once
  // its first human message lands. Off unless the adapter setting is set — no
  // fallback runner.
  final conversationTitleService = ConversationTitleService(
    runner: adapterOneShotRunner,
    settings: workspaceSettingsRepository,
    conversationRepo: conversationRepository,
    messagingRepo: messagingRepository,
  );
  // `/handoff`, `/btw`, `/omfg`: one question ABOUT the conversation that is
  // never added to it. Runs on the SAME operator-chosen one-shot runner as
  // conversation titling — a side question that silently used a different
  // model would be a surprise on the bill.
  final conversationSideChannelService = ConversationSideChannelService(
    repo: messagingRepository,
    runner: adapterOneShotRunner,
    settings: workspaceSettingsRepository,
  );
  // Turns a rough request into an objective an agent can pursue for hours
  // without supervision. On the same one-shot runner: anything wanting a
  // single short completion on the workspace's chosen model belongs here.
  final guidedGoalService = GuidedGoalService(
    runner: adapterOneShotRunner,
    settings: workspaceSettingsRepository,
  );
  // Declared ahead of MessagingService because the two point at each other: the
  // provisioning service reads the messaging repositories, and messaging routes
  // "stop preparing this space" into the provisioning service.
  late final SpaceProvisioningService spaceProvisioningService;
  final messagingService = MessagingService(
    messagingRepository,
    agentRepo: agentRepository,
    // Resolves the space's standing conversation for dispatches that name none
    // (a ticket, a pipeline step, the chat bridge): conversations own their
    // uuid, so there is no space-id aliasing left to guess with.
    conversationRepo: conversationRepository,
    agentDispatchService: agentDispatchService,
    streamRegistry: streamRegistry,
    streamProcessor: agentStreamProcessor,
    eventBus: eventBus,
    // Forced out-of-band compaction (`/compact`) routes through the same
    // service the post-turn auto-maintenance uses.
    compactionService: conversationCompactionService,
    // The side channel behind `/handoff`, `/btw` and `/omfg`.
    sideChannelService: conversationSideChannelService,
    guidedGoalService: guidedGoalService,
    // Automatic conversation titling (see ConversationTitleService above).
    titleService: conversationTitleService,
    // Gives an attached picture or file a body an agent can open: the blob the
    // composer uploaded is written into the space's own `attachments/` dir and
    // each `@[file:…]` token in the dispatched prompt is replaced by that
    // file's path. Without it a run is handed the names of files it was never
    // given — the sender's own paths mean nothing here, and no adapter can
    // resolve a `blob:sha256:` reference.
    promptAttachments:
        SpacePromptAttachments(
          blobStore: blobStore,
          spaceDir: workspaceFilesystem.spaceDir,
        ).resolve,
    // Stopping a space's preparation (the pipeline step that owned it was
    // cancelled, or a human pressed stop in the space) kills the running clone
    // rather than only stopping whoever was waiting for it.
    cancelProvisioning: ({required workspaceId, required spaceId}) =>
        spaceProvisioningService.cancel(
          workspaceId: workspaceId,
          spaceId: spaceId,
        ),
    // Programmatic "user" messages (pipeline steps, team dispatch) with no
    // acting human are attributed to the server owner — never a sentinel.
    resolveDefaultUserId: () async => ownerUserId,
    // While a human holds a take-over on a conversation, new dispatches into
    // it are refused (PRD 16 §8 — no auto-resume into a half-finished edit).
    dispatchBlocked: (workspaceId, spaceId) async =>
        await takeoverHolder.value?.isActive(workspaceId, spaceId) ?? false,
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
          required spaceId,
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
              spaceId: spaceId,
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
          // No main-id aliasing: when the caller did not pin a stream,
          // idempotently ensure the space has one and run the goal there.
          final goalConversation =
              conversationId ??
              (await conversationRepository.ensure(
                workspaceId: workspaceId,
                spaceId: spaceId,
              )).id;
          final goal = await goalSupervisor.startGoal(
            workspaceId: workspaceId,
            spaceId: spaceId,
            conversationId: goalConversation,
            agentId: agentId,
            userText: userText,
            kind: kind,
            requestedByUserId: requestedByUserId,
          );
          // The first run's message id; null when the supervisor refused (it
          // narrates the refusal into the space itself).
          return goal?.activeRunId;
        },
  );
  // The durable steering queue. Constructed AFTER the messaging and dispatch
  // services (its lifecycle hooks are late-bound fields on them, so the
  // dependency cannot run the other way at build time): harness runs report
  // their drainable moment, run endings trigger the queued→message
  // conversion, and the messaging service's `steering.*` port methods
  // delegate here.
  final steeringQueueService = SteeringQueueService(
    messagingRepository: messagingRepository,
    runLogRepository: agentRunLogRepository,
    dispatchResponder: messagingService.dispatchResponderForText,
    sessionsForConversation: agentDispatch.sessionsForConversation,
  );
  messagingService.steeringQueueService = steeringQueueService;
  agentDispatch.onSessionHarnessStarted = steeringQueueService.handleHarnessStarted;
  agentDispatchService.onRunEnded =
      (workspaceId, conversationId, spaceId) => unawaited(
        steeringQueueService.handleRunEnded(
          workspaceId,
          conversationId,
          spaceId,
        ),
      );
  goalSupervisor = GoalSupervisor(
    goalRepository: agentGoalRunRepository,
    runLogRepository: agentRunLogRepository,
    eventBus: eventBus,
    // dispatchAgentRun, NOT dispatchAgent: the supervisor's first run
    // re-sends the verbatim `/goal ...` prompt and dispatchAgent would
    // route it straight back into the goal command handler above — an
    // infinite refusal loop.
    dispatcher: messagingService.dispatchAgentRun,
    // Same message shape as the take-over refusal (senderId 'system',
    // senderType 'agent', messageType 'system').
    systemMessageSender:
        ({
          required workspaceId,
          required spaceId,
          required content,
          conversationId,
        }) async {
          await messagingService.postSystemMessage(
            workspaceId,
            spaceId,
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
    ..register(TicketPrLinkTool(service: ticketWorkflow))
    ..register(
      TicketRelationTool(
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
    // delegation and the todo read-back half. The two peer-messaging tools
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
  // Background-provision a space's conversation workspace (repo worktrees +
  // per-agent overlay + `.mcp.json`) at creation, so the first agent turn
  // doesn't pay the setup cost and the UI can show a "preparing" state. Runs
  // unawaited off the SpaceCreated event; message dispatch is gated on
  // the space's provisioningStatus until this flips it to ready/failed.
  spaceProvisioningService = SpaceProvisioningService(
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
    setProvisioningStatus: (workspaceId, spaceId, status) => workspaceDbs
        .of(workspaceId)
        .messagingDao
        .updateSpaceProvisioningStatus(spaceId, status.toDbValue()),
    // Granular progress ("cloning repo X", "setting up agent Y"): written to
    // the space row, so it rides the same live space stream clients
    // already watch for the status. The status write clears it on ready/failed.
    setProvisioningStep: (workspaceId, spaceId, step) => workspaceDbs
        .of(workspaceId)
        .messagingDao
        .updateSpaceProvisioningStep(spaceId, step.toDbValue()),
    // PR-review spaces provision their repo at the PR head ref so chat /
    // terminal / file-edit all see the PR's proposed tree. Resolved from the
    // space's review-space association (newest wins).
    resolvePrContext: (workspaceId, spaceId) async {
      final assoc = await reviewSpaceRepository
          .watchBySpace(workspaceId, spaceId)
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
    // Per-space repo selection recorded at creation: the `noRepos` flag on
    // the space row means "explicitly none" (an empty result), join rows are
    // an explicit subset, and neither (null) means all workspace repos.
    spaceRepoIds: (workspaceId, spaceId) async {
      final db = workspaceDbs.of(workspaceId);
      final row = await db.messagingDao.getSpaceById(spaceId);
      if (row?.noRepos ?? false) {
        return const <String>[];
      }
      final selected = await db.spaceRepoDao.repoIdsForSpace(
        workspaceId,
        spaceId,
      );
      return selected.isEmpty ? null : selected;
    },
    // The same progress, announced for surfaces that watch events rather than
    // the space row — the chat bridge reports it on its task card.
    eventBus: eventBus,
    // One watchdog budget per scripted repo: a setup script still inside its
    // own (5-minute) bound must not trip the space-level watchdog.
    setupScriptedRepoCount: (workspaceId) async {
      final repos = await workspaceRepository
          .watchReposForWorkspace(workspaceId)
          .first;
      var count = 0;
      for (final repo in repos) {
        final scripts = await repoScriptRepository.getScripts(
          workspaceId,
          repo.id,
        );
        if (scripts.setup != null) {
          count++;
        }
      }
      return count;
    },
  );
  eventBus.on<SpaceCreated>().listen((e) {
    final workspaceId = e.workspaceId;
    if (workspaceId.isEmpty) {
      // A space with no workspace has no database file to live in, so there is
      // no row to flip — the event itself is the bug. Say so instead of writing
      // into an arbitrary workspace. (`SpaceCreated.workspaceId` is non-null
      // now; an EMPTY one is still reachable from a bad wire payload.)
      CcHostLog.warning(
        'space provisioning: SpaceCreated for ${e.spaceId} carries no '
        'workspace; skipping (the space row cannot be located)',
      );
      return;
    }
    unawaited(
      spaceProvisioningService
          .provision(workspaceId: workspaceId, spaceId: e.spaceId)
          .catchError((Object err, StackTrace st) {
            CcHostLog.error(
              'channel provisioning: failed for ${e.spaceId}: $err',
              err,
              st,
            );
            // Mark failed so the UI shows a retry affordance.
            workspaceDbs
                .of(workspaceId)
                .messagingDao
                .updateSpaceProvisioningStatus(e.spaceId, 'failed');
          }),
    );
  });
  // Space-provisioning reconciler: re-kick spaces a previous session left
  // stranded in `provisioning`. The ready/failed flip only ever comes from the
  // in-flight provisioning future, so a server exit mid-provision would
  // otherwise leave the space behind an eternal "preparing workspace"
  // spinner — dispatch gated, no retry affordance (retry only shows on
  // `failed`). provision() is idempotent: existing worktrees are reused. One
  // best-effort sweep at boot, mirroring the orphan-run reaper.
  unawaited(() async {
    try {
      // CROSS-WORKSPACE BY DESIGN: a boot reconciler, so it visits every
      // workspace's database once. Each workspace's stranded spaces are
      // resumed with that workspace's own id in hand.
      await crossWorkspace.forEachWorkspace((wsDb) async {
        final workspaceId = wsDb.workspaceId;
        final stranded = await wsDb.messagingDao.spacesByProvisioningStatus(
          'provisioning',
        );
        for (final row in stranded) {
          CcHostLog.info(
            'channel provisioning: resuming stranded channel ${row.id}',
          );
          unawaited(
            spaceProvisioningService
                .provision(workspaceId: workspaceId, spaceId: row.id)
                .catchError((Object err, StackTrace st) {
                  CcHostLog.error(
                    'channel provisioning: resume failed for ${row.id}: $err',
                    err,
                    st,
                  );
                  wsDb.messagingDao.updateSpaceProvisioningStatus(
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
  // Enclosures (rigs): disposable VMs an agent or a human drives, and the
  // machines the interactive terminals move into. Constructed unconditionally
  // and cheap to build — `probe()` is what decides whether anything can
  // actually boot, and it runs lazily rather than on the path to the ready
  // banner the desktop parses with a 20s timeout.
  final rigImageStore = RigImageStore(dataDir: config.dataDir);
  final rigCredentials = GuestCredentialService(broker: credentialBroker);
  final qemuBackend = QemuEnclosureBackend(
    dataDir: config.dataDir,
    images: rigImageStore,
  );
  // The microVM backend: exec (terminal) and browser rigs. Owns no state the
  // smolvm CLI does not own — the machines live in its store.
  final smolvmBackend = SmolvmEnclosureBackend(dataDir: config.dataDir);
  // Hoisted (rather than inlined into RigService) because RigEventListener
  // needs the same view: a rig event carries only workspace + rig id, so the
  // agent driving the machine is resolved from the stored row.
  final rigRepository = DaoRigRepository(workspaceDbs);
  final rigService = RigService(
    repository: rigRepository,
    qemu: qemuBackend,
    smolvm: smolvmBackend,
    images: rigImageStore,
    credentials: rigCredentials,
    eventBus: eventBus,
    // The confinement root for `install_apk` on a mobile rig: every
    // workspace's working directories live under it, and a path outside it is
    // refused rather than pushed into a guest.
    dataDir: config.dataDir,
    // A workspace may point its Terminal/Browser (VM) at its own image — an
    // admin-gated workspace setting, re-validated at boot before the value
    // touches a command line. Null/blank means the pinned defaults.
    smolvmImageOverride: (workspaceId, {required exec}) async =>
        normalizeCustomRigImageRef(
          await workspaceSettingsRepository.get(
            workspaceId,
            exec ? kRigExecImageSettingKey : kRigBrowserImageSettingKey,
          ),
        ),
    // The workspace's extra browser egress hosts — same admin-gated settings
    // store, same read-side re-validation (`parseRigEgressHostsSetting`
    // drops anything that is not a valid host entry before it reaches the
    // egress gate).
    browserEgressHosts: (workspaceId) async => parseRigEgressHostsSetting(
      await workspaceSettingsRepository.get(
        workspaceId,
        kRigBrowserEgressHostsSettingKey,
      ),
    ),
  );
  // Bind the late reference the `eval` kernel launcher reads: a cell resolves
  // its enclosure when it runs, not when the dispatch adapter was assembled.
  enclosureService = rigService;

  // Interactive terminal over RPC: a connected client runs a REAL shell on this
  // host (libccpty), or inside an enclosed VM when the `microvm` backend is
  // chosen and available. Ownership is validated per op against the bound
  // workspace.
  final terminalSessions = TerminalSessionService(
    manager: sandboxManager,
    filesystem: workspaceFilesystem,
    // Resolving a VM shell boots the conversation's exec rig on demand. It
    // returns null when no enclosure can be provided, and the terminal service
    // then fails loudly rather than quietly running the shell on the host —
    // "I asked for a VM and got my laptop" is the one degradation this feature
    // cannot afford.
    vmShell:
        ({
          required String workspaceId,
          String? conversationId,
          String? worktreePath,
          String? actingUserId,
        }) async {
          if (conversationId == null || conversationId.isEmpty) {
            return null;
          }
          try {
            // Reuse only a rig THIS member opened. One rig per conversation is
            // the feature, but it cannot span members: the rig's credential
            // grant is bound to its opener, and another member's agent may be
            // running inside with its token in the environment.
            final existing = rigService.execRigFor(
              workspaceId,
              conversationId,
              openedByUserId: actingUserId,
            );
            // The worktree's own forge, so the egress allowlist admits its
            // git host and the broker mints a credential scoped to THIS repo
            // rather than a broad one.
            final forge = existing != null || worktreePath == null
                ? null
                : await detectWorktreeForge(worktreePath);
            final rig =
                existing ??
                await rigService.open(
                  workspaceId: workspaceId,
                  spec: RigSpec.exec(
                    conversationId: conversationId,
                    worktreePath: worktreePath,
                    // The dev baseline + apt + the worktree's forge. An empty
                    // list here is not "unrestricted", it is a terminal that
                    // cannot fetch, push or `apt install` — the per-rig
                    // proxies enforce exactly this list, and the credential
                    // broker's allowed-hosts set is derived from it.
                    egressAllowlist: execRigEgressAllowlist(forge: forge),
                    // A CEILING, not an authorization. A person typing in
                    // their own terminal expects `git push` to work, so the
                    // flags stay open — but what the shell can actually reach
                    // is decided by `openedByUserId` below, against that
                    // member's own forge access.
                    //
                    // The old reasoning here was "they can push from the host
                    // anyway", which is true for the operator and false for
                    // everyone else: a member on a remote client has no host
                    // to push from, so an unbounded enclosed terminal would
                    // hand them access they do not otherwise have.
                    capabilities: const AgentCapabilities(
                      canPushToRepo: true,
                      canCallGitHubApi: true,
                      canAccessNetwork: true,
                    ),
                    repoOwner: forge?.owner,
                    repoName: forge?.name,
                    // Whose access this shell is bounded by. Falls back to the
                    // operator only when nobody was named, which is the
                    // single-operator case.
                    openedByUserId: actingUserId ?? ownerUserId,
                  ),
                  openedBy: UserPrincipal(actingUserId ?? ownerUserId),
                );
            // Wait for the boot the open() call kicked off. A terminal has
            // nowhere to render "provisioning", so this is the one caller that
            // legitimately blocks — bounded, and reported as a spawn failure
            // rather than a hang if the machine never comes up.
            final deadline = DateTime.now().add(const Duration(seconds: 150));
            while (DateTime.now().isBefore(deadline)) {
              final argv = rigService.shellArgvFor(workspaceId, rig.id);
              if (argv != null) {
                // Pin it for as long as the terminal is open, so the reaper
                // does not park the VM under a shell someone is typing in.
                return (
                  argv: argv,
                  release: rigService.pin(workspaceId, rig.id),
                );
              }
              final current = await rigService.get(workspaceId, rig.id);
              if (current == null || current.status.phase.isTerminal) {
                return null;
              }
              await Future<void>.delayed(const Duration(milliseconds: 500));
            }
            return null;
          } on Object catch (e) {
            CcHostLog.warning('terminal: could not provide an enclosed VM: $e');
            return null;
          }
        },
    // Where an ENCLOSED terminal may be rooted. A `microvm` terminal's working
    // directory becomes the rig's `worktreePath`, and a rig tars its worktree
    // into a VM the caller drives — so an unconfined `cwd` would be a host
    // directory read primitive (`~/.ssh`) for any workspace member. The
    // workspace's own tree (which contains every conversation dir and its
    // isolated worktrees) plus the repos this workspace actually registered
    // are the whole legitimate set; the service adds the workspace dir itself.
    guestRoots: (workspaceId) async {
      try {
        final repos = await repoRepository.getAll(workspaceId);
        return [for (final repo in repos) repo.path];
      } on Object catch (e) {
        // Confine harder, never wider: an unreadable registry leaves only the
        // workspace's own tree, which is always legitimate.
        CcHostLog.warning('terminal: could not read repo roots: $e');
        return const <String>[];
      }
    },
  );

  // ── Enclosure (rig) tools ──
  // Registered post-construction because they need the rig service, which
  // needs the sandbox manager and the data dir — none of which exist when the
  // DB-only `buildServerMcpRegistry` runs. Whether any of them can actually
  // boot a machine is a probe question the tools answer per call, so they are
  // registered unconditionally and report honestly rather than vanishing from
  // `tools/list` on a host that could gain a hypervisor tomorrow.
  mcpRegistry
    ..register(ComputerUseTool(rigs: rigService))
    ..register(BrowserUseTool(rigs: rigService))
    ..register(MobileUseTool(rigs: rigService))
    ..register(RigListTool(rigs: rigService))
    ..register(RigCloseTool(rigs: rigService));

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
  // ── SAML crypto native (libcc_saml) ──
  // Backs SSO SAML login: AuthnRequest building, IdP metadata parsing and
  // XML-DSig-verified Response consumption (pure-Rust `saml` crate behind a
  // stateless C-ABI seam). REQUIRED with no degraded mode — a hand-rolled
  // Dart XML-DSig is exactly where signature-wrapping vulnerabilities live,
  // so a missing library refuses SAML login and the boot preflight below.
  CcSaml.libraryResolver = () => tryOpenFirst(
    nativeLibraryCandidates(
      samlLibraryBaseName,
      appSupportRoot: config.dataDir,
      envVar: samlLibraryEnvVar,
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
      '${platformLibraryFileName(samlLibraryBaseName)} (SAML SSO response '
      'verification)',
      () async => CcSaml.isAvailable,
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
      'Looked in \$$nativeLibDirEnvVar, ${config.dataDir}, $grammarsRoot and '
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
    // watches and on stop fires the summary pipeline. Lazy worker-isolate init.
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
    // as the meeting recorder — one set of loaded ASR weights for both and
    // dictation reuses the identical rolling-window tuning. Sharing is safe in
    // both directions: `unload()` no-ops while decodes are pending and leaves
    // the transcriber reusable, so a meeting going idle mid-dictation cannot
    // strand a window (the next chunk re-initializes lazily).
    dictationService = DictationService(transcriber: transcriber);
  } else {
    // Not "until a voice model is installed" any more: the warm-up at the end
    // of boot is about to fetch one unconditionally. Saying so is the whole
    // difference between "go do something" and "wait, then restart" — the
    // transcriber resolved its model here, minutes before that download can
    // land, so this boot serves no speech ops however the fetch goes.
    CcHostLog.warning(
      'cc_server: no speech model installed under ${config.dataDir} — meeting '
      'recording and composer dictation over RPC are unavailable FOR THIS RUN '
      '(the `meeting.startRecording`/`ingestAudio`/`stopRecording` and '
      '`dictation.start`/`ingestAudio`/`stop` ops stay absent). The model is '
      'downloaded in the background below; restart the server once it reports '
      'installed to enable them.',
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
  // fixed). The choice is persisted so it survives a restart and the meeting-
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
    onLog: (level, m) => _modelLog(level, 'voice model', m),
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
    description: modelDescription(
      embeddingModelManager.model.displayName,
      embeddingModelManager.model.modelBytes,
    ),
    onLog: (level, m) => _modelLog(level, 'embedding model', m),
  );
  final diarizationModelControl = ManagedModelControl(
    probeInstalled: () async =>
        (await diarizationModelManager.resolve()) != null,
    runInstall: diarizationModelManager.install,
    runUninstall: diarizationModelManager.uninstall,
    description: modelDescription(
      diarizationModelManager.model.displayName,
      diarizationModelManager.model.segmentationArchiveBytes +
          diarizationModelManager.model.embeddingBytes,
    ),
    onLog: (level, m) => _modelLog(level, 'diarization model', m),
  );

  // ── Code graph indexer (the `code.index` body of the `index_code` pipeline,
  // fired by `RepoAdded`) ──
  // Built from the workspace-scoped code-graph repo + the tree-sitter grammar
  // manager (constructed above, so the preflight can resolve every grammar
  // before boot completes), mirroring the desktop `codeIndexerProvider`. Symbols
  // are embedded on index when the embedding model is installed (semantic code
  // search via `search_code`) and fall back to FTS + graph otherwise. The
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
  // tree, not the linked checkout's) and reindexes incrementally on any file
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
  // workspaceId → (fetchedAt, spaceId → last message time).
  final spaceActivity = <String, MapEntry<DateTime, Map<String, DateTime>>>{};
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
    // the desktop's initial RPC burst (workspace list, space hydration).
    initialDelay: Duration(seconds: config.codeIndexDeferSeconds),
    // Only RECENTLY ACTIVE conversations get a file watcher. Measured here:
    // 117 worktree rows, 15 of them active in the last week and 72 belonging to
    // conversations that never exchanged a message. Arming a watcher costs a
    // full recursive scan, so watching the dormant 100 froze startup for ~65s
    // and served nobody — a conversation nobody is working in is not being
    // edited. Reopening one arms it within a reconcile tick and the cleanup
    // pipeline reclaims the rows that are genuinely finished.
    shouldWatchSpace: (workspaceId, spaceId) async {
      // Last MESSAGE time, not the space row's `updatedAt` — that is bumped by
      // any write (provisioning included), so it reads as "fresh" for every row
      // and filters nothing. One aggregate query per workspace, cached briefly
      // because the arming pass asks about ~100 spaces back to back.
      final cached = spaceActivity[workspaceId];
      var activity = cached?.value;
      if (activity == null ||
          DateTime.now().difference(cached!.key) > const Duration(minutes: 2)) {
        final rows = await workspaceDbs
            .of(workspaceId)
            .messagingDao
            .watchSpaceActivity(workspaceId)
            .first;
        activity = {
          for (final row in rows)
            if (row.lastMessageAt != null) row.spaceId: row.lastMessageAt!,
        };
        spaceActivity[workspaceId] = MapEntry(DateTime.now(), activity);
      }
      final lastMessageAt = activity[spaceId];
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
  // natives, so a PR worktree is a fast CoW clone — and only that: a CoW
  // failure fails the provision instead of writing into the checkout. Declared
  // before the pipeline executor because that executor consumes it (worktree GC).
  final prWorktree = PrWorktreeService(
    filesystem: workspaceFilesystem,
    isolation: repoIsolation,
    registry: isolatedRepoRepository,
    githubToken: () => forgeCredentials.tokenFor(ForgeHost.github),
  );

  // ── Pipeline executor (pure-Dart) ──
  // The headless server owns the pipeline engine + its step bodies (the same
  // ones the desktop registers), driving the relocated dispatch stack. The
  // common/core + PR-review + meeting + code-index bodies are wired; the
  // remaining heavier body (cleanupRepos) needs the rift stack and is a
  // follow-up (see buildServerPipelineExecutor).

  /// Late-bound forwarder to `ensurePrSpace` for the `messaging.createSpace`
  /// body — see the `ensureReviewSpace` argument below.
  late final Future<String?> Function({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prExternalId,
    String title,
  })
  ensureReviewSpaceFn;

  /// Late-bound forwarder to [ReviewFinalizer] for the `prReview.finalize`
  /// body — the finalizer is constructed further down this function.
  late final Future<Map<String, dynamic>> Function({
    required String workspaceId,
    required String spaceId,
    String? editorialNote,
    ReviewLevel level,
    String? headSha,
  })
  finalizeReviewFn;

  final pipeline = buildServerPipelineExecutor(
    templateRepository: pipelineTemplateRepository,
    runRepository: pipelineRunRepository,
    agentRunLogRepository: agentRunLogRepository,
    agentRepository: agentRepository,
    teamRepository: teamRepository,
    credentials: serverCredentials,
    messagingPort: messagingService,
    messagingRepository: messagingRepository,
    isolatedRepoRepository: isolatedRepoRepository,
    agentDispatchPort: agentDispatch,
    githubPrClient: serverGitHubClient.pr,
    orchestrationRepository: orchestrationRepository,
    ticketWorkflow: ticketWorkflow,
    codeIndexer: codeIndexer,
    skillAnalysis: skillAnalysis,
    eventBus: eventBus,
    schemaValidator: const JsonSchemaValidator(),
    runDirPath: (runId) async => (await paths.pipelineRunDir(runId)).path,
    // `messaging.createSpace`: the review pipeline's first step resolves the
    // PR's one backing space through the SAME closure the PR workbench uses,
    // so a review started from the pipeline and a PR page opened by hand land
    // in one room with one checkout at the PR head. Forwarded through
    // [ensureReviewSpaceFn] because `ensurePrSpace` is declared further down
    // this function and Dart refuses a local referenced before its
    // declaration; the holder is assigned the moment that declaration is
    // reached, which is still during boot and long before a step can run.
    ensureReviewSpace:
        ({
          required String workspaceId,
          required String repoFullName,
          required int prNumber,
          required String prExternalId,
          String title = '',
        }) => ensureReviewSpaceFn(
          workspaceId: workspaceId,
          repoFullName: repoFullName,
          prNumber: prNumber,
          prExternalId: prExternalId,
          title: title,
        ),
    // `prReview.finalize`: the same deterministic finalizer the
    // `finalize_review` MCP tool uses, so a pipeline review and an agent-driven
    // one produce the same verdict from the same findings.
    finalizeReview:
        ({
          required String workspaceId,
          required String spaceId,
          String? editorialNote,
          ReviewLevel level = ReviewLevel.balanced,
          String? headSha,
        }) => finalizeReviewFn(
          workspaceId: workspaceId,
          spaceId: spaceId,
          editorialNote: editorialNote,
          level: level,
          headSha: headSha,
        ),
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
  );
  final cancelOrchestration = CancelOrchestrationUseCase(
    orchestrations: orchestrationRepository,
    engine: pipeline.engine,
    ticketWorkflow: ticketWorkflow,
  );

  // ── Plan Studio (PRD 17) ──
  // Revision history + operator edits, plan-mode documents, playbooks,
  // honest per-node estimates and plan-drift detection — all served over
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
      await messagingRepository.setSpaceMode(
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
      // node carries its space id), so this line is the seam between the plan
      // and its execution.
      final steps = plan.graph.workNodes.length;
      await messagingRepository.sendMessage(
        workspaceId: plan.workspaceId,
        spaceId: plan.conversationId,
        conversationId: plan.conversationId,
        content:
            'Plan approved — executing $steps '
            '${steps == 1 ? 'step' : 'steps'} in this conversation.',
        senderId: 'system',
        senderType: 'agent',
        messageType: 'system',
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
    revisions: orchestrationRevisionRepository,
  );
  mcpRegistry
    ..register(proposeOrchestrationTool)
    ..register(
      SubmitPlanTool(
        runLogRepository: agentRunLogRepository,
        planDocuments: planDocumentRepository,
        // A submitted plan announces itself in the conversation it was authored
        // in (typed `plan` bubble), so it is discoverable without navigating to
        // Plan Studio and noticing a new card.
        messaging: messagingRepository,
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
  // diffs (golden harness — degraded gracefully without a Flutter SDK) and
  // per-axis results — all served over `review_studio.*` ops below. Compute
  // runs on this host (it owns the code graph + git + PR fetch).
  final reviewCohortRepository = DaoReviewCohortRepository(workspaceDbs);
  final apiContractDiffRepository = DaoApiContractDiffRepository(workspaceDbs);
  final visualDiffRepository = DaoVisualDiffRepository(workspaceDbs);
  final reviewAxisResultRepository = DaoReviewAxisResultRepository(
    workspaceDbs,
  );
  final reviewDependencyDiffRepository = DaoReviewDependencyDiffRepository(
    workspaceDbs,
  );
  final reviewRunSnapshotRepository = DaoReviewRunSnapshotRepository(
    workspaceDbs,
  );
  final reviewCohortService = ReviewCohortService(
    workspaceDbs: workspaceDbs,
    cohorts: reviewCohortRepository,
    idFactory: () => const Uuid().v4(),
  );
  final reviewDependencyService = ReviewDependencyService(
    repository: reviewDependencyDiffRepository,
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
      if (r.remoteOwner.toLowerCase() == owner.toLowerCase() &&
          r.remoteName.toLowerCase() == repo.toLowerCase()) {
        return r;
      }
    }
    throw const NotFoundException('Repository is not linked to this workspace');
  }

  // Resolves a PR's REAL GitHub node id — the canonical review-studio key
  // (unified with `review_spaces.prExternalId`, migration 46). Association-first
  // (a linked review space already stores it → pure DB), then a cached GitHub
  // fallback for a studio-only PR that has no review space yet. Cached per
  // server lifetime keyed by `owner/repo#n`.
  final prExternalIdCache = <String, String>{};
  Future<String> resolvePrExternalId({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
  }) async {
    final cacheKey = '$owner/$repo#$prNumber';
    final cached = prExternalIdCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    final repoFullName = '$owner/$repo';
    final assocs = await reviewSpaceRepository
        .watchByWorkspace(workspaceId)
        .first;
    for (final a in assocs) {
      if (a.repoFullName == repoFullName &&
          a.prNumber == prNumber &&
          a.prExternalId.isNotEmpty) {
        return prExternalIdCache[cacheKey] = a.prExternalId;
      }
    }
    final gh = await serverGitHubClient.pr.getPullRequest(
      owner,
      repo,
      prNumber,
    );
    final externalId = gh != null
        ? pullRequestFromGitHub(gh, repoFullName: repoFullName).externalId
        : '';
    // Last resort (PR not found): the synthetic key, so the key is never empty.
    return prExternalIdCache[cacheKey] = externalId.isNotEmpty
        ? externalId
        : cacheKey;
  }

  // The reviewer fan-out + GitHub publish services back the AI-review MCP
  // surface (dispatch_reviewers / publish_review_to_github) and the client
  // publish RPC op.
  final dispatchReviewersService = DispatchReviewersService(
    agents: agentRepository,
    messaging: messagingRepository,
    reviewSpaces: reviewSpaceRepository,
    messagingPort: messagingService,
    workspaces: workspaceRepository,
    filesystemPort: workspaceFilesystem,
    // Standing review instructions: the fact's topic doubles as its path
    // glob, so `lib/api/**` in the topic scopes the rule to that subtree.
    guidelineLookup: (workspaceId, [repoFullName]) async {
      final facts = await memoryFactRepository.getActiveByWorkspace(
        workspaceId,
      );
      // Guidelines are matched on the BARE domain name so a repo-scoped
      // `repo:owner-project/review-guidelines` counts, then filtered to this
      // repo's scope plus the workspace-wide ones. Another repo's standing
      // instruction must not govern this review.
      final reviewedRepo = repoFullName == null
          ? null
          : slugifyMemoryName(repoFullName);
      return [
        for (final f in facts)
          if (MemoryDomainScope.bareName(f.domain) ==
              SystemMemoryDomains.reviewGuidelines)
            if (MemoryDomainScope.repoSlugOf(f.domain) == null ||
                MemoryDomainScope.repoSlugOf(f.domain) == reviewedRepo)
              ReviewGuideline(
                instruction: f.content,
                pathGlob: f.topic.isEmpty ? null : f.topic,
                source: 'workspace memory',
              ),
      ];
    },
    changedFilesLookup:
        ({
          required String workspaceId,
          required String repoFullName,
          required int prNumber,
        }) async {
          final parts = repoFullName.split('/');
          if (parts.length < 2) {
            return const [];
          }
          final files = await serverGitHubClient.pr.listPullRequestFiles(
            parts.first,
            parts.sublist(1).join('/'),
            prNumber,
          );
          return [for (final f in files) f.filename];
        },
  );
  final reviewPublisherService = ReviewPublisherService(
    // Per acting user: the "publish to GitHub" button submits as the person who
    // pressed it, and the opt-in auto-publish at the end of an agent
    // orchestration passes no user and stays on the server's identity.
    githubPrClientFor: (actingUserId) => actingUserId == null
        ? serverGitHubClient.pr
        : GitHubApiClient(
            forgeDioFactoryForActor(actingUserId).of(ForgeHost.github),
          ).pr,
    messaging: messagingRepository,
    reviewSpaces: reviewSpaceRepository,
  );

  // The deterministic finalize shared by the `finalize_review` MCP tool, the
  // review pipeline's `prReview.finalize` step and the review hub — one verdict
  // pipeline, three entry points.
  final reviewFinalizer = ReviewFinalizer(
    messaging: messagingRepository,
    reviewSpaces: reviewSpaceRepository,
    reviewAxisResults: reviewAxisResultRepository,
    runSnapshots: reviewRunSnapshotRepository,
    // Cohorts give the walkthrough its files-by-concern table. Optional: a
    // review whose cohorts were never computed still finalizes, just without
    // the table.
    reviewCohorts: reviewCohortRepository,
    // Closes the loop on dismissals: a finding that echoes what this workspace
    // has already rejected is grouped away instead of repeated. Suppresses
    // nothing until the on-device embedding model has downloaded, which is the
    // safe direction — a missing model must not become a silent reviewer.
    suppressionMatcher: ReviewSuppressionMatcher(embedder: embeddingService),
  );

  // Turns the poller's raw "the head moved" into "your review is out of date",
  // but only when a finished review exists for the commit that was replaced.
  // Notifying on every push would be a ping per commit per open PR, most of
  // them never reviewed — the exact noise this whole surface is tuned against.
  StaleReviewWatcher(
    eventBus: eventBus,
    reviewSpaces: reviewSpaceRepository,
    runSnapshots: reviewRunSnapshotRepository,
  ).start();

  // The ONE path a review finding's status moves along — for a person
  // pressing a button, and for an agent calling the tool. It writes through
  // the typed payload, leaves a trace in the room, and turns a dismissal into
  // the suppression fact that stops the finding coming back.
  final reviewFindingStatusService = ReviewFindingStatusService(
    messaging: messagingRepository,
    reviewSpaces: reviewSpaceRepository,
    // Without this a status change reaches the bubble and nothing else: a pass
    // freezes its findings' statuses when it finalizes, and every human
    // decision necessarily comes after that.
    runSnapshots: reviewRunSnapshotRepository,
    memoryFacts: memoryFactRepository,
    resolveDomain: resolveDomainUseCase,
  );

  // Close the loop for the `prReview.finalize` body wired into the pipeline
  // executor above. Returns a plain map because the pipeline's state is JSON —
  // the counts are what the run's step detail shows the operator.
  finalizeReviewFn =
      ({
        required String workspaceId,
        required String spaceId,
        String? editorialNote,
        ReviewLevel level = ReviewLevel.balanced,
        String? headSha,
      }) async {
        // The summary belongs beside the report it closes out: the pipeline's
        // consolidate conversation, resolved by the title the seed gave it.
        // Without it the post would mint a standing conversation — the "main"
        // stream a pipeline-made review space deliberately never has. Null
        // when absent (a space the pipeline did not fill): the finalizer
        // falls back to the standing stream, the pre-existing behaviour.
        String? summaryConversationId;
        try {
          final conversations = await conversationRepository.listForSpace(
            workspaceId: workspaceId,
            spaceId: spaceId,
          );
          summaryConversationId = conversations
              .where(
                (c) =>
                    !c.isArchived &&
                    !c.isThread &&
                    c.title.trim() ==
                        BuiltInBodyKeys.reviewConsolidateConversationTitle,
              )
              .firstOrNull
              ?.id;
        } on Object {
          summaryConversationId = null;
        }
        final result = await reviewFinalizer.finalize(
          workspaceId: workspaceId,
          spaceId: spaceId,
          // The CEO's consolidated report is the editorial note on the summary,
          // not a second review: the findings themselves are already filed as
          // review nodes by the reviewers that found them.
          finalizerId: 'system',
          editorialNote: editorialNote,
          level: level,
          headSha: headSha,
          conversationId: summaryConversationId,
        );
        return {
          'verdict': result.verdict.overall.name,
          'confidence': result.verdict.confidence,
          'explanation': result.verdict.explanation,
          'consensus_ready': result.consensusReadyCount,
          'needs_adjudication': result.needsAdjudicationCount,
          'summary_message_id': result.summaryMessageId,
        };
      };

  // Register the agent-facing review MCP tools. The review-node lifecycle
  // (add / confirm / peer-review / submit-verdict / finalize), the reviewer
  // fan-out, the studio annotations (cohort summaries + graph-verified
  // diagrams) and the user-gated GitHub publish. `finalize_review` folds the
  // studio axis results into one authoritative verdict.
  mcpRegistry
    ..register(
      SetCohortSummaryTool(
        cohorts: reviewCohortRepository,
        resolvePrExternalId: resolvePrExternalId,
      ),
    )
    // `runLogs` is what files a finding into the reviewer's own stream instead
    // of the lead's consolidate stream (where the report and summary live).
    ..register(
      AddReviewNodeTool(
        repository: messagingRepository,
        runLogs: agentRunLogRepository,
      ),
    )
    ..register(ConfirmReviewNodeTool(repository: messagingRepository))
    // Previously constructed nowhere, so no agent could dismiss a finding
    // and the suppression loop it feeds was never primed.
    ..register(DismissReviewNodeTool(status: reviewFindingStatusService))
    // The sibling that makes `actionRate` real: the agent that made the fix is
    // the one that knows, and it knows at the moment it is true. Leaving this
    // to a human pressing "Fixed" afterwards is bookkeeping nobody does.
    ..register(ResolveReviewNodeTool(status: reviewFindingStatusService))
    ..register(SubmitReviewerVerdictTool(repository: messagingRepository))
    ..register(RequestPeerReviewTool(messaging: messagingRepository))
    ..register(DispatchReviewersTool(service: dispatchReviewersService))
    ..register(FinalizeReviewTool(finalizer: reviewFinalizer))
    ..register(PublishReviewToGithubTool(service: reviewPublisherService))
    ..register(
      AddReviewDiagramTool(
        cohorts: reviewCohortRepository,
        resolvePrExternalId: resolvePrExternalId,
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
    final prExternalId = pr.externalId.isNotEmpty
        ? pr.externalId
        : reviewPrNodeKey(owner, repo, prNumber);
    prExternalIdCache['$owner/$repo#$prNumber'] = prExternalId;

    // The PR's own code-graph partition, when its worktree has been
    // materialized. Absent (or not yet indexed) it falls back to the base
    // partition inside the service and the result is stamped as such.
    String? checkoutId;
    try {
      final isolated = await isolatedRepoRepository.forUnitRepo(
        workspaceId,
        'pr:${linked.fullName}#$prNumber',
        linked.id,
      );
      checkoutId = isolated?.id;
    } catch (e) {
      CcHostLog.warning('review_studio: PR partition lookup failed: $e');
    }

    final cohorts = await reviewCohortService.compute(
      workspaceId: workspaceId,
      repoId: linked.id,
      prExternalId: prExternalId,
      headSha: pr.headSha,
      changedFiles: changedFiles,
      patchByFile: {
        for (final f in files)
          if (f.patch.isNotEmpty) f.filename: f.patch,
      },
      checkoutId: checkoutId,
    );

    final axes = <Map<String, dynamic>>[];
    // Test-gap axis (token-free). Deterministic grounding for what was
    // otherwise a purely token-driven axis: an area whose changed symbols have
    // no inbound reference from any test file is a real, checkable gap.
    final testGap = ReviewAxisService.testGapAxisFromCohorts(cohorts);
    await reviewAxisResultRepository.upsert(workspaceId, prExternalId, testGap);
    axes.add(testGap.toJson());

    // Dependency diffs (token-free, offline). Reuses the same content reader
    // the contract axis uses — no extra forge surface.
    try {
      final dependencyDiffs = await reviewDependencyService.compute(
        workspaceId: workspaceId,
        prExternalId: prExternalId,
        baseSha: pr.baseSha,
        headSha: pr.headSha,
        changedFiles: changedFiles,
        readContent: ({required String path, required String ref}) =>
            serverGitHubClient.content.getFileContent(owner, repo, path, ref),
      );
      if (dependencyDiffs.isNotEmpty) {
        CcHostLog.info(
          'review_studio: ${dependencyDiffs.length} lockfile diff(s)',
        );
      }
    } catch (e) {
      CcHostLog.warning('review_studio: dependency diff failed: $e');
    }
    // API-contract axis (token-free).
    final contract = await reviewAxisService.runContractAxis(
      workspaceId: workspaceId,
      repoId: linked.id,
      prExternalId: prExternalId,
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
      await reviewAxisResultRepository.upsert(
        workspaceId,
        prExternalId,
        result,
      );
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
          prExternalId: prExternalId,
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
        await reviewAxisResultRepository.upsert(
          workspaceId,
          prExternalId,
          result,
        );
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
  // filesystem. The coordinator resolves the worktree from the space's agent.
  final conversationCheckpoint = ConversationCheckpointCoordinator(
    messaging: messagingRepository,
    agents: agentRepository,
  );

  // Governance (PRD 09) read surface served over RPC: the goal hierarchy, board
  // approvals and computed agent presence — built from the same DAOs the MCP
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
    // For worktree.commitAndPush / publishBranch: the token rides in the git
    // auth header env, never argv (invisible to `ps`). Resolved through the
    // ACTOR lane — a push a human clicks is authored on GitHub as that human
    // (their own credential first, the server chain only when they have not
    // connected GitHub). With no acting user this is exactly `tokenFor`.
    githubToken: ({actingUserId}) =>
        forgeCredentials.tokenForActor(ForgeHost.github, actingUserId),
  );

  // ── Take-over / hand-back (PRD 16 §8) ──
  // Pauses runs at turn boundaries (or stops CLI runs), writes the durable
  // marker (a restart comes back paused) and gates dispatch while it stands.
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
  // A space's named checker agent reviews every other agent's completed
  // main run, in-thread.
  final checkerListener = CheckerDispatchListener(
    eventBus: eventBus,
    workspaceDbs: workspaceDbs,
    runLogs: agentRunLogRepository,
    dispatchChecker:
        ({
          required String spaceId,
          required String agentId,
          required String prompt,
          required String workspaceId,
        }) async {
          await messagingService.dispatchAgent(
            spaceId: spaceId,
            agentId: agentId,
            prompt: prompt,
            workspaceId: workspaceId,
          );
        },
  )..start();

  // ── Enclosure notices to the driving agent ──
  // A take-over is enforced at the `RigService.act` chokepoint; without this
  // the agent only finds out through a refused click. Injects the notice on
  // the same steering lane take-over/hand-back uses.
  final rigEventListener = RigEventListener(
    eventBus: eventBus,
    rigs: rigRepository,
    runLogs: agentRunLogRepository,
    steerRun: agentDispatchService.steerRun,
  )..start();

  // Reclaims isolated worktrees when a unit ends (ticket done/cancelled,
  // conversation deleted, PR merged/closed) and auto-archives a merged PR's
  // workbench conversations. Long-lived; stopped on [shutdown].
  final worktreeGcListener = WorktreeGcListener(
    eventBus: eventBus,
    provisioner: conversationProvisioner,
    reviewSpaces: reviewSpaceRepository,
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

  // PR workbench: idempotently ensure a PR has a backing space (mode review),
  // linked via the review-space association and kick off provisioning of its
  // repo worktree at the PR head. Reused by chat/terminal/file surfaces so the
  // whole PR page hangs off one space. Returns {space_id, provisioning}.
  Future<Map<String, dynamic>> ensurePrSpace({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prExternalId,
    String? createdByUserId,
    String title = '',
  }) async {
    final existing = await reviewSpaceRepository
        .watchByPr(workspaceId, prExternalId)
        .first;
    if (existing != null &&
        await messagingRepository.spaceExists(workspaceId, existing.spaceId)) {
      final ch = await messagingRepository.getSpaceById(
        workspaceId,
        existing.spaceId,
      );
      var status = ch?.provisioningStatus ?? SpaceProvisioningStatus.ready;
      // A space whose last provision ended badly is re-provisioned, not
      // reported. `SpaceCreated` fires once, at creation, so a space that
      // reached `failed` (or was stopped) had nothing left that would ever try
      // again: every later "Ask AI" on that pull request read the stale row and
      // threw `PR worktree provisioning failed` for ever, with the only escape
      // being to delete the space by hand. `provision` is idempotent and is the
      // same call the space banner's Retry makes — the failure is usually a
      // leftover the attempt itself cleans up, so the retry is what heals it.
      if (status.isStopped) {
        // Flip the row FIRST. `provision` sets `provisioning` itself, but it
        // runs unawaited and `awaitPrProvisioning` starts polling the moment
        // this returns — losing that race would read the old `failed` and
        // throw before the retry had begun.
        await workspaceDbs
            .of(workspaceId)
            .messagingDao
            .updateSpaceProvisioningStatus(
              existing.spaceId,
              SpaceProvisioningStatus.provisioning.toDbValue(),
            );
        CcHostLog.info(
          'PR space ${existing.spaceId} was ${status.toDbValue()}; '
          're-provisioning for #$prNumber',
        );
        unawaited(
          spaceProvisioningService
              .provision(workspaceId: workspaceId, spaceId: existing.spaceId)
              .catchError((Object err, StackTrace st) {
                CcHostLog.error(
                  're-provisioning failed for ${existing.spaceId}: $err',
                  err,
                  st,
                );
              }),
        );
        status = SpaceProvisioningStatus.provisioning;
      }
      return {
        'space_id': existing.spaceId,
        'provisioning_status': status.toDbValue(),
      };
    }
    final name = reviewSpaceName(prNumber, title);
    // Through [SpaceFactory] — the same chokepoint every other creation path
    // uses — so the row and its `SpaceCreated` cannot come apart. The
    // association is written in `beforeAnnounce` rather than after the call
    // because it is what the PR-aware provisioner reads to resolve the head ref
    // it checks out; announcing first races it into the default branch.
    final space =
        await SpaceFactory(
          repository: messagingRepository,
          eventBus: eventBus,
        ).create(
          workspaceId,
          name,
          const <String>[],
          mode: Mode.review,
          createdByUserId: createdByUserId,
          // Workbench spaces stay out of the sidebar until someone actually
          // messages in them — opening a PR must not mint visible spaces.
          kind: SpaceKind.pr,
          beforeAnnounce: (space) => reviewSpaceRepository.create(
            spaceId: space.id,
            workspaceId: workspaceId,
            prExternalId: prExternalId,
            prNumber: prNumber,
            repoFullName: repoFullName,
          ),
        );
    return {
      'space_id': space.id,
      'provisioning_status': SpaceProvisioningStatus.provisioning.toDbValue(),
    };
  }

  // Blocks until the (event-driven, idempotent) provisioner has finished a PR
  // space's checkout at the PR head. An already-ready space returns on the
  // first poll. Throws rather than returning on failure/timeout: a caller that
  // continued would hand an agent — or an editor — an empty `repos/` and call
  // it a review.
  Future<void> awaitPrProvisioning({
    required String workspaceId,
    required String spaceId,
    required int prNumber,
  }) async {
    final deadline = DateTime.now().add(const Duration(seconds: 120));
    while (true) {
      final ch = await messagingRepository.getSpaceById(workspaceId, spaceId);
      final status = ch?.provisioningStatus ?? SpaceProvisioningStatus.ready;
      if (status == SpaceProvisioningStatus.ready) {
        return;
      }
      if (status == SpaceProvisioningStatus.failed) {
        throw StateError('PR worktree provisioning failed for #$prNumber');
      }
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('PR worktree provisioning timed out for #$prNumber');
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }

  // Close the loop for the `messaging.createSpace` body wired into the pipeline
  // executor above: the review pipeline and the PR workbench now resolve the
  // PR's space through one implementation, so they can never disagree about
  // which room (and therefore which checkout) a pull request has.
  //
  // It WAITS for the checkout before returning. Provisioning is event-driven
  // and asynchronous, so returning at row-creation time would release the three
  // reviewer steps against an empty `repos/` — they would read nothing, find
  // nothing, and report a clean review of a tree that had not been cloned yet.
  ensureReviewSpaceFn =
      ({
        required String workspaceId,
        required String repoFullName,
        required int prNumber,
        required String prExternalId,
        String title = '',
      }) async {
        final ensured = await ensurePrSpace(
          workspaceId: workspaceId,
          repoFullName: repoFullName,
          prNumber: prNumber,
          prExternalId: prExternalId,
          title: title,
        );
        final spaceId = ensured['space_id'] as String?;
        if (spaceId == null || spaceId.isEmpty) {
          return null;
        }
        await awaitPrProvisioning(
          workspaceId: workspaceId,
          spaceId: spaceId,
          prNumber: prNumber,
        );
        return spaceId;
      };

  /// Starts an AI review of a pull request: the `pr_review` PIPELINE, which is
  /// the only implementation.
  ///
  /// There used to be a second one — `ReviewHubService` — reached by the "Ask
  /// AI" button and the `start_ai_review` tool while the PR page's overflow
  /// action started the pipeline. Two orchestrators meant different rooms,
  /// different repo scoping and different output depending on which affordance
  /// you happened to press. Every entry point now lands here.
  ///
  /// The trigger payload is assembled SERVER-side because it needs the
  /// workspace-scoped repo id and the PR's forge id; a client assembling its
  /// own copy is how the two paths came to disagree in the first place.
  Future<Map<String, dynamic>> startPrReview({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    String? userId,
    String? level,
  }) async {
    // An explicit level overrides the workspace default for this run only. A
    // stored value that no longer parses falls back rather than failing the
    // request — the level governs how much of a review is reported, and
    // refusing to review because a setting is stale is the worse outcome.
    final resolvedLevel =
        ReviewLevel.fromWire(level) ??
        ReviewLevel.fromWire(
          await workspaceSettingsRepository.get(
            workspaceId,
            kReviewLevelSettingKey,
          ),
        ) ??
        ReviewLevel.defaultLevel;
    final linkedRepo = await resolveLinkedReviewRepo(workspaceId, owner, repo);
    final gh = await serverGitHubClient.pr.getPullRequest(
      owner,
      repo,
      prNumber,
    );
    if (gh == null) {
      throw const NotFoundException('Pull request not found');
    }
    final pr = pullRequestFromGitHub(gh, repoFullName: '$owner/$repo');
    final prExternalId = pr.externalId.isNotEmpty
        ? pr.externalId
        : await resolvePrExternalId(
            workspaceId: workspaceId,
            owner: owner,
            repo: repo,
            prNumber: prNumber,
          );
    final run = await pipeline.engine.start(
      'pr_review',
      workspaceId: workspaceId,
      triggerEventType: 'manual',
      triggerPayload: {
        'workspace_id': workspaceId,
        // The workspace-scoped repo id, so a node that scopes its checkout
        // resolves rather than silently falling back to every repo.
        'repo_id': linkedRepo.id,
        'repo_owner': owner,
        'repo_name': repo,
        'repo_full_name': '$owner/$repo',
        'pr_number': prNumber,
        'pr_external_id': prExternalId,
        'pr_title': pr.title,
        'author': pr.author?.login ?? '',
        // The commit this review is ABOUT. Recorded so a later push can be
        // detected as making the review stale — without it, a review has no
        // way to say which version of the code it read.
        'head_sha': pr.headSha,
        kReviewLevelStateKey: resolvedLevel.wireName,
      },
    );
    // A null run is the engine's duplicate guard: a review for this PR is
    // already in flight. Report that rather than a failure — it is the same
    // space either way.
    final spaceId = await ensureReviewSpaceFn(
      workspaceId: workspaceId,
      repoFullName: '$owner/$repo',
      prNumber: prNumber,
      prExternalId: prExternalId,
      title: pr.title,
    );
    return {
      'status': run == null ? 'already_running' : 'started',
      'space_id': spaceId ?? '',
      'pr_external_id': prExternalId,
      if (run != null) 'pipeline_run_id': run.id,
    };
  }

  // ── GitHub PR conversations (bot identity inbound lane) ──
  // PR comments that @mention the server's GitHub App bot, replies inside its
  // review threads, and PRs carrying the review label become turns in the PR's
  // review space here, and the answering agent's completed turn is posted back
  // on GitHub. GitHub's only push channel for an app is a webhook, which needs
  // an inbound URL this server deliberately does not require — so a polling
  // sweep is the transport, at the cost of a sweep interval of latency.
  //
  // Everything the bridge does on GitHub rides the SERVER's identity (app →
  // owner → environment): a PR comment is background work no human clicked,
  // which is the attribution rule the forge seams already follow. The in-space
  // question is attributed to the member whose GitHub login the commenter maps
  // to (membership is the gate), and the run executes on their behalf.
  final prConversationGateway = AppBackedGitHubPrConversationGateway(
    app: providerApps.githubApp,
    clientForOwner: githubClientForOwner,
    onWarning: CcHostLog.warning,
  );
  final githubLoginDirectory = GitHubLoginDirectory(
    members: membershipRepository,
    credentials: userCredentials,
  );
  final prConversationBridge = GitHubPrConversationBridge(
    gateway: prConversationGateway,
    loginDirectory: githubLoginDirectory,
    messaging: messagingService,
    messagingRepository: messagingRepository,
    workspaceDbs: workspaceDbs,
    startReview: startPrReview,
    // The bridge hands the PR number; the space seam wants the PR's node id
    // (the review-space association key), which `startPrReview` resolves the
    // same way for its own path — reuse the same resolver so a
    // mention-started question and a UI-opened workbench can never disagree
    // about which room a PR lives in.
    ensureSpace:
        ({
          required workspaceId,
          required repoFullName,
          required prNumber,
          required title,
        }) async {
          final parts = repoFullName.split('/');
          if (parts.length != 2) {
            return null;
          }
          final prExternalId = await resolvePrExternalId(
            workspaceId: workspaceId,
            owner: parts[0],
            repo: parts[1],
            prNumber: prNumber,
          );
          return ensureReviewSpaceFn(
            workspaceId: workspaceId,
            repoFullName: repoFullName,
            prNumber: prNumber,
            prExternalId: prExternalId,
            title: title,
          );
        },
    // A question on a PR with no review running lands in an empty space; the
    // seeded coordinator is who wakes up for it.
    defaultAnswerer: (workspaceId) async {
      final agents = await agentRepository.watchByWorkspace(workspaceId).first;
      for (final agent in agents) {
        if (agent.role == AgentRole.ceo) {
          return agent.id;
        }
      }
      return null;
    },
    eventBus: eventBus,
    onWarning: CcHostLog.warning,
  )..start();
  final prConversationPoller = PrConversationPollingService(
    gateway: prConversationGateway,
    bridge: prConversationBridge,
    workspacesForRepo: repoWorkspaceIndex.workspacesFor,
    // CROSS-WORKSPACE BY DESIGN: the interactive-follow-up set is every PR
    // that already has a review space, in whatever workspace owns it — the
    // poller must watch those threads wherever they live. Per-workspace scoped
    // reads over the workspace registry, the same shape RepoWorkspaceIndex
    // uses.
    associatedPullRequests: () async {
      final out = <AssociatedPullRequest>[];
      final workspaces = await workspaceRepository.watchAll().first;
      for (final workspace in workspaces) {
        if (workspace.deletedAt != null) {
          continue;
        }
        final associations = await reviewSpaceRepository
            .watchByWorkspace(workspace.id)
            .first;
        for (final association in associations) {
          out.add(
            AssociatedPullRequest(
              workspaceId: workspace.id,
              repoFullName: association.repoFullName,
              prNumber: association.prNumber,
            ),
          );
        }
      }
      return out;
    },
    // The dedupe store is cross-workspace (the sweep routes by repo), so it
    // lives in global.db's server_meta — the same place the viewer-activity
    // poller keeps its state.
    loadDedupeState: () =>
        globalDb.workspaceRouteDao.meta('githubPrConversationDedupe'),
    saveDedupeState: (state) =>
        globalDb.workspaceRouteDao.setMeta('githubPrConversationDedupe', state),
  );
  // demo: polling PR conversations is GitHub egress, and there is no forge
  // credential to poll with.
  if (demo == null) {
    prConversationPoller.start();
  }

  // Merged reverse-dependency subgraph for a whole cohort (the Review Hub's
  // deep-dive impact view): the dominant symbol of each of the cohort's files,
  // each symbol's impact radius, merged and deduped with per-node minimal hop
  // depth. Same dominant-symbol selection as the cohort computation.
  Future<Map<String, dynamic>> reviewCohortImpactFn({
    required String workspaceId,
    required String owner,
    required String repo,
    required int prNumber,
    required String cohortKey,
    required String userId,
    int depth = 2,
  }) async {
    final empty = {'indexed': false, 'nodes': const [], 'edges': const []};
    final linked = await resolveLinkedReviewRepo(workspaceId, owner, repo);
    final prExternalId = await resolvePrExternalId(
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      prNumber: prNumber,
    );
    final cohorts = await reviewCohortRepository.forPr(
      workspaceId,
      prExternalId,
    );
    ReviewCohort? cohort;
    for (final c in cohorts) {
      if (c.cohortKey == cohortKey) {
        cohort = c;
        break;
      }
    }
    if (cohort == null || cohort.filePaths.isEmpty) {
      return empty;
    }
    final symbols = await workspaceDbs
        .of(workspaceId)
        .codeGraphDao
        .getSymbolsByFiles(workspaceId, linked.id, cohort.filePaths);
    if (symbols.isEmpty) {
      return empty;
    }
    final files = cohort.filePaths.toSet();
    final dominantByFile = <String, CodeSymbolsTableData>{};
    for (final s in symbols) {
      if (!files.contains(s.filePath)) {
        continue;
      }
      final current = dominantByFile[s.filePath];
      if (current == null ||
          (s.endLine - s.startLine) > (current.endLine - current.startLine)) {
        dominantByFile[s.filePath] = s;
      }
    }
    final nodes = <String, Map<String, dynamic>>{};
    final edges = <String, Map<String, dynamic>>{};
    for (final dominant in dominantByFile.values) {
      final impact = await workspaceDbs
          .of(workspaceId)
          .codeGraphDao
          .getImpactRadius(workspaceId, dominant.id, depth: depth);
      for (final n in impact.nodes) {
        final hop = impact.depthById[n.id] ?? 0;
        final existing = nodes[n.id];
        if (existing == null) {
          nodes[n.id] = {
            'id': n.id,
            'name': n.name,
            'qualifiedName': n.qualifiedName,
            'filePath': n.filePath,
            'kind': n.kind,
            'depth': hop,
          };
        } else if (hop < (existing['depth'] as num)) {
          existing['depth'] = hop;
        }
      }
      for (final e in impact.edges) {
        edges['${e.sourceSymbolId}->${e.targetSymbolId}'] = {
          'source': e.sourceSymbolId,
          'target': e.targetSymbolId,
          'kind': e.kind,
        };
      }
    }
    return {
      'indexed': true,
      'cohort_key': cohortKey,
      'roots': [
        for (final r in dominantByFile.values)
          {
            'id': r.id,
            'name': r.name,
            'qualifiedName': r.qualifiedName,
            'filePath': r.filePath,
          },
      ],
      'nodes': nodes.values.toList(),
      'edges': edges.values.toList(),
    };
  }

  // The agent-facing entry to the SAME flow the UI's "Ask AI" action uses.
  mcpRegistry.register(
    StartAiReviewTool(
      start:
          ({
            required String workspaceId,
            required String owner,
            required String repo,
            required int prNumber,
            String? requestedByUserId,
            String? level,
          }) => startPrReview(
            workspaceId: workspaceId,
            owner: owner,
            repo: repo,
            prNumber: prNumber,
            userId: requestedByUserId,
            level: level,
          ),
    ),
  );

  // Resolves (creating + provisioning if needed) the on-disk PR-head worktree
  // for a pull request, reusing the SAME space worktree the in-app workbench
  // edits — there is no separate `pr_worktrees/` checkout anymore. Ensures the
  // PR space, waits for the background provisioner to check the repo out at
  // the PR head, then returns that worktree's path. Used by the "open in editor"
  // ops and the review-studio visual axis.
  Future<String> ensurePrWorktreePath({
    required String workspaceId,
    required String repoFullName,
    required int prNumber,
    required String prExternalId,
    String title = '',
    String? repoId,
  }) async {
    final res = await ensurePrSpace(
      workspaceId: workspaceId,
      repoFullName: repoFullName,
      prNumber: prNumber,
      prExternalId: prExternalId,
      title: title,
    );
    final spaceId = res['space_id'] as String;

    // Wait for the (event-driven, idempotent) provisioner to finish the PR-head
    // checkout. An already-ready space returns on the first poll.
    await awaitPrProvisioning(
      workspaceId: workspaceId,
      spaceId: spaceId,
      prNumber: prNumber,
    );

    final rows = repoId != null && repoId.isNotEmpty
        ? [
            ?await isolatedRepoRepository.forUnitRepo(
              workspaceId,
              spaceId,
              repoId,
            ),
          ]
        : await isolatedRepoRepository.forSpace(workspaceId, spaceId);
    if (rows.isEmpty) {
      throw StateError('PR worktree not available for #$prNumber');
    }
    return rows.first.path;
  }

  // Re-syncs a PR space's worktree to the latest PR head (commits pushed after
  // it was provisioned). Resolves the PR number/branch from the space's review
  // association, then delegates the git work to the IDE data service (which
  // no-ops on a dirty tree).
  Future<Map<String, dynamic>> syncPrWorktree({
    required String workspaceId,
    required String spaceId,
    required String repoId,
  }) async {
    final assoc = await reviewSpaceRepository
        .watchBySpace(workspaceId, spaceId)
        .first;
    if (assoc == null) {
      return {'ok': false, 'error': 'not a PR channel'};
    }
    final res = await repoIdeData.syncToPrHead(
      workspaceId,
      spaceId,
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
    spaceLinks: DaoChatSpaceLinkRepository(workspaceDbs),
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

  // On-demand backup: a timestamped snapshot DIRECTORY under
  // `<dataDir>/backups/` holding global.db, one file per workspace and a
  // manifest. Backs the `server.backupNow` / `server.listBackups` ops, the
  // `workspace.export` / `workspace.import` pair, AND the `/backup/*` HTTP
  // routes below — which is why it is hoisted here rather than built inline:
  // the RPC lane names paths on the server and the HTTP lane carries the bytes
  // to a client, and both have to be the same service or they describe
  // different files.
  // demo: no backup/export of a shared public database.
  final AppDatabaseBackupService? databaseBackupService = demo != null
      ? null
      : AppDatabaseBackupService(
          global: globalDb,
          workspaces: workspaceDbs,
          backupsDir: '${config.dataDir}/backups',
          onWarn: CcHostLog.warning,
        );

  // Where the `/backup/*` routes put transient bytes: an upload on its way in
  // and a snapshot archive on its way out. Both are deleted by the route that
  // made them, on every path out — this directory is a workbench, not a store.
  final backupTransferStagingDir = '${config.dataDir}/backups/transfer';

  final catalog = buildRemoteRpcCatalog(
    manualPairingEnabled: ssoSettings.isPairingEnabled,
    // The demo's one outbound marketing read: the project's own star count,
    // cached server-side inside the wiring. Null on a production server, which
    // is what keeps `demo.repoStars` structurally absent there.
    demoRepoStars: demo?.repoStats.current,
    // The same file the signed `/workspace/logo` route serves, handed back
    // over the RPC channel for clients that have no HTTP route here at all —
    // which is every client whose only path is the broker relay. The op is
    // workspace-scoped, so membership is checked by the dispatcher before
    // this runs; `getById` is id-scoped, so a foreign workspace resolves to
    // nothing rather than to another tenant's mark.
    workspaceLogoBytes: ({required workspaceId}) async {
      final ws = await workspaceRepository.getById(workspaceId);
      final path = ws?.logoPath;
      if (path == null || path.isEmpty) {
        return null;
      }
      final file = File(path);
      return file.existsSync() ? await file.readAsBytes() : null;
    },
    ensurePrSpace: ensurePrSpace,
    // demo: no worktrees to provision.
    ensurePrWorktree: demo != null
        ? null
        : ensurePrWorktreePath,
    // demo: no worktrees to sync.
    syncPrWorktree: demo != null
        ? null
        : syncPrWorktree,
    extraOps: [
      ...fleetOps,
      ...buildContextOps(
        inspection: ContextInspectionService(
          agentRepository: agentRepository,
          messagingRepository: messagingRepository,
          modeResolver: conversationModeResolver,
          filesystem: workspaceFilesystem,
          mcpRegistry: mcpRegistry,
          fileSearch: CcNativesFileSearchPort(fileSearch: ideFileSearch),
          memoryContextUseCase: memoryContextUseCase,
          sandboxManager: useNativeSandbox ? sandboxManager : null,
          confirmationPort: confirmationPort,
          protectedPathsResolver: protectedPathsResolver,
          // Must match dispatch's setting or the explorer reports a surface no
          // run gets — the one failure this service exists to prevent.
          toolDeferralEnabled: config.toolDeferralEnabled,
        ),
      ),
      ...buildWeatherOps(weatherService),
      ...buildFontsOps(fontCatalog),
      ...buildSoundscapeOps(soundscapeHub),
      ...buildChatOps(connector: chatConnector, users: userRepository),
      ...buildSsoOps(settings: ssoSettings, isServerOwner: isServerOwner),
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
    // demo: no per-user credential storage.
    userCredentials: demo != null
        ? null
        : userCredentials,
    ticketRepository: ticketRepository,
    projectRepository: projectRepository,
    // Read-only sync-health surface (§188): the client watches these to show
    // per-vendor last-sync + error streak. Cheap stateless DAO wrappers over
    // the same ticketSyncDao the sync engine writes to.
    syncConfigRepository: DaoTicketSyncConfigRepository(workspaceDbs),
    syncLogRepository: DaoTicketSyncLogRepository(workspaceDbs),
    // Manual "sync now" trigger (§188). Deferred: the engine is constructed
    // later in bootstrap; this closure is only invoked when an RPC arrives.
    // demo: no vendor sync — that is outbound network.
    ticketSyncNow: demo != null
        ? null
        : ({required String workspaceId, String? vendor}) =>
        ticketSyncEngineRef!.pullNow(workspaceId: workspaceId, vendor: vendor),
    ticketWorkflow: ticketWorkflow,
    messagingRepository: messagingRepository,
    // The other half of `ask_user`: `messaging.updateMessage` hands the
    // client's persisted answer to this service, which completes the run
    // blocked on it. Same instance the dispatch adapter asks through.
    agentQuestions: agentQuestions,
    // Backs `blob.put` — a human pasting a screenshot into the composer. Same
    // store the agent's own screenshots land in, so both directions of the
    // image lane share one directory and one lifecycle.
    blobStore: blobStore,
    // Space repo-selection teardown (`messaging.setSpaceRepos`): the same
    // provisioner that materializes a space's worktrees destroys the ones a
    // deselection orphans.
    provisioner: conversationProvisioner,
    // Live turn relay: the same registry the dispatch stack publishes into,
    // so `messaging.watchSpaceTurns` streams tokens as they arrive — and,
    // keyed by run id, so `agent_run_log.watchRunTranscript` streams a
    // subagent's own activity.
    streamRegistry: streamRegistry,
    // Durable per-run activity timelines, for replaying a finished run.
    runTranscriptRepository: runTranscriptRepository,
    // Server-computed messaging aggregates (SQL projection on the concrete
    // DAO repository): per-space sidebar signals and conversation size.
    watchSpaceActivity: messagingRepository.watchSpaceActivity,
    watchConversationTokens: messagingRepository.watchConversationTokens,
    // Conversations (parallel streams / "parentheses" inside a space).
    conversationRepository: conversationRepository,
    watchConversationsForSpace: (workspaceId, spaceId) => conversationRepository
        .watchForSpace(workspaceId: workspaceId, spaceId: spaceId),
    // See [databaseBackupService] above. fullClient-only ops; absent entirely
    // on a demo, where the service itself is null.
    databaseBackup: databaseBackupService,
    workspaceRepository: workspaceRepository,
    newsfeedRepository: newsfeedRepository,
    agentRepository: agentRepository,
    agentRunLogRepository: agentRunLogRepository,
    repoRepository: repoRepository,
    repoScriptRepository: repoScriptRepository,
    // demo: no repo script execution.
    repoScripts: demo != null
        ? null
        : repoScriptService,
    spaceReadRepository: spaceReadRepository,
    memoryDomainRepository: memoryDomainRepository,
    memoryAccessGrantRepository: memoryAccessGrantRepository,
    agentWorkingMemoryRepository: agentWorkingMemoryRepository,
    memoryFactRepository: memoryFactRepository,
    memoryPolicyRepository: memoryPolicyRepository,
    providerPolicyRepository: providerPolicyRepository,
    // PRD 24 §4: the same policy store the ActionGuard enforces with, exposed
    // for the agent-permissions matrix/probe RPC ops.
    actionPolicyRepository: actionPolicyRepository,
    // Stage 2 governance: custom roles, the audit spine's read/verify/export
    // surface, and the install-wide managed clamp.
    workspaceRoleRepository: workspaceRoleRepository,
    guardDecisionRepository: guardDecisionRepository,
    managedPolicy: managedPolicy,
    sandboxExecGrantRepository: sandboxExecGrantRepository,
    // Skill sources (the GitHub catalogs) + their browse/install/uninstall
    // ops; the installed-skills scan/status/save ops + quarantine detach
    // enforcement.
    skillBundles: skillBundles,
    skillSources: skillSourceStore,
    skillSourceCatalog: skillSourceCatalog,
    skillAnalysis: skillAnalysis,
    // Backs `skills.repoSkills`: the same gate the dispatch-time projector
    // uses, so the composer's palette and a slash command agree on what a
    // repo's skills are.
    skillScanner: skillScanner,
    // Built-in harness provider/credential brain (PRD 13): same store the
    // dispatch path reads, plus the OAuth broker, so a key/login saved over RPC
    // is immediately usable by a dispatched agent.
    harnessCredentialStore: harnessCreds,
    harnessOAuthBroker: harnessOAuthBroker,
    harnessModelOverrides: harnessModelOverrides,
    reviewSpaceRepository: reviewSpaceRepository,
    isolatedRepoRepository: isolatedRepoRepository,
    voiceProfileRepository: voiceProfileRepository,
    // PR "open in editor" resolves the space worktree (`ide.ensureWorktree`)
    // via `ensurePrWorktree` above; no editorLauncher is wired (the headless host
    // can't launch a GUI editor — the client launches the returned path locally),
    // so only the worktree-path op lights up, not `ide.openPrInEditor`.
    // Messaging IDE repo data ops: the Explorer file tree (`repos.searchFiles`),
    // the Source Control per-repo diff (`repos.changes`), the file viewer
    // (`repos.readFile`) and the aggregate conversation diff
    // (`conversation.changes`). All run on the SERVER over the checkouts +
    // worktrees it owns, so desktop and web get the same IDE.
    repoChanges: repoIdeData.repoChanges,
    repoChangesGrouped: repoIdeData.repoChangesGrouped,
    // demo: no git index mutation.
    repoStage: demo != null
        ? null
        : repoIdeData.stageFiles,
    // demo: no git index mutation.
    repoUnstage: demo != null
        ? null
        : repoIdeData.unstageFiles,
    repoFileContent: repoIdeData.readFile,
    repoFileSearch: repoIdeData.searchFiles,
    repoDirectoryListing: repoIdeData.listDirectory,
    repoContentSearch: repoIdeData.searchContentWithOptions,
    worktreeContentSearch: repoIdeData.searchWorktreeContentWithOptions,
    worktreeFileSearch: repoIdeData.searchFilesInWorktree,
    // demo: no git diffs without a checkout.
    conversationChanges: demo != null
        ? null
        : repoIdeData.conversationChanges,
    // IDE worktree mutate ops: the "untitled" draft save (⌘S) writes into the
    // conversation's CoW worktree and the Source Control "Revert" action
    // restores working-tree files to HEAD. Both run SERVER-SIDE over the
    // worktrees the host owns; absent on a host that owns no worktrees.
    // demo: no worktree writes; the demo has no repos at all.
    worktreeWriteFile: demo != null
        ? null
        : 
        ({
          required workspaceId,
          required spaceId,
          required repoId,
          required path,
          required content,
        }) async {
          final r = await repoIdeData.writeFile(
            workspaceId,
            spaceId,
            repoId,
            path,
            content,
          );
          if (r == null) {
            return null;
          }
          return {'repoId': r.repoId, 'path': r.path};
        },
    // demo: no worktree writes.
    worktreeRevertFiles: demo != null
        ? null
        : 
        ({
          required workspaceId,
          required spaceId,
          required repoId,
          required paths,
        }) async {
          final r = await repoIdeData.revertFiles(
            workspaceId,
            spaceId,
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
    // demo: nothing to read: no repos row is ever created.
    worktreeReadFile: demo != null
        ? null
        : 
        ({
          required workspaceId,
          required spaceId,
          required repoId,
          required path,
        }) async {
          final r = await repoIdeData.readFileFromWorktree(
            workspaceId,
            spaceId,
            repoId,
            path,
          );
          if (r == null) {
            return null;
          }
          return {'content': r.content, 'binary': r.binary};
        },
    // demo: never commit or push from a public endpoint.
    worktreeCommitAndPush: demo != null
        ? null
        : repoIdeData.commitAndPush,
    // demo: never publish a branch from a public endpoint.
    worktreePublishBranch: demo != null
        ? null
        : repoIdeData.publishBranch,
    // Remote agent-action approvals: the same registry the dispatch/MCP paths
    // publish to, exposed to clients over `confirmation.watchPending` +
    // `confirmation.respond` so a desktop/web/phone user can approve or deny.
    pendingConfirmationRegistry: pendingConfirmationRegistry,
    credentialBlockRegistry: credentialGateRegistry,
    meetingRepository: meetingRepository,
    // Live meeting recording over RPC (null when no ASR model is installed →
    // the recording ops stay absent and the web recorder reports unavailable).
    // demo: no audio capture.
    meetingRecording: demo != null
        ? null
        : meetingRecording,
    // Composer voice dictation over RPC (same null-when-no-ASR-model contract →
    // the `dictation.*` ops + `dictation.watchPartials` stay absent).
    // demo: no dictation.
    dictationService: demo != null
        ? null
        : dictationService,
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
    // demo: no tunnels, no mDNS.
    networkRuntime: demo != null
        ? null
        : () => networkRuntimeHolder.value,
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
    // PR lifecycle (workspace-scoped reads + writes). Publishing resolves a
    // client for the CALLER, so the pull request is opened in their name.
    prLifecycleRepositoryFor: prLifecycleRepositoryForActor,
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
    // demo: no host filesystem browsing.
    directoryBrowser: demo != null
        ? null
        : FilesystemDirectoryBrowser(
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
    // demo: no OAuth round trips.
    providerOAuth: demo != null
        ? null
        : providerOAuth,
    // demo: no app identity to configure.
    providerApps: demo != null
        ? null
        : providerApps,
    // demo: no forge credentials exist to read or write.
    forgeCredentials: demo != null
        ? null
        : forgeCredentials,
    buildForgePrClient: (repo, actingUserId) =>
        forgePrClientForRepo(repo, actingUserId: actingUserId),
    // Sandbox detection: report THIS host's OS-native sandbox capabilities so a
    // connected web/thin client's Settings → Sandboxing reflects the server.
    // demo: no sandbox probing; nothing is sandboxed because nothing runs.
    sandboxDetector: demo != null
        ? null
        : sandboxDetector,
    // Process detection: the server scans ITS OS process table for agent
    // processes (the dashboard's cross-workspace "active processes" matrix) and
    // can stop one by pid. Both ops are fullClient-only + cross-workspace.
    // demo: no host process enumeration.
    processDetection: demo != null
        ? null
        : ProcessDetectionService(
      runLogRepo: agentRunLogRepository,
      agentRepo: agentRepository,
      workspaceRepo: workspaceRepository,
    ),
    // Run-viewer reads: the NDJSON logs live under the server's data dir, which
    // also bounds what the op may open.
    runLogReader: RunLogReader(allowedRoot: config.dataDir),
    eventBus: eventBus,
    // PR review over RPC: when the server has a forge credential (see
    // [serverForgeRegistry] above) the authenticated detail/diff/comment
    // surface is LIVE — a thin client reads `pr_review.watch*`/mutations
    // against this host. Token-less, it stays null and those ops surface an
    // empty repository.
    forgeProviderRegistryFor: forgeRegistryForActor,
    // The PR-list screen's data: fetched server-side on the server's GitHub
    // client across the bound workspace's linked repos. Null (→
    // `authenticated:false`) when the
    // server holds no token, so the client shows "connect GitHub on the server".
    // Shares the poller's fetch adapter so the one-shot op and the live
    // `pr.watchOpenForWorkspace` snapshot are built by the same code path.
    // The op serves whatever GitHub resolved (it persists nothing, so a
    // partial answer cannot overwrite the poller's snapshot — see
    // [OpenPrFetchResult]).
    fetchOpenPrList: (repos) async =>
        (await openPrFetchAdapter.fetchGroups(repos)).groups,
    // The open-PR poller: `pr.watchOpenForWorkspace` + `pr.refreshOpenForWorkspace`.
    // demo: a poller that never sweeps, so `pr.watchOpenForWorkspace` follows
    // the SEEDED snapshot instead of short-circuiting to a signed-out empty
    // list (a null poller never reads the cache at all).
    openPrPoller: demo?.openPrPoller ?? openPrPoller,
    // The thin client holds no token, so its `login`/avatar resolve here — for
    // the CALLER, on the caller's own credential. Both share one per-user
    // identity cache so `GET /user` and `GET /user/teams` are each fetched once
    // per person, not once per call.
    //
    // Unconditional: both answer null for a user who has not connected GitHub,
    // and the cache re-probes after its cooldown, so a sign-in lands without a
    // restart. Deciding at boot instead pinned "not connected" for the life of
    // the process.
    fetchCurrentGitHubUser: (actingUserId) async =>
        (await githubIdentityForActor(actingUserId).user())?.toJson(),
    fetchViewerGitHubTeams: (actingUserId) async =>
        await githubIdentityForActor(actingUserId).teams() ?? const {},
    // The dashboard's "review-requested:<viewer>" search.
    //
    // Both this and [fetchReviewedBy] used to be wired to null at boot unless
    // `ghUsername` was non-empty — and `ghUsername` resolves with NO calling
    // user, so it takes the app-identity lane, whose installation token gets a
    // permanent 403 from `GET /user` and therefore resolves to ''. The result
    // was that on any install with a GitHub App configured, BOTH fetchers were
    // null for the life of the process: the dashboard's priority-review panel
    // and the inbox's "Waiting for author" section were wired to a handler
    // that returns an empty list unconditionally, and neither search ever ran
    // once. Silent, because "no results" and "never asked" render identically.
    //
    // Unconditional now, and resolved PER CALL for the ACTING USER: an empty
    // login yields an empty result for that call and the next one re-probes, so
    // a sign-in lands without a restart. Same reasoning as
    // `fetchCurrentGitHubUser` above.
    fetchReviewRequested: (repos, actingUserId) async {
      final login =
          (await githubIdentityForActor(actingUserId).user())?.login ?? '';
      if (login.isEmpty) {
        return const <({Repo repo, PullRequest pr})>[];
      }
      final nodes = await githubClientForActor(actingUserId).graphql
          .searchReviewRequestedPullRequests(
            reviewerLogin: login,
            repos: [
              for (final r in repos) (owner: r.remoteOwner, name: r.remoteName),
            ],
          );
      final byFullName = {for (final r in repos) r.fullName.toLowerCase(): r};
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
    // The PR-list "reviewed by me" key set — what drives the inbox's "Waiting
    // for author" section.
    fetchReviewedBy: (repos, actingUserId) async {
      final login =
          (await githubIdentityForActor(actingUserId).user())?.login ?? '';
      if (login.isEmpty) {
        return const <String>{};
      }
      final pairs = await githubClientForActor(actingUserId).graphql
          .searchReviewedByPullRequests(
            reviewerLogin: login,
            repos: [
              for (final r in repos) (owner: r.remoteOwner, name: r.remoteName),
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
              for (final r in repos) (owner: r.remoteOwner, name: r.remoteName),
            ],
          ),
    // The caller's merged PR history, asked of each repo's own forge under
    // the CALLER's per-forge viewer identity. Fails soft per repo so one
    // inaccessible repo — or one unconnected forge — never sinks the rest.
    fetchMergedHistory: mergedHistory.mergedByViewer,
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
    // demo: every GitHub read is egress.
    githubRead: demo != null
        ? null
        : ghToken.isEmpty
        ? null
        : (
            repoBranches: (owner, repo) async {
              final branches = await serverGitHubClient.graphql
                  .listBranchesWithActivity(owner, repo);
              final me = ghUsername.toLowerCase();
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
            // The CALLER's permission, on the CALLER's client. The answer is
            // about one specific human — gating their merge/edit affordances
            // on the boot-time server login reported the wrong person's
            // access to every member.
            repoPermission: (owner, repo, actingUserId) async {
              if (actingUserId.isEmpty) {
                return 'none';
              }
              try {
                final login =
                    (await githubIdentityForActor(
                      actingUserId,
                    ).user())?.login ??
                    '';
                if (login.isEmpty) {
                  return 'none';
                }
                return await githubClientForActor(
                  actingUserId,
                ).content.getCollaboratorPermission(owner, repo, login);
              } on Object {
                return 'none';
              }
            },
            // On the ACTING USER's client, like `github.currentUser` above.
            // The profile query asks for `organizations.nodes.teams`, which no
            // GitHub App installation token may read — GitHub answers FORBIDDEN
            // "Resource not accessible by integration" per org — and
            // `serverGitHubClient` takes the no-caller lane, which resolves the
            // app identity first. So on any install with a GitHub App
            // configured, every hover card and profile page failed. A
            // user-to-server token reads the whole profile. A member who has
            // not connected GitHub still falls back to the app identity and
            // gets the tolerated partial answer (profile without orgs).
            userProfile: (login, actingUserId) async =>
                (await githubClientForActor(
                  actingUserId,
                ).graphql.getUserProfile(login: login))?.toWire(),
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
        }) async {
          final all = await SubscriptionUsageService(dio: createDio()).fetchAll(
            zaiApiKey: zaiApiKey,
            zaiBaseUrl: zaiBaseUrl,
            kimiAccessToken: kimiAccessToken,
            kimiBaseUrl: kimiBaseUrl,
            kimiDeviceId: kimiDeviceId,
          );
          // Claude's quota is per ACCOUNT, and with several attached the one
          // aggregate reading answers the wrong question — the operator wants
          // to know which login still has room, not what the default one has
          // left. So the single Claude entry expands into one per managed
          // account; every other provider is untouched.
          final accounts = await claudeAccountStore.listWithStatus();
          if (accounts.length < 2) {
            return [for (final u in all) u.toJson()];
          }
          final perAccount = await Future.wait(
            accounts.map((a) async {
              // An account the host already knows cannot authenticate — signed
              // out, or holding an access token past its own expiry — is
              // answered from what we know instead of asked. The endpoint takes
              // the bearer as-is and refreshes nothing, so it can only reply
              // 401; this runs on a ten-minute timer, so probing anyway spends
              // a request per account per cycle to re-learn a fact the
              // credential states on disk. (An expired token whose refresh
              // token is still good remains a perfectly usable RUN account —
              // the CLI renews it on start. It just cannot answer this.)
              //
              // The two cases are reported SEPARATELY, because they ask
              // different things of the operator. A signed-out account (or one
              // a run already watched 401) needs a human; a merely-lapsed token
              // with a refresh token beside it renews itself. Both used to
              // arrive as `unconfigured`, which the flyout renders as "no usage
              // reported for this account" — so an account that had silently
              // fallen out of the rotation looked exactly like a quiet one.
              SubscriptionUsage stateOnly(
                SubscriptionStatus status,
                String reason,
              ) => SubscriptionUsage(
                providerId: 'claude',
                displayName: 'Claude',
                status: status,
                error: reason,
                fetchedAt: DateTime.now().toUtc(),
                accountId: a.id,
                accountLabel: _claudeAccountLabel(a),
              );

              if (!a.loggedIn) {
                return stateOnly(
                  SubscriptionStatus.signInRequired,
                  a.statusError ??
                      'This account cannot authenticate. Sign in again.',
                );
              }
              if (a.isCredentialExpired()) {
                return stateOnly(
                  SubscriptionStatus.signInExpired,
                  'The sign-in expired. Usage is readable again after the '
                  'next run renews it, or after signing in.',
                );
              }
              final usage = await claudeUsageCache.get(
                claudeAccountStore.configDirFor(a.id),
              );
              return usage.copyWith(
                accountId: a.id,
                accountLabel: _claudeAccountLabel(a),
              );
            }),
          );
          return [
            for (final u in all)
              if (u.providerId != 'claude') u.toJson(),
            for (final u in perAccount) u.toJson(),
          ];
        },
    // The Claude Code logins this host manages, and the per-account quota the
    // composer picker shows so "which account should this run use?" can be
    // answered on remaining headroom rather than from memory.
    claudeAccounts: claudeAccountStore,
    fetchClaudeAccountUsage: (configDir) async =>
        (await claudeUsageCache.get(configDir)).toJson(),
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
    // demo: no MCP server control, so /mcp and /sse are never mounted.
    mcpControl: demo != null
        ? null
        : mcpControl,
    // The `mcp.client.*` ops drive the external-MCP client subsystem (list
    // discovered servers, steer the approval posture, reconnect).
    // demo: no external MCP clients.
    mcpClientControl: demo != null
        ? null
        : mcpClientControl,
    // The headless server owns its filesystem, so it serves the `fs.*` ops over
    // the workspace on-disk layout rooted at its data dir.
    // demo: removes every fs.* op, writeString included.
    workspaceFilesystem: demo != null
        ? null
        : workspaceFilesystem,
    // Agent dispatch + space lifecycle: the headless server now runs agents
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
          required spaceId,
          required messageId,
          required inclusive,
        }) async {
          final outcome = await conversationCheckpoint.revertTo(
            workspaceId: workspaceId,
            spaceId: spaceId,
            messageId: messageId,
            inclusive: inclusive,
          );
          return (
            affectedMessageIds: outcome.affectedMessageIds,
            filesystemRestored: outcome.filesystemRestored,
          );
        },
    conversationUnrevert: ({required workspaceId, required spaceId}) async =>
        (await conversationCheckpoint.unrevert(
          workspaceId: workspaceId,
          spaceId: spaceId,
        )).affectedMessageIds,
    retrySpaceProvisioning: spaceProvisioningService.provision,
    cancelSpaceProvisioning: spaceProvisioningService.cancel,
    // Review-fix agent: dispatch a sandboxed/relay agent server-side, as a
    // real turn in the space's chat. Goes through the messaging path (the only
    // place the `agent_turn` row and the stream processor that fills it live)
    // — see [buildReviewFixDispatch] for why dispatching underneath it left
    // an empty conversation spinning forever.
    reviewDispatch: buildReviewFixDispatch(
      messaging: messagingService,
      conversations: conversationRepository,
    ),
    // Interactive terminal over RPC (libccpty): the `terminal.*` ops run a REAL
    // shell on this host, scoped + ownership-checked per the bound workspace.
    // demo: no PTY on a public demo — the ops vanish from the registry.
    terminalSessions: demo != null
        ? null
        : terminalSessions,
    // Enclosures over RPC: the `rig.*` ops open, drive and destroy VMs, and
    // `rig.watchSessions` pushes status. Frames ride `/rig/stream/<id>`.
    // demo: no enclosures: booting VMs for anonymous visitors is not a demo.
    rigs: demo != null
        ? null
        : rigService,
    // Port visibility + forwarding for enclosed rigs: `rig.ports` /
    // `rig.watchPorts` and the add/remove/expose/domain mutations. The same
    // RigService owns both — the machines and their ports share one lifecycle.
    // demo: ditto — rig port forwarding.
    rigPorts: demo != null
        ? null
        : rigService,
    // code-server over RPC: the `codeServer.*` ops spawn/reuse a loopback-bound
    // code-server per conversation worktree, scoped + ownership-checked per the
    // bound workspace; reached through the `/proxy/vscode/<sid>/` reverse proxy.
    // demo: no editor proxy.
    codeServer: demo != null
        ? null
        : codeServerSessions,
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
    // decision gates and the compute + blast-radius closures (host owns the
    // code graph + git + PR fetch).
    reviewCohortRepository: reviewCohortRepository,
    apiContractDiffRepository: apiContractDiffRepository,
    visualDiffRepository: visualDiffRepository,
    reviewAxisResultRepository: reviewAxisResultRepository,
    reviewDependencyDiffRepository: reviewDependencyDiffRepository,
    computeReviewStudio: computeReviewStudioFn,
    reviewBlastRadius: reviewBlastRadiusFn,
    reviewCohortImpact: reviewCohortImpactFn,
    reviewHubStats: ({required String workspaceId}) async {
      final stats = await reviewRunSnapshotRepository.statsForWorkspace(
        workspaceId,
      );
      return {
        'findings_total': stats.findingsTotal,
        'resolved': stats.resolved,
        'dismissed': stats.dismissed,
        'still_open': stats.stillOpen,
        'addressed': stats.addressed,
        // The two that actually say whether the review is worth running.
        // `action_rate` counts only findings a human FIXED — a dismissal is a
        // rejection, and folding it into "addressed" is how a reviewer
        // congratulates itself for being ignored. `dismissal_rate` is the
        // noise signal to tune against.
        'action_rate': stats.actionRate,
        'dismissal_rate': stats.dismissalRate,
      };
    },
    // Every AI-review entry point runs the `pr_review` pipeline through one
    // implementation — see [startPrReview]. The op name and its
    // `{status, space_id, pr_external_id}` shape are kept deliberately: they
    // are a wire contract with connected clients and the `start_ai_review`
    // tool, and renaming an op buys nothing a comment cannot say.
    reviewFindingStatus: reviewFindingStatusService,
    reviewHubStart: startPrReview,
    publishReview:
        ({
          required String workspaceId,
          required String spaceId,
          required String selection,
          required bool approveOnShip,
          required String userId,
        }) async {
          // Published under the APP, not the person who pressed the button.
          //
          // The general rule is that a human-driven forge write is authored by
          // that human — but the content here is not theirs. Every finding in
          // it was written by a reviewer AGENT and stored as a review node; the
          // operator is forwarding an agent's review, not writing one. Signing
          // it with their account puts their name on judgements they did not
          // make, and a PR author reading the thread cannot tell which of the
          // two it was. Agent work rides the app identity, and this is agent
          // work with a human release gate on it.
          //
          // `userId` still matters and is deliberately still required: it is
          // what the role gate and the audit record are keyed on. Who pressed
          // publish is recorded; who is credited on GitHub is the app.
          final result = await reviewPublisherService.publish(
            workspaceId: workspaceId,
            spaceId: spaceId,
            selection: selection == 'all_open'
                ? ReviewPublishSelection.allOpen
                : ReviewPublishSelection.consensus,
            approveOnShip: approveOnShip,
            actingUserId: null,
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
    resolveStudioKey: resolvePrExternalId,
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
  //
  // POSITIVE results are memoized for a minute: this gate runs on every
  // `repo/call` AND every `sub/subscribe`, so it was a registry SELECT in
  // front of every request, serialized on the one shared connection.
  //
  // Negatives are deliberately NOT cached — a workspace created a moment later
  // has to be reachable at once, and a miss costs one primary-key lookup. The
  // positive TTL is what bounds the other direction: a DELETED workspace keeps
  // passing this gate for at most `_workspaceExistsTtl`. That is safe because
  // of what the gate is FOR — refusing ids that were never registered, so that
  // opening one cannot spray a ghost `workspace.db`. A deleted workspace's file
  // already exists, so nothing is materialized, and the authorization that
  // actually protects its data (the role gate) is exact and uncached-by-TTL.
  const workspaceExistsTtl = Duration(minutes: 1);
  final knownWorkspaceIds = <String, DateTime>{};
  Future<bool> workspaceExists(String workspaceId) async {
    final seenAt = knownWorkspaceIds[workspaceId];
    final now = DateTime.now();
    if (seenAt != null && now.difference(seenAt) < workspaceExistsTtl) {
      return true;
    }
    final exists =
        await globalDb.workspaceRegistryDao.getById(workspaceId) != null;
    if (exists) {
      knownWorkspaceIds[workspaceId] = now;
    } else {
      knownWorkspaceIds.remove(workspaceId);
    }
    return exists;
  }

  // The audit trail's WRITE path. `activity_log` had a table, a DAO, a
  // retention sweep and a read path (`activityLogReader`, serving the client's
  // entity timeline) — and no writer: `ActivityLogPersister` existed but was
  // never constructed, so the timeline read an always-empty table. Wired here,
  // behind the same registry gate as every other workspace-scoped write so a
  // late event from a deleted workspace cannot materialize a ghost database.
  final activityLogPersister = ActivityLogPersister(
    eventBus: eventBus,
    dbs: workspaceDbs,
    workspaceExists: workspaceExists,
  )..start();

  final initialWorkspaces = await _bootStep(
    'listing workspaces',
    () => listWorkspaces(ownerUserId),
  );

  // Decoded on first audited call that carries an IP (the embedded RIR table
  // is gzip+base64 — building it eagerly would tax every boot for a table
  // most headless runs never query).
  GeoIpLookup? geoIpLookup;
  // The membership chokepoint resolver, shared by the `repo/call` dispatcher,
  // the per-session `tools/call` + subscription gates and the event
  // forwarders: every surface resolves the SAME membership truth.
  // Custom (subtractive) roles: a member's stored role is either a preset
  // wire name or `custom:<id>`. The membership repository resolves the wire
  // value to its base preset (so every existing role gate keeps working
  // unchanged); this resolver additionally loads the custom row so the
  // permission resolver can subtract what the role denies.
  Future<RoleDefinition?> resolveRoleDefinition(
    String workspaceId,
    String userId,
  ) async {
    final member = await membershipRepository.getMember(workspaceId, userId);
    if (member == null) {
      return null;
    }
    final customId = RoleDefinition.customIdOf(member.roleWire);
    if (customId == null) {
      return RoleDefinition.preset(member.role);
    }
    final custom = await workspaceRoleRepository.byId(workspaceId, customId);
    // A member holding a role that no longer exists falls back to the base
    // preset the membership row resolved to — never to something broader.
    return custom ?? RoleDefinition.preset(member.role);
  }

  // Every lane resolves the member's EFFECTIVE base preset. A custom role
  // stores `custom:<id>`, which `WorkspaceRole.fromWire` reads as null (and
  // the mapper floors to guest), so without this a custom-role member would
  // be treated as a guest on the subscription / tools-call / event lanes.
  // Those lanes see the base preset; only `repo/call` additionally applies
  // the role's subtractions, because a custom role can never grant MORE than
  // its base.
  Future<WorkspaceRole?> resolveRole(String workspaceId, String userId) async =>
      (await resolveRoleDefinition(workspaceId, userId))?.basePreset;

  final repoOps = RepoOpDispatcher(
    // demo: the name allowlist, applied by REBUILDING the registry — a refused
    // op is genuinely absent, so `lookup` returns null and the dispatcher
    // answers `opUnknown` exactly as for an op that was never wired.
    registry: demo?.profile.lockdown(catalog.ops) ?? catalog.ops,
    mapException: mapAppExceptionToRpc,
    workspaceExists: workspaceExists,
    // The `ServerAuthority.serverOwner` gate — the same identity the catalog's
    // in-handler `requireServerAdmin` compares against.
    resolveServerOwner: isServerOwner,
    // `RepoOpKind.destructive` asks the operator before it applies. This was
    // never wired, and the dispatcher denies a destructive op when it is
    // absent — so the tier was not merely unused, the two ops that DID
    // declare it (`skills.uninstall`, `pr_lifecycle.delete`) were refused on
    // every call. Routed through the same fail-closed registry the guardrail
    // prompts use, so a headless server with nobody connected still denies.
    confirm: (op, args) => confirmationPort.requestApproval(
      ConfirmationRequest(
        spaceId: (args['space_id'] as String?) ?? '',
        workspaceId: args['workspace_id'] as String?,
        title: 'Confirm: ${op.name}',
        detail:
            'This operation is destructive and cannot be undone from the '
            'app.',
        severity: ConfirmationSeverity.destructive,
        kind: ConfirmationKind.capabilityEscalation,
      ),
    ),
    // The human lane's half of the tamper-evident audit spine: every
    // authorization verdict, refusals included (which `user_activity`, a
    // successes-only timeline, has never recorded).
    recordGuardDecision:
        ({
          required String workspaceId,
          required String userId,
          required String deviceId,
          required String opName,
          required String permission,
          required bool allowed,
          required String sourceScope,
          String? reason,
          String? ip,
          String? correlationId,
          List<String> actionClasses = const [],
        }) {
          unawaited(
            guardDecisionRepository
                .append(
                  GuardDecision(
                    id: const Uuid().v4(),
                    workspaceId: workspaceId,
                    occurredAt: DateTime.now(),
                    actorType: 'user',
                    actorId: userId,
                    deviceId: deviceId,
                    ip: ip,
                    surface: GuardSurface.repoRpc,
                    actionName: opName,
                    permission: permission,
                    actionClasses: actionClasses,
                    decision: allowed
                        ? ActionDecision.allow
                        : ActionDecision.deny,
                    sourceScope: sourceScope,
                    correlationId: correlationId,
                  ),
                )
                .catchError(
                  (Object e) =>
                      CcHostLog.warning('guard audit append failed: $e'),
                ),
          );
        },
    // The membership chokepoint: every workspace-scoped op resolves the
    // caller's role (non-members are refused; viewers/guests are read-only)
    // and code-bearing ops additionally check the per-repo grant.
    resolveRole: resolveRole,
    resolveRoleDefinition: resolveRoleDefinition,
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
  // against that token, duplicates are dropped and the delivery is logged.
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
  // environment: the gh token for GitHub Issues, LINEAR_API_KEY for Linear and
  // JIRA_BASE_URL + JIRA_EMAIL + JIRA_API_TOKEN for Jira. Per-workspace, per-
  // vendor connections live in `ticket_sync_configs`.
  final env = serverEnv;
  final linearSyncDio = createDio(baseUrl: 'https://api.linear.app/graphql');
  // Read PER REQUEST from the app-credential store (which the environment
  // seeds on first boot), not captured here: a key pasted in Settings has to
  // work on the next sync, not after a restart.
  linearSyncDio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final key = await providerApps.linearApiKey();
        if (key.isNotEmpty) {
          options.headers['Authorization'] = key;
        }
        handler.next(options);
      },
    ),
  );
  final githubIssuesDio = createDio(baseUrl: 'https://api.github.com');
  // Same rule for GitHub Issues: resolve the server's credential per call so
  // an app installed (or a token pasted) later takes effect immediately.
  githubIssuesDio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await forgeCredentials.tokenFor(ForgeHost.github);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
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
  final multiVendorTicketSyncCoordinator = MultiVendorTicketSyncCoordinator(
    eventBus: eventBus,
    engine: ticketSyncEngine,
    repository: ticketRepository,
  )..start();
  // Inbound vendor webhooks → CC tickets, behind HMAC verification.
  final ticketSyncWebhookHandler = TicketSyncWebhookHandler(
    engine: ticketSyncEngine,
    configRepository: ticketSyncConfigRepository,
  );

  // One pool across every transport: a user's direct-WSS, web and relayed
  // phone sessions all draw from the same rate budget.
  final rateLimiterPool = RemoteRateLimiterPool();

  // Pre-auth invite redemption (`POST /invites/redeem`): validates the one-
  // time code, JIT-provisions the user + membership + repo grants, then mints
  // the redeemer's first device credential so the new client can immediately
  // authenticate over the normal PSK handshake.
  // `remoteIp` is supplied by the route for redeemers that apply a per-address
  // cap (the demo does). The real invite path does not need it: an invite code
  // is single-use, so one address cannot accumulate sessions with it.
  Future<Map<String, dynamic>> redeemInvite(
    Map<String, dynamic> body, {
    String? remoteIp,
  }) async {
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
    // Install session policy (max age / idle timeout), enforced at the
    // device-credential check every authenticated lane funnels through.
    sessionPolicy: ssoSettings.sessionPolicy,
    dispatcher: mcpDispatcher,
    devicesDao: globalDb.pairedDeviceDao,
    secrets: secrets,
    workspaceExists: workspaceExists,
    resolveRole: resolveRole,
    eventBus: eventBus,
    workspaceResolver: listWorkspaces,
    repoOps: repoOps,
    // demo: the watch lane gets the same lockdown as the op lane — an
    // unreviewed watch query must be as unreachable as an unclassified op.
    watchQueries: demo?.profile.lockdownWatch(catalog.watch) ?? catalog.watch,
    // demo: claims a warm, pre-seeded workspace and returns the SAME envelope
    // shape, so the web client's existing auto-redeem path needs no changes.
    inviteRedeemer: demo != null ? demo.redeemVisitor : redeemInvite,
    // demo: the newsfeed reads REAL feeds, and a feed without its images is a
    // wall of grey placeholders — the one surface a screenshot is taken of.
    // Keeping the proxy is safe here because every protection it has applies
    // to a visitor exactly as to an operator: the target is signed against the
    // device PSK, `isBlockedProxyTarget` + `resolvesToBlockedAddress` refuse
    // loopback / link-local / cloud-metadata / RFC-1918 on the request AND on
    // every redirect hop, and `mediaCredential` is null below, so a demo fetch
    // carries no bearer token to leak. What it does NOT bound is size, so the
    // demo takes a tighter cap: a public host has no business relaying 96 MB
    // videos on behalf of anonymous visitors.
    mediaProxyEnabled: true,
    mediaProxyMaxBytes: demo == null ? null : 8 * 1024 * 1024,
    isDemo: demo != null,
    // demo: the documented topology puts a TLS-terminating edge in front
    // (Railway/Render/Fly forward plaintext), so without XFF every visitor
    // shares the proxy's address and a per-IP cap bounds the whole
    // deployment, not an address. Used for shaping only — never for
    // authorization.
    trustProxy: demo != null,
    // Private PR attachments: the client holds no forge token any more, so the
    // proxy fetches them as the VIEWER. Restricted to the GitHub hosts that
    // actually authenticate — sending a bearer token to an arbitrary image
    // host would hand a credential to whoever hosts the asset.
    // demo: no outbound media fetches, so no credential to mint.
    mediaCredential: demo != null
        ? null
        : (userId, target) async {
      const authenticatedHosts = {
        'api.github.com',
        'raw.githubusercontent.com',
        'private-user-images.githubusercontent.com',
      };
      if (!authenticatedHosts.contains(target.host.toLowerCase())) {
        return null;
      }
      final token = await forgeCredentials.tokenFor(
        ForgeHost.github,
        userId: userId,
      );
      return (token == null || token.isEmpty) ? null : 'Bearer $token';
    },
    // demo: no SSO on a public demo.
    oidc: demo != null
        ? null
        : oidcService,
    // demo: no OAuth callback route.
    providerOAuth: demo != null
        ? null
        : providerOAuth,
    // demo: no SSO on a public demo.
    saml: demo != null
        ? null
        : samlService,
    // demo: no directory provisioning.
    scim: demo != null
        ? null
        : scimService,
    webClientUrl: config.webClientUrl,
    authProviders: ssoSettings.authProviders,
    manualPairingEnabled: ssoSettings.isPairingEnabled,
    identity: serverIdentity,
    rateLimiters: rateLimiterPool,
    // Persistent `/proxy/media` disk cache: avatars/favicons/feed images stop
    // costing an upstream round trip on every repeat render (see MediaCache).
    mediaCacheDir: p.join(config.dataDir, 'media_cache'),
    // Font variants, cached separately so image churn cannot evict the few
    // files the UI is actively rendering with.
    fontCacheDir: p.join(config.dataDir, 'font_cache'),
    // demo: the client falls back to its bundled fonts.
    fontFile: demo != null
        ? null
        : fontCatalog.resolveFileUrl,
    // demo: nothing inbound from a forge.
    webhookHandler: demo != null
        ? null
        : 
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
    // demo: nothing inbound from a ticket vendor.
    ticketWebhookHandler: demo != null
        ? null
        : 
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
    // signed workspace (getById is workspace-scoped) and assembles `mixed.wav`
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
    // Serves a stored tool-result image over `/blob` — the screenshot an agent
    // took, resolved from the workspace's own blob directory. The route has
    // already verified the device signature AND the caller's membership of
    // this workspace before this runs.
    blob: ({required workspaceId, required hash}) async {
      final file = blobStore.fileFor(workspaceId, hash);
      if (file == null) {
        return null;
      }
      return (
        file: file,
        contentType: await blobStore.mediaTypeFor(workspaceId, hash),
      );
    },
    // The write half of the same lane: a screenshot a human attached in the
    // composer. It arrives over HTTP because the RPC socket refuses a frame
    // this size — see [BlobWriter].
    blobPut: ({required workspaceId, required bytes, required mediaType}) async {
      final stored = await blobStore.put(
        workspaceId,
        Uint8List.fromList(bytes),
        mediaType: mediaType,
      );
      return stored == null
          ? null
          : (
              ref: stored.ref,
              bytes: stored.bytes,
              mediaType: stored.mediaType,
            );
    },
    // ---- Backup transfer (`/backup/*`) ----
    // The byte half of the backup surface. `workspace.export` returns a PATH
    // and `workspace.import` takes one, which is a complete answer only when
    // the server is the operator's own machine; these three carry the bytes
    // instead, so a backup can be collected onto — and restored from — the
    // device the person is actually sitting at. All null on a demo, because
    // the service they hang off is.
    //
    // Every route re-checks the role itself: the RPC gate never runs for an
    // HTTP request, so "export is admin, import is owner" has to be stated
    // twice or it is enforced once.
    backupExport: databaseBackupService == null
        ? null
        : ({required workspaceId}) async {
            // The same `VACUUM INTO` the export op performs. The route deletes
            // the file after streaming it — see [BackupExportWriter].
            final path = await databaseBackupService.exportWorkspace(
              workspaceId,
            );
            final file = File(path);
            return file.existsSync() ? file : null;
          },
    backupSnapshotArchive: databaseBackupService == null
        ? null
        : ({required name}) async {
            // Resolved through the LISTING rather than by joining `name` onto
            // the backups root: the client names a snapshot, never a path, so
            // this route cannot be aimed at a directory the listing would not
            // have shown it.
            final snapshots = await databaseBackupService.listBackups();
            final match = snapshots.where((s) => s.name == name).firstOrNull;
            if (match == null) {
              return null;
            }
            return BackupSnapshotArchiveBuilder(
              stagingDir: backupTransferStagingDir,
            ).build(snapshot: Directory(match.path), name: name);
          },
    backupRestore: databaseBackupService == null
        ? null
        : ({required workspaceId, required sourcePath}) async {
            await databaseBackupService.importWorkspace(
              workspaceId: workspaceId,
              sourcePath: sourcePath,
            );
          },
    backupUploadDir: demo != null ? null : backupTransferStagingDir,
    // Who may download a snapshot: it holds every workspace on the install, so
    // a role in one of them authorizes nothing here.
    isServerOwner: (userId) async => userId == ownerUserId,
    // Streams the server-generated soundscape audio over `/soundscape/*`. The
    // hub keys sessions by `(workspaceId, mood)` and shares one generative
    // session across all listeners; the signed URL (`soundscape:<ws>/<mood>`)
    // is verified by the route before these run.
    // Opens a rig's watch lane for `/rig/stream/<id>`. The route verifies the
    // signed target AND workspace membership before this runs.
    // demo: no enclosures.
    rigStream: demo != null
        ? null
        : 
        ({
          required String workspaceId,
          required String rigId,
          required Map<String, dynamic> request,
        }) async {
          // `lane=audio` is the guest's sound as encoded bytes — same auth,
          // same relay-never-decode rule as the frame lane.
          if (request['lane'] == 'audio') {
            final audio = await rigService.watchAudio(
              workspaceId: workspaceId,
              rigId: rigId,
            );
            if (audio == null) {
              return null;
            }
            return (bytes: audio, contentType: 'audio/mpeg');
          }
          final stream = await rigService.watchStream(
            workspaceId: workspaceId,
            rigId: rigId,
            request: RigWatchRequest.fromJson(request),
          );
          if (stream == null) {
            return null;
          }
          return (
            bytes: stream.bytes,
            contentType: stream.negotiated.codec.contentType,
          );
        },
    // The rig clipboard and file lanes (`/rig/clipboard/<id>`,
    // `/rig/files/<id>`). The service IS the port, and the routes verify the
    // signed target plus workspace membership before touching it; every
    // operation then passes the same take-over chokepoint `rig.act` does.
    // demo: no enclosures.
    rigTransfer: demo != null
        ? null
        : rigService,
    soundscapeStream: soundscapeHub.streamFor,
    soundscapePlaylist: soundscapeHub.playlistFor,
    soundscapeSegment: soundscapeHub.segmentFor,
    // Authorizes each `/proxy/vscode/<sid>/` request against a live code-server
    // session (capability authz): unknown / expired / foreign-workspace → 403.
    // demo: no editor proxy.
    codeServerLookup: demo != null
        ? null
        : codeServerSessions.lookup,
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
    // demo: no editor proxy.
    codeServerReport: demo != null
        ? null
        : (sid, absPath, line) => codeServerSessions.reportOpen(
      sessionId: sid,
      absPath: absPath,
      line: line,
    ),
    // Receives the bridge extension's dirty-state reports (same endpoint,
    // `{type:'dirty'}`) and fans them out so the app can toggle the per-tab
    // unsaved-changes dot.
    // demo: no editor proxy.
    codeServerReportDirty: demo != null
        ? null
        : (sid, absPath, dirty) => codeServerSessions
        .reportDirty(sessionId: sid, absPath: absPath, dirty: dirty),
    // Serves the reverse command SSE stream (`/__cc_commands__`) the bridge
    // extension subscribes to for Save-on-close and future editor commands.
    // demo: no editor proxy.
    codeServerCommandStream: demo != null
        ? null
        : codeServerSessions.commandStream,
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
  // demo: never attach. Without a main server the control cannot mount its
  // handler at all, so `/mcp` + `/sse` 404 even if something later asked it to
  // start — belt over the `startIfEnabled` guard below.
  if (demo == null) {
    mcpControl.attachMainServer(server);
  }

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

  // ── On-device model warm-up (embedding + diarization + ASR) ──
  // All three models are force-installed at boot, alongside the code-server
  // warm-up: models are the only artifacts the server fetches at runtime (the
  // native dylibs ship in the bundle), so a fresh deploy lights up semantic
  // search, diarization AND speech without any client action. Runs through the
  // same [ManagedModelControl]s the `models.*` RPC ops drive, so install is a
  // no-op when already on disk, a concurrently connected client sees the boot
  // download's live progress over `models.watch*` and a failed download
  // surfaces as the control's `error` state (retried on next boot or via the
  // client's install button) without blocking the ready path.
  //
  // The ASR model is the SELECTED one, not a hardcoded id — the voice control
  // is selectable and defaults to Parakeet TDT v3, so someone who picked
  // Whisper gets the model they chose warmed rather than a second one they
  // never asked for. It is by far the largest (~600 MB against ~90 and ~35),
  // which is why it used to be opt-in; the tradeoff is deliberate now, because
  // it is the ONE model whose absence disables whole RPC ops rather than
  // degrading a feature (`meeting.*` / `dictation.*` are simply not served).
  //
  // Speech still needs ONE restart to light up, and that is not an oversight:
  // the transcriber resolves its model near the top of boot, minutes before
  // this download can finish, and awaiting a 600 MB fetch on the boot path
  // would blow the desktop's 20s ready-banner timeout and get the process
  // killed. Predownloading turns the old three-step dance (open settings,
  // install, restart) into a single restart.
  //
  // demo: SKIPPED. These are ~700 MB of downloads from a public model host —
  // by far the largest outbound transfer the server can make — and a demo
  // needs none of them: meetings and dictation are denied at the op layer and
  // the seeded memory facts are FTS-only by design (the documented degrade
  // while no embedding model is installed). Leaving this unguarded would have
  // made "a demo container makes no outbound request" plainly false.
  if (demo == null) {
    CcHostLog.info(
      'cc_server: ensuring on-device models (embedding + diarization + '
      'speech) under ${config.dataDir}/models',
    );
    unawaited(embeddingModelControl.install());
    unawaited(diarizationModelControl.install());
    unawaited(voiceModelControl.install());
  }

  // ── Client relay (broker rendezvous, PRD 15) ──
  // cc_server OWNS one N-way signaling room: it joins the broker as the room
  // owner, publishes the admission-hash set derived from every active paired
  // device and serves an authenticated RPC session per relayed client
  // (desktop, web, or phone) over the E2E-encrypted chunked relay — the
  // guaranteed fallback when no direct path exists. Watching the device
  // table covers startup, mint and revoke uniformly (revocation evicts the
  // live broker connection too).
  final relayHost = RemoteRelayHost(
    signalingUrl: config.signalingUrl,
    identity: serverIdentity,
    dispatcher: mcpDispatcher,
    workspaceExists: workspaceExists,
    resolveRole: resolveRole,
    devicesDao: globalDb.pairedDeviceDao,
    secrets: secrets,
    eventBus: eventBus,
    workspaceResolver: listWorkspaces,
    repoOps: repoOps,
    // demo: the watch lane gets the same lockdown as the op lane — an
    // unreviewed watch query must be as unreachable as an unclassified op.
    watchQueries: demo?.profile.lockdownWatch(catalog.watch) ?? catalog.watch,
    rateLimiters: rateLimiterPool,
  );
  // `cc_server pair` writes the device row from its OWN process, and drift's
  // update notifications are in-process only — so `watchAll()` above (and the
  // clients' `pairing.watchOwn`) would not fire for it, leaving the device
  // unadmitted to the relay room and invisible in the device list until the
  // next boot. This re-reads the registry and republishes a change, which is
  // what makes pairing from the CLI work against a RUNNING server.
  final pairedDeviceWatch = PairedDeviceRegistryWatch(global: globalDb);
  unawaited(() async {
    try {
      await pairedDeviceWatch.start();
    } on Object catch (e) {
      CcHostLog.warning('cc_server: paired-device registry watch failed: $e');
    }
  }());

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
  // mDNS LAN advertisement, the persisted share-this-server tunnel and
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
  //
  // demo: skipped. A public demo is reached at a known URL behind a proxy; it
  // has no business advertising itself on the host's LAN or opening a tunnel.
  if (demo == null) {
    await _bootStepBounded(
      'starting network runtime (mDNS + tunnel)',
      networkRuntime.start,
      onTimeout: 'LAN discovery / tunnel will come up in the background',
    );
  }

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
  // Hand it to the demo's pool (see `demoBaseSeeder` above).
  demoBaseSeeder = workspaceSeeder;
  eventBus.on<WorkspaceCreated>().listen(
    (event) => unawaited(
      workspaceSeeder.seed(
        event.workspaceId,
        // demo: the same two-template whitelist everywhere templates are
        // written — this listener is unawaited, so an unfiltered seed here
        // re-added the eleven the seeder's prune had just removed.
        onlyTemplateIds: demo == null ? null : kDemoPipelineTemplateIds,
      ),
    ),
  );
  // Built-in templates are seeded when a workspace is created, so a workspace
  // created by an older version keeps that version's graph forever unless
  // something reconciles it — a seed that gains a node, a repo scope or a
  // reworded prompt would only ever reach brand-new workspaces. Reconcile every
  // workspace at boot. Read-only in steady state and a template the user edited
  // is skipped outright (the editor clears `isBuiltIn` on save), so this cannot
  // overwrite their work or their enabled/trigger choices.
  // CROSS-WORKSPACE BY DESIGN: a startup reconciler delivering a template
  // seed, like the orphan-run reaper.
  //
  // `resumeAll` below AWAITS this (see `templateReconcile`) rather than racing
  // it. A seed that gains a node is also what UNBLOCKS the runs stuck on the
  // old graph: `resumeAll` re-evaluates each in-flight run against the live
  // template, so a run left non-terminal by a missing terminal node finishes
  // on the next boot — but only if the reconcile landed first. Racing it made
  // that a coin flip, and a lost toss means another boot with the same stuck
  // rows (and their dedup keys still blocking new runs).
  final templateReconcile = () async {
    try {
      final all = await workspaceRepository.watchAll().first;
      for (final ws in all) {
        // demo: the same two-template whitelist the seeder prunes to — an
        // unfiltered reconcile would re-add the other eleven on every boot.
        await workspaceSeeder.reseedTemplates(
          ws.id,
          onlyTemplateIds: demo == null ? null : kDemoPipelineTemplateIds,
        );
      }
    } on Object catch (e) {
      CcHostLog.warning('built-in template reconcile failed: $e');
    }
  }();
  unawaited(templateReconcile);
  // Skills antivirus on-disk trigger: watch every workspace's skills dir and
  // publish SkillUpdated(origin: watch) for out-of-band edits, which the
  // seeded skill_analysis trigger turns into an analysis run. Arming is O(1)
  // (native watch, no tree scan); the service only reacts to events.
  final skillWatch = SkillWatchService(
    workspaces: workspaceRepository,
    filesystem: workspaceFilesystem,
    eventBus: eventBus,
    bundles: skillBundles,
  );
  // demo: no repos are ever registered, so there is nothing to watch, and the
  // skills surface is denied at the op layer.
  if (demo == null) {
    skillWatch.start();
  }

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
  final teamRoutingService = TeamRoutingService(
    eventBus: eventBus,
    teamRepository: teamRepository,
    agentRepository: agentRepository,
    ticketRepository: ticketRepository,
    runLogRepository: agentRunLogRepository,
    activityRepository: TeamActivityRepositoryImpl(workspaceDbs),
    leaderDispatch: MessagingTeamLeaderDispatch(messagingService),
  )..start();
  final pipelineTriggerDispatcher = PipelineTriggerDispatcher(
    eventBus: eventBus,
    engine: pipeline.engine,
    triggerRepository: pipelineTriggerRepository,
  )..start();
  // Time-based triggers: ticks every minute, fires due cron/interval schedules
  // (CatchUpLatestOnly) and records each fire in the cron_executions ledger so
  // a restart mid-slot never double-starts a run. Evaluated in UTC.
  final pipelineScheduler = PipelineSchedulerService(
    triggerRepository: pipelineTriggerRepository,
    engine: pipeline.engine,
    ledger: CronExecutionLedgerImpl(workspaceDbs),
  )..start();
  final subPipelineResumeListener = SubPipelineResumeListener(
    eventBus: eventBus,
    engine: pipeline.engine,
    repository: pipelineRunRepository,
  )..start();
  // Bound the growth of append-only audit/log tables (activity_log,
  // webhook_deliveries, cron_executions) plus finished runs' activity
  // transcripts: daily prune past a generous per-table window.
  final databaseRetention = DatabaseRetentionService(
    workspaces: workspaceDbs,
    onError: (message) => CcHostLog.warning('retention: $message'),
  )..start();
  // Harness transcripts age out on the same cadence. They are keyed by
  // conversation AND agent while the deletion signal (SpaceDeleted) carries
  // neither, so precise deletion would mean the store querying the database —
  // the dependency it exists without. A transcript is a cache: a stale one
  // costs disk, never correctness, because a deleted conversation's id is
  // never resumed.
  final transcriptRetention = Timer.periodic(const Duration(hours: 24), (
    _,
  ) async {
    final removed = await transcriptStore.pruneAll(dataDir: config.dataDir);
    if (removed > 0) {
      CcHostLog.info('retention: pruned $removed harness transcript(s)');
    }
  });
  // ONE boot-time skill re-verification pass (PRD 23 §6): after a server
  // upgrade that bumps the scanner rules version, installed skills' verdicts
  // predate the tightened rules and get one re-examination (clears or
  // quarantines + detaches). Steady state: a no-op. Everything continuous is
  // event-driven — gated writes and the skills-dir watcher publish
  // SkillUpdated, which the skill_analysis trigger re-scans within seconds.
  SkillReVerifyService(
    workspaces: workspaceRepository,
    bundles: skillBundles,
    quarantineGuard: skillQuarantineGuard,
    onError: (message) => CcHostLog.warning('skill re-verify: $message'),
  ).start();
  final pipelineCostRollupListener = PipelineCostRollupListener(
    eventBus: eventBus,
    runLogRepository: agentRunLogRepository,
    runRepository: pipelineRunRepository,
  )..start();
  // Budget governance (PRD 09): evaluate an agent's spend the moment and run
  // completes — a soft-threshold crossing records a warning incident, and an
  // exhausted budget records a hard incident AND auto-pauses the agent (its
  // lifecycle flips to `paused`, so it stops being dispatchable).
  final budgetEvaluationListener = BudgetEvaluationListener(
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
  )..start();
  final pipelineStepResumeListener = PipelineStepResumeListener(
    eventBus: eventBus,
    runLogRepository: agentRunLogRepository,
    engine: pipeline.engine,
    // Plan drift (PRD 17 §6): a finished node that diverged from its
    // declared scope under `stopAndAsk` HOLDS here until the operator
    // resumes it via `orchestration.continueNode`.
    driftGate: planDriftService.evaluate,
  )..start();
  final agentRunTaskCompleter = AgentRunTaskCompleter(
    eventBus: eventBus,
    runLogRepository: agentRunLogRepository,
    messagingRepository: messagingRepository,
  )..start();
  final orchestrationRunListener = OrchestrationRunListener(
    eventBus: eventBus,
    orchestrations: orchestrationRepository,
    ticketWorkflow: ticketWorkflow,
  )..start();
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
      // Same rule for the skill-analysis projection runs: they are the scan
      // ops' rows, not resumable pipelines — close them before resumeAll.
      final closedSkillRuns = await skillAnalysisReporter.reapInterrupted();
      if (closedSkillRuns > 0) {
        CcHostLog.info(
          'cc_server: closed $closedSkillRuns interrupted skill-analysis '
          'run(s)',
        );
      }
      // Resume against the RECONCILED graph, not whatever this workspace was
      // last seeded with — a run stuck on a stale template only completes if
      // the seed that fixes it is already written. Bounded: the reconcile is
      // an ordering preference, not a prerequisite, and resume must never be
      // the thing a slow/stuck seed pass takes down with it.
      await templateReconcile.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          CcHostLog.warning(
            'cc_server: built-in template reconcile still running after 30s; '
            'resuming pipelines against the templates as they stand',
          );
        },
      );
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
  // Crash recovery for agent RUNS and the tickets behind them.
  //
  // Both services existed and were unit-tested but were wired NOWHERE, so
  // after a crash or SIGKILL runs stayed `running` and tickets stayed
  // `inProgress` forever — the UI showed live work that no process was doing,
  // and the ticket could never be picked up again. (The space-provisioning
  // reconciler above even documents itself as "mirroring the orphan-run
  // reaper", a reaper that was not running.)
  //
  // One best-effort sweep at boot, after the pipeline/goal resumes so a run
  // legitimately resumed above is already `running` again by the time the
  // reaper looks — and after the ready banner, like every other reconciler.
  final budgetEnforcement = BudgetEnforcementService(
    agentRunLogRepository: agentRunLogRepository,
    agentRepository: agentRepository,
    eventBus: eventBus,
  );
  unawaited(() async {
    try {
      await OrphanRunReaper(
        runLogRepo: agentRunLogRepository,
        ticketRepo: ticketRepository,
        ticketWorkflow: ticketWorkflow,
        processControl: const ProcessControlService(),
        budgetEnforcement: budgetEnforcement,
      ).reap();
    } on Object catch (e, st) {
      CcHostLog.error('cc_server: orphan-run reap failed: $e', e, st);
    }
    try {
      await StrandedTicketReconciler(
        ticketRepo: ticketRepository,
        agentRepo: agentRepository,
        runLogRepo: agentRunLogRepository,
        ticketWorkflow: ticketWorkflow,
        budgetEnforcement: budgetEnforcement,
      ).reconcile();
    } on Object catch (e, st) {
      CcHostLog.error(
        'cc_server: stranded-ticket reconciliation failed: $e',
        e,
        st,
      );
    }
  }());

  // Start the MCP surface when the persisted config has it enabled. A
  // companion bind failure (TLS topology, port in use) is logged but does not
  // abort the RPC server.
  //
  // demo: NOT started. Nulling `mcpControl` in the catalog only removes the
  // `mcp.*` OPS — the HTTP surface is mounted by this separate call, so
  // without this guard `/mcp` and `/sse` stayed live on a public demo (and
  // `/sse` held the connection open, which is how this was found).
  try {
    if (demo == null) {
      await mcpControl.startIfEnabled();
    }
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
    .._pairedDeviceWatch = pairedDeviceWatch
    .._networkRuntime = networkRuntime
    .._presenceHub = presenceHub
    .._agentPresenceSynthesizer = agentPresenceSynthesizer
    .._syncFeed = syncFeed
    .._checkerListener = checkerListener
    .._worktreeGcListener = worktreeGcListener
    .._rigEventListener = rigEventListener
    .._notificationFeedRecorder = notificationFeedRecorder
    .._codeGraphWatch = codeGraphWatch
    .._lspSupervisor = lspSupervisor
    .._mcpClientService = mcpClientService
    .._codeServer = codeServerSessions
    .._rigs = rigService
    .._pendingConfirmations = pendingConfirmationRegistry
    .._approvalEscalation = approvalEscalation
    .._auditStream = auditStream
    .._skillWatch = skillWatch
    .._pipelineScheduler = pipelineScheduler
    .._databaseRetention = databaseRetention
    .._transcriptRetention = transcriptRetention
    .._debugSupervisor = debugSupervisor
    .._astParsers = astParsers
    .._eventListenerStops.add(activityLogPersister.dispose)
    .._eventListenerStops.add(agentRunTaskCompleter.dispose)
    .._eventListenerStops.add(budgetEvaluationListener.dispose)
    .._eventListenerStops.add(multiVendorTicketSyncCoordinator.dispose)
    .._eventListenerStops.add(orchestrationRunListener.dispose)
    .._eventListenerStops.add(pipelineCostRollupListener.dispose)
    .._eventListenerStops.add(pipelineStepResumeListener.dispose)
    .._eventListenerStops.add(pipelineTriggerDispatcher.dispose)
    .._eventListenerStops.add(subPipelineResumeListener.dispose)
    .._eventListenerStops.add(teamRoutingService.dispose)
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
  // every subscribed andnt), publish domain events (new PR / merged / closed
  // → notifications), and signal open PR-detail streams to re-validate.
  // demo: never sweep. The demo's poller is a no-op subclass anyway, but the
  // real one must not be armed on a host with no forge credential.
  if (demo == null) {
    openPrPoller.start();
  }
  ccServer._openPrPoller = openPrPoller;
  ccServer._demo = demo;
  ccServer._prChangeSignals = prChangeSignals;

  // The viewer-activity poll reads the owner's own pull-request activity
  // (pending reviews incl. TEAM requests, mentions, merges) as four aliased
  // GraphQL searches in ONE request per sweep. Review requests become
  // `PrReviewRequested` events (→ client notifications); any PR activity on a
  // linked repo triggers a targeted refresh of that PR's open streams.
  //
  // This replaced a `GET /notifications` poll. That endpoint is user-only and
  // NO GitHub App token can read it — installation or user-to-server alike —
  // while signing in here mints a GitHub App user token, so the lane 403'd
  // ("Resource not accessible by integration") on every install that had not
  // also pasted a classic PAT, and three notification types silently never
  // fired. `search` is reachable by every credential kind. There is no fallback
  // to the inbox when a PAT happens to be present: one lane that always works
  // beats two that can disagree.
  //
  // Gated at every pass rather than at boot, and on the OWNER'S OWN credential
  // rather than on whatever `ghToken` resolved to. Both halves matter: an app
  // identity or a bare `GITHUB_TOKEN` makes `ghToken` non-empty without any
  // human having signed in, so the old boot check started a poller with nobody
  // to read activity FOR; and deciding once at boot meant a server that started
  // empty never polled after onboarding finished, while one that started
  // configured kept polling after a sign-out. A per-pass gate is self-healing
  // in both directions and costs one cached credential read every 5 minutes.
  final githubActivityPoller = GitHubViewerActivityPollingService(
    githubClient: GitHubApiClient(ownerForgeDioFactory.of(ForgeHost.github)),
    shouldPoll: () async {
      final token = await forgeCredentials.tokenFor(
        ForgeHost.github,
        userId: ownerUserId,
      );
      if (token == null || token.isEmpty) {
        return false;
      }
      // Nowhere to route a notification to. Every PR would be resolved
      // against the repo→workspace index and dropped, so this is a request
      // per minute for a guaranteed no-op.
      final workspaces = await workspaceRepository.watchAll().first;
      return workspaces.any((w) => w.deletedAt == null);
    },
    eventBus: eventBus,
    changeSignals: prChangeSignals,
    // The comment lane: resolves a mention down to the comment that carries
    // it, so the notification names the file and line and the deep link lands
    // on the comment. Runs on the OPERATOR's credential, which is why it lives
    // here and not in the bot's conversation poller — that one holds app
    // installation tokens and cannot see a human mentioning this person on a
    // repo the app is not installed on.
    viewerLogin: () =>
        forgeCredentials.viewerLogin(ForgeHost.github, userId: ownerUserId),
    commentFetch: GitHubViewerCommentFetchAdapter(
      prClient: GitHubApiClient(
        ownerForgeDioFactory.of(ForgeHost.github),
      ).pr,
      graphqlClient: GitHubApiClient(
        ownerForgeDioFactory.of(ForgeHost.github),
      ).graphql,
    ),
    forUserId: ownerUserId,
    // Answered from a maintained `repo full name → workspace ids` index
    // instead of re-reading every workspace and then every workspace's
    // repo list on each lookup (O(workspaces) queries per repo per ~60s
    // tick). Repo↔workspace links change rarely, so the index is rebuilt on
    // a TTL rather than per lookup.
    workspacesForRepo: repoWorkspaceIndex.workspacesFor,
    onWorkspaceTouched: (workspaceId) =>
        unawaited(openPrPoller.pollSoon(workspaceId)),
    // The viewer's activity is cross-workspace, so the dedupe store lives in
    // global.db's server_meta — not in any workspace file. A fresh key: the
    // v1 store under `githubNotificationDedupe` was keyed by notification
    // thread id, which has no meaning for a search-derived sweep.
    loadDedupeState: () =>
        globalDb.workspaceRouteDao.meta('githubActivityDedupe'),
    saveDedupeState: (state) =>
        globalDb.workspaceRouteDao.setMeta('githubActivityDedupe', state),
  );
  // demo: polling GitHub is egress, and there is no account to poll for.
  if (demo == null) {
    githubActivityPoller.start();
  }
  ccServer._githubActivityPoller = githubActivityPoller;
  // Started earlier, where its seams live; bound here because `ccServer` is
  // declared only now.
  ccServer._prConversationPoller = prConversationPoller;

  // ── Ticket sync pull fallback ──
  // Vendor webhooks require this server to be publicly reachable, which it
  // often is not (no tunnel). A modest periodic pull keeps vendor-side ticket
  // changes flowing in  anddless; the sweep skips workspaces with no enabled
  // pull-capable config, and `applyPull` dedupes anything a webhook already
  // delivered.
  // demo: no vendor sync — `ticket_sync.*` is denied and there are no vendor
  // credentials, so the sweep would only make failing outbound calls.
  ccServer._ticketSyncPullTimer = demo != null
      ? null
      : Timer.periodic(const Duration(minutes: 5), (
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
  // demo: the seeded calendar is fictional and static; syncing would dial
  // Google for an account that does not exist.
  if (demo == null) {
    serverCalendar.sync.start();
  }
  ccServer._calendarSync = serverCalendar.sync;
  ccServer._weatherService = weatherService;
  ccServer._soundscapeHub = soundscapeHub;
  // demo: the weather service fetches a public API — still egress.
  if (demo == null) {
    weatherService.start();
  }

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
  // The newsfeed is PER-USER (global tables, not workspace-scoped) and
  // fetched SERVER-SIDE only — the thin clients (web / desktop) just read
  // the synced articles, they never fetch RSS themselves. So the server owns
  // the schedule: seed the default feeds for every user on first run, fetch
  // once now so a freshly-connected client sees articles immediately, then
  // refresh on a fixed cadence. Users created after boot seed lazily via
  // `newsfeed.seedDefaultFeedsIfEmpty` when they first open the newsfeed.
  // Relocated here from the old desktop bootstrap (which no longer opens the
  // DB). Best-effort: a network failure is logged, never fatal.
  Future<void> refreshAllUsersNewsfeeds() async {
    // CROSS-WORKSPACE BY DESIGN: the newsfeed is per-USER and users are a
    // global registry — the sweep fans out to every user's own feeds.
    final users = await globalDb.userDao.getAll();
    for (final user in users) {
      await newsfeedRepository.seedDefaultFeedsIfEmpty(user.id);
      await newsfeedRepository.refreshAll(user.id);
    }
  }

  unawaited(() async {
    try {
      await refreshAllUsersNewsfeeds();
    } on Object catch (e, st) {
      CcHostLog.error('cc_server: newsfeed seed/refresh failed: $e', e, st);
    }
  }());
  ccServer._newsfeedRefreshTimer = Timer.periodic(const Duration(minutes: 30), (
    _,
  ) async {
    try {
      await refreshAllUsersNewsfeeds();
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

  // The demo's pool warm-up and reaper start here for exactly the reason
  // indexing does: seeding a workspace is seconds of SQLite writes, and the
  // desktop supervisor kills a child that has not printed the banner in 20s.
  unawaited(demo?.start() ?? Future<void>.value());

  // Background code-graph indexing starts only AFTER the ready banner. The
  // desktop parses that banner with a hard 20s timeout and kills the child on
  // expiry (cc_server_process.dart), so indexing must never compete with the
  // path to it. The service additionally holds its first sweep for
  // `--code-index-defer` seconds so the desktop's initial RPC burst lands on
  // an idle database connection.
  // Enclosures arm after the banner for the same reason indexing does: the
  // desktop kills this process if the banner is late, and a hypervisor probe
  // plus an orphan sweep is exactly the kind of work that must not be on the
  // path to it.
  unawaited(() async {
    try {
      await rigCredentials.start();
      qemuBackend.credentialPort = rigCredentials.port;
      smolvmBackend.credentialPort = rigCredentials.port;
      // Egress proxies are per-rig now — each launch starts listeners bound
      // to that rig's own allowlist — so nothing here touches the shared
      // sandbox proxies, whose single mutable config every terminal spawn
      // overwrites.
      await rigService.start();
    } on Object catch (e, st) {
      // A host with no hypervisor is the common case, not an error: rigs are
      // simply unavailable and every surface says so. One INFO line, and the
      // stack trace only for the failures that are NOT that case — a full
      // trace at warning on every boot of every hypervisor-less host is how a
      // log stops being read.
      CcHostLog.info('cc_server: enclosures unavailable ($e)');
      if (e is! RigLaunchException) {
        CcHostLog.warning('cc_server: enclosure start trace: $st');
      }
    }
  }());

  // After the banner, for the same reason indexing is: it touches the
  // filesystem, and a late banner costs the desktop the whole server.
  unawaited(astParsers.warm());

  if (config.codeIndexEnabled && demo == null) {
    codeGraphWatch.start();
    CcHostLog.info(
      'cc_server: code-graph indexing armed '
      '(first sweep in ${config.codeIndexDeferSeconds}s)',
    );
  } else {
    CcHostLog.info('cc_server: code-graph indexing disabled by config');
  }

  // Chat transports dial out after the banner for the sa andason indexing does:
  // the desktop kills this process if the banner is late, and an unreachable
  // provider must cost chat connectivity, never the whole server.
  // demo: no chat transports. They dial Slack/Discord and there are no
  // credentials to dial with.
  if (demo == null) {
    unawaited(() async {
      try {
        await chatConnector.start();
      } on Object catch (e, st) {
        CcHostLog.error('cc_server: chat connector start failed: $e', e, st);
      }
    }());
  }
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
/// A malformed blob yields an EMPTY map rather th androwing: a corrupt
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

/// Workspace-settings key holding a Claude Code account pool.
///
/// One key per scope: the workspace's own, and one per agent that overrides it.
/// Namespaced so it cannot collide with a real setting, and absent until the
/// operator attaches something — which is what keeps an install that never
/// opens the screen on the pre-pool path.
String claudeAccountPoolKey(String? agentId) =>
    agentId == null || agentId.isEmpty
    ? 'claude_accounts.pool'
    : 'claude_accounts.pool.agent.$agentId';

/// Workspace-settings key holding a pool's round-robin position.
String claudeAccountCursorKey(String? agentId) =>
    '${claudeAccountPoolKey(agentId)}.cursor';

/// Reads the most specific pool that applies: the agent's, else the
/// workspace's, else unconfigured.
///
/// An agent pool with no accounts in it is treated as "not set" rather than as
/// "attach nothing" — an empty list is what an editor leaves behind when the
/// operator removes the last row, and reading that as a deliberate opt-out
/// would silently stop every run for that agent.
Future<AccountPool> _readClaudeAccountPool(
  WorkspaceSettingsRepository settings,
  String workspaceId,
  String? agentId,
) async {
  for (final key in [
    if (agentId != null && agentId.isNotEmpty) claudeAccountPoolKey(agentId),
    claudeAccountPoolKey(null),
  ]) {
    final raw = await settings.get(workspaceId, key);
    if (raw == null || raw.isEmpty) {
      continue;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final pool = AccountPool.fromJson(decoded);
        if (!pool.isEmpty) {
          return pool;
        }
      }
    } on Object {
      // A corrupt pool falls through to the next scope rather than stopping
      // the dispatch.
    }
  }
  return const AccountPool();
}

/// The lane an account pool belongs to.
///
/// One string so a single pair of RPC ops serves both, because the editing
/// surface is identical: an ordered list plus a strategy. `claude-code` names
/// the CLI adapter's account directories; `harness:<providerId>` names one
/// harness provider's stored credentials.
const String claudeAccountLane = 'claude-code';

/// The `harness:<providerId>` lane string for [providerId].
String harnessAccountLane(String providerId) => 'harness:$providerId';

/// The workspace-settings key a [lane] + [agentId] pool is stored under, or
/// null when the lane is not one we recognize.
///
/// Rejecting an unknown lane rather than deriving a key from it is what stops a
/// client writing arbitrary settings keys through this op.
String? accountPoolKeyForLane(String lane, String? agentId) {
  if (lane == claudeAccountLane) {
    return claudeAccountPoolKey(agentId);
  }
  const prefix = 'harness:';
  if (lane.startsWith(prefix) && lane.length > prefix.length) {
    return harnessPoolKey(lane.substring(prefix.length), agentId);
  }
  return null;
}

/// Workspace-settings key holding a harness provider's account pool.
///
/// Per provider, because "which keys may this workspace spend" is a different
/// question for OpenAI than for Kimi — and per agent on top of that, so a
/// research agent can be pinned to the cheap key while the rest of the
/// workspace rotates.
String harnessPoolKey(String providerId, String? agentId) =>
    agentId == null || agentId.isEmpty
    ? 'harness_accounts.pool.$providerId'
    : 'harness_accounts.pool.$providerId.agent.$agentId';

/// Workspace-settings key holding a harness pool's round-robin position.
String harnessCursorKey(String providerId, String? agentId) =>
    '${harnessPoolKey(providerId, agentId)}.cursor';

/// Orders [credentialIds] for one dispatch, applying the workspace's (or the
/// agent's) pool, its strategy, and any cooling-off keys.
///
/// Returns null when nothing is configured, so the caller keeps the store's own
/// order — the behaviour every install had before pools existed. The
/// round-robin cursor is advanced and persisted here, BEFORE the run, so two
/// dispatches racing still lead with different credentials.
Future<List<String>?> resolveHarnessRotationOrder({
  required WorkspaceSettingsRepository settings,
  required CredentialCooldownStore cooldowns,
  required String? workspaceId,
  required String? agentId,
  required String providerId,
  required List<String> credentialIds,
}) async {
  if (workspaceId == null || credentialIds.length < 2) {
    return null;
  }
  AccountPool pool = const AccountPool();
  String? usedKey;
  for (final key in [
    if (agentId != null && agentId.isNotEmpty)
      harnessPoolKey(providerId, agentId),
    harnessPoolKey(providerId, null),
  ]) {
    final raw = await settings.get(workspaceId, key);
    if (raw == null || raw.isEmpty) {
      continue;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final candidate = AccountPool.fromJson(decoded);
        if (!candidate.isEmpty) {
          pool = candidate;
          usedKey = key;
          break;
        }
      }
    } on Object {
      // A corrupt pool falls through to the next scope rather than stopping
      // the dispatch.
    }
  }
  if (pool.isEmpty || usedKey == null) {
    return null;
  }

  final cooling = await cooldowns.activeFor(providerId);
  final availability = {
    for (final id in credentialIds)
      id: AccountAvailability(
        id: id,
        signedIn: true,
        spent: cooling.containsKey(id),
        availableAt: cooling[id],
      ),
  };
  final cursorKey = harnessCursorKey(
    providerId,
    usedKey.contains('.agent.') ? agentId : null,
  );
  final cursor =
      int.tryParse(await settings.get(workspaceId, cursorKey) ?? '') ?? 0;
  final choice = AccountSelector.select(
    pool: pool,
    availability: availability,
    cursor: cursor,
  );

  switch (choice) {
    case AccountPoolUnset():
      // Every id in the pool names a credential that no longer exists.
      return null;
    case AccountsAllSpent():
      // Unlike the Claude lane there is no refusal here, and that asymmetry is
      // deliberate: `FallbackProvider` retries a capacity error on the SAME
      // target after backoff, so handing it the pool anyway lets a window that
      // reopens mid-turn still serve the run. Refusing would be strictly worse.
      return [
        for (final id in pool.accountIds)
          if (availability.containsKey(id)) id,
      ];
    case AccountChosen(:final accountId, cursor: final next):
      if (next != cursor) {
        await settings.set(workspaceId, cursorKey, '$next');
      }
      return [
        accountId,
        for (final id in pool.accountIds)
          if (id != accountId && availability.containsKey(id)) id,
      ];
  }
}

/// `me@example.com · max · Acme` — one line naming a Claude Code account.
///
/// Not localized on purpose: every part is a value the CLI handed back
/// verbatim, and translating around an unknown-shaped string reads worse than
/// showing it plainly. Falls back to the operator's own label when the CLI has
/// reported no identity yet.
String _claudeAccountLabel(ClaudeAccount account) {
  final parts = [
    if (account.email != null && account.email!.isNotEmpty) account.email!,
    if (account.subscriptionType != null &&
        account.subscriptionType!.isNotEmpty)
      account.subscriptionType!,
    if (account.orgName != null && account.orgName!.isNotEmpty)
      account.orgName!,
  ];
  return parts.isEmpty ? account.label : parts.join(' · ');
}
