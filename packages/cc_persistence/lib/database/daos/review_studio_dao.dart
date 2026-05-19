import 'package:cc_persistence/database/tables/review_studio_tables.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'review_studio_dao.g.dart';

/// Data access for Review Studio (PRD 18): semantic cohorts, API-contract
/// diffs, UI visual diffs, and per-axis results. Every read filters by
/// `workspaceId` (workspace isolation invariant); repo-scoped snapshots also
/// filter by `repoId`.
@DriftAccessor(
  tables: [
    ReviewCohortsTable,
    ApiContractSnapshotsTable,
    VisualDiffSnapshotsTable,
    ReviewAxisResultsTable,
  ],
)
class ReviewStudioDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ReviewStudioDaoMixin {
  /// Creates a [ReviewStudioDao].
  ReviewStudioDao(super.db);

  // ── Cohorts ──

  /// Atomically replaces the whole cohort set for [prNodeId] within
  /// [workspaceId] (a recompute on PR open / head-SHA change). Readers never
  /// observe a half-written set.
  Future<void> replaceCohortsForPr(
    String workspaceId,
    String prNodeId,
    List<ReviewCohortsTableCompanion> cohorts,
  ) => transaction(() async {
    await (delete(reviewCohortsTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) & t.prNodeId.equals(prNodeId),
        ))
        .go();
    if (cohorts.isNotEmpty) {
      await batch((b) => b.insertAll(reviewCohortsTable, cohorts));
    }
  });

  /// The cohorts for [prNodeId] within [workspaceId], in reading order.
  Future<List<ReviewCohortsTableData>> cohortsForPr(
    String workspaceId,
    String prNodeId,
  ) =>
      (select(reviewCohortsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prNodeId.equals(prNodeId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .get();

  /// Live cohorts for [prNodeId] within [workspaceId], in reading order.
  Stream<List<ReviewCohortsTableData>> watchCohortsForPr(
    String workspaceId,
    String prNodeId,
  ) =>
      (select(reviewCohortsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prNodeId.equals(prNodeId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .watch();

  /// Sets a single cohort's summary markdown within [workspaceId].
  Future<void> updateCohortSummary(
    String workspaceId,
    String cohortId,
    String summaryMarkdown,
  ) =>
      (update(reviewCohortsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.id.equals(cohortId),
          ))
          .write(
            ReviewCohortsTableCompanion(
              summaryMarkdown: Value(summaryMarkdown),
              updatedAt: Value(DateTime.now()),
            ),
          );

  /// Replaces a single cohort's diagrams JSON within [workspaceId].
  Future<void> updateCohortDiagrams(
    String workspaceId,
    String cohortId,
    String diagramsJson,
  ) =>
      (update(reviewCohortsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.id.equals(cohortId),
          ))
          .write(
            ReviewCohortsTableCompanion(
              diagramsJson: Value(diagramsJson),
              updatedAt: Value(DateTime.now()),
            ),
          );

  // ── API contract snapshots ──

  /// Inserts or replaces a contract snapshot (deterministic id → PK upsert).
  Future<void> upsertContractSnapshot(
    ApiContractSnapshotsTableCompanion entry,
  ) => into(apiContractSnapshotsTable).insertOnConflictUpdate(entry);

  /// The contract snapshots for [prNodeId] within [workspaceId].
  Future<List<ApiContractSnapshotsTableData>> contractSnapshotsForPr(
    String workspaceId,
    String prNodeId,
  ) =>
      (select(apiContractSnapshotsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prNodeId.equals(prNodeId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.specPath)]))
          .get();

  /// Live contract snapshots for [prNodeId] within [workspaceId].
  Stream<List<ApiContractSnapshotsTableData>> watchContractSnapshotsForPr(
    String workspaceId,
    String prNodeId,
  ) =>
      (select(apiContractSnapshotsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prNodeId.equals(prNodeId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.specPath)]))
          .watch();

  /// One contract snapshot by id within [workspaceId], or null.
  Future<ApiContractSnapshotsTableData?> contractSnapshotById(
    String workspaceId,
    String id,
  ) =>
      (select(apiContractSnapshotsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .getSingleOrNull();

  /// Writes back a snapshot's classified-changes JSON (per-change decision).
  Future<void> updateContractChanges(
    String workspaceId,
    String id,
    String changesJson,
  ) =>
      (update(apiContractSnapshotsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .write(
            ApiContractSnapshotsTableCompanion(changesJson: Value(changesJson)),
          );

  // ── Visual diff snapshots ──

  /// Inserts or replaces a visual snapshot (deterministic id → PK upsert).
  Future<void> upsertVisualSnapshot(VisualDiffSnapshotsTableCompanion entry) =>
      into(visualDiffSnapshotsTable).insertOnConflictUpdate(entry);

  /// The visual snapshots for [prNodeId] within [workspaceId].
  Future<List<VisualDiffSnapshotsTableData>> visualSnapshotsForPr(
    String workspaceId,
    String prNodeId,
  ) =>
      (select(visualDiffSnapshotsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prNodeId.equals(prNodeId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.componentKey)]))
          .get();

  /// Live visual snapshots for [prNodeId] within [workspaceId].
  Stream<List<VisualDiffSnapshotsTableData>> watchVisualSnapshotsForPr(
    String workspaceId,
    String prNodeId,
  ) =>
      (select(visualDiffSnapshotsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prNodeId.equals(prNodeId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.componentKey)]))
          .watch();

  /// Sets a visual snapshot's approval status within [workspaceId].
  Future<void> updateVisualStatus(
    String workspaceId,
    String id,
    String status,
  ) =>
      (update(visualDiffSnapshotsTable)
            ..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id)))
          .write(VisualDiffSnapshotsTableCompanion(status: Value(status)));

  // ── Axis results ──

  /// Inserts or replaces an axis result (deterministic id → PK upsert).
  Future<void> upsertAxisResult(ReviewAxisResultsTableCompanion entry) =>
      into(reviewAxisResultsTable).insertOnConflictUpdate(entry);

  /// The axis results for [prNodeId] within [workspaceId].
  Future<List<ReviewAxisResultsTableData>> axisResultsForPr(
    String workspaceId,
    String prNodeId,
  ) =>
      (select(reviewAxisResultsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prNodeId.equals(prNodeId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.axis)]))
          .get();

  /// Live axis results for [prNodeId] within [workspaceId].
  Stream<List<ReviewAxisResultsTableData>> watchAxisResultsForPr(
    String workspaceId,
    String prNodeId,
  ) =>
      (select(reviewAxisResultsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prNodeId.equals(prNodeId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.axis)]))
          .watch();
}
