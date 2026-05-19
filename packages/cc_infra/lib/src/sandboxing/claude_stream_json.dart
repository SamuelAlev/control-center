import 'dart:convert';

/// A completed tool invocation surfaced from a `tool_use` content block.
class ClaudeToolUse {
  /// Creates a [ClaudeToolUse].
  const ClaudeToolUse({required this.id, required this.name, this.input});

  /// Anthropic tool_use id.
  final String id;

  /// Tool name (e.g. `Bash`, `Edit`).
  final String name;

  /// Decoded tool input.
  final Object? input;
}

/// Callbacks invoked by [ClaudeStreamJsonParser] as it walks a
/// `claude -p --output-format stream-json` NDJSON stream.
class ClaudeStreamJsonCallbacks {
  /// Creates [ClaudeStreamJsonCallbacks].
  const ClaudeStreamJsonCallbacks({
    this.onText,
    this.onThinking,
    this.onToolCall,
    this.onError,
  });

  /// Streamed assistant text delta.
  final void Function(String delta)? onText;

  /// Streamed extended-thinking delta.
  final void Function(String delta)? onThinking;

  /// A completed tool call (decoded input).
  final void Function(ClaudeToolUse toolUse)? onToolCall;

  /// A terminal error reported by `claude` in its final `result` event
  /// (e.g. `model_not_found`, rate-limit/overload, MCP-config rejection).
  /// These arrive OUTSIDE the `stream_event` content-block path — without
  /// surfacing them the turn renders blank and only the process exit code is
  /// seen, which is exactly the "nothing visible, then exited with code 1"
  /// failure.
  final void Function(String message)? onError;
}

/// Pure parser for Claude Code's `stream-json` output format
/// (`claude -p --output-format stream-json --verbose
/// --include-partial-messages`). Each NDJSON line is fed to [process]; the
/// parser reconstructs streamed text / thinking deltas and reassembles
/// `tool_use` blocks (whose input arrives as incremental
/// `input_json_delta` fragments) into a single decoded object.
///
/// Claude Code is driven as a plain structured CLI (like Pi): `claude -p`
/// emits these events itself on stdout, on the same subscription quota as
/// interactive mode — no proxy or PTY is involved.
class ClaudeStreamJsonParser {
  /// Creates a [ClaudeStreamJsonParser].
  ClaudeStreamJsonParser(this._callbacks);

  final ClaudeStreamJsonCallbacks _callbacks;

  final Map<int, _Block> _blocks = {};

  /// Feeds one decoded NDJSON line. Unknown event shapes are ignored.
  void process(Map<String, dynamic> obj) {
    final type = obj['type'];
    if (type == 'stream_event') {
      final event = obj['event'];
      if (event is Map<String, dynamic>) {
        _handleEvent(event);
      }
      return;
    }
    // The terminal `result` event carries `is_error: true` when the whole turn
    // failed (bad model id, rate-limit/overload, MCP-config rejection, …). No
    // `content_block_*` deltas precede such a failure, so this is the ONLY
    // signal — surface it or the turn looks empty and only the exit code shows.
    if (type == 'result' && obj['is_error'] == true) {
      _callbacks.onError?.call(_errorMessage(obj));
      return;
    }
    // `system` (init), `assistant`, `user`, … are not needed for live
    // transcription — text/thinking/tool calls all arrive via the
    // `stream_event` wrappers above.
  }

  /// Builds a human-readable message from a failed `result` event. Prefers
  /// claude's own `result` text, falling back to `error` and appends the HTTP
  /// status when present (e.g. a 404 model_not_found).
  static String _errorMessage(Map<String, dynamic> obj) {
    final text = (obj['result'] as String?)?.trim();
    final error = (obj['error'] as String?)?.trim();
    final base = (text != null && text.isNotEmpty)
        ? text
        : (error != null && error.isNotEmpty)
        ? error
        : 'claude reported an error';
    final status = obj['api_error_status'];
    return status is num ? '$base (HTTP $status)' : base;
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type'];
    switch (type) {
      case 'content_block_start':
        final index = (event['index'] as num?)?.toInt();
        final block = event['content_block'];
        if (index == null || block is! Map<String, dynamic>) {
          return;
        }
        _blocks[index] = _Block(
          kind: (block['type'] as String?) ?? 'text',
          id: block['id'] as String?,
          name: block['name'] as String?,
        );
      case 'content_block_delta':
        final index = (event['index'] as num?)?.toInt();
        final delta = event['delta'];
        if (index == null || delta is! Map<String, dynamic>) {
          return;
        }
        _handleDelta(index, delta);
      case 'content_block_stop':
        final index = (event['index'] as num?)?.toInt();
        if (index == null) {
          return;
        }
        final block = _blocks.remove(index);
        if (block != null && block.kind == 'tool_use') {
          _emitToolCall(block);
        }
    }
  }

  void _handleDelta(int index, Map<String, dynamic> delta) {
    final block = _blocks[index];
    final deltaType = delta['type'];
    if (deltaType == 'text_delta') {
      final text = delta['text'] as String? ?? '';
      if (text.isEmpty) {
        return;
      }
      if (block?.kind == 'thinking') {
        _callbacks.onThinking?.call(text);
      } else {
        _callbacks.onText?.call(text);
      }
    } else if (deltaType == 'thinking_delta') {
      final thinking = delta['thinking'] as String? ?? '';
      if (thinking.isNotEmpty) {
        _callbacks.onThinking?.call(thinking);
      }
    } else if (deltaType == 'input_json_delta') {
      final partial = delta['partial_json'] as String? ?? '';
      if (partial.isNotEmpty && block != null) {
        block.jsonBuffer.write(partial);
      }
    }
  }

  void _emitToolCall(_Block block) {
    Object? input;
    final raw = block.jsonBuffer.toString();
    if (raw.isNotEmpty) {
      try {
        input = jsonDecode(raw);
      } catch (_) {
        input = raw;
      }
    }
    _callbacks.onToolCall?.call(
      ClaudeToolUse(id: block.id ?? '', name: block.name ?? '', input: input),
    );
  }
}

class _Block {
  _Block({required this.kind, this.id, this.name});

  final String kind;
  final String? id;
  final String? name;
  final StringBuffer jsonBuffer = StringBuffer();
}
