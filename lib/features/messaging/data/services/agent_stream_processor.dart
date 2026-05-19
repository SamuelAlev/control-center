import 'dart:async';
import 'dart:typed_data';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/messaging_events.dart';
import 'package:control_center/core/domain/ports/embedding_port.dart';
import 'package:control_center/core/domain/value_objects/run_cost.dart';
import 'package:control_center/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/core/domain/value_objects/transcript_update.dart';
import 'package:control_center/features/dispatch/data/services/agent_dispatch_service.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:control_center/features/messaging/data/services/active_stream_registry.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:control_center/shared/utils/json_content_extractor.dart';
import 'package:control_center/shared/utils/message_compactor.dart';

/// Flush delay after a structural change (segment open/close, atomic segment).
const Duration _structuralFlushDelay = Duration(milliseconds: 50);

/// Throttle window for delta-only changes. The UI reads the live registry, so
/// mid-run DB writes are purely crash-recovery insurance — a slow cadence is
/// plenty and avoids re-serializing the whole segment list on every token.
const Duration _deltaFlushInterval = Duration(milliseconds: 500);

class _StreamContext {
  _StreamContext({
    required this.agentDispatchService,
    required this.repo,
    required this.streamRegistry,
    required this.embeddingPort,
    required this.eventBus,
    required this.channelId,
    required this.agentId,
    required this.agentName,
    required this.messageId,
    required this.dispatchResult,
    required this.contentExtractor,
    required this.compactor,
  });

  final AgentDispatchService agentDispatchService;
  final MessagingRepository repo;
  final ActiveStreamRegistry streamRegistry;
  final EmbeddingPort? embeddingPort;
  final DomainEventBus? eventBus;
  final String channelId;
  final String agentId;
  final String agentName;
  final String messageId;
  final AgentDispatchResult dispatchResult;
  final JsonContentExtractor contentExtractor;
  final MessageCompactor compactor;

  /// Ordered transcript, mutated in place as events arrive.
  final segments = <TranscriptSegment>[];

  /// Index of the currently-open text or reasoning segment, or null.
  int? openTextIndex;

  /// Whether [openTextIndex] points at a reasoning (vs text) segment.
  bool openIsReasoning = false;

  /// Buffered text for the open text/reasoning segment.
  final openTextBuf = StringBuffer();

  /// Open tool segments keyed by their tool-call id (empty ids excluded).
  final openToolByCallId = <String, int>{};

  /// Fallback for results whose tool-call id is empty / unknown (legacy pi).
  int? lastOpenToolIndex;

  bool sawDone = false;
  DateTime? firstTokenAt;
  RunCost accumulatedCost = RunCost.zero;
  Timer? dbFlushTimer;
  bool dbDirty = false;
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
  })  : _agentDispatchService = agentDispatchService,
        _repo = repo,
        _streamRegistry = streamRegistry,
        _embeddingPort = embeddingPort,
        _eventBus = eventBus;

  final AgentDispatchService _agentDispatchService;
  final MessagingRepository _repo;
  final ActiveStreamRegistry _streamRegistry;
  final EmbeddingPort? _embeddingPort;
  final DomainEventBus? _eventBus;
  final _contentExtractor = const JsonContentExtractor();
  final _compactor = const MessageCompactor();

  /// Starts streaming agent events into the transcript message [messageId].
  void processStream({
    required Stream<AgentProcessEvent> stream,
    required AgentDispatchResult dispatchResult,
    required String channelId,
    required String agentId,
    required String agentName,
    required String messageId,
  }) {
    final ctx = _StreamContext(
      agentDispatchService: _agentDispatchService,
      repo: _repo,
      streamRegistry: _streamRegistry,
      embeddingPort: _embeddingPort,
      eventBus: _eventBus,
      channelId: channelId,
      agentId: agentId,
      agentName: agentName,
      messageId: messageId,
      dispatchResult: dispatchResult,
      contentExtractor: _contentExtractor,
      compactor: _compactor,
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
        _appendText(ctx, event, reasoning: false);
      case ThinkingEvent():
        _appendText(ctx, event, reasoning: true);
      case ToolCallEvent():
        _openTool(ctx, event);
      case ToolResultEvent():
        _applyToolResult(ctx, event);
      case ErrorEvent():
        _addAtomic(
          ctx,
          ErrorSegment(
            message: event.content,
            code: event.code,
            source: event.source,
            startedAt: event.timestamp,
          ),
        );
      case SandboxViolationEvent():
        _addAtomic(
          ctx,
          ViolationSegment(
            message: event.content,
            action: event.action,
            target: event.target,
            suggestedCapability: event.suggestedCapability,
            startedAt: event.timestamp,
          ),
        );
      case UsageEvent():
        ctx.accumulatedCost = ctx.accumulatedCost +
            event.usage.toCost(
              durationMs: event.durationMs,
              timeToFirstTokenMs: ctx.firstTokenAt == null
                  ? null
                  : ctx.firstTokenAt!.millisecondsSinceEpoch -
                      ctx.dispatchResult.runLog.startedAt.millisecondsSinceEpoch,
            );
      case DebugEvent():
        // Diagnostics live in the NDJSON run log, never the transcript.
        return;
      case DoneEvent():
        ctx.sawDone = true;
        return;
    }
  }

  void _appendText(
    _StreamContext ctx,
    AgentProcessEvent event, {
    required bool reasoning,
  }) {
    final extracted = ctx.contentExtractor.extractContent(
      content: event.content,
      metadata: event.metadata,
    );
    if (extracted.isEmpty) {
      return;
    }

    // A switch in kind (text<->reasoning) closes the previous open segment.
    if (ctx.openTextIndex != null && ctx.openIsReasoning != reasoning) {
      _closeOpenText(ctx, event.timestamp);
    }

    final idx = ctx.openTextIndex;
    if (idx == null) {
      ctx.openTextBuf
        ..clear()
        ..write(extracted);
      ctx.openIsReasoning = reasoning;
      final seg = reasoning
          ? ReasoningSegment(text: extracted, startedAt: event.timestamp)
          : TextSegment(text: extracted, startedAt: event.timestamp);
      ctx.segments.add(seg);
      ctx.openTextIndex = ctx.segments.length - 1;
      _apply(ctx, SegmentOpened(ctx.openTextIndex!, seg), structural: true);
    } else {
      ctx.openTextBuf.write(extracted);
      final current = ctx.segments[idx];
      ctx.segments[idx] = current is ReasoningSegment
          ? current.copyWith(text: ctx.openTextBuf.toString())
          : (current as TextSegment).copyWith(text: ctx.openTextBuf.toString());
      _apply(ctx, SegmentDelta(idx, extracted), structural: false);
    }
  }

  void _closeOpenText(_StreamContext ctx, DateTime now) {
    final idx = ctx.openTextIndex;
    if (idx == null) {
      return;
    }
    final current = ctx.segments[idx];
    final durationMs = now.difference(current.startedAt).inMilliseconds;
    final closed = current is ReasoningSegment
        ? current.copyWith(durationMs: durationMs)
        : (current as TextSegment).copyWith(durationMs: durationMs);
    ctx.segments[idx] = closed;
    ctx.openTextIndex = null;
    ctx.openTextBuf.clear();
    _apply(ctx, SegmentClosed(idx, closed), structural: true);
  }

  void _openTool(_StreamContext ctx, ToolCallEvent event) {
    _closeOpenText(ctx, event.timestamp);
    final seg = ToolSegment(
      toolName: event.toolName,
      toolCallId: event.toolCallId,
      inputs: event.inputs,
      startedAt: event.timestamp,
    );
    ctx.segments.add(seg);
    final idx = ctx.segments.length - 1;
    if (event.toolCallId.isNotEmpty) {
      ctx.openToolByCallId[event.toolCallId] = idx;
    }
    ctx.lastOpenToolIndex = idx;
    _apply(ctx, SegmentOpened(idx, seg), structural: true);
  }

  void _applyToolResult(_StreamContext ctx, ToolResultEvent event) {
    final target = (event.toolCallId.isNotEmpty
            ? ctx.openToolByCallId[event.toolCallId]
            : null) ??
        ctx.lastOpenToolIndex;

    if (target == null || ctx.segments[target] is! ToolSegment) {
      // Orphan result — no matching open call. Render as a terminal cell.
      final seg = ToolSegment(
        toolName: event.toolName ?? 'tool',
        toolCallId: event.toolCallId,
        outputs: event.outputs,
        status: event.isError ? ToolSegmentStatus.error : ToolSegmentStatus.ok,
        startedAt: event.timestamp,
        durationMs: 0,
      );
      ctx.segments.add(seg);
      final idx = ctx.segments.length - 1;
      _apply(ctx, SegmentOpened(idx, seg), structural: true);
      _apply(ctx, SegmentClosed(idx, seg), structural: true);
      return;
    }

    final existing = ctx.segments[target] as ToolSegment;
    if (event.isPartial) {
      ctx.segments[target] =
          existing.copyWith(outputs: existing.outputs + event.outputs);
      _apply(ctx, SegmentDelta(target, event.outputs), structural: false);
      return;
    }

    final durationMs =
        event.timestamp.difference(existing.startedAt).inMilliseconds;
    final closed = existing.copyWith(
      outputs: event.outputs,
      status: event.isError ? ToolSegmentStatus.error : ToolSegmentStatus.ok,
      durationMs: durationMs,
    );
    ctx.segments[target] = closed;
    if (event.toolCallId.isNotEmpty) {
      ctx.openToolByCallId.remove(event.toolCallId);
    }
    if (ctx.lastOpenToolIndex == target) {
      ctx.lastOpenToolIndex = null;
    }
    _apply(ctx, SegmentClosed(target, closed), structural: true);
  }

  void _addAtomic(_StreamContext ctx, TranscriptSegment segment) {
    _closeOpenText(ctx, segment.startedAt);
    ctx.segments.add(segment);
    final idx = ctx.segments.length - 1;
    _apply(ctx, SegmentOpened(idx, segment), structural: true);
    _apply(ctx, SegmentClosed(idx, segment), structural: true);
  }

  void _apply(
    _StreamContext ctx,
    TranscriptUpdate update, {
    required bool structural,
  }) {
    ctx.streamRegistry.apply(ctx.messageId, update);
    _markDirty(ctx, structural: structural);
  }

  void _markDirty(_StreamContext ctx, {required bool structural}) {
    ctx.dbDirty = true;
    if (structural) {
      ctx.dbFlushTimer?.cancel();
      ctx.dbFlushTimer = Timer(_structuralFlushDelay, () {
        ctx.dbFlushTimer = null;
        _flushDb(ctx);
      });
    } else {
      ctx.dbFlushTimer ??= Timer(_deltaFlushInterval, () {
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
    _closeOpenText(ctx, now);
    _interruptRunningTools(ctx, now);

    final outcome = ctx.sawDone ? TurnOutcome.completed : TurnOutcome.interrupted;
    final content = _currentContent(ctx);

    await ctx.repo.updateMessage(
      ctx.messageId,
      content: content,
      metadata: _finalMetadata(ctx, outcome: outcome, now: now),
    );

    ctx.streamRegistry.apply(
      ctx.messageId,
      TurnFinished(ctx.segments.length - 1, outcome),
    );
    await ctx.streamRegistry.unregister(ctx.messageId);

    await ctx.agentDispatchService.completeRun(
      ctx.dispatchResult.runLog,
      content.isNotEmpty ? content.split('\n').first : null,
      cost: ctx.accumulatedCost,
    );

    await _compactIfNeeded(ctx, ctx.dispatchResult.agent?.contextSize);
    _embedAssistantResponse(ctx, content);
    _notifyMessageReceived(ctx, content: content);
  }

  Future<void> _onError(_StreamContext ctx, Object error) async {
    if (ctx.finalized) {
      return;
    }
    ctx.finalized = true;
    ctx.dbFlushTimer?.cancel();
    ctx.dbFlushTimer = null;

    final now = DateTime.now();
    _closeOpenText(ctx, now);
    _interruptRunningTools(ctx, now);
    ctx.segments.add(ErrorSegment(message: error.toString(), startedAt: now));

    final content = _currentContent(ctx);
    final runLog = ctx.dispatchResult.runLog;

    await ctx.repo.updateMessage(
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
      TurnFinished(ctx.segments.length - 1, TurnOutcome.failed),
    );
    await ctx.streamRegistry.unregister(ctx.messageId);

    await ctx.agentDispatchService.failRun(runLog, error.toString());
  }

  void _interruptRunningTools(_StreamContext ctx, DateTime now) {
    for (var i = 0; i < ctx.segments.length; i++) {
      final seg = ctx.segments[i];
      if (seg is ToolSegment && seg.status == ToolSegmentStatus.running) {
        ctx.segments[i] = seg.copyWith(
          status: ToolSegmentStatus.interrupted,
          durationMs: now.difference(seg.startedAt).inMilliseconds,
        );
      }
    }
  }

  Map<String, dynamic> _finalMetadata(
    _StreamContext ctx, {
    required TurnOutcome outcome,
    required DateTime now,
  }) {
    final durationMs =
        now.difference(ctx.dispatchResult.runLog.startedAt).inMilliseconds;
    return {
      'agentName': ctx.agentName,
      'streamComplete': true,
      'outcome': turnOutcomeToString(outcome),
      'segments': encodeTranscript(ctx.segments),
      'turn': {
        'durationMs': durationMs,
        'totalTokens': ctx.accumulatedCost.totalTokens,
        'costCents': ctx.accumulatedCost.estimatedCostCents,
      },
    };
  }

  String _currentContent(_StreamContext ctx) {
    final buf = <String>[];
    for (final seg in ctx.segments) {
      if (seg is TextSegment && seg.text.trim().isNotEmpty) {
        buf.add(seg.text.trim());
      }
    }
    return buf.join('\n\n').trim();
  }

  void _flushDb(_StreamContext ctx) {
    if (!ctx.dbDirty || ctx.finalized) {
      return;
    }
    ctx.dbDirty = false;
    ctx.repo.updateMessage(
      ctx.messageId,
      content: _currentContent(ctx),
      metadata: {
        'agentName': ctx.agentName,
        'streamComplete': false,
        'segments': encodeTranscript(ctx.segments),
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
        messageId,
        Uint8List.view(vec.buffer),
      );
    } catch (_) {}
  }

  Future<void> _compactIfNeeded(_StreamContext ctx, int? contextSize) async {
    if (contextSize == null) {
      return;
    }

    final messages = await ctx.repo.getMessages(ctx.channelId);
    final compactable = messages
        .map(
          (m) => CompactableMessage(
            id: m.id,
            label: m.isUser ? 'user' : m.senderId,
            content: m.content,
            compacted: m.compacted,
          ),
        )
        .toList();

    final result = ctx.compactor.compact(
      messages: compactable,
      contextSize: contextSize,
    );
    if (result == null) {
      return;
    }

    await ctx.repo.markCompacted(result.idsToCompact);
    await ctx.repo.sendMessage(
      channelId: ctx.channelId,
      content: result.summary,
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
      metadata: {'compacted': true, 'compactedIds': result.idsToCompact},
    );

    final port = ctx.embeddingPort;
    if (port != null && port.isReady) {
      final allAfter = await ctx.repo.getMessages(ctx.channelId);
      final summaryMsg = allAfter.lastOrNull;
      if (summaryMsg != null && summaryMsg.content == result.summary) {
        unawaited(_doEmbedMessage(ctx, summaryMsg.id, result.summary, port));
      }
    }
  }

  void _notifyMessageReceived(_StreamContext ctx, {required String content}) {
    final bus = ctx.eventBus;
    if (bus == null) {
      return;
    }

    final preview =
        content.length > 120 ? '${content.substring(0, 120)}…' : content;

    bus.publish(
      MessageReceived(
        channelId: ctx.channelId,
        messageId: ctx.messageId,
        senderName: ctx.agentName,
        contentPreview: preview,
        isAgentMessage: true,
        // The sending agent owns the notification's workspace; agents always
        // belong to exactly one workspace, so this scopes agent-message
        // activity to the right workspace's dashboard feed.
        workspaceId: ctx.dispatchResult.agent?.workspaceId,
        occurredAt: DateTime.now(),
      ),
    );
  }
}
