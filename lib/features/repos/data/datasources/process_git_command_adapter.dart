import 'dart:async';
import 'dart:io';

import 'package:control_center/core/domain/ports/git_command_port.dart';

/// Adapter that shells out to the system `git` binary.
class ProcessGitCommandAdapter implements GitCommandPort {
  const ProcessGitCommandAdapter();

  @override
  Future<GitResult> run(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
    void Function(String line)? onProgress,
  }) async {
    final process = await Process.start(
      'git',
      args,
      workingDirectory: workdir,
      environment: _buildEnv(env),
      runInShell: false,
    );

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final stdoutDone = process.stdout
        .transform(const SystemEncoding().decoder)
        .listen(stdoutBuffer.write);
    final stderrDone = process.stderr
        .transform(const SystemEncoding().decoder)
        .listen((chunk) {
      stderrBuffer.write(chunk);
      if (onProgress != null) {
        // git uses both \n and \r as line delimiters in progress output.
        for (final line in chunk.split(RegExp(r'[\r\n]'))) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            onProgress(trimmed);
          }
        }
      }
    });

    // Wait for the MAIN process to exit, then give stdout/stderr a brief window
    // to deliver any bytes still buffered in the OS pipe. We must NOT wait
    // indefinitely on the stream `onDone` callbacks: after a `git diff` (or any
    // command) against a blobless partial clone, git lazily fetches the missing
    // blobs by spawning helpers (git fetch → git-remote-https). Those
    // grandchildren inherit the stdout/stderr write-end and can keep it open
    // long after the git process we launched has exited, so `onDone` would never
    // fire and this method would hang forever. The data we care about has
    // already been delivered via the `listen` data callbacks before exit — the
    // grace window only covers the last in-flight chunk. This mirrors the
    // exit-code-then-grace pattern already used by [runStreaming]/_runProcess.
    final exitCode = await process.exitCode;
    try {
      await Future.wait([
        stdoutDone.asFuture<void>(),
        stderrDone.asFuture<void>(),
      ]).timeout(const Duration(milliseconds: 300));
    } on TimeoutException catch (_) {
      // A child process is still holding the pipe open — fine; we have the exit
      // code and all output the main process wrote.
    }

    return GitResult(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
    );
  }

  @override
  Stream<String> runStreaming(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
  }) {
    // IMPORTANT: do NOT use an async* generator that `await for`-iterates
    // stderr. When the generator pauses at `yield`, Dart pauses the stream
    // subscription, which stops draining the stderr pipe. If git tries to
    // write more data (its final bytes, or any internal subprocess writing),
    // the OS pipe buffer fills and git blocks — it never exits, so
    // process.exitCode never resolves.
    //
    // Instead: consume stderr with listen() (never paused) and buffer into a
    // StreamController. The controller's buffer absorbs events while the
    // downstream consumer is busy, and git is never blocked.
    final controller = StreamController<String>();

    unawaited(_runProcess(args, workdir, env, controller));

    return controller.stream;
  }

  Future<void> _runProcess(
    List<String> args,
    String workdir,
    Map<String, String>? env,
    StreamController<String> controller,
  ) async {
    Process process;
    try {
      process = await Process.start(
        'git',
        args,
        workingDirectory: workdir,
        environment: _buildEnv(env),
        runInShell: false,
      );
    } catch (e, st) {
      controller
        ..addError(e, st)
        ..close();
      return;
    }

    // Close stdin so git never blocks waiting for terminal input.
    unawaited(process.stdin.close());
    // Drain stdout silently — git progress goes to stderr.
    unawaited(process.stdout.drain<void>());

    final stderrLines = <String>[];
    final stderrDone = Completer<void>();

    // listen() is always active and never paused by backpressure, so the
    // OS pipe drains continuously regardless of how fast the consumer is.
    process.stderr.transform(const SystemEncoding().decoder).listen(
      (chunk) {
        for (final part in chunk.split(RegExp(r'[\r\n]'))) {
          final t = part.trim();
          if (t.isNotEmpty) {
            stderrLines.add(t);
            if (!controller.isClosed) {
              controller.add(t);
            }
          }
        }
      },
      onDone: stderrDone.complete,
      onError: (Object e, StackTrace st) {
        if (!stderrDone.isCompleted) stderrDone.completeError(e, st);
      },
      cancelOnError: true,
    );

    // Wait for the MAIN process to exit — not for stderrDone.
    //
    // After a partial (blobless) clone, git may spawn background helpers
    // (connectivity check, git-remote-https, git maintenance) that keep the
    // inherited stderr write-end open long after the main process has exited.
    // Waiting for stderrDone in that case means waiting forever.
    //
    // Waiting for exitCode resolves as soon as the git binary we launched
    // finishes, regardless of what its grandchildren are doing.
    final exitCode = await process.exitCode;

    // Give stderr a brief window to deliver any bytes already buffered in the
    // OS pipe (the listen() callback may not have fired for the last chunk yet).
    try {
      await stderrDone.future.timeout(const Duration(milliseconds: 300));
    } on TimeoutException catch (_) {
      // A child process is still holding stderr — that is fine; we have the
      // exit code and all output that the main process wrote.
    }

    if (!controller.isClosed) {
      if (exitCode != 0) {
        controller.addError(StateError(
          'git ${args.firstOrNull ?? ''} failed (exit $exitCode)'
          '${stderrLines.isNotEmpty ? ': ${stderrLines.last}' : ''}',
        ));
      }
      await controller.close();
    }
  }

  Map<String, String> _buildEnv(Map<String, String>? extra) {
    // Start from the current process environment so PATH, HOME etc. are
    // available (git needs HOME for config lookups).
    final env = Map<String, String>.from(Platform.environment);
    // Disable interactive prompts so the process never hangs waiting for input.
    env['GIT_TERMINAL_PROMPT'] = '0';
    env['GIT_ASKPASS'] = 'echo';
    if (extra != null) {
      env.addAll(extra);
    }
    return env;
  }
}
