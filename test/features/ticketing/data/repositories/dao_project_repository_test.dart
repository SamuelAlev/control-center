import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/project_dao.dart';
import 'package:control_center/features/ticketing/data/repositories/dao_project_repository.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DaoProjectRepository repo;
  late ProjectDao dao;

  setUp(() async {
    db = createTestDatabase();
    dao = ProjectDao(db);
    repo = DaoProjectRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  Project makeProject({
    String id = 'p-1',
    String workspaceId = 'ws-1',
    String name = 'Epic Project',
    String? description = 'Getting things done',
    ProjectStatus status = ProjectStatus.active,
    ProjectColor color = ProjectColor.blue,
  }) =>
      Project(
        id: id,
        workspaceId: workspaceId,
        name: name,
        description: description,
        status: status,
        color: color,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

  group('insert', () {
    test('inserts and retrieves project', () async {
      final project = makeProject();
      await repo.insert(project);

      final result = await repo.getById('p-1');
      expect(result, isNotNull);
      expect(result!.name, 'Epic Project');
      expect(result.status, ProjectStatus.active);
      expect(result.color, ProjectColor.blue);
    });
  });

  group('update', () {
    test('updates project fields', () async {
      await repo.insert(makeProject());
      final updated = makeProject(name: 'Updated', description: 'Changed');
      await repo.update(updated);

      final result = await repo.getById('p-1');
      expect(result!.name, 'Updated');
      expect(result.description, 'Changed');
    });

    test('update returns row count', () async {
      await repo.insert(makeProject());
      final updated = makeProject(name: 'V2');
      final count = await repo.update(updated);
      expect(count, 1);
    });

    test('update returns 0 for nonexistent project', () async {
      final count = await repo.update(makeProject(id: 'nonexistent'));
      expect(count, 0);
    });
  });

  group('delete', () {
    test('removes project', () async {
      await repo.insert(makeProject());
      final count = await repo.delete('p-1', workspaceId: 'ws-1');
      expect(count, 1);

      final result = await repo.getById('p-1');
      expect(result, isNull);
    });

    test('scoped to workspace', () async {
      await repo.insert(makeProject(workspaceId: 'ws-1'));
      final count = await repo.delete('p-1', workspaceId: 'ws-2');
      expect(count, 0);

      final result = await repo.getById('p-1');
      expect(result, isNotNull);
    });
  });

  group('getById', () {
    test('returns null for unknown id', () async {
      final result = await repo.getById('nonexistent');
      expect(result, isNull);
    });
  });

  group('getForWorkspace', () {
    test('filters by workspace', () async {
      await repo.insert(makeProject(id: 'p-1', workspaceId: 'ws-1', name: 'A'));
      await repo.insert(makeProject(id: 'p-2', workspaceId: 'ws-1', name: 'B'));
      await repo.insert(makeProject(id: 'p-3', workspaceId: 'ws-2', name: 'C'));

      final ws1 = await repo.getForWorkspace('ws-1');
      expect(ws1.length, 2);

      final ws2 = await repo.getForWorkspace('ws-2');
      expect(ws2.length, 1);
    });

    test('returns empty for unused workspace', () async {
      final projects = await repo.getForWorkspace('empty');
      expect(projects, isEmpty);
    });
  });

  group('watchForWorkspace', () {
    test('emits current projects', () async {
      await repo.insert(makeProject());

      final results = await repo.watchForWorkspace('ws-1').first;
      expect(results.length, 1);
    });
  });

  group('project status and color', () {
    test('all statuses round-trip', () async {
      for (final status in ProjectStatus.values) {
        final project = makeProject(id: 'p-${status.name}', status: status);
        await repo.insert(project);

        final result = await repo.getById('p-${status.name}');
        expect(result!.status, status);
      }
    });

    test('all colors round-trip', () async {
      for (final color in ProjectColor.values) {
        final project = makeProject(id: 'p-${color.name}', color: color);
        await repo.insert(project);

        final result = await repo.getById('p-${color.name}');
        expect(result!.color, color);
      }
    });
  });
}
