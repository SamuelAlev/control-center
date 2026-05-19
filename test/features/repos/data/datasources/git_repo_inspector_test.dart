import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
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

  group('parseForgeRemote', () {
    test('parses ssh URL', () {
      final result = parseForgeRemote('git@github.com:owner/repo.git');
      expect(result, isNotNull);
      expect(result!.forge, ForgeHost.github);
      expect(result.owner, 'owner');
      expect(result.name, 'repo');
    });

    test('parses https URL', () {
      final result = parseForgeRemote('https://github.com/owner/repo.git');
      expect(result, isNotNull);
      expect(result!.forge, ForgeHost.github);
      expect(result.owner, 'owner');
      expect(result.name, 'repo');
    });

    test('parses https URL without .git', () {
      final result = parseForgeRemote('https://github.com/owner/repo');
      expect(result, isNotNull);
      expect(result!.owner, 'owner');
      expect(result.name, 'repo');
    });

    test('parses ssh URL without .git', () {
      final result = parseForgeRemote('git@github.com:owner/repo');
      expect(result, isNotNull);
      expect(result!.owner, 'owner');
      expect(result.name, 'repo');
    });

    test('resolves a gitlab remote to the gitlab forge', () {
      final result = parseForgeRemote('https://gitlab.com/owner/repo');
      expect(result, isNotNull);
      expect(result!.forge, ForgeHost.gitlab);
      expect(result.owner, 'owner');
      expect(result.name, 'repo');
    });

    test('resolves a bitbucket remote to the bitbucket forge', () {
      final result = parseForgeRemote('git@bitbucket.org:team/repo.git');
      expect(result, isNotNull);
      expect(result!.forge, ForgeHost.bitbucket);
      expect(result.owner, 'team');
      expect(result.name, 'repo');
    });

    test('returns null for empty string', () {
      expect(parseForgeRemote(''), isNull);
    });

    test('returns null for an unsupported host', () {
      expect(parseForgeRemote('https://git.example.com/owner/repo'), isNull);
    });

    test('parses URL with trailing slash', () {
      final result = parseForgeRemote('https://github.com/owner/repo/');
      expect(result, isNotNull);
      expect(result!.owner, 'owner');
      expect(result.name, 'repo');
    });

    test('parses URL with org repo naming', () {
      final result = parseForgeRemote('git@github.com:my-org/my-repo.git');
      expect(result, isNotNull);
      expect(result!.owner, 'my-org');
      expect(result.name, 'my-repo');
    });
  });

  group('GitRepoInfo', () {
    test('equality works', () {
      const a = GitRepoInfo(
        path: '/path',
        forge: ForgeHost.github,
        owner: 'owner',
        repoName: 'repo',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/path',
        forge: ForgeHost.github,
        owner: 'owner',
        repoName: 'repo',
        branch: 'main',
      );
      expect(a, equals(b));
    });

    test('unequal branches differ', () {
      const a = GitRepoInfo(
        path: '/path',
        forge: ForgeHost.github,
        owner: 'owner',
        repoName: 'repo',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/path',
        forge: ForgeHost.github,
        owner: 'owner',
        repoName: 'repo',
        branch: 'develop',
      );
      expect(a, isNot(equals(b)));
    });

    test('the same coordinate on two forges is not the same repo', () {
      const a = GitRepoInfo(
        path: '/path',
        forge: ForgeHost.github,
        owner: 'owner',
        repoName: 'repo',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/path',
        forge: ForgeHost.gitlab,
        owner: 'owner',
        repoName: 'repo',
        branch: 'main',
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
