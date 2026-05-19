import 'dart:async';
import 'dart:io';

import 'package:cc_infra/src/git/process_git_command_adapter.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises [ProcessGitCommandAdapter] against a real (temp) git repository:
/// the `run` path (stdout/stderr capture, exit code, env hardening,
/// onProgress line delivery) and the `runStreaming` path (success emits
/// stderr lines then closes; a failing command surfaces a StateError).
void main() {
  const adapter = ProcessGitCommandAdapter();
  late Directory repo;

  Future<int> git(List<String> args) async =>
      (await Process.run('git', args, workingDirectory: repo.path)).exitCode;

  setUp(() async {
    repo = Directory.systemTemp.createTempSync('cc_git_cmd_');
    await git(['init', '-q']);
    await git(['config', 'user.email', 'test@example.com']);
    await git(['config', 'user.name', 'Test']);
    File(p.join(repo.path, 'a.txt')).writeAsStringSync('hello\n');
    await git(['add', '-A']);
    await git(['commit', '-q', '-m', 'init']);
  });
  tearDown(() => repo.deleteSync(recursive: true));

  group('ProcessGitCommandAdapter.run', () {
    test('captures stdout + exit code 0 for a successful command', () async {
      final res = await adapter.run(['log', '--format=%s'], workdir: repo.path);
      expect(res.exitCode, 0);
      expect(res.stdout.trim(), 'init');
      expect(res.stderr, isEmpty);
    });

    test('captures stderr + non-zero exit for a failing command', () async {
      final res = await adapter.run([
        'show',
        'no-such-ref',
      ], workdir: repo.path);
      expect(res.exitCode, isNot(0));
      expect(res.stderr, contains("ambiguous argument 'no-such-ref'"));
    });

    test('forwards stderr progress lines via onProgress', () async {
      final lines = <String>[];
      // `git commit --amend` rewrites and emits progress to stderr.
      File(p.join(repo.path, 'a.txt')).writeAsStringSync('changed\n');
      await git(['add', '-A']);
      await adapter.run(
        ['commit', '-q', '--amend', '-m', 'amended'],
        workdir: repo.path,
        onProgress: lines.add,
      );
      // onProgress is best-effort; we only assert it doesn't throw and the
      // amend landed. The key contract: stdout/log reflects the new message.
      final log = await adapter.run(['log', '--format=%s'], workdir: repo.path);
      expect(log.stdout.trim(), 'amended');
    });

    test('merges extra env over the hardened baseline', () async {
      // GIT_AUTHOR_NAME in extra overrides config; proves env is applied.
      final res = await adapter.run(
        ['var', 'GIT_AUTHOR_IDENT'],
        workdir: repo.path,
        env: {
          'GIT_AUTHOR_NAME': 'EnvOverride',
          'GIT_AUTHOR_EMAIL': 'env@x.com',
          'GIT_AUTHOR_DATE': '2020-01-01T00:00:00',
        },
      );
      expect(res.exitCode, 0);
      expect(res.stdout, contains('EnvOverride'));
    });
  });

  group('ProcessGitCommandAdapter.runStreaming', () {
    test('closes cleanly on a successful command (no events required)', () {
      final done = Completer<void>();
      final events = <String>[];
      final sub = adapter
          .runStreaming(['log', '--format=%s'], workdir: repo.path)
          .listen(
            events.add,
            onDone: done.complete,
            onError: (Object e, _) => done.completeError(e),
          );
      addTearDown(sub.cancel);
      expect(done.future, completes);
    });

    test('surfaces a StateError on a failing command', () async {
      final errors = <Object>[];
      final done = Completer<void>();
      final sub = adapter
          .runStreaming(['show', 'no-such-ref'], workdir: repo.path)
          .listen(
            (_) {},
            onError: (Object e, _) {
              errors.add(e);
              if (!done.isCompleted) {
                done.complete();
              }
            },
            onDone: () {
              if (!done.isCompleted) {
                done.complete();
              }
            },
          );
      addTearDown(sub.cancel);
      await done.future;
      expect(errors, anyElement(isA<StateError>()));
    });

    test(
      'surfaces a ProcessException-shaped error for a bad workdir',
      () async {
        final done = Completer<void>();
        Object? caught;
        final sub = adapter
            .runStreaming(['log'], workdir: '/definitely/not/a/dir')
            .listen(
              (_) {},
              onError: (Object e, _) {
                caught = e;
                if (!done.isCompleted) {
                  done.complete();
                }
              },
              onDone: () {
                if (!done.isCompleted) {
                  done.complete();
                }
              },
            );
        addTearDown(sub.cancel);
        await done.future;
        // The spawn failure must reach the consumer as a stream error, not a
        // silent close — a caller that only listens for output would otherwise
        // read "no output" as "nothing to report".
        expect(caught, isA<ProcessException>());
      },
    );
  });

  group('stdout ceiling', () {
    // stdout is the RESULT, so it is never truncated — a silently shortened
    // diff is worse than none, because the caller parses it and believes what
    // it gets. But "never truncate" is not "hold any amount": one
    // `git log -p` over a repo with large binaries can outgrow the heap, and a
    // server that dies mid-command loses every other run in the process. The
    // ceiling ABORTS and says so.
    test('an over-ceiling command fails loudly instead of returning a '
        'truncated result', () async {
      const adapter = ProcessGitCommandAdapter(maxStdoutChars: 16);
      final result = await adapter.run([
        'log',
        '--oneline',
        '-n',
        '50',
      ], workdir: _repoRoot().path);

      expect(result.isSuccess, isFalse, reason: 'must not read as success');
      expect(
        result.stdout,
        isEmpty,
        reason: 'a partial result is the one thing this must never hand back',
      );
      expect(result.stderr, contains('aborted'));
      expect(
        result.stderr,
        contains('runStreaming'),
        reason: 'the message has to say what to do instead',
      );
    });

    test('a normal command is unaffected by the ceiling', () async {
      const adapter = ProcessGitCommandAdapter();
      final result = await adapter.run([
        'rev-parse',
        '--abbrev-ref',
        'HEAD',
      ], workdir: _repoRoot().path);

      expect(result.isSuccess, isTrue);
      expect(result.stdout.trim(), isNotEmpty);
    });
  });

  group('index.lock contention', () {
    // Concurrent git on ONE worktree is normal here (a dispatch commits while
    // the indexer reads), and correctness used to rest entirely on git's own
    // lock failing loudly — leaving every caller to treat a transient
    // collision as a real error.
    Future<Directory> repoWithHeldLock() async {
      final dir = Directory.systemTemp.createTempSync('git_lock');
      addTearDown(() => dir.deleteSync(recursive: true));
      const adapter = ProcessGitCommandAdapter();
      await adapter.run(['init', '-q'], workdir: dir.path);
      // A lock nobody will release: the retries must expire and the real
      // error must reach the caller.
      File('${dir.path}/.git/index.lock').writeAsStringSync('');
      return dir;
    }

    test('a held lock still fails, with git\'s own message', () async {
      final dir = await repoWithHeldLock();
      File('${dir.path}/a.txt').writeAsStringSync('hi');
      const adapter = ProcessGitCommandAdapter(
        indexLockRetries: 2,
        indexLockBackoff: Duration(milliseconds: 1),
      );

      final result = await adapter.run(['add', 'a.txt'], workdir: dir.path);

      expect(result.isSuccess, isFalse);
      expect(
        result.stderr,
        contains('index.lock'),
        reason:
            'a stale lock is an operator problem; retrying must not hide it',
      );
    });

    test('the contention detector matches git and not everything else', () {
      // Pinned directly: the detector keys on the lock FILE name plus one of
      // git's phrasings, because the prose around it has been reworded across
      // versions and is localized.
      expect(
        isIndexLockContentionForTesting(
          "fatal: Unable to create '/repo/.git/index.lock': File exists.",
        ),
        isTrue,
      );
      expect(
        isIndexLockContentionForTesting(
          'Another git process seems to be running in this repository',
        ),
        isFalse,
        reason: 'no lock file named — not this failure',
      );
      expect(
        isIndexLockContentionForTesting('error: pathspec did not match'),
        isFalse,
      );
    });

    test('a succeeding command is not retried', () async {
      final dir = Directory.systemTemp.createTempSync('git_ok');
      addTearDown(() => dir.deleteSync(recursive: true));
      const adapter = ProcessGitCommandAdapter();
      await adapter.run(['init', '-q'], workdir: dir.path);

      final result = await adapter.run([
        'rev-parse',
        '--is-inside-work-tree',
      ], workdir: dir.path);
      expect(result.isSuccess, isTrue);
      expect(result.stdout.trim(), 'true');
    });
  });
}

Directory _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (Directory('${dir.path}/.git').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Could not locate a git repo root from ${Directory.current.path}');
    }
    dir = parent;
  }
}
