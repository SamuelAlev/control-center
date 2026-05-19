import 'package:control_center/core/domain/entities/agent.dart';

class ResolvedMention {
  const ResolvedMention({
    required this.agent,
    required this.resolvedVia,
  });

  final Agent agent;
  final String resolvedVia;
}

class MentionResolver {
  const MentionResolver();

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
