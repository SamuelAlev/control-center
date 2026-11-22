/// Where a dispatch session reaches the server's "Still in flight" state
/// (plan section 12, D24) without knowing the goal, wake, ask or store
/// repositories: the server sets both hooks once at boot.
class StillInFlightHooks {
  /// The server's lines of the block for a built-in harness run of an agent
  /// in a conversation (`Goal:`, `Wakes:`, `Asked:`, `Stored:`). `scripts`
  /// says the run has `repl`, so a refresh call is written as a script
  /// call. Null adds no lines.
  Future<List<String>> Function({
    required String workspaceId,
    required String agentId,
    required String conversationId,
    required bool scripts,
  })?
  lines;

  /// A Claude Code session of an agent compacted its own context (an
  /// automatic compaction, the idle compactor or `/compact` on resume): the
  /// server writes the block as the conversation's system row, which the
  /// agent's next turn reads. Null does nothing.
  Future<void> Function({
    required String workspaceId,
    required String spaceId,
    required String agentId,
    required String conversationId,
  })?
  claudeCompacted;
}
