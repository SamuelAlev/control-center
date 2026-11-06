import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';
import 'package:cc_infra/src/sandboxing/env_sanitizer.dart';
import 'package:cc_infra/src/util/command_redaction.dart';
import 'package:path/path.dart' as p;

/// The exit code reported for a command that overran its deadline, the same
/// one `timeout(1)` uses.
const int environmentTimeoutExitCode = 124;

/// The exit code reported for a command that could not be started.
const int environmentSpawnFailureExitCode = 127;

/// A driver operation failed with something worth showing as it is.
class EnvironmentDriverException implements Exception {
  /// Creates an [EnvironmentDriverException].
  const EnvironmentDriverException(this.error);

  /// What went wrong.
  final EnvironmentError error;

  @override
  String toString() => error.message;
}

/// Starts a process. A seam for tests.
typedef EnvironmentProcessStarter =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
      Map<String, String>? environment,
    });

/// Finds a bare command on disk, or null. A seam for tests.
typedef EnvironmentBinaryResolver = Future<String?> Function(String binary);

/// Signals the children of a process. A seam for tests.
typedef EnvironmentChildSignaller =
    Future<void> Function(int pid, ProcessSignal signal);

/// One thing a running command said.
sealed class EnvironmentCommandEvent {
  const EnvironmentCommandEvent();
}

/// A redacted line of output.
class EnvironmentCommandOutput extends EnvironmentCommandEvent {
  /// Creates an [EnvironmentCommandOutput].
  const EnvironmentCommandOutput(this.line, {this.isStderr = false});

  /// The line, with no terminator.
  final String line;

  /// Whether it came from stderr.
  final bool isStderr;
}

/// A stderr `step` or `note` line.
class EnvironmentCommandProgress extends EnvironmentCommandEvent {
  /// Creates an [EnvironmentCommandProgress].
  const EnvironmentCommandProgress(this.progress);

  /// The parsed line.
  final EnvironmentProgress progress;
}

/// How a command ended. Output is redacted and bounded to its tail.
class EnvironmentCommandResult {
  /// Creates an [EnvironmentCommandResult].
  const EnvironmentCommandResult({
    required this.exitCode,
    required this.display,
    this.stdout = '',
    this.stderr = '',
    this.timedOut = false,
    this.cancelled = false,
    this.error,
    this._rawStdout,
  });

  /// The exit code, [environmentTimeoutExitCode] after a deadline, and
  /// [environmentSpawnFailureExitCode] when nothing started.
  final int exitCode;

  /// The redacted command line, for messages.
  final String display;

  /// Standard output, redacted: what may be shown, logged or stored.
  final String stdout;

  final String? _rawStdout;

  /// Standard output as the command printed it, for parsing only. Redaction
  /// can cut through JSON, so anything parsed reads this and anything shown
  /// reads [stdout].
  String get rawStdout => _rawStdout ?? stdout;

  /// Standard error, without progress lines.
  final String stderr;

  /// Whether the deadline ended it.
  final bool timedOut;

  /// Whether [EnvironmentCommandHandle.cancel] ended it.
  final bool cancelled;

  /// What went wrong, null on exit 0.
  final EnvironmentError? error;

  /// Whether it exited 0.
  bool get succeeded => exitCode == 0;
}

/// A started command.
class EnvironmentCommandHandle {
  /// Creates an [EnvironmentCommandHandle].
  EnvironmentCommandHandle({
    required this.events,
    required this.result,
    required this._onCancel,
  });

  /// Lines and progress as they arrive. Broadcast: listen before yielding to
  /// the event loop to see everything.
  final Stream<EnvironmentCommandEvent> events;

  /// Completes when it has ended. Never completes with an error.
  final Future<EnvironmentCommandResult> result;

  final void Function() _onCancel;

  /// Takes it down the same SIGTERM, SIGKILL ladder as a deadline.
  void cancel() => _onCancel();
}

/// Runs definition commands: argv with no shell, or shell as `bash -lc`.
///
/// [start] and [run] take a typed command and expand its placeholders.
/// [startArgv] and [runArgv] take a literal argv, for CC's own calls (`docker`)
/// where a `{` in an argument means a `{`.
///
/// The environment is the sanitized server environment under the caller's
/// variables, so the caller's `NODE_OPTIONS` survives while an inherited
/// `DYLD_INSERT_LIBRARIES` does not.
class EnvironmentCommandRunner {
  /// Creates an [EnvironmentCommandRunner].
  EnvironmentCommandRunner({
    EnvironmentProcessStarter? starter,
    EnvironmentBinaryResolver? binaryResolver,
    EnvironmentChildSignaller? childSignaller,
    this.killGrace = const Duration(seconds: 3),
    this.drainGrace = const Duration(seconds: 6),
    this.maxCapturedChars = 1024 * 1024,
  }) : _starter = starter ?? _startProcess,
       _binaryResolver = binaryResolver ?? resolveBinaryPath,
       _childSignaller = childSignaller ?? _signalChildren;

  /// Lines of stderr quoted when a tool gives no structured error.
  static const int errorTailLines = 20;

  final EnvironmentProcessStarter _starter;
  final EnvironmentBinaryResolver _binaryResolver;
  final EnvironmentChildSignaller _childSignaller;

  /// Between SIGTERM and SIGKILL.
  final Duration killGrace;

  /// How long output may stay open once the process has exited.
  final Duration drainGrace;

  /// Retained characters per stream.
  final int maxCapturedChars;

  /// The argv [command] resolves to, with [arguments] appended or, for shell,
  /// available as `"$@"`.
  static List<String> argvFor(
    EnvironmentCommand command,
    EnvironmentValues values, {
    List<String> arguments = const [],
  }) => switch (command) {
    ArgvEnvironmentCommand() => [...command.resolve(values), ...arguments],
    ShellEnvironmentCommand(:final body) => [
      'bash',
      '-lc',
      body,
      'bash',
      ...arguments,
    ],
  };

  /// Starts [command]. Throws `EnvironmentTemplateException` on an unknown
  /// placeholder, before anything runs.
  EnvironmentCommandHandle start(
    EnvironmentCommand command, {
    EnvironmentValues values = EnvironmentValues.empty,
    List<String> arguments = const [],
    String? workingDirectory,
    Map<String, String> environment = const {},
    Duration? timeout,
  }) => startArgv(
    argvFor(command, values, arguments: arguments),
    workingDirectory: workingDirectory,
    environment: environment,
    timeout: timeout,
  );

  /// Runs [command] to its end.
  Future<EnvironmentCommandResult> run(
    EnvironmentCommand command, {
    EnvironmentValues values = EnvironmentValues.empty,
    List<String> arguments = const [],
    String? workingDirectory,
    Map<String, String> environment = const {},
    Duration? timeout,
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) async => runArgv(
    argvFor(command, values, arguments: arguments),
    workingDirectory: workingDirectory,
    environment: environment,
    timeout: timeout,
    onEvent: onEvent,
  );

  /// Runs a literal [argv] to its end.
  Future<EnvironmentCommandResult> runArgv(
    List<String> argv, {
    String? workingDirectory,
    Map<String, String> environment = const {},
    Duration? timeout,
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) async {
    final handle = startArgv(
      argv,
      workingDirectory: workingDirectory,
      environment: environment,
      timeout: timeout,
    );
    final subscription = onEvent == null ? null : handle.events.listen(onEvent);
    final result = await handle.result;
    await subscription?.cancel();
    return result;
  }

  /// Starts a literal [argv].
  EnvironmentCommandHandle startArgv(
    List<String> argv, {
    String? workingDirectory,
    Map<String, String> environment = const {},
    Duration? timeout,
  }) {
    if (argv.isEmpty) {
      throw ArgumentError('A command needs at least one argument');
    }
    final events = StreamController<EnvironmentCommandEvent>.broadcast();
    final cancelled = Completer<void>();
    final result = _execute(
      argv,
      workingDirectory: workingDirectory,
      environment: environment,
      timeout: timeout,
      events: events,
      cancelled: cancelled.future,
    ).whenComplete(events.close);
    return EnvironmentCommandHandle(
      events: events.stream,
      result: result,
      onCancel: () {
        if (!cancelled.isCompleted) {
          cancelled.complete();
        }
      },
    );
  }

  Future<EnvironmentCommandResult> _execute(
    List<String> argv, {
    required String? workingDirectory,
    required Map<String, String> environment,
    required Duration? timeout,
    required StreamController<EnvironmentCommandEvent> events,
    required Future<void> cancelled,
  }) async {
    final display = redactSecrets(environmentCommandLine(argv));
    final Process process;
    try {
      final executable = await resolveEnvironmentExecutable(
        argv.first,
        workingDirectory: workingDirectory,
        resolver: _binaryResolver,
      );
      process = await _starter(
        executable,
        argv.sublist(1),
        workingDirectory: workingDirectory,
        environment: environmentProcessVariables(
          environment,
          executable: executable,
        ),
      );
    } on EnvironmentDriverException catch (e) {
      return EnvironmentCommandResult(
        exitCode: environmentSpawnFailureExitCode,
        display: display,
        error: e.error,
      );
    } on Object catch (e) {
      return EnvironmentCommandResult(
        exitCode: environmentSpawnFailureExitCode,
        display: display,
        error: EnvironmentError(
          code: 'command-not-started',
          message: 'Could not start `${argv.first}`: $e',
          exitCode: environmentSpawnFailureExitCode,
        ),
      );
    }

    // Closed at once, so anything reading stdin sees end of file instead of
    // waiting forever on a pipe nobody writes to.
    unawaited(process.stdin.close().catchError((Object _) {}));

    final stdout = EnvironmentOutputTail(maxChars: maxCapturedChars);
    final rawStdout = EnvironmentOutputTail(maxChars: maxCapturedChars);
    final stderr = EnvironmentOutputTail(maxChars: maxCapturedChars);
    String? lastStderrLine;

    final outSubscription = _lines(process.stdout).listen((raw) {
      rawStdout.addLine(raw);
      final line = redactSecrets(raw);
      stdout.addLine(line);
      events.add(EnvironmentCommandOutput(line));
    });
    final errSubscription = _lines(process.stderr).listen((raw) {
      final line = redactSecrets(raw);
      if (line.trim().isNotEmpty) {
        lastStderrLine = line;
      }
      final progress = EnvironmentProgress.tryParseLine(line);
      if (progress != null) {
        events.add(EnvironmentCommandProgress(progress));
        return;
      }
      stderr.addLine(line);
      events.add(EnvironmentCommandOutput(line, isStderr: true));
    });
    final outDone = outSubscription.asFuture<void>();
    final errDone = errSubscription.asFuture<void>();

    var exited = false;
    var timedOut = false;
    var wasCancelled = false;
    final abandoned = Completer<int>();
    Timer? killTimer;
    Timer? abandonTimer;

    void takeDown() {
      if (exited || killTimer != null) {
        return;
      }
      unawaited(_signal(process, ProcessSignal.sigterm));
      killTimer = Timer(killGrace, () {
        unawaited(_signal(process, ProcessSignal.sigkill));
        // Stuck in the kernel: report it rather than hang a lifecycle call.
        abandonTimer = Timer(killGrace, () {
          if (!abandoned.isCompleted) {
            abandoned.complete(environmentTimeoutExitCode);
          }
        });
      });
    }

    final deadline = timeout == null
        ? null
        : Timer(timeout, () {
            timedOut = true;
            takeDown();
          });
    unawaited(
      cancelled.then((_) {
        if (!exited) {
          wasCancelled = true;
          takeDown();
        }
      }),
    );

    var exitCode = await Future.any([process.exitCode, abandoned.future]);
    exited = true;
    deadline?.cancel();
    killTimer?.cancel();
    abandonTimer?.cancel();

    // A daemon the command left behind inherits stdout and holds it open.
    // That says nothing about how the command went, so the exit code stands
    // and the wait for the last output is simply bounded.
    await Future.wait([outDone, errDone])
        .timeout(
          drainGrace,
          onTimeout: () {
            CcInfraLog.info(
              'environment command left its output open: $display',
            );
            return const [];
          },
        )
        .catchError((Object _) => const <void>[]);
    await outSubscription.cancel();
    await errSubscription.cancel();

    if (timedOut) {
      exitCode = environmentTimeoutExitCode;
    }
    return EnvironmentCommandResult(
      exitCode: exitCode,
      display: display,
      stdout: stdout.toString(),
      rawStdout: rawStdout.toString(),
      stderr: stderr.toString(),
      timedOut: timedOut,
      cancelled: wasCancelled,
      error: _errorFor(
        exitCode: exitCode,
        timedOut: timedOut,
        timeout: timeout,
        lastStderrLine: lastStderrLine,
        stderr: stderr,
        display: display,
      ),
    );
  }

  EnvironmentError? _errorFor({
    required int exitCode,
    required bool timedOut,
    required Duration? timeout,
    required String? lastStderrLine,
    required EnvironmentOutputTail stderr,
    required String display,
  }) {
    if (exitCode == 0) {
      return null;
    }
    if (timedOut) {
      return EnvironmentError(
        code: 'timeout',
        message: 'Timed out after ${timeout?.inSeconds} s: $display',
        exitCode: exitCode,
      );
    }
    // Only exits 3, 4 and 5 ask a person to act, so only they fall back to the
    // command itself: it is what to run again after fixing the host.
    final actionable = exitCode >= 3 && exitCode <= 5;
    final structured = _parseErrorLine(lastStderrLine);
    if (structured != null) {
      return EnvironmentError(
        code: structured.code,
        message: structured.message,
        hint: structured.hint,
        command: structured.command ?? (actionable ? display : null),
        exitCode: exitCode,
      );
    }
    final tail = stderr.lastLines(errorTailLines);
    return EnvironmentError(
      code: switch (exitCode) {
        3 => 'host-setup-required',
        4 => 'auth-required',
        5 => 'dependency-unavailable',
        _ => 'command-failed',
      },
      message: tail.isEmpty ? '`$display` exited $exitCode' : tail,
      command: actionable ? display : null,
      exitCode: exitCode,
    );
  }

  static EnvironmentError? _parseErrorLine(String? line) {
    final text = line?.trim();
    if (text == null || !text.startsWith('{')) {
      return null;
    }
    try {
      final json = jsonDecode(text);
      if (json is Map && json['type'] == 'error') {
        return EnvironmentError.tryFromJson(json);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Stream<String> _lines(Stream<List<int>> bytes) => bytes
      .transform(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter());

  Future<void> _signal(Process process, ProcessSignal signal) async {
    try {
      // Children first: a wrapper that dies on SIGTERM orphans them otherwise.
      await _childSignaller(process.pid, signal);
    } on Object catch (e) {
      CcInfraLog.debug('could not signal children of ${process.pid}: $e');
    }
    process.kill(signal);
  }

  static Future<Process> _startProcess(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) => Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    // The environment is already complete. Inheriting would put back exactly
    // what the sanitizer took out.
    includeParentEnvironment: false,
  );

  /// Signals the direct children of [pid], found by exact parent pid.
  static Future<void> _signalChildren(int pid, ProcessSignal signal) async {
    if (Platform.isWindows) {
      return;
    }
    final result = await Process.run('ps', ['-A', '-o', 'pid=,ppid=']);
    for (final line in const LineSplitter().convert('${result.stdout}')) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length == 2 && int.tryParse(parts[1]) == pid) {
        final child = int.tryParse(parts[0]);
        if (child != null) {
          Process.killPid(child, signal);
        }
      }
    }
  }
}

/// [variables] over the sanitized server environment.
///
/// [executable], when absolute, adds its directory to the end of `PATH`. A
/// server started from a launcher has a minimal `PATH`, and a resolved `tool`
/// that is a `#!/usr/bin/env node` script needs the `node` installed beside it.
/// At the end, so it can never shadow what the `PATH` already finds.
Map<String, String> environmentProcessVariables(
  Map<String, String> variables, {
  String? executable,
}) {
  final merged = {
    ...const EnvSanitizer().harden(Platform.environment),
    ...variables,
  };
  if (executable != null && p.isAbsolute(executable)) {
    final directory = p.dirname(executable);
    final path = merged['PATH'] ?? '';
    final separator = Platform.isWindows ? ';' : ':';
    if (!path.split(separator).contains(directory)) {
      merged['PATH'] = path.isEmpty ? directory : '$path$separator$directory';
    }
  }
  return merged;
}

/// The path to run [command] from.
///
/// Throws [EnvironmentDriverException] when it can't be found, so a typo reads
/// as a typo instead of whatever the spawn layer does with a failed `exec`.
Future<String> resolveEnvironmentExecutable(
  String command, {
  String? workingDirectory,
  EnvironmentBinaryResolver resolver = resolveBinaryPath,
}) async {
  if (command.contains('/') || command.contains(r'\')) {
    final path = workingDirectory == null
        ? command
        : p.join(workingDirectory, command);
    if (!File(path).existsSync()) {
      throw EnvironmentDriverException(
        EnvironmentError(
          code: 'command-not-found',
          message: 'Command not found: $path',
          exitCode: environmentSpawnFailureExitCode,
        ),
      );
    }
    return p.isAbsolute(path) ? path : p.absolute(path);
  }
  final resolved = await resolver(command);
  if (resolved == null) {
    throw EnvironmentDriverException(
      EnvironmentError(
        code: 'command-not-found',
        message: 'Command not found: $command',
        hint: 'Install it on the server host, or add it to the server PATH',
        exitCode: environmentSpawnFailureExitCode,
      ),
    );
  }
  return resolved;
}

/// [argv] as one line a person could paste into a shell.
String environmentCommandLine(List<String> argv) =>
    argv.map(_shellQuote).join(' ');

final RegExp _shellSafe = RegExp(r'^[A-Za-z0-9_@%+=:,./-]+$');

String _shellQuote(String value) =>
    _shellSafe.hasMatch(value) ? value : "'${value.replaceAll("'", r"'\''")}'";

/// Keeps the most recent [maxChars] of a line stream.
class EnvironmentOutputTail {
  /// Creates an [EnvironmentOutputTail].
  EnvironmentOutputTail({required this.maxChars});

  /// Retained characters.
  final int maxChars;

  final List<String> _lines = [];
  int _chars = 0;
  bool _truncated = false;

  /// Adds [line], dropping the oldest lines past [maxChars].
  void addLine(String line) {
    _lines.add(line);
    _chars += line.length + 1;
    var start = 0;
    while (_chars > maxChars && start < _lines.length - 1) {
      _chars -= _lines[start].length + 1;
      start++;
      _truncated = true;
    }
    if (start > 0) {
      _lines.removeRange(0, start);
    }
  }

  /// The last [count] lines, joined.
  String lastLines(int count) =>
      _lines.skip(_lines.length > count ? _lines.length - count : 0).join('\n');

  @override
  String toString() {
    final body = _lines.join('\n');
    return _truncated ? '[…output truncated…]\n$body' : body;
  }
}
