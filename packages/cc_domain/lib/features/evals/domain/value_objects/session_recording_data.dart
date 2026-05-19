import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';

/// The ordered [LlmEvent]s a provider returned for ONE `complete()` call.
///
/// A recorded session is a list of these — one per agent-loop turn — so the
/// replay provider can hand the loop back the exact stream it saw when the
/// session was first run.
class RecordedLlmTurn {
  /// Creates a recorded turn from its ordered [events].
  const RecordedLlmTurn(this.events);

  /// Rebuilds a turn from its JSON form.
  factory RecordedLlmTurn.fromJson(Map<String, dynamic> json) =>
      RecordedLlmTurn([
        for (final e in (json['events'] as List).cast<Map<String, dynamic>>())
          _llmEventFromJson(e),
      ]);

  /// The provider events for this turn, in emission order.
  final List<LlmEvent> events;

  /// JSON form (round-trips through [RecordedLlmTurn.fromJson]).
  Map<String, dynamic> toJson() => {
    'events': [for (final e in events) _llmEventToJson(e)],
  };
}

/// A self-contained recording of one harness session: the inputs (config,
/// history, user message), every provider turn, every tool result, and the
/// canonical event-signature stream the harness produced (PRD 21 — "replay is
/// the primitive").
///
/// It serializes to plain JSON so a recorded session becomes a golden file
/// runnable under `dart test` with zero token cost: re-running it against the
/// live harness must reproduce [expectedEventSignatures] byte-for-byte, which
/// makes any harness change that alters behavior a red test.
class SessionRecordingData {
  /// Creates a recording.
  const SessionRecordingData({
    required this.configHash,
    required this.history,
    required this.userMessage,
    required this.llmTurns,
    required this.toolResults,
    required this.expectedEventSignatures,
  });

  /// Rebuilds a recording from its JSON form.
  factory SessionRecordingData.fromJson(
    Map<String, dynamic> json,
  ) => SessionRecordingData(
    configHash: json['configHash'] as String,
    history: [
      for (final m in (json['history'] as List).cast<Map<String, dynamic>>())
        Map<String, dynamic>.from(m),
    ],
    userMessage: json['userMessage'] as String,
    llmTurns: [
      for (final t in (json['llmTurns'] as List).cast<Map<String, dynamic>>())
        RecordedLlmTurn.fromJson(t),
    ],
    toolResults: {
      for (final e in (json['toolResults'] as Map).entries)
        e.key as String: _toolResultFromJson(
          (e.value as Map).cast<String, dynamic>(),
        ),
    },
    expectedEventSignatures: (json['expectedEventSignatures'] as List)
        .cast<String>(),
  );

  /// Fingerprint of the effective agent config the session ran under. Two
  /// recordings are only comparable when their hashes match (a config change
  /// legitimately re-keys the golden).
  final String configHash;

  /// The conversation history BEFORE the loop appended the user message, each
  /// entry a `HarnessMessage.toJson()` map.
  final List<Map<String, dynamic>> history;

  /// The user message that drove the run.
  final String userMessage;

  /// The provider turns, in call order (one per `complete()` call).
  final List<RecordedLlmTurn> llmTurns;

  /// Recorded tool results keyed by tool-call id (the provider-assigned id from
  /// the tool-use block). Replay returns these verbatim without executing.
  final Map<String, HarnessToolResult> toolResults;

  /// The canonical, timestamp-free event signatures the harness emitted — the
  /// byte-identical comparison unit for a replay.
  final List<String> expectedEventSignatures;

  /// Reconstructs the initial [history] as typed [HarnessMessage]s for the loop.
  List<HarnessMessage> toHistoryMessages() => [
    for (final m in history)
      HarnessMessage(
        role: _roleFromName(m['role'] as String),
        content: [
          for (final b in (m['content'] as List).cast<Map<String, dynamic>>())
            _blockFromJson(b),
        ],
      ),
  ];

  /// JSON form (round-trips through [SessionRecordingData.fromJson]).
  Map<String, dynamic> toJson() => {
    'configHash': configHash,
    'history': history,
    'userMessage': userMessage,
    'llmTurns': [for (final t in llmTurns) t.toJson()],
    'toolResults': {
      for (final e in toolResults.entries) e.key: _toolResultToJson(e.value),
    },
    'expectedEventSignatures': expectedEventSignatures,
  };
}

// ---------------------------------------------------------------------------
// Small local codecs. These round-trip only the fields replay needs, so a
// recording stays a plain-JSON, dependency-free golden file.
// ---------------------------------------------------------------------------

Map<String, dynamic> _llmEventToJson(LlmEvent event) {
  switch (event) {
    case LlmTextDelta(:final text):
      return {'type': 'text', 'text': text};
    case LlmThinkingDelta(:final thinking, :final signature):
      return {
        'type': 'thinking',
        'thinking': thinking,
        'signature': ?signature,
      };
    case LlmToolUseDelta(:final id, :final name, :final argumentsJson):
      return {
        'type': 'tool_use',
        'id': id,
        'name': name,
        'argumentsJson': argumentsJson,
      };
    case final LlmUsage usage:
      return {'type': 'usage', ..._usageFields(usage)};
    case LlmDone(:final stopReason, :final usage):
      return {
        'type': 'done',
        'stopReason': stopReason.name,
        if (usage != null) 'usage': _usageFields(usage),
      };
    case LlmError(
      :final message,
      :final code,
      :final retryable,
      :final retryAfterMs,
    ):
      return {
        'type': 'error',
        'message': message,
        'code': ?code,
        'retryable': retryable,
        'retryAfterMs': ?retryAfterMs,
      };
  }
}

LlmEvent _llmEventFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String;
  switch (type) {
    case 'text':
      return LlmTextDelta(json['text'] as String);
    case 'thinking':
      return LlmThinkingDelta(
        json['thinking'] as String,
        signature: json['signature'] as String?,
      );
    case 'tool_use':
      return LlmToolUseDelta(
        id: json['id'] as String,
        name: json['name'] as String,
        argumentsJson: json['argumentsJson'] as String,
      );
    case 'usage':
      return _usageFromJson(json);
    case 'done':
      final usage = json['usage'];
      return LlmDone(
        stopReason: _stopReasonFromName(json['stopReason'] as String),
        usage: usage is Map
            ? _usageFromJson(usage.cast<String, dynamic>())
            : null,
      );
    case 'error':
      return LlmError(
        json['message'] as String,
        code: json['code'] as String?,
        retryable: json['retryable'] as bool? ?? false,
        retryAfterMs: json['retryAfterMs'] as int?,
      );
    default:
      throw FormatException('Unknown LlmEvent type: $type');
  }
}

Map<String, dynamic> _usageFields(LlmUsage usage) => {
  'inputTokens': usage.inputTokens,
  'outputTokens': usage.outputTokens,
  'cacheReadTokens': usage.cacheReadTokens,
  'cacheWriteTokens': usage.cacheWriteTokens,
  'thoughtTokens': usage.thoughtTokens,
};

LlmUsage _usageFromJson(Map<String, dynamic> json) => LlmUsage(
  inputTokens: json['inputTokens'] as int? ?? 0,
  outputTokens: json['outputTokens'] as int? ?? 0,
  cacheReadTokens: json['cacheReadTokens'] as int? ?? 0,
  cacheWriteTokens: json['cacheWriteTokens'] as int? ?? 0,
  thoughtTokens: json['thoughtTokens'] as int? ?? 0,
);

LlmStopReason _stopReasonFromName(String name) => LlmStopReason.values
    .firstWhere((r) => r.name == name, orElse: () => LlmStopReason.unknown);

Map<String, dynamic> _toolResultToJson(HarnessToolResult result) => {
  'content': result.content,
  'isError': result.isError,
};

HarnessToolResult _toolResultFromJson(Map<String, dynamic> json) =>
    HarnessToolResult(
      content: json['content'] as String,
      isError: json['isError'] as bool? ?? false,
    );

HarnessRole _roleFromName(String name) => HarnessRole.values.firstWhere(
  (r) => r.name == name,
  orElse: () => HarnessRole.user,
);

HarnessContentBlock _blockFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String;
  switch (type) {
    case 'text':
      return HarnessTextBlock(json['text'] as String);
    case 'tool_use':
      return HarnessToolUseBlock(
        id: json['id'] as String,
        name: json['name'] as String,
        input: (json['input'] as Map).cast<String, dynamic>(),
      );
    case 'tool_result':
      return HarnessToolResultBlock(
        toolUseId: json['tool_use_id'] as String,
        content: json['content'] as String,
        isError: json['is_error'] as bool? ?? false,
      );
    case 'image':
      return HarnessImageBlock(
        data: json['data'] as String,
        mediaType: json['media_type'] as String,
      );
    case 'thinking':
      return HarnessThinkingBlock(
        json['thinking'] as String,
        signature: json['signature'] as String?,
      );
    default:
      throw FormatException('Unknown HarnessContentBlock type: $type');
  }
}
