import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GitRepoInfo createRepo({
    String path = '/home/user/project',
    String owner = 'acme',
    String repoName = 'my-repo',
    String branch = 'main',
  }) {
    return GitRepoInfo(
      path: path,
      owner: owner,
      repoName: repoName,
      branch: branch,
    );
  }

  group('GitRepoInfo', () {

    group('constructor', () {
      test('creates with all required fields', () {
        final info = createRepo();
        expect(info.path, '/home/user/project');
        expect(info.owner, 'acme');
        expect(info.repoName, 'my-repo');
        expect(info.branch, 'main');
      });

      test('creates with different values', () {
        const info = GitRepoInfo(
          path: '/tmp/workspace',
          owner: 'org',
          repoName: 'library',
          branch: 'feature/x',
        );
        expect(info.path, '/tmp/workspace');
        expect(info.owner, 'org');
        expect(info.repoName, 'library');
        expect(info.branch, 'feature/x');
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', () {
        final a = createRepo();
        final b = createRepo();
        expect(a, equals(b));
      });

      test('== returns true for same instance', () {
        final info = createRepo();
        expect(info, equals(info));
      });

      test('== returns false for different path', () {
        final a = createRepo(path: '/a');
        final b = createRepo(path: '/b');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different owner', () {
        final a = createRepo(owner: 'alice');
        final b = createRepo(owner: 'bob');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different repoName', () {
        final a = createRepo(repoName: 'repo-a');
        final b = createRepo(repoName: 'repo-b');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different branch', () {
        final a = createRepo(branch: 'main');
        final b = createRepo(branch: 'dev');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for non-GitRepoInfo', () {
        final info = createRepo();
        expect(info, isNot(equals('not a repo')));
      });

      test('hashCode matches for equal instances', () {
        final a = createRepo();
        final b = createRepo();
        expect(a.hashCode, equals(b.hashCode));
      });

      test('hashCode differs for different instances', () {
        final a = createRepo(owner: 'a');
        final b = createRepo(owner: 'b');
        expect(a.hashCode, isNot(equals(b.hashCode)));
      });
    });
  });

  group('GitRepoInspectionException', () {
    test('stores message', () {
      const exc = GitRepoInspectionException('bad remote');
      expect(exc.message, 'bad remote');
    });

    test('toString returns message', () {
      const exc = GitRepoInspectionException('bad remote');
      expect(exc.toString(), 'bad remote');
    });
  });

  group('parseGitHubRemote', () {
    test('parses HTTPS URL', () {
      final result = parseGitHubRemote('https://github.com/owner/repo.git');
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('parses HTTPS URL without .git suffix', () {
      final result = parseGitHubRemote('https://github.com/owner/repo');
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('parses SSH URL', () {
      final result = parseGitHubRemote('git@github.com:owner/repo.git');
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('parses SSH URL without .git suffix', () {
      final result = parseGitHubRemote('git@github.com:owner/repo');
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('parses HTTPS URL with trailing slash', () {
      final result = parseGitHubRemote('https://github.com/owner/repo/');
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('returns null for non-GitHub URL', () {
      expect(parseGitHubRemote('https://gitlab.com/owner/repo'), isNull);
    });

    test('returns null for empty string', () {
      expect(parseGitHubRemote(''), isNull);
    });

    test('returns null for malformed URL', () {
      expect(parseGitHubRemote('not-a-url'), isNull);
    });
  });
}
