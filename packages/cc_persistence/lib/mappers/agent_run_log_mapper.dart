import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/observability/domain/run_stage.dart';
import 'package:cc_domain/features/observability/domain/run_verification.dart';
import 'package:cc_persistence/database/daos/agent_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';

/// Maps database agent run log rows to domain [AgentRunLog] entities.
///
/// A run read from a list has no [AgentRunPayloadsTableData]: its payload
/// fields (`contextSnapshotJson`, `expectedOutputSchema`, `outputJson`) are
/// null and its verification carries the verdict without its detail. The single-run reads pass the payload row.
class AgentRunLogMapper {
  /// Creates a const [AgentRunLogMapper].
  const AgentRunLogMapper();

  /// Converts a run-log row, and its [payload] row when one was read, into an
  /// [AgentRunLog] domain entity.
  AgentRunLog toDomain(
    AgentRunLogsTableData row, [
    AgentRunPayloadsTableData? payload,
  ]) {
    return AgentRunLog(
      id: row.id,
      agentId: row.agentId,
      workspaceId: row.workspaceId,
      conversationId: row.conversationId,
      ticketId: row.ticketId,
      spaceId: row.spaceId,
      startedAt: row.startedAt,
      completedAt: row.completedAt,
      status: _parseRunStatus(row.status),
      summary: row.summary,
      adapter: row.adapter,
      modelId: row.modelId,
      pid: row.pid,
      logPath: row.logPath,
      cost: RunCost(
        inputTokens: row.inputTokens,
        outputTokens: row.outputTokens,
        thoughtTokens: row.thoughtTokens,
        cachedReadTokens: row.cachedReadTokens,
        cachedWriteTokens: row.cachedWriteTokens,
        costMicros: row.costMicros,
        // A null basis reads as `estimated`, which is what a locally-priced
        // figure is — never as a reported or billed one.
        costBasis: CostBasis.fromWire(row.costBasis),
        durationMs: row.durationMs,
        timeToFirstTokenMs: row.timeToFirstTokenMs,
      ),
      role: AgentRunRole.tryParse(row.agentRole),
      childCostMicros: row.childCostMicros,
      effort: row.effort,
      taskFamily: row.taskFamily,
      nativeSessionId: row.nativeSessionId,
      resumedNativeSession: row.resumedNativeSession,
      latency: RunLatencyProfile.fromJson(_decodeJsonOrNull(row.latencyJson)),
      verification: _verification(
        row.verificationStatus,
        payload?.verificationJson,
      ),
      lastOutputAt: row.lastOutputAt,
      contextSnapshotJson: payload?.contextSnapshotJson,
      // NOT `tryParse` on a null column: it answers `empty` for anything it
      // does not recognise, which turned "nobody has classified this run yet"
      // into "this run produced nothing" on the way out — and the next upsert
      // then wrote that fabricated verdict back, permanently. A run with no
      // classification stays unclassified.
      liveness: row.livenessClass == null
          ? null
          : RunLiveness.tryParse(row.livenessClass),
      errorFamily: RunErrorFamily.tryParse(row.errorFamily),
      pipelineRunId: row.pipelineRunId,
      pipelineStepId: row.pipelineStepId,
      errorCode: row.errorCode,
      expectedOutputSchema: _decodeObjectOrNull(payload?.expectedOutputSchema),
      outputContractMode: OutputContractMode.fromStorage(
        row.outputContractMode,
      ),
      outputJson: _decodeObjectOrNull(payload?.outputJson),
      outputRejections: row.outputRejections,
      retry: RetryMeta(
        parentRunId: row.retryOfRunId,
        attempt: row.retryAttempt,
      ),
      parentRunId: row.parentRunId,
      spawnToolCallId: row.spawnToolCallId,
    );
  }

  /// Converts a run-log row read with its payload into a full [AgentRunLog].
  AgentRunLog toDomainWithPayload(AgentRunLogWithPayload row) =>
      toDomain(row.log, row.payload);

  /// Converts list rows (no payload) into [AgentRunLog] domain entities.
  List<AgentRunLog> toDomainList(List<AgentRunLogsTableData> rows) => [
    for (final row in rows) toDomain(row),
  ];

  /// The run's verdict from [status] (the run-log column), with the detail
  /// from [detailJson] (the payload column) only while that detail records
  /// the same verdict: a detail left from an earlier verdict is never shown
  /// under a later one.
  static RunVerification _verification(String? status, String? detailJson) {
    if (status == null) {
      return RunVerification.none;
    }
    final verdict = RunVerification(
      status: VerificationStatus.fromWire(status),
    );
    final detail = RunVerification.fromJson(_decodeJsonOrNull(detailJson));
    return detail.status == verdict.status && detailJson != null
        ? detail
        : verdict;
  }

  /// Decodes a JSON-object payload column, or null when it is null.
  static Map<String, dynamic>? _decodeObjectOrNull(String? raw) =>
      raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;

  /// Decodes a nullable JSON column to its Dart value, or null when the column
  /// is null/corrupt.
  ///
  /// A malformed blob must degrade to "unknown" rather than throwing and
  /// taking down the whole row read: latency/verification columns are written
  /// by this process, so corruption there means an interrupted write, not a
  /// reason to lose the run.
  static Object? _decodeJsonOrNull(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  static RunStatus _parseRunStatus(String value) {
    return switch (value) {
      'pending' => RunStatus.pending,
      'running' => RunStatus.running,
      'completed' => RunStatus.completed,
      'error' => RunStatus.error,
      _ => RunStatus.error,
    };
  }
}
