/// The role an agent played in a persisted run, for cost/usage attribution.
///
/// Mirrors the runtime `AgentKind` (main / sub / advisor) from the dispatch
/// registry, but lives in `core/domain` so it can be persisted on an
/// `AgentRunLog` without `core` importing the `features/dispatch` layer. The
/// dispatch service maps `AgentKind` → [AgentRunRole] by name when it writes the
/// run log.
///
/// * [main] — a top-level, user-facing driving agent run.
/// * [sub] — a subagent spawned by another agent (its cost rolls up to the
///   parent run via `AgentRunLog.childCostCents`).
/// * [advisor] — a passive shadow reviewer: tracked for usage/observability but
///   never a peer.
enum AgentRunRole {
  /// A top-level driving agent run.
  main,

  /// A subagent run spawned by another agent.
  sub,

  /// A passive shadow-reviewer run — observability only.
  advisor;

  /// Parses [value] (an `AgentKind`/`AgentRunRole` `.name`) into a role,
  /// defaulting to [main] for null/unknown values so legacy run logs (written
  /// before role attribution existed) attribute to the main agent.
  static AgentRunRole tryParse(String? value) {
    if (value == null) {
      return AgentRunRole.main;
    }
    return AgentRunRole.values
            .where((r) => r.name == value.toLowerCase())
            .firstOrNull ??
        AgentRunRole.main;
  }
}
