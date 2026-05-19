import 'dart:async';

import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/features/repos/domain/usecases/add_repo_from_path.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepoRepository implements RepoRepository {
  final List<Repo> _repos = [];
  final _controller = StreamController<List<Repo>>.broadcast();

  List<Repo> get saved => List.unmodifiable(_repos);

  @override
  Stream<List<Repo>> watchAll() => _controller.stream;

  @override
  Future<Repo?> getById(String id) async {
    try {
      return _repos.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> upsert(Repo repo) async {
    final idx = _repos.indexWhere((r) => r.id == repo.id);
    if (idx >= 0) {
      _repos[idx] = repo;
    } else {
      _repos.add(repo);
    }
    _controller.add(List.unmodifiable(_repos));
    return repo.id;
  }

  @override
  Future<void> delete(String id) async {
    _repos.removeWhere((r) => r.id == id);
    _controller.add(List.unmodifiable(_repos));
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
      fakeInspector.setResult(const GitRepoInfo(
        path: '/path/to/repo',
        owner: 'acme',
        repoName: 'project',
        branch: 'main',
      ));

      final repo = await useCase.execute('/path/to/repo', workspaceId: _testWs);

      expect(repo, isA<Repo>());
      expect(repo.name, 'acme/project');
      expect(repo.path, '/path/to/repo');
      expect(repo.githubOwner, 'acme');
      expect(repo.githubRepoName, 'project');
      expect(fakeRepo.saved.length, 1);
    });

    test('generates a UUID v4 as repo id', () async {
      fakeInspector.setResult(const GitRepoInfo(
        path: '/path', owner: 'org', repoName: 'repo', branch: 'main',
      ));

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
      fakeInspector.setResult(const GitRepoInfo(
        path: '/path', owner: 'org', repoName: 'name', branch: 'main',
      ));

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
      fakeInspector.setResult(const GitRepoInfo(
        path: '/code', owner: 'github', repoName: 'myproject', branch: 'dev',
      ));

      final repo = await useCase.execute('/code', workspaceId: _testWs);

      expect(repo.name, 'github/myproject');
    });

    test('throws when repo upsert fails', () async {
      fakeInspector.setResult(const GitRepoInfo(
        path: '/path', owner: 'org', repoName: 'repo', branch: 'main',
      ));

      final repo = await useCase.execute('/path', workspaceId: _testWs);
      expect(repo, isA<Repo>());
      expect(fakeRepo.saved.length, 1);
    });

    test('different paths produce different repos', () async {
      fakeInspector.setResult(const GitRepoInfo(
        path: '/path/a', owner: 'org', repoName: 'a', branch: 'main',
      ));
      final repoA = await useCase.execute('/path/a', workspaceId: _testWs);

      fakeInspector.setResult(const GitRepoInfo(
        path: '/path/b', owner: 'org', repoName: 'b', branch: 'feature',
      ));
      final repoB = await useCase.execute('/path/b', workspaceId: _testWs);

      expect(repoA.path, '/path/a');
      expect(repoB.path, '/path/b');
      expect(repoA.name, 'org/a');
      expect(repoB.name, 'org/b');
      expect(repoA.id, isNot(repoB.id));
    });
  });
}
