/// Lifecycle of a command's bounded captured output.
enum AgentShellOutputState { running, exited, unavailable }

/// A read-only, bounded snapshot of an agent command's output.
class AgentShellOutput {
  /// Creates an output snapshot.
  const AgentShellOutput({
    required this.output,
    required this.state,
    this.truncated = false,
  });

  /// Captured stdout and stderr, with secrets redacted before delivery.
  final String output;

  /// Whether the command is still running, finished, or cannot be captured.
  final AgentShellOutputState state;

  /// Whether older output was omitted to bound the snapshot.
  final bool truncated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentShellOutput &&
          output == other.output &&
          state == other.state &&
          truncated == other.truncated;

  @override
  int get hashCode => Object.hash(output, state, truncated);
}
