import 'dart:convert';

import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps code executions, their payloads and their nested calls between the
/// domain entities and the `code_executions`, `code_execution_payloads` and
/// `code_execution_calls` rows.
///
/// `started_at_ms` holds epoch milliseconds, so an execution comes back with
/// its start at millisecond resolution.
class CodeExecutionMapper {
  /// Creates a [CodeExecutionMapper].
  const CodeExecutionMapper();

  /// The `code_executions` row for [e].
  CodeExecutionsTableCompanion toCompanion(CodeExecution e) {
    final counts = e.callCounts;
    return CodeExecutionsTableCompanion.insert(
      id: e.id,
      runId: e.runId,
      toolCallId: e.toolCallId,
      idSuffix: idSuffixOf(e),
      surface: e.surface.wire,
      conversationId: Value(e.conversationId),
      agentId: Value(e.agentId),
      spaceId: Value(e.spaceId),
      description: Value(e.description),
      startedAtMs: e.startedAt.millisecondsSinceEpoch,
      durationMs: e.durationMs,
      status: e.status.wire,
      errorKind: Value(e.errorKind),
      sourceHash: e.sourceHash,
      sourceBytes: e.sourceBytes,
      cpuMs: Value(e.cpuMs),
      peakHeapBytes: Value(e.peakHeapBytes),
      callsCompleted: Value(counts.completed),
      callsFailed: Value(counts.failed),
      callsDenied: Value(counts.denied),
      callsCancelled: Value(counts.cancelled),
      callsTimedOut: Value(counts.timedOut),
      callsUnknownTool: Value(counts.unknownTool),
      callsInvalidArgs: Value(counts.invalidArgs),
      questionCount: Value(e.questionCount),
      outputBytes: Value(e.outputBytes),
      outputTruncated: Value(e.outputTruncated),
      engineVersion: Value(e.engineVersion),
      lockdownJson: Value(e.lockdown == null ? null : jsonEncode(e.lockdown)),
      limitsJson: jsonEncode(e.limits.toJson()),
    );
  }

  /// The columns of [e] that say how it ended, for finishing its running
  /// row: nothing [toCompanion] wrote at admission that names another row,
  /// labels or places it.
  CodeExecutionsTableCompanion terminalCompanion(CodeExecution e) {
    final counts = e.callCounts;
    return CodeExecutionsTableCompanion(
      durationMs: Value(e.durationMs),
      status: Value(e.status.wire),
      errorKind: Value(e.errorKind),
      cpuMs: Value(e.cpuMs),
      peakHeapBytes: Value(e.peakHeapBytes),
      callsCompleted: Value(counts.completed),
      callsFailed: Value(counts.failed),
      callsDenied: Value(counts.denied),
      callsCancelled: Value(counts.cancelled),
      callsTimedOut: Value(counts.timedOut),
      callsUnknownTool: Value(counts.unknownTool),
      callsInvalidArgs: Value(counts.invalidArgs),
      questionCount: Value(e.questionCount),
      outputBytes: Value(e.outputBytes),
      outputTruncated: Value(e.outputTruncated),
      engineVersion: Value(e.engineVersion),
      lockdownJson: Value(e.lockdown == null ? null : jsonEncode(e.lockdown)),
    );
  }

  /// Which execution of its `repl` call [e] is: 1 for
  /// [CodeExecution.idFor] of its run and call, n for that id with `#<n>`.
  static int idSuffixOf(CodeExecution e) {
    final base = CodeExecution.idFor(runId: e.runId, toolCallId: e.toolCallId);
    if (e.id == base) {
      return 1;
    }
    if (e.id.startsWith('$base#')) {
      final n = int.tryParse(e.id.substring(base.length + 1));
      if (n != null && n >= 2) {
        return n;
      }
    }
    throw ArgumentError.value(
      e.id,
      'execution.id',
      'is neither $base nor $base#<n>',
    );
  }

  /// The execution a `code_executions` row holds.
  CodeExecution fromRow(CodeExecutionsTableData row) => CodeExecution(
    id: row.id,
    runId: row.runId,
    toolCallId: row.toolCallId,
    surface: CodeExecutionSurface.parse(row.surface),
    conversationId: row.conversationId,
    agentId: row.agentId,
    spaceId: row.spaceId,
    description: row.description,
    startedAt: DateTime.fromMillisecondsSinceEpoch(
      row.startedAtMs,
      isUtc: true,
    ),
    durationMs: row.durationMs,
    status: CodeExecutionStatus.parse(row.status),
    errorKind: row.errorKind,
    sourceHash: row.sourceHash,
    sourceBytes: row.sourceBytes,
    cpuMs: row.cpuMs,
    peakHeapBytes: row.peakHeapBytes,
    callCounts: NestedCallCounts(
      completed: row.callsCompleted,
      failed: row.callsFailed,
      denied: row.callsDenied,
      cancelled: row.callsCancelled,
      timedOut: row.callsTimedOut,
      unknownTool: row.callsUnknownTool,
      invalidArgs: row.callsInvalidArgs,
    ),
    questionCount: row.questionCount,
    outputBytes: row.outputBytes,
    outputTruncated: row.outputTruncated,
    engineVersion: row.engineVersion,
    lockdown: switch (row.lockdownJson) {
      final String json => (jsonDecode(json) as Map).cast<String, dynamic>(),
      null => null,
    },
    limits: CodeModeLimits.fromJson(
      (jsonDecode(row.limitsJson) as Map).cast<String, dynamic>(),
    ),
  );

  /// The `code_execution_payloads` row for [p].
  CodeExecutionPayloadsTableCompanion payloadToCompanion(
    CodeExecutionPayload p,
  ) => CodeExecutionPayloadsTableCompanion.insert(
    executionId: p.executionId,
    source: p.source,
    output: Value(p.output),
    console: Value(p.console),
    errorName: Value(p.errorName),
  );

  /// The payload a `code_execution_payloads` row holds.
  CodeExecutionPayload payloadFromRow(CodeExecutionPayloadsTableData row) =>
      CodeExecutionPayload(
        executionId: row.executionId,
        source: row.source,
        output: row.output,
        console: row.console,
        errorName: row.errorName,
      );

  /// The `code_execution_calls` row for [c].
  CodeExecutionCallsTableCompanion callToCompanion(CodeExecutionCall c) =>
      CodeExecutionCallsTableCompanion.insert(
        executionId: c.executionId,
        sequence: c.sequence,
        toolCallId: c.toolCallId,
        toolName: c.toolName,
        startOffsetMs: c.startOffsetMs,
        durationMs: c.durationMs,
        status: c.status.wire,
        gateDecision: Value(c.gateDecision?.wire),
        approvalWaitMs: Value(c.approvalWaitMs),
        argumentBytes: Value(c.argumentBytes),
        resultBytes: Value(c.resultBytes),
        arguments: Value(c.argumentsJson),
        error: Value(c.error),
        siteLine: Value(c.site?.line),
        siteColumn: Value(c.site?.column),
      );

  /// The call a `code_execution_calls` row holds.
  CodeExecutionCall callFromRow(CodeExecutionCallsTableData row) =>
      CodeExecutionCall(
        executionId: row.executionId,
        sequence: row.sequence,
        toolCallId: row.toolCallId,
        toolName: row.toolName,
        startOffsetMs: row.startOffsetMs,
        durationMs: row.durationMs,
        status: NestedCallStatus.parse(row.status),
        gateDecision: NestedCallGateDecision.tryParse(row.gateDecision),
        approvalWaitMs: row.approvalWaitMs,
        argumentBytes: row.argumentBytes,
        resultBytes: row.resultBytes,
        argumentsJson: row.arguments,
        error: row.error,
        site: _siteOf(row.siteLine, row.siteColumn),
      );
}

/// The site a row's two columns hold, or null when there is none or it is
/// out of range: a site is a display hint, and a bad one must not cost the
/// row it rides on.
ScriptCallSite? _siteOf(int? line, int? column) =>
    line == null || column == null
    ? null
    : ScriptCallSite.tryParse([line, column]);
