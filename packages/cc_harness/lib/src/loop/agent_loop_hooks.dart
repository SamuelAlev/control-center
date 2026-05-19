/// Lifecycle hooks for the built-in agent loop.
///
/// A host can observe (and gate) the loop without the loop knowing about the
/// host. All methods are optional via [NoopAgentLoopHooks]; a pre-tool hook may
/// deny a call by returning false.
library;

/// Observes and optionally gates agent-loop lifecycle events.
abstract interface class AgentLoopHooks {
  /// Whether this implementation actually observes or gates INDIVIDUAL tool
  /// calls ([preToolUse] / [postToolUse]).
  ///
  /// The loop batches consecutive read-only tools so they execute
  /// concurrently, but a per-tool veto or observation has to run in the
  /// model's original order — so batching is disabled whenever a hook
  /// intercepts tools. That trade is only worth paying for hooks that DO:
  /// gating on "a hooks object exists at all" made a session-start-only hook
  /// serialize every tool call in the run, which is a large, silent cost for
  /// a hook that could not observe the difference.
  ///
  /// Implementations that only handle lifecycle events return false.
  /// Anything unsure returns true — over-serializing is slow, but
  /// under-serializing lets a veto arrive after the call it meant to stop.
  bool get interceptsTools;

  /// Called once when the run starts.
  Future<void> onSessionStart();

  /// Called before a tool executes. Return false to DENY the call (the loop
  /// feeds an error result back to the model instead of running the tool).
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args);

  /// Called after a tool finishes, with the (possibly errored) result text.
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  });
}

/// A no-op [AgentLoopHooks] that allows everything.
class NoopAgentLoopHooks implements AgentLoopHooks {
  /// Creates a [NoopAgentLoopHooks].
  const NoopAgentLoopHooks();

  @override
  bool get interceptsTools => false;

  @override
  Future<void> onSessionStart() async {}

  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async =>
      true;

  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) async {}
}
