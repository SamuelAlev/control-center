import 'package:cc_domain/cc_domain.dart';
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
  Future<Project?> getById(String id) async => store[id];

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

  test('update from a different workspace is rejected', () async {
    final p = await service.create(workspaceId: 'w', name: 'Mine');
    await expectLater(
      () => service.update(p.id, workspaceId: 'other-ws', name: 'Hacked'),
      throwsA(isA<WorkspaceMismatchException>()),
    );
    expect(repo.store[p.id]!.name, 'Mine');
  });

  test('archive sets the status to archived', () async {
    final p = await service.create(workspaceId: 'w', name: 'P');
    final archived = await service.archive(p.id, workspaceId: 'w');
    expect(archived!.status, ProjectStatus.archived);
  });

  test('delete from a different workspace is rejected and it survives',
      () async {
    final p = await service.create(workspaceId: 'w', name: 'P');
    await expectLater(
      () => service.delete(p.id, workspaceId: 'other-ws'),
      throwsA(isA<WorkspaceMismatchException>()),
    );
    expect(repo.store[p.id], isNotNull);

    await service.delete(p.id, workspaceId: 'w');
    expect(repo.store[p.id], isNull);
  });
}
