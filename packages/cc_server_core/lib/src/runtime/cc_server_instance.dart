part of '../cc_server_runtime.dart';

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
