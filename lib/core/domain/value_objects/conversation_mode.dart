/// Conversation-scoped behavior mode.
///
/// A mode is a tuple of (sandbox filesystem allow-list, MCP tool allow-list,
/// system-prompt block) consulted by the agent dispatch pipeline. Stored as
/// a column on the channel row so the same agent can act in different modes
/// across different conversations.
///
/// * [chat]   — default. No extra constraints; agent dir + `/tmp` are
///   writable, all MCP tools available.
/// * [review] — read-only PR review. Sandbox denies all writes; MCP guard
///   restricts the agent to a curated allow-list of review/comms tools.
/// * [plan]   — write-a-plan-only mode (kilocode "Architect"). Sandbox
///   allows writes only inside `{agentDir}/plans/`; the agent is prompted
///   to emit timestamped plan files.
enum ConversationMode {
  /// Default conversation mode (no extra constraints).
  chat,

  /// Read-only PR review mode.
  review,

  /// Plan-authoring mode — writes only to `{agentDir}/plans/`.
  plan;

  /// Parses the database serialization. Unknown / null → [chat].
  static ConversationMode fromDbValue(String? raw) {
    for (final m in values) {
      if (m.name == raw) {
        return m;
      }
    }
    return chat;
  }

  /// Serializes for the `channels.mode` column.
  String toDbValue() => name;
}
