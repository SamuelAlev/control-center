import 'dart:convert';

import 'package:cc_domain/features/governance/domain/entities/agent_runtime_state.dart';
import 'package:cc_domain/features/governance/domain/repositories/agent_runtime_state_repository.dart';
import 'package:cc_domain/features/governance/domain/services/heartbeat_monitor_service.dart';
import 'package:cc_mcp/src/tools/governance_runtime_tools.dart';
import 'package:test/test.dart';

void main() {
  late _FakeRuntimeStates states;
  late AgentHeartbeatTool tool;

  setUp(() {
    states = _FakeRuntimeStates();
    tool = AgentHeartbeatTool(
      service: HeartbeatMonitorService(repository: states),
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'agent_id': 'agent-1'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('heartbeat records the agent', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'agent_id': 'agent-1',
      'status': 'alive',
    });
    expect(result.isError, isFalse);
    expect(states.store['agent-1'], isNotNull);
    expect(states.store['agent-1']!.agentId, 'agent-1');
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['agent_id'], 'agent-1');
    expect(body['reported_status'], 'alive');
  });
}

class _FakeRuntimeStates implements AgentRuntimeStateRepository {
  final Map<String, AgentRuntimeState> store = {};

  @override
  Future<AgentRuntimeState?> getForAgent(
    String workspaceId,
    String agentId,
  ) async {
    final state = store[agentId];
    return state?.workspaceId == workspaceId ? state : null;
  }

  @override
  Future<void> upsert(AgentRuntimeState state) async =>
      store[state.agentId] = state;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
