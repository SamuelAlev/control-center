@TestOn('mac-os || linux')
library;

import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_natives/cc_natives.dart' show DartFileSearch, IsolatedGit;
import 'package:cc_server_core/src/repo_ide_data_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Git the server runs in a tree an agent or a pull request can write never
/// runs a program that tree chose: no hook (wherever `core.hooksPath` points),
/// no editor, prompt, `ext::` transport or signing program from its config.
void main() {
  late Directory tmp;
  late String marks;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cc-ide-hooks-');
    marks = p.join(tmp.path, 'marks');
    Directory(marks).createSync();
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  /// What ran, by the names the planted programs wrote.
  List<String> ran() =>
      [for (final f in Directory(marks).listSync()) p.basename(f.path)]..sort();

  /// A program that records [name] when anything runs it.
  String planted(String name) {
    final script = File(p.join(tmp.path, 'bin', name))
      ..createSync(recursive: true)
      ..writeAsStringSync('#!/bin/sh\ntouch "$marks/$name"\nexit 0\n');
    Process.runSync('chmod', ['755', script.path]);
    return script.path;
  }

  /// The fixture's own git: the test's, never the developer's config, and
  /// never the planted hooks.
  Future<String> git(List<String> args, String dir) async {
    final r = await Process.run(
      'git',
      ['-c', 'core.hooksPath=/dev/null', ...args],
      workingDirectory: dir,
      environment: const {
        'GIT_CONFIG_GLOBAL': '/dev/null',
        'GIT_CONFIG_NOSYSTEM': '1',
      },
    );
    if (r.exitCode != 0) {
      throw StateError('git ${args.join(' ')} failed: ${r.stderr}');
    }
    return (r.stdout as String).trim();
  }

  Future<void> identity(String dir) async {
    await git(['config', 'user.email', 'test@example.com'], dir);
    await git(['config', 'user.name', 'Test'], dir);
    await git(['config', 'commit.gpgsign', 'false'], dir);
  }

  const hookNames = [
    'pre-commit',
    'prepare-commit-msg',
    'commit-msg',
    'post-commit',
    'pre-rebase',
    'post-rewrite',
    'post-checkout',
    'post-merge',
    'pre-push',
    'reference-transaction',
    'pre-auto-gc',
    'post-index-change',
  ];

  /// Hooks in `.git/hooks`, and the same hooks in a directory inside the
  /// tree that the repository's config names as `core.hooksPath`.
  Future<void> plantHooks(String wt) async {
    final inTree = Directory(p.join(wt, '.tools', 'hooks'))
      ..createSync(recursive: true);
    for (final name in hookNames) {
      for (final dir in [p.join(wt, '.git', 'hooks'), inTree.path]) {
        final hook = File(p.join(dir, name))
          ..createSync(recursive: true)
          ..writeAsStringSync('#!/bin/sh\ntouch "$marks/$name"\nexit 0\n');
        Process.runSync('chmod', ['755', hook.path]);
      }
    }
    await git(['config', 'core.hooksPath', inTree.path], wt);
  }

  /// A worktree with an `origin` that already has its `main`, and a second
  /// clone that pushed one more commit there.
  Future<String> worktree() async {
    final wt = p.join(tmp.path, 'wt');
    File(p.join(wt, 'src', 'app.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}\n');
    await git(['init', '-q', '-b', 'main'], wt);
    await identity(wt);
    await git(['add', '-A'], wt);
    await git(['commit', '-q', '-m', 'init'], wt);
    final origin = p.join(tmp.path, 'origin.git');
    Directory(origin).createSync();
    await git(['init', '-q', '--bare', '-b', 'main'], origin);
    await git(['remote', 'add', 'origin', origin], wt);
    await git(['push', '-q', '-u', 'origin', 'HEAD:refs/heads/main'], wt);

    final other = p.join(tmp.path, 'other');
    await git(['clone', '-q', origin, other], tmp.path);
    await identity(other);
    File(p.join(other, 'README.md')).writeAsStringSync('upstream\n');
    await git(['add', '-A'], other);
    await git(['commit', '-q', '-m', 'upstream'], other);
    await git(['push', '-q', 'origin', 'HEAD:refs/heads/main'], other);
    return wt;
  }

  RepoIdeDataService service(String wt) => RepoIdeDataService(
    repoRepository: _Repos({
      'repo1': Repo(
        id: 'repo1',
        name: 'repo1',
        path: wt,
        remoteOwner: 'owner',
        remoteName: 'repo1',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    }),
    workspaceRepository: _Workspaces(),
    isolatedRepoRepository: _Worktrees(wt),
    fileSearch: DartFileSearch(),
    githubToken:
        ({
          required workspaceId,
          required owner,
          required repo,
          actingUserId,
          write = false,
        }) async => null,
  );

  group('an IDE commit, sync and checkout run no repository hook', () {
    late String wt;
    late RepoIdeDataService svc;

    setUp(() async {
      wt = await worktree();
      await plantHooks(wt);
      svc = service(wt);
    });

    test('commit and push', () async {
      File(p.join(wt, 'src', 'app.dart')).writeAsStringSync('// edited\n');
      final res = await svc.commitAndPush(
        workspaceId: 'ws',
        spaceId: 'ch',
        repoId: 'repo1',
        message: 'edit app',
        paths: const ['src/app.dart'],
        push: false,
      );
      expect(res?['committed'], isTrue, reason: '$res');
      expect(ran(), isEmpty);
    });

    test('sync: status, fetch, rebase and push', () async {
      File(p.join(wt, 'notes.txt')).writeAsStringSync('local\n');
      await git(['add', '-A'], wt);
      await git(['commit', '-q', '-m', 'local'], wt);

      final res = await svc.syncBranch(
        workspaceId: 'ws',
        spaceId: 'ch',
        repoId: 'repo1',
      );

      expect(res?['pulled'], isTrue, reason: '$res');
      expect(res?['pushed'], isTrue, reason: '$res');
      expect(ran(), isEmpty);
      expect(
        File(p.join(wt, 'README.md')).existsSync(),
        isTrue,
        reason: 'the upstream commit was rebased onto',
      );
    });

    test('checkout of a new branch', () async {
      final res = await svc.checkoutBranch(
        workspaceId: 'ws',
        spaceId: 'ch',
        repoId: 'repo1',
        branch: 'feature',
        create: true,
      );
      expect(res, isNotNull);
      expect(ran(), isEmpty);
    });
  });

  group('server git runs no program the repository config chose', () {
    late String repo;

    setUp(() async {
      repo = p.join(tmp.path, 'repo');
      Directory(repo).createSync();
      await git(['init', '-q', '-b', 'main'], repo);
      await identity(repo);
      await git(['commit', '-q', '--allow-empty', '-m', 'init'], repo);
    });

    Future<ProcessResult> server(List<String> args, {String? stdin}) async {
      if (stdin == null) {
        return IsolatedGit.run(args, workingDirectory: repo);
      }
      final process = await IsolatedGit.start(args, workingDirectory: repo);
      process.stdin.write(stdin);
      await process.stdin.close();
      final out = await process.stdout.transform(utf8.decoder).join();
      final err = await process.stderr.transform(utf8.decoder).join();
      return ProcessResult(process.pid, await process.exitCode, out, err);
    }

    test('an editor', () async {
      await git(['config', 'core.editor', planted('editor')], repo);
      await git([
        'config',
        'sequence.editor',
        planted('sequence-editor'),
      ], repo);
      final res = await server(['commit', '--allow-empty']);
      expect(res.exitCode, isNot(0), reason: 'no editor, no message');
      expect(ran(), isEmpty);
    });

    test('a signing program', () async {
      await git(['config', 'commit.gpgsign', 'true'], repo);
      await git(['config', 'gpg.format', 'ssh'], repo);
      await git(['config', 'user.signingkey', 'key::ssh-ed25519 AAAA'], repo);
      await git(['config', 'gpg.ssh.program', planted('ssh-signer')], repo);
      await git(['config', 'gpg.program', planted('gpg')], repo);
      final res = await server(['commit', '--allow-empty', '-m', 'x']);
      expect(res.exitCode, 0, reason: '${res.stderr}');
      expect(ran(), isEmpty);
      final raw = await git(['cat-file', 'commit', 'HEAD'], repo);
      expect(raw, isNot(contains('gpgsig')));
    });

    test('a credential prompt', () async {
      await git(['config', 'core.askPass', planted('askpass')], repo);
      final res = await server([
        'credential',
        'fill',
      ], stdin: 'protocol=https\nhost=example.com\n\n');
      expect(res.exitCode, isNot(0), reason: 'nothing may answer');
      expect(ran(), isEmpty);
    });

    test('an ext:: remote', () async {
      await git(['config', 'protocol.ext.allow', 'always'], repo);
      final command = planted('ext-transport');
      final res = await server(['ls-remote', 'ext::$command']);
      expect(res.exitCode, isNot(0));
      expect('${res.stderr}', contains("transport 'ext' not allowed"));
      expect(ran(), isEmpty);
    });

    test('hooks wherever core.hooksPath points', () async {
      await plantHooks(repo);
      final res = await server(['commit', '--allow-empty', '-m', 'x']);
      expect(res.exitCode, 0, reason: '${res.stderr}');
      expect(ran(), isEmpty);
    });

    test('an external diff program', () async {
      final file = File(p.join(repo, 'a.txt'))..writeAsStringSync('one\n');
      await git(['add', 'a.txt'], repo);
      await git(['commit', '-q', '-m', 'a'], repo);
      file.writeAsStringSync('two\n');
      await git(['config', 'diff.external', planted('external-diff')], repo);
      File(p.join(repo, '.gitattributes')).writeAsStringSync('*.txt diff=x\n');
      await git(['config', 'diff.x.command', planted('driver-diff')], repo);
      final res = await server(['diff']);
      expect(res.exitCode, 0, reason: '${res.stderr}');
      expect('${res.stdout}', contains('+two'), reason: "git's own diff");
      // Behind a global option, and against the index.
      final behindC = await server(['-C', repo, 'diff', 'HEAD']);
      expect(
        '${behindC.stdout}',
        contains('+two'),
        reason: '${behindC.stderr}',
      );
      await git(['add', 'a.txt'], repo);
      final staged = await server(['diff', '--cached']);
      expect('${staged.stdout}', contains('+two'), reason: '${staged.stderr}');
      expect(ran(), isEmpty);
    });
  });
}

class _Repos implements RepoRepository {
  _Repos(this._byId);

  final Map<String, Repo> _byId;

  @override
  Future<Repo?> getById(String workspaceId, String id) async => _byId[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Workspaces implements WorkspaceRepository {
  @override
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) =>
      Future.value(workspaceId == 'ws' && repoId == 'repo1');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Worktrees implements IsolatedRepoRepository {
  _Worktrees(this.path);

  final String path;

  @override
  Future<List<IsolatedRepo>> forSpace(String workspaceId, String spaceId) =>
      Future.value([
        if (workspaceId == 'ws' && spaceId == 'ch')
          IsolatedRepo(
            id: 'wt-repo1',
            workspaceId: 'ws',
            spaceId: 'ch',
            repoId: 'repo1',
            backend: RepoIsolationBackend.gitWorktree,
            path: path,
            branch: 'main',
            sourcePath: '/src/repo1',
            createdAt: DateTime(2026),
          ),
      ]);

  @override
  Future<void> upsert(IsolatedRepo repo) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
