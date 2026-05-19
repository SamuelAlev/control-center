import 'dart:convert';

import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/orchestration_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [OrchestrationRepository].
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).orchestrationDao` per call: orchestrations live in
/// their workspace's own database file, so the workspace id picks the file
/// before any SQL runs. [forPipelineRunAnyWorkspace] and
/// [approvedNeedingMaterialization] are the two reads that span files.
class DaoOrchestrationRepository implements OrchestrationRepository {
  /// Creates a [DaoOrchestrationRepository] over the per-workspace databases.
  DaoOrchestrationRepository(this._dbs) : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;

  OrchestrationDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).orchestrationDao;

  @override
  Future<void> insert(Orchestration o) =>
      // The orchestration names its own workspace, so the file is picked from
      // the entity rather than from a parameter that could disagree with it.
      _dao(o.workspaceId).insert(_toCompanion(o));

  @override
  Future<void> update(Orchestration o) =>
      _dao(o.workspaceId).updateById(o.id, o.workspaceId, _toCompanion(o));

  @override
  Future<Orchestration?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(id, workspaceId);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<Orchestration?> forParentTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final row = await _dao(workspaceId).forParentTicket(workspaceId, ticketId);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<Orchestration?> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async {
    final row = await _dao(
      workspaceId,
    ).forPipelineRun(workspaceId, pipelineRunId);
    return row == null ? null : _fromRow(row);
  }

  /// CROSS-WORKSPACE BY DESIGN: the pipeline event router receives a run id and
  /// nothing else, so the owning workspace has to be discovered. At most one
  /// workspace can own a run id, so the first hit wins. Callers that already
  /// know the workspace use [forPipelineRun].
  @override
  Future<Orchestration?> forPipelineRunAnyWorkspace(
    String pipelineRunId,
  ) async {
    final rows = await _cross.fanOut(
      (db) => db.orchestrationDao.forPipelineRunAnyWorkspace(pipelineRunId),
    );
    for (final row in rows) {
      if (row != null) {
        return _fromRow(row);
      }
    }
    return null;
  }

  @override
  Stream<List<Orchestration>> watchForWorkspace(String workspaceId) => _dao(
    workspaceId,
  ).watchForWorkspace(workspaceId).map((rows) => rows.map(_fromRow).toList());

  @override
  Stream<Orchestration?> watchById(String workspaceId, String id) => _dao(
    workspaceId,
  ).watchById(id, workspaceId).map((row) => row == null ? null : _fromRow(row));

  /// CROSS-WORKSPACE BY DESIGN: the boot-time materialization reconciler. An
  /// orchestration approved before a restart has to be resumed wherever it
  /// lives, so completeness across every workspace file is the point.
  @override
  Future<List<Orchestration>> approvedNeedingMaterialization() async {
    final perWorkspace = await _cross.fanOut(
      (db) => db.orchestrationDao.approvedNeedingMaterialization(),
    );
    return [
      for (final rows in perWorkspace)
        for (final row in rows) _fromRow(row),
    ];
  }

  OrchestrationsTableCompanion _toCompanion(Orchestration o) =>
      OrchestrationsTableCompanion(
        id: Value(o.id),
        workspaceId: Value(o.workspaceId),
        parentTicketId: Value(o.parentTicketId),
        spaceId: Value(o.spaceId),
        orchestratorAgentId: Value(o.orchestratorAgentId),
        status: Value(o.status.toStorageString()),
        proposalJson: Value(o.proposal.toJsonString()),
        revision: Value(o.revision),
        approvedRevision: Value(o.approvedRevision),
        pipelineTemplateId: Value(o.pipelineTemplateId),
        pipelineRunId: Value(o.pipelineRunId),
        teamId: Value(o.teamId),
        projectId: Value(o.projectId),
        estimatedCostCents: Value(o.estimatedCostCents),
        maxCostCents: Value(o.maxCostCents),
        hiredAgentIdsJson: Value(jsonEncode(o.hiredAgentIds)),
        approvedNodeKeysJson: Value(
          o.approvedNodeKeys == null ? null : jsonEncode(o.approvedNodeKeys),
        ),
        errorMessage: Value(o.errorMessage),
        createdAt: Value(o.createdAt),
        updatedAt: Value(o.updatedAt),
        completedAt: Value(o.completedAt),
      );

  Orchestration _fromRow(OrchestrationsTableData row) => Orchestration(
    id: row.id,
    workspaceId: row.workspaceId,
    proposal: OrchestrationProposal.fromJsonString(row.proposalJson),
    parentTicketId: row.parentTicketId,
    spaceId: row.spaceId,
    orchestratorAgentId: row.orchestratorAgentId,
    status: OrchestrationStatus.fromStorage(row.status),
    revision: row.revision,
    approvedRevision: row.approvedRevision,
    pipelineTemplateId: row.pipelineTemplateId,
    pipelineRunId: row.pipelineRunId,
    teamId: row.teamId,
    projectId: row.projectId,
    estimatedCostCents: row.estimatedCostCents,
    maxCostCents: row.maxCostCents,
    hiredAgentIds: (jsonDecode(row.hiredAgentIdsJson) as List)
        .whereType<String>()
        .toList(),
    approvedNodeKeys: row.approvedNodeKeysJson == null
        ? null
        : (jsonDecode(row.approvedNodeKeysJson!) as List)
              .whereType<String>()
              .toList(),
    errorMessage: row.errorMessage,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    completedAt: row.completedAt,
  );
}
