import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/loop.dart';

/// Starts a hook script: [executable] with [args] in [workingDirectory], with
/// [environment] added to whatever environment the starter gives every
/// process. The server passes the run's `ToolProcessLauncher.start`, so a hook
/// is a tool process of the run, sandboxed exactly like the others.
typedef HookProcessStart =
    Future<Process> Function(
      String executable,
      List<String> args, {
      required String workingDirectory,
      Map<String, String>? environment,
    });

/// [AgentLoopHooks] that runs host-configured scripts. Each configured script
/// is started as its own executable (no shell, no arguments) through [start],
/// receives a JSON payload on stdin and runs in [cwd] with a bounded timeout.
/// The script's stdout/stderr are drained (and discarded): an undrained pipe
/// fills its OS buffer and blocks a chatty script until the timeout kills it.
///
/// A hook gets nothing of the run's own environment: no gateway lease, no
/// forge or provider credential. It sees only what [start] gives every
/// process (the server's allowlisted child environment and, sandboxed, the
/// proxy), plus the event on stdin.
///
/// Failure semantics, deliberately split by what the hook is FOR:
///
/// * The **pre-tool** script is a policy gate, so it fails CLOSED: only an
///   observed exit code of 0 allows the call. A non-zero exit, a timeout, or a
///   script that could not be spawned at all all deny — a gate that cannot
///   answer is not permission (the same rule the loop applies to a throwing
///   [AgentLoopHooks.preToolUse]). [denyTools] is the same rule for a gate
///   that was declared but refused before the run.
/// * The **session-start** and **post-tool** scripts only observe, so they are
///   best-effort: a missing or failing script never breaks the run.
/// * The **stop** script ([AgentLoopTurnHooks.onWouldStop]) fails OPEN: only
///   an observed exit 2 with text on stdout keeps the run going (the text,
///   cut to [maxStopTextChars], becomes a system message), and at most
///   [maxStopBlocks] times in a run. A spawn failure, a timeout, any other
///   exit or a block past the limit lets the turn end: a broken stop hook
///   must not hold a run open. An exit 2 with nothing on stdout also ends
///   the turn, with one warning ([onWarning]). The script reads
///   `stop_hook_active` (this stop follows a continuation it caused) and
///   `block_count` (its blocks so far in the run, 0-based) on stdin.
/// * The **pre-compact** script's stdout (cut to [maxPreCompactChars]) is
///   added to a compaction's focus; a failing script adds nothing.
class ShellAgentLoopHooks implements AgentLoopHooks, AgentLoopTurnHooks {
  /// Creates a [ShellAgentLoopHooks].
  ShellAgentLoopHooks({
    required this.cwd,
    required this.start,
    this.sessionStartScript,
    this.preToolScript,
    this.postToolScript,
    this.stopScript,
    this.preCompactScript,
    this.denyTools = false,
    this.timeout = const Duration(seconds: 30),
    this.onWarning,
  });

  /// Receives a warning about a script's misuse (a stop block without a
  /// reason). Null drops it.
  final void Function(String message)? onWarning;

  /// The warning for an exit 2 with nothing on stdout.
  static const String reasonlessBlockWarning =
      'stop hook blocked without a reason';

  /// Working directory the scripts run in.
  final String cwd;

  /// Starts each script.
  final HookProcessStart start;

  /// Whether every tool call is denied: a pre-tool gate was declared but could
  /// not be honored.
  final bool denyTools;

  /// Script run once at session start (optional).
  final String? sessionStartScript;

  /// Script consulted before each tool call; non-zero exit denies (optional).
  final String? preToolScript;

  /// Script run after each tool call (optional).
  final String? postToolScript;

  /// Script asked when the model would end its turn (optional).
  final String? stopScript;

  /// Script run before a compaction; its stdout joins the focus (optional).
  final String? preCompactScript;

  /// How many times the stop script may keep one run going.
  static const int maxStopBlocks = 3;

  /// The most of the stop script's stdout the model reads.
  static const int maxStopTextChars = 2000;

  /// The most of the pre-compact script's stdout added to the focus.
  static const int maxPreCompactChars = 1000;

  /// The exit code with which the stop script keeps the run going.
  static const int stopBlockExitCode = 2;

  int _stopBlocks = 0;

  /// Whether the last stop answer was a block: the next stop follows a
  /// continuation this hook caused.
  bool _lastStopBlocked = false;

  /// Whether the next stop follows a continuation the stop script caused.
  bool get stopHookActive => _lastStopBlocked;

  /// How many times the stop script kept this run going so far.
  int get stopBlocks => _stopBlocks;

  /// Per-hook timeout.
  final Duration timeout;

  /// Only the per-tool scripts force the loop to run tools sequentially. A
  /// config carrying just [sessionStartScript] observes nothing per tool, so
  /// it must not cost the run its read-only tool batching.
  @override
  bool get interceptsTools =>
      denyTools || preToolScript != null || postToolScript != null;

  @override
  Future<void> onSessionStart() async {
    if (sessionStartScript != null) {
      await _run(sessionStartScript!, jsonEncode({'event': 'session_start'}));
    }
  }

  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async {
    if (denyTools) {
      return false;
    }
    if (preToolScript == null) {
      return true;
    }
    final code = await _run(
      preToolScript!,
      jsonEncode({'event': 'pre_tool', 'tool': toolName, 'args': args}),
    );
    // Fail closed: only an observed clean exit allows. A spawn failure (null,
    // which covers a missing or non-executable script), a timeout (-1) and
    // any non-zero exit deny.
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

  @override
  Future<WouldStop> onWouldStop(WouldStopContext context) async {
    final text = await stopBlock(
      event: {
        'event': 'stop',
        'turn': context.turn,
        'last_message': context.lastAssistantText,
        'stop_hook_active': _lastStopBlocked,
        'block_count': _stopBlocks,
      },
    );
    // The owner's own words: steering a compaction keeps.
    return text == null
        ? const WouldStopEnd()
        : WouldStopContinue(text, origin: null);
  }

  /// Asks the stop script whether the turn may end. Returns the text to send
  /// the model when the script keeps the run going (exit 2 with text on
  /// stdout, cut to [maxStopTextChars]), or null when the turn may end. Past
  /// [maxStopBlocks] blocks the script is not run at all.
  ///
  /// Shared by the harness loop ([onWouldStop]) and the Claude Code `Stop`
  /// hook the agent run gateway answers, so both lanes count blocks the same
  /// way. [event] is the JSON object the script reads on stdin; it gains
  /// `block_count` when the caller did not set it.
  Future<String?> stopBlock({required Map<String, Object?> event}) async {
    final script = stopScript;
    if (script == null || _stopBlocks >= maxStopBlocks) {
      _lastStopBlocked = false;
      return null;
    }
    final (:code, :stdout) = await _runCapturing(
      script,
      jsonEncode({'block_count': _stopBlocks, ...event}),
      maxStopTextChars,
    );
    final text = stdout.trim();
    if (code == stopBlockExitCode && text.isEmpty) {
      onWarning?.call(reasonlessBlockWarning);
    }
    if (code != stopBlockExitCode || text.isEmpty) {
      _lastStopBlocked = false;
      return null;
    }
    _stopBlocks++;
    _lastStopBlocked = true;
    return text;
  }

  @override
  Future<String?> preCompact() => preCompactFocus();

  /// Runs the pre-compact script with [event] on stdin and returns its
  /// stdout (cut to [maxPreCompactChars]) when it exits 0, else null. Shared
  /// by the harness loop ([preCompact]) and the Claude Code `PreCompact` hook
  /// the agent run gateway answers.
  Future<String?> preCompactFocus({
    Map<String, Object?> event = const {'event': 'pre_compact'},
  }) async {
    final script = preCompactScript;
    if (script == null) {
      return null;
    }
    final (:code, :stdout) = await _runCapturing(
      script,
      jsonEncode(event),
      maxPreCompactChars,
    );
    final text = stdout.trim();
    return code == 0 && text.isNotEmpty ? text : null;
  }

  /// Runs [script] like [_run] and also keeps the first [maxChars]
  /// characters of its stdout (the rest is drained and dropped).
  Future<({int? code, String stdout})> _runCapturing(
    String script,
    String stdinJson,
    int maxChars,
  ) async {
    final out = StringBuffer();
    final code = await _run(
      script,
      stdinJson,
      onStdout: (process) => process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen((chunk) {
            final room = maxChars - out.length;
            if (room > 0) {
              out.write(chunk.length <= room ? chunk : chunk.substring(0, room));
            }
          })
          .asFuture<void>(),
    );
    return (code: code, stdout: out.toString());
  }

  /// Runs [script] with [stdinJson] piped in; returns its exit code, or null if
  /// the process could not be spawned. A timeout kills the script and returns
  /// `-1`. [onStdout] reads stdout instead of draining it; its future is
  /// awaited (briefly) after the exit so the last bytes are in.
  Future<int?> _run(
    String script,
    String stdinJson, {
    Future<void> Function(Process process)? onStdout,
  }) async {
    final Process process;
    try {
      process = await start(
        script,
        const [],
        workingDirectory: cwd,
        environment: const {},
      );
    } on Object {
      return null;
    }
    // Drain both pipes concurrently with the run. Errors on them (the process
    // was killed mid-write) are irrelevant to the exit-code verdict.
    final Future<void> stdoutDone = onStdout == null
        ? process.stdout.drain<void>()
        : onStdout(process);
    final readingStdout = stdoutDone.catchError((Object _) {});
    unawaited(process.stderr.drain<void>().catchError((Object _) {}));
    try {
      process.stdin.write(stdinJson);
      await process.stdin.close();
    } on Object {
      // Broken pipe: the script already exited without reading stdin. The
      // exit code is still the gate — do not treat this as a failed launch.
    }
    int? code;
    try {
      code = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          process.kill();
          return -1;
        },
      );
    } on Object {
      return null;
    }
    if (onStdout != null) {
      // A grandchild may hold the pipe open; never wait on it for long.
      await readingStdout.timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    }
    return code;
  }
}
