import 'dart:async';

import 'dart:convert';

import 'dart:io';

import 'package:control_center/core/domain/events/agent_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/run_cost.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/core/infrastructure/process/binary_resolver.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:control_center/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:flutter/foundation.dart';

/// Data source that spawns and manages an external agent CLI process.
class AgentProcessDataSource implements AgentDispatchPort {
  /// Creates a new [AgentProcessDataSource].
  AgentProcessDataSource({DomainEventBus? eventBus}) : _eventBus = eventBus;

  final DomainEventBus? _eventBus;

  Process? _process;
  String? _workingDirectory;

  StreamController<AgentProcessEvent>? _controller;
  int _pendingStreams = 0;

  String? _agentId;
  String? _workspaceId;
  String? _conversationId;
  Map<String, String>? _env;

  static const _coalesceWindow = Duration(milliseconds: 50);
  AgentProcessEventType? _bufferedType;
  final StringBuffer _bufferedContent = StringBuffer();
  Timer? _flushTimer;

  /// The duration window over which consecutive events of the same type are coalesced.
  @visibleForTesting
  static Duration get coalesceWindow => _coalesceWindow;

  /// Immediately flushes any buffered coalesced event to the output stream.
  @visibleForTesting
  void flushBufferedEvent() => _flushBufferedEvent();

  /// Creates and returns a test controller stream. For testing only.
  @visibleForTesting
  Stream<AgentProcessEvent> initTestController() {
    _controller = StreamController<AgentProcessEvent>.broadcast();
    return _controller!.stream;
  }

  void _flushBufferedEvent() {
    _flushTimer?.cancel();
    _flushTimer = null;
    final type = _bufferedType;
    final content = _bufferedContent.toString();
    _bufferedType = null;
    _bufferedContent.clear();
    if (type != null && content.isNotEmpty) {
      _addEvent(_createTypedEvent(type, content));
    }
  }

  void _bufferEvent(AgentProcessEventType type, String content) {
    if (content.isEmpty) {
      return;
    }
    if (_bufferedType != null && _bufferedType != type) {
      _flushBufferedEvent();
    }
    _bufferedType = type;
    _bufferedContent.write(content);
    _flushTimer ??= Timer(_coalesceWindow, _flushBufferedEvent);
  }

  /// Creates the appropriate typed [AgentProcessEvent] for a coalesced buffer.
  AgentProcessEvent _createTypedEvent(
    AgentProcessEventType type,
    String content,
  ) {
    switch (type) {
      case AgentProcessEventType.thinking:
        return ThinkingEvent(content: content);
      case AgentProcessEventType.text:
        return TextEvent(content: content);
      case AgentProcessEventType.toolCall:
        return ToolCallEvent(toolName: content, toolCallId: '');
      case AgentProcessEventType.toolResult:
        return ToolResultEvent(toolCallId: '', outputs: content);
      case AgentProcessEventType.usage:
        return UsageEvent(usage: const RunUsage());
      case AgentProcessEventType.error:
        return ErrorEvent(content: content);
      case AgentProcessEventType.sandboxViolation:
        return SandboxViolationEvent(content: content);
      case AgentProcessEventType.debug:
        return DebugEvent(content: content);
      case AgentProcessEventType.done:
        return DoneEvent();
    }
  }

  void _addEvent(AgentProcessEvent event) {
    final c = _controller;
    if (c != null && !c.isClosed) {
      c.add(event);
    }
  }

  void _emitEvent(AgentProcessEvent event) {
    _flushBufferedEvent();
    _addEvent(event);
  }

  void _addError(Object error) {
    final c = _controller;
    if (c != null && !c.isClosed) {
      c.addError(error);
    }
  }

  void _closeController() {
    _flushBufferedEvent();
    _controller?.close();
    _controller = null;
  }

  void _onStreamDone() {
    _pendingStreams--;
    if (_pendingStreams <= 0) {
      if (_agentId != null) {
        _eventBus?.publish(
          AgentRunCompleted(
            agentId: _agentId!,
            workspaceId: _workspaceId,
            conversationId: _conversationId,
            occurredAt: DateTime.now(),
          ),
        );
      }
      _closeController();
    }
  }

  void _onStreamError(Object error) {
    _addError(error);
    _closeController();
  }

  @override
  DispatchHandle start({
    required String cliName,
    required String prompt,
    required String workingDirectory,
    String? modelId,
    String? agentId,
    String? workspaceId,
    String? conversationId,
    String? runLogId,
    String? ticketId,
    WakeContext? wakeContext,
    ConversationMode? mode,
    Map<String, String>? environment,
    List<String>? imagePaths,
  }) {
    _workingDirectory = workingDirectory;
    _agentId = agentId;
    _workspaceId = workspaceId;
    _conversationId = conversationId;
    _env = {
      ...?environment,
      if (wakeContext != null) ...wakeContext.toEnvironment(),
    };
    _controller = StreamController<AgentProcessEvent>();

    final dispatchId = runLogId ?? 'ds-${DateTime.now().millisecondsSinceEpoch}';
    _spawnProcess(cliName, prompt, modelId: modelId);

    return DispatchHandle(
      dispatchId: dispatchId,
      events: _controller!.stream,
    );
  }

  @override
  Future<void> stopDispatch(String dispatchId) async {
    _flushBufferedEvent();
    _process?.kill();
    _process = null;
    _closeController();
  }

  @override
  Future<void> stopAllForAgent(String agentId) async {
    await stop();
  }

  @override
  Future<void> stop() async {
    _flushBufferedEvent();
    _process?.kill();
    _process = null;
    _closeController();
  }

  Future<void> _spawnProcess(
    String cliName,
    String prompt, {
    String? modelId,
  }) async {
    if (cliName != 'pi') {
      _addError(
        ArgumentError(
          'Unsupported CLI "$cliName" — only "pi" is supported.',
        ),
      );
      _closeController();
      return;
    }
    return _spawnPi(prompt, modelId: modelId);
  }

  Future<void> _spawnPi(String prompt, {String? modelId}) async {
    try {
      // Resolve `pi` to its absolute path: a bundled `.app` / `.desktop`
      // launch inherits a minimal PATH (no Homebrew/Nix), so the bare name
      // fails with "pi: command not found". Same probe Settings → Adapters
      // uses to display the path.
      final executable = await resolveBinaryPath('pi');
      if (executable == null) {
        _addError(
          const ProcessException(
            'pi',
            ['--mode', 'json'],
            '"pi" not found. Install it on your host or check '
                'Settings → Adapters for the detected path.',
            127,
          ),
        );
        _closeController();
        return;
      }

      final args = <String>['--mode', 'json'];
      if (modelId != null && modelId.isNotEmpty) {
        args.addAll(['--model', modelId]);
      }

      _process = await Process.start(
        executable,
        args,
        workingDirectory: _workingDirectory,
        environment: _env,
        includeParentEnvironment: true,
        runInShell: true,
      );

      _pendingStreams = 2;

      _process!.stdin.write(prompt);
      unawaited(_process!.stdin.close());
      _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              try {
                final json = jsonDecode(line) as Map<String, dynamic>;
                handlePiEvent(json);
              } catch (_) {
                _addEvent(TextEvent(content: line));
              }
            },
            onDone: _onStreamDone,
            onError: _onStreamError,
          );

      _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              _addEvent(ErrorEvent(content: line));
            },
            onDone: _onStreamDone,
            onError: _onStreamError,
          );
    } catch (e) {
      _addError(e);
      _closeController();
    }
  }

  /// Handles a raw JSON event from the Pi CLI process, parsing and routing it to the appropriate event type.
  @visibleForTesting
  void handlePiEvent(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';

    switch (type) {
      case 'event':
        final eventType = json['eventType'] as String? ?? '';
        final content = json['content'] as String? ?? '';
        switch (eventType) {
          case 'thinking':
            _bufferEvent(AgentProcessEventType.thinking, content);
          case 'text':
            _bufferEvent(AgentProcessEventType.text, content);
          case 'debug':
            _emitEvent(DebugEvent(content: content));
          case 'error':
            _emitEvent(ErrorEvent(content: content));
          case 'tool_call':
            _emitEvent(ToolCallEvent(toolName: content, toolCallId: ''));
          case 'tool_result':
            _emitEvent(ToolResultEvent(toolCallId: '', outputs: content));
          case 'sandbox_violation':
            _emitEvent(SandboxViolationEvent(content: content));
          case 'done':
            _emitEvent(DoneEvent());
        }
      case 'message_update':
        final assistantEvent =
            json['assistantMessageEvent'] as Map<String, dynamic>?;
        if (assistantEvent == null) {
          return;
        }
        final subType = assistantEvent['type'] as String? ?? '';
        final delta = assistantEvent['delta'] as String? ?? '';
        if (delta.isEmpty) {
          return;
        }
        if (subType == 'text_delta') {
          _bufferEvent(AgentProcessEventType.text, delta);
        } else if (subType == 'thinking_delta') {
          _bufferEvent(AgentProcessEventType.thinking, delta);
        }
      case 'tool_execution_start':
        _emitEvent(ToolCallEvent(
          toolName: json['toolName'] as String? ?? '',
          toolCallId: json['toolCallId'] as String? ?? '',
          inputs: json['args'] as Map<String, dynamic>?,
        ));
      case 'tool_execution_update':
        final partialResult = json['partialResult'];
        if (partialResult is Map<String, dynamic>) {
          final contentList = partialResult['content'];
          if (contentList is List) {
            final text = contentList
                .whereType<Map<String, dynamic>>()
                .where((b) => b['type'] == 'text')
                .map((b) => b['text'] as String? ?? '')
                .join();
            if (text.isNotEmpty) {
              _emitEvent(ToolResultEvent(
                toolCallId: json['toolCallId'] as String? ?? '',
                outputs: text,
                toolName: json['toolName'] as String? ?? '',
                isPartial: true,
              ));
            }
          }
        }
      case 'tool_execution_end':
        final isError = json['isError'] as bool? ?? false;
        _emitEvent(ToolResultEvent(
          toolCallId: json['toolCallId'] as String? ?? '',
          outputs: json['result'] != null ? jsonEncode(json['result']) : '',
          toolName: json['toolName'] as String? ?? '',
          isError: isError,
        ));
      case 'agent_end':
        _emitEvent(DoneEvent());
      case 'start':
      case 'end':
      case 'session':
        break;
    }
  }
}
