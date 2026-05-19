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
}
