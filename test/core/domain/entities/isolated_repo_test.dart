import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCreatedAt = DateTime(2024, 6, 15);

  IsolatedRepo createRepo({
    String id = 'iso-1',
    String workspaceId = 'ws-1',
    String channelId = 'ch-1',
    String repoId = 'repo-1',
    String path = '/workspaces/ws-1/conversations/ch-1/repos/my-repo',
    String branch = 'feature/x',
    RepoIsolationBackend backend = RepoIsolationBackend.rift,
    String sourcePath = '/repos/my-repo',
    String? ticketId,
    DateTime? createdAt,
  }) {
    return IsolatedRepo(
      id: id,
      workspaceId: workspaceId,
      channelId: channelId,
      repoId: repoId,
      path: path,
      branch: branch,
      backend: backend,
      sourcePath: sourcePath,
      ticketId: ticketId,
      createdAt: createdAt ?? testCreatedAt,
    );
  }

  group('IsolatedRepo', () {

    group('constructor', () {
      test('creates with required fields', () {
        final repo = createRepo();
        expect(repo.id, 'iso-1');
        expect(repo.workspaceId, 'ws-1');
        expect(repo.channelId, 'ch-1');
        expect(repo.repoId, 'repo-1');
        expect(repo.path, '/workspaces/ws-1/conversations/ch-1/repos/my-repo');
        expect(repo.branch, 'feature/x');
        expect(repo.backend, RepoIsolationBackend.rift);
        expect(repo.sourcePath, '/repos/my-repo');
        expect(repo.ticketId, isNull);
        expect(repo.createdAt, testCreatedAt);
      });

      test('creates with optional ticketId', () {
        final repo = createRepo(ticketId: 'ticket-42');
        expect(repo.ticketId, 'ticket-42');
      });

      test('creates with gitWorktree backend', () {
        final repo = createRepo(backend: RepoIsolationBackend.gitWorktree);
        expect(repo.backend, RepoIsolationBackend.gitWorktree);
      });

      test('asserts workspaceId is not empty', () {
        expect(
          () => IsolatedRepo(
            id: 'x',
            workspaceId: '',
            channelId: 'ch',
            repoId: 'r',
            path: '/p',
            branch: 'main',
            backend: RepoIsolationBackend.rift,
            sourcePath: '/s',
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts channelId is not empty', () {
        expect(
          () => IsolatedRepo(
            id: 'x',
            workspaceId: 'ws',
            channelId: '',
            repoId: 'r',
            path: '/p',
            branch: 'main',
            backend: RepoIsolationBackend.rift,
            sourcePath: '/s',
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts repoId is not empty', () {
        expect(
          () => IsolatedRepo(
            id: 'x',
            workspaceId: 'ws',
            channelId: 'ch',
            repoId: '',
            path: '/p',
            branch: 'main',
            backend: RepoIsolationBackend.rift,
            sourcePath: '/s',
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', () {
        final a = createRepo();
        final b = createRepo();
        expect(a, equals(b));
      });

      test('== returns true for same instance', () {
        final repo = createRepo();
        expect(repo, equals(repo));
      });

      test('== returns false for different id', () {
        final a = createRepo(id: 'iso-1');
        final b = createRepo(id: 'iso-2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different workspaceId', () {
        final a = createRepo(workspaceId: 'ws-1');
        final b = createRepo(workspaceId: 'ws-2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different channelId', () {
        final a = createRepo(channelId: 'ch-1');
        final b = createRepo(channelId: 'ch-2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different repoId', () {
        final a = createRepo(repoId: 'repo-1');
        final b = createRepo(repoId: 'repo-2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different path', () {
        final a = createRepo(path: '/a');
        final b = createRepo(path: '/b');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different branch', () {
        final a = createRepo(branch: 'main');
        final b = createRepo(branch: 'dev');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different backend', () {
        final a = createRepo(backend: RepoIsolationBackend.rift);
        final b = createRepo(backend: RepoIsolationBackend.gitWorktree);
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different sourcePath', () {
        final a = createRepo(sourcePath: '/s1');
        final b = createRepo(sourcePath: '/s2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different ticketId', () {
        final a = createRepo(ticketId: 't1');
        final b = createRepo(ticketId: 't2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false when one has ticketId and other is null', () {
        final a = createRepo(ticketId: 't1');
        final b = createRepo();
        expect(a, isNot(equals(b)));
      });

      test('== returns false for non-IsolatedRepo', () {
        final repo = createRepo();
        expect(repo, isNot(equals('not a repo')));
      });

      test('hashCode matches for equal instances', () {
        final a = createRepo();
        final b = createRepo();
        expect(a.hashCode, equals(b.hashCode));
      });

      test('hashCode differs for different instances', () {
        final a = createRepo(id: 'iso-1');
        final b = createRepo(id: 'iso-2');
        expect(a.hashCode, isNot(equals(b.hashCode)));
      });
    });

    group('copyWith', () {
      test('returns identical copy with no arguments', () {
        final repo = createRepo();
        final copy = repo.copyWith();
        expect(copy, equals(repo));
        expect(copy.hashCode, equals(repo.hashCode));
      });

      test('updates id', () {
        final repo = createRepo();
        final copy = repo.copyWith(id: 'new-id');
        expect(copy.id, 'new-id');
        expect(copy.workspaceId, repo.workspaceId);
      });

      test('updates workspaceId', () {
        final repo = createRepo();
        final copy = repo.copyWith(workspaceId: 'ws-2');
        expect(copy.workspaceId, 'ws-2');
      });

      test('updates channelId', () {
        final repo = createRepo();
        final copy = repo.copyWith(channelId: 'ch-2');
        expect(copy.channelId, 'ch-2');
      });

      test('updates repoId', () {
        final repo = createRepo();
        final copy = repo.copyWith(repoId: 'repo-2');
        expect(copy.repoId, 'repo-2');
      });

      test('updates path', () {
        final repo = createRepo();
        final copy = repo.copyWith(path: '/new/path');
        expect(copy.path, '/new/path');
      });

      test('updates branch', () {
        final repo = createRepo();
        final copy = repo.copyWith(branch: 'dev');
        expect(copy.branch, 'dev');
      });

      test('updates backend', () {
        final repo = createRepo();
        final copy = repo.copyWith(backend: RepoIsolationBackend.gitWorktree);
        expect(copy.backend, RepoIsolationBackend.gitWorktree);
      });

      test('updates sourcePath', () {
        final repo = createRepo();
        final copy = repo.copyWith(sourcePath: '/new-source');
        expect(copy.sourcePath, '/new-source');
      });

      test('updates ticketId', () {
        final repo = createRepo();
        final copy = repo.copyWith(ticketId: 'ticket-99');
        expect(copy.ticketId, 'ticket-99');
      });
      test('copyWith keeps ticketId when passing null', () {
        // copyWith uses ?? so passing null keeps the old value
        final repo = createRepo(ticketId: 'ticket-1');
        final copy = repo.copyWith(ticketId: null);
        expect(copy.ticketId, 'ticket-1');
      });

      test('updates createdAt', () {
        final repo = createRepo();
        final newDate = DateTime(2025, 1, 1);
        final copy = repo.copyWith(createdAt: newDate);
        expect(copy.createdAt, newDate);
      });

      test('does not mutate original', () {
        final repo = createRepo();
        repo.copyWith(branch: 'changed');
        expect(repo.branch, 'feature/x');
      });

      test('chaining copyWith calls', () {
        final repo = createRepo();
        final copy = repo
            .copyWith(branch: 'dev')
            .copyWith(backend: RepoIsolationBackend.gitWorktree);
        expect(copy.branch, 'dev');
        expect(copy.backend, RepoIsolationBackend.gitWorktree);
      });
    });
  });
}
