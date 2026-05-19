import 'package:collection/collection.dart';

/// Kind of an entry in a thinking transcript.
enum ThinkingEventKind {
  /// Free-form reasoning prose from the agent.
  reasoning,

  /// A tool / MCP invocation: contains [ThinkingEvent.toolName] and
  /// optionally a JSON [ThinkingEvent.inputs] map describing the args.
  toolCall,

  /// Result of the preceding [toolCall]. Paired into the same UI row.
  toolResult,

  /// An error emitted by the agent process.
  error,

  /// The sandbox blocked a syscall (file read, network).
  sandboxViolation,
}

ThinkingEventKind _kindFromString(String? raw) {
  switch (raw) {
    case 'tool_call':
      return ThinkingEventKind.toolCall;
    case 'tool_result':
      return ThinkingEventKind.toolResult;
    case 'error':
      return ThinkingEventKind.error;
    case 'sandbox_violation':
      return ThinkingEventKind.sandboxViolation;
    case 'reasoning':
    default:
      return ThinkingEventKind.reasoning;
  }
}

String _kindToString(ThinkingEventKind k) => switch (k) {
      ThinkingEventKind.reasoning => 'reasoning',
      ThinkingEventKind.toolCall => 'tool_call',
      ThinkingEventKind.toolResult => 'tool_result',
      ThinkingEventKind.error => 'error',
      ThinkingEventKind.sandboxViolation => 'sandbox_violation',
    };

/// A single entry in an agent's structured thinking transcript.
///
/// Persisted under `ChannelMessage.metadata['events']` as a JSON list and
/// streamed live during agent execution.
class ThinkingEvent {

  /// Decodes an entry from JSON.
  factory ThinkingEvent.fromJson(Map<String, dynamic> json) {
    final durationMs = json['durationMs'];
    return ThinkingEvent(
      kind: _kindFromString(json['kind'] as String?),
      content: json['content'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] as num?)?.toInt() ?? 0,
      ),
      duration: durationMs is num ? Duration(milliseconds: durationMs.toInt()) : null,
      toolName: json['toolName'] as String?,
      inputs: (json['inputs'] as Map?)?.cast<String, dynamic>(),
      outputs: json['outputs'] as String?,
    );
  }
  /// Creates a [ThinkingEvent].
  ThinkingEvent({
    required this.kind,
    required this.timestamp,
    this.content = '',
    this.duration,
    this.toolName,
    this.inputs,
    this.outputs,
  });

  /// What this entry represents.
  final ThinkingEventKind kind;

  /// Free-form payload (markdown reasoning, error message, raw tool output).
  final String content;

  /// When the event was observed.
  final DateTime timestamp;

  /// Duration between this event and the next one. Computed at persist time.
  final Duration? duration;

  /// Tool name when [kind] is [ThinkingEventKind.toolCall].
  final String? toolName;

  /// JSON-shaped inputs when [kind] is [ThinkingEventKind.toolCall].
  final Map<String, dynamic>? inputs;

  /// Stringified outputs when [kind] is [ThinkingEventKind.toolResult].
  final String? outputs;

  /// Returns a copy with selected fields overridden.
  ThinkingEvent copyWith({
    ThinkingEventKind? kind,
    String? content,
    DateTime? timestamp,
    Duration? duration,
    bool clearDuration = false,
    String? toolName,
    Map<String, dynamic>? inputs,
    String? outputs,
  }) {
    return ThinkingEvent(
      kind: kind ?? this.kind,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      duration: clearDuration ? null : (duration ?? this.duration),
      toolName: toolName ?? this.toolName,
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
    );
  }

  /// Encodes the entry to JSON.
  Map<String, dynamic> toJson() => {
        'kind': _kindToString(kind),
        if (content.isNotEmpty) 'content': content,
        'timestamp': timestamp.millisecondsSinceEpoch,
        if (duration != null) 'durationMs': duration!.inMilliseconds,
        if (toolName != null) 'toolName': toolName,
        if (inputs != null) 'inputs': inputs,
        if (outputs != null) 'outputs': outputs,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThinkingEvent &&
          kind == other.kind &&
          content == other.content &&
          timestamp == other.timestamp &&
          duration == other.duration &&
          toolName == other.toolName &&
          const DeepCollectionEquality().equals(inputs, other.inputs) &&
          outputs == other.outputs;

  @override
  int get hashCode => Object.hash(
        kind,
        content,
        timestamp,
        duration,
        toolName,
        const DeepCollectionEquality().hash(inputs),
        outputs,
      );
}

/// A reasoning event with its paired tool-call follow-up rows.
///
/// Each `toolCall` is grouped with the following consecutive `toolResult`
/// so the UI renders them as a single expandable row instead of two rows.
class ThinkingEventRow {
  /// Creates a [ThinkingEventRow].
  const ThinkingEventRow({required this.primary, this.result});

  /// The leading event (reasoning, toolCall, error, sandboxViolation).
  final ThinkingEvent primary;

  /// The paired result event when [primary] is a tool call.
  final ThinkingEvent? result;
}

/// Groups an ordered event list into UI rows by attaching each
/// [ThinkingEventKind.toolResult] to its preceding
/// [ThinkingEventKind.toolCall].
List<ThinkingEventRow> groupThinkingEvents(List<ThinkingEvent> events) {
  final rows = <ThinkingEventRow>[];
  for (var i = 0; i < events.length; i++) {
    final e = events[i];
    if (e.kind == ThinkingEventKind.toolResult) {
      // Already attached to the prior tool call below; skip standalone.
      if (rows.isNotEmpty &&
          rows.last.primary.kind == ThinkingEventKind.toolCall &&
          rows.last.result == null) {
        final prev = rows.removeLast();
        rows.add(ThinkingEventRow(primary: prev.primary, result: e));
        continue;
      }
      // Orphan result with no preceding call — render on its own row.
      rows.add(ThinkingEventRow(primary: e));
      continue;
    }
    rows.add(ThinkingEventRow(primary: e));
  }
  return rows;
}
