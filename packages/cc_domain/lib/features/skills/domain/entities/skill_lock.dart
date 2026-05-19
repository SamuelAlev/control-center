import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';

/// Where a pinned skill's content originates.
enum SkillOrigin {
  /// Authored in-workspace (e.g. via `create_skill`).
  manual,

  /// Copied from a runtime-local skills directory on disk.
  runtimeLocal,

  /// Fetched from a GitHub repository, pinned to a commit SHA.
  github,

  /// Resolved and installed from a skills registry (skills.sh), pinned to the
  /// content hash Control Center computed over the fetched bytes.
  registry;

  /// The `skills-lock.json` storage string.
  String get wire => switch (this) {
    SkillOrigin.manual => 'manual',
    SkillOrigin.runtimeLocal => 'runtime-local',
    SkillOrigin.github => 'github',
    SkillOrigin.registry => 'registry',
  };

  /// Parses a [SkillOrigin] from its storage string, defaulting to [manual].
  static SkillOrigin fromWire(String value) => switch (value) {
    'runtime-local' => SkillOrigin.runtimeLocal,
    'github' => SkillOrigin.github,
    'registry' => SkillOrigin.registry,
    _ => SkillOrigin.manual,
  };
}

/// One pinned skill in the lock file: its origin, the path that was hashed, the
/// content-addressed rolled-up hash, and (for GitHub origins) the pinned ref.
class SkillLockEntry {
  /// Creates a [SkillLockEntry].
  const SkillLockEntry({
    required this.slug,
    required this.source,
    required this.sourceType,
    required this.skillPath,
    required this.computedHash,
    this.ref,
    this.trustTier = SkillTrustTier.community,
    this.scanVerdict,
    this.rulesVersion,
    this.previousHash,
  });

  /// The skill slug (directory basename).
  final String slug;

  /// The origin descriptor: `owner/repo` for GitHub, a local path / label
  /// otherwise.
  final String source;

  /// The origin kind.
  final SkillOrigin sourceType;

  /// The path within the source that was hashed (e.g. `skills/<slug>/SKILL.md`).
  final String skillPath;

  /// The content-addressed rolled-up SHA256 of the skill's files.
  final String computedHash;

  /// For [SkillOrigin.github], the 40-hex commit SHA the skill is pinned to.
  final String? ref;

  /// The provenance trust tier (PRD 23 §5). Never a scan substitute — a
  /// [SkillTrustTier.verified] skill is still scanned. Defaults to
  /// [SkillTrustTier.community] so pre-scanner locks parse unchanged.
  final SkillTrustTier trustTier;

  /// The scan verdict recorded at install (null on pre-scanner locks).
  final SkillScanVerdict? scanVerdict;

  /// The static-rules version [scanVerdict] was produced under (null on
  /// pre-scanner locks). Compared against `kSkillRulesVersion` for staleness.
  final int? rulesVersion;

  /// The hash this entry replaced, forming the rollback chain (PRD 23 §5). Null
  /// for the first install of a slug.
  final String? previousHash;

  /// Whether [ref] is a full 40-hex commit SHA (a stable pin, not a branch/tag).
  bool get isPinnedToCommit =>
      ref != null && RegExp(r'^[0-9a-f]{40}$').hasMatch(ref!);

  /// JSON for the lock file. Only non-default/non-null scanner fields are
  /// emitted so pre-scanner locks round-trip byte-identically.
  Map<String, dynamic> toJson() => {
    'source': source,
    'sourceType': sourceType.wire,
    'skillPath': skillPath,
    'computedHash': computedHash,
    if (ref != null) 'ref': ref,
    if (trustTier != SkillTrustTier.community) 'trustTier': trustTier.wire,
    if (scanVerdict != null) 'scanVerdict': scanVerdict!.wire,
    if (rulesVersion != null) 'rulesVersion': rulesVersion,
    if (previousHash != null) 'previousHash': previousHash,
  };

  /// Reconstructs an entry from its lock-file JSON. Tolerant: a lock written
  /// before the scanner (no scanner fields) parses to the safe defaults.
  static SkillLockEntry fromJson(String slug, Map<String, dynamic> json) =>
      SkillLockEntry(
        slug: slug,
        source: (json['source'] as String?) ?? '',
        sourceType: SkillOrigin.fromWire((json['sourceType'] as String?) ?? ''),
        skillPath: (json['skillPath'] as String?) ?? '',
        computedHash: (json['computedHash'] as String?) ?? '',
        ref: json['ref'] as String?,
        trustTier: SkillTrustTier.fromWire(json['trustTier'] as String?),
        scanVerdict: json['scanVerdict'] == null
            ? null
            : SkillScanVerdict.fromWire(json['scanVerdict'] as String),
        rulesVersion: (json['rulesVersion'] as num?)?.toInt(),
        previousHash: json['previousHash'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillLockEntry &&
          runtimeType == other.runtimeType &&
          slug == other.slug &&
          computedHash == other.computedHash &&
          ref == other.ref;

  @override
  int get hashCode => Object.hash(slug, computedHash, ref);
}

/// The parsed `skills-lock.json`: a versioned, content-addressed manifest of a
/// workspace's pinned skills.
class SkillLock {
  /// Creates a [SkillLock].
  const SkillLock({this.version = 1, this.skills = const {}});

  /// The lock-file format version.
  final int version;

  /// Pinned skills keyed by slug.
  final Map<String, SkillLockEntry> skills;

  /// Returns a copy with [entry] added/replaced under its slug.
  SkillLock withEntry(SkillLockEntry entry) =>
      SkillLock(version: version, skills: {...skills, entry.slug: entry});

  /// Returns a copy with [slug] removed.
  SkillLock without(String slug) => SkillLock(
    version: version,
    skills: {
      for (final e in skills.entries)
        if (e.key != slug) e.key: e.value,
    },
  );

  /// Serializes to the canonical `skills-lock.json` shape (slugs sorted for a
  /// stable, diff-friendly file).
  Map<String, dynamic> toJson() {
    final sorted = skills.keys.toList()..sort();
    return {
      'version': version,
      'skills': {for (final slug in sorted) slug: skills[slug]!.toJson()},
    };
  }

  /// Parses a lock file, tolerating an empty/malformed shape (→ empty lock).
  static SkillLock fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills'];
    final skills = <String, SkillLockEntry>{};
    if (rawSkills is Map) {
      for (final entry in rawSkills.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          final slug = entry.key.toString();
          skills[slug] = SkillLockEntry.fromJson(slug, value);
        }
      }
    }
    final version = json['version'];
    return SkillLock(version: version is int ? version : 1, skills: skills);
  }

  /// An empty lock at version 1.
  static const SkillLock empty = SkillLock();
}
