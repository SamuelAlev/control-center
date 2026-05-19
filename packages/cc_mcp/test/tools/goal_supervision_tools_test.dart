import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/ports/goal_supervision_port.dart';
import 'package:cc_mcp/src/tools/goal_supervision_tools.dart';
import 'package:test/test.dart';

class _FakeGoalSupervisionPort implements GoalSupervisionPort {
  AgentGoalRun? activeGoal;
  Object? completeError;

  int completeCalls = 0;
  String? completedWorkspaceId;
  String? completedAgentId;
  String? completedSummary;

  @override
  Future<AgentGoalRun?> activeGoalForAgent(
    String workspaceId,
    String agentId,
  ) async => activeGoal;

  @override
  Future<void> completeGoal(
    String workspaceId,
    String agentId, {
    required String summary,
  }) async {
    completeCalls++;
    final error = completeError;
    if (error != null) {
      throw error;
    }
    completedWorkspaceId = workspaceId;
    completedAgentId = agentId;
    completedSummary = summary;
  }
}

AgentGoalRun _goal() => AgentGoalRun(
  id: 'goal-1',
  workspaceId: 'ws-1',
  channelId: 'ch-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  userText: 'Ship the thing',
  kind: AgentGoalKind.goal,
  deadlineAt: DateTime(2026, 8),
  costCapCents: 5000,
  maxRuns: 100,
  createdAt: DateTime(2026, 7, 27),
  updatedAt: DateTime(2026, 7, 27),
);

void main() {
  group('CompleteGoalTool', () {
    test('schema declares workspace_id and summary required', () {
      final tool = CompleteGoalTool(
        supervisionPort: _FakeGoalSupervisionPort(),
      );
      expect(tool.name, 'complete_goal');
      final required = tool.inputSchema['required'] as List;
      expect(required, containsAll(['workspace_id', 'summary']));
      final properties = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(properties, contains('workspace_id'));
      expect(properties, contains('summary'));
    });

    test('missing workspace_id returns an error', () async {
      final port = _FakeGoalSupervisionPort();
      final tool = CompleteGoalTool(supervisionPort: port);
      final result = await tool.run({'agent_id': 'agent-1', 'summary': 'done'});
      expect(result.isError, isTrue);
      expect(
        result.content.single.text,
        'Missing or invalid argument: workspace_id',
      );
      expect(port.completeCalls, 0);
    });

    test('completes the agent\'s active goal via the port', () async {
      final port = _FakeGoalSupervisionPort()..activeGoal = _goal();
      final tool = CompleteGoalTool(supervisionPort: port);
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'agent-1',
        'summary': 'Shipped it.',
      });
      expect(result.isError, isFalse);
      expect(port.completeCalls, 1);
      expect(port.completedWorkspaceId, 'ws-1');
      expect(port.completedAgentId, 'agent-1');
      expect(port.completedSummary, 'Shipped it.');
      final payload =
          jsonDecode(result.content.single.text) as Map<String, dynamic>;
      expect(payload['status'], 'completed');
      expect(payload['goal_id'], 'goal-1');
      expect(payload['summary'], 'Shipped it.');
    });

    test('StateError from the port surfaces its message verbatim', () async {
      final port = _FakeGoalSupervisionPort()
        ..completeError = StateError('Agent agent-1 has no active goal.');
      final tool = CompleteGoalTool(supervisionPort: port);
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'agent-1',
        'summary': 'done',
      });
      expect(result.isError, isTrue);
      expect(result.content.single.text, 'Agent agent-1 has no active goal.');
    });
  });
}
