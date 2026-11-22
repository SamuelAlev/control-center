import 'package:cc_domain/core/domain/entities/message.dart';

/// The metadata key that marks a conversation row as the server's "Still in
/// flight" block for one agent (plan section 12, D24). Its value is the
/// agent's id.
///
/// The conversation lane writes one such system row after a compaction (the
/// conversation compactor's summary, or a Claude Code session's own
/// compaction). A later block supersedes the earlier one: the earlier row is
/// marked compacted, so only the newest block of an agent is live, and the
/// prompt builder hands that one to the agent's next turn.
const String stillInFlightRowKey = 'stillInFlightFor';

/// The agent whose "Still in flight" block [message] is, or null when it is
/// not such a block.
String? stillInFlightRowAgent(Message message) {
  if (!message.isSystem) {
    return null;
  }
  final agent = message.metadata?[stillInFlightRowKey];
  return agent is String && agent.isNotEmpty ? agent : null;
}

/// The newest live "Still in flight" block of [agentId] in [messages] (in
/// conversation order), or null.
Message? newestStillInFlightRow(List<Message> messages, String agentId) {
  for (final m in messages.reversed) {
    if (!m.compacted && stillInFlightRowAgent(m) == agentId) {
      return m;
    }
  }
  return null;
}
