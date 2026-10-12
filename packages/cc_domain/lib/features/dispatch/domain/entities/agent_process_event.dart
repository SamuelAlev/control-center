import 'package:cc_domain/core/domain/value_objects/llm_call_purpose.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/usage_scope.dart';
import 'package:cc_domain/features/observability/domain/run_stage.dart';

/// Agent process event type discriminant.
///
/// Used for log-line coalescing and lightweight consumers that only need the
/// kind label. The sealed class hierarchy below carries structured fields for
/// type-safe access in business logic.
enum AgentProcessEventType {
  /// Thinking event.
  thinking,

  /// Text event.
  text,

  /// Tool call event.
  toolCall,

  /// Tool result event.
  toolResult,

  /// Usage / token-count event.
  usage,

  /// A typed run-stage latency boundary (request sent, first byte, first model
  /// delta, first useful work, verified completion).
  stageTiming,

  /// The provider-reported size of the context the model just read.
  contextWindow,

  /// Error event.
  error,

  /// Sandbox violation — the OS denied a syscall (file read, network).
  sandboxViolation,

  /// Diagnostic event from the sandbox runtime itself (lifecycle markers,
  /// "launching claude", "exited cleanly", etc.).
  debug,

  /// Done event.
  done,
}

/// Extension on [AgentProcessEventType] for serialization.
extension AgentProcessEventTypeExtension on AgentProcessEventType {
  /// String name of this event type.
  String get name {
    switch (this) {
      case AgentProcessEventType.thinking:
        return 'thinking';
      case AgentProcessEventType.text:
        return 'text';
      case AgentProcessEventType.toolCall:
        return 'tool_call';
      case AgentProcessEventType.toolResult:
        return 'tool_result';
      case AgentProcessEventType.usage:
        return 'usage';
      case AgentProcessEventType.stageTiming:
        return 'stage_timing';
      case AgentProcessEventType.contextWindow:
        return 'context_window';
      case AgentProcessEventType.error:
        return 'error';
      case AgentProcessEventType.sandboxViolation:
        return 'sandbox_violation';
      case AgentProcessEventType.debug:
        return 'debug';
      case AgentProcessEventType.done:
        return 'done';
    }
  }

  /// Parses an [AgentProcessEventType] from a string value.
  static AgentProcessEventType fromString(String value) {
    switch (value) {
      case 'thinking':
        return AgentProcessEventType.thinking;
      case 'text':
      case 'message':
        return AgentProcessEventType.text;
      case 'tool_call':
        return AgentProcessEventType.toolCall;
      case 'tool_result':
        return AgentProcessEventType.toolResult;
      case 'usage':
        return AgentProcessEventType.usage;
      case 'stage_timing':
      case 'stagetiming':
        return AgentProcessEventType.stageTiming;
      case 'context_window':
        return AgentProcessEventType.contextWindow;
      case 'error':
      case 'stderr':
        return AgentProcessEventType.error;
      case 'sandbox_violation':
        return AgentProcessEventType.sandboxViolation;
      case 'debug':
        return AgentProcessEventType.debug;
      case 'done':
        return AgentProcessEventType.done;
      default:
        return AgentProcessEventType.text;
    }
  }
}

/// Sealed hierarchy of events emitted by an agent CLI process.
///
/// Each subtype carries structured fields for its payload. Use `event.type`
/// for lightweight discrimination or pattern-match on the sealed class for
/// type-safe field access.
///
/// Backwards-compatible: every subtype has a `content` getter that returns the
/// primary text payload so consumers that only read `.content` keep working.
sealed class AgentProcessEvent {
  AgentProcessEvent({DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  /// Type discriminant for this event.
  AgentProcessEventType get type;

  /// Primary text payload — kept for backwards compatibility with consumers
  /// that read `.content` on the base type.
  String get content;

  /// Optional metadata map — kept for backwards compatibility.
  Map<String, dynamic>? get metadata => null;

  /// Wall-clock time at which the event was observed by the dispatcher.
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentProcessEvent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          content == other.content;

  @override
  int get hashCode => Object.hash(type, content);
}

/// Agent produced visible text output.
class TextEvent extends AgentProcessEvent {
  /// Creates a text output event.
  TextEvent({required this.content, super.timestamp});

  @override
  AgentProcessEventType get type => AgentProcessEventType.text;

  @override
  final String content;
}

/// Agent produced thinking / reasoning output.
class ThinkingEvent extends AgentProcessEvent {
  /// Creates a thinking/reasoning output event.
  ThinkingEvent({required this.content, super.timestamp});

  @override
  AgentProcessEventType get type => AgentProcessEventType.thinking;

  @override
  final String content;
}

/// Agent invoked a tool.
class ToolCallEvent extends AgentProcessEvent {
  /// Creates a tool invocation event.
  ToolCallEvent({
    required this.toolName,
    required this.toolCallId,
    this.inputs,
    super.timestamp,
  }) : content = toolName;

  @override
  AgentProcessEventType get type => AgentProcessEventType.toolCall;

  @override
  final String content;

  /// Name of the tool being called.
  final String toolName;

  /// Unique id linking this call to its [ToolResultEvent].
  final String toolCallId;

  /// Structured tool input arguments.
  final Map<String, dynamic>? inputs;

  @override
  Map<String, dynamic>? get metadata => {
    'toolName': toolName,
    'toolCallId': toolCallId,
    if (inputs != null) 'inputs': inputs,
  };
}

/// Tool execution completed with a result.
class ToolResultEvent extends AgentProcessEvent {
  /// Creates a tool result event.
  ToolResultEvent({
    required this.toolCallId,
    required this.outputs,
    this.toolName,
    this.isError = false,
    this.isPartial = false,
    this.images = const [],
    super.timestamp,
  }) : content = outputs;

  @override
  AgentProcessEventType get type => AgentProcessEventType.toolResult;

  @override
  final String content;

  /// Id of the tool call this result belongs to.
  final String toolCallId;

  /// Tool result output text.
  final String outputs;

  /// Optional tool name.
  final String? toolName;

  /// Whether the tool execution resulted in an error.
  final bool isError;

  /// Whether this is a partial streaming result.
  final bool isPartial;

  /// Blob references for images the tool returned (screenshots, rendered
  /// output). Already externalized by the producer — this event never carries
  /// base64, so it stays cheap to fan out over the event bus and the relay.
  final List<ToolImageRef> images;

  @override
  Map<String, dynamic>? get metadata => {
    'toolCallId': toolCallId,
    'outputs': outputs,
    if (toolName != null) 'toolName': toolName,
    'isError': isError,
    if (isPartial) 'partial': true,
    if (images.isNotEmpty) 'images': [for (final i in images) i.toJson()],
  };
}

/// Token usage / cost report from the agent.

class UsageEvent extends AgentProcessEvent {
  /// Creates a token usage report event.
  ///
  /// [scope] decides how the report folds into the run's accumulated cost:
  /// [UsageScope.request] / [UsageScope.turn] are ADDITIVE deltas, while
  /// [UsageScope.runCumulative] is an ABSOLUTE snapshot that REPLACES the
  /// accumulated totals. A resumed CLI that reports whole-process totals must
  /// send the latter, or every turn doubles the run's spend.
  UsageEvent({
    required this.usage,
    this.durationMs,
    this.purpose = LlmCallPurpose.main,
    this.provider,
    this.modelId,
    this.attempt,
    this.requestId,
    this.scope = UsageScope.request,
    this.nativeSessionId,
    this.resumedNativeSession = false,
    super.timestamp,
  }) : content = '';

  @override
  AgentProcessEventType get type => AgentProcessEventType.usage;

  @override
  final String content;

  /// Token usage and cost breakdown.
  final RunUsage usage;

  /// Wall-clock duration for this measurement window, if reported.
  final int? durationMs;

  /// What the reported call(s) were for. Defaults to [LlmCallPurpose.main] so
  /// every existing adapter keeps its meaning without changes.
  final LlmCallPurpose purpose;

  /// Provider that served the call, when known.
  final String? provider;

  /// Model that ACTUALLY served the call, when known (a fallback or re-route
  /// is not the requested alias).
  final String? modelId;

  /// 1-based attempt number for calls sharing [requestId], when known.
  final int? attempt;

  /// Id of the request this report belongs to, when the adapter assigns one.
  final String? requestId;

  /// How this report folds into the run's totals.
  final UsageScope scope;

  /// The adapter's OWN session/thread id for this run (e.g. a Claude CLI
  /// session id), when it has one.
  ///
  /// Recorded as data rather than prose: the evaluation's resume-vs-fresh
  /// stratum has to be derivable from stored runs, and a `DebugEvent` line is
  /// not a queryable field.
  final String? nativeSessionId;

  /// Whether this run RESUMED a native session ([nativeSessionId]) rather than
  /// starting a fresh one.
  final bool resumedNativeSession;

  @override
  Map<String, dynamic>? get metadata => {
    'inputTokens': usage.inputTokens,
    'outputTokens': usage.outputTokens,
    if (usage.thoughtTokens > 0) 'thoughtTokens': usage.thoughtTokens,
    if (usage.cachedReadTokens > 0) 'cachedReadTokens': usage.cachedReadTokens,
    if (usage.cachedWriteTokens > 0)
      'cachedWriteTokens': usage.cachedWriteTokens,
    'estimatedCostCents': usage.estimatedCostCents,
    if (usage.costMicros != 0) 'costMicros': usage.costMicros,
    if (usage.costBasis != CostBasis.estimated)
      'costBasis': usage.costBasis.name,
    if (durationMs != null) 'durationMs': durationMs,
    if (purpose != LlmCallPurpose.main) 'purpose': purpose.wire,
    if (provider != null) 'provider': provider,
    if (modelId != null) 'modelId': modelId,
    if (attempt != null) 'attempt': attempt,
    if (requestId != null) 'requestId': requestId,
    if (scope != UsageScope.request) 'scope': scope.wire,
    if (nativeSessionId != null) 'nativeSessionId': nativeSessionId,
    if (resumedNativeSession) 'resumedNativeSession': true,
  };
}

/// One observed run-stage latency boundary.
///
/// The stream processors emit these instead of deriving a single "TTFT" from
/// the first text event: a thinking-first or tool-first run does useful work
/// while that number is unset, and the old derivation silently reported
/// context-assembly time as if it were provider latency. Stages that cannot be
/// observed are simply NOT emitted — an absent stage is unknown, and a consumer
/// must never render it as zero.
class StageTimingEvent extends AgentProcessEvent {
  /// Creates a stage timing event.
  StageTimingEvent({
    required this.stage,
    required this.offsetMs,
    required this.source,
    this.durationMs,
    this.provider,
    this.modelId,
    this.requestId,
    super.timestamp,
  }) : content = '';

  @override
  AgentProcessEventType get type => AgentProcessEventType.stageTiming;

  @override
  final String content;

  /// Which boundary this marks.
  final RunStage stage;

  /// Milliseconds from run start to this boundary.
  final int offsetMs;

  /// Who observed it (provider, transport, adapter, harness).
  final RunTimingSource source;

  /// Milliseconds this stage itself took, when it closes a span.
  final int? durationMs;

  /// Provider id, when the boundary is provider/transport specific.
  final String? provider;

  /// Model id, when known.
  final String? modelId;

  /// Physical request identity for retry-safe latency intervals.
  final String? requestId;

  /// This timing as a domain value, for folding into a run profile.
  RunStageTiming toTiming() => RunStageTiming(
    stage: stage,
    offsetMs: offsetMs,
    source: source,
    durationMs: durationMs,
    provider: provider,
    modelId: modelId,
    requestId: requestId,
  );

  @override
  Map<String, dynamic>? get metadata => {
    'stage': stage.wire,
    'offsetMs': offsetMs,
    'source': source.wire,
    if (durationMs != null) 'durationMs': durationMs,
    if (provider != null) 'provider': provider,
    if (modelId != null) 'modelId': modelId,
    if (requestId != null) 'requestId': requestId,
  };
}

/// How full the model's context window was on its latest call, as the
/// provider reported it.
///
/// Spend ([UsageEvent]) and occupancy are different questions: a turn's usage
/// sums every call it made, while this is the size of ONE request — the
/// prompt the model actually read (uncached + cache read + cache write input)
/// plus what it wrote back, which the next call carries forward. Emitted once
/// per main-thread model call; the newest one wins.
class ContextWindowEvent extends AgentProcessEvent {
  /// Creates a context-window reading.
  ContextWindowEvent({
    required this.contextTokens,
    this.windowTokens,
    this.compactions = 0,
    super.timestamp,
  }) {
    if (contextTokens < 0) {
      throw ArgumentError.value(
        contextTokens,
        'contextTokens',
        'must be non-negative',
      );
    }
    if (compactions < 0) {
      throw ArgumentError.value(
        compactions,
        'compactions',
        'must be non-negative',
      );
    }
  }

  @override
  AgentProcessEventType get type => AgentProcessEventType.contextWindow;

  @override
  String get content => '';

  /// Tokens occupying the window after this call.
  final int contextTokens;

  /// The window those tokens are measured against, when the runner knows it.
  final int? windowTokens;

  /// Automatic compactions the runner performed so far in this run.
  final int compactions;

  @override
  Map<String, dynamic>? get metadata => {
    'contextTokens': contextTokens,
    'windowTokens': ?windowTokens,
    if (compactions > 0) 'compactions': compactions,
  };
}

/// Error from the agent process.

class ErrorEvent extends AgentProcessEvent {
  /// Creates an agent error event.
  ErrorEvent({required this.content, this.code, this.source, super.timestamp});

  @override
  AgentProcessEventType get type => AgentProcessEventType.error;

  @override
  final String content;

  /// Structured machine-readable error code from the adapter, when reported
  /// (e.g. `rate_limit_error`, `overloaded_error`). Drives deterministic
  /// failure classification ahead of the regex fallback.
  final String? code;

  /// Where the code came from (e.g. `anthropic`).
  final String? source;
}

/// Sandbox violation — the OS denied a syscall.

class SandboxViolationEvent extends AgentProcessEvent {
  /// Creates a sandbox policy violation event.
  SandboxViolationEvent({
    required this.content,
    this.action,
    this.target,
    super.timestamp,
  });

  @override
  AgentProcessEventType get type => AgentProcessEventType.sandboxViolation;

  @override
  final String content;

  /// Denied action (e.g. "file-read", "network-connect").
  final String? action;

  /// Target of the denied action.
  final String? target;

  @override
  Map<String, dynamic>? get metadata => {
    if (action != null) 'action': action,
    if (target != null) 'target': target,
  };
}

/// Diagnostic / debug event from the sandbox runtime.

class DebugEvent extends AgentProcessEvent {
  /// Creates a diagnostic debug event.
  DebugEvent({required this.content, super.timestamp});

  @override
  AgentProcessEventType get type => AgentProcessEventType.debug;

  @override
  final String content;
}

/// Agent run completed.

class DoneEvent extends AgentProcessEvent {
  /// Creates an agent run completion event.
  ///
  /// [outcome] overrides the turn's outcome when the run ended cleanly but
  /// NOT as a plain completion (e.g. the loop hit its turn ceiling). Null
  /// means a normal completion; consumers that only care about "the process
  /// finished" can ignore it.
  DoneEvent({this.outcome, super.timestamp}) : content = '';

  @override
  AgentProcessEventType get type => AgentProcessEventType.done;

  @override
  final String content;

  /// Terminal outcome override, when the run ended without delivering.
  final TurnOutcome? outcome;
}
