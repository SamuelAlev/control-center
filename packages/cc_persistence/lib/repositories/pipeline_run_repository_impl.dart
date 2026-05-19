import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/pipeline_dao.dart';
import 'package:cc_persistence/database/daos/workspace_route_dao.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/pipeline_mappers.dart';

/// Drift-backed implementation of [PipelineRunRepository].
///
/// Runs live in their workspace's own database file. Most methods are handed
/// the workspace (directly, or on the [PipelineRun] they write), but a run is
/// also reached from places that hold nothing but its id — a deep link, a
/// worker callback, a lifecycle event carrying `pipelineRunId`. Those resolve
/// the owning workspace through the global routing table, which [insertRun]
/// writes and [deleteRun] drops so a route never outlives its run.
class PipelineRunRepositoryImpl implements PipelineRunRepository {
  /// Creates a [PipelineRunRepositoryImpl] over the per-workspace databases
  /// [_dbs], using [_routes] to resolve run ids arriving with no workspace.
  PipelineRunRepositoryImpl(this._dbs, this._routes)
    : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final WorkspaceRouteDao _routes;
  final CrossWorkspaceQueries _cross;

  PipelineDao _dao(String workspaceId) => _dbs.of(workspaceId).pipelineDao;

  /// The workspace owning [runId], or null when no route was recorded for it.
  ///
  /// A miss stays a miss: reading every workspace to find the run would turn a
  /// missing route into a slow success and hide it forever.
  Future<String?> _workspaceOf(String runId) =>
      _routes.resolve(WorkspaceRouteKind.pipelineRun, runId);

  /// Resolves [runId] to its [PipelineDao], or null when it has no route.
  Future<PipelineDao?> _daoForRun(String runId) async {
    final workspaceId = await _workspaceOf(runId);
    return workspaceId == null ? null : _dao(workspaceId);
  }

  @override
  Future<void> insertRun(PipelineRun run) async {
    await _dao(run.workspaceId).insertRun(pipelineRunToCompanion(run));
    // Route written after the row, so it never points at a run that does not
    // exist yet.
    await _routes.put(WorkspaceRouteKind.pipelineRun, run.id, run.workspaceId);
  }

  @override
  Future<void> updateRun(PipelineRun run) async {
    await _dao(run.workspaceId).updateRun(pipelineRunToCompanion(run));
  }

  @override
  Future<PipelineRun?> getRun(String id) async {
    final dao = await _daoForRun(id);
    final row = await dao?.getRun(id);
    return row != null ? pipelineRunFromRow(row) : null;
  }

  @override
  Stream<PipelineRun?> watchRun(String id) {
    return Stream.fromFuture(_daoForRun(id)).asyncExpand(
      (dao) => dao == null
          ? Stream.value(null)
          : dao
                .watchRun(id)
                .map((row) => row != null ? pipelineRunFromRow(row) : null),
    );
  }

  @override
  Future<void> updateRunState(String runId, Map<String, dynamic> state) async {
    final dao = await _daoForRun(runId);
    await dao?.updateRunState(runId, jsonEncode(state));
  }

  @override
  Future<void> incrementCost(String runId, int cents, int tokens) async {
    final dao = await _daoForRun(runId);
    if (dao == null) {
      return;
    }
    final run = await dao.getRun(runId);
    if (run == null) {
      return;
    }
    await dao.updateRunCost(
      runId,
      run.totalCostCents + cents,
      run.totalTokens + tokens,
    );
  }

  /// CROSS-WORKSPACE BY DESIGN: the startup pipeline-resume reconciler needs
  /// every in-flight run on the install to re-attach or fail it, before any
  /// workspace has been chosen. Workspace surfaces use [watchForWorkspace].
  @override
  Future<List<PipelineRun>> nonTerminalRuns() async {
    final perWorkspace = await _cross.fanOut(
      (db) => db.pipelineDao.nonTerminalRuns(),
    );
    return [
      for (final rows in perWorkspace)
        for (final row in rows) pipelineRunFromRow(row),
    ];
  }

  @override
  Future<PipelineRun?> activeForDedupKey({
    required String templateId,
    required String workspaceId,
    required String dedupKey,
  }) async {
    final row = await _dao(
      workspaceId,
    ).findActiveByDedupKey(templateId, workspaceId, dedupKey);
    return row != null ? pipelineRunFromRow(row) : null;
  }

  /// CROSS-WORKSPACE BY DESIGN: the operator's all-workspace pipeline view.
  /// Every workspace-scoped surface uses [watchForWorkspace] instead.
  @override
  Stream<List<PipelineRun>> watchAll() {
    return _cross
        .mergeStreams(
          (db) => db.pipelineDao.watchAll(),
          // Concatenation does not preserve the per-workspace ordering, so the
          // merged list is re-sorted into one newest-first sequence.
          sort: (a, b) => b.startedAt.compareTo(a.startedAt),
        )
        .map((rows) => rows.map(pipelineRunFromRow).toList());
  }

  @override
  Stream<List<PipelineRun>> watchForWorkspace(String workspaceId) {
    return _dao(workspaceId)
        .watchForWorkspace(workspaceId)
        .map((rows) => rows.map(pipelineRunFromRow).toList());
  }

  @override
  Future<void> deleteRun(String workspaceId, String runId) async {
    final deleted = await _dao(workspaceId).deleteRun(workspaceId, runId);
    // Only drop the route when the row was actually this workspace's, so a
    // cross-workspace delete attempt cannot unroute someone else's run.
    if (deleted > 0) {
      await _routes.remove(WorkspaceRouteKind.pipelineRun, runId);
    }
  }

  @override
  Future<void> insertStepRun(PipelineStepRun stepRun) async {
    final dao = await _daoForRun(stepRun.pipelineRunId);
    await dao?.insertStepRun(stepRunToCompanion(stepRun));
  }

  @override
  Future<void> updateStepRun(
    String workspaceId,
    String stepRunId, {
    PipelineStepStatus? status,
    String? inputJson,
    String? outputJson,
    String? channelId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) async {
    await _dao(workspaceId).updateStepRun(
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
  Future<void> deleteStepRun(String workspaceId, String stepRunId) async {
    await _dao(workspaceId).deleteStepRun(stepRunId);
  }

  @override
  Future<List<PipelineStepRun>> stepRunsForPipeline(
    String pipelineRunId,
  ) async {
    final dao = await _daoForRun(pipelineRunId);
    final rows = await dao?.stepRunsForPipeline(pipelineRunId);
    return rows == null ? const [] : rows.map(stepRunFromRow).toList();
  }

  @override
  Future<PipelineStepRun?> getStepRunById(
    String workspaceId,
    String stepRunId,
  ) async {
    final row = await _dao(workspaceId).getStepRunById(stepRunId);
    return row != null ? stepRunFromRow(row) : null;
  }

  @override
  Stream<List<PipelineStepRun>> watchStepRunsForPipeline(String pipelineRunId) {
    return Stream.fromFuture(_daoForRun(pipelineRunId)).asyncExpand(
      (dao) => dao == null
          ? Stream.value(const <PipelineStepRun>[])
          : dao
                .watchStepRunsForPipeline(pipelineRunId)
                .map((rows) => rows.map(stepRunFromRow).toList()),
    );
  }
}
