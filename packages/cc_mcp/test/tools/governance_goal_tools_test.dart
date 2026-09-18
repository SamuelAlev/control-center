import 'dart:convert';

import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_domain/features/governance/domain/services/goal_progress_service.dart';
import 'package:cc_mcp/src/tools/governance_goal_tools.dart';
import 'package:test/test.dart';

void main() {
  late _FakeGoals goals;
  late CreateGoalTool tool;

  setUp(() {
    goals = _FakeGoals();
    tool = CreateGoalTool(service: GoalProgressService(repository: goals));
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'title': 'Ship Q3', 'level': 'company'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('creates a goal with title and level', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'title': 'Ship Q3',
      'level': 'company',
    });
    expect(result.isError, isFalse);
    expect(goals.store, hasLength(1));
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['title'], 'Ship Q3');
    expect(body['level'], 'company');
  });
}

class _FakeGoals implements GoalRepository {
  final Map<String, OrgGoal> store = {};

  @override
  Future<void> upsert(OrgGoal goal) async => store[goal.id] = goal;

  @override
  Future<OrgGoal?> getById(String workspaceId, String id) async {
    final goal = store[id];
    return goal?.workspaceId == workspaceId ? goal : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
