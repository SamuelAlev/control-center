import 'package:cc_persistence/database/tables/plan_studio_tables.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'plan_studio_dao.g.dart';

/// Data access for Plan Studio (PRD 17): orchestration revision history,
/// single-agent plan-mode documents and reusable playbooks. Every read
/// filters by `workspaceId` (workspace isolation invariant).
@DriftAccessor(
  tables: [OrchestrationRevisionsTable, PlanDocumentsTable, PlaybooksTable],
)
class PlanStudioDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$PlanStudioDaoMixin {
  /// Creates a [PlanStudioDao].
  PlanStudioDao(super.db);

  // ── Orchestration revisions ──

  /// Records one revision snapshot. Idempotent per
  /// `(orchestrationId, revision)` — the table's unique key makes a repeat
  /// insert a no-op via `insertOrIgnore`, so the first-recorded row for a
  /// given revision always wins.
  Future<void> recordRevision(OrchestrationRevisionsTableCompanion row) => into(
    orchestrationRevisionsTable,
  ).insert(row, mode: InsertMode.insertOrIgnore);

  /// Every revision of [orchestrationId] within [workspaceId], oldest first.
  Future<List<OrchestrationRevisionsTableData>> revisionsForOrchestration(
    String workspaceId,
    String orchestrationId,
  ) =>
      (select(orchestrationRevisionsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.orchestrationId.equals(orchestrationId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.revision)]))
          .get();

  /// One revision snapshot within [workspaceId], or null.
  Future<OrchestrationRevisionsTableData?> byRevision(
    String workspaceId,
    String orchestrationId,
    int revision,
  ) =>
      (select(orchestrationRevisionsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.orchestrationId.equals(orchestrationId) &
                t.revision.equals(revision),
          ))
          .getSingleOrNull();

  /// Live revision list for [orchestrationId] within [workspaceId], oldest
  /// first.
  Stream<List<OrchestrationRevisionsTableData>> watchRevisionsForOrchestration(
    String workspaceId,
    String orchestrationId,
  ) =>
      (select(orchestrationRevisionsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.orchestrationId.equals(orchestrationId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.revision)]))
          .watch();

  // ── Plan documents ──

  /// Inserts or replaces a plan document (keyed by id).
  Future<void> upsertPlanDocument(PlanDocumentsTableCompanion entry) =>
      into(planDocumentsTable).insertOnConflictUpdate(entry);

  /// One plan document by id within [workspaceId], or null.
  Future<PlanDocumentsTableData?> getPlanDocumentById(
    String workspaceId,
    String id,
  ) =>
      (select(planDocumentsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// The newest document authored in [conversationId] within [workspaceId],
  /// or null.
  Future<PlanDocumentsTableData?> latestPlanDocumentForConversation(
    String workspaceId,
    String conversationId,
  ) =>
      (select(planDocumentsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.conversationId.equals(conversationId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Live plan documents for [workspaceId], newest first.
  Stream<List<PlanDocumentsTableData>> watchPlanDocumentsForWorkspace(
    String workspaceId,
  ) =>
      (select(planDocumentsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// Live single plan document within [workspaceId].
  Stream<PlanDocumentsTableData?> watchPlanDocumentById(
    String workspaceId,
    String id,
  ) =>
      (select(planDocumentsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .watchSingleOrNull();

  /// Deletes a plan document within [workspaceId]. Returns rows deleted.
  Future<int> deletePlanDocumentById(String workspaceId, String id) => (delete(
    planDocumentsTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();

  // ── Playbooks ──

  /// Inserts or replaces a playbook (keyed by id; name unique per workspace).
  Future<void> upsertPlaybook(PlaybooksTableCompanion entry) =>
      into(playbooksTable).insertOnConflictUpdate(entry);

  /// One playbook by id within [workspaceId], or null.
  Future<PlaybooksTableData?> getPlaybookById(String workspaceId, String id) =>
      (select(playbooksTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// One playbook by display name within [workspaceId], or null.
  Future<PlaybooksTableData?> getPlaybookByName(
    String workspaceId,
    String name,
  ) =>
      (select(playbooksTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.name.equals(name),
          ))
          .getSingleOrNull();

  /// All playbooks in [workspaceId], by name.
  Future<List<PlaybooksTableData>> playbooksForWorkspace(String workspaceId) =>
      (select(playbooksTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  /// Live playbook list for [workspaceId], by name.
  Stream<List<PlaybooksTableData>> watchPlaybooksForWorkspace(
    String workspaceId,
  ) =>
      (select(playbooksTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  /// Deletes a playbook within [workspaceId]. Returns rows deleted.
  Future<int> deletePlaybookById(String workspaceId, String id) => (delete(
    playbooksTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();
}
