/// Which agent's context window `/context` should open, decided as a pure
/// function of the space's roster, who is currently at work and what the
/// operator typed.
///
/// Separated from the command handler because this is the only part with a
/// judgement in it — everything else is two reads and a tab open. A pure
/// function is also the only shape this decision can be tested in without a
/// widget tree, a toast overlay and its dismiss timer.
library;

/// The outcome of resolving `/context [agent]` against a space.
sealed class ContextCommandTarget {
  const ContextCommandTarget();
}

/// Exactly one agent answers: open its explorer.
class ContextTargetResolved extends ContextCommandTarget {
  /// Creates a [ContextTargetResolved] for [agentId].
  const ContextTargetResolved(this.agentId);

  /// The agent whose context window to open.
  final String agentId;
}

/// The space has no agent, so there is no context window to open.
class ContextTargetNoAgent extends ContextCommandTarget {
  /// Creates a [ContextTargetNoAgent].
  const ContextTargetNoAgent();
}

/// The operator named an agent that is not in this space.
///
/// Carries [choices] (sorted, for a stable message) alongside what was [typed],
/// so the caller can answer with what is actually here.
class ContextTargetUnknownAgent extends ContextCommandTarget {
  /// Creates a [ContextTargetUnknownAgent].
  const ContextTargetUnknownAgent({
    required this.choices,
    required this.typed,
  });

  /// The names of the agents in this space, sorted.
  final List<String> choices;

  /// What the operator typed.
  final String typed;
}

/// Resolves `/context [agent]` for a space.
///
/// [agentIdsInSpace] are the agent participants; [namesById] is the workspace
/// roster (only entries in the space are consulted). [args] is the raw command
/// tail — a leading `@` is tolerated, because the operator is naming an agent
/// and that is how they are named everywhere else in the composer.
/// [currentAgentId] is the agent the space is currently ABOUT — the one the
/// header's context meter is reading (`spaceMeteredAgentIdProvider`).
///
/// A single-agent space never consults [args] at all: the answer is not in
/// doubt, and refusing a stray word would make the common case the fussy one.
///
/// A bare `/context` past one agent used to refuse and ask which. It no longer
/// does: it opens [currentAgentId], the same window the header meters, so the
/// command and the counter can never disagree about what "the context" means
/// here. A stale or absent hint falls back to the first participant rather than
/// dead-ending on a prompt — the explorer names the agent it opened, and
/// `/context <name>` is one keystroke away.
///
/// A TYPED name is still matched EXACTLY (case-insensitive) and never fuzzily:
/// two agents in a space hold two different context windows, so a near-miss
/// that opened the other one would be a plausible-looking answer to a question
/// nobody asked.
ContextCommandTarget resolveContextTarget({
  required List<String> agentIdsInSpace,
  required Map<String, String> namesById,
  required String args,
  String? currentAgentId,
}) {
  if (agentIdsInSpace.isEmpty) {
    return const ContextTargetNoAgent();
  }
  if (agentIdsInSpace.length == 1) {
    return ContextTargetResolved(agentIdsInSpace.first);
  }

  final typed = args.trim().replaceFirst(RegExp('^@'), '');
  if (typed.isEmpty) {
    return ContextTargetResolved(
      currentAgentId != null && agentIdsInSpace.contains(currentAgentId)
          ? currentAgentId
          : agentIdsInSpace.first,
    );
  }

  final idByName = <String, String>{
    for (final id in agentIdsInSpace)
      if (namesById[id] case final String name) name.toLowerCase(): id,
  };
  final match = idByName[typed.toLowerCase()];
  if (match != null) {
    return ContextTargetResolved(match);
  }
  return ContextTargetUnknownAgent(
    choices: idByName.keys.toList()..sort(),
    typed: typed,
  );
}
