import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:collection/collection.dart';

/// How many nested calls of an execution ended in each [NestedCallStatus].
class NestedCallCounts {
  /// Creates counts. Throws [ArgumentError] when a count is negative.
  NestedCallCounts({
    this.completed = 0,
    this.failed = 0,
    this.denied = 0,
    this.cancelled = 0,
    this.timedOut = 0,
    this.unknownTool = 0,
    this.invalidArgs = 0,
  }) {
    for (final (status, count) in _pairs) {
      if (count < 0) {
        throw ArgumentError.value(count, status.wire, 'must not be negative');
      }
    }
  }

  /// Counts [calls] by status.
  factory NestedCallCounts.of(Iterable<CodeExecutionCall> calls) =>
      NestedCallCounts.ofStatuses(calls.map((c) => c.status));

  /// Counts [statuses].
  factory NestedCallCounts.ofStatuses(Iterable<NestedCallStatus> statuses) {
    final by = <NestedCallStatus, int>{};
    for (final s in statuses) {
      by[s] = (by[s] ?? 0) + 1;
    }
    return NestedCallCounts._fromMap(by);
  }

  /// Rebuilds from [toJson]'s output. Unknown keys are ignored.
  factory NestedCallCounts.fromJson(Map<String, dynamic> json) =>
      NestedCallCounts._fromMap({
        for (final s in NestedCallStatus.values)
          s: (json[s.wire] as num?)?.toInt() ?? 0,
      });

  factory NestedCallCounts._fromMap(Map<NestedCallStatus, int> by) =>
      NestedCallCounts(
        completed: by[NestedCallStatus.completed] ?? 0,
        failed: by[NestedCallStatus.failed] ?? 0,
        denied: by[NestedCallStatus.denied] ?? 0,
        cancelled: by[NestedCallStatus.cancelled] ?? 0,
        timedOut: by[NestedCallStatus.timedOut] ?? 0,
        unknownTool: by[NestedCallStatus.unknownTool] ?? 0,
        invalidArgs: by[NestedCallStatus.invalidArgs] ?? 0,
      );

  /// Calls that completed.
  final int completed;

  /// Calls whose tool returned an error.
  final int failed;

  /// Calls the gate refused.
  final int denied;

  /// Calls cancelled before they settled.
  final int cancelled;

  /// Calls whose own deadline ran out.
  final int timedOut;

  /// Calls naming a tool outside the callable set.
  final int unknownTool;

  /// Calls with unusable arguments.
  final int invalidArgs;

  List<(NestedCallStatus, int)> get _pairs => [
    (NestedCallStatus.completed, completed),
    (NestedCallStatus.failed, failed),
    (NestedCallStatus.denied, denied),
    (NestedCallStatus.cancelled, cancelled),
    (NestedCallStatus.timedOut, timedOut),
    (NestedCallStatus.unknownTool, unknownTool),
    (NestedCallStatus.invalidArgs, invalidArgs),
  ];

  /// Every call.
  int get total => _pairs.fold(0, (sum, p) => sum + p.$2);

  /// The count for [status].
  int of(NestedCallStatus status) =>
      _pairs.firstWhere((p) => p.$1 == status).$2;

  /// The wire form, keyed by [NestedCallStatus.wire]. Every key is present so
  /// a column per status reads straight from it.
  Map<String, int> toJson() => {for (final (s, n) in _pairs) s.wire: n};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NestedCallCounts &&
          const ListEquality<int>().equals(
            [for (final p in other._pairs) p.$2],
            [for (final p in _pairs) p.$2],
          );

  @override
  int get hashCode => Object.hashAll([for (final p in _pairs) p.$2]);

  @override
  String toString() => 'NestedCallCounts(${toJson()})';
}

/// One `repl` call: the durable `code_executions` row.
///
/// Holds what an operator needs to see at a glance and to aggregate (status,
/// timings, sizes, call counts, limits). The source and output live in the
/// 1:1 [CodeExecutionPayload], so a list page never loads them.
class CodeExecution {
  /// Creates an execution record.
  ///
  /// Throws [ArgumentError] when an id is empty, a size or duration is
  /// negative, [sourceHash] is not 64 lowercase hex characters,
  /// [questionCount] is over [CodeModeLimits.maxQuestions], [description] is
  /// not what [boundDescription] makes of it, or [errorKind] does not fit
  /// [status]: none for a running or completed script, one of
  /// [CodeExecutionErrorKind.values] for every other status.
  CodeExecution({
    required this.id,
    required this.runId,
    required this.toolCallId,
    required this.surface,
    required DateTime startedAt,
    required this.durationMs,
    required this.status,
    required this.sourceHash,
    required this.sourceBytes,
    required this.limits,
    this.conversationId,
    this.agentId,
    this.spaceId,
    this.description = '',
    this.errorKind,
    this.cpuMs,
    this.peakHeapBytes,
    NestedCallCounts? callCounts,
    this.questionCount = 0,
    this.outputBytes = 0,
    this.outputTruncated = false,
    this.engineVersion,
    Map<String, dynamic>? lockdown,
  }) : startedAt = startedAt.toUtc(),
       callCounts = callCounts ?? NestedCallCounts(),
       lockdown = lockdown == null ? null : Map.unmodifiable(lockdown) {
    for (final (value, name) in [
      (id, 'id'),
      (runId, 'runId'),
      (toolCallId, 'toolCallId'),
    ]) {
      if (value.isEmpty) {
        throw ArgumentError.value(value, name, 'must not be empty');
      }
    }
    for (final (value, name) in [
      (durationMs, 'durationMs'),
      (sourceBytes, 'sourceBytes'),
      (cpuMs ?? 0, 'cpuMs'),
      (peakHeapBytes ?? 0, 'peakHeapBytes'),
      (questionCount, 'questionCount'),
      (outputBytes, 'outputBytes'),
    ]) {
      if (value < 0) {
        throw ArgumentError.value(value, name, 'must not be negative');
      }
    }
    if (!_sha256Hex.hasMatch(sourceHash)) {
      throw ArgumentError.value(
        sourceHash,
        'sourceHash',
        'must be a lowercase hex SHA-256 digest',
      );
    }
    if (questionCount > CodeModeLimits.maxQuestions) {
      throw ArgumentError.value(
        questionCount,
        'questionCount',
        'must be at most ${CodeModeLimits.maxQuestions}',
      );
    }
    if (!isOneLineLabel(description, maxDescriptionChars)) {
      throw ArgumentError.value(
        description,
        'description',
        'must be one line of at most $maxDescriptionChars characters with no '
            'control characters',
      );
    }
    final kindExpected =
        status != CodeExecutionStatus.running &&
        status != CodeExecutionStatus.completed;
    if (kindExpected
        ? !CodeExecutionErrorKind.isKnown(errorKind)
        : errorKind != null) {
      throw ArgumentError.value(
        errorKind,
        'errorKind',
        kindExpected
            ? 'must be one of CodeExecutionErrorKind.values for ${status.wire}'
            : 'must be null for ${status.wire}',
      );
    }
  }

  /// Rebuilds from [toJson]'s output.
  factory CodeExecution.fromJson(Map<String, dynamic> json) => CodeExecution(
    id: json['id'] as String? ?? '',
    runId: json['run_id'] as String? ?? '',
    toolCallId: json['tool_call_id'] as String? ?? '',
    surface: CodeExecutionSurface.parse(json['surface'] as String? ?? ''),
    startedAt: DateTime.parse(json['started_at'] as String),
    durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
    status: CodeExecutionStatus.parse(json['status'] as String? ?? ''),
    sourceHash: json['source_hash'] as String? ?? '',
    sourceBytes: (json['source_bytes'] as num?)?.toInt() ?? 0,
    limits: CodeModeLimits.fromJson(
      (json['limits'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    conversationId: json['conversation_id'] as String?,
    agentId: json['agent_id'] as String?,
    spaceId: json['space_id'] as String?,
    description: json['description'] as String? ?? '',
    errorKind: json['error_kind'] as String?,
    cpuMs: (json['cpu_ms'] as num?)?.toInt(),
    peakHeapBytes: (json['peak_heap_bytes'] as num?)?.toInt(),
    callCounts: NestedCallCounts.fromJson(
      (json['call_counts'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
    outputBytes: (json['output_bytes'] as num?)?.toInt() ?? 0,
    outputTruncated: json['output_truncated'] == true,
    engineVersion: json['engine_version'] as String?,
    lockdown: (json['lockdown'] as Map?)?.cast<String, dynamic>(),
  );

  static final RegExp _sha256Hex = RegExp(r'^[0-9a-f]{64}$');

  /// The id of the execution a `repl` call starts: `<runId>/<toolCallId>`.
  ///
  /// Derived, not generated, so every party that knows the run and the
  /// `repl` call's id names the same execution without being handed it: the
  /// execution service that writes the row, and the gate that marks an
  /// approval card or a question with its `ScriptCallOrigin`. A tool call id
  /// is unique within its run, so the pair is unique in the workspace.
  static String idFor({required String runId, required String toolCallId}) {
    if (runId.isEmpty) {
      throw ArgumentError.value(runId, 'runId', 'must not be empty');
    }
    if (toolCallId.isEmpty) {
      throw ArgumentError.value(toolCallId, 'toolCallId', 'must not be empty');
    }
    return '$runId/$toolCallId';
  }

  /// The record's id. Also what `ScriptCallOrigin.executionId` names.
  final String id;

  /// The run (run-log id) the script belongs to. Rows are deleted with it.
  final String runId;

  /// The `repl` tool call's id.
  final String toolCallId;

  /// Which surface ran it.
  final CodeExecutionSurface surface;

  /// The conversation, when the run has one.
  final String? conversationId;

  /// The agent, when the run has one.
  final String? agentId;

  /// The space, when the run has one. What the read gate checks before
  /// showing source or output.
  final String? spaceId;

  /// The one-line description the model gave the call, as
  /// [boundDescription] keeps it.
  final String description;

  /// When the host admitted the call, in UTC.
  final DateTime startedAt;

  /// Wall-clock milliseconds from admission to the result, waits included.
  /// Zero while [status] is [CodeExecutionStatus.running].
  final int durationMs;

  /// Where it is: [CodeExecutionStatus.running] until it ends, then how it
  /// ended.
  final CodeExecutionStatus status;

  /// Why a script that did not complete ended, from the fixed vocabulary
  /// [CodeExecutionErrorKind.values] (`script_error`, `deadline`, `cpu`,
  /// `protocol`, …). Null while running and when it completed. The script's
  /// own error name is [CodeExecutionPayload.errorName].
  final String? errorKind;

  /// SHA-256 of the source, lowercase hex. Groups reruns of the same script.
  final String sourceHash;

  /// Size of the source in UTF-8 bytes.
  final int sourceBytes;

  /// Interpreter CPU milliseconds, when the runner reported them.
  final int? cpuMs;

  /// Peak interpreter heap in bytes, when the runner reported it.
  final int? peakHeapBytes;

  /// Nested calls by outcome.
  final NestedCallCounts callCounts;

  /// Questions the script asked a person.
  final int questionCount;

  /// Size of the output the script produced, in UTF-8 bytes, before
  /// truncation for the model.
  final int outputBytes;

  /// Whether the model read a head-and-tail cut of the output.
  final bool outputTruncated;

  /// The runner's engine and version (`quickjs-ng 0.10.1`), when it started.
  final String? engineVersion;

  /// The lockdown the runner reported in its `ready` frame, when it started.
  final Map<String, dynamic>? lockdown;

  /// The limits the script ran under, after workspace overrides and the
  /// model's clamp.
  final CodeModeLimits limits;

  /// This running record as it ended: [status] and the other terminal
  /// fields replaced, everything recorded at admission (ids, surface, label,
  /// start, source, limits) kept.
  ///
  /// Throws [StateError] when this record is not running, and
  /// [ArgumentError] as the constructor does (a running [status], an
  /// [errorKind] that does not fit it).
  CodeExecution ended({
    required CodeExecutionStatus status,
    required int durationMs,
    String? errorKind,
    int? cpuMs,
    int? peakHeapBytes,
    NestedCallCounts? callCounts,
    int questionCount = 0,
    int outputBytes = 0,
    bool outputTruncated = false,
    String? engineVersion,
    Map<String, dynamic>? lockdown,
  }) {
    if (this.status != CodeExecutionStatus.running) {
      throw StateError('Code execution $id already ended (${this.status}).');
    }
    if (status == CodeExecutionStatus.running) {
      throw ArgumentError.value(status, 'status', 'is not how a script ends');
    }
    return CodeExecution(
      id: id,
      runId: runId,
      toolCallId: toolCallId,
      surface: surface,
      startedAt: startedAt,
      durationMs: durationMs,
      status: status,
      sourceHash: sourceHash,
      sourceBytes: sourceBytes,
      limits: limits,
      conversationId: conversationId,
      agentId: agentId,
      spaceId: spaceId,
      description: description,
      errorKind: errorKind,
      cpuMs: cpuMs,
      peakHeapBytes: peakHeapBytes,
      callCounts: callCounts,
      questionCount: questionCount,
      outputBytes: outputBytes,
      outputTruncated: outputTruncated,
      engineVersion: engineVersion,
      lockdown: lockdown,
    );
  }

  /// The longest [description], in characters.
  static const int maxDescriptionChars = 200;

  /// The description a record keeps for the label [raw] the model gave: one
  /// line of at most [maxDescriptionChars] characters, whitespace and control
  /// characters collapsed and a longer label cut with an ellipsis. A script is
  /// never refused for its label.
  static String boundDescription(String raw) =>
      oneLineLabel(raw, maxDescriptionChars);

  /// The wire form.
  Map<String, dynamic> toJson() => {
    'id': id,
    'run_id': runId,
    'tool_call_id': toolCallId,
    'surface': surface.wire,
    if (conversationId != null) 'conversation_id': conversationId,
    if (agentId != null) 'agent_id': agentId,
    if (spaceId != null) 'space_id': spaceId,
    'description': description,
    'started_at': startedAt.toIso8601String(),
    'duration_ms': durationMs,
    'status': status.wire,
    if (errorKind != null) 'error_kind': errorKind,
    'source_hash': sourceHash,
    'source_bytes': sourceBytes,
    if (cpuMs != null) 'cpu_ms': cpuMs,
    if (peakHeapBytes != null) 'peak_heap_bytes': peakHeapBytes,
    'call_counts': callCounts.toJson(),
    'question_count': questionCount,
    'output_bytes': outputBytes,
    'output_truncated': outputTruncated,
    if (engineVersion != null) 'engine_version': engineVersion,
    if (lockdown != null) 'lockdown': lockdown,
    'limits': limits.toJson(),
  };

  static const _deep = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeExecution &&
          other.id == id &&
          other.runId == runId &&
          other.toolCallId == toolCallId &&
          other.surface == surface &&
          other.conversationId == conversationId &&
          other.agentId == agentId &&
          other.spaceId == spaceId &&
          other.description == description &&
          other.startedAt == startedAt &&
          other.durationMs == durationMs &&
          other.status == status &&
          other.errorKind == errorKind &&
          other.sourceHash == sourceHash &&
          other.sourceBytes == sourceBytes &&
          other.cpuMs == cpuMs &&
          other.peakHeapBytes == peakHeapBytes &&
          other.callCounts == callCounts &&
          other.questionCount == questionCount &&
          other.outputBytes == outputBytes &&
          other.outputTruncated == outputTruncated &&
          other.engineVersion == engineVersion &&
          _deep.equals(other.lockdown, lockdown) &&
          other.limits == limits;

  @override
  int get hashCode => Object.hashAll([
    id,
    runId,
    toolCallId,
    surface,
    conversationId,
    agentId,
    spaceId,
    description,
    startedAt,
    durationMs,
    status,
    errorKind,
    sourceHash,
    sourceBytes,
    cpuMs,
    peakHeapBytes,
    callCounts,
    questionCount,
    outputBytes,
    outputTruncated,
    engineVersion,
    _deep.hash(lockdown),
    limits,
  ]);

  @override
  String toString() => 'CodeExecution($id ${status.wire})';
}

/// The bounded source and output of one execution: the 1:1
/// `code_execution_payloads` row.
///
/// Kept apart from [CodeExecution] because it is space content: reading it
/// passes the space read gate, and a list page never needs it.
class CodeExecutionPayload {
  /// Creates a payload. Throws [ArgumentError] when [executionId] is empty or
  /// a field is over its cap; [CodeExecutionPayload.bounded] fits them first.
  CodeExecutionPayload({
    required this.executionId,
    required this.source,
    this.output = '',
    this.console = '',
    this.errorName,
  }) {
    if (executionId.isEmpty) {
      throw ArgumentError.value(
        executionId,
        'executionId',
        'must not be empty',
      );
    }
    for (final (value, cap, name) in [
      (source, maxSourceBytes, 'source'),
      (output, maxOutputBytes, 'output'),
      (console, maxConsoleBytes, 'console'),
    ]) {
      final size = utf8Length(value);
      if (size > cap) {
        throw ArgumentError.value(size, name, 'must be at most $cap bytes');
      }
    }
    final name = errorName;
    if (name != null && !isOneLineLabel(name, maxErrorNameChars)) {
      throw ArgumentError.value(
        name,
        'errorName',
        'must be one line of at most $maxErrorNameChars characters',
      );
    }
  }

  /// Creates a payload, cutting each field to its cap with a marker that
  /// names the original size.
  factory CodeExecutionPayload.bounded({
    required String executionId,
    required String source,
    String output = '',
    String console = '',
    String? errorName,
  }) => CodeExecutionPayload(
    executionId: executionId,
    source: boundUtf8(source, maxSourceBytes),
    output: boundUtf8(output, maxOutputBytes),
    console: boundUtf8(console, maxConsoleBytes),
    errorName: errorName == null
        ? null
        : oneLineLabel(errorName, maxErrorNameChars),
  );

  /// Rebuilds from [toJson]'s output.
  factory CodeExecutionPayload.fromJson(Map<String, dynamic> json) =>
      CodeExecutionPayload(
        executionId: json['execution_id'] as String? ?? '',
        source: json['source'] as String? ?? '',
        output: json['output'] as String? ?? '',
        console: json['console'] as String? ?? '',
        errorName: json['error_name'] as String?,
      );

  /// The source cap. Equal to the largest script the host accepts, so an
  /// accepted script is always stored whole.
  static const int maxSourceBytes = CodeModeLimits.maxSourceBytes;

  /// The output cap.
  static const int maxOutputBytes = 256 * 1024;

  /// The console cap.
  static const int maxConsoleBytes = 64 * 1024;

  /// The longest [errorName], in characters.
  static const int maxErrorNameChars = 100;

  /// The execution this belongs to.
  final String executionId;

  /// The script as the model wrote it.
  final String source;

  /// The result text the model read.
  final String output;

  /// The script's `console.*` lines, in order, one per line with its level.
  final String console;

  /// The constructor name of the error a failed script threw (`TypeError`),
  /// as the script set it and cut to one line of [maxErrorNameChars]: the
  /// script chooses it, so it is display text and never decides anything.
  /// Null unless the script failed with an error.
  final String? errorName;

  /// The wire form.
  Map<String, dynamic> toJson() => {
    'execution_id': executionId,
    'source': source,
    'output': output,
    'console': console,
    if (errorName != null) 'error_name': errorName,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeExecutionPayload &&
          other.executionId == executionId &&
          other.source == source &&
          other.output == output &&
          other.console == console &&
          other.errorName == errorName;

  @override
  int get hashCode =>
      Object.hash(executionId, source, output, console, errorName);
}
