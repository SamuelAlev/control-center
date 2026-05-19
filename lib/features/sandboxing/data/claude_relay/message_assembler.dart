import 'dart:convert';

import 'package:control_center/features/sandboxing/data/claude_relay/sse.dart';

/// One assembled content block in an assistant message.
///
/// Dart port of the upstream relay's `ContentBlock` (src/message-assembler.ts).
sealed class AssembledBlock {
  const AssembledBlock();
}

/// A plain-text content block.
class TextBlock extends AssembledBlock {
  /// Creates a [TextBlock].
  TextBlock(this.text);

  /// The accumulated text.
  String text;
}

/// An extended-thinking content block.
class ThinkingBlock extends AssembledBlock {
  /// Creates a [ThinkingBlock].
  ThinkingBlock(this.thinking);

  /// The accumulated thinking text.
  String thinking;
}

/// A tool-use content block.
class ToolUseBlock extends AssembledBlock {
  /// Creates a [ToolUseBlock].
  ToolUseBlock({required this.id, required this.name});

  /// Anthropic tool_use id (`toolu_…`).
  final String id;

  /// Tool name (e.g. `Bash`, `Edit`).
  final String name;

  /// Accumulated partial JSON for the tool input while streaming.
  String inputJson = '';

  /// Decoded tool input once the block is complete (defaults to `{}`).
  Object? input = const <String, Object?>{};
}

/// Token usage observed across `message_start` / `message_delta` events.
class TokenUsage {
  /// Creates a [TokenUsage].
  TokenUsage({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cacheReadInputTokens = 0,
    this.cacheCreationInputTokens = 0,
  });

  /// Input tokens.
  int inputTokens;

  /// Output tokens.
  int outputTokens;

  /// Cache-read input tokens.
  int cacheReadInputTokens;

  /// Cache-creation input tokens.
  int cacheCreationInputTokens;
}

/// A completed assistant message (one content block per emission, mirroring
/// the upstream relay which emits at each `content_block_stop`).
class AssembledMessage {
  /// Creates an [AssembledMessage].
  AssembledMessage({
    required this.id,
    required this.model,
    required this.content,
    required this.stopReason,
    required this.usage,
  });

  /// Anthropic message id.
  final String id;

  /// Model that produced the message.
  final String model;

  /// The content blocks (typically a single block per emission).
  final List<AssembledBlock> content;

  /// The stop reason once known.
  final String? stopReason;

  /// Token usage snapshot.
  final TokenUsage usage;
}

class _MessageState {
  _MessageState({required this.id, required this.model});
  final String id;
  final String model;
  final List<AssembledBlock> content = [];
  int currentBlockIndex = -1;
  String? stopReason;
  final TokenUsage usage = TokenUsage();
}

/// Reference to the most recent completed tool_use block, used for permission
/// forwarding / surfacing tool calls.
class ToolUseRef {
  /// Creates a [ToolUseRef].
  const ToolUseRef({required this.id, required this.name, required this.input});

  /// Anthropic tool_use id.
  final String id;

  /// Tool name.
  final String name;

  /// Decoded tool input.
  final Object? input;
}

/// Converts Anthropic streaming SSE deltas into the complete assistant content
/// blocks expected by the `claude -p` protocol.
///
/// Faithful Dart port of the upstream relay's `MessageAssembler` (src/message-assembler.ts).
class MessageAssembler {
  /// Creates a [MessageAssembler]. [onMessage] is invoked once per completed
  /// content block (on `content_block_stop`).
  MessageAssembler(this.onMessage);

  /// Called with each completed content block.
  final void Function(AssembledMessage message) onMessage;

  _MessageState? _current;
  ToolUseRef? _lastToolUse;
  final TokenUsage _contextUsage = TokenUsage();

  /// The most recent completed tool_use block, if any.
  ToolUseRef? get lastToolUse => _lastToolUse;

  /// Latest token counts observed in message_start / message_delta events.
  TokenUsage get contextUsage => TokenUsage(
        inputTokens: _contextUsage.inputTokens,
        outputTokens: _contextUsage.outputTokens,
        cacheReadInputTokens: _contextUsage.cacheReadInputTokens,
        cacheCreationInputTokens: _contextUsage.cacheCreationInputTokens,
      );

  /// Clears all state between sessions/tests.
  void reset() {
    _current = null;
    _lastToolUse = null;
    _contextUsage
      ..inputTokens = 0
      ..outputTokens = 0
      ..cacheReadInputTokens = 0
      ..cacheCreationInputTokens = 0;
  }

  /// Updates assembler state from one parsed SSE event.
  void processSse(SseEvent event) {
    final parsed = event.parsed;
    if (parsed is! Map) {
      return;
    }
    final e = parsed.cast<String, Object?>();

    switch (e['type']) {
      case 'message_start':
        final msg = e['message'];
        final msgMap = msg is Map ? msg.cast<String, Object?>() : null;
        final state = _MessageState(
          id: (msgMap?['id'] as String?) ?? '',
          model: (msgMap?['model'] as String?) ?? '',
        );
        _current = state;
        final usage = msgMap?['usage'];
        if (usage is Map) {
          final u = usage.cast<String, Object?>();
          state.usage.inputTokens = _asInt(u['input_tokens']);
          state.usage.outputTokens = _asInt(u['output_tokens']);
          final input = _asInt(u['input_tokens']);
          if (input != 0) {
            _contextUsage.inputTokens = input;
          }
          final cacheRead = _asInt(u['cache_read_input_tokens']);
          if (cacheRead != 0) {
            _contextUsage.cacheReadInputTokens = cacheRead;
          }
          final cacheCreate = _asInt(u['cache_creation_input_tokens']);
          if (cacheCreate != 0) {
            _contextUsage.cacheCreationInputTokens = cacheCreate;
          }
        }

      case 'content_block_start':
        final state = _current;
        if (state == null) {
          break;
        }
        final blockRaw = e['content_block'];
        final block = blockRaw is Map ? blockRaw.cast<String, Object?>() : null;
        state.currentBlockIndex = _asInt(e['index']);
        switch (block?['type']) {
          case 'text':
            state.content.add(TextBlock((block?['text'] as String?) ?? ''));
          case 'thinking':
            state.content
                .add(ThinkingBlock((block?['thinking'] as String?) ?? ''));
          case 'tool_use':
            state.content.add(ToolUseBlock(
              id: (block?['id'] as String?) ?? '',
              name: (block?['name'] as String?) ?? '',
            ));
        }

      case 'content_block_delta':
        final state = _current;
        if (state == null || state.content.isEmpty) {
          break;
        }
        final deltaRaw = e['delta'];
        final delta = deltaRaw is Map ? deltaRaw.cast<String, Object?>() : null;
        final block = state.content.last;
        final deltaType = delta?['type'];
        if (deltaType == 'text_delta' && block is TextBlock) {
          block.text += (delta?['text'] as String?) ?? '';
        } else if (deltaType == 'thinking_delta' && block is ThinkingBlock) {
          block.thinking += (delta?['thinking'] as String?) ?? '';
        } else if (deltaType == 'input_json_delta' && block is ToolUseBlock) {
          block.inputJson += (delta?['partial_json'] as String?) ?? '';
        }

      case 'content_block_stop':
        final state = _current;
        if (state == null) {
          break;
        }
        final block = state.content.isNotEmpty ? state.content.last : null;
        if (block is ToolUseBlock) {
          if (block.inputJson.isNotEmpty) {
            try {
              block.input = jsonDecode(block.inputJson);
            } catch (_) {
              // Leave the default empty input on malformed JSON.
            }
          }
          _lastToolUse =
              ToolUseRef(id: block.id, name: block.name, input: block.input);
        }
        onMessage(AssembledMessage(
          id: state.id,
          model: state.model,
          content: block != null ? [block] : const [],
          stopReason: null,
          usage: TokenUsage(
            inputTokens: state.usage.inputTokens,
            outputTokens: state.usage.outputTokens,
          ),
        ));

      case 'message_delta':
        final state = _current;
        if (state == null) {
          break;
        }
        final deltaRaw = e['delta'];
        final delta = deltaRaw is Map ? deltaRaw.cast<String, Object?>() : null;
        final stopReason = delta?['stop_reason'];
        if (stopReason is String && stopReason.isNotEmpty) {
          state.stopReason = stopReason;
        }
        final usageRaw = e['usage'];
        if (usageRaw is Map) {
          final outputTokens = _asInt(usageRaw['output_tokens']);
          if (outputTokens != 0) {
            state.usage.outputTokens = outputTokens;
            _contextUsage.outputTokens = outputTokens;
          }
        }

      case 'message_stop':
        _current = null;
    }
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
