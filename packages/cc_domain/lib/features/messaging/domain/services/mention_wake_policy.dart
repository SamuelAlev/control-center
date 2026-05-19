import 'package:cc_domain/core/domain/entities/agent.dart';

/// One agent an `@mention` in another agent's finished turn should wake, and
/// the token that named it (kept for the refusal/audit line).
class MentionWakeTarget {
  /// Creates a [MentionWakeTarget].
  const MentionWakeTarget({required this.agent, required this.token});

  /// The resolved recipient.
  final Agent agent;

  /// The lowercase `@token` that resolved to [agent].
  final String token;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentionWakeTarget &&
          runtimeType == other.runtimeType &&
          agent.id == other.agent.id &&
          token == other.token;

  @override
  int get hashCode => Object.hash(agent.id, token);
}

/// Turns the mention tokens in an agent's own turn into the agents to wake.
///
/// Pure and deterministic — the impure half (adding a participant, dispatching)
/// lives in the messaging service. Resolution is EXACT, matching the rule
/// `send_to_agent`/`ask_agent` already follow: an unknown name and an ambiguous
/// one both resolve to nothing rather than to a best guess. That matters more
/// here than on the tool path, because a tool can return "did you mean…?" to
/// the caller and a finished turn cannot — a wrong guess would simply wake the
/// wrong agent with nobody watching.
///
/// The human composer path (`MessagingService.sendAndDispatch`) deliberately
/// keeps its looser prefix match: a person typing `@arch` is present, sees who
/// answered and can correct it in the next line.
class MentionWakePolicy {
  /// Creates a [MentionWakePolicy].
  const MentionWakePolicy({this.maxWakesPerTurn = 3});

  /// How many agents one turn may wake. A ceiling, not a budget: an agent that
  /// names six teammates in a summary is listing them, not summoning them.
  final int maxWakesPerTurn;

  /// Resolves [tokens] against [candidates] (the workspace's agents), dropping
  /// the unresolvable, the ambiguous, the self-mention and the duplicates, and
  /// stopping at [maxWakesPerTurn].
  List<MentionWakeTarget> resolveTargets({
    required List<String> tokens,
    required List<Agent> candidates,
    required String selfAgentId,
  }) {
    final targets = <MentionWakeTarget>[];
    final claimed = <String>{};
    for (final raw in tokens) {
      if (targets.length >= maxWakesPerTurn) {
        break;
      }
      final token = raw.toLowerCase();
      final matches = candidates
          .where((a) => a.name.toLowerCase() == token)
          .toList();
      // Zero matches: prose, not a mention. Two or more: ambiguous, and there
      // is no one to ask which was meant.
      if (matches.length != 1) {
        continue;
      }
      final agent = matches.single;
      // Mentioning yourself does nothing — the prompt says so, and a turn that
      // woke its own author would re-enter immediately.
      if (agent.id == selfAgentId) {
        continue;
      }
      if (!claimed.add(agent.id)) {
        continue;
      }
      targets.add(MentionWakeTarget(agent: agent, token: token));
    }
    return List.unmodifiable(targets);
  }
}
