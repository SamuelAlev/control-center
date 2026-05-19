import 'package:control_center/core/domain/entities/git_repo_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitRepoInfo constructor', () {
    test('creates with all fields', () {
      const info = GitRepoInfo(
        path: '/home/user/repo',
        owner: 'owner',
        repoName: 'repo',
        branch: 'main',
      );
      expect(info.path, '/home/user/repo');
      expect(info.owner, 'owner');
      expect(info.repoName, 'repo');
      expect(info.branch, 'main');
    });

    test('handles different branches', () {
      const info = GitRepoInfo(
        path: '/path',
        owner: 'o',
        repoName: 'r',
        branch: 'feature/test',
      );
      expect(info.branch, 'feature/test');
    });
  });

  group('GitRepoInfo == and hashCode', () {
    test('identical info are equal', () {
      const a = GitRepoInfo(
        path: '/p',
        owner: 'o',
        repoName: 'r',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/p',
        owner: 'o',
        repoName: 'r',
        branch: 'main',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different path makes unequal', () {
      const a = GitRepoInfo(
        path: '/p1',
        owner: 'o',
        repoName: 'r',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/p2',
        owner: 'o',
        repoName: 'r',
        branch: 'main',
      );
      expect(a, isNot(equals(b)));
    });

    test('different branch makes unequal', () {
      const a = GitRepoInfo(
        path: '/p',
        owner: 'o',
        repoName: 'r',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/p',
        owner: 'o',
        repoName: 'r',
        branch: 'develop',
      );
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      const a = GitRepoInfo(
        path: '/p',
        owner: 'o',
        repoName: 'r',
        branch: 'main',
      );
      expect(a, equals(a));
    });
  });

  group('GitRepoInspectionException', () {
    test('stores message and implements Exception', () {
      const exc = GitRepoInspectionException('Not a git repo');
      expect(exc, isA<Exception>());
      expect(exc.message, 'Not a git repo');
    });

    test('toString returns message', () {
      const exc = GitRepoInspectionException('Error occurred');
      expect(exc.toString(), 'Error occurred');
    });
  });

  group('parseGitHubRemote', () {
    test('parses HTTPS URL', () {
      final result = parseGitHubRemote(
        'https://github.com/owner/repo.git',
      );
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('parses HTTPS URL without .git suffix', () {
      final result = parseGitHubRemote(
        'https://github.com/owner/repo',
      );
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('parses SSH URL', () {
      final result = parseGitHubRemote(
        'git@github.com:owner/repo.git',
      );
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('parses URL with trailing slash', () {
      final result = parseGitHubRemote(
        'https://github.com/owner/repo/',
      );
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('returns null for non-GitHub URLs', () {
      final result = parseGitHubRemote(
        'https://gitlab.com/owner/repo.git',
      );
      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = parseGitHubRemote('');
      expect(result, isNull);
    });

    test('returns null for malformed URL', () {
      final result = parseGitHubRemote('not-a-url');
      expect(result, isNull);
    });

    test('parses URL with colon separator', () {
      final result = parseGitHubRemote(
        'git@github.com:owner/repo',
      );
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('parses URL with multiple path segments returns null', () {
      final result = parseGitHubRemote(
        'git@github.com:acme/team/project.git',
      );
      expect(result, isNull);
    });

    test('parses URL with underscores in names', () {
      final result = parseGitHubRemote(
        'https://github.com/team_name/repo_name.git',
      );
      expect(result, isNotNull);
      expect(result!.$1, 'team_name');
      expect(result.$2, 'repo_name');
    });
  });

  group('GitRepoInfo hashCode', () {
    test('same fields produce same hashCode', () {
      const a = GitRepoInfo(
        path: '/repo',
        owner: 'org',
        repoName: 'name',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/repo',
        owner: 'org',
        repoName: 'name',
        branch: 'main',
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different fields produce different hashCode', () {
      const a = GitRepoInfo(
        path: '/repo',
        owner: 'org',
        repoName: 'name',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/repo',
        owner: 'org',
        repoName: 'other',
        branch: 'main',
      );
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });
}
