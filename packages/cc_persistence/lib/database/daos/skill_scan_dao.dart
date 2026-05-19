import 'package:cc_persistence/database/tables/skill_scan_results_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'skill_scan_dao.g.dart';

/// Data access for the skill scan cache/audit (PRD 23). Every read filters by
/// `workspaceId` (workspace isolation invariant). The cache key is
/// `(workspaceId, contentHash, rulesVersion)`.
@DriftAccessor(tables: [SkillScanResultsTable])
class SkillScanDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$SkillScanDaoMixin {
  /// Creates a [SkillScanDao].
  SkillScanDao(super.db);

  /// Inserts or replaces a scan result (deterministic id → PK upsert).
  Future<void> upsertScan(SkillScanResultsTableCompanion entry) =>
      into(skillScanResultsTable).insertOnConflictUpdate(entry);

  /// The cached scan for exactly `(workspaceId, contentHash, rulesVersion)`, or
  /// null — the cache-by-hash fast path (identical bytes are never re-scanned).
  Future<SkillScanResultsTableData?> scanByHash(
    String workspaceId,
    String contentHash,
    int rulesVersion,
  ) =>
      (select(skillScanResultsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.contentHash.equals(contentHash) &
                t.rulesVersion.equals(rulesVersion),
          ))
          .getSingleOrNull();

  /// The most-recent scan for [contentHash] within [workspaceId] under ANY
  /// rules version (staleness check compares its `rulesVersion` to current).
  Future<SkillScanResultsTableData?> latestScanForHash(
    String workspaceId,
    String contentHash,
  ) =>
      (select(skillScanResultsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.contentHash.equals(contentHash),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.scannedAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Scan results in [workspaceId] scanned under a rules version older than
  /// [currentRulesVersion] — verdict-stale (§6 continuous re-verify).
  Future<List<SkillScanResultsTableData>> staleScans(
    String workspaceId,
    int currentRulesVersion,
  ) =>
      (select(skillScanResultsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.rulesVersion.isSmallerThanValue(currentRulesVersion),
          ))
          .get();

  /// All scan results in [workspaceId], newest first (audit surface).
  Future<List<SkillScanResultsTableData>> scans(String workspaceId) =>
      (select(skillScanResultsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.scannedAt)]))
          .get();

  /// Live scan results in [workspaceId].
  Stream<List<SkillScanResultsTableData>> watchScans(String workspaceId) =>
      (select(skillScanResultsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.scannedAt)]))
          .watch();
}
