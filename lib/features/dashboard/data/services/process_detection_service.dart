import 'dart:io';

import 'package:control_center/core/domain/ports/process_detection_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/features/dashboard/domain/entities/dashboard_status.dart';

/// Detects running agent processes by querying the agent run log database.
class ProcessDetectionService implements ProcessDetectionPort {
  /// Creates a [ProcessDetectionService] backed by the given repositories.
  ProcessDetectionService({
    required AgentRunLogRepository runLogRepo,
    required AgentRepository agentRepo,
    required WorkspaceRepository workspaceRepo,
  })  : _runLogRepo = runLogRepo,
        _agentRepo = agentRepo,
        _workspaceRepo = workspaceRepo;

  final AgentRunLogRepository _runLogRepo;
  final AgentRepository _agentRepo;
  final WorkspaceRepository _workspaceRepo;

  @override
  Future<List<ActiveProcessInfo>> detect() async {
    try {
      final allLogs = await _runLogRepo.watchAll().first;
      final runningLogs =
          allLogs.where((l) => l.isRunning && l.pid != null).toList();

      if (runningLogs.isEmpty) {
        return [];
      }

      final agents = await _agentRepo.watchAll().first;
      final workspaces = await _workspaceRepo.watchAll().first;

      final agentMap = {for (final a in agents) a.id: a};
      final workspaceMap = {for (final w in workspaces) w.id: w};

      final processes = <ActiveProcessInfo>[];
      for (final log in runningLogs) {
        if (!await _isPidAlive(log.pid!)) {
          continue;
        }

        final agent = agentMap[log.agentId];
        final agentName = agent?.name ?? 'Unknown';

        String workspaceName = '';
        if (log.workspaceId != null) {
          workspaceName = workspaceMap[log.workspaceId]?.name ?? '';
        }

        processes.add(
          ActiveProcessInfo(
            agentName: agentName,
            workspaceName: workspaceName,
            pid: log.pid!,
            command: agentName,
            startTime: log.startedAt,
          ),
        );
      }

      return processes;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> killProcess(int pid) async {
    try {
      Process.killPid(pid);
    } catch (_) {}
  }

  Future<bool> _isPidAlive(int pid) async {
    try {
      final result = await Process.run('kill', ['-0', pid.toString()]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
