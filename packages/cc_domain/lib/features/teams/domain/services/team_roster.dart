import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';

/// Builds the leader-facing **team roster**: a Markdown block listing each
/// non-leader member with a paste-ready mention link and its assigned skills,
/// so the leader delegates by capability rather than guessing names.
///
/// Each member renders as `[@Name](mention://agent/<uuid>)`. The leader can
/// paste that literal token into a reply to summon the member; the dispatch
/// mention path resolves the `mention://agent/<uuid>` URL back to the agent.
///
/// Skills are surfaced inline (`skills: code-review, testing`) so the routing
/// decision is capability-driven. Members whose agent is missing from
/// [agentsById] are skipped (a stale membership row).
String buildTeamRoster({
  required Team team,
  required List<TeamMember> members,
  required Map<String, Agent> agentsById,
}) {
  final buf = StringBuffer();
  buf.writeln('## ${team.name} — roster');
  buf.writeln();

  final leaderId = team.leaderId;
  final delegatable =
      members
          .where((m) => m.agentId != leaderId)
          .map((m) => agentsById[m.agentId])
          .whereType<Agent>()
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  if (delegatable.isEmpty) {
    buf.writeln('_No delegatable members. Handle the request yourself._');
    return buf.toString().trimRight();
  }

  for (final agent in delegatable) {
    final mention = '[@${agent.name}](mention://agent/${agent.id})';
    final role = agent.role?.label;
    final skills = agent.skills.isNotEmpty
        ? agent.skills.join(', ')
        : '(no skills assigned)';
    final roleSuffix = role != null ? ' · $role' : '';
    buf.writeln('- $mention$roleSuffix');
    buf.writeln('  - skills: $skills');
    if (agent.title.isNotEmpty) {
      buf.writeln('  - title: ${agent.title}');
    }
  }

  return buf.toString().trimRight();
}
