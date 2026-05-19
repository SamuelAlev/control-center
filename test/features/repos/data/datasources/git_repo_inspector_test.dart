import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitRepoInspector', () {
    test('creates const instance', () {
      const inspector = GitRepoInspector();
      expect(inspector, isNotNull);
    });

    test('throws GitRepoInspectionException for non-existent path', () async {
      const inspector = GitRepoInspector();
      await expectLater(
        inspector.inspect('/tmp/non_existent_path_12345'),
        throwsA(isA<GitRepoInspectionException>()),
      );
    });
  });

  group('parseGitHubRemote', () {
    test('parses ssh URL', () {
      final result = parseGitHubRemote('git@github.com:owner/repo.git');
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('parses https URL', () {
      final result =
          parseGitHubRemote('https://github.com/owner/repo.git');
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('parses https URL without .git', () {
      final result =
          parseGitHubRemote('https://github.com/owner/repo');
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('parses ssh URL without .git', () {
      final result =
          parseGitHubRemote('git@github.com:owner/repo');
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('returns null for non-github URL', () {
      final result = parseGitHubRemote('https://gitlab.com/owner/repo');
      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = parseGitHubRemote('');
      expect(result, isNull);
    });

    test('parses URL with trailing slash', () {
      final result =
          parseGitHubRemote('https://github.com/owner/repo/');
      expect(result, isNotNull);
      expect(result!.$1, 'owner');
      expect(result.$2, 'repo');
    });

    test('parses URL with org repo naming', () {
      final result = parseGitHubRemote(
        'git@github.com:my-org/my-repo.git',
      );
      expect(result, isNotNull);
      expect(result!.$1, 'my-org');
      expect(result.$2, 'my-repo');
    });
  });

  group('GitRepoInfo', () {
    test('equality works', () {
      const a = GitRepoInfo(
        path: '/path',
        owner: 'owner',
        repoName: 'repo',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/path',
        owner: 'owner',
        repoName: 'repo',
        branch: 'main',
      );
      expect(a, equals(b));
    });

    test('unequal branches differ', () {
      const a = GitRepoInfo(
        path: '/path',
        owner: 'owner',
        repoName: 'repo',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/path',
        owner: 'owner',
        repoName: 'repo',
        branch: 'develop',
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('GitRepoInspectionException', () {
    test('toString returns message', () {
      const ex = GitRepoInspectionException('test error');
      expect(ex.toString(), 'test error');
      expect(ex.message, 'test error');
    });

    test('different messages are unequal', () {
      const a = GitRepoInspectionException('error a');
      const b = GitRepoInspectionException('error b');
      expect(a.message, isNot(b.message));
    });
  });

  group('GitRepoInspector additional', () {
    test('const constructor works', () {
      const inspector = GitRepoInspector();
      expect(inspector, isA<GitRepoInspector>());
    });

    test('inspect throws on non-git directory', () async {
      const inspector = GitRepoInspector();
      expect(
        () => inspector.inspect('/tmp'),
        throwsA(isA<GitRepoInspectionException>()),
      );
    });
  });
}
