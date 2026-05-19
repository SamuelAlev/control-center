import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';

/// In-memory [WorkspaceRepository] over a per-workspace repo map.
///
/// There is no link table: a repo belongs to exactly one workspace, so the same
/// checkout registered twice is two rows under two ids. That shape is what makes
/// cross-workspace resolution impossible rather than merely filtered.
class FakeWorkspaceRepository implements WorkspaceRepository {
  final List<Workspace> _workspaces = [];
  final _controller = StreamController<List<Workspace>>.broadcast();

  final Map<String, List<Repo>> _reposByWorkspace = {};

  /// Workspaces upserted so far, in manual order.
  List<Workspace> get saved => List.unmodifiable(_workspaces);

  /// Replaces [workspaceId]'s repos, for tests that need one pre-registered.
  void seedRepos(String workspaceId, List<Repo> repos) {
    _reposByWorkspace[workspaceId] = List.of(repos);
  }

  /// The repos currently registered in [workspaceId].
  List<Repo> reposIn(String workspaceId) =>
      List.unmodifiable(_reposByWorkspace[workspaceId] ?? const <Repo>[]);

  /// Pushes the current workspace list to [watchAll] listeners.
  void emit() => _controller.add(List.unmodifiable(_workspaces));

  @override
  Stream<List<Workspace>> watchAll() => _controller.stream;

  @override
  Future<List<Workspace>> getAll() async => List.unmodifiable(_workspaces);

  @override
  Future<Workspace?> getById(String id) async {
    for (final w in _workspaces) {
      if (w.id == id) {
        return w;
      }
    }
    return null;
  }

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
    // Deleting a workspace drops its database file, and with it every repo row.
    _reposByWorkspace.remove(id);
    emit();
  }

  @override
  Future<void> reorderWorkspaces(List<String> orderedIds) async {
    _workspaces.sort((a, b) {
      final ai = orderedIds.indexOf(a.id);
      final bi = orderedIds.indexOf(b.id);
      // Ids absent from the requested order keep their relative place at the end.
      return (ai < 0 ? orderedIds.length : ai).compareTo(
        bi < 0 ? orderedIds.length : bi,
      );
    });
    emit();
  }

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) {
    return Stream.value(reposIn(workspaceId));
  }

  @override
  Future<void> setReposForWorkspace(
    String workspaceId,
    List<String> repoIds,
  ) async {
    final owned = _reposByWorkspace[workspaceId];
    if (owned == null) {
      return;
    }
    // Ids the workspace does not own are ignored: a repo cannot be conjured from
    // an id, because ids are per-workspace.
    final byId = {for (final r in owned) r.id: r};
    final reordered = <Repo>[];
    for (final id in repoIds) {
      final repo = byId.remove(id);
      if (repo != null) {
        reordered.add(repo);
      }
    }
    _reposByWorkspace[workspaceId] = [...reordered, ...byId.values];
  }

  @override
  Future<bool> isRepoLinkedToWorkspace(
    String workspaceId,
    String repoId,
  ) async => reposIn(workspaceId).any((r) => r.id == repoId);

  @override
  Future<void> unlinkRepoFromWorkspace(
    String workspaceId,
    String repoId,
  ) async {
    _reposByWorkspace[workspaceId]?.removeWhere((r) => r.id == repoId);
  }

  /// Closes the [watchAll] controller.
  void dispose() => _controller.close();
}
