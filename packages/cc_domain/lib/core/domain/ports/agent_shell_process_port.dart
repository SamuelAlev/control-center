import 'package:cc_domain/core/domain/entities/agent_shell_process.dart';

/// Lists and stops the shell commands agents left running in a space.
///
/// Scoped to one workspace AND one space on every call: the host's process
/// table is global, so the scope is what keeps one conversation's commands
/// out of another's list — and out of reach of its stop button.
abstract interface class AgentShellProcessPort {
  /// The space's agent shell commands that are still running, oldest first.
  Future<List<AgentShellProcess>> list({
    required String workspaceId,
    required String spaceId,
  });

  /// Stops the command whose top shell is [pid] and everything under it.
  ///
  /// Only a pid [list] reports for the same workspace and space is stopped;
  /// any other pid is refused with `false`, never killed.
  Future<bool> kill({
    required String workspaceId,
    required String spaceId,
    required int pid,
  });
}
