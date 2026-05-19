/// Conversation-scoped behavior mode.
///
/// Stored as a column on the space row so the same agent can act in different
/// modes across different conversations.
///
/// The mode is only the *key*. What it guarantees — tool surface, required
/// output verb, denied effect classes, sandbox posture, prompt block — is
/// declared once in `ModeCapabilityProfile` and projected from there. This enum
/// deliberately carries no policy of its own: a `loopPolicy` getter used to
/// live here and it was one of five independent copies of the same fact.
///
/// * [chat]   — default. No extra constraints; agent dir + `/tmp` are writable, all MCP tools available.
/// * [review] — read-only PR review. Sandbox denies all writes; MCP guard restricts the agent to a curated allow-list of review/comms tools.
/// * [plan]   — read-only worktree. The agent must NOT write the worktree; the plan is delivered by `submit_plan` as a typed `PlanDocument`.
/// * [orchestrate] — autonomous-orchestration planning mode. Read/research + the single `propose_orchestration` verb; the orchestrator researches the ask and emits a structured plan for one upfront user approval. Sandbox is plan-equivalent (read-mostly); hiring/decomposition happen deterministically only after the user approves.
enum Mode {
  /// Default conversation mode (no extra constraints).
  chat,

  /// Read-only PR review mode.
  review,

  /// Plan-authoring mode — fully read-only worktree.
  plan,

  /// Autonomous-orchestration planning mode.
  orchestrate;

  /// Parses the database serialization. Unknown / null → [chat].
  static Mode fromDbValue(String? raw) {
    for (final m in values) {
      if (m.name == raw) {
        return m;
      }
    }
    return chat;
  }

  /// Serializes for the `spaces.mode` column.
  String toDbValue() => name;
}
