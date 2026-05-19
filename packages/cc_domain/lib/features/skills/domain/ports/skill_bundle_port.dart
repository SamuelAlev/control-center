import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';

/// The result of verifying a workspace's pinned skills against the lock.
class SkillVerifyResult {
  /// Creates a [SkillVerifyResult].
  const SkillVerifyResult({
    this.matched = const [],
    this.drifted = const [],
    this.missing = const [],
    this.stale = const [],
    this.quarantined = const [],
  });

  /// Slugs whose on-disk content matches the recorded hash.
  final List<String> matched;

  /// Slugs whose on-disk content no longer matches the recorded hash.
  final List<String> drifted;

  /// Slugs recorded in the lock but missing on disk.
  final List<String> missing;

  /// Slugs whose recorded scan was produced under an older rules version and
  /// is due for a re-scan (PRD 23 §6 verdict-staleness).
  final List<String> stale;

  /// Slugs a re-scan (drift or rules bump) has quarantined and that are now
  /// blocked pending operator action (PRD 23 §6).
  final List<String> quarantined;

  /// Whether every pinned skill matches its recorded hash.
  bool get isClean => drifted.isEmpty && missing.isEmpty;
}

/// A pinned skill that has a newer version available upstream (PRD 23 §4).
class SkillUpdateCandidate {
  /// Creates a [SkillUpdateCandidate].
  const SkillUpdateCandidate({
    required this.slug,
    required this.currentRef,
    required this.latestRef,
  });

  /// The installed skill slug.
  final String slug;

  /// The currently-pinned ref (commit SHA / tag / branch).
  final String currentRef;

  /// The latest upstream ref for the skill's path on its tracking branch.
  final String latestRef;

  /// Whether the upstream ref differs from the pinned one.
  bool get hasUpdate => latestRef.isNotEmpty && latestRef != currentRef;

  @override
  bool operator ==(Object other) =>
      other is SkillUpdateCandidate &&
      other.slug == slug &&
      other.currentRef == currentRef &&
      other.latestRef == latestRef;

  @override
  int get hashCode => Object.hash(slug, currentRef, latestRef);
}

/// Content-addresses, pins, and installs workspace skill bundles.
///
/// Implemented in infrastructure (filesystem + GitHub + SHA256); the domain
/// only declares the contract so MCP tools and use cases stay testable.
abstract interface class SkillBundlePort {
  /// The rolled-up SHA256 of the skill [slug]'s files in [workspaceId], or
  /// `null` when the skill is absent on disk.
  Future<String?> computeSkillHash(String workspaceId, String slug);

  /// Reads the workspace's `skills-lock.json`, returning an empty lock when the
  /// file is absent.
  Future<SkillLock> readLock(String workspaceId);

  /// Writes the workspace's `skills-lock.json`.
  Future<void> writeLock(String workspaceId, SkillLock lock);

  /// Installs a skill from a GitHub repository, pinned to [ref], writing its
  /// `SKILL.md` into the workspace and recording the pin in the lock. When
  /// [ref] is a 40-hex commit SHA the pin is stable.
  ///
  /// The mandatory scan gate (PRD 23 §2) runs over the fetched bytes BEFORE any
  /// disk write; a `quarantine` verdict (or a scanner failure) aborts the
  /// install with a `SkillScanBlockedException`. [allowQuarantineOverride]
  /// permits an explicit, recorded operator override of a quarantine verdict.
  ///
  /// The skill's capability manifest is additionally resolved against the
  /// PRD 24 action policy (in [channelId]/[agentId] scope) before the write: a
  /// skill demanding a capability the workspace policy denies is blocked
  /// *before* install, not at runtime (PRD 23 §2 ties PRD 24).
  Future<SkillLockEntry> installFromGitHub({
    required String workspaceId,
    required String slug,
    required String owner,
    required String repo,
    required String path,
    required String ref,
    bool allowQuarantineOverride,
    String? channelId,
    String? agentId,
  });

  /// Records an already-present skill ([SkillOrigin.manual] /
  /// [SkillOrigin.runtimeLocal]) into the lock by hashing it now. Returns the
  /// recorded entry.
  Future<SkillLockEntry> pinLocal({
    required String workspaceId,
    required String slug,
    SkillOrigin origin,
    String source,
  });

  /// Verifies every pinned skill's on-disk content against its recorded hash.
  Future<SkillVerifyResult> verify(String workspaceId);

  /// Checks each GitHub-origin pinned skill for a newer upstream version on its
  /// tracking branch (PRD 23 §4). Best-effort per skill: a network error for
  /// one skill is skipped, not fatal. Returns only skills that actually have an
  /// update available.
  Future<List<SkillUpdateCandidate>> checkUpdates(String workspaceId);

  /// Re-fetches the skill [slug] at [ref], re-runs the FULL scan gate over the
  /// new bytes (PRD 23 §4, TOCTOU-safe), and re-pins it — recording the old
  /// hash as `previousHash` for rollback. Same fail-closed semantics as install:
  /// a quarantine verdict (without [allowQuarantineOverride]) or a scanner
  /// error throws and leaves the currently-installed version untouched.
  Future<SkillLockEntry> applyUpdate({
    required String workspaceId,
    required String slug,
    required String ref,
    bool allowQuarantineOverride,
    String? channelId,
    String? agentId,
  });

  /// Re-scans installed skills whose recorded scan is verdict-stale (produced
  /// under an older rules version) against the CURRENT rules over their on-disk
  /// bytes, rewriting each lock entry's verdict + rules version — clearing or
  /// quarantining it (PRD 23 §6 continuous re-verification). Returns the slugs
  /// that were re-scanned. A no-op when no scanner is wired. Never applies a
  /// network fetch (it reads on-disk content only) and never throws for one
  /// skill's failure.
  Future<List<String>> reVerify(String workspaceId);

  /// Resolves [slug] (optionally [version]) from the skills registry, runs the
  /// FULL scan gate over the fetched bytes, and installs + pins it to the
  /// computed content hash (PRD 23 §1/§3). Same fail-closed semantics as a
  /// GitHub install. Throws [StateError] when no registry is wired.
  Future<SkillLockEntry> installFromRegistry({
    required String workspaceId,
    required String slug,
    String? version,
    bool allowQuarantineOverride,
    String? channelId,
    String? agentId,
  });

  /// Resolves [slug] and scans it WITHOUT writing anything — the pre-confirm
  /// preview for the browse UI (PRD 23 §1). Returns the scan result over the
  /// exact bytes an install would write (byte-identical; cache-by-hash makes the
  /// subsequent install scan free). Returns even a `quarantine` verdict (never
  /// throws on verdict) so the operator sees why. Throws only when no registry
  /// is wired or resolution fails.
  Future<SkillScanResult> previewInstall({
    required String workspaceId,
    required String slug,
    String? version,
  });
}
