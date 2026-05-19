import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_domain/features/governance/domain/services/goal_progress_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_level.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_status.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGoalRepo implements GoalRepository {
  final Map<String, OrgGoal> goals = {};

  @override
  Future<void> upsert(OrgGoal goal) async => goals[goal.id] = goal;

  @override
  Future<OrgGoal?> getById(String workspaceId, String id) async {
    final g = goals[id];
    return (g != null && g.workspaceId == workspaceId) ? g : null;
  }

  @override
  Future<List<OrgGoal>> childrenOf(
    String workspaceId,
    String parentGoalId,
  ) async => goals.values
      .where(
        (g) => g.workspaceId == workspaceId && g.parentGoalId == parentGoalId,
      )
      .toList();

  @override
  Future<List<OrgGoal>> listByWorkspace(String workspaceId) async =>
      goals.values.where((g) => g.workspaceId == workspaceId).toList();

  @override
  Stream<List<OrgGoal>> watchByWorkspace(String workspaceId) =>
      Stream.value(listSync(workspaceId));

  List<OrgGoal> listSync(String workspaceId) =>
      goals.values.where((g) => g.workspaceId == workspaceId).toList();

  @override
  Future<void> delete(String workspaceId, String id) async => goals.remove(id);
}

void main() {
  late _FakeGoalRepo repo;
  late GoalProgressService svc;

  setUp(() {
    repo = _FakeGoalRepo();
    svc = GoalProgressService(repository: repo);
  });

  test('creating a goal under a missing parent throws', () async {
    expect(
      () => svc.createGoal(
        workspaceId: 'ws1',
        title: 'Task',
        level: OrgGoalLevel.task,
        parentGoalId: 'ghost',
      ),
      throwsA(anything),
    );
  });

  test(
    'parent progress aggregates as the rounded average of children',
    () async {
      final company = await svc.createGoal(
        workspaceId: 'ws1',
        title: 'Mission',
        level: OrgGoalLevel.company,
      );
      final a = await svc.createGoal(
        workspaceId: 'ws1',
        title: 'Task A',
        level: OrgGoalLevel.task,
        parentGoalId: company.id,
      );
      final b = await svc.createGoal(
        workspaceId: 'ws1',
        title: 'Task B',
        level: OrgGoalLevel.task,
        parentGoalId: company.id,
      );

      await svc.setProgress('ws1', a.id, 100);
      await svc.setProgress('ws1', b.id, 50);

      final parent = await repo.getById('ws1', company.id);
      expect(parent!.progress, 75); // (100 + 50) / 2
    },
  );

  test('a 100%-complete goal flips to achieved', () async {
    final g = await svc.createGoal(
      workspaceId: 'ws1',
      title: 'Task',
      level: OrgGoalLevel.task,
    );
    await svc.setProgress('ws1', g.id, 100);
    final updated = await repo.getById('ws1', g.id);
    expect(updated!.status, OrgGoalStatus.achieved);
  });

  test('marking a goal achieved sets progress to 100', () async {
    final g = await svc.createGoal(
      workspaceId: 'ws1',
      title: 'Task',
      level: OrgGoalLevel.task,
    );
    await svc.setStatus('ws1', g.id, OrgGoalStatus.achieved);
    final updated = await repo.getById('ws1', g.id);
    expect(updated!.progress, 100);
  });
}
