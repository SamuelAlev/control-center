import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/repos/repo_workspace_provisioner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A space is provisioned from more than one path at once: the background run
/// off `SpaceCreated`, and the inline call every agent dispatch makes to resolve
/// its working directory. A fan-out sends several agents into one room inside
/// the same second, so those calls genuinely overlap — the provisioner's own
/// cancellation bookkeeping is refcounted precisely because they do.
///
/// What was NOT serialized is the materialization itself.
void main() {
  late Directory root;
  late _FakeFilesystem fs;
  late _RaceyIsolation isolation;
  late _LiveRegistry registry;
  late RepoWorkspaceProvisioner provisioner;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc_provisioner_race');
    fs = _FakeFilesystem(root.path);
    isolation = _RaceyIsolation();
    registry = _LiveRegistry();
    provisioner = RepoWorkspaceProvisioner(
      filesystem: fs,
      isolation: isolation,
      registry: registry,
      workspaces: _FakeWorkspaces([
        Repo(
          id: 'repo-1',
          name: 'web-app',
          path: '/src/web-app',
          remoteOwner: 'acme',
          remoteName: 'web-app',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]),
      githubToken: () async => null,
      branchTemplate: (_) async => '{type}/{key}',
    );
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  String worktreePath() =>
      p.join(root.path, 'spaces', 'sp-1', 'repos', 'web-app');

  Future<String> provision(String agentSlug) => provisioner.ensureSpaceWorkspace(
    workspaceId: 'ws-1',
    spaceId: 'sp-1',
    agentSlug: agentSlug,
    fallbackDir: '',
    repoAllowlist: const {'repo-1'},
  );

  test('overlapping provisions of one space materialize the repo once', () async {
    await Future.wait([provision('alice'), provision('bob'), provision('cara')]);

    expect(
      isolation.provisioned,
      hasLength(1),
      reason:
          'Three dispatches into one room share ONE checkout. Asking the '
          'backend for it three times is three copies of the repository — and '
          'two of the three fail, because a worktree cannot be built over one '
          'that already exists.',
    );
    expect(registry.rows, hasLength(1));
  });

  test('a loser does not reap the winner\'s worktree', () async {
    // The failure mode this guards. Unserialized, the second caller's provision
    // fails with `already_exists` and its own cleanup — which exists to clear a
    // half-materialized copy — deletes the directory the FIRST caller just
    // created and registered. The registry then holds a row for a worktree that
    // is gone, and the agent's overlay symlinks into nothing.
    await Future.wait([provision('alice'), provision('bob')]);

    expect(isolation.destroyed, isEmpty);
    expect(registry.rows.single.path, worktreePath());
    expect(
      Directory(worktreePath()).existsSync(),
      isTrue,
      reason: 'the registered worktree must still be on disk',
    );
  });

  test('different repos of one space still materialize in parallel', () async {
    // The lock is per repo, not per space: serializing a whole space would turn
    // a ten-repo workspace into a queue.
    final wide = RepoWorkspaceProvisioner(
      filesystem: fs,
      isolation: isolation,
      registry: registry,
      workspaces: _FakeWorkspaces([
        for (var i = 1; i <= 3; i++)
          Repo(
            id: 'repo-$i',
            name: 'svc-$i',
            path: '/src/svc-$i',
            remoteOwner: 'acme',
            remoteName: 'svc-$i',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
      ]),
      githubToken: () async => null,
      branchTemplate: (_) async => '{type}/{key}',
    );

    await wide.ensureSpaceWorkspace(
      workspaceId: 'ws-1',
      spaceId: 'sp-2',
      agentSlug: 'alice',
      fallbackDir: '',
    );

    expect(isolation.provisioned, hasLength(3));
    expect(registry.rows, hasLength(3));
  });
}

/// Mimics the backend's real behaviour closely enough for the race to show:
/// `provision` takes a few event-loop turns (a copy is not instantaneous) and
/// REFUSES a destination that already exists, exactly as rift reports
/// `already_exists` and `git worktree add` reports "already exists".
class _RaceyIsolation implements RepoIsolationPort {
  final List<String> provisioned = [];
  final List<String> destroyed = [];

  @override
  bool get isCowAvailable => true;

  @override
  Future<RepoIsolationResult> provision({
    required String sourcePath,
    required String destParentDir,
    required String name,
    required String branch,
    String baseRef = '',
    String? authUrl,
    String? headRef,
    bool pristine = false,
    CancellationToken? cancel,
  }) async {
    final path = p.join(destParentDir, name);
    if (Directory(path).existsSync()) {
      throw StateError('already_exists: $path');
    }
    // Yield, so an unserialized second caller gets in before the row lands.
    await Future<void>.delayed(Duration.zero);
    Directory(path).createSync(recursive: true);
    await Future<void>.delayed(Duration.zero);
    provisioned.add(path);
    return RepoIsolationResult(path: path, backend: RepoIsolationBackend.rift);
  }

  @override
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
  }) async {
    destroyed.add(path);
    final dir = Directory(path);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Unlike the orphan test's stub, this one answers reads from what has actually
/// been written — which is what makes "the second caller reuses the first's
/// worktree" observable at all.
class _LiveRegistry implements IsolatedRepoRepository {
  final List<IsolatedRepo> rows = [];

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async {
    // A read is not free in the real adapter either; yielding keeps the fake
    // from hiding an interleaving the database would allow.
    await Future<void>.delayed(Duration.zero);
    for (final row in rows) {
      if (row.workspaceId == workspaceId &&
          row.spaceId == spaceId &&
          row.repoId == repoId) {
        return row;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(IsolatedRepo repo) async {
    rows
      ..removeWhere(
        (r) =>
            r.workspaceId == repo.workspaceId &&
            r.spaceId == repo.spaceId &&
            r.repoId == repo.repoId,
      )
      ..add(repo);
  }

  @override
  Future<void> deleteById(String workspaceId, String id) async =>
      rows.removeWhere((r) => r.id == id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFilesystem implements WorkspaceFilesystemPort {
  _FakeFilesystem(this.root);

  final String root;

  @override
  Future<String> ensureSpaceDir(String workspaceId, String spaceId) async {
    final dir = Directory(p.join(root, 'spaces', spaceId));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir.path;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWorkspaces implements WorkspaceRepository {
  _FakeWorkspaces(this.repos);

  final List<Repo> repos;

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(repos);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
