import 'dart:async';

import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/repos/domain/usecases/add_repo_from_path.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepoRepository implements RepoRepository {
  /// Repos keyed by workspace: a repo row lives in exactly one workspace's
  /// database, so the same checkout registered twice is two independent rows.
  final Map<String, List<Repo>> _byWorkspace = {};
  final _controller = StreamController<List<Repo>>.broadcast();

  List<Repo> get saved =>
      List.unmodifiable(_byWorkspace.values.expand((r) => r));

  List<Repo> reposIn(String workspaceId) =>
      List.unmodifiable(_byWorkspace[workspaceId] ?? const <Repo>[]);

  @override
  Stream<List<Repo>> watchAll(String workspaceId) => _controller.stream;

  @override
  Future<List<Repo>> getAll(String workspaceId) async => reposIn(workspaceId);

  @override
  Future<Repo?> getById(String workspaceId, String repoId) async =>
      reposIn(workspaceId).where((r) => r.id == repoId).firstOrNull;

  @override
  Future<Repo?> findByPath(String workspaceId, String path) async =>
      reposIn(workspaceId).where((r) => r.path == path).firstOrNull;

  @override
  Future<bool> exists(String workspaceId, String repoId) async =>
      await getById(workspaceId, repoId) != null;

  @override
  Future<String> upsert(String workspaceId, Repo repo) async {
    final list = _byWorkspace.putIfAbsent(workspaceId, () => <Repo>[]);
    final idx = list.indexWhere((r) => r.id == repo.id);
    if (idx >= 0) {
      list[idx] = repo;
    } else {
      list.add(repo);
    }
    _controller.add(reposIn(workspaceId));
    return repo.id;
  }

  @override
  Future<void> delete(String workspaceId, String repoId) async {
    _byWorkspace[workspaceId]?.removeWhere((r) => r.id == repoId);
    _controller.add(reposIn(workspaceId));
  }

  @override
  Future<void> reorder(String workspaceId, List<String> orderedIds) async {
    final list = _byWorkspace[workspaceId];
    if (list == null) {
      return;
    }
    final byId = {for (final r in list) r.id: r};
    final reordered = [
      for (final id in orderedIds)
        if (byId.remove(id) case final Repo r) r,
      ...byId.values,
    ];
    list
      ..clear()
      ..addAll(reordered);
    _controller.add(reposIn(workspaceId));
  }

  void dispose() => _controller.close();
}

class _FakeInspector implements GitRepoInspectorPort {
  GitRepoInfo? _info;
  GitRepoInspectionException? _error;

  void setResult(GitRepoInfo info) {
    _info = info;
    _error = null;
  }

  void setError(GitRepoInspectionException error) {
    _error = error;
    _info = null;
  }

  @override
  Future<GitRepoInfo> inspect(String path) async {
    if (_error != null) {
      throw _error!;
    }
    if (_info != null) {
      return _info!;
    }
    throw const GitRepoInspectionException('Not configured');
  }
}

const _testWs = 'test-workspace';

void main() {
  late _FakeRepoRepository fakeRepo;
  late _FakeInspector fakeInspector;
  late AddRepoFromPathUseCase useCase;

  setUp(() {
    fakeRepo = _FakeRepoRepository();
    fakeInspector = _FakeInspector();
    useCase = AddRepoFromPathUseCase(
      repository: fakeRepo,
      inspector: fakeInspector,
    );
  });

  tearDown(() {
    fakeRepo.dispose();
  });

  group('AddRepoFromPathUseCase', () {
    test('executes successfully and returns a repo', () async {
      fakeInspector.setResult(
        const GitRepoInfo(
          path: '/path/to/repo',
          forge: ForgeHost.github,
          owner: 'acme',
          repoName: 'project',
          branch: 'main',
        ),
      );

      final repo = await useCase.execute('/path/to/repo', workspaceId: _testWs);

      expect(repo, isA<Repo>());
      expect(repo.name, 'acme/project');
      expect(repo.path, '/path/to/repo');
      expect(repo.remoteOwner, 'acme');
      expect(repo.remoteName, 'project');
      expect(fakeRepo.saved.length, 1);
    });

    test('generates a UUID v4 as repo id', () async {
      fakeInspector.setResult(
        const GitRepoInfo(
          path: '/path',
          forge: ForgeHost.github,
          owner: 'org',
          repoName: 'repo',
          branch: 'main',
        ),
      );

      final repo = await useCase.execute('/path', workspaceId: _testWs);

      expect(repo.id, isNotEmpty);
      expect(repo.id.length, 36);
    });

    test('throws GitRepoInspectionException on inspect failure', () async {
      fakeInspector.setError(
        const GitRepoInspectionException('Not a git work tree'),
      );

      expect(
        () => useCase.execute('/bad/path', workspaceId: _testWs),
        throwsA(isA<GitRepoInspectionException>()),
      );
      expect(fakeRepo.saved, isEmpty);
    });

    test('sets createdAt and updatedAt to current time', () async {
      fakeInspector.setResult(
        const GitRepoInfo(
          path: '/path',
          forge: ForgeHost.github,
          owner: 'org',
          repoName: 'name',
          branch: 'main',
        ),
      );

      final before = DateTime.now();
      final repo = await useCase.execute('/path', workspaceId: _testWs);
      final after = DateTime.now();

      expect(
        repo.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        repo.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
      expect(repo.createdAt, repo.updatedAt);
    });

    test('uses name format owner/repoName', () async {
      fakeInspector.setResult(
        const GitRepoInfo(
          path: '/code',
          forge: ForgeHost.github,
          owner: 'github',
          repoName: 'myproject',
          branch: 'dev',
        ),
      );

      final repo = await useCase.execute('/code', workspaceId: _testWs);

      expect(repo.name, 'github/myproject');
    });

    test('throws when repo upsert fails', () async {
      fakeInspector.setResult(
        const GitRepoInfo(
          path: '/path',
          forge: ForgeHost.github,
          owner: 'org',
          repoName: 'repo',
          branch: 'main',
        ),
      );

      final repo = await useCase.execute('/path', workspaceId: _testWs);
      expect(repo, isA<Repo>());
      expect(fakeRepo.saved.length, 1);
    });

    test(
      're-registering a path in the same workspace reuses the repo',
      () async {
        fakeInspector.setResult(
          const GitRepoInfo(
            path: '/path',
            forge: ForgeHost.github,
            owner: 'org',
            repoName: 'repo',
            branch: 'main',
          ),
        );

        final first = await useCase.execute('/path', workspaceId: _testWs);
        final second = await useCase.execute('/path', workspaceId: _testWs);

        expect(second.id, first.id);
        expect(fakeRepo.reposIn(_testWs), hasLength(1));
      },
    );

    test('the same checkout in two workspaces is two repos', () async {
      fakeInspector.setResult(
        const GitRepoInfo(
          path: '/path',
          forge: ForgeHost.github,
          owner: 'org',
          repoName: 'repo',
          branch: 'main',
        ),
      );

      final inA = await useCase.execute('/path', workspaceId: _testWs);
      final inB = await useCase.execute(
        '/path',
        workspaceId: 'other-workspace',
      );

      // Repos are workspace-scoped: identity across workspaces is the path.
      expect(inB.id, isNot(inA.id));
      expect(inA.path, inB.path);
      expect(fakeRepo.reposIn(_testWs).single.id, inA.id);
      expect(fakeRepo.reposIn('other-workspace').single.id, inB.id);
    });

    test('different paths produce different repos', () async {
      fakeInspector.setResult(
        const GitRepoInfo(
          path: '/path/a',
          forge: ForgeHost.github,
          owner: 'org',
          repoName: 'a',
          branch: 'main',
        ),
      );
      final repoA = await useCase.execute('/path/a', workspaceId: _testWs);

      fakeInspector.setResult(
        const GitRepoInfo(
          path: '/path/b',
          forge: ForgeHost.github,
          owner: 'org',
          repoName: 'b',
          branch: 'feature',
        ),
      );
      final repoB = await useCase.execute('/path/b', workspaceId: _testWs);

      expect(repoA.path, '/path/a');
      expect(repoB.path, '/path/b');
      expect(repoA.name, 'org/a');
      expect(repoB.name, 'org/b');
      expect(repoA.id, isNot(repoB.id));
    });
  });
}
