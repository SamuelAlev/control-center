import 'package:control_center/core/domain/entities/agent.dart';

class AgentResponderResolver {
  AgentResponderResolver._();

  static Agent? resolveDefault({
    required List<Agent> agents,
    required bool isDm,
    String? lastAgentSenderId,
    Agent? leadHint,
  }) {
    if (agents.isEmpty) {
      return null;
    }

    if (isDm) {
      return agents.first;
    }

    if (lastAgentSenderId != null) {
      final last = agents.where((a) => a.id == lastAgentSenderId).firstOrNull;
      if (last != null) {
        return last;
      }
    }

    if (leadHint != null && agents.any((a) => a.id == leadHint.id)) {
      return leadHint;
    }

    return agents.where((a) => a.isTopLevel).firstOrNull ?? agents.first;
  }
}

