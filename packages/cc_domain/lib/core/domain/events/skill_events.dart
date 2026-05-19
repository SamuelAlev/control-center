import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';

/// Origin constants for [SkillUpdated].
abstract final class SkillUpdateOrigin {
  /// Installed/updated from the skills registry (marketplace).
  static const String registry = 'registry';

  /// Installed/updated from a GitHub repository (MCP install path).
  static const String github = 'github';

  /// Authored/edited in-workspace (the settings editor save path).
  static const String manual = 'manual';

  /// Detected by the skills directory watcher (content changed on disk).
  static const String watch = 'watch';
}

/// A workspace skill's content was written through a gated path (install,
/// update, editor save) or changed on disk (watcher).
///
/// Consumed by the `skill_analysis` pipeline trigger (an antivirus analysis
/// run over the new bytes) and available to user-authored pipelines via the
/// trigger dispatcher. The scan verdict carried here is the one the writing
/// path's gate already produced (null when none ran), NOT a fresh analysis.
class SkillUpdated implements DomainEvent {
  /// Creates a [SkillUpdated].
  const SkillUpdated({
    required this.workspaceId,
    required this.slug,
    required this.origin,
    required this.computedHash,
    this.scanVerdict,
    required this.occurredAt,
  });

  /// Workspace that owns the skill.
  final String workspaceId;

  /// The skill slug (directory basename).
  final String slug;

  /// One of the [SkillUpdateOrigin] constants.
  final String origin;

  /// The content hash of the bytes that were written / observed.
  final String computedHash;

  /// The verdict the writing path's scan gate produced, when it ran one.
  final SkillScanVerdict? scanVerdict;

  @override
  final DateTime occurredAt;
}
