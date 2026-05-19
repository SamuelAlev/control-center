import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_level.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_status.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises [DaoGoalRepository] end-to-end against an in-memory database.
/// Covers every repository method (watch, list, childrenOf, getById, upsert,
/// delete) through the domain [OrgGoal] entity and the goal mapper.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoGoalRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    repo = DaoGoalRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  OrgGoal goal({
    String id = 'g-1',
    String workspaceId = 'w-1',
    String title = 'Ship it',
    OrgGoalLevel level = OrgGoalLevel.company,
    String? parentGoalId,
    OrgGoalStatus status = OrgGoalStatus.active,
    int progress = 0,
  }) => OrgGoal(
    id: id,
    workspaceId: workspaceId,
    title: title,
    level: level,
    parentGoalId: parentGoalId,
    status: status,
    progress: progress,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('DaoGoalRepository upsert + read round-trip', () {
    test('getById returns null when absent', () async {
      expect(await repo.getById('w-1', 'missing'), isNull);
    });

    test('upsert then getById round-trips the goal', () async {
      await repo.upsert(
        goal(
          title: 'Mission',
          level: OrgGoalLevel.company,
          status: OrgGoalStatus.achieved,
          progress: 75,
        ),
      );
      final loaded = await repo.getById('w-1', 'g-1');
      expect(loaded, isNotNull);
      expect(loaded!.title, 'Mission');
      expect(loaded.level, OrgGoalLevel.company);
      expect(loaded.status, OrgGoalStatus.achieved);
      expect(loaded.progress, 75);
    });

    test('upsert replaces on conflict (same id PK)', () async {
      await repo.upsert(goal(title: 'first'));
      await repo.upsert(goal(title: 'second', progress: 99));
      final loaded = await repo.getById('w-1', 'g-1');
      expect(loaded?.title, 'second');
      expect(loaded?.progress, 99);
    });
  });

  group('DaoGoalRepository workspace isolation', () {
    test('listByWorkspace returns only the workspace rows', () async {
      await repo.upsert(goal(id: 'g-1', workspaceId: 'w-1'));
      await repo.upsert(goal(id: 'g-2', workspaceId: 'w-2'));
      final rows = await repo.listByWorkspace('w-1');
      expect(rows, hasLength(1));
      expect(rows.first.id, 'g-1');
    });

    test('watchByWorkspace emits only the workspace rows', () async {
      await repo.upsert(goal(id: 'g-1', workspaceId: 'w-1'));
      await repo.upsert(goal(id: 'g-2', workspaceId: 'w-2'));
      final rows = await repo.watchByWorkspace('w-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'g-1');
    });

    test('getById is workspace-scoped', () async {
      await repo.upsert(goal(id: 'g-1', workspaceId: 'w-1'));
      expect(await repo.getById('w-2', 'g-1'), isNull);
    });

    test('delete is workspace-scoped', () async {
      await repo.upsert(goal(id: 'g-1', workspaceId: 'w-1'));
      await repo.delete('w-2', 'g-1');
      expect(await repo.getById('w-1', 'g-1'), isNotNull);
      await repo.delete('w-1', 'g-1');
      expect(await repo.getById('w-1', 'g-1'), isNull);
    });
  });

  group('DaoGoalRepository hierarchy', () {
    test('childrenOf lists only direct children in the workspace', () async {
      await repo.upsert(goal(id: 'g-1', level: OrgGoalLevel.company));
      await repo.upsert(
        goal(id: 'g-2', level: OrgGoalLevel.team, parentGoalId: 'g-1'),
      );
      await repo.upsert(
        goal(id: 'g-3', level: OrgGoalLevel.team, parentGoalId: 'g-1'),
      );
      final children = await repo.childrenOf('w-1', 'g-1');
      expect(children.map((g) => g.id).toSet(), {'g-2', 'g-3'});
    });
  });
}
