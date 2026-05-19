import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';

/// Enforces PRD 23 §6 quarantine on already-installed skills: when a skill's
/// authoritative (lock-recorded) verdict is `quarantine`, its symlink is removed
/// from every agent's prompt-visible `.agents/skills` dir so no agent loads it
/// until the operator resolves the finding.
///
/// The structural half of the enforcement lives one layer down: the link FILTER
/// wired into `WorkspaceFilesystemService.syncAgentSkillLinks` refuses to
/// (re)create a quarantined skill's link, so this guard only has to re-run the
/// sync for agents that had the skill attached — the filter then strips the
/// stale link. Agents' `Agent.skills` attachments are deliberately LEFT
/// UNTOUCHED: the operator's intent is preserved and the skill re-links
/// automatically on the next sync once its verdict clears.
class SkillQuarantineGuard {
  /// Creates a [SkillQuarantineGuard].
  SkillQuarantineGuard({
    required AgentRepository agents,
    required SkillBundlePort bundles,
    required WorkspaceFilesystemPort filesystem,
  }) : _agents = agents,
       _bundles = bundles,
       _filesystem = filesystem;

  final AgentRepository _agents;
  final SkillBundlePort _bundles;
  final WorkspaceFilesystemPort _filesystem;

  /// Re-syncs every agent's skill links in [workspaceId] so quarantined skills
  /// are detached. Returns the names of agents that HAD a quarantined skill
  /// attached (the caller surfaces this — "detached from N agents"). When
  /// [slug] is given, only that skill is considered. Best-effort per agent: one
  /// agent's sync failure never aborts the pass.
  Future<List<String>> detachQuarantined(
    String workspaceId, {
    String? slug,
  }) async {
    final lock = await _bundles.readLock(workspaceId);
    final quarantined = lock.skills.values
        .where((e) => e.scanVerdict == SkillScanVerdict.quarantine)
        .map((e) => e.slug)
        .toSet();
    if (slug != null) {
      if (!quarantined.contains(slug)) {
        return const [];
      }
      quarantined
        ..clear()
        ..add(slug);
    }
    if (quarantined.isEmpty) {
      return const [];
    }

    final agents = await _agents.watchByWorkspace(workspaceId).first;
    final detached = <String>[];
    for (final agent in agents) {
      final attached = agent.skills.toList();
      if (!attached.any(quarantined.contains)) {
        continue;
      }
      try {
        // The full attachment list goes through the sync — the link filter
        // drops (and deletes the link of) every quarantined slug in it.
        await _filesystem.syncAgentSkillLinks(
          workspaceId,
          agent.name,
          attached,
        );
        detached.add(agent.name);
      } on Object {
        // Best-effort: report the agents we did detach, swallow the rest.
      }
    }
    return detached;
  }

  /// Whether [slug] is quarantined in [workspaceId] per the lock — the verdict
  /// source the runtime wires into the filesystem link filter.
  Future<bool> isQuarantined(String workspaceId, String slug) async {
    final lock = await _bundles.readLock(workspaceId);
    return lock.skills[slug]?.scanVerdict == SkillScanVerdict.quarantine;
  }
}
