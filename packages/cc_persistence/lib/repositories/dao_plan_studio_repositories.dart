import 'dart:convert';

import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/orchestration_revision.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_persistence/database/daos/plan_studio_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [OrchestrationRevisionRepository].
class DaoOrchestrationRevisionRepository
    implements OrchestrationRevisionRepository {
  /// Creates a [DaoOrchestrationRevisionRepository] over the per-workspace
  /// databases.
  DaoOrchestrationRevisionRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  PlanStudioDao _dao(String workspaceId) => _dbs.of(workspaceId).planStudioDao;

  @override
  Future<void> record(OrchestrationRevision revision) =>
      // The revision names its own workspace, so the file is picked from the
      // entity rather than from a parameter that could disagree with it.
      _dao(revision.workspaceId).recordRevision(
        OrchestrationRevisionsTableCompanion(
          id: Value(revision.id),
          workspaceId: Value(revision.workspaceId),
          orchestrationId: Value(revision.orchestrationId),
          revision: Value(revision.revision),
          proposalJson: Value(revision.proposal.toJsonString()),
          authoredBy: Value(revision.authoredBy),
          authorKind: Value(revision.authorKind),
          createdAt: Value(revision.createdAt),
        ),
      );

  @override
  Future<List<OrchestrationRevision>> forOrchestration(
    String workspaceId,
    String orchestrationId,
  ) async {
    final rows = await _dao(
      workspaceId,
    ).revisionsForOrchestration(workspaceId, orchestrationId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<OrchestrationRevision?> byRevision(
    String workspaceId,
    String orchestrationId,
    int revision,
  ) async {
    final row = await _dao(
      workspaceId,
    ).byRevision(workspaceId, orchestrationId, revision);
    return row == null ? null : _fromRow(row);
  }

  @override
  Stream<List<OrchestrationRevision>> watchForOrchestration(
    String workspaceId,
    String orchestrationId,
  ) => _dao(workspaceId)
      .watchRevisionsForOrchestration(workspaceId, orchestrationId)
      .map((rows) => rows.map(_fromRow).toList());

  OrchestrationRevision _fromRow(OrchestrationRevisionsTableData row) =>
      OrchestrationRevision(
        id: row.id,
        workspaceId: row.workspaceId,
        orchestrationId: row.orchestrationId,
        revision: row.revision,
        proposal: OrchestrationProposal.fromJsonString(row.proposalJson),
        authoredBy: row.authoredBy,
        authorKind: row.authorKind,
        createdAt: row.createdAt,
      );
}

/// Drift-backed [PlanDocumentRepository].
class DaoPlanDocumentRepository implements PlanDocumentRepository {
  /// Creates a [DaoPlanDocumentRepository] over the per-workspace
  /// databases.
  DaoPlanDocumentRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  PlanStudioDao _dao(String workspaceId) => _dbs.of(workspaceId).planStudioDao;

  @override
  Future<void> upsert(PlanDocument doc) =>
      _dao(doc.workspaceId).upsertPlanDocument(_toCompanion(doc));

  @override
  Future<PlanDocument?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getPlanDocumentById(workspaceId, id);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<PlanDocument?> latestForConversation(
    String workspaceId,
    String conversationId,
  ) async {
    final row = await _dao(
      workspaceId,
    ).latestPlanDocumentForConversation(workspaceId, conversationId);
    return row == null ? null : _fromRow(row);
  }

  @override
  Stream<List<PlanDocument>> watchForWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchPlanDocumentsForWorkspace(workspaceId)
          .map((rows) => rows.map(_fromRow).toList());

  @override
  Stream<PlanDocument?> watchById(String workspaceId, String id) =>
      _dao(workspaceId)
          .watchPlanDocumentById(workspaceId, id)
          .map((row) => row == null ? null : _fromRow(row));

  @override
  Future<void> deleteById(String workspaceId, String id) =>
      _dao(workspaceId).deletePlanDocumentById(workspaceId, id);

  PlanDocumentsTableCompanion _toCompanion(PlanDocument doc) =>
      PlanDocumentsTableCompanion(
        id: Value(doc.id),
        workspaceId: Value(doc.workspaceId),
        conversationId: Value(doc.conversationId),
        agentId: Value(doc.agentId),
        planJson: Value(doc.bodyToJsonString()),
        status: Value(doc.status.name),
        revision: Value(doc.revision),
        createdAt: Value(doc.createdAt),
        updatedAt: Value(doc.updatedAt),
      );

  PlanDocument _fromRow(PlanDocumentsTableData row) => PlanDocument.fromBody(
    id: row.id,
    workspaceId: row.workspaceId,
    conversationId: row.conversationId,
    agentId: row.agentId,
    body: jsonDecode(row.planJson) as Map<String, dynamic>,
    status: PlanDocumentStatus.fromName(row.status),
    revision: row.revision,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

/// Drift-backed [PlaybookRepository].
class DaoPlaybookRepository implements PlaybookRepository {
  /// Creates a [DaoPlaybookRepository] over the per-workspace
  /// databases.
  DaoPlaybookRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  PlanStudioDao _dao(String workspaceId) => _dbs.of(workspaceId).planStudioDao;

  @override
  Future<void> upsert(Playbook playbook) =>
      _dao(playbook.workspaceId).upsertPlaybook(_toCompanion(playbook));

  @override
  Future<Playbook?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getPlaybookById(workspaceId, id);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<Playbook?> getByName(String workspaceId, String name) async {
    final row = await _dao(workspaceId).getPlaybookByName(workspaceId, name);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<Playbook>> forWorkspace(String workspaceId) async {
    final rows = await _dao(workspaceId).playbooksForWorkspace(workspaceId);
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<Playbook>> watchForWorkspace(String workspaceId) =>
      _dao(workspaceId)
          .watchPlaybooksForWorkspace(workspaceId)
          .map((rows) => rows.map(_fromRow).toList());

  @override
  Future<void> deleteById(String workspaceId, String id) =>
      _dao(workspaceId).deletePlaybookById(workspaceId, id);

  PlaybooksTableCompanion _toCompanion(Playbook playbook) =>
      PlaybooksTableCompanion(
        id: Value(playbook.id),
        workspaceId: Value(playbook.workspaceId),
        name: Value(playbook.name),
        description: Value(playbook.description),
        paramsSchemaJson: Value(playbook.paramsToJsonString()),
        sourceProposalJson: Value(playbook.sourceProposal.toJsonString()),
        version: Value(playbook.version),
        createdAt: Value(playbook.createdAt),
        updatedAt: Value(playbook.updatedAt),
      );

  Playbook _fromRow(PlaybooksTableData row) => Playbook(
    id: row.id,
    workspaceId: row.workspaceId,
    name: row.name,
    description: row.description,
    params: Playbook.paramsFromJsonString(row.paramsSchemaJson),
    sourceProposal: OrchestrationProposal.fromJsonString(
      row.sourceProposalJson,
    ),
    version: row.version,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
