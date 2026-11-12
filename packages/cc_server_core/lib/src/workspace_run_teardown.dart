import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;

/// Stops every run still in flight in [workspaceId]. Call it before the
/// workspace's database is deleted.
///
/// A run that outlives its workspace keeps its model process alive and
/// spending while every write it makes is refused. Best-effort: a run that
/// cannot be stopped is logged and the deletion goes on, because a workspace
/// its owner asked to delete must not stay because of one stuck run.
Future<void> stopRunsOfWorkspace(
  String workspaceId, {
  required AgentRunLogRepository runLogs,
  required Future<void> Function(String workspaceId, String runId) stopRun,
}) async {
  final List<AgentRunLog> live;
  try {
    live = await runLogs.watchNonTerminalForWorkspace(workspaceId).first;
  } on Object catch (e) {
    CcHostLog.warning('runs of workspace $workspaceId not listed: $e');
    return;
  }
  for (final run in live) {
    try {
      await stopRun(workspaceId, run.id);
    } on Object catch (e) {
      CcHostLog.warning(
        'run ${run.id} of workspace $workspaceId not stopped: $e',
      );
    }
  }
}
