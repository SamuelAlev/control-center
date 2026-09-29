import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';

/// Wire body of `skills.installedList`.
///
/// Content is read through [bundles], which already owns the skills directory.
/// The `fs.*` port is a separate surface (path disclosure and writes) and is
/// null on a demo, so reading `SKILL.md` through it dropped every seeded skill
/// from the settings page.
Future<Map<String, dynamic>> installedSkillsListPayload(
  SkillBundlePort bundles,
  String workspaceId,
) async {
  final statuses = await bundles.listInstalledStatus(workspaceId);
  return {
    'skills': [
      for (final s in statuses)
        {
          'slug': s.slug,
          'lock_state': s.lockState.wire,
          'origin': s.origin?.wire,
          'source': s.source,
          'trust_tier': s.trustTier?.wire,
          'computed_hash': s.computedHash,
          'content': await bundles.readSkillFile(workspaceId, s.slug),
          'scan': s.scan == null
              ? null
              : {
                  'verdict': s.scan!.verdict.wire,
                  'llm_reviewed': s.scan!.llmReviewed,
                  'rules_version': s.scan!.rulesVersion,
                  'rules_stale': s.rulesStale,
                  'findings': [for (final f in s.scan!.findings) f.toJson()],
                },
        },
    ],
  };
}
