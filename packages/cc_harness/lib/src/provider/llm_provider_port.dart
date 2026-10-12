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

/// Cumulative per-component token accounting within one request.
///
/// A provider may report only some components, or repeat a full snapshot.
/// Reconcile snapshots with component-wise maxima; sum separate requests.
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

  /// Total output tokens, including reasoning/thinking when present.
  final int outputTokens;

  /// Cache-hit read tokens (discounted by the provider).
  final int cacheReadTokens;

  /// Cache-write tokens.
  final int cacheWriteTokens;

  /// Reasoning/thinking subset of [outputTokens], when reported.
  final int thoughtTokens;

  /// Adds independent usage deltas or separate calls.
  LlmUsage operator +(LlmUsage other) => LlmUsage(
    inputTokens: inputTokens + other.inputTokens,
    outputTokens: outputTokens + other.outputTokens,
    cacheReadTokens: cacheReadTokens + other.cacheReadTokens,
    cacheWriteTokens: cacheWriteTokens + other.cacheWriteTokens,
    thoughtTokens: thoughtTokens + other.thoughtTokens,
  );

  /// Reconciles accumulated deltas with a cumulative final report without
  /// counting the same tokens twice or losing a partially reported component.
  LlmUsage reconcile(LlmUsage? cumulative) {
    if (cumulative == null) {
      return this;
    }
    final input = _larger(inputTokens, cumulative.inputTokens);
    final output = _larger(outputTokens, cumulative.outputTokens);
    final read = _larger(cacheReadTokens, cumulative.cacheReadTokens);
    final write = _larger(cacheWriteTokens, cumulative.cacheWriteTokens);
    final thought = _larger(thoughtTokens, cumulative.thoughtTokens);
    if (input == inputTokens &&
        output == outputTokens &&
        read == cacheReadTokens &&
        write == cacheWriteTokens &&
        thought == thoughtTokens) {
      return this;
    }
    if (input == cumulative.inputTokens &&
        output == cumulative.outputTokens &&
        read == cumulative.cacheReadTokens &&
        write == cumulative.cacheWriteTokens &&
        thought == cumulative.thoughtTokens) {
      return cumulative;
    }
    return LlmUsage(
      inputTokens: input,
      outputTokens: output,
      cacheReadTokens: read,
      cacheWriteTokens: write,
      thoughtTokens: thought,
    );
  }

  static int _larger(int a, int b) => a > b ? a : b;
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

/// Why a completion was requested.
///
/// Attribution exists because a run's cost is the sum of EVERY call it makes,
/// not just its main turns. The probe that motivated this measured a real
/// compaction through the loop: the provider billed 918 input tokens for one
/// summarization request plus one main request, while the loop accounted for
/// 17. Work moved into an auxiliary call made the run *look* cheaper. Tagging
/// the purpose at the call site is what lets a ledger price every caller —
/// main turns, compactions, advisor reviews, side requests, subagent turns —
/// against the same budget.
enum LlmCallPurpose {
  /// The primary agent turn.
  main,

  /// Context compaction / summarization.
  compaction,

  /// A watchdog/advisor review.
  advisor,

  /// A one-off side question or handoff document.
  sideRequest,

  /// A subagent's own turns.
  subagent;

  /// The wire spelling used by the observability/accounting layer.
  String get wire => switch (this) {
    LlmCallPurpose.main => 'main',
    LlmCallPurpose.compaction => 'compaction',
    LlmCallPurpose.advisor => 'advisor',
    LlmCallPurpose.sideRequest => 'side_request',
    LlmCallPurpose.subagent => 'subagent',
  };

  /// Parses [wire]; an unknown value degrades to [LlmCallPurpose.main].
  static LlmCallPurpose fromWire(String? raw) => switch (raw) {
    'compaction' => LlmCallPurpose.compaction,
    'advisor' => LlmCallPurpose.advisor,
    'side_request' => LlmCallPurpose.sideRequest,
    'subagent' => LlmCallPurpose.subagent,
    _ => LlmCallPurpose.main,
  };
}

/// Per-call instrumentation a provider's transport reports into.
///
/// The usage ledger creates one per completed request and hands it to the
/// provider through [LlmCompleteConfig.trace]; a provider that can observe
/// these boundaries calls the hooks, and one that cannot leaves them uncalled.
/// Nothing is ever inferred on the provider's behalf: an unobserved boundary
/// stays `null` in the resulting record rather than being back-filled from a
/// nearby timestamp, so a CLI adapter whose output is buffered never publishes
/// a fabricated time-to-first-byte.
class LlmCallTrace {
  /// Creates a trace.
  const LlmCallTrace();

  /// The HTTP transport committed the request body, after encoding/connect.
  /// Unobservable providers leave this unset; this is not a socket timestamp.
  void requestSent() {}

  /// The transport received the first response BODY byte.
  ///
  /// Fires at most once per call (first boundary wins — an auth-retry's second
  /// response does not move it) and never fires for a response with no body, so
  /// an unobserved boundary stays null rather than being inferred.
  ///
  /// It is a body-byte boundary, NOT a wire first-byte one: response headers
  /// complete earlier, and the first TCP/TLS byte is not observable from the
  /// client at all. The interval between this timestamp and the first model
  /// delta is server generation plus transport plus queueing — do not attribute
  /// it to the network, or to the model, from this metric alone.
  void transportFirstByte() {}

  /// The provider learned which model actually served the request (a proxy or
  /// router can serve a different one than was asked for).
  void servedModel(String model) {}
}

/// A tool definition handed to the provider so the model can call it.
class LlmToolSchema {
  /// Creates a tool schema.
  const LlmToolSchema({
    required this.name,
    required this.description,
    required this.inputSchema,
    this.deferLoading = false,
  });

  /// Tool name.
  final String name;

  /// Description shown to the model.
  final String description;

  /// JSON Schema for the tool input.
  final Map<String, dynamic> inputSchema;

  /// Whether the provider should keep this definition OUT of the model's
  /// working context until the model discovers it (Anthropic's native deferred
  /// loading / tool search).
  ///
  /// The definition is still SENT in full — `defer_loading` controls what
  /// enters the context window, not what travels on the wire, and the API needs
  /// the schema server-side to expand a `tool_reference` back into it. A
  /// provider without a native deferral mechanism ignores this flag and sends
  /// the tool normally, which is exactly the pre-existing behavior.
  final bool deferLoading;

  /// Returns a copy with [deferLoading] overridden.
  LlmToolSchema copyWith({bool? deferLoading}) => LlmToolSchema(
    name: name,
    description: description,
    inputSchema: inputSchema,
    deferLoading: deferLoading ?? this.deferLoading,
  );
}

/// A provider that can defer tool definitions natively (Anthropic's tool
/// search: `defer_loading` + `tool_reference` blocks).
///
/// A capability interface rather than a member of [LlmProviderPort] so the many
/// existing implementations and test doubles stay valid, and so a caller must
/// ask explicitly instead of assuming every provider caches tools the same way
/// — sending `defer_loading` to an endpoint that does not understand it is a
/// rejected request, not a no-op.
abstract interface class LlmDeferredToolSupport {
  /// Whether this provider can defer tool loading for [model] (null = the
  /// provider's default model).
  bool supportsDeferredTools({String? model});
}

/// Whether [provider] can defer tool loading for [model].
///
/// The single check to use instead of `provider is LlmDeferredToolSupport`
/// (which would answer `true` for a wrapper whose delegate cannot).
bool providerSupportsDeferredTools(LlmProviderPort provider, {String? model}) =>
    switch (provider) {
      final LlmDeferredToolSupport capability =>
        capability.supportsDeferredTools(model: model),
      _ => false,
    };

/// A provider that can report which concrete provider/model actually served the
/// most recent request (credential rotation and cross-provider fallback chains
/// serve from a different target than the one that was configured).
///
/// Reported identity is a FALLBACK for a wrapper that had to instrument a whole
/// chain: it names only the target that finally served, so any earlier target
/// the chain consumed is not accounted separately. Instrument each entry's
/// provider when per-target accounting matters.
abstract interface class LlmServedIdentity {
  /// Provider id of the target that served the most recent completion.
  String get lastServedProviderId;

  /// Model of the target that served the most recent completion.
  String get lastServedModel;
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
    this.purpose = LlmCallPurpose.main,
    this.callId,
    this.trace,
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

  /// What this request is for, for usage attribution. Providers ignore it; the
  /// usage ledger reads it so an auxiliary call is priced against the same
  /// budget as a main turn instead of vanishing from the accounting.
  final LlmCallPurpose purpose;

  /// Correlation id for the LOGICAL request this call belongs to.
  ///
  /// One logical request can be attempted several times (the loop retries a
  /// retryable error with backoff). Sharing a [callId] across those attempts is
  /// what lets the ledger number them (`attempt` 1, 2, …) instead of presenting
  /// three identical-looking calls. Null yields `attempt: 1`.
  final String? callId;

  /// Optional per-call instrumentation sink, set by the usage ledger. A
  /// provider that can observe the transport/model boundaries reports them
  /// here; a provider that cannot simply never calls it.
  final LlmCallTrace? trace;

  /// Returns a copy with the given overrides.
  LlmCompleteConfig copyWith({
    String? model,
    String? systemPrompt,
    int? toolCacheBreakpointIndex,
    int? cacheAnchorIndex,
    LlmCallPurpose? purpose,
    String? callId,
    LlmCallTrace? trace,
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
    purpose: purpose ?? this.purpose,
    callId: callId ?? this.callId,
    trace: trace ?? this.trace,
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
