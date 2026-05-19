import 'package:control_center/core/domain/value_objects/run_cost.dart';

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
  /// Error event.
  error,
  /// Sandbox violation — the OS denied a syscall (file read, network).
  sandboxViolation,
  /// Diagnostic event from the sandbox runtime itself (lifecycle markers,
  /// "launching pi", "exited cleanly", etc.).
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

// ---------------------------------------------------------------------------
// Concrete event subtypes
// ---------------------------------------------------------------------------

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

  @override
  Map<String, dynamic>? get metadata => {
        'toolCallId': toolCallId,
        'outputs': outputs,
        if (toolName != null) 'toolName': toolName,
        'isError': isError,
        if (isPartial) 'partial': true,
      };
}

/// Token usage / cost report from the agent.

class UsageEvent extends AgentProcessEvent {
  /// Creates a token usage report event.
  UsageEvent({
    required this.usage,
    this.durationMs,
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

  @override
  Map<String, dynamic>? get metadata => {
        'inputTokens': usage.inputTokens,
        'outputTokens': usage.outputTokens,
        if (usage.thoughtTokens > 0) 'thoughtTokens': usage.thoughtTokens,
        if (usage.cachedReadTokens > 0)
          'cachedReadTokens': usage.cachedReadTokens,
        if (usage.cachedWriteTokens > 0)
          'cachedWriteTokens': usage.cachedWriteTokens,
        'estimatedCostCents': usage.estimatedCostCents,
        if (durationMs != null) 'durationMs': durationMs,
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
  /// (e.g. `rate_limit_error`, `overloaded_error`, `relay_crash`). Drives
  /// deterministic failure classification ahead of the regex fallback.
  final String? code;

  /// Where the code came from (e.g. `anthropic`, `relay`, `pi`).
  final String? source;
}

/// Sandbox violation — the OS denied a syscall.

class SandboxViolationEvent extends AgentProcessEvent {
  /// Creates a sandbox policy violation event.
  SandboxViolationEvent({
    required this.content,
    this.action,
    this.target,
    this.suggestedCapability,
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

  /// Capability the user could grant to allow this.
  final String? suggestedCapability;

  @override
  Map<String, dynamic>? get metadata => {
        if (action != null) 'action': action,
        if (target != null) 'target': target,
        if (suggestedCapability != null)
          'suggestedCapability': suggestedCapability,
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
  DoneEvent({super.timestamp}) : content = '';

  @override
  AgentProcessEventType get type => AgentProcessEventType.done;

  @override
  final String content;
}
