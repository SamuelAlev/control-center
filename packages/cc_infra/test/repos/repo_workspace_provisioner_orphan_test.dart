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

void main() {
  late Directory root;
  late _FakeFilesystem fs;
  late _RecordingIsolation isolation;
  late _FakeRegistry registry;
  late _FakeWorkspaces workspaces;
  late RepoWorkspaceProvisioner provisioner;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc_provisioner_test');
    fs = _FakeFilesystem(root.path);
    isolation = _RecordingIsolation();
    registry = _FakeRegistry();
    workspaces = _FakeWorkspaces([
      Repo(
        id: 'repo-1',
        name: 'web-app',
        path: '/src/web-app',
        remoteOwner: 'acme',
        remoteName: 'web-app',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ]);
    provisioner = RepoWorkspaceProvisioner(
      filesystem: fs,
      isolation: isolation,
      registry: registry,
      workspaces: workspaces,
      githubToken: () async => null,
      branchTemplate: (_) async => '{type}/{key}',
    );
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  String orphanPath() => p.join(root.path, 'spaces', 'sp-1', 'repos', 'web-app');

  test('an orphaned worktree directory is reaped before provisioning, so the '
      'first attempt succeeds', () async {
    // A copy on disk whose registry row is gone — a deleted space, a reaped
    // conversation, or a provision that was killed mid-run. Neither backend can
    // build over it: rift refuses with `already_exists` and `git worktree add`
    // with "already exists", so before the reap moved earlier this attempt was
    // guaranteed to fail and take the whole space to `failed` with it.
    Directory(orphanPath()).createSync(recursive: true);
    File(p.join(orphanPath(), 'leftover.txt')).writeAsStringSync('stale');

    await provisioner.ensureSpaceWorkspace(
      workspaceId: 'ws-1',
      spaceId: 'sp-1',
      agentSlug: '_pr',
      fallbackDir: '',
      prHeadRef: 'refs/pull/42/head',
      prHeadRepoFullName: 'acme/web-app',
      prBranch: 'pr/42',
      repoAllowlist: const {'repo-1'},
    );

    expect(
      isolation.destroyed,
      [orphanPath()],
      reason: 'the orphan must be torn down, not provisioned over',
    );
    expect(isolation.provisioned, hasLength(1));
    expect(
      isolation.order,
      ['destroy', 'provision'],
      reason: 'the reap has to happen BEFORE the backend is asked to create',
    );
    expect(
      registry.upserts.single.path,
      orphanPath(),
      reason: 'a successful provision registers its worktree',
    );
  });

  test('a clean destination is provisioned without a teardown', () async {
    await provisioner.ensureSpaceWorkspace(
      workspaceId: 'ws-1',
      spaceId: 'sp-1',
      agentSlug: '_pr',
      fallbackDir: '',
      prHeadRef: 'refs/pull/42/head',
      prHeadRepoFullName: 'acme/web-app',
      prBranch: 'pr/42',
      repoAllowlist: const {'repo-1'},
    );

    expect(isolation.destroyed, isEmpty);
    expect(isolation.provisioned, hasLength(1));
  });

  test('an existing registered worktree is reused, never reaped', () async {
    Directory(orphanPath()).createSync(recursive: true);
    registry.existing = IsolatedRepo(
      id: 'iso-1',
      workspaceId: 'ws-1',
      spaceId: 'sp-1',
      repoId: 'repo-1',
      path: orphanPath(),
      branch: 'pr/42',
      backend: RepoIsolationBackend.rift,
      sourcePath: '/src/web-app',
      createdAt: DateTime(2026),
    );

    await provisioner.ensureSpaceWorkspace(
      workspaceId: 'ws-1',
      spaceId: 'sp-1',
      agentSlug: '_pr',
      fallbackDir: '',
      prHeadRef: 'refs/pull/42/head',
      prHeadRepoFullName: 'acme/web-app',
      prBranch: 'pr/42',
      repoAllowlist: const {'repo-1'},
    );

    expect(isolation.destroyed, isEmpty);
    expect(isolation.provisioned, isEmpty);
  });
}

/// Records the calls and mimics the on-disk effect of each: `provision`
/// materializes the destination, `destroy` removes it.
class _RecordingIsolation implements RepoIsolationPort {
  final List<String> provisioned = [];
  final List<String> destroyed = [];
  final List<String> order = [];

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
    provisioned.add(path);
    order.add('provision');
    Directory(path).createSync(recursive: true);
    return RepoIsolationResult(
      path: path,
      backend: RepoIsolationBackend.rift,
    );
  }

  @override
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
  }) async {
    destroyed.add(path);
    order.add('destroy');
    final dir = Directory(path);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

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

class _FakeRegistry implements IsolatedRepoRepository {
  IsolatedRepo? existing;
  final List<IsolatedRepo> upserts = [];

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async => existing;

  @override
  Future<void> upsert(IsolatedRepo repo) async => upserts.add(repo);

  @override
  Future<void> deleteById(String workspaceId, String id) async =>
      existing = null;

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
