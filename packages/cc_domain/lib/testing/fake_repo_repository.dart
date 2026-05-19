/// An in-memory fake of [RepoRepository], shared by every suite that needs one.
///
/// Lives under `lib/testing/` for the same reason as the memory fakes: more
/// than one package's suite needs it (cc_mcp's memory tool tests and the root
/// app suite), and a Dart test file cannot import another package's `test/`
/// directory.
library;

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';

/// In-memory fake [RepoRepository], keyed by workspace.
class FakeRepoRepository implements RepoRepository {
  final Map<String, List<Repo>> _byWorkspace = {};

  /// Seeds [repos] into [workspaceId], appending to whatever is already there.
  void seed(String workspaceId, List<Repo> repos) =>
      _byWorkspace.putIfAbsent(workspaceId, () => []).addAll(repos);

  @override
  Future<List<Repo>> getAll(String workspaceId) async =>
      List<Repo>.from(_byWorkspace[workspaceId] ?? const []);

  @override
  Stream<List<Repo>> watchAll(String workspaceId) async* {
    yield await getAll(workspaceId);
  }

  @override
  Future<Repo?> getById(String workspaceId, String repoId) async =>
      (_byWorkspace[workspaceId] ?? const <Repo>[])
          .where((r) => r.id == repoId)
          .firstOrNull;

  @override
  Future<Repo?> findByPath(String workspaceId, String path) async =>
      (_byWorkspace[workspaceId] ?? const <Repo>[])
          .where((r) => r.path == path)
          .firstOrNull;

  @override
  Future<bool> exists(String workspaceId, String repoId) async =>
      await getById(workspaceId, repoId) != null;

  @override
  Future<String> upsert(String workspaceId, Repo repo) async {
    final repos = _byWorkspace.putIfAbsent(workspaceId, () => []);
    final idx = repos.indexWhere((r) => r.id == repo.id);
    if (idx >= 0) {
      repos[idx] = repo;
    } else {
      repos.add(repo);
    }
    return repo.id;
  }

  @override
  Future<void> delete(String workspaceId, String repoId) async =>
      _byWorkspace[workspaceId]?.removeWhere((r) => r.id == repoId);

  @override
  Future<void> reorder(String workspaceId, List<String> orderedIds) async {
    final repos = _byWorkspace[workspaceId];
    if (repos == null) {
      return;
    }
    final byId = {for (final r in repos) r.id: r};
    final ordered = [
      for (final id in orderedIds)
        if (byId.remove(id) case final Repo r) r,
    ];
    _byWorkspace[workspaceId] = [...ordered, ...byId.values];
  }
}
