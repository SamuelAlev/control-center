import 'dart:async';

import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';

class FakeWorkspaceRepository implements WorkspaceRepository {
  final List<Workspace> _workspaces = [];
  final _controller = StreamController<List<Workspace>>.broadcast();

  List<Workspace> get saved => List.unmodifiable(_workspaces);

  void emit() => _controller.add(List.unmodifiable(_workspaces));

  @override
  Stream<List<Workspace>> watchAll() => _controller.stream;

  @override
  Future<String> upsert(Workspace workspace) async {
    final index = _workspaces.indexWhere((w) => w.id == workspace.id);
    if (index >= 0) {
      _workspaces[index] = workspace;
    } else {
      _workspaces.add(workspace);
    }
    emit();
    return workspace.id;
  }

  @override
  Future<void> delete(String id) async {
    _workspaces.removeWhere((w) => w.id == id);
    emit();
  }

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) {
    return Stream.value(const []);
  }

  @override
  Future<void> setReposForWorkspace(
    String workspaceId,
    List<String> repoIds,
  ) async {}

  final Set<String> _repoLinks = {};

  @override
  Future<bool> isRepoLinkedToWorkspace(
    String workspaceId,
    String repoId,
  ) async =>
      _repoLinks.contains('$workspaceId/$repoId');

  @override
  Future<void> linkRepoToWorkspace(String workspaceId, String repoId) async {
    _repoLinks.add('$workspaceId/$repoId');
  }

  @override
  Future<void> unlinkRepoFromWorkspace(
    String workspaceId,
    String repoId,
  ) async {}

  void dispose() => _controller.close();
}
