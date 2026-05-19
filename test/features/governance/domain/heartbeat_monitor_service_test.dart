import 'package:cc_domain/features/governance/domain/entities/agent_runtime_state.dart';
import 'package:cc_domain/features/governance/domain/repositories/agent_runtime_state_repository.dart';
import 'package:cc_domain/features/governance/domain/services/heartbeat_monitor_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/heartbeat_status.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRuntimeStateRepo implements AgentRuntimeStateRepository {
  final Map<String, AgentRuntimeState> states = {};

  String _key(String ws, String agent) => '$ws/$agent';

  @override
  Future<void> upsert(AgentRuntimeState state) async =>
      states[_key(state.workspaceId, state.agentId)] = state;

  @override
  Future<AgentRuntimeState?> getForAgent(
    String workspaceId,
    String agentId,
  ) async => states[_key(workspaceId, agentId)];

  @override
  Future<List<AgentRuntimeState>> listByWorkspace(String workspaceId) async =>
      states.values.where((s) => s.workspaceId == workspaceId).toList();

  @override
  Stream<List<AgentRuntimeState>> watchByWorkspace(String workspaceId) =>
      Stream.value(
        states.values.where((s) => s.workspaceId == workspaceId).toList(),
      );

  @override
  Future<List<AgentRuntimeState>> listAll() async => states.values.toList();

  @override
  Future<void> delete(String workspaceId, String agentId) async =>
      states.remove(_key(workspaceId, agentId));
}

void main() {
  late _FakeRuntimeStateRepo repo;
  late HeartbeatMonitorService svc;
  final now = DateTime.utc(2026, 1, 1, 12, 0, 0);

  setUp(() {
    repo = _FakeRuntimeStateRepo();
    svc = HeartbeatMonitorService(repository: repo);
  });

  test('recordHeartbeat upserts liveness + last-seen', () async {
    final state = await svc.recordHeartbeat(
      workspaceId: 'ws1',
      agentId: 'a1',
      status: HeartbeatStatus.alive,
      runId: 'run1',
      now: now,
    );
    expect(state.reportedStatus, HeartbeatStatus.alive);
    expect(state.lastHeartbeatAt, now);
    expect(state.currentRunId, 'run1');
  });

  test('an agent reporting stuck is surfaced as needing attention', () async {
    await svc.recordHeartbeat(
      workspaceId: 'ws1',
      agentId: 'a1',
      status: HeartbeatStatus.stuck,
      now: now,
    );
    final stuck = await svc.stuckAgents('ws1', now: now);
    expect(stuck.map((s) => s.agentId), contains('a1'));
  });

  test('an alive agent gone quiet for >5 min is surfaced', () async {
    await svc.recordHeartbeat(
      workspaceId: 'ws1',
      agentId: 'a1',
      status: HeartbeatStatus.alive,
      now: now.subtract(const Duration(hours: 1)),
    );
    final stuck = await svc.stuckAgents('ws1', now: now);
    expect(stuck.map((s) => s.agentId), contains('a1'));
  });

  test('reconcileStale flips silently-lost agents to offline', () async {
    await svc.recordHeartbeat(
      workspaceId: 'ws1',
      agentId: 'a1',
      status: HeartbeatStatus.alive,
      now: now.subtract(const Duration(hours: 2)),
    );
    final count = await svc.reconcileStale('ws1', now: now);
    expect(count, 1);
    final state = await repo.getForAgent('ws1', 'a1');
    expect(state!.reportedStatus, HeartbeatStatus.offline);
  });
}
