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

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('shell_hooks_'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// Writes an executable shell script and returns its path.
  String sh(String name, String body) {
    final file = File(p.join(dir.path, name))
      ..writeAsStringSync('#!/bin/sh\n$body\n');
    // runInShell launches via the user's shell; the script path itself is the
    // command. Make it executable for portability.
    // ignore: avoid_slow_async_io
    Process.runSync('chmod', ['+x', file.path]);
    return file.path;
  }

  group('ShellAgentLoopHooks — no scripts configured', () {
    test('all hooks are no-ops that allow every tool', () async {
      final hooks = ShellAgentLoopHooks(cwd: dir.path);
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
        preToolScript: sh('pre_allow', 'exit 0'),
      );
      expect(await hooks.preToolUse('write', {'path': 'x'}), isTrue);
    });

    test('a pre-tool script exiting non-zero DENIES the call', () async {
      final hooks = ShellAgentLoopHooks(
        cwd: dir.path,
        preToolScript: sh('pre_deny', 'exit 5'),
      );
      expect(await hooks.preToolUse('write', {}), isFalse);
    });

    test(
      'a missing script (shell command-not-found, exit 127) denies',
      () async {
        // runInShell runs the path through the shell. A missing binary yields
        // a non-zero exit (127). The shell can exit before stdin is written
        // (broken pipe); that must still deny, not be treated as a failed
        // launch that allows the tool.
        final hooks = ShellAgentLoopHooks(
          cwd: dir.path,
          preToolScript: 'definitely-not-a-real-command-xyz',
        );
        expect(await hooks.preToolUse('write', {}), isFalse);
      },
    );

    test('a hanging script is killed by the timeout and denies', () async {
      // A timed-out run returns -1 (not null), which the gate treats as deny.
      final hooks = ShellAgentLoopHooks(
        cwd: dir.path,
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
        postToolScript: sh('post', 'touch "\$PWD/post.flag"'),
      );
      await hooks.postToolUse('bash', 'done', isError: false);
      expect(File(marker).existsSync(), isTrue);
    });
  }, skip: _shScriptsSkip());
}
