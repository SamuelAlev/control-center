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

/// The result of a tool invocation, paired back to its [ClaudeToolUse] by id.
class ClaudeToolResult {
  /// Creates a [ClaudeToolResult].
  const ClaudeToolResult({
    required this.id,
    required this.outputs,
    this.isError = false,
  });

  /// The `tool_use_id` this result answers.
  final String id;

  /// Flattened result text.
  final String outputs;

  /// Whether the tool reported a failure.
  final bool isError;
}

/// Cumulative token usage reported by `claude` in its terminal `result` event.
///
/// `claude` reports usage ONCE, at the end, on the top-level `result` event —
/// the per-turn `usage` on each `assistant` message is a mid-stream snapshot
/// that would double-count if summed. So this is the whole invocation's spend,
/// not a delta.
///
/// [inputTokens] / [outputTokens] / the cache counts are the PRIMARY model's
/// (`result.usage`); [costUsd] is `total_cost_usd`, which additionally covers
/// the small auxiliary-model calls `claude` makes on its own (titling, and
/// similar). They are therefore not derivable from each other — the token
/// counts answer "what did this model do", the cost answers "what did this
/// invocation spend", and each is the honest number for its own question.
class ClaudeUsage {
  /// Creates a [ClaudeUsage].
  const ClaudeUsage({
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheReadTokens,
    required this.cacheWriteTokens,
    required this.costUsd,
    this.durationMs,
    this.timeToFirstTokenMs,
  });

  /// Reads the usage block off a terminal `result` event.
  ///
  /// Returns null when the event carries no `usage` object — an older CLI, or
  /// a failure that died before any accounting. Never throws on a shape it
  /// does not recognise: a missing field reads as zero, because a partial
  /// count is worth more than dropping the whole measurement.
  static ClaudeUsage? tryFromResult(Map<String, dynamic> obj) {
    final usage = obj['usage'];
    if (usage is! Map<String, dynamic>) {
      return null;
    }
    int count(String key) {
      final value = usage[key];
      return value is num ? value.toInt() : 0;
    }

    final cost = obj['total_cost_usd'];
    return ClaudeUsage(
      inputTokens: count('input_tokens'),
      outputTokens: count('output_tokens'),
      cacheReadTokens: count('cache_read_input_tokens'),
      cacheWriteTokens: count('cache_creation_input_tokens'),
      costUsd: cost is num ? cost.toDouble() : 0.0,
      durationMs:
          _intOrNull(obj['duration_ms']) ?? _intOrNull(obj['duration_api_ms']),
      timeToFirstTokenMs: _intOrNull(obj['ttft_ms']),
    );
  }

  static int? _intOrNull(Object? value) => value is num ? value.toInt() : null;

  /// Uncached input tokens.
  final int inputTokens;

  /// Output tokens (thinking is folded in by the provider, as elsewhere).
  final int outputTokens;

  /// Input tokens served from the prompt cache.
  final int cacheReadTokens;

  /// Input tokens written to the prompt cache.
  final int cacheWriteTokens;

  /// What the invocation would cost at list price, in USD.
  ///
  /// `claude` reports this even on a subscription account, where nothing is
  /// billed per token — there it reads as the equivalent API spend rather than
  /// an invoice.
  final double costUsd;

  /// Wall-clock duration `claude` measured for the turn, when it reported one.
  final int? durationMs;

  /// Time to first token, when reported.
  final int? timeToFirstTokenMs;

  /// [costUsd] in whole cents, the unit the run log stores.
  int get costCents => (costUsd * 100).round();
}

/// Callbacks invoked by [ClaudeStreamJsonParser] as it walks a
/// `claude -p --output-format stream-json` NDJSON stream.
class ClaudeStreamJsonCallbacks {
  /// Creates [ClaudeStreamJsonCallbacks].
  const ClaudeStreamJsonCallbacks({
    this.onText,
    this.onThinking,
    this.onToolCall,
    this.onToolResult,
    this.onUsage,
    this.onError,
    this.onTerminalError,
  });

  /// Streamed assistant text delta.
  final void Function(String delta)? onText;

  /// Streamed extended-thinking delta.
  final void Function(String delta)? onThinking;

  /// A completed tool call (decoded input).
  final void Function(ClaudeToolUse toolUse)? onToolCall;

  /// The result closing a previously-reported [onToolCall].
  ///
  /// Results do NOT arrive on the `stream_event` content-block path: `claude`
  /// replays them as top-level `user` messages carrying `tool_result` blocks.
  /// Without this the call opens and nothing ever closes it, so every tool row
  /// in the transcript spins for the whole turn.
  final void Function(ClaudeToolResult result)? onToolResult;

  /// The invocation's cumulative token usage, from the terminal `result`
  /// event. Fires on a successful AND on a failed result — a turn that ended
  /// in an error still spent the tokens it spent.
  final void Function(ClaudeUsage usage)? onUsage;

  /// A terminal error reported by `claude` in its final `result` event
  /// (e.g. `model_not_found`, rate-limit/overload, MCP-config rejection).
  /// These arrive OUTSIDE the `stream_event` content-block path — without
  /// surfacing them the turn renders blank and only the process exit code is
  /// seen, which is exactly the "nothing visible, then exited with code 1"
  /// failure.
  final void Function(String message)? onError;

  /// The same terminal event, classified.
  ///
  /// Separate from [onError] because the caller does something structurally
  /// different with an ACCOUNT failure — [ClaudeTerminalError.isCapacity] (a
  /// plan with nothing left) or [ClaudeTerminalError.isAuth] (a credential
  /// that no longer authenticates): neither is a broken run, both are a run
  /// that belongs on another account. Every other terminal error must NOT
  /// trigger that — retrying a bad model id or a rejected MCP config on each
  /// account in turn just burns them all.
  final void Function(ClaudeTerminalError error)? onTerminalError;
}

/// A classified terminal `result` failure.
class ClaudeTerminalError {
  /// Creates a [ClaudeTerminalError].
  const ClaudeTerminalError({
    required this.message,
    this.httpStatus,
    this.resetsAt,
  });

  /// Classifies a failed `result` event.
  factory ClaudeTerminalError.fromResult(
    Map<String, dynamic> obj,
    String message,
  ) {
    final status = obj['api_error_status'];
    return ClaudeTerminalError(
      message: message,
      httpStatus: status is num ? status.toInt() : null,
      resetsAt: parseResetEpoch(message),
    );
  }

  /// The human-readable message (already includes the HTTP status when known).
  final String message;

  /// The upstream HTTP status, when `claude` reported one.
  final int? httpStatus;

  /// When the plan's window reopens, when the message carried it.
  final DateTime? resetsAt;

  /// Whether this is a capacity failure — the account is out of headroom.
  ///
  /// Two signals, because the CLI uses both: an upstream `429`, and its own
  /// `Claude AI usage limit reached|<epoch>` sentence, which is what a
  /// subscription (rather than an API key) actually hits.
  bool get isCapacity =>
      httpStatus == 429 || _usageLimit.hasMatch(message.toLowerCase());

  static final RegExp _usageLimit = RegExp(
    r'usage limit reached|rate limit|quota exceeded|overloaded',
  );

  /// Whether this is an AUTHENTICATION failure — this account's credential is
  /// no longer usable.
  ///
  /// Separate from [isCapacity] because the two heal differently: a spent plan
  /// comes back on its own at [resetsAt], while an expired OAuth token comes
  /// back only when a human signs in again. They share the one property the
  /// retry loop cares about, though — the failure is about the ACCOUNT, not
  /// about the run — so both belong on the next account rather than ending the
  /// turn. A bad model id or a rejected MCP config would fail identically
  /// everywhere and must keep not retrying.
  ///
  /// This was paid for: three pooled accounts, the third one's token expired
  /// mid-day, and every reviewer dispatched onto it died with
  /// `401 OAuth access token has expired` while two signed-in accounts sat
  /// unused next to it.
  bool get isAuth =>
      httpStatus == 401 ||
      httpStatus == 403 ||
      _authFailure.hasMatch(message.toLowerCase());

  static final RegExp _authFailure = RegExp(
    r'token has expired|re-?authenticate|failed to authenticate|'
    r'authentication_error|invalid api key|invalid bearer token|'
    r'not logged in|please run /login',
  );

  /// Extracts the reset time from Claude Code's
  /// `Claude AI usage limit reached|1787601441` sentence.
  ///
  /// The epoch is the useful half: it turns "come back later" into a time the
  /// operator (and the cooldown) can act on. Seconds vs milliseconds is
  /// disambiguated by magnitude — a seconds value for any plausible date is far
  /// below the millisecond threshold.
  static DateTime? parseResetEpoch(String message) {
    final match = RegExp(r'\|\s*(\d{9,14})').firstMatch(message);
    if (match == null) {
      return null;
    }
    final raw = int.tryParse(match.group(1)!);
    if (raw == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(
      raw > 100000000000 ? raw : raw * 1000,
    );
  }
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

  /// tool_use ids reported through `onToolCall` and not yet answered. See
  /// [_handleToolResults] for why an unknown id must not be paired.
  final Set<String> _openToolIds = {};

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
    // The terminal `result` event carries two things nothing else does: the
    // invocation's cumulative token usage, and `is_error: true` when the whole
    // turn failed (bad model id, rate-limit/overload, MCP-config rejection, …).
    // No `content_block_*` deltas precede such a failure, so this is the ONLY
    // error signal — surface it or the turn looks empty and only the exit code
    // shows. Usage is read FIRST and on both paths: a turn that ended in an
    // error still spent whatever it spent before dying, and dropping that is
    // what makes a failed run look free.
    if (type == 'result') {
      final usage = ClaudeUsage.tryFromResult(obj);
      if (usage != null) {
        _callbacks.onUsage?.call(usage);
      }
      if (obj['is_error'] == true) {
        final message = _errorMessage(obj);
        _callbacks.onError?.call(message);
        _callbacks.onTerminalError?.call(
          ClaudeTerminalError.fromResult(obj, message),
        );
      }
      return;
    }
    // Tool RESULTS are the one thing the `stream_event` lane never carries:
    // `claude` feeds them back as a top-level `user` message whose content is
    // a list of `tool_result` blocks.
    if (type == 'user') {
      final message = obj['message'];
      if (message is Map<String, dynamic>) {
        _handleToolResults(message['content']);
      }
      return;
    }
    // `system` (init) and `assistant` (the non-streamed replay of blocks we
    // already reconstructed from deltas) are not needed for live transcription.
  }

  void _handleToolResults(Object? content) {
    if (content is! List) {
      return;
    }
    for (final block in content) {
      if (block is! Map<String, dynamic> || block['type'] != 'tool_result') {
        continue;
      }
      final id = block['tool_use_id'] as String? ?? '';
      // Only close a call this parser actually opened. An unpaired id (a
      // subagent's inner tool, whose blocks never reach this stream) would
      // otherwise fall through the transcript's last-open-tool fallback and
      // close the wrong row — the parent `Task` call still in flight.
      if (!_openToolIds.remove(id)) {
        continue;
      }
      _callbacks.onToolResult?.call(
        ClaudeToolResult(
          id: id,
          outputs: _flattenResult(block['content']),
          isError: block['is_error'] == true,
        ),
      );
    }
  }

  /// Flattens a `tool_result` body: plain string, or the block list some tools
  /// (and MCP servers) return. Non-text blocks are named rather than dropped,
  /// so an image result reads as a result instead of as empty output.
  static String _flattenResult(Object? content) {
    if (content is String) {
      return content;
    }
    if (content is! List) {
      return content == null ? '' : jsonEncode(content);
    }
    final buf = StringBuffer();
    for (final block in content) {
      if (block is! Map) {
        continue;
      }
      if (block['type'] == 'text') {
        buf.write(block['text'] as String? ?? '');
      } else {
        buf.write('[${block['type'] ?? 'content'}]');
      }
    }
    return buf.toString();
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
    final id = block.id ?? '';
    if (id.isNotEmpty) {
      _openToolIds.add(id);
    }
    _callbacks.onToolCall?.call(
      ClaudeToolUse(id: id, name: block.name ?? '', input: input),
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
