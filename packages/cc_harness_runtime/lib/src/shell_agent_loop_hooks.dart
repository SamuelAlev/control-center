import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/loop.dart';

/// [AgentLoopHooks] that shells out to user-authored scripts. Each configured
/// script receives a JSON payload on stdin; a non-zero
/// exit from the pre-tool script DENIES the call. All scripts run in [cwd] with
/// a bounded timeout and are best-effort (a missing/failing script never breaks
/// the run, except that a pre-tool non-zero exit is an intentional deny).
class ShellAgentLoopHooks implements AgentLoopHooks {
  /// Creates a [ShellAgentLoopHooks].
  ShellAgentLoopHooks({
    required this.cwd,
    this.sessionStartScript,
    this.preToolScript,
    this.postToolScript,
    this.timeout = const Duration(seconds: 30),
  });

  /// Working directory the scripts run in.
  final String cwd;

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
    // Failed to spawn the shell at all (null) allows — a missing hook must
    // not break the run. Any observed non-zero exit, including 127 from a
    // command-not-found shell, is an intentional deny.
    return code == null || code == 0;
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
  /// the process could not be spawned. A timeout returns `-1`.
  Future<int?> _run(String script, String stdinJson) async {
    final Process process;
    try {
      process = await Process.start(
        script,
        const [],
        workingDirectory: cwd,
        runInShell: true,
      );
    } on Object {
      return null;
    }
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
