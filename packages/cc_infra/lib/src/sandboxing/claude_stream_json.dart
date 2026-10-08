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

/// Work a subagent (the `Agent` / `Task` tool) did inside a `claude -p` run.
///
/// `claude` reports a subagent on the same stdout as its parent, tagging each
/// line with `parent_tool_use_id`: the id of the spawn call it is working for.
/// The subagent's turns arrive as whole `assistant` / `user` messages (no
/// partial deltas), and its final answer only as the result of that spawn call
/// on the parent's lane.
sealed class ClaudeSubagentEvent {
  const ClaudeSubagentEvent(this.spawnToolUseId);

  /// The `tool_use` id of the spawn call this subagent is working for.
  final String spawnToolUseId;
}

/// `claude` started a subagent (`system` / `task_started`).
class ClaudeSubagentStarted extends ClaudeSubagentEvent {
  /// Creates a [ClaudeSubagentStarted].
  const ClaudeSubagentStarted(
    super.spawnToolUseId, {
    this.description,
    this.subagentType,
  });

  /// The short task description the parent gave it.
  final String? description;

  /// Which subagent definition runs it (`general-purpose`, `Explore`, …).
  final String? subagentType;
}

/// A whole text block the subagent wrote.
class ClaudeSubagentText extends ClaudeSubagentEvent {
  /// Creates a [ClaudeSubagentText].
  const ClaudeSubagentText(super.spawnToolUseId, this.text);

  /// The block's text.
  final String text;
}

/// A whole thinking block the subagent wrote.
class ClaudeSubagentThinking extends ClaudeSubagentEvent {
  /// Creates a [ClaudeSubagentThinking].
  const ClaudeSubagentThinking(super.spawnToolUseId, this.text);

  /// The block's reasoning text.
  final String text;
}

/// A tool call the subagent made.
class ClaudeSubagentToolCall extends ClaudeSubagentEvent {
  /// Creates a [ClaudeSubagentToolCall].
  const ClaudeSubagentToolCall(super.spawnToolUseId, this.call);

  /// The call, with its decoded input.
  final ClaudeToolUse call;
}

/// The result of one of the subagent's tool calls.
class ClaudeSubagentToolResult extends ClaudeSubagentEvent {
  /// Creates a [ClaudeSubagentToolResult].
  const ClaudeSubagentToolResult(super.spawnToolUseId, this.result);

  /// The result, paired to its call by id.
  final ClaudeToolResult result;
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

/// The size of ONE main-thread model call, from its `message_start` /
/// `message_delta` stream events.
///
/// Unlike [ClaudeUsage] (the invocation's summed spend), this is occupancy:
/// [promptTokens] is everything the model read on that call — uncached input
/// plus cache read plus cache write — and [outputTokens] what it has written
/// back so far, which the next call carries forward.
class ClaudeCallUsage {
  /// Creates a [ClaudeCallUsage].
  const ClaudeCallUsage({required this.promptTokens, this.outputTokens = 0});

  /// Input tokens the call read, cached or not.
  final int promptTokens;

  /// Output tokens produced by the call so far.
  final int outputTokens;

  /// Tokens in the window once this call's output joins the context.
  int get contextTokens => promptTokens + outputTokens;
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
    this.onCallUsage,
    this.onCompactBoundary,
    this.onError,
    this.onTerminalError,
    this.onSubagent,
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

  /// The newest main-thread call's size, on its `message_start` and again as
  /// its `message_delta` reports output. Subagent (`Task`) calls are skipped:
  /// they run in their own window, not the one the meter describes.
  final void Function(ClaudeCallUsage usage)? onCallUsage;

  /// `claude` auto-compacted (or was asked to compact) its own context.
  /// The argument is the size it compacted from, when reported.
  final void Function(int? preTokens)? onCompactBoundary;

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

  /// Work a subagent did, routed apart from the parent's own turn. Never
  /// reported through [onText] / [onToolCall] / [onToolResult]: those describe
  /// the parent, and a subagent's tool rows merged into it would read as the
  /// parent's own work.
  final void Function(ClaudeSubagentEvent event)? onSubagent;
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

  /// Prompt size of the main-thread call in flight, so its `message_delta`
  /// (which carries output only) can report the whole call.
  int? _callPromptTokens;

  /// Feeds one decoded NDJSON line. Unknown event shapes are ignored.
  void process(Map<String, dynamic> obj) {
    final type = obj['type'];
    final parent = obj['parent_tool_use_id'];
    if (type == 'stream_event') {
      final event = obj['event'];
      // A subagent's partial deltas (when a CLI sends them) would interleave
      // with the parent's own block indices; its whole `assistant` messages
      // below carry the same content, so they are the one lane read.
      if (event is Map<String, dynamic> && parent == null) {
        _handleCallUsage(event);
        _handleEvent(event);
      }
      return;
    }
    if (parent is String && parent.isNotEmpty) {
      _handleSubagentLine(parent, type, obj['message']);
      return;
    }
    if (type == 'system' && obj['subtype'] == 'task_started') {
      final spawnId = obj['tool_use_id'];
      final subagentType = obj['subagent_type'];
      // Background shells report `task_started` too; only a subagent names
      // the definition it runs.
      if (spawnId is String && spawnId.isNotEmpty && subagentType is String) {
        _callbacks.onSubagent?.call(
          ClaudeSubagentStarted(
            spawnId,
            description: obj['description'] as String?,
            subagentType: subagentType,
          ),
        );
      }
      return;
    }
    if (type == 'system' && obj['subtype'] == 'compact_boundary') {
      final meta = obj['compact_metadata'];
      final pre = meta is Map ? meta['pre_tokens'] : null;
      _callbacks.onCompactBoundary?.call(pre is num ? pre.toInt() : null);
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

  /// Routes one subagent line: its `assistant` blocks become text, thinking
  /// and tool calls, its `user` tool results close them. The `user` text that
  /// opens a subagent is the parent's prompt, already on the spawn call.
  void _handleSubagentLine(String spawnId, Object? type, Object? message) {
    final onSubagent = _callbacks.onSubagent;
    if (onSubagent == null || message is! Map<String, dynamic>) {
      return;
    }
    final content = message['content'];
    if (content is! List) {
      return;
    }
    for (final block in content) {
      if (block is! Map<String, dynamic>) {
        continue;
      }
      switch ((type, block['type'])) {
        case ('assistant', 'text'):
          final text = block['text'] as String? ?? '';
          if (text.isNotEmpty) {
            onSubagent(ClaudeSubagentText(spawnId, text));
          }
        case ('assistant', 'thinking'):
          final text = block['thinking'] as String? ?? '';
          if (text.isNotEmpty) {
            onSubagent(ClaudeSubagentThinking(spawnId, text));
          }
        case ('assistant', 'tool_use'):
          onSubagent(
            ClaudeSubagentToolCall(
              spawnId,
              ClaudeToolUse(
                id: block['id'] as String? ?? '',
                name: block['name'] as String? ?? '',
                input: block['input'],
              ),
            ),
          );
        case ('user', 'tool_result'):
          onSubagent(
            ClaudeSubagentToolResult(
              spawnId,
              ClaudeToolResult(
                id: block['tool_use_id'] as String? ?? '',
                outputs: _flattenResult(block['content']),
                isError: block['is_error'] == true,
              ),
            ),
          );
      }
    }
  }

  /// Reads one call's size off its `message_start` (prompt) and
  /// `message_delta` (output so far). A missing field reads as zero, matching
  /// [ClaudeUsage.tryFromResult].
  void _handleCallUsage(Map<String, dynamic> event) {
    int count(Map<dynamic, dynamic> usage, String key) {
      final value = usage[key];
      return value is num ? value.toInt() : 0;
    }

    switch (event['type']) {
      case 'message_start':
        final message = event['message'];
        final usage = message is Map ? message['usage'] : null;
        if (usage is! Map) {
          return;
        }
        final prompt =
            count(usage, 'input_tokens') +
            count(usage, 'cache_read_input_tokens') +
            count(usage, 'cache_creation_input_tokens');
        _callPromptTokens = prompt;
        _callbacks.onCallUsage?.call(
          ClaudeCallUsage(
            promptTokens: prompt,
            outputTokens: count(usage, 'output_tokens'),
          ),
        );
      case 'message_delta':
        final usage = event['usage'];
        final prompt = _callPromptTokens;
        if (usage is! Map || prompt == null) {
          return;
        }
        _callbacks.onCallUsage?.call(
          ClaudeCallUsage(
            promptTokens: prompt,
            outputTokens: count(usage, 'output_tokens'),
          ),
        );
    }
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
      // Only close a call this parser actually opened. An unpaired id would
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
