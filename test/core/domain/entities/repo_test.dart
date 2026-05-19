import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCreatedAt = DateTime(2024, 1, 1);
  final testUpdatedAt = DateTime(2024, 6, 1);

  Repo createRepo({
    String id = 'repo-1',
    String name = 'my-org/my-repo',
    String path = '/home/user/projects/my-repo',
    String githubOwner = 'my-org',
    String githubRepoName = 'my-repo',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Repo(
      id: id,
      name: name,
      path: path,
      githubOwner: githubOwner,
      githubRepoName: githubRepoName,
      createdAt: createdAt ?? testCreatedAt,
      updatedAt: updatedAt ?? testUpdatedAt,
    );
  }

  group('Repo', () {
    group('constructor', () {
      test('creates repo with required fields', () {
        final repo = Repo(
          id: 'repo-1',
          name: 'org/repo',
          path: '/path',
          githubOwner: 'org',
          githubRepoName: 'repo',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );
        expect(repo.id, 'repo-1');
        expect(repo.name, 'org/repo');
        expect(repo.path, '/path');
        expect(repo.githubOwner, 'org');
        expect(repo.githubRepoName, 'repo');
        expect(repo.createdAt, testCreatedAt);
        expect(repo.updatedAt, testUpdatedAt);
      });

      test('constructor asserts name is not empty', () {
        expect(
          () => Repo(
            id: 'r',
            name: '',
            path: '/path',
            githubOwner: 'org',
            githubRepoName: 'repo',
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('constructor asserts path is not empty', () {
        expect(
          () => Repo(
            id: 'r',
            name: 'org/repo',
            path: '',
            githubOwner: 'org',
            githubRepoName: 'repo',
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('getters', () {
      test('hasGitHubRemote returns true when owner and repo are present', () {
        final repo = createRepo(githubOwner: 'org', githubRepoName: 'repo');
        expect(repo.hasGitHubRemote, isTrue);
      });

      test('hasGitHubRemote returns false when githubOwner is empty', () {
        final repo = createRepo(
          githubOwner: '',
          githubRepoName: 'repo',
        );
        expect(repo.hasGitHubRemote, isFalse);
      });

      test('hasGitHubRemote returns false when githubRepoName is empty', () {
        final repo = createRepo(
          githubOwner: 'org',
          githubRepoName: '',
        );
        expect(repo.hasGitHubRemote, isFalse);
      });

      test('hasGitHubRemote returns false when both are empty', () {
        final repo = createRepo(
          githubOwner: '',
          githubRepoName: '',
        );
        expect(repo.hasGitHubRemote, isFalse);
      });

      test('fullName returns owner/repo when remote is present', () {
        final repo = createRepo(githubOwner: 'flutter', githubRepoName: 'flutter');
        expect(repo.fullName, 'flutter/flutter');
      });

      test('fullName returns path when remote is not present', () {
        final repo = createRepo(
          githubOwner: '',
          githubRepoName: '',
          path: '/local/path/repo',
        );
        expect(repo.fullName, '/local/path/repo');
      });

      test('fullName returns path when githubOwner is missing', () {
        final repo = createRepo(
          githubOwner: '',
          githubRepoName: 'repo',
          path: '/local/repo',
        );
        expect(repo.fullName, '/local/repo');
      });

      test('fullName returns path when githubRepoName is missing', () {
        final repo = createRepo(
          githubOwner: 'org',
          githubRepoName: '',
          path: '/local/repo',
        );
        expect(repo.fullName, '/local/repo');
      });
    });

    group('== and hashCode', () {
      test('== returns true for same id', () {
        final r1 = createRepo(id: 'repo-1');
        final r2 = createRepo(id: 'repo-1', name: 'different-name');
        expect(r1, equals(r2));
      });

      test('== returns false for different id', () {
        expect(
          createRepo(id: 'a') == createRepo(id: 'b'),
          isFalse,
        );
      });

      test('== ignores non-id fields', () {
        final r1 = createRepo(id: 'repo-1', name: 'A');
        final r2 = createRepo(id: 'repo-1', name: 'B');
        expect(r1, equals(r2));
      });

      test('== (identical)', () {
        final repo = createRepo();
        expect(repo, equals(repo));
      });

      test('hashCode depends only on id', () {
        final r1 = createRepo(id: 'repo-1', name: 'A');
        final r2 = createRepo(id: 'repo-1', name: 'B');
        expect(r1.hashCode, equals(r2.hashCode));
      });

      test('hashCode differs for different ids', () {
        final r1 = createRepo(id: 'a');
        final r2 = createRepo(id: 'b');
        expect(r1.hashCode, isNot(equals(r2.hashCode)));
      });
    });

    group('copyWith', () {
      test('returns identical copy with no arguments', () {
        final repo = createRepo();
        final copy = repo.copyWith();
        expect(copy.id, repo.id);
        expect(copy.name, repo.name);
        expect(copy.path, repo.path);
        expect(copy.githubOwner, repo.githubOwner);
        expect(copy.githubRepoName, repo.githubRepoName);
        expect(copy.createdAt, repo.createdAt);
        expect(copy.updatedAt, repo.updatedAt);
      });

      test('updates id', () {
        final copy = createRepo().copyWith(id: 'new-id');
        expect(copy.id, 'new-id');
      });

      test('updates name', () {
        final copy = createRepo().copyWith(name: 'new-name');
        expect(copy.name, 'new-name');
      });

      test('updates path', () {
        final copy = createRepo().copyWith(path: '/new/path');
        expect(copy.path, '/new/path');
      });

      test('updates githubOwner', () {
        final copy = createRepo().copyWith(githubOwner: 'new-org');
        expect(copy.githubOwner, 'new-org');
      });

      test('updates githubRepoName', () {
        final copy = createRepo().copyWith(githubRepoName: 'new-repo');
        expect(copy.githubRepoName, 'new-repo');
      });

      test('updates createdAt', () {
        final newDate = DateTime(2025, 1, 1);
        final copy = createRepo().copyWith(createdAt: newDate);
        expect(copy.createdAt, newDate);
      });

      test('updates updatedAt', () {
        final newDate = DateTime(2025, 6, 1);
        final copy = createRepo().copyWith(updatedAt: newDate);
        expect(copy.updatedAt, newDate);
      });

      test('copyWith does not mutate original', () {
        final repo = createRepo(name: 'original');
        repo.copyWith(name: 'changed');
        expect(repo.name, 'original');
      });

      test('chaining copyWith calls', () {
        final repo = createRepo();
        final copy = repo
            .copyWith(name: 'new-name')
            .copyWith(githubOwner: 'new-org');
        expect(copy.name, 'new-name');
        expect(copy.githubOwner, 'new-org');
        expect(copy.id, repo.id);
      });

      test('copyWith preserves other fields unchanged', () {
        final repo = createRepo(
          id: 'repo-x',
          name: 'name-x',
          path: '/path-x',
        );
        final copy = repo.copyWith(name: 'staging');
        expect(copy.id, 'repo-x');
        expect(copy.name, 'staging');
        expect(copy.path, '/path-x');
      });
    });
  });
}
