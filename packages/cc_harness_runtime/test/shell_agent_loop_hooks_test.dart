import 'dart:io';

import 'package:cc_harness_runtime/src/shell_agent_loop_hooks.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises [ShellAgentLoopHooks] — the script-backed hook implementation.
/// Each hook shells out to a user script (JSON on stdin, bounded timeout) and
/// is best-effort: a missing/failed script never breaks the run and a
/// pre-tool non-zero exit DENIES the call. Uses real tiny shell scripts in a
/// temp dir so the spawn + stdin + exit-code path is exercised end-to-end.

/// Skip reason for tests that execute real `#!/bin/sh` hook scripts: Windows
/// cannot exec a shebang script (the GitHub runner's PATH `sh`/`bash` is the
/// WSL stub with no distro installed), so the script-backed hook CONTRACT is
/// only provable on POSIX here.
Object _shScriptsSkip() => Platform.isWindows
    ? 'hook scripts are #!/bin/sh files; no POSIX exec contract on Windows'
    : false;

/// The base environment [_Starts] gives every script, as a host launcher
/// gives its allowlisted one.
const _env = {'PATH': '/usr/bin:/bin'};

/// One start of a script, as [_Starts] saw it.
typedef _Start = ({
  String executable,
  List<String> args,
  Map<String, String>? environment,
});

/// Starts scripts the way a host launcher does (the script as its own
/// executable, no shell, [_env] as the base) and records each start.
class _Starts {
  final List<_Start> starts = [];

  Future<Process> call(
    String executable,
    List<String> args, {
    required String workingDirectory,
    Map<String, String>? environment,
  }) {
    starts.add((executable: executable, args: args, environment: environment));
    return Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      environment: {..._env, ...?environment},
      includeParentEnvironment: false,
    );
  }
}

void main() {
  late Directory dir;
  late _Starts start;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('shell_hooks_');
    start = _Starts();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// Writes an executable shell script and returns its path.
  String sh(String name, String body) {
    final file = File(p.join(dir.path, name))
      ..writeAsStringSync('#!/bin/sh\n$body\n');
    // The script is started as its own executable, so it must be one.
    // ignore: avoid_slow_async_io
    Process.runSync('chmod', ['+x', file.path]);
    return file.path;
  }

  group('ShellAgentLoopHooks — no scripts configured', () {
    test('all hooks are no-ops that allow every tool', () async {
      final hooks = ShellAgentLoopHooks(cwd: dir.path, start: start.call);
      await expectLater(hooks.onSessionStart(), completes);
      expect(await hooks.preToolUse('bash', {}), isTrue);
      await expectLater(
        hooks.postToolUse('bash', 'ok', isError: false),
        completes,
      );
    });
  });

  group('ShellAgentLoopHooks — session start', () {
    test('runs the session-start script (exit 0)', () async {
      final marker = p.join(dir.path, 'started.flag');
      final hooks = ShellAgentLoopHooks(
        cwd: dir.path,
        start: start.call,
        sessionStartScript: sh('on_start', 'touch "\$PWD/started.flag"'),
      );
      await hooks.onSessionStart();
      expect(File(marker).existsSync(), isTrue);
    });
  }, skip: _shScriptsSkip());

  group('ShellAgentLoopHooks — pre-tool gating', () {
    test('a pre-tool script exiting 0 allows the call', () async {
      final hooks = ShellAgentLoopHooks(
        cwd: dir.path,
        start: start.call,
        preToolScript: sh('pre_allow', 'exit 0'),
      );
      expect(await hooks.preToolUse('write', {'path': 'x'}), isTrue);
    });

    test('a pre-tool script exiting non-zero DENIES the call', () async {
      final hooks = ShellAgentLoopHooks(
        cwd: dir.path,
        start: start.call,
        preToolScript: sh('pre_deny', 'exit 5'),
      );
      expect(await hooks.preToolUse('write', {}), isFalse);
    });

    test('a missing script cannot be started, and denies', () async {
      final hooks = ShellAgentLoopHooks(
        cwd: dir.path,
        start: start.call,
        preToolScript: 'definitely-not-a-real-command-xyz',
      );
      expect(await hooks.preToolUse('write', {}), isFalse);
    });

    test('a chatty script is drained and answers before the timeout', () async {
      // ~1 MB on each pipe overflows any OS pipe buffer: undrained, the
      // script blocks on write until the timeout kills it and the call is
      // denied for a reason the script never chose.
      final hooks = ShellAgentLoopHooks(
        cwd: dir.path,
        start: start.call,
        preToolScript: sh(
          'chatty',
          'i=0; while [ \$i -lt 16000 ]; do '
              'echo "0123456789012345678901234567890123456789012345678901234567890"; '
              'echo "err err err err err err err err err err err err err err err" >&2; '
              'i=\$((i+1)); done; exit 0',
        ),
        timeout: const Duration(seconds: 20),
      );
      final watch = Stopwatch()..start();
      expect(await hooks.preToolUse('write', {}), isTrue);
      expect(watch.elapsed, lessThan(const Duration(seconds: 20)));
    });

    test(
      'a pre-tool script that cannot be spawned denies (fail closed)',
      () async {
        final hooks = ShellAgentLoopHooks(
          // A working directory that does not exist makes the spawn itself fail.
          cwd: p.join(dir.path, 'missing-dir'),
          start: start.call,
          preToolScript: sh('pre_allow2', 'exit 0'),
        );
        expect(await hooks.preToolUse('write', {}), isFalse);
      },
    );

    test('a hanging script is killed by the timeout and denies', () async {
      // A timed-out run returns -1 (not null), which the gate treats as deny.
      final hooks = ShellAgentLoopHooks(
        cwd: dir.path,
        start: start.call,
        preToolScript: sh('hang', 'sleep 30'),
        timeout: const Duration(milliseconds: 200),
      );
      expect(await hooks.preToolUse('write', {}), isFalse);
    });
  }, skip: _shScriptsSkip());

  group('ShellAgentLoopHooks — post-tool', () {
    test('runs the post-tool script with the result payload', () async {
      final marker = p.join(dir.path, 'post.flag');
      final hooks = ShellAgentLoopHooks(
        cwd: dir.path,
        start: start.call,
        postToolScript: sh('post', 'touch "\$PWD/post.flag"'),
      );
      await hooks.postToolUse('bash', 'done', isError: false);
      expect(File(marker).existsSync(), isTrue);
    });
  }, skip: _shScriptsSkip());

  group('ShellAgentLoopHooks — how a script starts', () {
    test('through the starter it is given, as itself, with no shell, no '
        'arguments and none of the run\'s environment', () async {
      final script = sh(
        'env_probe',
        'echo "\${CC_HOOK_PROBE:-none} \${HOME:-no-home}" > "\$PWD/env.txt"',
      );
      final hooks = ShellAgentLoopHooks(
        cwd: dir.path,
        start: start.call,
        sessionStartScript: script,
      );
      await hooks.onSessionStart();
      expect(start.starts, hasLength(1));
      final started = start.starts.single;
      expect(started.executable, script);
      expect(started.args, isEmpty);
      // Nothing of the run (gateway lease, forge or provider credentials):
      // the script sees only the starter's own base environment.
      expect(started.environment, isEmpty);
      expect(
        File(p.join(dir.path, 'env.txt')).readAsStringSync().trim(),
        'none no-home',
      );
    });

    test('a refused pre-tool gate denies every call without starting '
        'anything', () async {
      final hooks = ShellAgentLoopHooks(
        cwd: dir.path,
        start: start.call,
        denyTools: true,
      );
      expect(hooks.interceptsTools, isTrue);
      expect(await hooks.preToolUse('read', {}), isFalse);
      expect(start.starts, isEmpty);
    });

    test('the hooks start no process of their own', () {
      final source = File(
        'lib/src/shell_agent_loop_hooks.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('Process.start(')));
      expect(source, isNot(contains('Process.run(')));
      expect(source, isNot(contains('runInShell')));
    });
  }, skip: _shScriptsSkip());
}
