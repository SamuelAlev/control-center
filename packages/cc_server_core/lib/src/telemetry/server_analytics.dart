import 'dart:async';
import 'dart:io' show Platform;

import 'package:cc_analytics/cc_analytics.dart';
import 'package:cc_domain/cc_domain.dart' show BuildInfo;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/events/meeting_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/events/repo_events.dart';
import 'package:cc_domain/core/domain/events/rig_events.dart';
import 'package:cc_domain/core/domain/events/skill_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/server_settings_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart' show createHttpClient;
import 'package:rhttp/rhttp.dart' show RhttpCompatibleClient;
import 'package:uuid/uuid.dart';

/// The install's telemetry config and, outside a demo, the server's own
/// reporting.
typedef ServerTelemetry = ({
  ServerTelemetryConfigRepository config,
  ServerAnalytics? analytics,
});

/// Builds the telemetry config over [settings] and, unless [isDemo], starts
/// [ServerAnalytics] on [eventBus]. Call before any service can publish.
///
/// `CC_ANALYTICS_DEBUG=1` in [environment] (the process environment over
/// `.env`) lets debug and profile builds of this server and of every client
/// connected to it send too, for testing the pipeline; the operator's switch
/// still decides. A demo never reports: a public demo container makes no
/// outbound request.
ServerTelemetry startServerTelemetry({
  required ServerSettingsRepository settings,
  required DomainEventBus eventBus,
  required AgentRunLogRepository runLogs,
  required PipelineRunRepository pipelineRuns,
  required Map<String, String> environment,
  required bool isDemo,
}) {
  final config = ServerTelemetryConfigRepository(
    settings,
    debugBuildsAllowed: analyticsDebugBuildsAllowed(environment),
  );
  if (isDemo) {
    return (config: config, analytics: null);
  }
  final analytics = ServerAnalytics(
    eventBus: eventBus,
    config: config,
    runLogs: runLogs,
    pipelineRuns: pipelineRuns,
    isDemo: false,
    environment: environment,
    log: CcHostLog.info,
    sinkFactory: (_, context) => AnalyticsDestination.createSink(
      context: context,
      nativeUserAgent: true,
      client: RhttpCompatibleClient.of(createHttpClient()),
      onDiagnostic: CcHostLog.info,
    ),
  )..start();
  return (config: config, analytics: analytics);
}

/// The server's own analytics: domain facts no single client observes once.
///
/// Clients report what a person did in their UI; the server reports what
/// happened in the install (a run finished, a workspace or ticket was
/// created, a pipeline ended), whoever caused it, so an agent's work is
/// counted exactly once however many clients are watching. It listens on the
/// [DomainEventBus] and maps each event through the tracking plan.
///
/// Gated like every other surface: the install's usage-analytics switch
/// (followed live through [TelemetryConfigRepository.watch]) and the build —
/// only an AOT-compiled server (`dart build cli`, `dart.vm.product`) sends;
/// `dart run` logs instead, unless `CC_ANALYTICS_DEBUG=1`
/// ([analyticsDebugBuildsAllowed]) lifts that gate. A `DO_NOT_TRACK=1`
/// environment variable turns the server's own reporting off regardless of
/// the switch.
class ServerAnalytics {
  /// Creates the listener. Call [start] to subscribe.
  ServerAnalytics({
    required this._eventBus,
    required this._config,
    required this._runLogs,
    required this._pipelineRuns,
    required AnalyticsSink Function(
      TelemetryConfig config,
      AnalyticsContext context,
    )
    sinkFactory,
    required bool isDemo,
    required void Function(String message) log,
    Map<String, String>? environment,
    bool? collectionAllowed,
  }) : _log = log {
    final env = environment ?? Platform.environment;
    final context = AnalyticsContext(
      appType: AnalyticsAppType.server,
      appVersion: BuildInfo.buildVersion,
      appBuild: BuildInfo.buildGitSha,
      platform: Platform.operatingSystem,
      launchId: AnalyticsId(const Uuid().v4()),
      isDemo: isDemo,
    );
    _optedOut = _doNotTrack(env);
    _analytics = Analytics(
      context: context,
      collectionAllowed:
          collectionAllowed ?? const bool.fromEnvironment('dart.vm.product'),
      sinkFactory: (config) => sinkFactory(config, context),
      developmentSink: LoggingAnalyticsSink(log),
      onDiagnostic: log,
    );
  }

  final DomainEventBus _eventBus;
  final TelemetryConfigRepository _config;
  final AgentRunLogRepository _runLogs;
  final PipelineRunRepository _pipelineRuns;
  final void Function(String message) _log;
  late final Analytics _analytics;
  late final bool _optedOut;
  final _subscriptions = <StreamSubscription<Object?>>[];

  /// Whether `DO_NOT_TRACK` turned the server's reporting off.
  bool get optedOut => _optedOut;

  /// Subscribes to the config and the domain events.
  void start() {
    if (_optedOut || _subscriptions.isNotEmpty) {
      return;
    }
    _subscriptions
      ..add(
        _config.watch().listen(
          _analytics.configure,
          onError: (Object e) => _log('analytics: config watch failed: $e'),
        ),
      )
      ..add(
        _on<WorkspaceCreated>(
          (e) => AnalyticsEvents.workspaceCreated(workspaceId: e.workspaceId),
        ),
      )
      ..add(
        _on<SpaceCreated>(
          (e) => AnalyticsEvents.spaceCreated(
            workspaceId: e.workspaceId,
            spaceId: e.spaceId,
          ),
        ),
      )
      ..add(
        _on<RepoAdded>(
          (e) => AnalyticsEvents.repoAdded(
            workspaceId: e.workspaceId,
            repoId: e.repoId,
          ),
        ),
      )
      ..add(
        _on<TicketCreated>(
          (e) => AnalyticsEvents.ticketCreated(
            workspaceId: e.workspaceId,
            ticketId: e.ticketId,
          ),
        ),
      )
      ..add(
        _on<AgentAwaitingInput>(
          (e) => AnalyticsEvents.agentAwaitingInput(
            kind: e.kind.wire,
            workspaceId: e.workspaceId,
            agentId: e.agentId,
            conversationId: e.conversationId,
          ),
        ),
      )
      ..add(
        _on<AgentActionBlocked>(
          (e) => AnalyticsEvents.agentActionBlocked(
            workspaceId: e.workspaceId,
            agentId: e.agentId,
            spaceId: e.spaceId,
            source: e.source,
          ),
        ),
      )
      ..add(
        _eventBus.on<PipelineRunCompleted>().listen(
          (e) => unawaited(
            _pipelineFinished(
              e.workspaceId,
              e.pipelineRunId,
              e.templateId,
              'completed',
            ),
          ),
        ),
      )
      ..add(
        _eventBus.on<PipelineRunFailed>().listen(
          (e) => unawaited(
            _pipelineFinished(
              e.workspaceId,
              e.pipelineRunId,
              e.templateId,
              'failed',
            ),
          ),
        ),
      )
      ..add(
        _eventBus.on<PipelineRunCancelled>().listen(
          (e) => unawaited(
            _pipelineFinished(
              e.workspaceId,
              e.pipelineRunId,
              e.templateId,
              'cancelled',
            ),
          ),
        ),
      )
      ..add(
        _on<TicketStatusChanged>(
          (e) => AnalyticsEvents.ticketStatusChanged(
            workspaceId: e.workspaceId,
            ticketId: e.ticketId,
            from: _ticketStatus(e.from),
            to: _ticketStatus(e.to),
          ),
        ),
      )
      ..add(
        _on<TicketAssigned>(
          (e) => AnalyticsEvents.ticketAssigned(
            workspaceId: e.workspaceId,
            ticketId: e.ticketId,
            assigneeType: e.assigneeType,
            agentId: e.assignedAgentId,
            teamId: e.assignedTeamId,
          ),
        ),
      )
      ..add(
        _on<TicketReassigned>(
          (e) => AnalyticsEvents.ticketReassigned(
            workspaceId: e.workspaceId,
            ticketId: e.ticketId,
            fromAgentId: e.fromAgentId,
            toAgentId: e.toAgentId,
          ),
        ),
      )
      ..add(
        _on<TicketCompleted>(
          (e) => AnalyticsEvents.ticketWorkFinished(
            ticketId: e.ticketId,
            outcome: 'completed',
          ),
        ),
      )
      ..add(
        _on<TicketFailed>(
          (e) => AnalyticsEvents.ticketWorkFinished(
            ticketId: e.ticketId,
            outcome: 'failed',
          ),
        ),
      )
      ..add(
        _on<TicketCancelled>(
          (e) => AnalyticsEvents.ticketWorkFinished(
            ticketId: e.ticketId,
            outcome: 'cancelled',
          ),
        ),
      )
      ..add(
        _on<SpaceDeleted>(
          (e) => AnalyticsEvents.spaceDeleted(
            workspaceId: e.workspaceId,
            spaceId: e.spaceId,
          ),
        ),
      )
      ..add(
        _on<WorkspaceMemberAdded>(
          (e) => AnalyticsEvents.workspaceMemberChanged(
            workspaceId: e.workspaceId,
            memberUserId: e.userId,
            change: 'added',
            role: e.role.name,
          ),
        ),
      )
      ..add(
        _on<WorkspaceMemberRemoved>(
          (e) => AnalyticsEvents.workspaceMemberChanged(
            workspaceId: e.workspaceId,
            memberUserId: e.userId,
            change: 'removed',
          ),
        ),
      )
      ..add(
        _on<WorkspaceMemberRoleChanged>(
          (e) => AnalyticsEvents.workspaceMemberChanged(
            workspaceId: e.workspaceId,
            memberUserId: e.userId,
            change: 'role_changed',
            role: e.role.name,
          ),
        ),
      )
      ..add(
        _on<RigClosedEvent>(
          (e) => AnalyticsEvents.rigClosed(
            workspaceId: e.workspaceId,
            rigId: e.rigId,
            reason: e.reason.name,
            reaped: false,
          ),
        ),
      )
      ..add(
        _on<RigReaped>(
          (e) => AnalyticsEvents.rigClosed(
            workspaceId: e.workspaceId,
            rigId: e.rigId,
            reason: e.reason.name,
            reaped: true,
            agentId: e.agentId,
          ),
        ),
      )
      ..add(
        _on<SkillUpdated>(
          (e) => AnalyticsEvents.skillUpdated(
            workspaceId: e.workspaceId,
            skillSlug: e.slug,
            origin: e.origin,
            scanVerdict: e.scanVerdict?.wire,
          ),
        ),
      )
      ..add(
        _on<CalendarAuthExpired>(
          (e) =>
              AnalyticsEvents.calendarAuthExpired(workspaceId: e.workspaceId),
        ),
      )
      ..add(
        _on<MeetingStartingSoon>(
          (e) => AnalyticsEvents.calendarMeetingStartingSoon(
            workspaceId: e.workspaceId,
            calendarEventId: e.eventId,
            hasMeetingLink: (e.meetingUrl ?? '').isNotEmpty,
            leadS: e.startTime.difference(e.occurredAt).inSeconds,
          ),
        ),
      )
      ..add(
        _on<BudgetThresholdCrossed>(
          (e) => AnalyticsEvents.budgetThresholdCrossed(
            scopeType: e.scopeType,
            scopeId: e.scopeId,
            spentCents: e.spentCents,
            budgetCents: e.budgetCents,
            hardStop: e.isHardStop,
          ),
        ),
      )
      ..add(
        _on<PrReviewRequested>(
          (e) => AnalyticsEvents.pullRequestReviewRequested(
            workspaceId: e.workspaceId,
            repoFullName: '${e.repoOwner}/${e.repoName}',
          ),
        ),
      )
      ..add(
        _on<PrReviewDecisionChanged>(
          (e) => AnalyticsEvents.pullRequestReviewDecisionChanged(
            workspaceId: e.workspaceId,
            repoFullName: '${e.repoOwner}/${e.repoName}',
            decision: e.decision,
            reviewersRemaining: e.reviewersRemaining,
          ),
        ),
      )
      ..add(
        _on<ExternalPrMerged>(
          (e) => AnalyticsEvents.externalPullRequestMerged(
            workspaceId: e.workspaceId,
            repoFullName: '${e.repoOwner}/${e.repoName}',
          ),
        ),
      )
      ..add(
        _on<PullRequestPublished>(
          (e) => AnalyticsEvents.pullRequestPublished(
            workspaceId: e.workspaceId,
            prId: e.prId,
          ),
        ),
      )
      ..add(
        _on<PrMerged>(
          (e) => AnalyticsEvents.pullRequestMerged(
            workspaceId: e.workspaceId,
            prId: e.prId,
            agentId: e.agentId,
          ),
        ),
      )
      ..add(
        _on<MeetingRecordingStopped>(
          (e) => AnalyticsEvents.meetingRecorded(
            workspaceId: e.workspaceId,
            meetingId: e.meetingId,
            transcriptChars: e.transcript.length,
          ),
        ),
      )
      ..add(
        _eventBus.on<AgentRunCompleted>().listen(
          (e) => unawaited(_runCompleted(e)),
        ),
      );
  }

  /// Measures `server_started.startup_ms` from construction, which
  /// [startServerTelemetry] does right after the global database opens.
  final _bootClock = Stopwatch()..start();

  /// Records that boot finished, with the install's workspace count. Never
  /// throws; a failed count is logged.
  void reportStarted(WorkspaceRepository workspaces) {
    final startupMs = _bootClock.elapsedMilliseconds;
    unawaited(
      workspaces.getAll().then(
        (all) =>
            serverStarted(workspaceCount: all.length, startupMs: startupMs),
        onError: (Object e) => _log('analytics: workspace count failed: $e'),
      ),
    );
  }

  /// Records that boot finished.
  void serverStarted({required int workspaceCount, required int startupMs}) {
    if (_optedOut) {
      return;
    }
    _analytics.track(
      AnalyticsEvents.serverStarted(
        workspaceCount: workspaceCount,
        startupMs: startupMs,
      ),
    );
  }

  /// Unsubscribes and gives queued records one delivery attempt.
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _analytics.dispose();
  }

  StreamSubscription<T> _on<T extends DomainEvent>(
    AnalyticsEvent Function(T event) map,
  ) => _eventBus.on<T>().listen((event) {
    try {
      _analytics.track(map(event));
    } on Object catch (e) {
      _log('analytics: could not map $T: $e');
    }
  });

  Future<void> _pipelineFinished(
    String workspaceId,
    String runId,
    String templateId,
    String outcome,
  ) async {
    PipelineRun? run;
    if (_analytics.isCollecting) {
      try {
        run = await _pipelineRuns.getRun(runId);
      } on Object catch (e) {
        _log('analytics: pipeline run lookup failed: $e');
      }
      // The event names the workspace; a run routed elsewhere is not this one.
      if (run != null && run.workspaceId != workspaceId) {
        run = null;
      }
    }
    final finishedAt = run?.finishedAt;
    _analytics.track(
      AnalyticsEvents.pipelineRunFinished(
        workspaceId: workspaceId,
        pipelineRunId: runId,
        templateId: templateId,
        outcome: outcome,
        trigger: run == null
            ? null
            : AnalyticsEvents.pipelineTriggerKind(run.triggerEventType),
        durationMs: run != null && finishedAt != null
            ? finishedAt.difference(run.startedAt).inMilliseconds
            : null,
        activeMs: run?.activeMs,
        attemptCount: run?.attemptCount,
        templateVersion: run?.templateVersion,
        costCents: run?.totalCostCents,
        tokens: run?.totalTokens,
        dryRun: run?.dryRun,
        subPipeline: run == null ? null : run.parentPipelineRunId != null,
      ),
    );
  }

  /// A `TicketStatus` storage name, or `other` for anything unrecognized.
  static String _ticketStatus(String raw) =>
      TicketStatus.values.any((s) => s.name == raw) ? raw : 'other';

  Future<void> _runCompleted(AgentRunCompleted event) async {
    AgentRunLog? run;
    final workspaceId = event.workspaceId;
    final runId = event.runId;
    if (workspaceId != null && runId != null && _analytics.isCollecting) {
      try {
        run = await _runLogs.getById(workspaceId, runId);
      } on Object catch (e) {
        _log('analytics: run log lookup failed: $e');
      }
    }
    final cost = run?.cost;
    final completedAt = run?.completedAt;
    _analytics.track(
      AnalyticsEvents.agentRunCompleted(
        agentId: event.agentId,
        workspaceId: workspaceId,
        conversationId: event.conversationId,
        runId: runId,
        status: run?.status.name,
        errorFamily: run?.errorFamily?.name,
        role: run?.role.name,
        adapter: run?.adapter,
        model: run?.modelId,
        effort: run?.effort,
        taskFamily: run?.taskFamily,
        subagent: run == null ? null : run.parentRunId != null,
        pipeline: run == null ? null : run.pipelineRunId != null,
        resumedNativeSession: run?.resumedNativeSession,
        durationMs:
            cost?.durationMs ??
            (run != null && completedAt != null
                ? completedAt.difference(run.startedAt).inMilliseconds
                : null),
        timeToFirstTokenMs: cost?.timeToFirstTokenMs,
        inputTokens: cost?.inputTokens,
        outputTokens: cost?.outputTokens,
        thoughtTokens: cost?.thoughtTokens,
        cacheReadTokens: cost?.cachedReadTokens,
        cacheWriteTokens: cost?.cachedWriteTokens,
        outputRejections: run?.outputRejections,
        costUsd: cost?.costUsd,
      ),
    );
  }

  /// The [consoledonottrack.com](https://consoledonottrack.com) convention.
  static bool _doNotTrack(Map<String, String> env) =>
      _truthy(env['DO_NOT_TRACK']);
}

/// Whether `CC_ANALYTICS_DEBUG` in [env] (the process environment layered
/// over `.env`) lets debug and profile builds send usage analytics.
bool analyticsDebugBuildsAllowed(Map<String, String> env) =>
    _truthy(env['CC_ANALYTICS_DEBUG']);

bool _truthy(String? raw) {
  final value = raw?.trim().toLowerCase();
  return value != null && value.isNotEmpty && value != '0' && value != 'false';
}
