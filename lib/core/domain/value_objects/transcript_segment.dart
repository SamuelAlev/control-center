import 'package:collection/collection.dart';

/// Terminal status of a [ToolSegment].
enum ToolSegmentStatus {
  /// The tool is currently executing (no result yet).
  running,

  /// The tool completed successfully.
  ok,

  /// The tool returned an error.
  error,

  /// The run ended (killed / crashed) before the tool produced a result.
  interrupted,
}

ToolSegmentStatus _statusFromString(String? raw) {
  switch (raw) {
    case 'ok':
      return ToolSegmentStatus.ok;
    case 'error':
      return ToolSegmentStatus.error;
    case 'interrupted':
      return ToolSegmentStatus.interrupted;
    case 'running':
    default:
      return ToolSegmentStatus.running;
  }
}

String _statusToString(ToolSegmentStatus s) => switch (s) {
      ToolSegmentStatus.running => 'running',
      ToolSegmentStatus.ok => 'ok',
      ToolSegmentStatus.error => 'error',
      ToolSegmentStatus.interrupted => 'interrupted',
    };

/// How an agent turn ended. Persisted as `metadata['outcome']`.
enum TurnOutcome {
  /// The agent finished normally (a `DoneEvent` was observed).
  completed,

  /// The run errored out before finishing.
  failed,

  /// The run ended (killed / crashed) without a `DoneEvent`.
  interrupted,
}

/// Parses a [TurnOutcome] from its persisted string, or null when absent.
TurnOutcome? turnOutcomeFromString(String? raw) {
  switch (raw) {
    case 'completed':
      return TurnOutcome.completed;
    case 'failed':
      return TurnOutcome.failed;
    case 'interrupted':
      return TurnOutcome.interrupted;
    default:
      return null;
  }
}

/// Serializes a [TurnOutcome] to its persisted string.
String turnOutcomeToString(TurnOutcome o) => switch (o) {
      TurnOutcome.completed => 'completed',
      TurnOutcome.failed => 'failed',
      TurnOutcome.interrupted => 'interrupted',
    };

/// A single ordered entry in an agent turn's transcript.
///
/// Segments are appended in the exact chronological order events arrive, so a
/// transcript faithfully interleaves reasoning, tool calls, and text the way a
/// Codex-style UI renders them. Persisted under
/// `ChannelMessage.metadata['segments']` as a JSON list (discriminated by the
/// `type` field) and streamed live via `TranscriptUpdate`.
sealed class TranscriptSegment {
  /// Creates a [TranscriptSegment].
  const TranscriptSegment({required this.startedAt, this.durationMs});

  /// When the segment was first observed.
  final DateTime startedAt;

  /// Wall-clock duration of the segment in milliseconds. Null while open.
  final int? durationMs;

  /// Encodes the segment to JSON (discriminated by `type`).
  Map<String, dynamic> toJson();

  /// Decodes a segment from JSON, dispatching on the `type` discriminator.
  static TranscriptSegment fromJson(Map<String, dynamic> json) {
    final startedAt = DateTime.fromMillisecondsSinceEpoch(
      (json['ts'] as num?)?.toInt() ?? 0,
    );
    final durationMs = (json['durationMs'] as num?)?.toInt();
    switch (json['type'] as String?) {
      case 'tool':
        return ToolSegment(
          toolName: json['toolName'] as String? ?? 'tool',
          toolCallId: json['toolCallId'] as String? ?? '',
          inputs: (json['inputs'] as Map?)?.cast<String, dynamic>(),
          outputs: json['outputs'] as String? ?? '',
          status: _statusFromString(json['status'] as String?),
          startedAt: startedAt,
          durationMs: durationMs,
        );
      case 'text':
        return TextSegment(
          text: json['text'] as String? ?? '',
          startedAt: startedAt,
          durationMs: durationMs,
        );
      case 'error':
        return ErrorSegment(
          message: json['message'] as String? ?? '',
          code: json['code'] as String?,
          source: json['source'] as String?,
          startedAt: startedAt,
          durationMs: durationMs,
        );
      case 'violation':
        return ViolationSegment(
          message: json['message'] as String? ?? '',
          action: json['action'] as String?,
          target: json['target'] as String?,
          suggestedCapability: json['suggestedCapability'] as String?,
          startedAt: startedAt,
          durationMs: durationMs,
        );
      case 'reasoning':
      default:
        return ReasoningSegment(
          text: json['text'] as String? ?? '',
          startedAt: startedAt,
          durationMs: durationMs,
        );
    }
  }
}

/// Free-form reasoning prose from the agent ("extended thinking").
class ReasoningSegment extends TranscriptSegment {
  /// Creates a [ReasoningSegment].
  const ReasoningSegment({
    required this.text,
    required super.startedAt,
    super.durationMs,
  });

  /// The reasoning markdown.
  final String text;

  /// Returns a copy with selected fields overridden.
  ReasoningSegment copyWith({String? text, int? durationMs}) => ReasoningSegment(
        text: text ?? this.text,
        startedAt: startedAt,
        durationMs: durationMs ?? this.durationMs,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'reasoning',
        'ts': startedAt.millisecondsSinceEpoch,
        if (text.isNotEmpty) 'text': text,
        if (durationMs != null) 'durationMs': durationMs,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReasoningSegment &&
          text == other.text &&
          startedAt == other.startedAt &&
          durationMs == other.durationMs;

  @override
  int get hashCode => Object.hash(text, startedAt, durationMs);
}

/// Visible answer text from the agent.
class TextSegment extends TranscriptSegment {
  /// Creates a [TextSegment].
  const TextSegment({
    required this.text,
    required super.startedAt,
    super.durationMs,
  });

  /// The answer markdown.
  final String text;

  /// Returns a copy with selected fields overridden.
  TextSegment copyWith({String? text, int? durationMs}) => TextSegment(
        text: text ?? this.text,
        startedAt: startedAt,
        durationMs: durationMs ?? this.durationMs,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'ts': startedAt.millisecondsSinceEpoch,
        if (text.isNotEmpty) 'text': text,
        if (durationMs != null) 'durationMs': durationMs,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextSegment &&
          text == other.text &&
          startedAt == other.startedAt &&
          durationMs == other.durationMs;

  @override
  int get hashCode => Object.hash(text, startedAt, durationMs);
}

/// A tool / MCP invocation, with its result merged into the same segment.
class ToolSegment extends TranscriptSegment {
  /// Creates a [ToolSegment].
  const ToolSegment({
    required this.toolName,
    required this.toolCallId,
    this.inputs,
    this.outputs = '',
    this.status = ToolSegmentStatus.running,
    required super.startedAt,
    super.durationMs,
  });

  /// Name of the tool (e.g. `Read`, `Edit`, `mcp__cc__create_ticket`).
  final String toolName;

  /// Id pairing the call with its result. May be `''` for legacy pi events.
  final String toolCallId;

  /// Parsed JSON tool arguments (e.g. `{file_path, old_string, new_string}`).
  final Map<String, dynamic>? inputs;

  /// Stringified tool output (accumulates partials; final result replaces it).
  final String outputs;

  /// Lifecycle status.
  final ToolSegmentStatus status;

  /// Whether the tool errored.
  bool get isError => status == ToolSegmentStatus.error;

  /// Returns a copy with selected fields overridden.
  ToolSegment copyWith({
    String? toolName,
    Map<String, dynamic>? inputs,
    String? outputs,
    ToolSegmentStatus? status,
    int? durationMs,
  }) =>
      ToolSegment(
        toolName: toolName ?? this.toolName,
        toolCallId: toolCallId,
        inputs: inputs ?? this.inputs,
        outputs: outputs ?? this.outputs,
        status: status ?? this.status,
        startedAt: startedAt,
        durationMs: durationMs ?? this.durationMs,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tool',
        'ts': startedAt.millisecondsSinceEpoch,
        'toolName': toolName,
        if (toolCallId.isNotEmpty) 'toolCallId': toolCallId,
        if (inputs != null) 'inputs': inputs,
        if (outputs.isNotEmpty) 'outputs': outputs,
        'status': _statusToString(status),
        if (durationMs != null) 'durationMs': durationMs,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolSegment &&
          toolName == other.toolName &&
          toolCallId == other.toolCallId &&
          const DeepCollectionEquality().equals(inputs, other.inputs) &&
          outputs == other.outputs &&
          status == other.status &&
          startedAt == other.startedAt &&
          durationMs == other.durationMs;

  @override
  int get hashCode => Object.hash(
        toolName,
        toolCallId,
        const DeepCollectionEquality().hash(inputs),
        outputs,
        status,
        startedAt,
        durationMs,
      );
}

/// An error emitted by the agent process.
class ErrorSegment extends TranscriptSegment {
  /// Creates an [ErrorSegment].
  const ErrorSegment({
    required this.message,
    this.code,
    this.source,
    required super.startedAt,
    super.durationMs,
  });

  /// Human-readable error message.
  final String message;

  /// Machine-readable error code from the adapter, when reported.
  final String? code;

  /// Where the code came from (e.g. `anthropic`, `relay`, `pi`).
  final String? source;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'error',
        'ts': startedAt.millisecondsSinceEpoch,
        'message': message,
        if (code != null) 'code': code,
        if (source != null) 'source': source,
        if (durationMs != null) 'durationMs': durationMs,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorSegment &&
          message == other.message &&
          code == other.code &&
          source == other.source &&
          startedAt == other.startedAt;

  @override
  int get hashCode => Object.hash(message, code, source, startedAt);
}

/// The sandbox blocked a syscall (file read, network connect, …).
class ViolationSegment extends TranscriptSegment {
  /// Creates a [ViolationSegment].
  const ViolationSegment({
    required this.message,
    this.action,
    this.target,
    this.suggestedCapability,
    required super.startedAt,
    super.durationMs,
  });

  /// Human-readable description of the denied action.
  final String message;

  /// Denied action (e.g. "file-read", "network-connect").
  final String? action;

  /// Target of the denied action.
  final String? target;

  /// Capability the user could grant to allow this.
  final String? suggestedCapability;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'violation',
        'ts': startedAt.millisecondsSinceEpoch,
        'message': message,
        if (action != null) 'action': action,
        if (target != null) 'target': target,
        if (suggestedCapability != null)
          'suggestedCapability': suggestedCapability,
        if (durationMs != null) 'durationMs': durationMs,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViolationSegment &&
          message == other.message &&
          action == other.action &&
          target == other.target &&
          suggestedCapability == other.suggestedCapability &&
          startedAt == other.startedAt;

  @override
  int get hashCode =>
      Object.hash(message, action, target, suggestedCapability, startedAt);
}

/// Decodes a transcript from a persisted `metadata['segments']` value.
///
/// Tolerant: non-list inputs yield an empty list, and non-map entries are
/// skipped rather than throwing.
List<TranscriptSegment> decodeTranscript(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  return [
    for (final e in raw)
      if (e is Map) TranscriptSegment.fromJson(e.cast<String, dynamic>()),
  ];
}

/// Encodes a transcript to a JSON list for persistence.
List<Map<String, dynamic>> encodeTranscript(List<TranscriptSegment> segments) =>
    segments.map((s) => s.toJson()).toList();
