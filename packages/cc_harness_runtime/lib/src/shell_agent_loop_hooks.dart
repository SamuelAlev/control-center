import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/loop.dart';

/// [AgentLoopHooks] that shells out to user-authored scripts. Each configured
/// script receives a JSON payload on stdin and runs in [cwd] with a bounded
/// timeout. The script's stdout/stderr are drained (and discarded): an
/// undrained pipe fills its OS buffer and blocks a chatty script until the
/// timeout kills it.
///
/// Failure semantics, deliberately split by what the hook is FOR:
///
/// * The **pre-tool** script is a policy gate, so it fails CLOSED: only an
///   observed exit code of 0 allows the call. A non-zero exit, a timeout, or a
///   script that could not be spawned at all all deny — a gate that cannot
///   answer is not permission (the same rule the loop applies to a throwing
///   [AgentLoopHooks.preToolUse]).
/// * The **session-start** and **post-tool** scripts only observe, so they are
///   best-effort: a missing or failing script never breaks the run.
class ShellAgentLoopHooks implements AgentLoopHooks {
  /// Creates a [ShellAgentLoopHooks].
  ShellAgentLoopHooks({
    required this.cwd,
    required this.environment,
    this.sessionStartScript,
    this.preToolScript,
    this.postToolScript,
    this.timeout = const Duration(seconds: 30),
  });

  /// Working directory the scripts run in.
  final String cwd;

  /// The scripts' complete environment. Nothing from this process's own
  /// environment is added: the caller builds it (the server passes its
  /// allowlisted child environment).
  final Map<String, String> environment;

  /// Script run once at session start (optional).
  final String? sessionStartScript;

  /// Script consulted before each tool call; non-zero exit denies (optional).
  final String? preToolScript;

  /// Script run after each tool call (optional).
  final String? postToolScript;

  /// Per-hook timeout.
  final Duration timeout;

  /// Only the per-tool scripts force the loop to run tools sequentially. A
  /// config carrying just [sessionStartScript] observes nothing per tool, so
  /// it must not cost the run its read-only tool batching.
  @override
  bool get interceptsTools => preToolScript != null || postToolScript != null;

  @override
  Future<void> onSessionStart() async {
    if (sessionStartScript != null) {
      await _run(sessionStartScript!, jsonEncode({'event': 'session_start'}));
    }
  }

  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async {
    if (preToolScript == null) {
      return true;
    }
    final code = await _run(
      preToolScript!,
      jsonEncode({'event': 'pre_tool', 'tool': toolName, 'args': args}),
    );
    // Fail closed: only an observed clean exit allows. A spawn failure (null),
    // a timeout (-1) and any non-zero exit — including 127 from a
    // command-not-found shell — deny.
    return code == 0;
  }

  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) async {
    if (postToolScript != null) {
      await _run(
        postToolScript!,
        jsonEncode({
          'event': 'post_tool',
          'tool': toolName,
          'is_error': isError,
          'result': result,
        }),
      );
    }
  }

  /// Runs [script] with [stdinJson] piped in; returns its exit code, or null if
  /// the process could not be spawned. A timeout kills the script and returns
  /// `-1`.
  Future<int?> _run(String script, String stdinJson) async {
    final Process process;
    try {
      process = await Process.start(
        script,
        const [],
        workingDirectory: cwd,
        environment: environment,
        includeParentEnvironment: false,
        runInShell: true,
      );
    } on Object {
      return null;
    }
    // Drain both pipes concurrently with the run. Errors on them (the process
    // was killed mid-write) are irrelevant to the exit-code verdict.
    unawaited(process.stdout.drain<void>().catchError((Object _) {}));
    unawaited(process.stderr.drain<void>().catchError((Object _) {}));
    try {
      process.stdin.write(stdinJson);
      await process.stdin.close();
    } on Object {
      // Broken pipe: the script already exited (command-not-found is the
      // common case). The exit code is still the gate — do not treat this
      // as a failed launch.
    }
    try {
      return await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          process.kill();
          return -1;
        },
      );
    } on Object {
      return null;
    }
  }
}
