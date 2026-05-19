import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';

/// A cached scan whose rules version is behind the current one — the unit
/// [SkillScanRepository.staleScans] reports for §6 continuous re-verification.
class StaleScan {
  /// Creates a [StaleScan].
  const StaleScan({required this.contentHash, required this.rulesVersion});

  /// The content hash whose cached verdict is stale.
  final String contentHash;

  /// The (older) rules version the cached verdict was produced under.
  final int rulesVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaleScan &&
          runtimeType == other.runtimeType &&
          contentHash == other.contentHash &&
          rulesVersion == other.rulesVersion;

  @override
  int get hashCode => Object.hash(contentHash, rulesVersion);
}

/// Persistence contract for the skill-scan cache + audit trail (PRD 23 §2, §3).
///
/// A scan is expensive (Layer 3 rides dispatch), so verdicts are cached by
/// `(workspaceId, contentHash, rulesVersion)`: identical bytes scanned under the
/// same rules are never re-scanned. Every read is **workspace-scoped** — a
/// verdict from one workspace must never satisfy another's install gate.
abstract interface class SkillScanRepository {
  /// Records [result] for [contentHash] in [workspaceId] (upsert). [skillRef]
  /// is the slug/coordinate scanned, kept for the audit surface.
  Future<void> upsert(
    String workspaceId,
    String contentHash,
    SkillScanResult result, {
    String? skillRef,
  });

  /// The cached result for exactly `(workspaceId, contentHash, rulesVersion)`,
  /// or null — the cache-by-hash fast path.
  Future<SkillScanResult?> byHash(
    String workspaceId,
    String contentHash,
    int rulesVersion,
  );

  /// The most-recent result for [contentHash] within [workspaceId] under ANY
  /// rules version (the staleness check compares its version to current).
  Future<SkillScanResult?> latestForHash(
    String workspaceId,
    String contentHash,
  );

  /// The scans in [workspaceId] produced under a rules version older than
  /// [currentRulesVersion] (verdict-stale, §6 continuous re-verify).
  Future<List<StaleScan>> staleScans(
    String workspaceId,
    int currentRulesVersion,
  );

  /// Live scan results in [workspaceId], newest first (audit surface).
  Stream<List<SkillScanResult>> watchScans(String workspaceId);
}
