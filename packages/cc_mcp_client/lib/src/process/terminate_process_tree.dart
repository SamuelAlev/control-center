import 'dart:async';
import 'dart:io';

/// Stops [process] and, best-effort, its descendants: reap the child tree, SIGTERM, wait
/// [grace], then SIGKILL.
///
/// This ladder is the house pattern for every child this repo spawns, and it exists because
/// the two shortcuts both fail in practice:
/// Never throws: every step is best-effort, because "the process is already gone" is the
/// ordinary case on a teardown path.
Future<void> terminateProcessTree(
  Process process, {
  Duration grace = const Duration(seconds: 3),
}) async {
  if (!Platform.isWindows) {
    try {
      await Process.run('pkill', ['-TERM', '-P', '${process.pid}']);
    } on Object {
      // pkill unavailable (a minimal container) — fall through to the direct
      // kill; the direct child still dies, we just cannot promise the tree.
    }
  }
  try {
    process.kill();
  } on Object {
    return; // Already dead: nothing left to escalate to.
  }
  try {
    await process.exitCode.timeout(grace);
  } on TimeoutException {
    try {
      process.kill(ProcessSignal.sigkill);
      // A SIGKILLed process cannot ignore the signal, but reaping it still
      // needs the exit code to be awaited somewhere — bound that too so a
      // wedged kernel state cannot hang a shutdown path forever.
      await process.exitCode.timeout(const Duration(seconds: 2));
    } on Object {
      // Best effort.
    }
  } on Object {
    // exitCode already completed with an error — nothing to do.
  }
}
