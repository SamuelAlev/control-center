import 'package:cc_persistence/database/tables/review_studio_tables.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'review_studio_dao.g.dart';

/// Data access for Review Studio (PRD 18): semantic cohorts, API-contract
/// diffs, UI visual diffs and per-axis results. Every read filters by
/// `workspaceId` (workspace isolation invariant); repo-scoped snapshots also
/// filter by `repoId`.
@DriftAccessor(
  tables: [
    ReviewCohortsTable,
    ApiContractSnapshotsTable,
    VisualDiffSnapshotsTable,
    ReviewAxisResultsTable,
    ReviewDependencyDiffsTable,
    ReviewRunSnapshotsTable,
  ],
)
class ReviewStudioDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ReviewStudioDaoMixin {
  /// Creates a [ReviewStudioDao].
  ReviewStudioDao(super.db);

  // ── Cohorts ──

  /// Atomically replaces the whole cohort set for [prExternalId] within
  /// [workspaceId] (a recompute on PR open / head-SHA change). Readers never
  /// observe a half-written set.
  Future<void> replaceCohortsForPr(
    String workspaceId,
    String prExternalId,
    List<ReviewCohortsTableCompanion> cohorts,
  ) => transaction(() async {
    await (delete(reviewCohortsTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) & t.prExternalId.equals(prExternalId),
        ))
        .go();
    if (cohorts.isNotEmpty) {
      await batch((b) => b.insertAll(reviewCohortsTable, cohorts));
    }
  });

  /// The cohorts for [prExternalId] within [workspaceId], in reading order.
  Future<List<ReviewCohortsTableData>> cohortsForPr(
    String workspaceId,
    String prExternalId,
  ) =>
      (select(reviewCohortsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prExternalId.equals(prExternalId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .get();

  /// Live cohorts for [prExternalId] within [workspaceId], in reading order.
  Stream<List<ReviewCohortsTableData>> watchCohortsForPr(
    String workspaceId,
    String prExternalId,
  ) =>
      (select(reviewCohortsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prExternalId.equals(prExternalId),
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

  /// The contract snapshots for [prExternalId] within [workspaceId].
  Future<List<ApiContractSnapshotsTableData>> contractSnapshotsForPr(
    String workspaceId,
    String prExternalId,
  ) =>
      (select(apiContractSnapshotsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prExternalId.equals(prExternalId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.specPath)]))
          .get();

  /// Live contract snapshots for [prExternalId] within [workspaceId].
  Stream<List<ApiContractSnapshotsTableData>> watchContractSnapshotsForPr(
    String workspaceId,
    String prExternalId,
  ) =>
      (select(apiContractSnapshotsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prExternalId.equals(prExternalId),
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

  /// The visual snapshots for [prExternalId] within [workspaceId].
  Future<List<VisualDiffSnapshotsTableData>> visualSnapshotsForPr(
    String workspaceId,
    String prExternalId,
  ) =>
      (select(visualDiffSnapshotsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prExternalId.equals(prExternalId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.componentKey)]))
          .get();

  /// Live visual snapshots for [prExternalId] within [workspaceId].
  Stream<List<VisualDiffSnapshotsTableData>> watchVisualSnapshotsForPr(
    String workspaceId,
    String prExternalId,
  ) =>
      (select(visualDiffSnapshotsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prExternalId.equals(prExternalId),
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

  /// The axis results for [prExternalId] within [workspaceId].
  Future<List<ReviewAxisResultsTableData>> axisResultsForPr(
    String workspaceId,
    String prExternalId,
  ) =>
      (select(reviewAxisResultsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prExternalId.equals(prExternalId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.axis)]))
          .get();

  /// Live axis results for [prExternalId] within [workspaceId].
  Stream<List<ReviewAxisResultsTableData>> watchAxisResultsForPr(
    String workspaceId,
    String prExternalId,
  ) =>
      (select(reviewAxisResultsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prExternalId.equals(prExternalId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.axis)]))
          .watch();

  // ── Dependency diffs ──

  /// Atomically replaces the whole dependency-diff set for [prExternalId]
  /// within [workspaceId]. Replaced wholesale on every recompute for the same
  /// reason cohorts are: a lockfile removed from the PR must stop being
  /// reported, which an upsert-only path would never notice.
  Future<void> replaceDependencyDiffsForPr(
    String workspaceId,
    String prExternalId,
    List<ReviewDependencyDiffsTableCompanion> diffs,
  ) => transaction(() async {
    await (delete(reviewDependencyDiffsTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.prExternalId.equals(prExternalId),
        ))
        .go();
    if (diffs.isNotEmpty) {
      await batch((b) => b.insertAll(reviewDependencyDiffsTable, diffs));
    }
  });

  /// The dependency diffs for [prExternalId] within [workspaceId].
  Future<List<ReviewDependencyDiffsTableData>> dependencyDiffsForPr(
    String workspaceId,
    String prExternalId,
  ) =>
      (select(reviewDependencyDiffsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prExternalId.equals(prExternalId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.filePath)]))
          .get();

  /// Live dependency diffs for [prExternalId] within [workspaceId].
  Stream<List<ReviewDependencyDiffsTableData>> watchDependencyDiffsForPr(
    String workspaceId,
    String prExternalId,
  ) =>
      (select(reviewDependencyDiffsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prExternalId.equals(prExternalId),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.filePath)]))
          .watch();

  // ── Review run snapshots ──

  /// Records one finalized review pass.
  Future<void> insertRunSnapshot(ReviewRunSnapshotsTableCompanion entry) =>
      into(reviewRunSnapshotsTable).insert(entry);

  /// The most recent finalized pass for [prExternalId] within [workspaceId],
  /// or null when this is the first review of the PR.
  Future<ReviewRunSnapshotsTableData?> latestRunSnapshot(
    String workspaceId,
    String prExternalId,
  ) =>
      (select(reviewRunSnapshotsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prExternalId.equals(prExternalId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.finalizedAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Finalized passes for [prExternalId] within [workspaceId], newest first.
  Future<List<ReviewRunSnapshotsTableData>> runSnapshotsForPr(
    String workspaceId,
    String prExternalId, {
    int limit = 20,
  }) =>
      (select(reviewRunSnapshotsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.prExternalId.equals(prExternalId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.finalizedAt)])
            ..limit(limit))
          .get();

  /// Every finalized pass in [workspaceId], newest first — the input to the
  /// review-effectiveness counters ("N findings made, M addressed").
  Future<List<ReviewRunSnapshotsTableData>> runSnapshotsForWorkspace(
    String workspaceId, {
    int limit = 500,
  }) =>
      (select(reviewRunSnapshotsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.finalizedAt)])
            ..limit(limit))
          .get();
}
