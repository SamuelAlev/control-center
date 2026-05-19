import 'package:control_center/core/domain/entities/agent_run_log.dart';

/// Classifies an [AgentRunLog] into a [RunLiveness] level based on run
/// status, output recency, and blocked indicator phrases.
class RunLivenessClassifier {
  /// Creates a [RunLivenessClassifier].
  const RunLivenessClassifier();

  /// Duration after last output at which a run is considered suspiciously quiet.
  static const outputSuspicionThreshold = Duration(hours: 1);
  /// Duration after last output at which a run is considered critically stalled.
  static const outputCriticalThreshold = Duration(hours: 4);

  static const _blockedIndicators = [
    'blocked',
    'waiting for',
    'awaiting',
    'stuck',
    'deadlock',
    'cannot proceed',
    'requires input',
    'pending approval',
    'on hold',
    'dependency unmet',
    'upstream blocked',
  ];

  /// Classifies [run] as alive, stalled, blocked, dead, failed,
  /// productive, or empty.
  RunLiveness classify(AgentRunLog run, {DateTime? lastOutputAt}) {
    final effectiveLastOutput = lastOutputAt ?? run.lastOutputAt;
    final now = DateTime.now();

    switch (run.status) {
      case RunStatus.running:
        return _classifyRunning(effectiveLastOutput, now);
      case RunStatus.completed:
        return _classifyCompleted(run);
      case RunStatus.error:
        return _classifyError(run);
      case RunStatus.pending:
        return RunLiveness.empty;
    }
  }

  RunLiveness _classifyRunning(DateTime? lastOutput, DateTime now) {
    if (lastOutput == null) {
      return RunLiveness.alive;
    }

    final sinceLastOutput = now.difference(lastOutput);

    if (sinceLastOutput > outputCriticalThreshold) {
      return RunLiveness.stalled;
    }
    if (sinceLastOutput > outputSuspicionThreshold) {
      return RunLiveness.stalled;
    }

    return RunLiveness.alive;
  }

  RunLiveness _classifyCompleted(AgentRunLog run) {
    if (_isBlocked(run)) {
      return RunLiveness.blocked;
    }

    if (run.summary == null || run.summary!.isEmpty) {
      return RunLiveness.empty;
    }

    return RunLiveness.productive;
  }

  RunLiveness _classifyError(AgentRunLog run) {
    if (_isBlocked(run)) {
      return RunLiveness.blocked;
    }

    if (run.errorFamily == RunErrorFamily.processLost) {
      return RunLiveness.dead;
    }

    return RunLiveness.failed;
  }

  bool _isBlocked(AgentRunLog run) {
    final summary = run.summary?.toLowerCase() ?? '';
    if (_blockedIndicators.any(summary.contains)) {
      return true;
    }

    if (run.errorFamily == RunErrorFamily.silentRun) {
      return true;
    }

    return false;
  }
}
