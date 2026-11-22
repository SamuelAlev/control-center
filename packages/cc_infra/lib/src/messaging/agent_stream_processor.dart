import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show AppException;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/ports/git_snapshot_port.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart'
    show DeletedWorkspaceException;
import 'package:cc_domain/core/domain/services/active_stream_registry.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/core/domain/value_objects/usage_scope.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/observability/domain/run_stage.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/dispatch/goal_activity.dart';
import 'package:cc_infra/src/messaging/conversation_compaction_service.dart';
import 'package:cc_infra/src/messaging/json_content_extractor.dart';
import 'package:cc_infra/src/messaging/transcript_folder.dart';

class _StreamContext {
  _StreamContext({
    required this.agentDispatchService,
    required this.repo,
    required this.streamRegistry,
    required this.embeddingPort,
    required this.eventBus,
    required this.workspaceId,
    required this.spaceId,
    required this.agentId,
    required this.agentName,
    required this.messageId,
    required this.dispatchResult,
    this.conversationId,
    this.workingDirectory,
    this.snapshotStartFuture,
    this.spaceKind,
    this.requestedByUserId,
    this.onTurnCompleted,
  });

  final AgentDispatchService agentDispatchService;
  final MessagingRepository repo;
  final ActiveStreamRegistry streamRegistry;
  final EmbeddingPort? embeddingPort;
  final DomainEventBus? eventBus;

  /// Workspace owning the space this turn is streamed into — it selects the
  /// database every transcript write lands in.
  final String workspaceId;
  final String spaceId;
  final String agentId;
  final String agentName;
  final String messageId;

  /// Conversation the turn is posted into — carried onto its
  /// `MessageReceived` so the notification opens that conversation, not the
  /// space's standing one. Null when it could not be resolved.
  final String? conversationId;
  final AgentDispatchResult dispatchResult;

  /// Folds the event stream into the ordered transcript. Wired in
  /// [AgentStreamProcessor.processStream] to broadcast every update on the live
  /// registry and mark the persisted row dirty.
  late final TranscriptFolder folder;

  /// Worktree the turn runs in, for per-turn git snapshots (null = no snapshot).
  final String? workingDirectory;

  /// The human on whose behalf this run executed, when known (PRD 16 §7):
  /// carried onto the turn's completion `MessageReceived` notification so a
  /// receiver can suppress "someone else's agent run finished" pings.
  final String? requestedByUserId;

  /// In-flight capture of the pre-turn git snapshot, awaited at finalization.
  final Future<String?>? snapshotStartFuture;

  /// The kind of [spaceId], looked up when the turn starts so the finished
  /// turn's notification can say it landed in an agent-only space without a
  /// read on the finalization path. Null when it could not be resolved.
  final Future<SpaceKind?>? spaceKind;

  /// Called once with the final text when a turn finishes CLEANLY with real
  /// content — the seam the owning service reacts to (waking the teammates the
  /// turn `@mentioned`). A callback rather than a direct call because the
  /// reaction needs the space roster and the dispatch chain, which live a layer
  /// up; injecting the service here would be a cycle.
  final Future<void> Function(String content)? onTurnCompleted;

  /// Captured pre-turn git ref, resolved once [snapshotStartFuture] completes.
  String? snapshotStart;

  /// Captured post-turn git ref.
  String? snapshotEnd;

  bool sawDone = false;

  /// Terminal outcome carried by the DoneEvent when the run ended cleanly but
  /// unfinished (e.g. the harness hit its turn ceiling). Takes precedence over
  /// the plain `sawDone → completed` mapping.
  TurnOutcome? doneOutcome;

  /// Why the run ended, when the session decided it (carried by the
  /// DoneEvent): a stop, the cost cap, the watchdog, a usage limit.
  RunEndReason? doneEndReason;

  /// The provider's reset time for a usage-limit end (from the DoneEvent).
  DateTime? doneLimitResetsAt;

  /// Observed stage boundaries, earliest-per-stage. `submitted` is stamped when
  /// the stream opens; everything else is folded from [StageTimingEvent]s or
  /// from the first event the processor itself can see.
  RunLatencyProfile latency = RunLatencyProfile.empty;

  /// Additive usage totals (each reported delta summed).
  RunCost accumulatedCost = RunCost.zero;

  /// The LAST absolute whole-run snapshot, when the adapter reports cumulative
  /// totals (a CLI whose ledger covers the whole process, resumed runs
  /// included). When present it SUPERSEDES [accumulatedCost]: adding an absolute
  /// total to the deltas that produced it is how a resumed run's spend doubled
  /// on every turn.
  RunCost? cumulativeCost;

  /// The adapter's native session id for this run, when it reported one.
  String? nativeSessionId;

  /// Whether the run resumed the native session rather than starting fresh.
  bool resumedNativeSession = false;

  /// The newest provider-reported context reading, persisted on the turn as
  /// `metadata['context']` so the meter shows what the model actually holds.
  ContextWindowEvent? contextReading;
  Timer? dbFlushTimer;
  bool dbDirty = false;

  /// Message text last written by a mid-turn flush. Unchanged text is left
  /// out of the next flush so a tool-only update does not reindex search.
  String? flushedText;

  /// When the row first became stale after the last flush — drives the
  /// structural-debounce max-latency guard.
  DateTime? dirtySince;
  bool finalized = false;
}

/// Transforms a live agent process event stream into a single ordered
/// transcript message, persisting and broadcasting segment updates as they
/// happen.
class AgentStreamProcessor {
  /// Creates an [AgentStreamProcessor].
  AgentStreamProcessor({
    required this._agentDispatchService,
    required this._repo,
    required this._streamRegistry,
    this._embeddingPort,
    this._eventBus,
    this._compactionService,
    this._snapshotPort,
    this._flushMessage,
    this._toolActivity,
  });

  final AgentDispatchService _agentDispatchService;
  final MessagingRepository _repo;
  final ActiveStreamRegistry _streamRegistry;
  final EmbeddingPort? _embeddingPort;
  final DomainEventBus? _eventBus;
  final ConversationCompactionService? _compactionService;
  final GitSnapshotPort? _snapshotPort;

  /// Where a finished run's tool calls are kept for the goal supervisor's
  /// progress check, recorded before the run settles.
  final RunToolActivity? _toolActivity;

  /// Writes one flush of the turn: only the transcript segments that changed
  /// since the previous flush (`changedSegments`, by position), the
  /// transcript's length, and the message row (its metadata only when
  /// `writeMetadata`, so a tool-only flush does not rebuild the open chat).
  ///
  /// Null keeps [MessagingRepository.updateMessage] with the whole transcript
  /// as `metadata['segments']` on every flush.
  final Future<void> Function(
    String workspaceId,
    String messageId, {
    String? content,
    required Map<String, dynamic> metadata,
    required Map<int, Map<String, dynamic>> changedSegments,
    required int segmentCount,
    required bool writeMetadata,
  })?
  _flushMessage;

  final _contentExtractor = const JsonContentExtractor();

  /// Starts streaming agent events into the transcript message [messageId]
  /// inside [workspaceId] — the workspace that owns [spaceId] and therefore
  /// the database every transcript write lands in.
  void processStream({
    required Stream<AgentProcessEvent> stream,
    required AgentDispatchResult dispatchResult,
    required String workspaceId,
    required String spaceId,
    required String agentId,
    required String agentName,
    required String messageId,
    String? conversationId,
    String? workingDirectory,
    String? requestedByUserId,
    Future<void> Function(String content)? onTurnCompleted,
  }) {
    // Capture the pre-turn working-tree snapshot now (best-effort) so a later
    // revert can roll the filesystem back to this point.
    final snapshotStartFuture =
        (_snapshotPort != null && workingDirectory != null)
        ? _snapshotPort.capture(workingDirectory)
        : null;

    final ctx = _StreamContext(
      agentDispatchService: _agentDispatchService,
      repo: _repo,
      streamRegistry: _streamRegistry,
      embeddingPort: _embeddingPort,
      eventBus: _eventBus,
      workspaceId: workspaceId,
      spaceId: spaceId,
      agentId: agentId,
      agentName: agentName,
      messageId: messageId,
      conversationId: conversationId,
      dispatchResult: dispatchResult,
      workingDirectory: workingDirectory,
      snapshotStartFuture: snapshotStartFuture,
      spaceKind: _spaceKindOf(workspaceId, spaceId),
      requestedByUserId: requestedByUserId,
      onTurnCompleted: onTurnCompleted,
    );
    ctx.folder = TranscriptFolder(
      contentExtractor: _contentExtractor,
      onUpdate: (update, {required structural}) {
        ctx.streamRegistry.apply(ctx.messageId, update);
        _markDirty(ctx, structural: structural);
      },
    );
    // The run's own start is the only boundary the processor knows exactly, so
    // stamp it: every other stage's offset is measured from here.
    ctx.latency = ctx.latency.merge(
      const RunStageTiming(
        stage: RunStage.submitted,
        offsetMs: 0,
        source: RunTimingSource.harness,
      ),
    );

    stream.listen(
      (event) => _onEvent(ctx, event),
      onDone: () => unawaited(_finish(ctx, () => _onDone(ctx))),
      onError: (Object error) =>
          unawaited(_finish(ctx, () => _onError(ctx, error))),
    );
  }

  /// Runs a turn's last step, [finalize].
  ///
  /// A workspace deleted while its run was still streaming has no transcript
  /// left to write and no run log to close. The turn then ends in memory only:
  /// its live stream is released and nothing else is attempted.
  Future<void> _finish(
    _StreamContext ctx,
    Future<void> Function() finalize,
  ) async {
    try {
      await finalize();
    } on DeletedWorkspaceException {
      await ctx.streamRegistry.unregister(ctx.messageId);
    }
  }

  // Event handling

  void _onEvent(_StreamContext ctx, AgentProcessEvent event) {
    switch (event) {
      case StageTimingEvent():
        // An adapter/transport-observed boundary. Folded, never derived: the
        // earliest observation of a stage wins, so the processor's own coarse
        // text-derived boundary never overwrites a real provider measurement.
        ctx.latency = ctx.latency.merge(event.toTiming());
        return;
      case TextEvent():
        _noteStage(
          ctx,
          RunStage.firstModelDelta,
          event,
          RunTimingSource.adapter,
        );
        if (event.content.trim().isNotEmpty) {
          _noteStage(
            ctx,
            RunStage.firstUsefulText,
            event,
            RunTimingSource.harness,
          );
        }
      case ThinkingEvent():
        // Reasoning output IS a model delta: a thinking-first run has started
        // producing while "time to first text" is still unset.
        _noteStage(
          ctx,
          RunStage.firstModelDelta,
          event,
          RunTimingSource.adapter,
        );
      case ToolCallEvent():
        // A tool call is useful work. Waiting for assistant prose to call a run
        // "started" is what made a tool-first turn look like it had not begun.
        _noteStage(
          ctx,
          RunStage.firstUsefulText,
          event,
          RunTimingSource.harness,
        );
      case UsageEvent():
        _applyUsage(ctx, event);
        return;
      case ContextWindowEvent():
        ctx.contextReading = event;
        // Not structural: a reading changes no bubble, it only needs to reach
        // the stored row on the next delta flush so the meter moves mid-turn.
        _markDirty(ctx, structural: false);
        return;
      case DebugEvent():
        // Diagnostics live in the NDJSON run log, never the transcript.
        return;
      case DoneEvent(
        outcome: final doneOutcome,
        :final endReason,
        :final limitResetsAt,
      ):
        ctx.sawDone = true;
        ctx.doneOutcome = doneOutcome;
        ctx.doneEndReason = endReason;
        ctx.doneLimitResetsAt = limitResetsAt;
        return;
      default:
        break;
    }
    ctx.folder.add(event);
  }

  /// Folds a boundary the PROCESSOR observed (as opposed to one an adapter
  /// reported), keeping the earliest offset per stage.
  void _noteStage(
    _StreamContext ctx,
    RunStage stage,
    AgentProcessEvent event,
    RunTimingSource source,
  ) {
    ctx.latency = ctx.latency.merge(
      RunStageTiming(
        stage: stage,
        offsetMs: _offsetMs(ctx, event.timestamp),
        source: source,
      ),
    );
  }

  /// Milliseconds from run start to [at]. Negative is clamped to 0: a clock
  /// step or an out-of-order event must not produce a negative latency that
  /// then drags a percentile below zero.
  static int _offsetMs(_StreamContext ctx, DateTime at) {
    final delta = at
        .difference(ctx.dispatchResult.runLog.startedAt)
        .inMilliseconds;
    return delta < 0 ? 0 : delta;
  }

  /// Folds a usage report into the turn's totals.
  ///
  /// The SCOPE decides how: an additive report ([UsageScope.request] /
  /// [UsageScope.turn]) sums, while an absolute [UsageScope.runCumulative]
  /// snapshot REPLACES the cumulative total (last reading wins). Treating the
  /// latter as additive inflated a resumed CLI run's cost on every turn —
  /// exactly the accounting bug that made the harness look cheap.
  void _applyUsage(_StreamContext ctx, UsageEvent event) {
    // Lineage travels on the usage report because that is what the adapter
    // already emits per result; it is persisted on the RUN, where the
    // evaluation's resume-vs-fresh stratum can query it.
    if (event.nativeSessionId != null) {
      ctx.nativeSessionId = event.nativeSessionId;
    }
    if (event.resumedNativeSession) {
      ctx.resumedNativeSession = true;
    }
    final reported = event.usage.toCost(durationMs: event.durationMs);
    if (event.scope == UsageScope.runCumulative) {
      // Keep the last absolute snapshot. A cumulative reading that arrives with
      // no duration leaves the earlier one's duration in place.
      final previous = ctx.cumulativeCost;
      ctx.cumulativeCost = reported.copyWith(
        durationMs: reported.durationMs ?? previous?.durationMs,
      );
      return;
    }
    ctx.accumulatedCost = ctx.accumulatedCost + reported;
  }

  /// The turn's authoritative cost: the absolute snapshot when the adapter
  /// reported one, else the summed deltas — with the provider latencies attached
  /// only where they were actually observed.
  RunCost _effectiveCost(_StreamContext ctx) {
    final base = ctx.cumulativeCost ?? ctx.accumulatedCost;
    return RunCost(
      inputTokens: base.inputTokens,
      outputTokens: base.outputTokens,
      thoughtTokens: base.thoughtTokens,
      cachedReadTokens: base.cachedReadTokens,
      cachedWriteTokens: base.cachedWriteTokens,
      costMicros: base.costMicros,
      costBasis: base.costBasis,
      durationMs: base.durationMs,
      // Provider TTFT/TTFB ONLY when a transport or provider actually observed
      // it. The old value was derived from the first text event and labelled a
      // latency it never measured.
      timeToFirstTokenMs:
          ctx.latency.transportTtfbMs ?? ctx.latency.providerTtftMs,
    );
  }

  void _markDirty(_StreamContext ctx, {required bool structural}) {
    ctx.dbDirty = true;
    final now = DateTime.now();
    ctx.dirtySince ??= now;
    if (structural) {
      // Max-latency guard: a tool-heavy turn re-arms the trailing debounce
      // continuously; force a flush once staleness exceeds the bound.
      if (now.difference(ctx.dirtySince!) >= kStructuralFlushMaxLatency) {
        ctx.dbFlushTimer?.cancel();
        ctx.dbFlushTimer = null;
        _flushDb(ctx);
        return;
      }
      ctx.dbFlushTimer?.cancel();
      ctx.dbFlushTimer = Timer(kStructuralFlushDelay, () {
        ctx.dbFlushTimer = null;
        _flushDb(ctx);
      });
    } else {
      ctx.dbFlushTimer ??= Timer(kDeltaFlushInterval, () {
        ctx.dbFlushTimer = null;
        _flushDb(ctx);
      });
    }
  }

  // Finalization

  Future<void> _onDone(_StreamContext ctx) async {
    if (ctx.finalized) {
      return;
    }
    ctx.finalized = true;
    ctx.dbFlushTimer?.cancel();
    ctx.dbFlushTimer = null;

    final now = DateTime.now();
    ctx.folder.closeOpenText(now);
    ctx.folder.interruptRunningTools(now);

    final content = ctx.folder.currentText();
    // A trailing error fails the turn even after progress prose. The folder
    // ignores errors followed by a recovered answer.
    final failure = ctx.folder.terminalFailure();
    final outcome = failure != null
        ? TurnOutcome.failed
        : (ctx.doneOutcome ??
              (ctx.sawDone ? TurnOutcome.completed : TurnOutcome.interrupted));
    final runLog = ctx.dispatchResult.runLog;

    await _resolveSnapshot(ctx);
    await _writeFinal(
      ctx,
      // A failed turn SAYS why. `currentText()` collects text segments only, so
      // a run that died before answering anything (`claude exited with code 1`,
      // a refusal, a spawn failure) persisted an empty string: the reader got a
      // blank agent bubble with a failed badge and no reason anywhere on the
      // surface, and the only account of what happened lived in the run log.
      content: content.isEmpty ? failure ?? content : content,
      metadata: {
        ..._finalMetadata(ctx, outcome: outcome, now: now),
        // The same shape `_onError` writes, so the bubble's existing failed
        // badge + scoped retry light up with no client change.
        if (failure != null) ...{
          'error': true,
          'runId': runLog.id,
          if (runLog.errorFamily != null)
            'errorFamily': runLog.errorFamily!.name,
        },
      },
    );

    ctx.streamRegistry.apply(
      ctx.messageId,
      TurnFinished(ctx.folder.length - 1, outcome),
    );
    await ctx.streamRegistry.unregister(ctx.messageId);

    _recordToolActivity(ctx);
    if (failure != null) {
      await ctx.agentDispatchService.failRun(
        runLog,
        failure,
        endReason: ctx.doneEndReason ?? RunEndReason.error,
        cost: _effectiveCost(ctx),
        errorCode: ctx.folder.terminalFailureCode(),
        limitResetsAt: ctx.doneLimitResetsAt,
      );
    } else {
      await ctx.agentDispatchService.completeRun(
        runLog,
        content.isNotEmpty ? content.split('\n').first : null,
        endReason: ctx.doneEndReason ?? RunEndReason.completed,
        cost: _effectiveCost(ctx),
        latency: ctx.latency,
        nativeSessionId: ctx.nativeSessionId,
        resumedNativeSession: ctx.resumedNativeSession,
      );
    }

    await _runContextMaintenance(ctx, ctx.dispatchResult.agent?.contextSize);
    // Only real answer text is embedded — error prose is not knowledge.
    _embedAssistantResponse(ctx, content);
    // Fall back to the failure text so the notification says what went wrong
    // instead of arriving with an empty body.
    await _notifyMessageReceived(
      ctx,
      content: content.isNotEmpty ? content : (failure ?? ''),
      // A schedule or watch run that finished cleanly stays quiet; one that
      // failed, stopped or hit a limit tells its person.
      quiet:
          ctx.dispatchResult.quiet &&
          failure == null &&
          outcome == TurnOutcome.completed &&
          (ctx.doneEndReason ?? RunEndReason.completed) ==
              RunEndReason.completed,
    );
    _notifyTurnCompleted(
      ctx,
      outcome: outcome,
      failure: failure,
      content: content,
    );
  }

  /// Hands a cleanly-finished turn's text to the owner (see
  /// [_StreamContext.onTurnCompleted]).
  ///
  /// Only a turn that ran to completion qualifies: a failed or interrupted one
  /// stopped mid-thought, and acting on half a sentence — waking whoever it had
  /// named so far — is worse than doing nothing. Fire-and-forget and fully
  /// swallowed, because this runs after the turn is already persisted and
  /// completed: a reaction that threw here would surface as an unhandled async
  /// error against a turn that actually succeeded.
  void _notifyTurnCompleted(
    _StreamContext ctx, {
    required TurnOutcome outcome,
    required String? failure,
    required String content,
  }) {
    final onCompleted = ctx.onTurnCompleted;
    if (onCompleted == null ||
        failure != null ||
        outcome != TurnOutcome.completed ||
        content.trim().isEmpty) {
      return;
    }
    try {
      unawaited(onCompleted(content).catchError((Object _) {}));
    } catch (_) {
      // A synchronous throw from the callback is swallowed for the same reason.
    }
  }

  /// Awaits the in-flight pre-turn snapshot and captures the post-turn one, so
  /// the turn can record `snapshot.start`/`snapshot.end`. Best-effort: any
  /// failure leaves the refs null and the turn proceeds without a snapshot.
  Future<void> _resolveSnapshot(_StreamContext ctx) async {
    final port = _snapshotPort;
    final wd = ctx.workingDirectory;
    if (port == null || wd == null) {
      return;
    }
    try {
      ctx.snapshotStart = await ctx.snapshotStartFuture;
      ctx.snapshotEnd = await port.capture(wd);
    } catch (_) {
      // Snapshots are best-effort; never fail the turn over them.
    }
  }

  /// Keeps the run's tool calls for the goal supervisor, before the run's
  /// settlement announces its end.
  void _recordToolActivity(_StreamContext ctx) => _toolActivity?.recordSegments(
    workspaceId: ctx.workspaceId,
    runId: ctx.dispatchResult.runLog.id,
    segments: ctx.folder.segments,
  );

  Future<void> _onError(_StreamContext ctx, Object error) async {
    if (ctx.finalized) {
      return;
    }
    ctx.finalized = true;
    ctx.dbFlushTimer?.cancel();
    ctx.dbFlushTimer = null;

    final now = DateTime.now();
    ctx.folder.closeOpenText(now);
    ctx.folder.interruptRunningTools(now);
    ctx.folder.appendUnreported(
      ErrorSegment(message: error.toString(), startedAt: now),
    );

    final text = ctx.folder.currentText();
    // Same rule as the done path: the error is what there is to read when the
    // turn produced nothing.
    final content = text.isEmpty
        ? (ctx.folder.terminalFailure() ?? error.toString())
        : text;
    final runLog = ctx.dispatchResult.runLog;

    await _writeFinal(
      ctx,
      content: content,
      metadata: {
        ..._finalMetadata(ctx, outcome: TurnOutcome.failed, now: now),
        // Correlate the failed turn to its run so the bubble can offer a
        // scoped retry and surface the failure family.
        'error': true,
        'runId': runLog.id,
        if (runLog.errorFamily != null) 'errorFamily': runLog.errorFamily!.name,
      },
    );

    ctx.streamRegistry.apply(
      ctx.messageId,
      TurnFinished(ctx.folder.length - 1, TurnOutcome.failed),
    );
    await ctx.streamRegistry.unregister(ctx.messageId);

    _recordToolActivity(ctx);
    await ctx.agentDispatchService.failRun(
      runLog,
      error.toString(),
      endReason: ctx.doneEndReason ?? RunEndReason.error,
      cost: _effectiveCost(ctx),
      errorCode: error is AppException ? error.code : null,
      limitResetsAt: ctx.doneLimitResetsAt,
    );
    // The turn's message is the only "agent finished" notification, so a
    // crashed turn still sends one — carrying what went wrong.
    await _notifyMessageReceived(ctx, content: content);
  }

  Map<String, dynamic> _finalMetadata(
    _StreamContext ctx, {
    required TurnOutcome outcome,
    required DateTime now,
  }) {
    final durationMs = now
        .difference(ctx.dispatchResult.runLog.startedAt)
        .inMilliseconds;
    final cost = _effectiveCost(ctx);
    final usefulWorkMs = ctx.latency.timeToFirstUsefulWorkMs;
    final ttfbMs = ctx.latency.transportTtfbMs;
    return {
      'agentName': ctx.agentName,
      'streamComplete': true,
      'outcome': turnOutcomeToString(outcome),
      // Thin clients receive list rows without segments; this keeps their
      // context-window estimates accurate (TokenEstimator.estimateMessage).
      'transcriptChars': ctx.folder.transcriptChars,
      'context': ?_contextMetadata(ctx),
      'turn': {
        'durationMs': durationMs,
        'totalTokens': cost.totalTokens,
        'costMicros': cost.costMicros,
        // Exact precision + provenance: without these the turn's cost is only
        // available rounded to a cent and with no way to tell an estimate from
        // a billed, provider-reported figure.
        if (cost.costMicros != 0) 'costMicros': cost.costMicros,
        if (cost.costBasis != CostBasis.estimated)
          'costBasis': cost.costBasis.name,
        // Latency boundaries that were actually observed. A stage that never
        // reported is absent rather than zero.
        'ttfbMs': ?ttfbMs,
        'timeToFirstUsefulWorkMs': ?usefulWorkMs,
      },
      if (ctx.snapshotStart != null || ctx.snapshotEnd != null)
        'snapshot': {
          if (ctx.snapshotStart != null) 'start': ctx.snapshotStart,
          if (ctx.snapshotEnd != null) 'end': ctx.snapshotEnd,
        },
    };
  }

  /// `metadata['context']` for the turn, or null before the runner reported
  /// a reading. The DAO stamps `tokens` and `window` into their own columns.
  Map<String, dynamic>? _contextMetadata(_StreamContext ctx) {
    final reading = ctx.contextReading;
    if (reading == null) {
      return null;
    }
    return {
      'tokens': reading.contextTokens,
      'window': ?reading.windowTokens,
      if (reading.compactions > 0) 'compactions': reading.compactions,
    };
  }

  void _flushDb(_StreamContext ctx) {
    if (!ctx.dbDirty || ctx.finalized) {
      return;
    }
    ctx.dbDirty = false;
    ctx.dirtySince = null;
    final text = ctx.folder.currentText();
    // Assigning `content` reindexes the row even when the text did not
    // change. Tool flushes only grow the transcript, so skip that write.
    final textChanged = text != ctx.flushedText;
    ctx.flushedText = text;
    final metadata = <String, dynamic>{
      'agentName': ctx.agentName,
      'streamComplete': false,
      'transcriptChars': ctx.folder.transcriptChars,
      'context': ?_contextMetadata(ctx),
    };
    final flush = _flushMessage;
    if (flush == null) {
      ctx.repo.updateMessage(
        ctx.workspaceId,
        ctx.messageId,
        content: textChanged ? text : null,
        metadata: {
          ...metadata,
          'segments': encodeTranscript(ctx.folder.snapshot()),
        },
      );
      return;
    }
    // The open chat watches the message's metadata, not the transcript.
    // Rewriting it when only the transcript grew rebuilds every bubble.
    unawaited(
      flush(
        ctx.workspaceId,
        ctx.messageId,
        content: textChanged ? text : null,
        metadata: metadata,
        changedSegments: ctx.folder.takeChangedSegments(),
        segmentCount: ctx.folder.length,
        writeMetadata: textChanged,
      ).catchError((Object _) {
        // The segments this flush took were not stored: the next flush, or
        // the final write, stores them all again (rows whose body did not
        // change are not rewritten). A flush is crash insurance, never a
        // reason to fail the turn.
        ctx.folder.forgetFlushed();
      }),
    );
  }

  /// The turn's last write: [content], the final [metadata] and the
  /// transcript as it ended.
  Future<void> _writeFinal(
    _StreamContext ctx, {
    required String content,
    required Map<String, dynamic> metadata,
  }) {
    final flush = _flushMessage;
    if (flush == null) {
      return ctx.repo.updateMessage(
        ctx.workspaceId,
        ctx.messageId,
        content: content,
        metadata: {
          ...metadata,
          'segments': encodeTranscript(ctx.folder.snapshot()),
        },
      );
    }
    return flush(
      ctx.workspaceId,
      ctx.messageId,
      content: content,
      metadata: metadata,
      changedSegments: ctx.folder.takeChangedSegments(),
      segmentCount: ctx.folder.length,
      writeMetadata: true,
    );
  }

  // Side effects (unchanged behavior, single message id)

  void _embedAssistantResponse(_StreamContext ctx, String response) {
    final port = ctx.embeddingPort;
    if (port == null || !port.isReady || response.isEmpty) {
      return;
    }
    unawaited(_doEmbedMessage(ctx, ctx.messageId, response, port));
  }

  Future<void> _doEmbedMessage(
    _StreamContext ctx,
    String messageId,
    String content,
    EmbeddingPort port,
  ) async {
    try {
      final vec = await port.embed(content);
      await ctx.repo.updateMessageEmbedding(
        ctx.workspaceId,
        messageId,
        Uint8List.view(vec.buffer),
      );
    } catch (_) {}
  }

  /// Runs the anchored-compaction + tool-pruning maintenance pass after a turn
  /// finishes, against the window the turn's runner reported (the real one,
  /// e.g. a Claude Code `[1m]` variant) or else the agent's configured
  /// [contextSize] in tokens. No-op when no compaction service is wired or
  /// neither is known.
  Future<void> _runContextMaintenance(
    _StreamContext ctx,
    int? contextSize,
  ) async {
    final service = _compactionService;
    final windowTokens = ctx.contextReading?.windowTokens ?? contextSize;
    if (service == null || windowTokens == null) {
      return;
    }
    try {
      await service.maintain(
        workspaceId: ctx.workspaceId,
        spaceId: ctx.spaceId,
        contextWindowTokens: windowTokens,
        self: (id: ctx.agentId, name: ctx.agentName),
      );
    } catch (_) {
      // Compaction is best-effort maintenance; never fail the turn over it.
    }
  }

  /// The kind of the space a turn streams into; never throws.
  Future<SpaceKind?> _spaceKindOf(String workspaceId, String spaceId) async {
    try {
      return (await _repo.getSpaceById(workspaceId, spaceId))?.kind;
    } on Object {
      return null;
    }
  }

  Future<void> _notifyMessageReceived(
    _StreamContext ctx, {
    required String content,
    bool quiet = false,
  }) async {
    final bus = ctx.eventBus;
    if (bus == null) {
      return;
    }
    final kind = await ctx.spaceKind;

    // Stored content includes every progress update. Completion previews use
    // the last visible answer, not the opening narration; both terminal paths
    // have already closed the folder's text buffers before reaching here.
    var previewContent = content;
    final segments = ctx.folder.segments;
    for (var i = segments.length - 1; i >= 0; i--) {
      final segment = segments[i];
      if (segment is TextSegment) {
        final text = segment.text.trim();
        if (text.isNotEmpty) {
          previewContent = text;
          break;
        }
      }
    }
    final preview = previewContent.length > 120
        ? '${previewContent.substring(0, 120)}…'
        : previewContent;
    // Never ping about a message with nothing to say: a content-less turn used
    // to surface as a notification row with the agent's name and a blank body.
    // The run's own completion event still fires, so nothing is lost.
    if (preview.trim().isEmpty) {
      return;
    }

    bus.publish(
      MessageReceived(
        spaceId: ctx.spaceId,
        messageId: ctx.messageId,
        senderName: ctx.agentName,
        contentPreview: preview,
        isAgentMessage: true,
        // The sending agent owns the notification's workspace; agents always
        // belong to exactly one workspace, so this scopes agent-message
        // activity to the right workspace's dashboard feed.
        workspaceId: ctx.dispatchResult.agent?.workspaceId,
        requestedByUserId: ctx.requestedByUserId,
        conversationId: ctx.conversationId,
        inAgentOnlySpace: kind?.isAgentOnly ?? false,
        quietRun: quiet,
        occurredAt: DateTime.now(),
      ),
    );
  }
}
