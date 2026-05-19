import 'package:cc_domain/features/skills/domain/entities/skill_source.dart';

/// Persistence contract for a workspace's registered skill sources.
///
/// Every method takes a **required** [String] workspaceId — it picks the
/// workspace's own database file, so a foreign workspace's source is simply
/// never found (isolation invariant).
abstract interface class SkillSourceRepository {
  /// The workspace's sources, newest first.
  Future<List<SkillSource>> list(String workspaceId);

  /// The source with [sourceId] in [workspaceId], or null.
  Future<SkillSource?> byId(String workspaceId, String sourceId);

  /// The source for [owner]/[repo] in [workspaceId], or null (dedupe probe).
  Future<SkillSource?> byOwnerRepo(
    String workspaceId,
    String owner,
    String repo,
  );

  /// Inserts a new source row and returns the persisted entity.
  Future<SkillSource> add(String workspaceId, SkillSource source);

  /// Persists mutable fields of [source] (description, default branch, stars,
  /// sync state, last error). The [SkillSource.id] and identity columns are
  /// immutable.
  Future<void> update(String workspaceId, SkillSource source);

  /// Deletes the source row. Installed skills stay installed — their lock
  /// pins are self-contained.
  Future<void> remove(String workspaceId, String sourceId);
}
