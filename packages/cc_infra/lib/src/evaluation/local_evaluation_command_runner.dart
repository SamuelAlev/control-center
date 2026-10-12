import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart';

/// Runs the harness `bash` tool's commands directly on the host, inside the
/// isolated evaluation workspace.
///
/// This deliberately does NOT reuse Control Center's sandboxed command runner:
/// a live evaluation must exercise the *agent*, and the workspace it runs in is
/// already a throwaway copy. What it does keep is the port's shape (result
/// type, timeout, cancellation, output truncation) so the `bash` tool behaves
/// the same way it does in production.
class LocalEvaluationCommandRunner implements HarnessCommandRunner {
  /// Creates a [LocalEvaluationCommandRunner].
  LocalEvaluationCommandRunner({
    required this.workspaceRoot,
    this.maxOutputChars = 200000,
    this.environment,
  });

  /// The default working directory for commands.
  final String workspaceRoot;

  /// Output cap per stream (head kept, tail kept, middle elided).
  final int maxOutputChars;

  /// Extra environment variables layered over the parent process environment.
  final Map<String, String>? environment;

  @override
  Future<HarnessCommandResult> run(
    String command, {
    String? workdir,
    int timeoutSeconds = 120,
    Map<String, String>? env,
    CancellationToken? cancel,
  }) async {
    if (cancel?.isCancelled ?? false) {
      return HarnessCommandResult.deny('cancelled before start');
    }
    final cwd = workdir ?? workspaceRoot;
    if (!Directory(cwd).existsSync()) {
      return const HarnessCommandResult(
        exitCode: 127,
        stdout: '',
        stderr: 'working directory does not exist',
      );
    }
    final resolvedEnv = <String, String>{
      ...Platform.environment,
      ...?environment,
      ...?env,
    };
    Process process;
    try {
      process = await Process.start(
        'bash',
        ['-lc', command],
        workingDirectory: cwd,
        environment: resolvedEnv,
      );
    } on ProcessException catch (error) {
      return HarnessCommandResult(
        exitCode: 127,
        stdout: '',
        stderr: 'could not start command: ${error.message}',
      );
    }

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    final done = Completer<int>();
    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .listen(stdoutBuffer.write)
        .asFuture<void>();
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .listen(stderrBuffer.write)
        .asFuture<void>();
    unawaited(
      process.exitCode.then((code) {
        if (!done.isCompleted) {
          done.complete(code);
        }
      }),
    );

    var timedOut = false;
    var cancelled = false;
    final timeout = Duration(seconds: timeoutSeconds);
    final killTimer = Timer(timeout, () {
      timedOut = true;
      process.kill(ProcessSignal.sigkill);
    });
    final cancelSubscription = cancel?.whenCancelled.then((_) {
      cancelled = true;
      process.kill(ProcessSignal.sigkill);
    });
    int exitCode;
    try {
      exitCode = await done.future;
    } finally {
      killTimer.cancel();
      unawaited(cancelSubscription ?? Future<void>.value());
      await stdoutDone.catchError((_) {});
      await stderrDone.catchError((_) {});
    }
    if (timedOut) {
      exitCode = 124;
    }
    if (cancelled) {
      exitCode = 130;
    }
    return HarnessCommandResult(
      exitCode: exitCode,
      stdout: _truncate(stdoutBuffer.toString()),
      stderr: _truncate(
        cancelled && stderrBuffer.isEmpty
            ? 'cancelled'
            : stderrBuffer.toString(),
      ),
      timedOut: timedOut,
    );
  }

  String _truncate(String value) {
    if (value.length <= maxOutputChars) {
      return value;
    }
    final head = maxOutputChars ~/ 2;
    final tail = maxOutputChars - head;
    return '${value.substring(0, head)}\n'
        '…[${value.length - maxOutputChars} characters elided]…\n'
        '${value.substring(value.length - tail)}';
  }
}
