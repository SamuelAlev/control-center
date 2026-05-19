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
/// * [plan]   — read-only worktree (kilocode "Architect"). The agent must NOT
///   write the worktree; plan artifacts are delivered via MCP tools or the
///   conversation.
/// * [orchestrate] — autonomous-orchestration planning mode. Read/research +
///   the single `propose_orchestration` verb; the orchestrator researches the
///   ask and emits a structured plan for one upfront user approval. Sandbox is
///   plan-equivalent (read-mostly); hiring/decomposition happen deterministically
///   only after the user approves.
enum ConversationMode {
  /// Default conversation mode (no extra constraints).
  chat,

  /// Read-only PR review mode.
  review,

  /// Plan-authoring mode — fully read-only worktree.
  plan,

  /// Autonomous-orchestration planning mode.
  orchestrate;

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
