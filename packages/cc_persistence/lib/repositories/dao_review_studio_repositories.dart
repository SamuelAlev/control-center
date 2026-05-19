import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_diagram.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';
import 'package:cc_persistence/database/daos/review_studio_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [ReviewCohortRepository] (PRD 18 §1).
class DaoReviewCohortRepository implements ReviewCohortRepository {
  /// Creates a [DaoReviewCohortRepository] over the per-workspace databases.
  DaoReviewCohortRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  ReviewStudioDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).reviewStudioDao;

  @override
  Future<List<ReviewCohort>> forPr(String workspaceId, String prNodeId) async {
    final rows = await _dao(workspaceId).cohortsForPr(workspaceId, prNodeId);
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<ReviewCohort>> watchForPr(String workspaceId, String prNodeId) =>
      _dao(workspaceId)
          .watchCohortsForPr(workspaceId, prNodeId)
          .map((rows) => rows.map(_fromRow).toList());

  @override
  Future<void> replaceForPr(
    String workspaceId,
    String prNodeId,
    List<ReviewCohort> cohorts,
  ) => _dao(workspaceId).replaceCohortsForPr(
    workspaceId,
    prNodeId,
    cohorts.map(_toCompanion).toList(),
  );

  @override
  Future<void> updateSummary(
    String workspaceId,
    String cohortId,
    String summaryMarkdown,
  ) => _dao(
    workspaceId,
  ).updateCohortSummary(workspaceId, cohortId, summaryMarkdown);

  @override
  Future<void> updateDiagrams(
    String workspaceId,
    String cohortId,
    List<ReviewDiagram> diagrams,
  ) => _dao(workspaceId).updateCohortDiagrams(
    workspaceId,
    cohortId,
    jsonEncode(diagrams.map((d) => d.toJson()).toList()),
  );

  ReviewCohortsTableCompanion _toCompanion(ReviewCohort c) =>
      ReviewCohortsTableCompanion(
        id: Value(c.id),
        workspaceId: Value(c.workspaceId),
        prNodeId: Value(c.prNodeId),
        cohortKey: Value(c.cohortKey),
        title: Value(c.title),
        summaryMarkdown: Value(c.summaryMarkdown),
        orderIndex: Value(c.orderIndex),
        impactScore: Value(c.impactScore),
        derivation: Value(c.derivation.wireName),
        filePathsJson: Value(jsonEncode(c.filePaths)),
        layersJson: Value(jsonEncode(c.layers.map((l) => l.toJson()).toList())),
        diagramsJson: Value(
          jsonEncode(c.diagrams.map((d) => d.toJson()).toList()),
        ),
        headSha: Value(c.headSha),
      );

  ReviewCohort _fromRow(ReviewCohortsTableData row) => ReviewCohort(
    id: row.id,
    workspaceId: row.workspaceId,
    prNodeId: row.prNodeId,
    cohortKey: row.cohortKey,
    title: row.title,
    summaryMarkdown: row.summaryMarkdown,
    orderIndex: row.orderIndex,
    impactScore: row.impactScore,
    derivation: CohortDerivation.fromName(row.derivation),
    filePaths: (jsonDecode(row.filePathsJson) as List)
        .whereType<String>()
        .toList(),
    layers: (jsonDecode(row.layersJson) as List)
        .whereType<Map>()
        .map((m) => CohortLayer.fromJson(m.cast<String, dynamic>()))
        .toList(),
    diagrams: (jsonDecode(row.diagramsJson) as List)
        .whereType<Map>()
        .map((m) => ReviewDiagram.fromJson(m.cast<String, dynamic>()))
        .toList(),
    headSha: row.headSha,
  );
}

/// Drift-backed [ApiContractDiffRepository] (PRD 18 §5).
class DaoApiContractDiffRepository implements ApiContractDiffRepository {
  /// Creates a [DaoApiContractDiffRepository] over the per-workspace databases.
  DaoApiContractDiffRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  ReviewStudioDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).reviewStudioDao;

  @override
  Future<List<ApiContractDiff>> forPr(
    String workspaceId,
    String prNodeId,
  ) async {
    final rows = await _dao(
      workspaceId,
    ).contractSnapshotsForPr(workspaceId, prNodeId);
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<ApiContractDiff>> watchForPr(
    String workspaceId,
    String prNodeId,
  ) => _dao(workspaceId)
      .watchContractSnapshotsForPr(workspaceId, prNodeId)
      .map((rows) => rows.map(_fromRow).toList());

  @override
  Future<void> upsert(String workspaceId, ApiContractDiff diff) =>
      _dao(workspaceId).upsertContractSnapshot(_toCompanion(diff));

  @override
  Future<void> setChangeDecision(
    String workspaceId,
    String diffId,
    String changeId,
    ApiChangeDecision decision,
  ) async {
    final row = await _dao(
      workspaceId,
    ).contractSnapshotById(workspaceId, diffId);
    if (row == null) {
      return;
    }
    final updated = _fromRow(row).withChangeDecision(changeId, decision);
    await _dao(workspaceId).updateContractChanges(
      workspaceId,
      diffId,
      jsonEncode(updated.changes.map((c) => c.toJson()).toList()),
    );
  }

  ApiContractSnapshotsTableCompanion _toCompanion(ApiContractDiff d) =>
      ApiContractSnapshotsTableCompanion(
        id: Value(d.id),
        workspaceId: Value(d.workspaceId),
        repoId: Value(d.repoId),
        prNodeId: Value(d.prNodeId),
        specPath: Value(d.specPath),
        changesJson: Value(
          jsonEncode(d.changes.map((c) => c.toJson()).toList()),
        ),
        derived: Value(d.derived),
        headSha: Value(d.headSha),
      );

  ApiContractDiff _fromRow(ApiContractSnapshotsTableData row) =>
      ApiContractDiff(
        id: row.id,
        workspaceId: row.workspaceId,
        repoId: row.repoId,
        prNodeId: row.prNodeId,
        specPath: row.specPath,
        changes: (jsonDecode(row.changesJson) as List)
            .whereType<Map>()
            .map((m) => ApiContractChange.fromJson(m.cast<String, dynamic>()))
            .toList(),
        headSha: row.headSha,
        derived: row.derived,
      );
}

/// Drift-backed [VisualDiffRepository] (PRD 18 §4).
class DaoVisualDiffRepository implements VisualDiffRepository {
  /// Creates a [DaoVisualDiffRepository] over the per-workspace databases.
  DaoVisualDiffRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  ReviewStudioDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).reviewStudioDao;

  @override
  Future<List<VisualDiffSnapshot>> forPr(
    String workspaceId,
    String prNodeId,
  ) async {
    final rows = await _dao(
      workspaceId,
    ).visualSnapshotsForPr(workspaceId, prNodeId);
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<VisualDiffSnapshot>> watchForPr(
    String workspaceId,
    String prNodeId,
  ) => _dao(workspaceId)
      .watchVisualSnapshotsForPr(workspaceId, prNodeId)
      .map((rows) => rows.map(_fromRow).toList());

  @override
  Future<void> upsert(String workspaceId, VisualDiffSnapshot snapshot) =>
      _dao(workspaceId).upsertVisualSnapshot(_toCompanion(snapshot));

  @override
  Future<void> setStatus(
    String workspaceId,
    String snapshotId,
    VisualDiffStatus status,
  ) => _dao(
    workspaceId,
  ).updateVisualStatus(workspaceId, snapshotId, status.wireName);

  VisualDiffSnapshotsTableCompanion _toCompanion(VisualDiffSnapshot s) =>
      VisualDiffSnapshotsTableCompanion(
        id: Value(s.id),
        workspaceId: Value(s.workspaceId),
        repoId: Value(s.repoId),
        prNodeId: Value(s.prNodeId),
        componentKey: Value(s.componentKey),
        componentTitle: Value(s.componentTitle),
        status: Value(s.status.wireName),
        variantsJson: Value(
          jsonEncode(s.variants.map((v) => v.toJson()).toList()),
        ),
        headSha: Value(s.headSha),
      );

  VisualDiffSnapshot _fromRow(VisualDiffSnapshotsTableData row) =>
      VisualDiffSnapshot(
        id: row.id,
        workspaceId: row.workspaceId,
        repoId: row.repoId,
        prNodeId: row.prNodeId,
        componentKey: row.componentKey,
        componentTitle: row.componentTitle,
        status: VisualDiffStatus.fromName(row.status),
        variants: (jsonDecode(row.variantsJson) as List)
            .whereType<Map>()
            .map((m) => VisualDiffVariant.fromJson(m.cast<String, dynamic>()))
            .toList(),
        headSha: row.headSha,
      );
}

/// Drift-backed [ReviewAxisResultRepository] (PRD 18 §7).
class DaoReviewAxisResultRepository implements ReviewAxisResultRepository {
  /// Creates a [DaoReviewAxisResultRepository] over the per-workspace
  /// databases.
  DaoReviewAxisResultRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  ReviewStudioDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).reviewStudioDao;

  @override
  Future<List<ReviewAxisResult>> forPr(
    String workspaceId,
    String prNodeId,
  ) async {
    final rows = await _dao(
      workspaceId,
    ).axisResultsForPr(workspaceId, prNodeId);
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<ReviewAxisResult>> watchForPr(
    String workspaceId,
    String prNodeId,
  ) => _dao(workspaceId)
      .watchAxisResultsForPr(workspaceId, prNodeId)
      .map((rows) => rows.map(_fromRow).toList());

  @override
  Future<void> upsert(
    String workspaceId,
    String prNodeId,
    ReviewAxisResult result,
  ) => _dao(workspaceId).upsertAxisResult(
    ReviewAxisResultsTableCompanion(
      // Deterministic id per (pr, axis) → PK upsert dedupes on re-run.
      id: Value('$prNodeId:${result.axis.wireName}'),
      workspaceId: Value(workspaceId),
      prNodeId: Value(prNodeId),
      axis: Value(result.axis.wireName),
      verdict: Value(result.verdict.wireName),
      findingsCount: Value(result.findingsCount),
      gated: Value(result.gated),
      confidence: Value(result.confidence),
      note: Value(result.note),
      updatedAt: Value(DateTime.now()),
    ),
  );

  ReviewAxisResult _fromRow(ReviewAxisResultsTableData row) => ReviewAxisResult(
    axis: ReviewAxis.fromName(row.axis) ?? ReviewAxis.correctness,
    verdict: ReviewAxisVerdict.fromName(row.verdict),
    findingsCount: row.findingsCount,
    gated: row.gated,
    confidence: row.confidence.clamp(0.0, 1.0),
    note: row.note,
  );
}
