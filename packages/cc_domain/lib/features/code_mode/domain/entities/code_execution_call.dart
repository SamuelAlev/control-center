import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';

/// One nested tool call a script made: the durable `code_execution_calls` row.
///
/// Records what the gate decided and how the call ended, with bounded and
/// redacted arguments. The call's full result is not kept here: it went to the
/// script, and the transcript row under the `repl` call holds what the person
/// sees.
class CodeExecutionCall {
  /// Creates a call record.
  ///
  /// Throws [ArgumentError] when an id or name is empty, [sequence] is below
  /// one, a duration or size is negative, [argumentsJson] is over
  /// [maxArgumentsBytes] or [error] is over [maxErrorChars]. Use
  /// [boundArguments] and [boundError] to fit values first.
  CodeExecutionCall({
    required this.executionId,
    required this.sequence,
    required this.toolCallId,
    required this.toolName,
    required this.startOffsetMs,
    required this.durationMs,
    required this.status,
    this.gateDecision,
    this.approvalWaitMs = 0,
    this.argumentBytes = 0,
    this.resultBytes = 0,
    this.argumentsJson = '{}',
    this.error,
    this.site,
  }) {
    _requireNonEmpty(executionId, 'executionId');
    _requireNonEmpty(toolCallId, 'toolCallId');
    _requireNonEmpty(toolName, 'toolName');
    if (sequence < 1) {
      throw ArgumentError.value(sequence, 'sequence', 'must be at least 1');
    }
    for (final (value, name) in [
      (startOffsetMs, 'startOffsetMs'),
      (durationMs, 'durationMs'),
      (approvalWaitMs, 'approvalWaitMs'),
      (argumentBytes, 'argumentBytes'),
      (resultBytes, 'resultBytes'),
    ]) {
      if (value < 0) {
        throw ArgumentError.value(value, name, 'must not be negative');
      }
    }
    if (utf8Length(argumentsJson) > maxArgumentsBytes) {
      throw ArgumentError.value(
        argumentsJson.length,
        'argumentsJson',
        'must be at most $maxArgumentsBytes bytes',
      );
    }
    final e = error;
    if (e != null && e.length > maxErrorChars) {
      throw ArgumentError.value(
        e.length,
        'error',
        'must be at most $maxErrorChars characters',
      );
    }
  }

  /// Rebuilds from [toJson]'s output. An unknown status or gate decision
  /// throws [ArgumentError]; a malformed site is dropped
  /// ([ScriptCallSite.tryParse]).
  factory CodeExecutionCall.fromJson(Map<String, dynamic> json) =>
      CodeExecutionCall(
        executionId: json['execution_id'] as String? ?? '',
        sequence: (json['sequence'] as num?)?.toInt() ?? 0,
        toolCallId: json['tool_call_id'] as String? ?? '',
        toolName: json['tool_name'] as String? ?? '',
        startOffsetMs: (json['start_offset_ms'] as num?)?.toInt() ?? 0,
        durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
        status: NestedCallStatus.parse(json['status'] as String? ?? ''),
        gateDecision: switch (json['gate_decision']) {
          null => null,
          final Object raw => NestedCallGateDecision.parse(raw as String),
        },
        approvalWaitMs: (json['approval_wait_ms'] as num?)?.toInt() ?? 0,
        argumentBytes: (json['argument_bytes'] as num?)?.toInt() ?? 0,
        resultBytes: (json['result_bytes'] as num?)?.toInt() ?? 0,
        argumentsJson: json['arguments'] as String? ?? '{}',
        error: json['error'] as String?,
        site: ScriptCallSite.tryParse(json['site']),
      );

  /// The most redacted argument JSON a row keeps, in UTF-8 bytes.
  static const int maxArgumentsBytes = 8 * 1024;

  /// The most error text a row keeps.
  static const int maxErrorChars = 500;

  /// The transcript id of the [sequence]th nested call of the `repl` call
  /// [replToolCallId]: `<replToolCallId>/<sequence>`.
  ///
  /// Derived, not random, so a reconnecting client can place a nested row
  /// under its parent from the id alone.
  static String nestedToolCallId(String replToolCallId, int sequence) {
    if (replToolCallId.isEmpty) {
      throw ArgumentError.value(
        replToolCallId,
        'replToolCallId',
        'must not be empty',
      );
    }
    if (sequence < 1) {
      throw ArgumentError.value(sequence, 'sequence', 'must be at least 1');
    }
    return '$replToolCallId/$sequence';
  }

  /// Fits already-redacted argument JSON into [maxArgumentsBytes].
  ///
  /// Over the cap, the JSON is cut on a character boundary and closed with a
  /// marker that says how much was dropped. The result is then a display
  /// string, not parseable JSON, which is what a bounded audit field is for.
  static String boundArguments(String json) =>
      boundUtf8(json, maxArgumentsBytes);

  /// Fits an error message into [maxErrorChars].
  static String boundError(String error) {
    if (error.length <= maxErrorChars) {
      return error;
    }
    const marker = '…';
    var cut = maxErrorChars - marker.length;
    // Never split a surrogate pair: half a pair is not a character.
    if (cut > 0 && _isHighSurrogate(error.codeUnitAt(cut - 1))) {
      cut -= 1;
    }
    return '${error.substring(0, cut)}$marker';
  }

  /// The `repl` execution this call belongs to.
  final String executionId;

  /// One-based position in call order.
  final int sequence;

  /// The nested transcript id ([nestedToolCallId]).
  final String toolCallId;

  /// The tool's registered name.
  final String toolName;

  /// Milliseconds from the script's start to this call's start.
  final int startOffsetMs;

  /// Milliseconds from start to settle, waits included.
  final int durationMs;

  /// How the call ended.
  final NestedCallStatus status;

  /// What the gate decided, or null when the call never reached it.
  final NestedCallGateDecision? gateDecision;

  /// Milliseconds spent waiting on a person (an approval or an answer). Part
  /// of [durationMs]; not charged to the script's deadline. Not checked
  /// against [durationMs]: the two are measured in different places, and a
  /// few milliseconds of skew must never veto an audit row.
  final int approvalWaitMs;

  /// Size of the arguments the script sent, in UTF-8 bytes, before redaction.
  final int argumentBytes;

  /// Size of the result handed back to the script, in UTF-8 bytes.
  final int resultBytes;

  /// The arguments as redacted JSON, at most [maxArgumentsBytes].
  final String argumentsJson;

  /// The error message for a call that did not complete, at most
  /// [maxErrorChars].
  final String? error;

  /// Where in the script the call was made, or null when the runner reported
  /// no position.
  ///
  /// A display hint from an untrusted process (the runner executes
  /// model-written code). It places the call in the script's structure in
  /// the detail view; nothing that decides reads it.
  final ScriptCallSite? site;

  /// The wire form. `site` is `[line, column]`, absent when there is none.
  Map<String, dynamic> toJson() => {
    'execution_id': executionId,
    'sequence': sequence,
    'tool_call_id': toolCallId,
    'tool_name': toolName,
    'start_offset_ms': startOffsetMs,
    'duration_ms': durationMs,
    'status': status.wire,
    if (gateDecision != null) 'gate_decision': gateDecision!.wire,
    'approval_wait_ms': approvalWaitMs,
    'argument_bytes': argumentBytes,
    'result_bytes': resultBytes,
    'arguments': argumentsJson,
    if (error != null) 'error': error,
    'site': ?site?.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeExecutionCall &&
          other.executionId == executionId &&
          other.sequence == sequence &&
          other.toolCallId == toolCallId &&
          other.toolName == toolName &&
          other.startOffsetMs == startOffsetMs &&
          other.durationMs == durationMs &&
          other.status == status &&
          other.gateDecision == gateDecision &&
          other.approvalWaitMs == approvalWaitMs &&
          other.argumentBytes == argumentBytes &&
          other.resultBytes == resultBytes &&
          other.argumentsJson == argumentsJson &&
          other.error == error &&
          other.site == site;

  @override
  int get hashCode => Object.hash(
    executionId,
    sequence,
    toolCallId,
    toolName,
    startOffsetMs,
    durationMs,
    status,
    gateDecision,
    approvalWaitMs,
    argumentBytes,
    resultBytes,
    argumentsJson,
    error,
    site,
  );

  @override
  String toString() =>
      'CodeExecutionCall($executionId#$sequence $toolName ${status.wire})';
}

void _requireNonEmpty(String value, String name) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be empty');
  }
}

bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;
