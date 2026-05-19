/// The agent run a sidebar AGENTS row points at, plus enough shape for the host
/// to decide what "open" means.
///
/// A ROOT row is an agent group whose activity IS the conversation, so opening it
/// belongs in the chat pane. A SUB row is one ephemeral subagent run whose
/// activity has no other home — that is the run-activity tab.
///
/// Its own file so `ide_sidebar → general_panel → agents_section` stays acyclic.
typedef AgentRunTarget = ({
  /// The agent that executed the run. For an ephemeral subagent this is the
  /// PARENT's agent id (or the literal `subagent`), not an agent of its own.
  String agentId,

  /// The run being opened.
  String runId,

  /// The row's resolved label — the agent's display name for a root row, the
  /// task label for a subagent row. Shown on the tab before any data lands, and
  /// after a restore even if the run row is gone.
  String label,

  /// Whether this is a spawned subagent run rather than a top-level agent group.
  bool isSubAgent,
});
