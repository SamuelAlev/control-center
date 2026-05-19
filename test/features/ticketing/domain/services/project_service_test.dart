import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:control_center/features/ticketing/domain/repositories/project_repository.dart';
import 'package:control_center/features/ticketing/domain/services/project_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake [ProjectRepository].
class FakeProjectRepository implements ProjectRepository {
  final Map<String, Project> _projects = {};
  int insertCount = 0;
  int updateCount = 0;
  int deleteCount = 0;

  @override
  Future<void> insert(Project project) async {
    insertCount++;
    _projects[project.id] = project;
  }

  @override
  Future<int> update(Project project) async {
    updateCount++;
    if (_projects.containsKey(project.id)) {
      _projects[project.id] = project;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> delete(String projectId, {required String workspaceId}) async {
    deleteCount++;
    final p = _projects[projectId];
    if (p != null && p.workspaceId == workspaceId) {
      _projects.remove(projectId);
      return 1;
    }
    return 0;
  }

  @override
  Future<Project?> getById(String id) async => _projects[id];

  @override
  Future<List<Project>> getForWorkspace(String workspaceId) async =>
      _projects.values.where((p) => p.workspaceId == workspaceId).toList();

  @override
  Stream<List<Project>> watchForWorkspace(String workspaceId) async* {
    yield _projects.values.where((p) => p.workspaceId == workspaceId).toList();
  }
}

void main() {
  group('ProjectService', () {
    late FakeProjectRepository repo;
    late ProjectService service;

    setUp(() {
      repo = FakeProjectRepository();
      service = ProjectService(repository: repo);
    });

    test('creates a project with valid inputs', () async {
      final project = await service.create(
        workspaceId: 'ws1',
        name: 'My Project',
        description: 'A test project',
        color: ProjectColor.blue,
      );

      expect(project.name, 'My Project');
      expect(project.description, 'A test project');
      expect(project.workspaceId, 'ws1');
      expect(project.color, ProjectColor.blue);
      expect(project.status, ProjectStatus.active);
      expect(project.id, isNotEmpty);
      expect(repo.insertCount, 1);
    });

    test('trims whitespace from name', () async {
      final project = await service.create(
        workspaceId: 'ws1',
        name: '  Padded Name  ',
      );
      expect(project.name, 'Padded Name');
    });

    test('trims whitespace from description', () async {
      final project = await service.create(
        workspaceId: 'ws1',
        name: 'Proj',
        description: '  desc  ',
      );
      expect(project.description, 'desc');
    });

    test('empty description becomes null', () async {
      final project = await service.create(
        workspaceId: 'ws1',
        name: 'Proj',
        description: '   ',
      );
      expect(project.description, isNull);
    });

    test('null description stays null', () async {
      final project = await service.create(
        workspaceId: 'ws1',
        name: 'Proj',
        description: null,
      );
      expect(project.description, isNull);
    });

    test('throws ArgumentError for empty name', () async {
      await expectLater(
        service.create(workspaceId: 'ws1', name: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for whitespace-only name', () async {
      await expectLater(
        service.create(workspaceId: 'ws1', name: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('default color is gray', () async {
      final project = await service.create(workspaceId: 'ws1', name: 'P');
      expect(project.color, ProjectColor.gray);
    });

    test('sets createdAt and updatedAt', () async {
      final before = DateTime.now();
      final project = await service.create(workspaceId: 'ws1', name: 'P');
      final after = DateTime.now();

      expect(project.createdAt, isNotNull);
      expect(project.updatedAt, isNotNull);
      expect(project.createdAt, project.updatedAt);
      expect(
        project.createdAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch - 1000),
      );
      expect(
        project.createdAt.millisecondsSinceEpoch,
        lessThanOrEqualTo(after.millisecondsSinceEpoch + 1000),
      );
    });

    test('generates unique IDs', () async {
      final p1 = await service.create(workspaceId: 'ws1', name: 'A');
      final p2 = await service.create(workspaceId: 'ws1', name: 'B');
      expect(p1.id, isNot(p2.id));
    });

    test('update name of existing project', () async {
      final created = await service.create(workspaceId: 'ws1', name: 'Old');
      final updated = await service.update(created.id, workspaceId: 'ws1', name: 'New');

      expect(updated, isNotNull);
      expect(updated!.name, 'New');
      expect(repo.updateCount, 1);
    });

    test('update description to null via empty string', () async {
      final created = await service.create(
        workspaceId: 'ws1', name: 'Proj', description: 'Old desc',
      );
      final updated = await service.update(
        created.id, workspaceId: 'ws1', description: '',
      );
      expect(updated!.description, isNull);
    });

    test('update removes description when empty passed', () async {
      final created = await service.create(
        workspaceId: 'ws1', name: 'Proj', description: 'Old desc',
      );
      final updated = await service.update(
        created.id, workspaceId: 'ws1', description: '   ',
      );
      expect(updated!.description, isNull);
    });

    test('update keeps existing description when null passed', () async {
      final created = await service.create(
        workspaceId: 'ws1', name: 'Proj', description: 'Old desc',
      );
      final updated = await service.update(
        created.id, workspaceId: 'ws1', description: null,
      );
      expect(updated!.description, 'Old desc');
    });

    test('update color only', () async {
      final created = await service.create(workspaceId: 'ws1', name: 'Proj');
      final updated = await service.update(
        created.id, workspaceId: 'ws1', color: ProjectColor.red,
      );
      expect(updated!.color, ProjectColor.red);
      expect(updated.name, 'Proj');
    });

    test('update returns null for missing project', () async {
      final result = await service.update('nonexistent', workspaceId: 'ws1', name: 'X');
      expect(result, isNull);
    });

    test('update throws WorkspaceMismatchException for wrong workspace', () async {
      final created = await service.create(workspaceId: 'ws1', name: 'Proj');
      await expectLater(
        service.update(created.id, workspaceId: 'ws2', name: 'X'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });

    test('update bumps updatedAt', () async {
      final created = await service.create(workspaceId: 'ws1', name: 'Proj');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final updated = await service.update(created.id, workspaceId: 'ws1', name: 'New');

      expect(updated!.updatedAt.isAfter(created.updatedAt), isTrue);
      expect(updated.createdAt, created.createdAt);
    });

    test('archive sets status to archived', () async {
      final created = await service.create(workspaceId: 'ws1', name: 'Proj');
      final archived = await service.archive(created.id, workspaceId: 'ws1');

      expect(archived, isNotNull);
      expect(archived!.status, ProjectStatus.archived);
    });

    test('delete removes the project', () async {
      final created = await service.create(workspaceId: 'ws1', name: 'Proj');
      await service.delete(created.id, workspaceId: 'ws1');

      expect(repo.deleteCount, 1);
      expect(await repo.getById(created.id), isNull);
    });

    test('delete is no-op for missing project', () async {
      await service.delete('nonexistent', workspaceId: 'ws1');
      expect(repo.deleteCount, 0);
    });

    test('delete throws WorkspaceMismatchException for wrong workspace', () async {
      final created = await service.create(workspaceId: 'ws1', name: 'Proj');
      await expectLater(
        service.delete(created.id, workspaceId: 'ws2'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      expect(repo.deleteCount, 0);
    });
  });
}
