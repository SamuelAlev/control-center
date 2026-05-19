import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/finding_fingerprint.dart';
import 'package:cc_domain/features/pr_review/domain/services/lockfile_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/cohort_insights.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_dependency_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_diagram.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_run_snapshot.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
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
  Future<List<ReviewCohort>> forPr(String workspaceId, String prExternalId) async {
    final rows = await _dao(workspaceId).cohortsForPr(workspaceId, prExternalId);
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<ReviewCohort>> watchForPr(String workspaceId, String prExternalId) =>
      _dao(workspaceId)
          .watchCohortsForPr(workspaceId, prExternalId)
          .map((rows) => rows.map(_fromRow).toList());

  @override
  Future<void> replaceForPr(
    String workspaceId,
    String prExternalId,
    List<ReviewCohort> cohorts,
  ) => _dao(workspaceId).replaceCohortsForPr(
    workspaceId,
    prExternalId,
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
        prExternalId: Value(c.prExternalId),
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
        insightsJson: Value(jsonEncode(c.insights.toJson())),
        headSha: Value(c.headSha),
      );

  ReviewCohort _fromRow(ReviewCohortsTableData row) => ReviewCohort(
    id: row.id,
    workspaceId: row.workspaceId,
    prExternalId: row.prExternalId,
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
    insights: _decodeInsights(row.insightsJson),
    headSha: row.headSha,
  );

  /// Insights are an enrichment: a blob written by a different server version
  /// must never make the cohort itself unreadable.
  CohortInsights _decodeInsights(String raw) {
    if (raw.isEmpty) {
      return CohortInsights.empty;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return CohortInsights.empty;
      }
      return CohortInsights.fromJson(decoded.cast<String, dynamic>());
    } on FormatException {
      return CohortInsights.empty;
    }
  }
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
    String prExternalId,
  ) async {
    final rows = await _dao(
      workspaceId,
    ).contractSnapshotsForPr(workspaceId, prExternalId);
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<ApiContractDiff>> watchForPr(
    String workspaceId,
    String prExternalId,
  ) => _dao(workspaceId)
      .watchContractSnapshotsForPr(workspaceId, prExternalId)
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
        prExternalId: Value(d.prExternalId),
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
        prExternalId: row.prExternalId,
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
    String prExternalId,
  ) async {
    final rows = await _dao(
      workspaceId,
    ).visualSnapshotsForPr(workspaceId, prExternalId);
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<VisualDiffSnapshot>> watchForPr(
    String workspaceId,
    String prExternalId,
  ) => _dao(workspaceId)
      .watchVisualSnapshotsForPr(workspaceId, prExternalId)
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
        prExternalId: Value(s.prExternalId),
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
        prExternalId: row.prExternalId,
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
    String prExternalId,
  ) async {
    final rows = await _dao(
      workspaceId,
    ).axisResultsForPr(workspaceId, prExternalId);
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<ReviewAxisResult>> watchForPr(
    String workspaceId,
    String prExternalId,
  ) => _dao(workspaceId)
      .watchAxisResultsForPr(workspaceId, prExternalId)
      .map((rows) => rows.map(_fromRow).toList());

  @override
  Future<void> upsert(
    String workspaceId,
    String prExternalId,
    ReviewAxisResult result,
  ) => _dao(workspaceId).upsertAxisResult(
    ReviewAxisResultsTableCompanion(
      // Deterministic id per (pr, axis) → PK upsert dedupes on re-run.
      id: Value('$prExternalId:${result.axis.wireName}'),
      workspaceId: Value(workspaceId),
      prExternalId: Value(prExternalId),
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

/// Drift-backed [ReviewDependencyDiffRepository].
class DaoReviewDependencyDiffRepository
    implements ReviewDependencyDiffRepository {
  /// Creates a [DaoReviewDependencyDiffRepository] over the per-workspace
  /// databases.
  DaoReviewDependencyDiffRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  ReviewStudioDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).reviewStudioDao;

  @override
  Future<List<PrDependencyDiff>> forPr(
    String workspaceId,
    String prExternalId,
  ) async {
    final rows = await _dao(
      workspaceId,
    ).dependencyDiffsForPr(workspaceId, prExternalId);
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<PrDependencyDiff>> watchForPr(
    String workspaceId,
    String prExternalId,
  ) => _dao(workspaceId)
      .watchDependencyDiffsForPr(workspaceId, prExternalId)
      .map((rows) => rows.map(_fromRow).toList());

  @override
  Future<void> replaceForPr(
    String workspaceId,
    String prExternalId,
    List<PrDependencyDiff> diffs,
  ) => _dao(workspaceId).replaceDependencyDiffsForPr(workspaceId, prExternalId, [
    for (final d in diffs)
      ReviewDependencyDiffsTableCompanion(
        id: Value(d.id),
        workspaceId: Value(workspaceId),
        prExternalId: Value(prExternalId),
        filePath: Value(d.filePath),
        ecosystem: Value(d.ecosystem.wireName),
        baseSha: Value(d.baseSha),
        headSha: Value(d.headSha),
        diffJson: Value(jsonEncode(d.diff.toJson())),
      ),
  ]);

  PrDependencyDiff _fromRow(ReviewDependencyDiffsTableData row) {
    final ecosystem =
        LockfileEcosystem.fromName(row.ecosystem) ?? LockfileEcosystem.pub;
    return PrDependencyDiff(
      id: row.id,
      workspaceId: row.workspaceId,
      prExternalId: row.prExternalId,
      filePath: row.filePath,
      diff: _decodeDiff(row.diffJson, ecosystem),
      baseSha: row.baseSha,
      headSha: row.headSha,
    );
  }

  /// A blob written by a different server version degrades to "no movement",
  /// never to an unreadable row.
  DependencyDiff _decodeDiff(String raw, LockfileEcosystem fallback) {
    if (raw.isEmpty) {
      return DependencyDiff(ecosystem: fallback);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return DependencyDiff(ecosystem: fallback);
      }
      return DependencyDiff.fromJson(decoded.cast<String, dynamic>()) ??
          DependencyDiff(ecosystem: fallback);
    } on FormatException {
      return DependencyDiff(ecosystem: fallback);
    }
  }
}

/// Drift-backed [ReviewRunSnapshotRepository].
class DaoReviewRunSnapshotRepository implements ReviewRunSnapshotRepository {
  /// Creates a [DaoReviewRunSnapshotRepository] over the per-workspace
  /// databases.
  DaoReviewRunSnapshotRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  ReviewStudioDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).reviewStudioDao;

  @override
  Future<void> record(String workspaceId, ReviewRunSnapshot snapshot) =>
      _dao(workspaceId).insertRunSnapshot(
        ReviewRunSnapshotsTableCompanion(
          id: Value(snapshot.id),
          workspaceId: Value(workspaceId),
          prExternalId: Value(snapshot.prExternalId),
          channelId: Value(snapshot.channelId),
          headSha: Value(snapshot.headSha),
          finalizedAt: Value(snapshot.finalizedAt),
          verdictJson: Value(
            jsonEncode(snapshot.verdict?.toMetadata() ?? const {}),
          ),
          fingerprintsJson: Value(
            jsonEncode([for (final f in snapshot.fingerprints) f.toJson()]),
          ),
          statsJson: Value(jsonEncode(snapshot.stats.toJson())),
        ),
      );

  @override
  Future<ReviewRunSnapshot?> latestForPr(
    String workspaceId,
    String prExternalId,
  ) async {
    final row = await _dao(
      workspaceId,
    ).latestRunSnapshot(workspaceId, prExternalId);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<ReviewRunSnapshot>> forPr(
    String workspaceId,
    String prExternalId, {
    int limit = 20,
  }) async {
    final rows = await _dao(
      workspaceId,
    ).runSnapshotsForPr(workspaceId, prExternalId, limit: limit);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<ReviewRunStats> statsForWorkspace(String workspaceId) async {
    final rows = await _dao(workspaceId).runSnapshotsForWorkspace(workspaceId);
    var total = const ReviewRunStats();
    for (final row in rows) {
      total = total + _decodeStats(row.statsJson);
    }
    return total;
  }

  ReviewRunSnapshot _fromRow(ReviewRunSnapshotsTableData row) =>
      ReviewRunSnapshot(
        id: row.id,
        workspaceId: row.workspaceId,
        prExternalId: row.prExternalId,
        channelId: row.channelId,
        finalizedAt: row.finalizedAt,
        headSha: row.headSha,
        verdict: _decodeVerdict(row.verdictJson),
        fingerprints: _decodeFingerprints(row.fingerprintsJson),
        stats: _decodeStats(row.statsJson),
      );

  ReviewVerdict? _decodeVerdict(String raw) {
    final map = _decodeMap(raw);
    return map == null ? null : ReviewVerdict.fromMetadata(map);
  }

  ReviewRunStats _decodeStats(String raw) =>
      ReviewRunStats.fromJson(_decodeMap(raw));

  List<FindingFingerprint> _decodeFingerprints(String raw) {
    if (raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      final out = <FindingFingerprint>[];
      for (final entry in decoded) {
        if (entry is! Map) {
          continue;
        }
        final parsed = FindingFingerprint.fromJson(
          entry.cast<String, dynamic>(),
        );
        if (parsed != null) {
          out.add(parsed);
        }
      }
      return out;
    } on FormatException {
      return const [];
    }
  }

  Map<String, dynamic>? _decodeMap(String raw) {
    if (raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } on FormatException {
      return null;
    }
  }
}
