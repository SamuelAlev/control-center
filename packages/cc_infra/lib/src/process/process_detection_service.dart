import 'dart:io';

import 'package:cc_domain/core/domain/entities/active_process_info.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';

import 'package:cc_infra/src/process/child_process.dart';

/// Lists and stops the agent runs alive on this host, from the agent run log.
///
/// Server-only. Every answer is filtered by the caller's workspaces, and a stop
/// resolves the pid against a live running run first: a pid that is not one,
/// or whose workspace the caller may not stop, is never signalled.
class ProcessDetectionService {
  /// Creates a [ProcessDetectionService] backed by the given repositories.
  ProcessDetectionService({
    required this._runLogRepo,
    required this._agentRepo,
    required this._workspaceRepo,
  });

  final AgentRunLogRepository _runLogRepo;
  final AgentRepository _agentRepo;
  final WorkspaceRepository _workspaceRepo;

  /// The agent runs alive on this host in a workspace [visible] admits.
  Future<List<ActiveProcessInfo>> detect({
    required Future<bool> Function(String workspaceId) visible,
  }) async {
    try {
      final runs = <AgentRunLog>[
        for (final log in await _liveRuns())
          if (await visible(log.workspaceId!)) log,
      ];
      if (runs.isEmpty) {
        return [];
      }
      final agents = await _agentRepo.watchAll().first;
      final workspaces = await _workspaceRepo.watchAll().first;
      final agentMap = {for (final a in agents) a.id: a};
      final workspaceMap = {for (final w in workspaces) w.id: w};
      return [
        for (final log in runs)
          ActiveProcessInfo(
            agentName: agentMap[log.agentId]?.name ?? 'Unknown',
            workspaceName: workspaceMap[log.workspaceId]?.name ?? '',
            pid: log.pid!,
            command: agentMap[log.agentId]?.name ?? 'Unknown',
            startTime: log.startedAt,
          ),
      ];
    } catch (_) {
      return [];
    }
  }

  /// Signals the live agent run whose process is [pid] when [mayStop] admits
  /// its workspace. False, with nothing signalled, when [pid] is no live
  /// running agent run or its workspace is not admitted.
  Future<bool> stopRun(
    int pid, {
    required Future<bool> Function(String workspaceId) mayStop,
  }) async {
    for (final log in await _liveRuns()) {
      if (log.pid == pid) {
        if (!await mayStop(log.workspaceId!)) {
          return false;
        }
        try {
          return Process.killPid(pid);
        } catch (_) {
          return false;
        }
      }
    }
    return false;
  }

  /// Running runs with a recorded pid and workspace whose process is alive.
  Future<List<AgentRunLog>> _liveRuns() async {
    final unfinished = await _runLogRepo.nonTerminal();
    return [
      for (final log in unfinished)
        if (log.isRunning &&
            log.pid != null &&
            log.workspaceId != null &&
            await _isPidAlive(log.pid!))
          log,
    ];
  }

  Future<bool> _isPidAlive(int pid) async {
    try {
      final result = await ChildProcess.run('kill', ['-0', pid.toString()]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
