import 'package:cc_domain/core/domain/entities/agent.dart';

/// The result of resolving a mention token to an [Agent].
class ResolvedMention {
  /// Creates a [ResolvedMention] with the resolved [agent] and how it
  /// was resolved.
  const ResolvedMention({
    required this.agent,
    required this.resolvedVia,
  });

  /// Resolved agent instance.
  final Agent agent;
  /// How the mention was resolved (e.g. 'name').
  final String resolvedVia;
}

/// Resolves mention tokens to [Agent] instances by name.

class MentionResolver {
  /// Creates a [MentionResolver].
  const MentionResolver();

  /// Resolves [token] to an [Agent] by case-insensitive name match.
  ///
  /// Returns `null` if zero or multiple agents match.
  ResolvedMention? resolve(String token, List<Agent> agents) {
    final lower = token.toLowerCase();

    final byName = agents.where(
      (a) => a.name.toLowerCase() == lower,
    );
    if (byName.length == 1) {
      return ResolvedMention(agent: byName.first, resolvedVia: 'name');
    }

    return null;
  }
}
