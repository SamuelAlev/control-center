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

  /// Resolved `runId -> workspaceId` routes, most-recently-used last.
  ///
  /// A run's workspace never changes: [insertRun] writes the route and
  /// [deleteRun] drops it, and nothing in between re-points a run at a
  /// different workspace. So a resolved route is a fact, not a snapshot, and
  /// re-asking `global.db` for it is pure overhead.
  ///
  /// It is not a micro-optimisation. Every id-only read — [getRun],
  /// [stepRunsForPipeline], [insertStepRun], [updateRunState], [incrementCost]
  /// — pays this lookup, and the engine performs six to ten of them per step
  /// against a server that holds ONE shared database connection. Under a
  /// multi-repo fan-out those queries queue ahead of every RPC the clients are
  /// waiting on.
  ///
  /// Only positive resolutions are cached. A miss must stay uncached: the route
  /// is written just after the run row, so a reader that raced the insert would
  /// otherwise remember "this run does not exist" for the life of the process.
  final Map<String, String> _routeCache = {};

  /// Cap on [_routeCache]. Bounded because a long-lived server indexing repos
  /// publishes a run per reindex; unbounded, the map would track every run the
  /// process ever touched.
  static const int _routeCacheLimit = 512;

  /// The workspace owning [runId], or null when no route was recorded for it.
  ///
  /// A miss stays a miss: reading every workspace to find the run would turn a
  /// missing route into a slow success and hide it forever.
  Future<String?> _workspaceOf(String runId) async {
    final cached = _routeCache[runId];
    if (cached != null) {
      return cached;
    }
    final resolved = await _routes.resolve(
      WorkspaceRouteKind.pipelineRun,
      runId,
    );
    if (resolved != null) {
      _rememberRoute(runId, resolved);
    }
    return resolved;
  }

  /// Records [runId]'s workspace, evicting the least-recently-used entry once
  /// the cache is full.
  void _rememberRoute(String runId, String workspaceId) {
    // Re-inserting moves the key to the end, which is what makes the map's
    // insertion order double as recency.
    _routeCache
      ..remove(runId)
      ..[runId] = workspaceId;
    while (_routeCache.length > _routeCacheLimit) {
      _routeCache.remove(_routeCache.keys.first);
    }
  }

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
    // The engine reads this run several times per step it executes, starting
    // immediately; seeding here means none of those reads has to ask global.db
    // for something this call already knows.
    _rememberRoute(run.id, run.workspaceId);
  }

  /// Writes [run]'s lifecycle columns. `state` and the cost totals on the
  /// passed object are IGNORED — they belong to [updateRunState] and
  /// [incrementCost], whose writers run concurrently with every transition. See
  /// [pipelineRunToUpdateCompanion].
  @override
  Future<void> updateRun(PipelineRun run) async {
    await _dao(run.workspaceId).updateRun(pipelineRunToUpdateCompanion(run));
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
    // One statement, never read-then-write: a fan-out's agents all complete at
    // once and two rollups reading the same pre-increment total would each
    // write it back plus their own share, losing one. See
    // [PipelineDao.incrementRunCost].
    await dao?.incrementRunCost(runId, cents, tokens);
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

  @override
  Future<int> activeRunCountForTemplate({
    required String workspaceId,
    required String templateId,
    Set<String> excludeTriggerEventTypes = const {},
  }) => _dao(workspaceId).countActiveForTemplate(
    workspaceId,
    templateId,
    excludeTriggerEventTypes: excludeTriggerEventTypes,
  );

  @override
  Future<PipelineRun?> nextQueuedRunForTemplate({
    required String workspaceId,
    required String templateId,
  }) async {
    final row = await _dao(
      workspaceId,
    ).findOldestQueuedForTemplate(workspaceId, templateId);
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
          //
          // `startedAt` has one-second resolution, so runs created together tie
          // — and rowid, the tiebreak inside a workspace file, means nothing
          // ACROSS files. Falling back to the id keeps this view from
          // reshuffling identically-stamped rows on every emission; it is a
          // stable order, not a queue order. Queue position is read off
          // [watchForWorkspace], which orders within one file and can.
          sort: (a, b) {
            final byTime = b.startedAt.compareTo(a.startedAt);
            return byTime != 0 ? byTime : b.id.compareTo(a.id);
          },
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
      _routeCache.remove(runId);
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
    String? spaceId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) async {
    await _dao(workspaceId).updateStepRun(
      id: stepRunId,
      status: status?.toStorageString(),
      inputJson: inputJson,
      outputJson: outputJson,
      spaceId: spaceId,
      errorMessage: errorMessage,
      errorStackTrace: errorStackTrace,
      finishedAt: finishedAt,
    );
  }

  @override
  Future<void> restartStepRun(
    String workspaceId,
    String stepRunId, {
    required DateTime startedAt,
  }) async {
    await _dao(workspaceId).restartStepRun(stepRunId, startedAt);
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
