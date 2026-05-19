import 'package:cc_harness/src/messages.dart';
import 'package:cc_harness/src/provider/reasoning_effort.dart';

/// The output-token ceiling used when nothing configures one.
///
/// A single hard-coded ceiling cannot fit every endpoint — published output
/// limits differ by an order of magnitude between a frontier API and a local
/// quant — so this is only the fallback for a provider that sets no
/// `maxTokens` of its own.
const int defaultHarnessMaxTokens = 8192;

/// Streaming events emitted by an [LlmProviderPort] while completing a request.
///
/// The agent loop consumes this stream and reassembles it into a complete
/// assistant turn. Every provider — SSE (Anthropic, OpenAI) or chunked
/// (local) — maps its wire protocol onto these events so the loop never sees
/// provider-specific framing.
sealed class LlmEvent {
  /// Const base constructor.
  const LlmEvent();
}

/// A chunk of streamed assistant text.
class LlmTextDelta extends LlmEvent {
  /// Creates a text delta.
  const LlmTextDelta(this.text);

  /// The incremental text.
  final String text;
}

/// A chunk of streamed extended-thinking text.
class LlmThinkingDelta extends LlmEvent {
  /// Creates a thinking delta.
  const LlmThinkingDelta(this.thinking, {this.signature});

  /// The incremental reasoning text.
  final String thinking;

  /// Opaque provider signature for the thinking block, emitted at block stop.
  final String? signature;
}

/// A complete tool-use request, emitted once the streamed input JSON for a
/// tool-use content block has fully arrived (at content-block-stop).
///
/// Providers accumulate partial JSON deltas internally and emit one of these
/// per tool call with the complete [argumentsJson]; the loop decodes it.
class LlmToolUseDelta extends LlmEvent {
  /// Creates a tool-use delta.
  const LlmToolUseDelta({
    required this.id,
    required this.name,
    required this.argumentsJson,
  });

  /// Provider-assigned tool-call id.
  final String id;

  /// Tool name.
  final String name;

  /// Accumulated JSON-encoded arguments string (`{}` when the model sent none).
  final String argumentsJson;
}

/// Token accounting for a request.
class LlmUsage extends LlmEvent {
  /// Creates a usage report.
  const LlmUsage({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cacheReadTokens = 0,
    this.cacheWriteTokens = 0,
    this.thoughtTokens = 0,
  });

  /// Non-cached input tokens.
  final int inputTokens;

  /// Output (completion) tokens.
  final int outputTokens;

  /// Cache-hit read tokens (discounted by the provider).
  final int cacheReadTokens;

  /// Cache-write tokens.
  final int cacheWriteTokens;

  /// Reasoning / thinking tokens, when reported separately.
  final int thoughtTokens;

  /// Merge two usage reports (later wins for non-additive context; counts sum).
  LlmUsage operator +(LlmUsage other) => LlmUsage(
    inputTokens: inputTokens + other.inputTokens,
    outputTokens: outputTokens + other.outputTokens,
    cacheReadTokens: cacheReadTokens + other.cacheReadTokens,
    cacheWriteTokens: cacheWriteTokens + other.cacheWriteTokens,
    thoughtTokens: thoughtTokens + other.thoughtTokens,
  );
}

/// Why a completion finished.
enum LlmStopReason {
  /// The model finished its turn with no pending tool calls.
  endTurn,

  /// The model emitted tool calls and is waiting for results.
  toolUse,

  /// The model hit the output-token ceiling mid-turn.
  maxTokens,

  /// A configured stop sequence matched.
  stopSequence,

  /// Provider did not report a recognized reason.
  unknown;

  /// Parses the provider's stop-reason string (Anthropic + OpenAI spellings).
  static LlmStopReason fromWire(String? raw) {
    switch (raw) {
      case 'end_turn':
      case 'stop':
        return LlmStopReason.endTurn;
      case 'tool_use':
      case 'tool_calls':
        return LlmStopReason.toolUse;
      case 'max_tokens':
      case 'length':
        return LlmStopReason.maxTokens;
      case 'stop_sequence':
        return LlmStopReason.stopSequence;
      default:
        return LlmStopReason.unknown;
    }
  }
}

/// Terminal event of a completion stream.
class LlmDone extends LlmEvent {
  /// Creates a done event.
  const LlmDone({this.stopReason = LlmStopReason.unknown, this.usage});

  /// Why the completion ended.
  final LlmStopReason stopReason;

  /// Final cumulative usage, when the provider reports it at the end.
  final LlmUsage? usage;
}

/// A provider-level error. Terminates the stream.
class LlmError extends LlmEvent {
  /// Creates an error event.
  const LlmError(
    this.message, {
    this.code,
    this.retryable = false,
    this.retryAfterMs,
  });

  /// Human-readable message.
  final String message;

  /// Machine-readable classification (e.g. `rate_limit_error`,
  /// `authentication_error`, `overloaded_error`) used for retry decisions.
  final String? code;

  /// Whether the loop may retry after backoff.
  final bool retryable;

  /// The server-supplied `Retry-After` delay in milliseconds, when present. The
  /// loop honors this instead of its computed backoff so a rate-limited request
  /// waits exactly as long as the provider asked.
  final int? retryAfterMs;
}

/// A tool definition handed to the provider so the model can call it.
class LlmToolSchema {
  /// Creates a tool schema.
  const LlmToolSchema({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  /// Tool name.
  final String name;

  /// Description shown to the model.
  final String description;

  /// JSON Schema for the tool input.
  final Map<String, dynamic> inputSchema;
}

/// How long a provider should keep a cached prefix alive.
enum LlmCacheTtl {
  /// The default short window. Free to refresh on every read, so a loop whose
  /// turns follow each other closely never needs anything longer.
  fiveMinutes('5m'),

  /// The long window, at a higher write premium.
  ///
  /// Worth it for a prefix that must survive a gap — an operator reading a
  /// diff, an approval waiting on a human, a turn that streams for minutes
  /// (the window is measured from when a request STARTS, so a long turn spends
  /// most of a short one). One avoided cold rebuild more than covers the extra
  /// write.
  oneHour('1h');

  const LlmCacheTtl(this.wire);

  /// The provider's wire spelling.
  final String wire;
}

/// Per-request completion parameters.
class LlmCompleteConfig {
  /// Creates a completion config.
  const LlmCompleteConfig({
    this.model,
    this.systemPrompt,
    this.maxTokens = defaultHarnessMaxTokens,
    this.temperature,
    this.topP,
    this.topK,
    this.stopSequences = const [],
    this.effort,
    this.cacheEnabled = true,
    this.cacheKey,
    this.toolCacheBreakpointIndex,
    this.cacheAnchorIndex,
    this.stablePrefixTtl = LlmCacheTtl.oneHour,
  });

  /// Overrides the provider default model.
  final String? model;

  /// System prompt (sent as a request field or a system message per provider).
  final String? systemPrompt;

  /// Maximum output tokens per turn.
  final int maxTokens;

  /// Sampling temperature, or null for the provider default.
  final double? temperature;

  /// Nucleus-sampling cutoff, or null for the provider default.
  ///
  /// Open-weights models routinely publish a required sampling recipe (Qwen-family
  /// reasoning models ship `top_p` and `top_k` alongside `temperature`) and drift
  /// out of their trained behavior — including out of their tool-call dialect —
  /// when served at other values. Omitting the field entirely left no way to
  /// honor those recipes.
  final double? topP;

  /// Top-k sampling cutoff, or null for the provider default. Not every
  /// OpenAI-compatible endpoint accepts it; it is only sent when set.
  final int? topK;

  /// Stop sequences.
  final List<String> stopSequences;

  /// Reasoning-effort level, or null to disable extended thinking / reasoning.
  /// Providers map it to their own wire form (see `effort_mapping.dart`).
  final ReasoningEffort? effort;

  /// Whether to request provider prompt caching (Anthropic `cache_control`
  /// breakpoints; OpenAI `prompt_cache_key`). Defaults on — the system + tools
  /// prefix is a large stable region worth caching.
  final bool cacheEnabled;

  /// Stable per-run key for providers with explicit cache keys (OpenAI). Null
  /// leaves caching to the provider's automatic prefix matching.
  final String? cacheKey;

  /// Index of the tool that carries the tools-array cache breakpoint.
  ///
  /// With a two-tier tool surface this must be the last RESIDENT tool, not the
  /// last tool sent: tools activated mid-run are appended after it, so putting
  /// the breakpoint at the end would move it every time one loads and rewrite
  /// the whole tools+system prefix. Anchored to the resident block, the prefix
  /// stays byte-identical and an activation costs only the appended schemas.
  /// Null means "the last tool", which is right when nothing is deferred.
  final int? toolCacheBreakpointIndex;

  /// Index into `messages` whose last block carries the cache READ anchor.
  ///
  /// The loop sets this to where the previous request's write breakpoint
  /// landed, so a hit is guaranteed rather than dependent on the provider's
  /// backward search finding it. That search only looks back a bounded number
  /// of content blocks, and one turn of parallel tool calls can easily emit
  /// more than that — at which point a single tail breakpoint silently misses
  /// and nothing in the response says so.
  final int? cacheAnchorIndex;

  /// TTL for the stable prefix (tools + system). The message tail always uses
  /// the short window: it is rewritten every turn regardless.
  final LlmCacheTtl stablePrefixTtl;

  /// Returns a copy with the given overrides.
  LlmCompleteConfig copyWith({
    String? model,
    String? systemPrompt,
    int? toolCacheBreakpointIndex,
    int? cacheAnchorIndex,
  }) => LlmCompleteConfig(
    model: model ?? this.model,
    systemPrompt: systemPrompt ?? this.systemPrompt,
    maxTokens: maxTokens,
    temperature: temperature,
    topP: topP,
    topK: topK,
    stopSequences: stopSequences,
    effort: effort,
    cacheEnabled: cacheEnabled,
    cacheKey: cacheKey,
    toolCacheBreakpointIndex:
        toolCacheBreakpointIndex ?? this.toolCacheBreakpointIndex,
    cacheAnchorIndex: cacheAnchorIndex ?? this.cacheAnchorIndex,
    stablePrefixTtl: stablePrefixTtl,
  );
}

/// A model advertised by a provider's own catalog endpoint.
///
/// `id` is the bare model id as the provider reports it (e.g. `claude-opus-4-8`);
/// callers compose the qualified `provider/model` id. Pricing is per-1M tokens
/// when the endpoint supplies it (e.g. OpenRouter), else null and enriched from
/// the models.dev catalog.
class ProviderModel {
  /// Creates a [ProviderModel].
  const ProviderModel({
    required this.id,
    this.displayName,
    this.inputCostPerMTokens,
    this.outputCostPerMTokens,
    this.contextWindow,
  });

  /// Bare provider-native model id.
  final String id;

  /// Friendly display name, when the endpoint provides one.
  final String? displayName;

  /// Input price per 1M tokens, when the endpoint provides it.
  final double? inputCostPerMTokens;

  /// Output price per 1M tokens, when the endpoint provides it.
  final double? outputCostPerMTokens;

  /// Context window in tokens, when the endpoint provides it.
  final int? contextWindow;
}

/// Talks to an LLM API and streams the completion as [LlmEvent]s.
///
/// Implementations live in the infrastructure layer (they own HTTP). The agent
/// loop depends only on this port, so it is provider-agnostic and the same
/// loop drives Anthropic, OpenAI, a local model, or a mock.
abstract interface class LlmProviderPort {
  /// Human-readable provider name (e.g. `Anthropic`).
  String get displayName;

  /// The model used when [LlmCompleteConfig.model] is null.
  String get defaultModel;

  /// Streams a completion for [messages] with the given [tools] and [config].
  ///
  /// The stream emits text / thinking / tool-use deltas, a [LlmUsage] when
  /// available and finishes with exactly one [LlmDone] or [LlmError].
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools,
    LlmCompleteConfig config,
  });

  /// Lists the models this provider currently offers, fetched from the
  /// provider's own catalog endpoint using its credential. Returns an empty
  /// list when the endpoint is unreachable or unsupported — the caller then
  /// falls back to the models.dev catalog.
  Future<List<ProviderModel>> listModels();
}
