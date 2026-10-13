import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_infra/src/dispatch/render_media_image_refs.dart';
import 'package:cc_infra/src/sandboxing/claude_native_session.dart';

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
    this.images = const [],
    this.isError = false,
    this.isAsync = false,
  });

  /// The `tool_use_id` this result answers.
  final String id;

  /// Flattened result text.
  final String outputs;

  /// Durable image references from render_media, never inline base64.
  final List<ToolImageRef> images;

  /// Whether the tool reported a failure.
  final bool isError;

  /// The tool returned a background-launch acknowledgement, not its outcome.
  final bool isAsync;
}

/// Work a subagent (the `Agent` / `Task` tool) did inside a `claude -p` run.
///
/// `claude` reports a subagent on the same stdout as its parent, tagging each
/// line with `parent_tool_use_id`: the id of the spawn call it is working for.
/// The subagent's turns arrive as whole `assistant` / `user` messages (no
/// partial deltas). Foreground answers arrive as spawn-call results; background
/// completion arrives through task lifecycle messages.
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

/// Terminal outcomes reported by Claude's task lifecycle.
enum ClaudeSubagentStatus {
  /// The child finished successfully.
  completed,

  /// The child failed.
  failed,

  /// The child was stopped before finishing.
  stopped,
}

/// A background subagent ended independently of its spawn tool call.
class ClaudeSubagentFinished extends ClaudeSubagentEvent {
  /// Creates a [ClaudeSubagentFinished].
  const ClaudeSubagentFinished(
    super.spawnToolUseId, {
    required this.status,
    this.summary,
  });

  /// The task's terminal outcome.
  final ClaudeSubagentStatus status;

  /// The completion summary or failure reason, when supplied.
  final String? summary;
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

/// What ONE `claude -p` turn's terminal `result` event reports.
///
/// `claude` emits one `result` per turn in streaming-input mode (the mode this
/// adapter runs: `--input-format stream-json`), and the three figures on it
/// have THREE DIFFERENT scopes — conflating them is the accounting bug this
/// class documents against:
///
/// * [inputTokens] / [outputTokens] / the cache counts — `result.usage` — cover
///   ONLY that turn, and within it only the main agent loop. Subagent tokens
///   are excluded. So these are additive across turns and are the honest
///   "what this turn's main thread read and wrote".
/// * [costUsd] is `total_cost_usd`: the RUNNING total for the whole call so
///   far (plus the spend a resumed call restored from the session's
///   transcript). Summing it across turns double counts, so
///   [ClaudeAccountingLedger] deltas it against the previous result instead.
/// * [modelUsage] is the same running total, broken down per model, and it
///   DOES include subagent requests — so it is the whole-tree attribution,
///   while [inputTokens] is the main loop only. Adding one to the other is the
///   double count to avoid.
///
/// Both cumulative figures restart on `/clear`/`/new`, on a fork, and whenever
/// a session is resumed without its transcript having been saved — which is why
/// the ledger detects a SHRINKING cumulative rather than assuming growth.
///
/// All three are client-side ESTIMATES computed from a bundled price table;
/// on a subscription account nothing is billed per token and [costUsd] reads
/// as API-equivalent spend, not an invoice.
class ClaudeUsage {
  /// Creates a [ClaudeUsage].
  const ClaudeUsage({
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheReadTokens,
    required this.cacheWriteTokens,
    required this.costUsd,
    this.costReported = true,
    this.durationMs,
    this.timeToFirstTokenMs,
    this.modelUsage = const {},
    this.subtype,
    this.sessionId,
    this.numTurns,
  });

  /// Reads the usage block off a terminal `result` event.
  ///
  /// Returns null only when no token or monetary counters were supplied.
  /// A partial terminal result can still report spend without a `usage` block;
  /// preserve that observation rather than treating it as an unpriced turn.
  static ClaudeUsage? tryFromResult(Map<String, dynamic> obj) {
    final rawUsage = obj['usage'];
    final cost = obj['total_cost_usd'];
    final models = ClaudeModelUsage.mapFrom(
      obj['modelUsage'] ?? obj['model_usage'],
    );
    if (rawUsage is! Map<String, dynamic> &&
        !(cost is num && cost.isFinite && cost >= 0) &&
        models.isEmpty) {
      return null;
    }
    final usage = rawUsage is Map<String, dynamic>
        ? rawUsage
        : const <String, dynamic>{};
    int count(String key) {
      final value = usage[key];
      return value is num ? value.toInt() : 0;
    }

    final subtype = obj['subtype'];
    final sessionId = obj['session_id'];
    final numTurns = obj['num_turns'];
    return ClaudeUsage(
      inputTokens: count('input_tokens'),
      outputTokens: count('output_tokens'),
      cacheReadTokens: count('cache_read_input_tokens'),
      cacheWriteTokens: count('cache_creation_input_tokens'),
      costUsd: cost is num && cost.isFinite && cost >= 0 ? cost.toDouble() : 0,
      costReported: cost is num && cost.isFinite && cost >= 0,
      durationMs:
          _intOrNull(obj['duration_ms']) ?? _intOrNull(obj['duration_api_ms']),
      timeToFirstTokenMs: _intOrNull(obj['ttft_ms']),
      modelUsage: models,
      subtype: subtype is String ? subtype : null,
      sessionId: sessionId is String && sessionId.isNotEmpty ? sessionId : null,
      numTurns: numTurns is num ? numTurns.toInt() : null,
    );
  }

  static int? _intOrNull(Object? value) => value is num ? value.toInt() : null;

  /// Uncached input tokens for THIS turn's main loop.
  final int inputTokens;

  /// Output tokens for this turn's main loop (thinking folded in, as
  /// elsewhere).
  final int outputTokens;

  /// Input tokens this turn's main loop read from the prompt cache.
  final int cacheReadTokens;

  /// Input tokens this turn's main loop wrote to the prompt cache.
  final int cacheWriteTokens;

  /// `total_cost_usd`: the RUNNING estimate for the whole call so far.
  final double costUsd;

  /// Whether the terminal event actually supplied a usable cost counter.
  /// Missing cost is unknown, not a free turn.
  final bool costReported;

  /// Wall-clock duration `claude` measured for the turn, when it reported one.
  final int? durationMs;

  /// Time to first token, when reported.
  final int? timeToFirstTokenMs;

  /// Whole-tree per-model counters (`modelUsage`), cumulative like [costUsd].
  final Map<String, ClaudeModelUsage> modelUsage;

  /// The result subtype (`success`, `error_during_execution`,
  /// `error_max_budget_usd`, …) or null when the CLI omitted it.
  final String? subtype;

  /// The CLI's session id on this result, when reported.
  final String? sessionId;

  /// How many turns the call had run, when reported.
  final int? numTurns;

  /// [costUsd] in whole cents — the unit the legacy run-log axis stores.
  int get costCents => (costUsd * 100).round();

  /// [costUsd] in exact micro-USD (USD × 1e6), the unit the precise axis
  /// stores. Integer maths, so no float drift is introduced here.
  int get costMicros => (costUsd * 1000000).round();

  /// Whether every cost/token counter on this result is zero.
  ///
  /// A crash result (`error_during_execution`) may zero `usage`,
  /// `total_cost_usd` and `modelUsage` together; the ledger reads this to tell
  /// "nothing was spent" apart from "the numbers were lost", and does not
  /// overwrite a good baseline with the zeroes.
  bool get isTokenless =>
      inputTokens == 0 &&
      outputTokens == 0 &&
      cacheReadTokens == 0 &&
      cacheWriteTokens == 0 &&
      costUsd == 0 &&
      modelUsage.isEmpty;

  /// Whether this result reports a crash whose cost fields were zeroed.
  bool get isZeroedCrash => subtype == 'error_during_execution' && isTokenless;

  /// The whole-tree totals summed across every model in [modelUsage].
  ClaudeModelUsageSnapshot get wholeTreeTotals =>
      ClaudeModelUsage.totals(modelUsage.values);
}

/// One model's cumulative counters from a `result`'s `modelUsage`.
///
/// Whole-tree: `claude` includes the requests its subagents made, so these are
/// the right source for per-model token attribution. They are NOT added to the
/// per-turn main-loop tokens on the same result.
class ClaudeModelUsage {
  /// Creates a [ClaudeModelUsage].
  const ClaudeModelUsage({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cacheReadTokens = 0,
    this.cacheWriteTokens = 0,
    this.costUsd = 0,
    this.costBasis,
  });

  /// Uncached input tokens.
  final int inputTokens;

  /// Output tokens.
  final int outputTokens;

  /// Cache-hit read tokens.
  final int cacheReadTokens;

  /// Cache-write tokens.
  final int cacheWriteTokens;

  /// Estimated USD cost for this model's share.
  final double costUsd;

  /// Which price table priced the latest request (`list`, `managed`,
  /// `unknown`), when the CLI reports it.
  final String? costBasis;

  /// Total tokens across every category.
  int get totalTokens =>
      inputTokens + outputTokens + cacheReadTokens + cacheWriteTokens;

  /// Parses `modelUsage`, tolerating both the camelCase keys the CLI emits
  /// and the snake_case keys the Python SDK documents. A model entry that is
  /// not a map is skipped rather than throwing.
  static Map<String, ClaudeModelUsage> mapFrom(Object? raw) {
    if (raw is! Map) {
      return const {};
    }
    final out = <String, ClaudeModelUsage>{};
    for (final entry in raw.entries) {
      final name = entry.key;
      final value = entry.value;
      if (name is! String || value is! Map) {
        continue;
      }
      int count(List<String> keys) {
        for (final key in keys) {
          final v = value[key];
          if (v is num) {
            return v.toInt();
          }
        }
        return 0;
      }

      out[name] = ClaudeModelUsage(
        inputTokens: count(const ['inputTokens', 'input_tokens']),
        outputTokens: count(const ['outputTokens', 'output_tokens']),
        cacheReadTokens: count(const [
          'cacheReadInputTokens',
          'cache_read_input_tokens',
        ]),
        cacheWriteTokens: count(const [
          'cacheCreationInputTokens',
          'cache_creation_input_tokens',
        ]),
        costUsd: _numOrNull(value['costUSD'] ?? value['cost_usd']) ?? 0,
        costBasis: (value['costBasis'] ?? value['cost_basis']) as String?,
      );
    }
    return out;
  }

  static double? _numOrNull(Object? value) =>
      value is num ? value.toDouble() : null;

  /// Sums [usages] into one snapshot.
  static ClaudeModelUsageSnapshot totals(Iterable<ClaudeModelUsage> usages) {
    var input = 0;
    var output = 0;
    var read = 0;
    var write = 0;
    var cost = 0.0;
    for (final u in usages) {
      input += u.inputTokens;
      output += u.outputTokens;
      read += u.cacheReadTokens;
      write += u.cacheWriteTokens;
      cost += u.costUsd;
    }
    return ClaudeModelUsageSnapshot(
      inputTokens: input,
      outputTokens: output,
      cacheReadTokens: read,
      cacheWriteTokens: write,
      costUsd: cost,
    );
  }

  /// Sums [snapshots] into one snapshot — the whole-tree totals across every
  /// model in a cumulative `modelUsage` map.
  static ClaudeModelUsageSnapshot sumSnapshots(
    Iterable<ClaudeModelUsageSnapshot> snapshots,
  ) {
    var input = 0;
    var output = 0;
    var read = 0;
    var write = 0;
    var cost = 0.0;
    for (final s in snapshots) {
      input += s.inputTokens;
      output += s.outputTokens;
      read += s.cacheReadTokens;
      write += s.cacheWriteTokens;
      cost += s.costUsd;
    }
    return ClaudeModelUsageSnapshot(
      inputTokens: input,
      outputTokens: output,
      cacheReadTokens: read,
      cacheWriteTokens: write,
      costUsd: cost,
    );
  }

  /// The durable-store snapshot of this model's counters.
  ClaudeModelUsageSnapshot toSnapshot() => ClaudeModelUsageSnapshot(
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    cacheReadTokens: cacheReadTokens,
    cacheWriteTokens: cacheWriteTokens,
    costUsd: costUsd,
    costBasis: costBasis,
  );
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

/// One MCP server as `system/init` reports it.
class ClaudeMcpServerStatus {
  /// Creates a [ClaudeMcpServerStatus].
  const ClaudeMcpServerStatus({required this.name, required this.status});

  /// Server name as configured.
  final String name;

  /// Connection status (`connected`, `pending`, `failed`, …).
  final String status;

  /// Whether the server is usable right now. `pending` is NOT a failure: a
  /// remote server with a cached tool list connects lazily on first use.
  bool get isConnected => status == 'connected';
}

/// A `--mcp-config` entry `claude` skipped because it failed validation.
///
/// These never fail the run — the CLI exits cleanly — so this is the only
/// place a caller can learn the tool surface is smaller than intended.
class ClaudeMcpServerError {
  /// Creates a [ClaudeMcpServerError].
  const ClaudeMcpServerError({required this.name, this.type, this.message});

  /// Server name from the skipped entry.
  final String name;

  /// Skip category (`unknown_type`, `url_missing_type`, …), when reported.
  final String? type;

  /// Human-readable reason, when reported.
  final String? message;

  /// Parses an `mcp_server_errors` (or plugin-error) array, ignoring malformed
  /// entries. Falls back to a `plugin` key so the same shape can describe a
  /// plugin that failed to load.
  static List<ClaudeMcpServerError> listFrom(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    final out = <ClaudeMcpServerError>[];
    for (final entry in raw) {
      if (entry is! Map) {
        continue;
      }
      final name = entry['name'] ?? entry['plugin'];
      out.add(
        ClaudeMcpServerError(
          name: name is String ? name : '(unnamed)',
          type: entry['type'] as String?,
          message: entry['message'] as String?,
        ),
      );
    }
    return out;
  }
}

/// Startup metadata from `system/init`, the first event of a `claude -p` run.
///
/// This is the only place the run learns what the CLI ACTUALLY resolved: the
/// serving model, the live tool surface, whether the MCP servers connected,
/// and which protocol capabilities the version implements. Parsing it is what
/// lets the adapter feature-detect instead of assuming — e.g. whether deferred
/// tools are native here, and whether a session id is available to resume.
class ClaudeInitMetadata {
  /// Creates a [ClaudeInitMetadata].
  const ClaudeInitMetadata({
    this.sessionId,
    this.model,
    this.tools = const [],
    this.mcpServers = const [],
    this.mcpServerErrors = const [],
    this.capabilities = const [],
    this.pluginErrors = const [],
    this.pluginCount = 0,
    this.cwd,
    this.permissionMode,
    this.apiKeySource,
    this.claudeCodeVersion,
    this.outputStyle,
  });

  /// The native session id this run is writing to — what `--resume` takes.
  final String? sessionId;

  /// The model actually serving the run (not necessarily the requested id).
  final String? model;

  /// Names of the tools the session can call.
  final List<String> tools;

  /// MCP servers in the session, with their connection status.
  final List<ClaudeMcpServerStatus> mcpServers;

  /// `--mcp-config` entries skipped by validation.
  final List<ClaudeMcpServerError> mcpServerErrors;

  /// Protocol capabilities this CLI version implements (e.g.
  /// `interrupt_receipt_v1`). Absent before v2.1.205 — check it to
  /// feature-detect rather than comparing version strings.
  final List<String> capabilities;

  /// Plugin load-time errors, rendered as readable lines.
  final List<String> pluginErrors;

  /// How many plugins loaded successfully.
  final int pluginCount;

  /// Working directory the CLI resolved.
  final String? cwd;

  /// The permission mode in force.
  final String? permissionMode;

  /// Where the credential came from (`oauth`, `api_key`, …), when reported.
  final String? apiKeySource;

  /// The CLI's own version string, when reported.
  final String? claudeCodeVersion;

  /// The output style in force.
  final String? outputStyle;

  /// Whether every configured MCP server connected (or is connectable
  /// lazily). False when validation skipped an entry or a server failed.
  bool get mcpHealthy =>
      mcpServerErrors.isEmpty &&
      mcpServers.every((s) => s.isConnected || s.status == 'pending');

  /// Servers that neither connected nor are lazily pending.
  List<ClaudeMcpServerStatus> get failedMcpServers => [
    for (final s in mcpServers)
      if (!s.isConnected && s.status != 'pending') s,
  ];

  /// Parses a `system`/`init` event. Never throws: missing fields stay null or
  /// empty so a partial init is still useful.
  static ClaudeInitMetadata fromInit(Map<String, dynamic> obj) {
    List<String> strings(Object? raw) {
      if (raw is! List) {
        return const [];
      }
      return [
        for (final v in raw)
          if (v is String) v,
      ];
    }

    final servers = <ClaudeMcpServerStatus>[];
    final rawServers = obj['mcp_servers'];
    if (rawServers is List) {
      for (final entry in rawServers) {
        if (entry is! Map) {
          continue;
        }
        final name = entry['name'];
        final status = entry['status'];
        if (name is String) {
          servers.add(
            ClaudeMcpServerStatus(
              name: name,
              status: status is String ? status : 'unknown',
            ),
          );
        }
      }
    }

    final plugins = obj['plugins'];
    final rawPluginErrors = obj['plugin_errors'];
    final pluginErrors = <String>[];
    if (rawPluginErrors is List) {
      for (final entry in rawPluginErrors) {
        if (entry is! Map) {
          continue;
        }
        final name = entry['plugin'] ?? entry['name'] ?? 'plugin';
        final type = entry['type'];
        final message = entry['message'];
        pluginErrors.add(
          [
            '$name',
            if (type is String) type,
            if (message is String) message,
          ].join(': '),
        );
      }
    }

    final sessionId = obj['session_id'] ?? obj['sessionId'];
    final model = obj['model'];
    String? str(Object? value) =>
        value is String && value.isNotEmpty ? value : null;
    return ClaudeInitMetadata(
      sessionId: str(sessionId),
      model: str(model),
      tools: strings(obj['tools']),
      mcpServers: servers,
      mcpServerErrors: ClaudeMcpServerError.listFrom(
        obj['mcp_server_errors'] ?? obj['mcpServerErrors'],
      ),
      capabilities: strings(obj['capabilities']),
      pluginErrors: pluginErrors,
      pluginCount: plugins is List ? plugins.length : 0,
      cwd: str(obj['cwd']),
      permissionMode: str(obj['permissionMode'] ?? obj['permission_mode']),
      apiKeySource: str(obj['apiKeySource'] ?? obj['api_key_source']),
      claudeCodeVersion: str(obj['claude_code_version']),
      outputStyle: str(obj['output_style'] ?? obj['outputStyle']),
    );
  }

  /// Whether the session exposed at least one tool whose name starts with
  /// `mcp__` — i.e. the Control Center MCP surface actually connected.
  bool get hasControlCenterTools => tools.any((t) => t.startsWith('mcp__'));
}

/// A `system/api_retry` event: `claude` is about to retry a failed request.
///
/// Surfaced so retries are visible (and countable) instead of appearing as a
/// stall; it is NOT a failure of the turn.
class ClaudeApiRetry {
  /// Creates a [ClaudeApiRetry].
  const ClaudeApiRetry({
    required this.attempt,
    this.maxRetries,
    this.retryDelayMs,
    this.errorStatus,
    this.error,
  });

  /// Current attempt number, starting at 1.
  final int attempt;

  /// Total retries permitted for this failure's cause.
  final int? maxRetries;

  /// Milliseconds until the next attempt.
  final int? retryDelayMs;

  /// HTTP status of the failed attempt, when it got one.
  final int? errorStatus;

  /// Error category (`rate_limit`, `overloaded`, …), when reported.
  final String? error;

  /// Parses a retry event; a missing `attempt` reads as 1.
  static ClaudeApiRetry fromEvent(Map<String, dynamic> obj) {
    int? at(String key) {
      final v = obj[key];
      return v is num ? v.toInt() : null;
    }

    return ClaudeApiRetry(
      attempt: at('attempt') ?? 1,
      maxRetries: at('max_retries'),
      retryDelayMs: at('retry_delay_ms'),
      errorStatus: at('error_status'),
      error: obj['error'] as String?,
    );
  }
}

/// What ONE dispatch spent, accumulated from turn deltas.
///
/// A CLI reports CUMULATIVE totals that include everything the native session
/// did before this dispatch (restored on resume) and that restart at a reset or
/// an account switch. Neither is what a run-level meter wants, so the emitted
/// `UsageScope.runCumulative` snapshot is built from THESE dispatch-lifetime
/// sums instead: each turn's `costDeltaUsd` and whole-tree `modelUsageDeltas`,
/// added up across turns, resets and accounts.
///
/// The native cumulative figures stay where they belong — in the persisted
/// resume baseline — so the run's reported spend is never inflated by an
/// earlier dispatch's spend, and never loses an attempt that a reset or a
/// failover removed from the session's own counters.
class ClaudeDispatchTotals {
  /// Creates empty totals.
  ClaudeDispatchTotals();

  int _inputTokens = 0;
  int _outputTokens = 0;
  int _cacheReadTokens = 0;
  int _cacheWriteTokens = 0;
  int _costMicros = 0;
  bool _hasTokenData = false;
  bool _costUnavailable = false;

  /// Whether at least one result supplied token counters.
  ///
  /// Whole-tree deltas are preferred; missing model counters retain the known
  /// main-loop usage until a later snapshot reconciles it.
  bool get hasTokenData => _hasTokenData;

  /// Whether some dispatch spend was unobservable.
  bool get costUnavailable => _costUnavailable;

  /// Whole-tree input tokens attributed to this dispatch.
  int get inputTokens => _inputTokens;

  /// Whole-tree output tokens attributed to this dispatch.
  int get outputTokens => _outputTokens;

  /// Whole-tree cache-read tokens attributed to this dispatch.
  int get cacheReadTokens => _cacheReadTokens;

  /// Whole-tree cache-write tokens attributed to this dispatch.
  int get cacheWriteTokens => _cacheWriteTokens;

  /// Exact cost attributed to this dispatch, in micro-USD.
  int get costMicros => _costMicros;

  /// Whether nothing has been accounted yet.
  bool get isEmpty => _costMicros == 0 && totalTokens == 0;

  /// Total tokens attributed to this dispatch.
  int get totalTokens =>
      _inputTokens + _outputTokens + _cacheReadTokens + _cacheWriteTokens;

  /// Folds one reconciled token/cost delta into the dispatch.
  void add(ClaudeTurnAccounting turn) {
    _costMicros += turn.costDeltaMicros;
    _costUnavailable = _costUnavailable || turn.costUnavailable;
    _hasTokenData = true;
    final delta = turn.tokenDelta;
    _inputTokens += delta.inputTokens;
    _outputTokens += delta.outputTokens;
    _cacheReadTokens += delta.cacheReadTokens;
    _cacheWriteTokens += delta.cacheWriteTokens;
  }

  /// The dispatch's totals as one snapshot, for the cumulative event.
  ClaudeModelUsageSnapshot get snapshot => ClaudeModelUsageSnapshot(
    inputTokens: _inputTokens,
    outputTokens: _outputTokens,
    cacheReadTokens: _cacheReadTokens,
    cacheWriteTokens: _cacheWriteTokens,
    costUsd: _costMicros / 1000000,
  );
}

/// A persisted accounting baseline, so a resumed call does not re-count the
/// spend its transcript restored.
class ClaudeAccountingBaseline {
  /// Creates a [ClaudeAccountingBaseline].
  const ClaudeAccountingBaseline({
    this.cumulativeCostUsd = 0,
    this.modelUsage = const {},
    this.mainUsageSinceModels = const ClaudeModelUsageSnapshot(),
    this.turns = 0,
    this.restoredByCli = false,
  });

  /// The CLI's cumulative estimated cost at the last accounted result.
  final double cumulativeCostUsd;

  /// The CLI's cumulative whole-tree per-model usage at the last result.
  final Map<String, ClaudeModelUsageSnapshot> modelUsage;

  /// Main-loop usage already credited while whole-tree counters were absent.
  final ClaudeModelUsageSnapshot mainUsageSinceModels;

  /// Turns already accounted for.
  final int turns;

  /// Whether the CLI is expected to RESTORE these totals into the totals of a
  /// later resumed call.
  ///
  /// Claude only makes a session's totals durable on a NORMAL process exit,
  /// and versions before 2.1.277 do not restore them at all. A baseline that
  /// will not be restored must NOT be seeded into the ledger: the non-restored
  /// figures start from zero and already describe this dispatch's own spend, so
  /// deltaing them against an old baseline silently swallows the difference.
  final bool restoredByCli;
}

/// ONE turn's honest accounting, produced by [ClaudeAccountingLedger.record].
class ClaudeTurnAccounting {
  /// Creates a [ClaudeTurnAccounting].
  const ClaudeTurnAccounting({
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheReadTokens,
    required this.cacheWriteTokens,
    required this.costDeltaUsd,
    required this.cumulativeCostUsd,
    required this.cumulativeModelUsage,
    required this.modelUsageDeltas,
    required this.tokenDelta,
    required this.costReset,
    required this.costUnavailable,
    this.subtype,
  });

  /// This turn's main-loop input tokens (additive).
  final int inputTokens;

  /// This turn's main-loop output tokens (additive).
  final int outputTokens;

  /// This turn's main-loop cache-read tokens (additive).
  final int cacheReadTokens;

  /// This turn's main-loop cache-write tokens (additive).
  final int cacheWriteTokens;

  /// The cost this turn added: the delta of the cumulative `total_cost_usd`
  /// (which includes subagent spend) against the previous result.
  final double costDeltaUsd;

  /// The cumulative `total_cost_usd` after this turn (absolute).
  final double cumulativeCostUsd;

  /// The cumulative whole-tree per-model usage after this turn (absolute).
  final Map<String, ClaudeModelUsageSnapshot> cumulativeModelUsage;

  /// Per-model deltas for this turn — whole-tree, so NOT added to
  /// [inputTokens] &co.
  final Map<String, ClaudeModelUsageSnapshot> modelUsageDeltas;

  /// Observed run token increment, with main-loop fallback credited only once
  /// when a later whole-tree snapshot fills in missing model counters.
  final ClaudeModelUsageSnapshot tokenDelta;

  /// Whether the cumulative counters SHRANK, so the whole reported figure was
  /// folded in as a new baseline (a reset/fork/unsaved-resume boundary).
  final bool costReset;

  /// Whether the result was a crashed, zeroed one whose cost fields must not
  /// overwrite the last known good baseline.
  final bool costUnavailable;

  /// The result subtype this turn came from.
  final String? subtype;

  /// [costDeltaUsd] in whole cents (legacy axis).
  int get costDeltaCents => (costDeltaUsd * 100).round();

  /// [costDeltaUsd] in exact micro-USD.
  int get costDeltaMicros => (costDeltaUsd * 1000000).round();

  /// [cumulativeCostUsd] in exact micro-USD.
  int get cumulativeCostMicros => (cumulativeCostUsd * 1000000).round();

  /// Whole-tree token totals after this turn (summed across models).
  ClaudeModelUsageSnapshot get wholeTreeTotals =>
      ClaudeModelUsage.sumSnapshots(cumulativeModelUsage.values);

  /// Whether this turn added no cost and no tokens at all.
  bool get isEmpty =>
      inputTokens == 0 &&
      outputTokens == 0 &&
      cacheReadTokens == 0 &&
      cacheWriteTokens == 0 &&
      costDeltaUsd == 0;
}

/// Deltas `claude`'s CUMULATIVE result counters so nothing is counted twice.
///
/// The CLI reports, on every turn's `result`: per-turn main-loop `usage`
/// (additive) and CUMULATIVE `total_cost_usd` + `modelUsage` (running totals,
/// restored-and-included on resume). Turning those into a per-turn delta is
/// this class's only job, and it is where 4C is fixed:
///
/// * tokens come straight from the per-turn `usage` (additive);
/// * cost is `total - previousTotal`;
/// * a SHRINKING total (a `/clear`, a fork, a resume whose transcript was not
///   saved) is treated as a fresh baseline, so the whole figure is folded in
///   once rather than producing a negative delta;
/// * a zeroed crash result is ignored rather than overwriting a good baseline;
/// * `modelUsage` deltas give whole-tree attribution without adding subagent
///   tokens onto the main-loop totals.
///
/// Seeded from a persisted [ClaudeAccountingBaseline] so a RESUME — where the
/// CLI's totals restart by including the session's earlier spend — does not
/// double count that restored spend.
class ClaudeAccountingLedger {
  /// Creates a [ClaudeAccountingLedger], seeded from [baseline].
  ///
  /// A baseline whose [ClaudeAccountingBaseline.restoredByCli] is false is
  /// IGNORED: the CLI will not restore those totals, so the figures a resumed
  /// call reports are its own, and deltaing them against a baseline it never
  /// restored would swallow the difference.
  ClaudeAccountingLedger({ClaudeAccountingBaseline? baseline})
    : _cumulativeCostUsd = (baseline?.restoredByCli ?? false)
          ? (baseline?.cumulativeCostUsd ?? 0)
          : 0,
      _modelUsage = (baseline?.restoredByCli ?? false)
          ? {
              for (final e in (baseline?.modelUsage ?? const {}).entries)
                e.key: e.value,
            }
          : {},
      _turns = (baseline?.restoredByCli ?? false) ? (baseline?.turns ?? 0) : 0,
      _mainUsageSinceModels = (baseline?.restoredByCli ?? false)
          ? (baseline?.mainUsageSinceModels ?? const ClaudeModelUsageSnapshot())
          : const ClaudeModelUsageSnapshot();

  double _cumulativeCostUsd;
  Map<String, ClaudeModelUsageSnapshot> _modelUsage;
  int _turns;
  ClaudeModelUsageSnapshot _mainUsageSinceModels;

  /// The cumulative cost baseline in force.
  double get cumulativeCostUsd => _cumulativeCostUsd;

  /// The cumulative whole-tree per-model usage baseline in force.
  Map<String, ClaudeModelUsageSnapshot> get modelUsage =>
      Map.unmodifiable(_modelUsage);

  /// Turns accounted for.
  int get turns => _turns;

  /// The baseline to persist for a later resume.
  ClaudeAccountingBaseline get baseline => ClaudeAccountingBaseline(
    cumulativeCostUsd: _cumulativeCostUsd,
    modelUsage: Map.unmodifiable(_modelUsage),
    turns: _turns,
    mainUsageSinceModels: _mainUsageSinceModels,
  );

  /// Forgets all cumulative state. Called on `/clear`, `/new`, a fork, or an
  /// account switch: the CLI restarts its totals, so the old baseline no
  /// longer describes anything.
  void reset() {
    _cumulativeCostUsd = 0;
    _modelUsage = {};
    _turns = 0;
    _mainUsageSinceModels = const ClaudeModelUsageSnapshot();
  }

  /// Folds one `result` into the ledger and returns this turn's delta.
  ClaudeTurnAccounting record(ClaudeUsage usage) {
    // A crashed, zeroed result carries no information: keep the last good
    // baseline rather than letting the zeroes look like a `-total` reset.
    if (usage.isZeroedCrash && _cumulativeCostUsd > 0) {
      return ClaudeTurnAccounting(
        inputTokens: usage.inputTokens,
        outputTokens: usage.outputTokens,
        cacheReadTokens: usage.cacheReadTokens,
        cacheWriteTokens: usage.cacheWriteTokens,
        costDeltaUsd: 0,
        cumulativeCostUsd: _cumulativeCostUsd,
        cumulativeModelUsage: Map.unmodifiable(_modelUsage),
        modelUsageDeltas: const {},
        tokenDelta: const ClaudeModelUsageSnapshot(),
        costReset: false,
        costUnavailable: true,
        subtype: usage.subtype,
      );
    }

    final previousCost = _cumulativeCostUsd;
    final previousUsage = _modelUsage;
    final cumulative = usage.costReported ? usage.costUsd : previousCost;
    final shrank = cumulative < previousCost;
    final delta = shrank ? cumulative : cumulative - previousCost;

    final nextUsage = {
      for (final e in usage.modelUsage.entries) e.key: e.value.toSnapshot(),
    };
    final deltas = <String, ClaudeModelUsageSnapshot>{};
    for (final entry in nextUsage.entries) {
      final before =
          previousUsage[entry.key] ?? const ClaudeModelUsageSnapshot();
      deltas[entry.key] = shrank ? entry.value : entry.value.delta(before);
    }

    if (shrank) {
      _mainUsageSinceModels = const ClaudeModelUsageSnapshot();
    }
    final ClaudeModelUsageSnapshot tokenDelta;
    if (nextUsage.isEmpty) {
      tokenDelta = ClaudeModelUsageSnapshot(
        inputTokens: usage.inputTokens,
        outputTokens: usage.outputTokens,
        cacheReadTokens: usage.cacheReadTokens,
        cacheWriteTokens: usage.cacheWriteTokens,
      );
      _mainUsageSinceModels = ClaudeModelUsage.sumSnapshots([
        _mainUsageSinceModels,
        tokenDelta,
      ]);
    } else {
      tokenDelta = ClaudeModelUsage.sumSnapshots(
        deltas.values,
      ).delta(_mainUsageSinceModels);
      _mainUsageSinceModels = const ClaudeModelUsageSnapshot();
    }

    _cumulativeCostUsd = cumulative;
    if (nextUsage.isNotEmpty || shrank) {
      _modelUsage = nextUsage;
    }
    _turns++;

    return ClaudeTurnAccounting(
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      cacheReadTokens: usage.cacheReadTokens,
      cacheWriteTokens: usage.cacheWriteTokens,
      costDeltaUsd: delta,
      cumulativeCostUsd: cumulative,
      cumulativeModelUsage: Map.unmodifiable(_modelUsage),
      modelUsageDeltas: deltas,
      tokenDelta: tokenDelta,
      costReset: shrank,
      costUnavailable: !usage.costReported || usage.isZeroedCrash,
      subtype: usage.subtype,
    );
  }
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
    this.onInit,
    this.onConversationReset,
    this.onApiRetry,
    this.onError,
    this.onTerminalError,
    this.onSubagent,
    this.onResult,
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

  /// ONE turn's result accounting, from the terminal `result` event. Fires on
  /// a successful AND on a failed result — a turn that ended in an error still
  /// spent the tokens it spent.
  ///
  /// The fields have THREE scopes (see [ClaudeUsage]); the consumer is
  /// [ClaudeAccountingLedger], which deltas the cumulative ones.
  final void Function(ClaudeUsage usage)? onUsage;

  /// The newest main-thread call's size, on its `message_start` and again as
  /// its `message_delta` reports output. Subagent (`Task`) calls are skipped:
  /// they run in their own window, not the one the meter describes.
  final void Function(ClaudeCallUsage usage)? onCallUsage;

  /// `claude` auto-compacted (or was asked to compact) its own context.
  /// The argument is the size it compacted from, when reported.
  final void Function(int? preTokens)? onCompactBoundary;

  /// Startup metadata (`system/init`): the serving model, the live tool
  /// surface, MCP connection status/errors, and protocol capabilities. This is
  /// the only place the run can feature-detect the CLI instead of assuming.
  final void Function(ClaudeInitMetadata init)? onInit;

  /// The conversation was cleared (`/clear`, `/new`): the CLI restarted its
  /// cumulative totals. The argument is the session id the reset reports, if
  /// any (a reset may mint a new native session).
  final void Function(String? sessionId)? onConversationReset;

  /// `claude` is about to retry a failed request (`system/api_retry`).
  final void Function(ClaudeApiRetry retry)? onApiRetry;

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

  /// The turn ended: a terminal `result` event, successful or not, after
  /// [onUsage] and [onTerminalError] have seen it. With `--input-format
  /// stream-json` the process then waits for the next user message, so this
  /// is where the caller decides between writing one and closing stdin.
  final void Function()? onResult;
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
  final Map<String, String> _openToolNames = {};

  /// Task ids outlive spawn calls; resumed tasks may have a new spawn/run pair.
  final Map<String, ({String spawnId, String? runId})> _subagentTasks = {};
  final Set<String> _subagentSpawnIds = {};

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
    if (type == 'system' && _handleSubagentTask(obj)) {
      return;
    }
    if (parent is String && parent.isNotEmpty) {
      _handleSubagentLine(parent, type, obj);
      return;
    }
    if (type == 'system' && obj['subtype'] == 'init') {
      // Startup metadata: the serving model, the live tool surface, MCP
      // connection status/errors and protocol capabilities. The ONLY place the
      // run can feature-detect the CLI, and the only place the native session
      // id is announced.
      _callbacks.onInit?.call(ClaudeInitMetadata.fromInit(obj));
      return;
    }
    if (type == 'system' && obj['subtype'] == 'conversation_reset') {
      // `/clear` (or `/new`): the CLI restarted its cumulative totals, which
      // is what lets the ledger tell a reset from growth.
      final sessionId = obj['session_id'];
      _callbacks.onConversationReset?.call(
        sessionId is String && sessionId.isNotEmpty ? sessionId : null,
      );
      return;
    }
    if (type == 'system' && obj['subtype'] == 'api_retry') {
      _callbacks.onApiRetry?.call(ClaudeApiRetry.fromEvent(obj));
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
      _callbacks.onResult?.call();
      return;
    }
    // Tool RESULTS are the one thing the `stream_event` lane never carries:
    // `claude` feeds them back as a top-level `user` message whose content is
    // a list of `tool_result` blocks.
    if (type == 'user') {
      final message = obj['message'];
      if (message is Map<String, dynamic>) {
        _handleToolResults(
          message['content'],
          isAsync: _isAsyncResult(obj['tool_use_result']),
        );
      }
      return;
    }
    // `assistant` (the non-streamed replay of blocks we already reconstructed
    // from deltas) is not needed for live transcription; the `system`
    // subtypes that ARE needed (init, task lifecycle, compact_boundary,
    // conversation_reset, api_retry) are handled above.
  }

  bool _handleSubagentTask(Map<String, dynamic> obj) {
    final subtype = obj['subtype'];
    if (subtype == 'task_started') {
      final spawnId = obj['tool_use_id'];
      final subagentType = obj['subagent_type'];
      // Bash tasks share this lane but must never open an agent row.
      if (spawnId is String &&
          spawnId.isNotEmpty &&
          (subagentType is String || obj['task_type'] == 'local_agent')) {
        _subagentSpawnIds.add(spawnId);
        final taskId = obj['task_id'];
        if (taskId is String && taskId.isNotEmpty) {
          _subagentTasks[taskId] = (
            spawnId: spawnId,
            runId: obj['run_id'] as String?,
          );
        }
        _callbacks.onSubagent?.call(
          ClaudeSubagentStarted(
            spawnId,
            description: obj['description'] as String?,
            subagentType: subagentType is String ? subagentType : null,
          ),
        );
      }
      return true;
    }
    if (subtype != 'task_notification' && subtype != 'task_updated') {
      return false;
    }
    final task = _subagentTasks[obj['task_id']];
    final runId = obj['run_id'];
    if (task != null &&
        task.runId != null &&
        runId is String &&
        runId != task.runId) {
      return true;
    }
    final spawnId = obj['tool_use_id'] ?? task?.spawnId;
    if (spawnId is! String || !_subagentSpawnIds.contains(spawnId)) {
      return true;
    }
    final patch = obj['patch'];
    final data = subtype == 'task_updated' && patch is Map ? patch : obj;
    final status = switch (data['status']) {
      'completed' => ClaudeSubagentStatus.completed,
      'failed' => ClaudeSubagentStatus.failed,
      'stopped' || 'killed' => ClaudeSubagentStatus.stopped,
      _ => null,
    };
    if (status != null) {
      _callbacks.onSubagent?.call(
        ClaudeSubagentFinished(
          spawnId,
          status: status,
          summary: (data['summary'] ?? data['error']) as String?,
        ),
      );
    }
    return true;
  }

  /// Routes one subagent line: its `assistant` blocks become text, thinking
  /// and tool calls, its `user` tool results close them. The `user` text that
  /// opens a subagent is the parent's prompt, already on the spawn call.
  void _handleSubagentLine(
    String spawnId,
    Object? type,
    Map<String, dynamic> obj,
  ) {
    final onSubagent = _callbacks.onSubagent;
    final message = obj['message'];
    if (onSubagent == null || message is! Map<String, dynamic>) {
      return;
    }
    final content = message['content'];
    if (content is! List) {
      return;
    }
    _subagentSpawnIds.add(spawnId);
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
          final toolId = block['id'];
          if (toolId is String) {
            _openToolNames[toolId] = block['name'] as String? ?? '';
          }
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
          final toolId = block['tool_use_id'] as String? ?? '';
          final toolName = _openToolNames.remove(toolId);
          onSubagent(
            ClaudeSubagentToolResult(
              spawnId,
              ClaudeToolResult(
                id: block['tool_use_id'] as String? ?? '',
                outputs: _flattenResult(block['content']),
                images: renderMediaImageRefs(toolName, block['content']),
                isError: block['is_error'] == true,
                isAsync: _isAsyncResult(obj['tool_use_result']),
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

  void _handleToolResults(Object? content, {bool isAsync = false}) {
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
      final toolName = _openToolNames.remove(id);
      _callbacks.onToolResult?.call(
        ClaudeToolResult(
          id: id,
          outputs: _flattenResult(block['content']),
          isError: block['is_error'] == true,
          images: renderMediaImageRefs(toolName, block['content']),
          isAsync: isAsync,
        ),
      );
    }
  }

  static bool _isAsyncResult(Object? result) =>
      result is Map &&
      (result['status'] == 'async_launched' || result['isAsync'] == true);

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
      _openToolNames[id] = block.name ?? '';
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
