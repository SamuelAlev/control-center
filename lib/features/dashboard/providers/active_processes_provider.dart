import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/dashboard/domain/entities/dashboard_status.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active processes notifier.
class ActiveProcessesNotifier extends Notifier<List<ActiveProcessInfo>> {
  @override
  List<ActiveProcessInfo> build() {
    final timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    ref.onDispose(timer.cancel);
    _refresh();
    return [];
  }

  Future<void> _refresh() async {
    final service = ref.read(processDetectionServiceProvider);
    state = await service.detect();
  }

  Future<void> _markLogKilled(int pid) async {
    final runLogRepo = ref.read(agentRunLogRepositoryProvider);
    final allLogs = await runLogRepo.watchAll().first;
    for (final log in allLogs) {
      if (log.isRunning && log.pid == pid) {
        await runLogRepo.upsert(
          log.copyWith(
            status: RunStatus.error,
            completedAt: DateTime.now(),
            summary: 'Killed by user',
          ),
        );
      }
    }
  }

  /// Kills a single process by PID.
  Future<void> killProcess(int pid) async {
    try {
      Process.killPid(pid);
    } catch (_) {}
    await _markLogKilled(pid);
    await _refresh();
  }

  /// Kills all tracked active processes.
  Future<void> killAllProcesses() async {
    final pids = state.map((p) => p.pid).toSet();
    for (final pid in pids) {
      try {
        Process.killPid(pid);
      } catch (_) {}
    }
    final runLogRepo = ref.read(agentRunLogRepositoryProvider);
    final allLogs = await runLogRepo.watchAll().first;
    for (final log in allLogs) {
      if (log.isRunning && pids.contains(log.pid)) {
        await runLogRepo.upsert(
          log.copyWith(
            status: RunStatus.error,
            completedAt: DateTime.now(),
            summary: 'Killed by user',
          ),
        );
      }
    }
    await _refresh();
  }
}

/// Provider that watches active agent processes.
final activeProcessesProvider =
    NotifierProvider<ActiveProcessesNotifier, List<ActiveProcessInfo>>(
      ActiveProcessesNotifier.new,
    );

