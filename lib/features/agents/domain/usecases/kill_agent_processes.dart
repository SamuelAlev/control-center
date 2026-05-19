import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/ports/process_detection_port.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';

/// Kill agent processes use case.
class KillAgentProcessesUseCase {
  /// Creates a new [KillAgentProcessesUseCase].
  const KillAgentProcessesUseCase({
    required AgentRunLogRepository runLogRepository,
    required ProcessDetectionPort processDetection,
  })  : _runLogRepository = runLogRepository,
        _processDetection = processDetection;

  final AgentRunLogRepository _runLogRepository;
  final ProcessDetectionPort _processDetection;

  /// Execute.
  Future<void> execute(Agent agent) async {
    final logs =
        await _runLogRepository.watchByAgent(agent.workspaceId, agent.id).first;
    final runningPids = <int>{};
    for (final log in logs) {
      if (log.isRunning && log.pid != null) {
        await _processDetection.killProcess(log.pid!);
        runningPids.add(log.pid!);
      }
    }

    final processes = await _processDetection.detect();
    for (final proc in processes) {
      if (!runningPids.contains(proc.pid) &&
          proc.command.contains(agent.name)) {
        await _processDetection.killProcess(proc.pid);
      }
    }
  }
}

