import 'dart:async';
import 'dart:typed_data';

import 'package:control_center/core/constants/app_log_level.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/messaging_events.dart';
import 'package:control_center/core/domain/ports/embedding_port.dart';
import 'package:control_center/core/domain/value_objects/run_cost.dart';
import 'package:control_center/core/domain/value_objects/thinking_event.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/dispatch/data/services/agent_dispatch_service.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:control_center/features/messaging/data/services/active_stream_registry.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:control_center/shared/utils/json_content_extractor.dart';
import 'package:control_center/shared/utils/message_compactor.dart';


const Duration _dbFlushInterval = Duration(milliseconds: 50);

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
    required this.thinkingId,
    required this.responseId,
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
  final String thinkingId;
  final String responseId;
  final AgentDispatchResult dispatchResult;
  final JsonContentExtractor contentExtractor;
  final MessageCompactor compactor;

  final thinkingLines = <String>[];
  final assistantBuffer = StringBuffer();
  final events = <ThinkingEvent>[];
  final reasoningBuffer = StringBuffer();
  DateTime? reasoningStartedAt;
  DateTime? firstTokenAt;
  AgentProcessEventType? lastLogEventType;
  int logEventCount = 0;
  Timer? dbFlushTimer;
  bool dbDirty = false;
  RunCost accumulatedCost = RunCost.zero;
}

class AgentStreamProcessor {
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

  void processStream({
    required Stream<AgentProcessEvent> stream,
    required AgentDispatchResult dispatchResult,
    required String channelId,
    required String agentId,
    required String agentName,
    required String thinkingId,
    required String responseId,
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
      thinkingId: thinkingId,
      responseId: responseId,
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

  void _onEvent(_StreamContext ctx, AgentProcessEvent event) {
    if (event.type == AgentProcessEventType.text) {
      ctx.firstTokenAt ??= event.timestamp;
      final extracted = ctx.contentExtractor.extractContent(
        content: event.content,
        metadata: event.metadata,
      );
      if (extracted.isNotEmpty) {
        ctx.assistantBuffer.write(extracted);
        ctx.streamRegistry.add(ctx.responseId, extracted);
      }
    } else if (event.type == AgentProcessEventType.thinking) {
      final extracted = ctx.contentExtractor.extractContent(
        content: event.content,
        metadata: event.metadata,
      );
      if (extracted.isNotEmpty) {
        ctx.reasoningStartedAt ??= event.timestamp;
        ctx.reasoningBuffer.write(extracted);
        ctx.streamRegistry.add(ctx.thinkingId, extracted);
      }
    } else if (event.type == AgentProcessEventType.toolCall) {
      _flushReasoning(ctx, event.timestamp);
      _addStructured(
        ctx,
        ThinkingEvent(
          kind: ThinkingEventKind.toolCall,
          content: event.content,
          timestamp: event.timestamp,
          toolName:
              (event.metadata?['toolName'] as String?) ??
              _firstLine(event.content),
          inputs:
              (event.metadata?['inputs'] as Map?)?.cast<String, dynamic>(),
        ),
      );
    } else if (event.type == AgentProcessEventType.toolResult) {
      _flushReasoning(ctx, event.timestamp);
      _addStructured(
        ctx,
        ThinkingEvent(
          kind: ThinkingEventKind.toolResult,
          content: event.content,
          timestamp: event.timestamp,
          outputs:
              (event.metadata?['outputs'] as String?) ?? event.content,
        ),
      );
    } else if (event.type == AgentProcessEventType.error) {
      _flushReasoning(ctx, event.timestamp);
      _addStructured(
        ctx,
        ThinkingEvent(
          kind: ThinkingEventKind.error,
          content: event.content,
          timestamp: event.timestamp,
        ),
      );
    } else if (event.type == AgentProcessEventType.sandboxViolation) {
      _flushReasoning(ctx, event.timestamp);
      _addStructured(
        ctx,
        ThinkingEvent(
          kind: ThinkingEventKind.sandboxViolation,
          content: event.content,
          timestamp: event.timestamp,
        ),
      );
      final banner = '\n🛡 ${event.content}\n';
      ctx.streamRegistry.add(ctx.responseId, banner);
      ctx.assistantBuffer.write(banner);
    } else if (event.type == AgentProcessEventType.debug) {
      if (AppLog.level.index < AppLogLevel.info.index) {
        return;
      }
      final line = '\n· ${event.content}\n';
      ctx.streamRegistry.add(ctx.responseId, line);
      ctx.assistantBuffer.write(line);
    } else if (event is UsageEvent) {
      ctx.accumulatedCost = ctx.accumulatedCost + event.usage.toCost(
        durationMs: event.durationMs,
        timeToFirstTokenMs: ctx.firstTokenAt == null
            ? null
            : ctx.firstTokenAt!.millisecondsSinceEpoch -
                ctx.dispatchResult.runLog.startedAt.millisecondsSinceEpoch,
      );
    }

    _appendLogEvent(ctx, event.type);
    ctx.dbDirty = true;
    ctx.dbFlushTimer ??= Timer.periodic(_dbFlushInterval, (_) {
      _flushDb(ctx);
      ctx.dbFlushTimer?.cancel();
      ctx.dbFlushTimer = null;
    });
  }

  Future<void> _onDone(_StreamContext ctx) async {
    ctx.dbFlushTimer?.cancel();
    ctx.dbFlushTimer = null;
    _flushReasoning(ctx, DateTime.now());
    _closePreviousDuration(ctx, DateTime.now());
    _flushDb(ctx);

    await ctx.repo.updateMessage(
      ctx.thinkingId,
      content: '',
      metadata: {
        'agentName': ctx.agentName,
        'streamComplete': true,
        'thinking': ctx.thinkingLines.join('\n'),
        'events': ctx.events.map((e) => e.toJson()).toList(),
      },
    );

    final response = ctx.assistantBuffer.toString().trim();
    await ctx.repo.updateMessage(
      ctx.responseId,
      content: response,
      metadata: {'streamComplete': true},
    );

    await ctx.streamRegistry.unregister(ctx.thinkingId);
    await ctx.streamRegistry.unregister(ctx.responseId);

    await ctx.agentDispatchService.completeRun(
      ctx.dispatchResult.runLog,
      response.isNotEmpty ? response.split('\n').first : null,
      cost: ctx.accumulatedCost,
    );

    await _compactIfNeeded(ctx, ctx.dispatchResult.agent?.contextSize);

    _embedAssistantResponse(ctx, ctx.responseId, response);

    _notifyMessageReceived(
      ctx,
      content: response,
      isAgentMessage: true,
      senderName: ctx.agentName,
      messageId: ctx.responseId,
    );
  }

  Future<void> _onError(_StreamContext ctx, Object error) async {
    ctx.dbFlushTimer?.cancel();
    ctx.dbFlushTimer = null;

    await ctx.repo.updateMessage(
      ctx.thinkingId,
      content: 'Error: $error',
      metadata: {
        'agentName': ctx.agentName,
        'streamComplete': true,
        'error': true,
      },
    );

    await ctx.streamRegistry.unregister(ctx.thinkingId);
    await ctx.streamRegistry.unregister(ctx.responseId);

    await ctx.agentDispatchService.failRun(
      ctx.dispatchResult.runLog,
      error.toString(),
    );
  }

  void _flushLogLine(_StreamContext ctx) {
    if (ctx.lastLogEventType == null) {
      return;
    }
    final label = ctx.lastLogEventType!.name;
    if (ctx.logEventCount == 1) {
      ctx.thinkingLines.add('[$label]');
    } else {
      ctx.thinkingLines.add('[$label] ×${ctx.logEventCount}');
    }
    ctx.lastLogEventType = null;
    ctx.logEventCount = 0;
  }

  void _appendLogEvent(_StreamContext ctx, AgentProcessEventType type) {
    if (ctx.lastLogEventType == type) {
      ctx.logEventCount++;
    } else {
      _flushLogLine(ctx);
      ctx.lastLogEventType = type;
      ctx.logEventCount = 1;
    }
  }

  void _closePreviousDuration(_StreamContext ctx, DateTime now) {
    if (ctx.events.isEmpty) return;
    final prev = ctx.events.last;
    if (prev.duration != null) return;
    ctx.events[ctx.events.length - 1] =
        prev.copyWith(duration: now.difference(prev.timestamp));
  }

  void _flushReasoning(_StreamContext ctx, DateTime endTime) {
    final text = ctx.reasoningBuffer.toString();
    if (text.isEmpty || ctx.reasoningStartedAt == null) {
      ctx.reasoningBuffer.clear();
      ctx.reasoningStartedAt = null;
      return;
    }
    final ev = ThinkingEvent(
      kind: ThinkingEventKind.reasoning,
      content: text,
      timestamp: ctx.reasoningStartedAt!,
      duration: endTime.difference(ctx.reasoningStartedAt!),
    );
    ctx.events.add(ev);
    ctx.streamRegistry.addEvent(ctx.thinkingId, ev);
    ctx.reasoningBuffer.clear();
    ctx.reasoningStartedAt = null;
  }

  void _addStructured(_StreamContext ctx, ThinkingEvent event) {
    _closePreviousDuration(ctx, event.timestamp);
    ctx.events.add(event);
    ctx.streamRegistry.addEvent(ctx.thinkingId, event);
  }

  List<Map<String, dynamic>> _snapshotEvents(_StreamContext ctx) {
    final snapshot = ctx.events.map((e) => e.toJson()).toList();
    if (ctx.reasoningBuffer.isNotEmpty && ctx.reasoningStartedAt != null) {
      snapshot.add(
        ThinkingEvent(
          kind: ThinkingEventKind.reasoning,
          content: ctx.reasoningBuffer.toString(),
          timestamp: ctx.reasoningStartedAt!,
        ).toJson(),
      );
    }
    return snapshot;
  }

  void _flushDb(_StreamContext ctx) {
    if (!ctx.dbDirty) {
      return;
    }
    ctx.dbDirty = false;
    _flushLogLine(ctx);
    ctx.repo.updateMessage(
      ctx.thinkingId,
      content: '',
      metadata: {
        'agentName': ctx.agentName,
        'streamComplete': false,
        'thinking': ctx.thinkingLines.join('\n'),
        'events': _snapshotEvents(ctx),
      },
    );
  }

  void _embedAssistantResponse(
    _StreamContext ctx,
    String responseId,
    String response,
  ) {
    final port = ctx.embeddingPort;
    if (port == null || !port.isReady || response.isEmpty) {
      return;
    }
    unawaited(_doEmbedMessage(ctx, responseId, response, port));
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

  void _notifyMessageReceived(
    _StreamContext ctx, {
    required String content,
    required bool isAgentMessage,
    String messageId = '',
    String senderName = 'You',
  }) {
    final bus = ctx.eventBus;
    if (bus == null) return;

    final preview = content.length > 120
        ? '${content.substring(0, 120)}…'
        : content;

    bus.publish(
      MessageReceived(
        channelId: ctx.channelId,
        messageId: messageId,
        senderName: senderName,
        contentPreview: preview,
        isAgentMessage: isAgentMessage,
        // The sending agent owns the notification's workspace; agents always
        // belong to exactly one workspace, so this scopes agent-message
        // activity to the right workspace's dashboard feed.
        workspaceId: ctx.dispatchResult.agent?.workspaceId,
        occurredAt: DateTime.now(),
      ),
    );
  }
}

String? _firstLine(String content) {
  if (content.isEmpty) return null;
  final i = content.indexOf('\n');
  final line = (i == -1 ? content : content.substring(0, i)).trim();
  return line.isEmpty ? null : line;
}
