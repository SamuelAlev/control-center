import 'dart:convert';

import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/orchestration_dao.dart';
import 'package:control_center/features/orchestration/domain/entities/orchestration.dart';
import 'package:control_center/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:control_center/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:control_center/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:drift/drift.dart';

/// Drift-backed [OrchestrationRepository].
class DaoOrchestrationRepository implements OrchestrationRepository {
  /// Creates a [DaoOrchestrationRepository].
  DaoOrchestrationRepository(this._dao);

  final OrchestrationDao _dao;

  @override
  Future<void> insert(Orchestration o) => _dao.insert(_toCompanion(o));

  @override
  Future<void> update(Orchestration o) =>
      _dao.updateById(o.id, o.workspaceId, _toCompanion(o));

  @override
  Future<Orchestration?> getById(String workspaceId, String id) async {
    final row = await _dao.getById(id, workspaceId);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<Orchestration?> forParentTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final row = await _dao.forParentTicket(workspaceId, ticketId);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<Orchestration?> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async {
    final row = await _dao.forPipelineRun(workspaceId, pipelineRunId);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<Orchestration?> forPipelineRunAnyWorkspace(
    String pipelineRunId,
  ) async {
    final row = await _dao.forPipelineRunAnyWorkspace(pipelineRunId);
    return row == null ? null : _fromRow(row);
  }

  @override
  Stream<List<Orchestration>> watchForWorkspace(String workspaceId) =>
      _dao.watchForWorkspace(workspaceId).map(
            (rows) => rows.map(_fromRow).toList(),
          );

  @override
  Stream<Orchestration?> watchById(String workspaceId, String id) =>
      _dao.watchById(id, workspaceId).map(
            (row) => row == null ? null : _fromRow(row),
          );

  @override
  Future<List<Orchestration>> approvedNeedingMaterialization() async {
    final rows = await _dao.approvedNeedingMaterialization();
    return rows.map(_fromRow).toList();
  }

  OrchestrationsTableCompanion _toCompanion(Orchestration o) =>
      OrchestrationsTableCompanion(
        id: Value(o.id),
        workspaceId: Value(o.workspaceId),
        parentTicketId: Value(o.parentTicketId),
        channelId: Value(o.channelId),
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
        channelId: row.channelId,
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
        errorMessage: row.errorMessage,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        completedAt: row.completedAt,
      );
}
