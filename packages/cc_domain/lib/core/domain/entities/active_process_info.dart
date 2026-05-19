/// Information about a detected active agent process.
///
/// Shared kernel entity: produced by the dashboard's process-detection port
/// (in `core/domain/ports`) and consumed by both the dashboard and the agents
/// feature (process killing), so it lives in the shared kernel.
class ActiveProcessInfo {
  /// Creates a new [ActiveProcessInfo].
  const ActiveProcessInfo({
    required this.agentName,
    required this.workspaceName,
    required this.pid,
    required this.command,
    required this.startTime,
  });

  /// Display name of the agent.
  final String agentName;

  /// Name of the workspace the agent is running in.
  final String workspaceName;

  /// Process ID.
  final int pid;

  /// Raw command string.
  final String command;

  /// When the process was started.
  final DateTime startTime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveProcessInfo &&
          runtimeType == other.runtimeType &&
          agentName == other.agentName &&
          workspaceName == other.workspaceName &&
          pid == other.pid &&
          command == other.command &&
          startTime == other.startTime;

  @override
  int get hashCode =>
      Object.hash(agentName, workspaceName, pid, command, startTime);
}
