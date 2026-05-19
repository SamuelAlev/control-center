import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitRepoInfo constructor', () {
    test('creates with all fields', () {
      const info = GitRepoInfo(
        path: '/home/user/repo',
        forge: ForgeHost.github,
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
        forge: ForgeHost.github,
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
        forge: ForgeHost.github,
        owner: 'o',
        repoName: 'r',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/p',
        forge: ForgeHost.github,
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
        forge: ForgeHost.github,
        owner: 'o',
        repoName: 'r',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/p2',
        forge: ForgeHost.github,
        owner: 'o',
        repoName: 'r',
        branch: 'main',
      );
      expect(a, isNot(equals(b)));
    });

    test('different branch makes unequal', () {
      const a = GitRepoInfo(
        path: '/p',
        forge: ForgeHost.github,
        owner: 'o',
        repoName: 'r',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/p',
        forge: ForgeHost.github,
        owner: 'o',
        repoName: 'r',
        branch: 'develop',
      );
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      const a = GitRepoInfo(
        path: '/p',
        forge: ForgeHost.github,
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

  group('parseForgeRemote', () {
    test('parses HTTPS URL', () {
      final result = parseForgeRemote('https://github.com/owner/repo.git');
      expect(result, isNotNull);
      expect(result!.forge, ForgeHost.github);
      expect(result.owner, 'owner');
      expect(result.name, 'repo');
    });

    test('parses HTTPS URL without .git suffix', () {
      final result = parseForgeRemote('https://github.com/owner/repo');
      expect(result, isNotNull);
      expect(result!.owner, 'owner');
      expect(result.name, 'repo');
    });

    test('parses SSH URL', () {
      final result = parseForgeRemote('git@github.com:owner/repo.git');
      expect(result, isNotNull);
      expect(result!.owner, 'owner');
      expect(result.name, 'repo');
    });

    test('parses URL with trailing slash', () {
      final result = parseForgeRemote('https://github.com/owner/repo/');
      expect(result, isNotNull);
      expect(result!.owner, 'owner');
      expect(result.name, 'repo');
    });

    test('resolves a GitLab URL to the GitLab forge', () {
      final result = parseForgeRemote('https://gitlab.com/owner/repo.git');
      expect(result, isNotNull);
      expect(result!.forge, ForgeHost.gitlab);
      expect(result.owner, 'owner');
      expect(result.name, 'repo');
    });

    test('returns null for empty string', () {
      expect(parseForgeRemote(''), isNull);
    });

    test('returns null for malformed URL', () {
      expect(parseForgeRemote('not-a-url'), isNull);
    });

    test('parses URL with colon separator', () {
      final result = parseForgeRemote('git@github.com:owner/repo');
      expect(result, isNotNull);
      expect(result!.owner, 'owner');
      expect(result.name, 'repo');
    });

    test('rejects extra path segments on a forge that does not nest', () {
      expect(parseForgeRemote('git@github.com:acme/team/project.git'), isNull);
    });

    test('keeps extra path segments on GitLab, which does nest', () {
      final result = parseForgeRemote('git@gitlab.com:acme/team/project.git');
      expect(result, isNotNull);
      expect(result!.owner, 'acme/team');
      expect(result.name, 'project');
    });

    test('parses URL with underscores in names', () {
      final result = parseForgeRemote(
        'https://github.com/team_name/repo_name.git',
      );
      expect(result, isNotNull);
      expect(result!.owner, 'team_name');
      expect(result.name, 'repo_name');
    });
  });

  group('GitRepoInfo hashCode', () {
    test('same fields produce same hashCode', () {
      const a = GitRepoInfo(
        path: '/repo',
        forge: ForgeHost.github,
        owner: 'org',
        repoName: 'name',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/repo',
        forge: ForgeHost.github,
        owner: 'org',
        repoName: 'name',
        branch: 'main',
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different fields produce different hashCode', () {
      const a = GitRepoInfo(
        path: '/repo',
        forge: ForgeHost.github,
        owner: 'org',
        repoName: 'name',
        branch: 'main',
      );
      const b = GitRepoInfo(
        path: '/repo',
        forge: ForgeHost.github,
        owner: 'org',
        repoName: 'other',
        branch: 'main',
      );
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });
}
