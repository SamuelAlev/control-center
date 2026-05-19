import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GitRepoInfo createRepo({
    String path = '/home/user/project',
    ForgeHost forge = ForgeHost.github,
    String owner = 'acme',
    String repoName = 'my-repo',
    String branch = 'main',
  }) {
    return GitRepoInfo(
      path: path,
      forge: forge,
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
          forge: ForgeHost.github,
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

  group('parseForgeRemote', () {
    group('GitHub', () {
      test('parses HTTPS URL', () {
        final result = parseForgeRemote('https://github.com/owner/repo.git');
        expect(result, isNotNull);
        expect(result!.forge, ForgeHost.github);
        expect(result.owner, 'owner');
        expect(result.name, 'repo');
      });

      test('parses HTTPS URL without .git suffix', () {
        final result = parseForgeRemote('https://github.com/owner/repo');
        expect(result!.owner, 'owner');
        expect(result.name, 'repo');
      });

      test('parses SSH URL', () {
        final result = parseForgeRemote('git@github.com:owner/repo.git');
        expect(result!.forge, ForgeHost.github);
        expect(result.owner, 'owner');
        expect(result.name, 'repo');
      });

      test('parses SSH URL without .git suffix', () {
        final result = parseForgeRemote('git@github.com:owner/repo');
        expect(result!.owner, 'owner');
        expect(result.name, 'repo');
      });

      test('parses HTTPS URL with trailing slash', () {
        final result = parseForgeRemote('https://github.com/owner/repo/');
        expect(result!.owner, 'owner');
        expect(result.name, 'repo');
      });

      test('parses ssh:// scheme with an explicit port', () {
        final result = parseForgeRemote(
          'ssh://git@github.com:22/owner/repo.git',
        );
        expect(result!.forge, ForgeHost.github);
        expect(result.owner, 'owner');
        expect(result.name, 'repo');
      });

      test('rejects a deeper path — GitHub owners do not nest', () {
        // A tree/blob link, not a clone URL.
        expect(parseForgeRemote('https://github.com/o/r/tree/main'), isNull);
      });
    });

    group('GitLab', () {
      test('parses a flat namespace', () {
        final result = parseForgeRemote('https://gitlab.com/owner/repo.git');
        expect(result!.forge, ForgeHost.gitlab);
        expect(result.owner, 'owner');
        expect(result.name, 'repo');
      });

      test('keeps a nested namespace intact', () {
        final result = parseForgeRemote(
          'https://gitlab.com/group/subgroup/project.git',
        );
        expect(result!.forge, ForgeHost.gitlab);
        expect(result.owner, 'group/subgroup');
        expect(result.name, 'project');
      });

      test('keeps a deeply nested namespace intact over SSH', () {
        final result = parseForgeRemote('git@gitlab.com:a/b/c/d.git');
        expect(result!.owner, 'a/b/c');
        expect(result.name, 'd');
      });
    });

    group('Bitbucket', () {
      test('parses HTTPS URL', () {
        final result = parseForgeRemote(
          'https://bitbucket.org/workspace/repo.git',
        );
        expect(result!.forge, ForgeHost.bitbucket);
        expect(result.owner, 'workspace');
        expect(result.name, 'repo');
      });

      test('parses SSH URL', () {
        final result = parseForgeRemote('git@bitbucket.org:workspace/repo.git');
        expect(result!.forge, ForgeHost.bitbucket);
        expect(result.owner, 'workspace');
        expect(result.name, 'repo');
      });

      test('parses an HTTPS URL carrying a username', () {
        final result = parseForgeRemote(
          'https://someone@bitbucket.org/workspace/repo.git',
        );
        expect(result!.forge, ForgeHost.bitbucket);
        expect(result.owner, 'workspace');
        expect(result.name, 'repo');
      });
    });

    group('rejects', () {
      test('an empty string', () {
        expect(parseForgeRemote(''), isNull);
      });

      test('a malformed URL', () {
        expect(parseForgeRemote('not-a-url'), isNull);
      });

      test('an unsupported host', () {
        expect(parseForgeRemote('https://git.example.com/owner/repo'), isNull);
      });

      test('a host with no repository path', () {
        expect(parseForgeRemote('https://github.com/owner'), isNull);
      });
    });
  });
}
