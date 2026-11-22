import 'package:cc_host/cc_host.dart' show CcHostLog;

/// One step of boot recovery: its `name` for the log, and the work.
typedef BootRecoveryStep = ({String name, Future<void> Function() run});

/// Recovers the runs a stopped server left behind, in the one safe order.
///
/// [reapOrphans] (the orphan-run reaper) runs to completion first. Every step
/// of [afterReap] (the pipeline resume, the goal reconcile, the stranded
/// ticket sweep) starts only after it, together: those steps dispatch runs of
/// this process's own, and a reaper still sweeping beside them could end one
/// it took for a leftover. A step's failure is logged and stops no other
/// step.
Future<void> recoverRunsAtBoot({
  required BootRecoveryStep reapOrphans,
  required List<BootRecoveryStep> afterReap,
}) async {
  await _guarded(reapOrphans);
  await Future.wait([for (final step in afterReap) _guarded(step)]);
}

Future<void> _guarded(BootRecoveryStep step) async {
  try {
    await step.run();
  } on Object catch (e, st) {
    CcHostLog.error('cc_server: ${step.name} failed: $e', e, st);
  }
}
