import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_attempt.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Converts a domain [PipelineRun] to a Drift companion for insert.
PipelineRunsTableCompanion pipelineRunToCompanion(PipelineRun run) {
  return PipelineRunsTableCompanion(
    id: Value(run.id),
    templateId: Value(run.templateId),
    workspaceId: Value(run.workspaceId),
    status: Value(run.status.toStorageString()),
    stateJson: Value(jsonEncode(run.state)),
    triggerEventType: Value(run.triggerEventType),
    triggerPayloadJson: run.triggerPayload != null
        ? Value(jsonEncode(run.triggerPayload))
        : const Value.absent(),
    dedupKey: Value(run.dedupKey),
    startedAt: Value(run.startedAt),
    attemptStartedAt: Value(run.attemptStartedAt),
    attemptCount: Value(run.attemptCount),
    finishedAt: Value(run.finishedAt),
    activeMs: Value(run.activeMs),
    lastResumedAt: Value(run.lastResumedAt),
    errorMessage: Value(run.errorMessage),
    errorStackTrace: Value(run.errorStackTrace),
    parentPipelineRunId: Value(run.parentPipelineRunId),
    parentStepId: Value(run.parentStepId),
    templateVersion: Value(run.templateVersion),
    totalCostCents: Value(run.totalCostCents),
    totalTokens: Value(run.totalTokens),
    dryRun: Value(run.dryRun),
  );
}

/// Converts a domain [PipelineRun] to a Drift companion for UPDATE.
///
/// Identical to [pipelineRunToCompanion] except that the three columns a
/// caller's snapshot must never speak for are left absent, so an update writes
/// nothing to them:
///
/// * `state_json` — merged by `PipelineDao.updateRunState` under the engine's
///   per-run state lock, from branches a terminal transition never saw.
/// * `total_cost_cents` / `total_tokens` — accumulated by
///   `PipelineDao.incrementRunCost` as each dispatched agent finishes, which is
///   the same instant the run completes.
///
/// Writing them from an in-memory [PipelineRun] is a lost update: the value
/// being written was read before the other writer's, and the row ends up
/// holding the older one.
PipelineRunsTableCompanion pipelineRunToUpdateCompanion(PipelineRun run) {
  final full = pipelineRunToCompanion(run);
  return full.copyWith(
    stateJson: const Value.absent(),
    totalCostCents: const Value.absent(),
    totalTokens: const Value.absent(),
  );
}

/// Converts a Drift row to a domain [PipelineRun].
PipelineRun pipelineRunFromRow(PipelineRunsTableData row) {
  final state = row.stateJson.isNotEmpty
      ? jsonDecode(row.stateJson) as Map<String, dynamic>
      : <String, dynamic>{};
  final triggerPayload = row.triggerPayloadJson != null
      ? jsonDecode(row.triggerPayloadJson!) as Map<String, dynamic>
      : null;

  return PipelineRun(
    id: row.id,
    templateId: row.templateId,
    workspaceId: row.workspaceId,
    status: PipelineRunStatus.fromString(row.status),
    state: state,
    triggerEventType: row.triggerEventType,
    triggerPayload: triggerPayload,
    dedupKey: row.dedupKey,
    startedAt: row.startedAt,
    attemptStartedAt: row.attemptStartedAt,
    attemptCount: row.attemptCount,
    finishedAt: row.finishedAt,
    activeMs: row.activeMs,
    lastResumedAt: row.lastResumedAt,
    errorMessage: row.errorMessage,
    errorStackTrace: row.errorStackTrace,
    parentPipelineRunId: row.parentPipelineRunId,
    parentStepId: row.parentStepId,
    templateVersion: row.templateVersion,
    totalCostCents: row.totalCostCents,
    totalTokens: row.totalTokens,
    dryRun: row.dryRun,
  );
}

/// Converts a Drift step run row to a domain [PipelineStepRun].
PipelineStepRun stepRunFromRow(PipelineStepRunsTableData row) {
  return PipelineStepRun(
    id: row.id,
    pipelineRunId: row.pipelineRunId,
    stepId: row.stepId,
    status: PipelineStepStatus.fromString(row.status),
    inputJson: row.inputJson,
    outputJson: row.outputJson,
    spaceId: row.spaceId,
    errorMessage: row.errorMessage,
    branchIndex: row.branchIndex,
    attemptCount: row.attemptCount,
    priorAttempts: _attemptHistoryFromJson(row.attemptHistory),
    startedAt: row.startedAt,
    finishedAt: row.finishedAt,
  );
}

/// Decodes the `attempt_history` column (a JSON list of attempt maps). A
/// malformed payload degrades to no history rather than breaking the read of
/// the step run itself.
List<PipelineStepAttempt> _attemptHistoryFromJson(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return [
      for (final e in decoded.whereType<Map>())
        PipelineStepAttempt.fromJson(e.cast<String, dynamic>()),
    ];
  } on Object {
    return const [];
  }
}

/// Converts a domain [PipelineStepRun] to a Drift companion for insert.
PipelineStepRunsTableCompanion stepRunToCompanion(PipelineStepRun stepRun) {
  return PipelineStepRunsTableCompanion(
    id: Value(stepRun.id),
    pipelineRunId: Value(stepRun.pipelineRunId),
    stepId: Value(stepRun.stepId),
    status: Value(stepRun.status.toStorageString()),
    inputJson: Value(stepRun.inputJson),
    spaceId: Value(stepRun.spaceId),
    branchIndex: Value(stepRun.branchIndex),
    startedAt: Value(stepRun.startedAt),
    // Round-trip finishedAt so a row inserted already-terminal (e.g. a router
    // branch recorded as `skipped`) doesn't read back as still running.
    finishedAt: Value(stepRun.finishedAt),
  );
}
