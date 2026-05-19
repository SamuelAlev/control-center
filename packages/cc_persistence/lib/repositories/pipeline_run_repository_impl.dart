import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_persistence/database/daos/pipeline_dao.dart';
import 'package:cc_persistence/mappers/pipeline_mappers.dart';

/// Drift-backed implementation of [PipelineRunRepository].
class PipelineRunRepositoryImpl implements PipelineRunRepository {
  /// Creates a [PipelineRunRepositoryImpl].
  PipelineRunRepositoryImpl(this._dao);

  final PipelineDao _dao;

  @override
  Future<void> insertRun(PipelineRun run) async {
    await _dao.insertRun(pipelineRunToCompanion(run));
  }

  @override
  Future<void> updateRun(PipelineRun run) async {
    await _dao.updateRun(pipelineRunToCompanion(run));
  }

  @override
  Future<PipelineRun?> getRun(String id) async {
    final row = await _dao.getRun(id);
    return row != null ? pipelineRunFromRow(row) : null;
  }

  @override
  Stream<PipelineRun?> watchRun(String id) {
    return _dao
        .watchRun(id)
        .map((row) => row != null ? pipelineRunFromRow(row) : null);
  }

  @override
  Future<void> updateRunState(
      String runId, Map<String, dynamic> state) async {
    await _dao.updateRunState(runId, jsonEncode(state));
  }

  @override
  Future<void> incrementCost(String runId, int cents, int tokens) async {
    final run = await _dao.getRun(runId);
    if (run == null) {
      return;
    }
    await _dao.updateRunCost(
      runId,
      run.totalCostCents + cents,
      run.totalTokens + tokens,
    );
  }

  @override
  Future<List<PipelineRun>> nonTerminalRuns() async {
    final rows = await _dao.nonTerminalRuns();
    return rows.map(pipelineRunFromRow).toList();
  }

  @override
  Future<PipelineRun?> activeForDedupKey({
    required String templateId,
    required String workspaceId,
    required String dedupKey,
  }) async {
    final row = await _dao.findActiveByDedupKey(templateId, workspaceId, dedupKey);
    return row != null ? pipelineRunFromRow(row) : null;
  }

  @override
  Stream<List<PipelineRun>> watchAll() {
    return _dao.watchAll().map((rows) => rows.map(pipelineRunFromRow).toList());
  }

  @override
  Stream<List<PipelineRun>> watchForWorkspace(String workspaceId) {
    return _dao
        .watchForWorkspace(workspaceId)
        .map((rows) => rows.map(pipelineRunFromRow).toList());
  }

  @override
  Future<void> deleteRun(String workspaceId, String runId) async {
    await _dao.deleteRun(workspaceId, runId);
  }

  @override
  Future<void> insertStepRun(PipelineStepRun stepRun) async {
    await _dao.insertStepRun(stepRunToCompanion(stepRun));
  }

  @override
  Future<void> updateStepRun(
    String stepRunId, {
    PipelineStepStatus? status,
    String? inputJson,
    String? outputJson,
    String? channelId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) async {
    await _dao.updateStepRun(
      id: stepRunId,
      status: status?.toStorageString(),
      inputJson: inputJson,
      outputJson: outputJson,
      channelId: channelId,
      errorMessage: errorMessage,
      errorStackTrace: errorStackTrace,
      finishedAt: finishedAt,
    );
  }

  @override
  Future<void> deleteStepRun(String stepRunId) async {
    await _dao.deleteStepRun(stepRunId);
  }

  @override
  Future<List<PipelineStepRun>> stepRunsForPipeline(
      String pipelineRunId) async {
    final rows = await _dao.stepRunsForPipeline(pipelineRunId);
    return rows.map(stepRunFromRow).toList();
  }

  @override
  Future<PipelineStepRun?> getStepRunById(String stepRunId) async {
    final row = await _dao.getStepRunById(stepRunId);
    return row != null ? stepRunFromRow(row) : null;
  }

  @override
  Stream<List<PipelineStepRun>> watchStepRunsForPipeline(
      String pipelineRunId) {
    return _dao
        .watchStepRunsForPipeline(pipelineRunId)
        .map((rows) => rows.map(stepRunFromRow).toList());
  }
}
