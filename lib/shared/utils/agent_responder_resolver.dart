import 'package:control_center/core/domain/entities/agent.dart';

/// Resolves which agent should respond to a message by default.
class AgentResponderResolver {
  AgentResponderResolver._();

  /// Returns the most appropriate agent to respond, given the current context.
  ///
  /// Prefers the agent that last sent a message in the channel; if none,
  /// picks the lead hint or the first top-level agent. Returns `null` when
  /// no agents are available.
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

