import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/scanner/installed_skill_status.dart';
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

/// Content-addresses, pins and installs workspace skill bundles.
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

  /// Installs a skill from a GitHub repository (the operator's registered
  /// skill sources or any explicit `owner/repo`), writing the skill's whole
  /// directory (its `SKILL.md` plus its supporting files) into the workspace
  /// and recording the pin in the lock. [path] is the repo-relative path to
  /// the skill's `SKILL.md`; a 40-hex commit SHA [ref] is a stable pin (null =
  /// the latest commit touching the skill).
  ///
  /// The mandatory scan gate (PRD 23 §2) runs over the fetched bytes BEFORE any
  /// disk write; a `quarantine` verdict (or a scanner failure) aborts the
  /// install with a `SkillScanBlockedException`. [allowQuarantineOverride]
  /// permits an explicit, recorded operator override of a quarantine verdict.
  ///
  /// The skill's capability manifest is additionally resolved against the
  /// PRD 24 action policy (in [spaceId]/[agentId] scope) before the write: a
  /// skill demanding a capability the workspace policy denies is blocked
  /// *before* install, not at runtime (PRD 23 §2 ties PRD 24).
  Future<SkillLockEntry> installFromGitHub({
    required String workspaceId,
    required String slug,
    required String owner,
    required String repo,
    required String path,
    String? ref,
    bool allowQuarantineOverride,
    String? spaceId,
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
  /// new bytes (PRD 23 §4, TOCTOU-safe) and re-pins it — recording the old
  /// hash as `previousHash` for rollback. Same fail-closed semantics as install:
  /// a quarantine verdict (without [allowQuarantineOverride]) or a scanner
  /// error throws and leaves the currently-installed version untouched.
  Future<SkillLockEntry> applyUpdate({
    required String workspaceId,
    required String slug,
    String? ref,
    bool allowQuarantineOverride,
    String? spaceId,
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

  /// Scans [files] — the exact bytes a caller already resolved for a skill —
  /// WITHOUT writing anything: the pre-confirm preview for the sources UI's
  /// detail view. Byte-identical to what an install would write, so the later
  /// install's scan is a free cache hit. Returns even a `quarantine` verdict
  /// (never throws on verdict) so the operator sees why. Throws when no
  /// scanner is wired.
  Future<SkillScanResult> previewFiles({
    required String workspaceId,
    required String slug,
    required Map<String, String> files,
  });

  /// Uninstalls a skill: removes its directory from disk and its entry from
  /// the lock. Returns the removed lock entry, or null when the skill was
  /// unmanaged (no entry — the directory is still deleted).
  Future<SkillLockEntry?> uninstall({
    required String workspaceId,
    required String slug,
  });

  /// Scans the CURRENT on-disk bytes of an installed skill (every file in its
  /// directory, lock excluded — the same rollup `computeSkillHash` addresses)
  /// and returns the verdict without writing skill content. Scan-only like
  /// [previewFiles]: returns even a `quarantine` verdict. When the verdict is
  /// `quarantine` the lock entry is upserted (adopting an unmanaged skill as
  /// `manual`-origin) so the quarantine is durable and enforcement (agent-link
  /// filtering) can see it; other verdicts leave the lock untouched. Throws
  /// [StateError] when the skill is absent on disk or no scanner is wired.
  Future<SkillScanResult> scanInstalled({
    required String workspaceId,
    required String slug,
    bool runLlmReview,
  });

  /// The gated save path for locally authored/edited skills (the settings
  /// editor): runs the scan gate over [content] BEFORE any disk write (Layers
  /// 1–2, [SkillTrustTier.workspace] — parity with `create_skill`) plus the
  /// PRD 24 capability→policy check, then writes and PINS the skill so it is
  /// lock-managed (visible to `verify`/`reVerify`). An existing lock entry's
  /// provenance (source/origin/trustTier) is preserved across the edit and the
  /// replaced hash is recorded as `previousHash`. Fail-closed: a `quarantine`
  /// verdict without [allowQuarantineOverride] (or a scanner/policy error)
  /// throws a `SkillScanBlockedException` and nothing is written.
  Future<SkillLockEntry> saveLocal({
    required String workspaceId,
    required String slug,
    required String content,
    bool allowQuarantineOverride,
    String? spaceId,
    String? agentId,
  });

  /// The security posture of every skill installed in the workspace: lock
  /// provenance (managed / unmanaged / drifted) plus the freshest cached scan
  /// verdict for each skill's CURRENT on-disk hash. Read-only; never scans.
  Future<List<InstalledSkillStatus>> listInstalledStatus(String workspaceId);
}
