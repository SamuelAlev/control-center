import 'dart:io';

import 'package:cc_domain/core/domain/ports/process_control_port.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// OS-level process control (kill, liveness check) for agent processes.
///
/// Kills follow the same ladder as every other child this repo spawns —
/// reap the descendants, SIGTERM, grace, SIGKILL — because the two shortcuts
/// both fail in practice: a bare SIGTERM leaves a wrapper's grandchildren
/// (`npx` → `node`) running, and a child that ignores SIGTERM survives the
/// "kill" entirely while the caller believes it is gone.
///
/// This port only ever holds a PID (the process was spawned elsewhere, often
/// inside a sandbox), so liveness is polled rather than awaited on an exit
/// code.
class ProcessControlService implements ProcessControlPort {
  /// Creates a [ProcessControlService].
  const ProcessControlService({
    this.grace = const Duration(seconds: 3),
    this.pollInterval = const Duration(milliseconds: 100),
  });

  /// How long a SIGTERMed process has to exit before it is SIGKILLed.
  final Duration grace;

  /// How often liveness is polled while waiting out [grace].
  final Duration pollInterval;

  @override
  Future<void> kill(int pid) async {
    if (pid <= 0) {
      return;
    }
    if (!Platform.isWindows) {
      // Reap the direct child tree FIRST: a wrapper that exits on SIGTERM
      // would otherwise orphan its grandchildren.
      try {
        await Process.run('pkill', ['-TERM', '-P', '$pid']);
      } on Object {
        // pkill unavailable — the direct kill below still applies.
      }
    }
    if (!_signal(pid, ProcessSignal.sigterm)) {
      return; // Already gone.
    }
    final deadline = DateTime.now().add(grace);
    while (DateTime.now().isBefore(deadline)) {
      if (!isPidAlive(pid)) {
        return;
      }
      await Future<void>.delayed(pollInterval);
    }
    if (isPidAlive(pid)) {
      CcInfraLog.warning(
        'pid $pid ignored SIGTERM for ${grace.inSeconds}s — sending SIGKILL',
      );
      _signal(pid, ProcessSignal.sigkill);
    }
  }

  @override
  bool isPidAlive(int pid) {
    if (pid <= 0) {
      return false;
    }
    if (Platform.isWindows) {
      // No signals; ask the task list. A missing pid prints a header only.
      try {
        final result = Process.runSync('tasklist', [
          '/FI',
          'PID eq $pid',
          '/NH',
        ]);
        return result.exitCode == 0 &&
            '${result.stdout}'.contains(
              RegExp(
                r'\b'
                '$pid'
                r'\b',
              ),
            );
      } on Object {
        return false;
      }
    }
    // Existence first: `kill -0` succeeds iff the pid exists and we may
    // signal it.
    final bool exists;
    try {
      exists = Process.runSync('kill', ['-0', '$pid']).exitCode == 0;
    } on Object {
      return false;
    }
    if (!exists) {
      return false;
    }
    // `kill -0` also succeeds for a ZOMBIE — a process that has exited but has
    // not been reaped, so waiting on it never finishes and "alive" is the wrong
    // answer. Refine with the process state when we can read it.
    //
    // ADVISORY, deliberately: `ps` prints an EMPTY state field in restricted
    // environments (a sandboxed/entitlement-limited macOS shell does exactly
    // this), and treating "no state" as "not alive" made every live process
    // read as dead. Unreadable state ⇒ keep the `kill -0` answer.
    try {
      final result = Process.runSync('ps', ['-o', 'stat=', '-p', '$pid']);
      final state = '${result.stdout}'.trim();
      if (result.exitCode == 0 && state.isNotEmpty) {
        return !state.startsWith('Z');
      }
    } on Object {
      // `ps` unavailable — fall through to the existence answer.
    }
    return true;
  }

  /// Sends [signal] to [pid]; false when the process is already gone.
  bool _signal(int pid, ProcessSignal signal) {
    try {
      return Process.killPid(pid, signal);
    } on Object {
      return false;
    }
  }
}
