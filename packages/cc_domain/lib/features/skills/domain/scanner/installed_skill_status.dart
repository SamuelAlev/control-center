import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_static_rules.dart';

/// How an on-disk skill relates to the workspace's `skills-lock.json`.
enum InstalledSkillLockState {
  /// On disk and pinned with a matching content hash.
  managed,

  /// On disk with no lock entry — authored outside the gated install paths
  /// (legacy editor saves, hand-copies), so no pin and no recorded verdict.
  unmanaged,

  /// Pinned but the on-disk content no longer matches the pinned hash —
  /// edited after install; the recorded verdict describes stale bytes.
  drifted;

  /// Stable wire string.
  String get wire => switch (this) {
    InstalledSkillLockState.managed => 'managed',
    InstalledSkillLockState.unmanaged => 'unmanaged',
    InstalledSkillLockState.drifted => 'drifted',
  };

  /// Parses from wire, defaulting to [unmanaged] (no pin = no trust).
  static InstalledSkillLockState fromWire(String value) => switch (value) {
    'managed' => InstalledSkillLockState.managed,
    'drifted' => InstalledSkillLockState.drifted,
    _ => InstalledSkillLockState.unmanaged,
  };
}

/// The security posture of one installed skill, as the settings UI renders it:
/// lock provenance plus the freshest scan verdict for the CURRENT on-disk bytes.
class InstalledSkillStatus {
  /// Creates an [InstalledSkillStatus]. Non-const: the assert validates the
  /// slug at construction.
  InstalledSkillStatus({
    required this.slug,
    required this.lockState,
    required this.computedHash,
    this.origin,
    this.source,
    this.trustTier,
    this.scan,
  }) {
    if (slug.isEmpty) {
      throw ArgumentError('slug must not be empty');
    }
  }

  /// The skill slug (directory basename).
  final String slug;

  /// How the skill relates to the lock (managed / unmanaged / drifted).
  final InstalledSkillLockState lockState;

  /// The rolled-up SHA256 of the skill's current on-disk files.
  final String computedHash;

  /// The lock-recorded origin (null when unmanaged).
  final SkillOrigin? origin;

  /// The lock-recorded source descriptor (null when unmanaged).
  final String? source;

  /// The lock-recorded provenance trust tier (null when unmanaged).
  final SkillTrustTier? trustTier;

  /// The most-recent cached scan verdict for [computedHash] (null when these
  /// exact bytes have never been scanned).
  final SkillScanResult? scan;

  /// Whether the recorded scan was produced under an older rules version
  /// (due for a re-scan under the current rules).
  bool get rulesStale =>
      scan != null && scan!.rulesVersion < kSkillRulesVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstalledSkillStatus &&
          runtimeType == other.runtimeType &&
          slug == other.slug &&
          lockState == other.lockState &&
          computedHash == other.computedHash &&
          origin == other.origin &&
          source == other.source &&
          trustTier == other.trustTier &&
          scan == other.scan;

  @override
  int get hashCode => Object.hash(
    slug,
    lockState,
    computedHash,
    origin,
    source,
    trustTier,
    scan,
  );
}
