import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:control_center/features/dispatch/providers/agent_registry_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Agent agent(String id) => Agent(
    id: id,
    name: id,
    title: 'Agent $id',
    agentMdPath: '',
    workspaceId: 'ws-1',
    skills: AgentSkills(const []),
    createdAt: DateTime(2026, 1, 1),
  );

  AgentRunLog run({
    required String id,
    required String agentId,
    required DateTime startedAt,
    DateTime? completedAt,
  }) => AgentRunLog(
    id: id,
    agentId: agentId,
    startedAt: startedAt,
    completedAt: completedAt,
    status: completedAt == null ? RunStatus.running : RunStatus.completed,
  );

  test('an open run is running; a finished one is idle', () {
    final roster = mapAgentsToRoster(
      [agent('a'), agent('b')],
      [
        run(
          id: 'r1',
          agentId: 'a',
          startedAt: DateTime(2026, 1, 2),
        ),
        run(
          id: 'r2',
          agentId: 'b',
          startedAt: DateTime(2026, 1, 2),
          completedAt: DateTime(2026, 1, 3),
        ),
      ],
    );
    expect(roster.singleWhere((r) => r.id == 'a').status, AgentStatus.running);
    expect(roster.singleWhere((r) => r.id == 'b').status, AgentStatus.idle);
  });
}
