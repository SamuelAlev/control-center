import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';

/// The refusal kind of a checker name or id that names no agent of the
/// workspace.
const String goalCheckerUnknownKind = 'goal_checker_unknown';

/// The refusal kind of a checker name that several agents of the workspace
/// carry.
const String goalCheckerAmbiguousKind = 'goal_checker_ambiguous';

/// The refusal kind of a checker that is the goal's own agent: the default
/// reviewer already is, so naming it is a mistake, not a choice.
const String goalCheckerIsGoalAgentKind = 'goal_checker_is_goal_agent';

/// How many candidate names a refusal lists at most.
const int goalCheckerMaxCandidates = 20;

/// Picks the agent a person named as a goal's checker (`/goal --checker`,
/// `agentGoalRuns.setChecker`) among [agents], the agents of the goal's
/// workspace, and returns it.
///
/// [reference] matches an agent's id exactly, or else its name ignoring
/// case and surrounding spaces. Throws [ValidationException] whose code is
/// [goalCheckerUnknownKind] (no agent; the message lists the candidates),
/// [goalCheckerAmbiguousKind] (several agents carry the name; it lists them
/// with their ids) or [goalCheckerIsGoalAgentKind] (the goal's own agent,
/// [goalAgentId]).
Agent chooseGoalChecker(
  String reference, {
  required List<Agent> agents,
  required String goalAgentId,
}) {
  final wanted = reference.trim();
  final byId = agents.where((agent) => agent.id == wanted).toList();
  final matches = byId.isNotEmpty
      ? byId
      : [
          for (final agent in agents)
            if (agent.name.trim().toLowerCase() == wanted.toLowerCase()) agent,
        ];
  if (matches.length > 1) {
    final listed = [for (final agent in matches) '${agent.name} (${agent.id})']
      ..sort();
    throw ValidationException(
      'Several agents are called "$wanted": ${listed.join(', ')}. Name the '
      'checker by its id.',
      code: goalCheckerAmbiguousKind,
    );
  }
  if (matches.isEmpty) {
    final names = [
      for (final agent in agents)
        if (agent.id != goalAgentId) agent.name,
    ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final shown = names.take(goalCheckerMaxCandidates).join(', ');
    final more = names.length > goalCheckerMaxCandidates
        ? ' (and ${names.length - goalCheckerMaxCandidates} more)'
        : '';
    throw ValidationException(
      names.isEmpty
          ? 'No agent of this workspace is called "$wanted", and there is no '
                'other agent to check this goal.'
          : 'No agent of this workspace is called "$wanted". The checker can '
                'be: $shown$more.',
      code: goalCheckerUnknownKind,
    );
  }
  final chosen = matches.single;
  if (chosen.id == goalAgentId) {
    throw ValidationException(
      '${chosen.name} is the agent pursuing this goal; it already reviews its '
      'own work when no checker is set. Name another agent.',
      code: goalCheckerIsGoalAgentKind,
    );
  }
  return chosen;
}
