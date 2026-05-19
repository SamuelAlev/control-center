import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/project_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProjectRepo implements ProjectRepository {
  final Map<String, Project> store = {};

  @override
  Future<void> insert(Project project) async => store[project.id] = project;

  @override
  Future<int> update(Project project) async {
    final current = store[project.id];
    if (current == null || current.workspaceId != project.workspaceId) {
      return 0;
    }
    store[project.id] = project;
    return 1;
  }

  @override
  Future<int> delete(String projectId, {required String workspaceId}) async {
    final p = store[projectId];
    if (p == null || p.workspaceId != workspaceId) {
      return 0;
    }
    store.remove(projectId);
    return 1;
  }

  @override
  Future<Project?> getById(String workspaceId, String id) async {
    final project = store[id];
    return project?.workspaceId == workspaceId ? project : null;
  }

  @override
  Future<List<Project>> getForWorkspace(String workspaceId) async =>
      store.values.where((p) => p.workspaceId == workspaceId).toList();

  @override
  Stream<List<Project>> watchForWorkspace(String workspaceId) =>
      Stream.value(getForWorkspaceSync(workspaceId));

  List<Project> getForWorkspaceSync(String workspaceId) =>
      store.values.where((p) => p.workspaceId == workspaceId).toList();
}

void main() {
  late _FakeProjectRepo repo;
  late ProjectService service;

  setUp(() {
    repo = _FakeProjectRepo();
    service = ProjectService(repository: repo);
  });

  test('create trims the name and persists', () async {
    final p = await service.create(
      workspaceId: 'w',
      name: '  Auth  ',
      color: ProjectColor.green,
    );
    expect(p.name, 'Auth');
    expect(p.color, ProjectColor.green);
    expect(repo.store[p.id], isNotNull);
  });

  test('create rejects an empty name', () async {
    await expectLater(
      () => service.create(workspaceId: 'w', name: '   '),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('update renames and recolors within the workspace', () async {
    final p = await service.create(workspaceId: 'w', name: 'Old');
    final updated = await service.update(
      p.id,
      workspaceId: 'w',
      name: 'New',
      color: ProjectColor.red,
    );
    expect(updated!.name, 'New');
    expect(updated.color, ProjectColor.red);
    expect(repo.store[p.id]!.name, 'New');
  });

  test('update from a different workspace does not resolve the id', () async {
    final p = await service.create(workspaceId: 'w', name: 'Mine');

    // A workspace id selects the database file, so the id of a project owned
    // by 'w' is simply absent in 'other-ws' — the update finds nothing.
    expect(
      await service.update(p.id, workspaceId: 'other-ws', name: 'Hacked'),
      isNull,
    );
    expect(repo.store[p.id]!.name, 'Mine');
  });

  test('archive sets the status to archived', () async {
    final p = await service.create(workspaceId: 'w', name: 'P');
    final archived = await service.archive(p.id, workspaceId: 'w');
    expect(archived!.status, ProjectStatus.archived);
  });

  test(
    'delete from a different workspace does not resolve and it survives',
    () async {
      final p = await service.create(workspaceId: 'w', name: 'P');

      // The foreign id resolves to nothing, so the delete is a no-op rather than
      // a cross-workspace write.
      await service.delete(p.id, workspaceId: 'other-ws');
      expect(repo.store[p.id], isNotNull);

      await service.delete(p.id, workspaceId: 'w');
      expect(repo.store[p.id], isNull);
    },
  );
}
