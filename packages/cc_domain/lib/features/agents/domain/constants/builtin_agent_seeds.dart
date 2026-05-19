import 'package:cc_domain/features/workspaces/domain/constants/ceo_agent_skills.dart';
import 'package:cc_domain/features/workspaces/domain/constants/specialist_agent_seeds.dart';

/// What a built-in agent looked like the moment its workspace was created.
///
/// Every workspace is seeded with a CEO and four specialists. Those five are
/// the only agents whose "default" is a thing that exists — everything else was
/// hired by a person or by another agent, so there is nothing to reset it to.
/// This is what lets the registry offer "reset to default" honestly: the button
/// is absent for an agent nobody seeded, rather than present and quietly
/// meaningless.
///
/// It is assembled FROM the seeding constants rather than restating them, so a
/// reset cannot drift away from what creation actually writes.
class BuiltinAgentSeed {
  /// Creates a [BuiltinAgentSeed].
  const BuiltinAgentSeed({
    required this.slug,
    required this.title,
    required this.skillSlugs,
    required this.reportsToSlug,
    required this.agentMdContent,
  });

  /// The agent's name, which is also its directory slug (`ceo`, `qa`, …).
  final String slug;

  /// The seeded title (`Chief Executive Officer`, `Quality Assurance`, …).
  final String title;

  /// The skills seeding linked to the agent.
  final List<String> skillSlugs;

  /// The NAME of the agent this one reports to, or null for the root. A name
  /// rather than an id: ids are per-workspace, the seed is not.
  final String? reportsToSlug;

  /// The AGENTS.md the agent was created with, front-matter included.
  final String agentMdContent;

  /// The markdown body — everything after the YAML front-matter.
  ///
  /// This is what the registry stages into the persona field on a reset: the
  /// front matter is regenerated from the entity's own fields when the file is
  /// written, so restoring it verbatim would duplicate it.
  String get agentMdBody {
    final trimmed = agentMdContent.trim();
    if (!trimmed.startsWith('---')) {
      return trimmed;
    }
    final end = trimmed.indexOf('---', 3);
    return end == -1 ? trimmed : trimmed.substring(end + 3).trim();
  }
}

/// The five agents every workspace is created with, in org order.
final builtinAgentSeeds = <BuiltinAgentSeed>[
  const BuiltinAgentSeed(
    slug: 'ceo',
    title: ceoAgentTitle,
    skillSlugs: ceoSkillSlugs,
    reportsToSlug: null,
    agentMdContent: ceoAgentMdContent,
  ),
  for (final specialist in defaultSpecialistAgents)
    BuiltinAgentSeed(
      slug: specialist.slug,
      title: specialist.title,
      skillSlugs: specialist.skillSlugs,
      reportsToSlug: 'ceo',
      agentMdContent: specialist.agentMdContent,
    ),
];

/// The seed for the agent called [name], or null when no one seeded it.
///
/// Matched on the name because that is what seeding sets and what the agent's
/// on-disk directory is derived from; an id would not survive the workspace it
/// was minted in.
BuiltinAgentSeed? builtinAgentSeedFor(String name) {
  final slug = name.trim().toLowerCase();
  for (final seed in builtinAgentSeeds) {
    if (seed.slug == slug) {
      return seed;
    }
  }
  return null;
}
