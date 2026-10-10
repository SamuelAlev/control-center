/// Which runner launched an [AgentShellProcess].
enum AgentShellOrigin {
  /// The built-in harness loop's `bash` tool, spawned by the server itself.
  harness,

  /// An external agent CLI (Claude Code, Codex, …) — a shell found under the
  /// run's process tree.
  cli,
}

/// A shell command an agent started that is still running on the server host:
/// a backgrounded task, or a foreground one that has outlived a quick call.
///
/// Surfaced so a person can see what an agent left running in a conversation
/// and stop a stuck one. [pid] is the command's top shell; stopping it stops
/// the whole tree under it.
class AgentShellProcess {
  /// Creates an [AgentShellProcess].
  AgentShellProcess({
    required this.pid,
    required this.workspaceId,
    required this.spaceId,
    required this.agentId,
    required this.command,
    required this.startedAt,
    required this.origin,
    this.runId,
  }) {
    if (pid <= 0) {
      throw ArgumentError.value(pid, 'pid', 'must be positive');
    }
    if (workspaceId.isEmpty || spaceId.isEmpty) {
      throw ArgumentError('AgentShellProcess needs a workspace and a space');
    }
  }

  /// OS process id of the command's top shell.
  final int pid;

  /// Workspace the launching run belongs to.
  final String workspaceId;

  /// Space (conversation container) the launching run belongs to.
  final String spaceId;

  /// Agent whose run launched the command ('' when unknown).
  final String agentId;

  /// The run that launched the command, when known.
  final String? runId;

  /// The command line as the agent wrote it, not the wrapper around it.
  final String command;

  /// When the command started.
  final DateTime startedAt;

  /// Which runner launched it.
  final AgentShellOrigin origin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentShellProcess &&
          pid == other.pid &&
          workspaceId == other.workspaceId &&
          spaceId == other.spaceId &&
          agentId == other.agentId &&
          runId == other.runId &&
          command == other.command &&
          startedAt == other.startedAt &&
          origin == other.origin;

  @override
  int get hashCode => Object.hash(
    pid,
    workspaceId,
    spaceId,
    agentId,
    runId,
    command,
    startedAt,
    origin,
  );
}
