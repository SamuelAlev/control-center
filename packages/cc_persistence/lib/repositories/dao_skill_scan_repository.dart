import 'dart:convert';

import 'package:cc_domain/features/skills/domain/repositories/skill_scan_repository.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_persistence/database/daos/skill_scan_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [SkillScanRepository] (PRD 23).
///
/// Maps rows↔[SkillScanResult]: the verdict, findings, and capability
/// manifest are stored as their wire/JSON forms and reconstructed on read.
/// Scan results live in their workspace's own database file, so the
/// `workspaceId` every method takes picks the file before any SQL runs.
class DaoSkillScanRepository implements SkillScanRepository {
  /// Creates a [DaoSkillScanRepository] over the per-workspace databases.
  DaoSkillScanRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  SkillScanDao _dao(String workspaceId) => _dbs.of(workspaceId).skillScanDao;

  @override
  Future<void> upsert(
    String workspaceId,
    String contentHash,
    SkillScanResult result, {
    String? skillRef,
  }) => _dao(workspaceId).upsertScan(
    SkillScanResultsTableCompanion(
      // Deterministic id from the cache key so a re-scan of identical
      // bytes under the same rules UPDATES in place (PK upsert) instead
      // of hitting the (workspaceId, contentHash, rulesVersion) UNIQUE
      // constraint.
      id: Value('$workspaceId:$contentHash:${result.rulesVersion}'),
      workspaceId: Value(workspaceId),
      contentHash: Value(contentHash),
      rulesVersion: Value(result.rulesVersion),
      verdict: Value(result.verdict.wire),
      findingsJson: Value(result.findingsJsonString()),
      manifestJson: Value(result.manifest.toJsonString()),
      llmReviewed: Value(result.llmReviewed),
      skillRef: Value(skillRef),
      scannedAt: Value(DateTime.now()),
    ),
  );

  @override
  Future<SkillScanResult?> byHash(
    String workspaceId,
    String contentHash,
    int rulesVersion,
  ) async {
    final row = await _dao(
      workspaceId,
    ).scanByHash(workspaceId, contentHash, rulesVersion);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<SkillScanResult?> latestForHash(
    String workspaceId,
    String contentHash,
  ) async {
    final row = await _dao(
      workspaceId,
    ).latestScanForHash(workspaceId, contentHash);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<List<StaleScan>> staleScans(
    String workspaceId,
    int currentRulesVersion,
  ) async =>
      (await _dao(workspaceId).staleScans(workspaceId, currentRulesVersion))
          .map(
            (r) => StaleScan(
              contentHash: r.contentHash,
              rulesVersion: r.rulesVersion,
            ),
          )
          .toList();

  @override
  Stream<List<SkillScanResult>> watchScans(String workspaceId) => _dao(
    workspaceId,
  ).watchScans(workspaceId).map((rows) => rows.map(_fromRow).toList());

  /// Reconstructs a [SkillScanResult] from a stored row.
  SkillScanResult _fromRow(SkillScanResultsTableData row) {
    final rawFindings = jsonDecode(row.findingsJson);
    final findings = <SkillScanFinding>[
      if (rawFindings is List)
        for (final f in rawFindings)
          if (f is Map<String, dynamic>) SkillScanFinding.fromJson(f),
    ];
    final rawManifest = jsonDecode(row.manifestJson);
    final manifest = rawManifest is Map<String, dynamic>
        ? SkillCapabilityManifest.fromJson(rawManifest)
        : const SkillCapabilityManifest();
    return SkillScanResult(
      verdict: SkillScanVerdict.fromWire(row.verdict),
      findings: findings,
      manifest: manifest,
      rulesVersion: row.rulesVersion,
      llmReviewed: row.llmReviewed,
    );
  }
}
