import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_persistence/database/app_database.dart';
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
    finishedAt: Value(run.finishedAt),
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
    finishedAt: row.finishedAt,
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
    channelId: row.channelId,
    errorMessage: row.errorMessage,
    branchIndex: row.branchIndex,
    attemptCount: row.attemptCount,
    startedAt: row.startedAt,
    finishedAt: row.finishedAt,
  );
}

/// Converts a domain [PipelineStepRun] to a Drift companion for insert.
PipelineStepRunsTableCompanion stepRunToCompanion(PipelineStepRun stepRun) {
  return PipelineStepRunsTableCompanion(
    id: Value(stepRun.id),
    pipelineRunId: Value(stepRun.pipelineRunId),
    stepId: Value(stepRun.stepId),
    status: Value(stepRun.status.toStorageString()),
    inputJson: Value(stepRun.inputJson),
    channelId: Value(stepRun.channelId),
    branchIndex: Value(stepRun.branchIndex),
    startedAt: Value(stepRun.startedAt),
    // Round-trip finishedAt so a row inserted already-terminal (e.g. a router
    // branch recorded as `skipped`) doesn't read back as still running.
    finishedAt: Value(stepRun.finishedAt),
  );
}
