import 'package:cc_data/cc_data.dart' show RemoteAgentRunLogRepository;
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/features/agents/presentation/widgets/agent_logs_tab.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dispatch/presentation/long_work/long_work_harness.dart';

/// Records Stop and answers it with [refuse] when set.
class _FakeRunLogOps implements RemoteAgentRunLogRepository {
  final calls = <String>[];
  Object? refuse;

  @override
  Future<void> stop(String workspaceId, String runId) async {
    calls.add('stop:$workspaceId:$runId');
    if (refuse case final e?) {
      throw e;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A Stop the server answers not-found (the run ended, or its space is now
/// hidden from this viewer) means the run is gone: the list refreshes and
/// nothing is raised as a failure.
void main() {
  testWidgets('stop answered not found treats the run as gone', (tester) async {
    final ops = _FakeRunLogOps()
      ..refuse = RemoteRpcException(
        RpcErrorCodes.notFound,
        'No live agent run to stop',
      );
    var subscriptions = 0;
    final log = AgentRunLog(
      id: 'run-1',
      agentId: 'agent-1',
      workspaceId: kTestWorkspaceId,
      startedAt: t0,
      status: RunStatus.running,
      pid: 4242,
    );
    await pumpLongWork(
      tester,
      AgentLogsTab(agent: testAgents.first),
      overrides: [
        agentRunLogsProvider.overrideWith((ref, key) {
          subscriptions++;
          return Stream.value([log]);
        }),
        remoteAgentRunLogOpsProvider.overrideWithValue(ops),
      ],
      // A running row animates; pump frames instead of settling.
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 100));
    final l10n = AppLocalizations.of(tester.element(find.byType(AgentLogsTab)));
    expect(subscriptions, 1);
    await tester.tap(find.text(l10n.stop).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(ops.calls, ['stop:$kTestWorkspaceId:run-1']);
    expect(tester.takeException(), isNull);
    expect(subscriptions, 2);
  });
}
