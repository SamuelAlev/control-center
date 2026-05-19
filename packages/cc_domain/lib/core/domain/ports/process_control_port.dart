/// Port for controlling OS processes.
///
/// Allows killing a process by pid and checking whether a pid is alive.
abstract interface class ProcessControlPort {
  /// Kills the process identified by [pid].
  Future<void> kill(int pid);

  /// Returns `true` if a process with [pid] is currently running.
  bool isPidAlive(int pid);
}
