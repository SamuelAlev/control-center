import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/ports/git_snapshot_port.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
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
    this.workingDirectory,
    this.snapshotStartFuture,
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
  DateTime? firstTokenAt;
  RunCost accumulatedCost = RunCost.zero;
  Timer? dbFlushTimer;
  bool dbDirty = false;

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
    required AgentDispatchService agentDispatchService,
    required MessagingRepository repo,
    required ActiveStreamRegistry streamRegistry,
    EmbeddingPort? embeddingPort,
    DomainEventBus? eventBus,
    ConversationCompactionService? compactionService,
    GitSnapshotPort? snapshotPort,
  }) : _agentDispatchService = agentDispatchService,
       _repo = repo,
       _streamRegistry = streamRegistry,
       _embeddingPort = embeddingPort,
       _eventBus = eventBus,
       _compactionService = compactionService,
       _snapshotPort = snapshotPort;

  final AgentDispatchService _agentDispatchService;
  final MessagingRepository _repo;
  final ActiveStreamRegistry _streamRegistry;
  final EmbeddingPort? _embeddingPort;
  final DomainEventBus? _eventBus;
  final ConversationCompactionService? _compactionService;
  final GitSnapshotPort? _snapshotPort;
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
      dispatchResult: dispatchResult,
      workingDirectory: workingDirectory,
      snapshotStartFuture: snapshotStartFuture,
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

    stream.listen(
      (event) => _onEvent(ctx, event),
      onDone: () => _onDone(ctx),
      onError: (error) => _onError(ctx, error),
    );
  }

  // ---------------------------------------------------------------------------
  // Event handling
  // ---------------------------------------------------------------------------

  void _onEvent(_StreamContext ctx, AgentProcessEvent event) {
    switch (event) {
      case TextEvent():
        ctx.firstTokenAt ??= event.timestamp;
      case UsageEvent():
        ctx.accumulatedCost =
            ctx.accumulatedCost +
            event.usage.toCost(
              durationMs: event.durationMs,
              timeToFirstTokenMs: ctx.firstTokenAt == null
                  ? null
                  : ctx.firstTokenAt!.millisecondsSinceEpoch -
                        ctx
                            .dispatchResult
                            .runLog
                            .startedAt
                            .millisecondsSinceEpoch,
            );
        return;
      case DebugEvent():
        // Diagnostics live in the NDJSON run log, never the transcript.
        return;
      case DoneEvent(outcome: final doneOutcome):
        ctx.sawDone = true;
        ctx.doneOutcome = doneOutcome;
        return;
      default:
        break;
    }
    ctx.folder.add(event);
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

  // ---------------------------------------------------------------------------
  // Finalization
  // ---------------------------------------------------------------------------

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
    // A turn that answered nothing and ended on an error DID fail, even though
    // the stream closed cleanly: an upstream refusal (e.g. the harness finding
    // no provider credential) emits an ErrorEvent and then a DoneEvent, so it
    // reaches `_onDone`, not `_onError`. Left as `completed` it produced an
    // empty bubble with a "was this helpful?" bar, a content-less notification,
    // and no retry affordance.
    final failure = content.isEmpty ? ctx.folder.terminalFailure() : null;
    final outcome = failure != null
        ? TurnOutcome.failed
        : (ctx.doneOutcome ??
              (ctx.sawDone ? TurnOutcome.completed : TurnOutcome.interrupted));
    final runLog = ctx.dispatchResult.runLog;

    await _resolveSnapshot(ctx);
    await ctx.repo.updateMessage(
      ctx.workspaceId,
      ctx.messageId,
      // A failed turn SAYS why. `currentText()` collects text segments only, so
      // a run that died before answering anything (`claude exited with code 1`,
      // a refusal, a spawn failure) persisted an empty string: the reader got a
      // blank agent bubble with a failed badge and no reason anywhere on the
      // surface, and the only account of what happened lived in the run log.
      content: failure ?? content,
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

    if (failure != null) {
      await ctx.agentDispatchService.failRun(runLog, failure);
    } else {
      await ctx.agentDispatchService.completeRun(
        runLog,
        content.isNotEmpty ? content.split('\n').first : null,
        cost: ctx.accumulatedCost,
      );
    }

    await _runContextMaintenance(ctx, ctx.dispatchResult.agent?.contextSize);
    // Only real answer text is embedded — error prose is not knowledge.
    _embedAssistantResponse(ctx, content);
    // Fall back to the failure text so the notification says what went wrong
    // instead of arriving with an empty body.
    _notifyMessageReceived(
      ctx,
      content: content.isNotEmpty ? content : (failure ?? ''),
    );
    _notifyTurnCompleted(ctx, outcome: outcome, failure: failure, content: content);
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

    await ctx.repo.updateMessage(
      ctx.workspaceId,
      ctx.messageId,
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

    await ctx.agentDispatchService.failRun(runLog, error.toString());
  }

  Map<String, dynamic> _finalMetadata(
    _StreamContext ctx, {
    required TurnOutcome outcome,
    required DateTime now,
  }) {
    final durationMs = now
        .difference(ctx.dispatchResult.runLog.startedAt)
        .inMilliseconds;
    return {
      'agentName': ctx.agentName,
      'streamComplete': true,
      'outcome': turnOutcomeToString(outcome),
      'segments': encodeTranscript(ctx.folder.snapshot()),
      // Thin clients receive list rows without segments; this keeps their
      // context-window estimates accurate (TokenEstimator.estimateMessage).
      'transcriptChars': ctx.folder.transcriptChars,
      'turn': {
        'durationMs': durationMs,
        'totalTokens': ctx.accumulatedCost.totalTokens,
        'costCents': ctx.accumulatedCost.estimatedCostCents,
      },
      if (ctx.snapshotStart != null || ctx.snapshotEnd != null)
        'snapshot': {
          if (ctx.snapshotStart != null) 'start': ctx.snapshotStart,
          if (ctx.snapshotEnd != null) 'end': ctx.snapshotEnd,
        },
    };
  }

  void _flushDb(_StreamContext ctx) {
    if (!ctx.dbDirty || ctx.finalized) {
      return;
    }
    ctx.dbDirty = false;
    ctx.dirtySince = null;
    ctx.repo.updateMessage(
      ctx.workspaceId,
      ctx.messageId,
      content: ctx.folder.currentText(),
      metadata: {
        'agentName': ctx.agentName,
        'streamComplete': false,
        'segments': ctx.folder.encodeForFlush(),
        'transcriptChars': ctx.folder.transcriptChars,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Side effects (unchanged behavior, single message id)
  // ---------------------------------------------------------------------------

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
  /// finishes. [contextSize] is CC's per-agent character budget; it is mapped
  /// to an estimated token window for the planner. No-op when no compaction
  /// service is wired or the agent has no configured context size.
  Future<void> _runContextMaintenance(
    _StreamContext ctx,
    int? contextSize,
  ) async {
    final service = _compactionService;
    if (service == null || contextSize == null) {
      return;
    }
    final windowTokens = TokenEstimator.instance.windowTokensFromChars(
      contextSize,
    );
    try {
      await service.maintain(
        workspaceId: ctx.workspaceId,
        spaceId: ctx.spaceId,
        contextWindowTokens: windowTokens,
        selfAgentName: ctx.agentName,
      );
    } catch (_) {
      // Compaction is best-effort maintenance; never fail the turn over it.
    }
  }

  void _notifyMessageReceived(_StreamContext ctx, {required String content}) {
    final bus = ctx.eventBus;
    if (bus == null) {
      return;
    }

    final preview = content.length > 120
        ? '${content.substring(0, 120)}…'
        : content;
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
        occurredAt: DateTime.now(),
      ),
    );
  }
}
