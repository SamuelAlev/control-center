import 'dart:io';

import 'package:control_center/core/domain/entities/isolated_repo.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/ports/repo_isolation_port.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/domain/repositories/isolated_repo_repository.dart';
import 'package:control_center/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/pr_review/data/services/pr_worktree_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFs extends Fake implements WorkspaceFilesystemPort {
  _FakeFs(this.root);
  final String root;
  @override
  Future<Directory> workspaceDir(String workspaceId) async =>
      Directory('$root/$workspaceId');
}

class _FakeIsolation extends Fake implements RepoIsolationPort {
  final List<Map<String, Object?>> provisioned = [];
  final List<String> destroyed = [];

  @override
  Future<RepoIsolationResult> provision({
    required String sourcePath,
    required String destParentDir,
    required String name,
    required String branch,
    String baseRef = '',
    String? authUrl,
    String? headRef,
  }) async {
    provisioned.add({
      'sourcePath': sourcePath,
      'destParentDir': destParentDir,
      'name': name,
      'branch': branch,
      'authUrl': authUrl,
      'headRef': headRef,
    });
    return RepoIsolationResult(
      path: '$destParentDir/$name',
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
  }
}

class _FakeRegistry extends Fake implements IsolatedRepoRepository {
  final List<IsolatedRepo> rows = [];

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String channelId,
    String repoId,
  ) async {
    for (final r in rows) {
      if (r.workspaceId == workspaceId &&
          r.channelId == channelId &&
          r.repoId == repoId) {
        return r;
      }
    }
    return null;
  }

  @override
  Future<List<IsolatedRepo>> forChannelAcrossWorkspaces(String channelId) async =>
      rows.where((r) => r.channelId == channelId).toList();

  @override
  Future<void> upsert(IsolatedRepo repo) async {
    rows
      ..removeWhere((r) => r.id == repo.id)
      ..add(repo);
  }

  @override
  Future<void> deleteById(String id) async =>
      rows.removeWhere((r) => r.id == id);
}

Repo _repo({String owner = 'octocat', String name = 'hello'}) => Repo(
      id: 'r1',
      name: name,
      path: '/src/$name',
      githubOwner: owner,
      githubRepoName: name,
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    );

void main() {
  group('PrWorktreeService', () {
    late _FakeFs fs;
    late _FakeIsolation isolation;
    late _FakeRegistry registry;
    late PrWorktreeService service;

    setUp(() {
      fs = _FakeFs('/ws');
      isolation = _FakeIsolation();
      registry = _FakeRegistry();
      service = PrWorktreeService(
        filesystem: fs,
        isolation: isolation,
        registry: registry,
        githubToken: () async => 'tok',
      );
    });

    test('provisions a CoW worktree at the PR head and registers it', () async {
      final path = await service.ensureWorktree(
        workspaceId: 'w1',
        repo: _repo(),
        prNumber: 42,
        prHeadRef: 'feature/foo',
      );

      // The directory stays stable + filesystem-safe per PR...
      expect(path, '/ws/w1/pr_worktrees/octocat__hello/pr-42');

      expect(isolation.provisioned, hasLength(1));
      final call = isolation.provisioned.single;
      expect(call['headRef'], 'refs/pull/42/head');
      expect(call['name'], 'pr-42');
      // ...while the git branch carries the PR's real head-ref name.
      expect(call['branch'], 'feature/foo');
      expect(call['sourcePath'], '/src/hello');
      expect(
        call['authUrl'],
        'https://x-access-token:tok@github.com/octocat/hello.git',
      );

      expect(registry.rows, hasLength(1));
      expect(registry.rows.single.channelId, 'pr:octocat/hello#42');
      expect(registry.rows.single.branch, 'feature/foo');
      expect(registry.rows.single.repoId, 'r1');
      expect(registry.rows.single.workspaceId, 'w1');
    });

    test('falls back to pr-<n> as the branch when the head ref is empty',
        () async {
      await service.ensureWorktree(
        workspaceId: 'w1',
        repo: _repo(),
        prNumber: 42,
        prHeadRef: '',
      );
      expect(isolation.provisioned.single['branch'], 'pr-42');
    });

    test('reuses an existing on-disk worktree without re-provisioning',
        () async {
      final tmp = Directory.systemTemp.createTempSync('pr_wt_test');
      addTearDown(() => tmp.deleteSync(recursive: true));
      registry.rows.add(
        IsolatedRepo(
          id: 'existing',
          workspaceId: 'w1',
          channelId: 'pr:octocat/hello#42',
          repoId: 'r1',
          path: tmp.path,
          branch: 'pr-42',
          backend: RepoIsolationBackend.rift,
          sourcePath: '/src/hello',
          createdAt: DateTime(2020),
        ),
      );

      final path = await service.ensureWorktree(
        workspaceId: 'w1',
        repo: _repo(),
        prNumber: 42,
        prHeadRef: 'feature/foo',
      );

      expect(path, tmp.path);
      expect(isolation.provisioned, isEmpty);
      expect(registry.rows, hasLength(1));
    });

    test('throws when the repo has no GitHub remote', () async {
      await expectLater(
        service.ensureWorktree(
          workspaceId: 'w1',
          repo: _repo(owner: '', name: ''),
          prNumber: 42,
          prHeadRef: 'feature/foo',
        ),
        throwsA(isA<PrWorktreeException>()),
      );
      expect(isolation.provisioned, isEmpty);
    });

    test('release destroys and forgets the PR worktree', () async {
      await service.ensureWorktree(
        workspaceId: 'w1',
        repo: _repo(),
        prNumber: 42,
        prHeadRef: 'feature/foo',
      );
      expect(registry.rows, hasLength(1));

      await service.release(repoFullName: 'octocat/hello', prNumber: 42);

      expect(isolation.destroyed, hasLength(1));
      expect(registry.rows, isEmpty);
    });
  });
}
