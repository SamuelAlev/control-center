/// Lifecycle hooks for the built-in agent loop.
///
/// A host can observe (and gate) the loop without the loop knowing about the
/// host. All methods are optional via [NoopAgentLoopHooks]; a pre-tool hook may
/// deny a call by returning false.
library;

/// Observes and optionally gates agent-loop lifecycle events.
abstract interface class AgentLoopHooks {
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
