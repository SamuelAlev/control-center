import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_server_core/src/workspace_run_teardown.dart';
import 'package:test/test.dart';

void main() {
  AgentRunLog run(String id) => AgentRunLog(
    id: id,
    workspaceId: 'ws-1',
    agentId: 'agent-1',
    status: RunStatus.running,
    startedAt: DateTime.utc(2026, 11, 12),
  );

  test('stops every run still in flight in the workspace', () async {
    final stopped = <String>[];
    await stopRunsOfWorkspace(
      'ws-1',
      runLogs: _RunLogs({
        'ws-1': [run('run-a'), run('run-b')],
        'ws-2': [run('run-other')],
      }),
      stopRun: (workspaceId, runId) async => stopped.add('$workspaceId/$runId'),
    );
    expect(stopped, ['ws-1/run-a', 'ws-1/run-b']);
  });

  test('a run that cannot be stopped does not keep the others', () async {
    final stopped = <String>[];
    await stopRunsOfWorkspace(
      'ws-1',
      runLogs: _RunLogs({
        'ws-1': [run('run-a'), run('run-b')],
      }),
      stopRun: (workspaceId, runId) async {
        if (runId == 'run-a') {
          throw StateError('the process does not answer');
        }
        stopped.add(runId);
      },
    );
    expect(stopped, ['run-b']);
  });

  test('a workspace whose runs cannot be listed is still deleted', () async {
    var asked = false;
    await stopRunsOfWorkspace(
      'ws-1',
      runLogs: _RunLogs(const {}, failing: true),
      stopRun: (workspaceId, runId) async => asked = true,
    );
    expect(asked, isFalse);
  });
}

class _RunLogs implements AgentRunLogRepository {
  _RunLogs(this._live, {this.failing = false});

  final Map<String, List<AgentRunLog>> _live;
  final bool failing;

  @override
  Stream<List<AgentRunLog>> watchNonTerminalForWorkspace(String workspaceId) =>
      failing
      ? Stream.error(StateError('the database is closed'))
      : Stream.value(_live[workspaceId] ?? const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
