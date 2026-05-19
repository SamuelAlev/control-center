import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cc_domain/core/domain/ports/git_command_port.dart';
import 'package:cc_harness/cancellation.dart';

/// Adapter that shells out to the system `git` binary.
class ProcessGitCommandAdapter implements GitCommandPort {
  /// Creates a [ProcessGitCommandAdapter] that shells out to `git`.
  ///
  /// [maxStdoutChars] is a test seam for the abort ceiling; production uses
  /// the default. A guard nothing can reach is a guard nobody knows still
  /// works.
  const ProcessGitCommandAdapter({
    this.maxStdoutChars = _defaultMaxStdoutChars,
    this.indexLockRetries = _defaultIndexLockRetries,
    this.indexLockBackoff = const Duration(milliseconds: 120),
  });

  /// Hard ceiling on buffered stdout for one [run]. See
  /// [_defaultMaxStdoutChars].
  final int maxStdoutChars;

  /// How many times [run] retries a command that lost the `index.lock` race.
  final int indexLockRetries;

  /// Base delay between `index.lock` retries (jittered, then doubled).
  final Duration indexLockBackoff;

  @override
  Future<GitResult> run(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
    void Function(String line)? onProgress,
    CancellationToken? cancel,
  }) async {
    // Concurrent git operations on ONE worktree are normal here — a dispatch
    // commits while the code-graph indexer reads, a rig syncs while a review
    // checks out — and correctness rested entirely on git's own `index.lock`
    // failing loudly. It does fail loudly, which is the right primitive; it
    // just left every caller to treat a transient collision as a real error.
    //
    // Retrying is safe for THIS failure and only this one: `index.lock` means
    // git refused to START, so there is no partial work to double-apply.
    // Anything else returns on the first attempt, unchanged.
    //
    // Jittered because several pollers share this adapter and a fixed backoff
    // makes contenders collide again in lockstep — the same reasoning the
    // HTTP retry interceptor already documents.
    for (var attempt = 0; ; attempt++) {
      if (cancel != null && cancel.isCancelled) {
        return _cancelledResult(args);
      }
      final result = await _runOnce(
        args,
        workdir: workdir,
        env: env,
        onProgress: onProgress,
        cancel: cancel,
      );
      if (result.isSuccess ||
          attempt >= indexLockRetries ||
          !_isIndexLockContention(result.stderr)) {
        return result;
      }
      final base = indexLockBackoff.inMilliseconds * (1 << attempt);
      await Future<void>.delayed(
        Duration(milliseconds: base + _jitter.nextInt(base + 1)),
      );
    }
  }

  Future<GitResult> _runOnce(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
    void Function(String line)? onProgress,
    CancellationToken? cancel,
  }) async {
    final process = await Process.start(
      'git',
      args,
      workingDirectory: workdir,
      environment: _buildEnv(env),
      runInShell: false,
    );

    // Kill the process the moment the caller cancels (a stopped conversation
    // or pipeline run), rather than letting a multi-minute fetch run to
    // completion with nobody waiting for it. SIGKILL, not SIGTERM: git's
    // transport helpers are separate processes and a polite signal leaves the
    // fetch alive. Idempotent with the stdout-ceiling kill below.
    var cancelled = false;
    void killForCancel() {
      cancelled = true;
      process.kill(ProcessSignal.sigkill);
    }

    if (cancel != null) {
      if (cancel.isCancelled) {
        killForCancel();
      } else {
        unawaited(
          cancel.whenCancelled.then((_) {
            if (!cancelled) {
              killForCancel();
            }
          }),
        );
      }
    }

    final stdoutBuffer = StringBuffer();
    // stderr is bounded to a rolling tail. Callers read it for the error
    // message, and progress lines have already been delivered through
    // [onProgress] by the time anyone looks — but a clone against a large
    // remote can write megabytes of progress there, and holding all of it
    // serves nobody.
    final stderrTail = _RollingTail(_maxStderrChars);

    // stdout is NOT truncated — it is the RESULT (a diff, a file list) and a
    // silently shortened one is worse than none, because the caller parses it
    // and believes what it gets. But "never truncate" is not the same as
    // "hold any amount": one `git log -p` over a repo with large binaries can
    // outgrow the heap, and a server that dies mid-command loses every other
    // run in the process. So there is a HARD CEILING that ABORTS instead:
    // the process is killed, and the caller gets a failed [GitResult] whose
    // stderr says exactly what happened. A loud failure the caller can handle,
    // never a quiet corruption it cannot detect.
    var stdoutChars = 0;
    var stdoutOverflowed = false;
    final stdoutDone = process.stdout
        .transform(const SystemEncoding().decoder)
        .listen((chunk) {
          if (stdoutOverflowed) {
            return;
          }
          stdoutChars += chunk.length;
          if (stdoutChars > maxStdoutChars) {
            stdoutOverflowed = true;
            stdoutBuffer.clear();
            process.kill(ProcessSignal.sigkill);
            return;
          }
          stdoutBuffer.write(chunk);
        });
    final stderrDone = process.stderr
        .transform(const SystemEncoding().decoder)
        .listen((chunk) {
          stderrTail.write(chunk);
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
    } finally {
      unawaited(stdoutDone.cancel());
      unawaited(stderrDone.cancel());
    }

    if (cancelled) {
      // Reported as a failure, never as an empty success: a caller that reads
      // `isSuccess` must not mistake a killed fetch for a completed one.
      return _cancelledResult(args);
    }

    if (stdoutOverflowed) {
      return GitResult(
        exitCode: exitCode == 0 ? 1 : exitCode,
        stdout: '',
        stderr:
            'git ${args.isEmpty ? '' : args.first} produced more than '
            '$maxStdoutChars characters on stdout and was '
            'aborted. Narrow the command (a path filter, --max-count, '
            '--stat instead of -p) or stream it with runStreaming.',
      );
    }

    return GitResult(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrTail.toString(),
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
    // downstream consumer is busy and git is never blocked.
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
      controller.addError(e, st);
      unawaited(controller.close());
      return;
    }

    // Close stdin so git never blocks waiting for terminal input.
    unawaited(process.stdin.close());
    // Drain stdout silently — git progress goes to stderr.
    unawaited(process.stdout.drain<void>());

    // Only the LAST stderr line is quoted in the failure error; consumers get
    // every line via the controller. Retaining just the tail keeps a long
    // clone/fetch (thousands of progress lines) from accumulating in memory.
    String? lastStderrLine;
    final stderrDone = Completer<void>();

    // listen() is always active and never paused by backpressure, so the
    // OS pipe drains continuously regardless of how fast the consumer is.
    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen(
          (chunk) {
            for (final part in chunk.split(RegExp(r'[\r\n]'))) {
              final t = part.trim();
              if (t.isNotEmpty) {
                lastStderrLine = t;
                if (!controller.isClosed) {
                  controller.add(t);
                }
              }
            }
          },
          onDone: stderrDone.complete,
          onError: (Object e, StackTrace st) {
            if (!stderrDone.isCompleted) {
              stderrDone.completeError(e, st);
            }
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
        controller.addError(
          StateError(
            'git ${args.firstOrNull ?? ''} failed (exit $exitCode)'
            '${lastStderrLine != null ? ': $lastStderrLine' : ''}',
          ),
        );
      }
      await controller.close();
    }
  }

  /// The result a cancelled command reports: non-zero, with a stderr line the
  /// caller can log verbatim.
  GitResult _cancelledResult(List<String> args) => GitResult(
    exitCode: 143,
    stdout: '',
    stderr: 'git ${args.firstOrNull ?? ''} was cancelled',
  );

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

/// Cap on retained git stderr. Generous — a real error message is a few lines —
/// but finite, so a progress-heavy clone cannot pin megabytes.
const int _maxStderrChars = 256 * 1024;

/// Default hard ceiling on buffered stdout for a single `run` (64 MiB).
///
/// Chosen to be far above any legitimate result this adapter is asked for —
/// the biggest real one is a full-repo `git diff`, which is a few MiB — and
/// far below the point where holding it threatens the process. A command that
/// exceeds it is a command that should have been streamed
/// ([GitCommandPort.runStreaming]) or narrowed, and saying so beats dying.
const int _defaultMaxStdoutChars = 64 * 1024 * 1024;

/// How many times a command that lost the `index.lock` race is retried.
///
/// Three retries at a jittered 120ms base covers well over a second of
/// contention, which is far longer than any operation that holds the index
/// lock (an `add`, a `commit`, a `checkout` of a few files). Beyond that the
/// lock is probably STALE — a crashed process left it behind — and retrying
/// forever would hide that from the operator instead of surfacing it.
const int _defaultIndexLockRetries = 3;

/// Jitter source for the `index.lock` backoff.
final Random _jitter = Random();

/// Whether [stderr] is git refusing because another process holds the index.
///
/// Matched on the lock FILE name rather than the surrounding prose, which git
/// has reworded across versions and localizes.
bool _isIndexLockContention(String stderr) =>
    stderr.contains('index.lock') &&
    (stderr.contains('File exists') ||
        stderr.contains('Unable to create') ||
        stderr.contains('unable to create') ||
        stderr.contains('another git process'));

/// Keeps only the last [maxChars] characters written to it, without ever
/// re-copying the whole accumulation.
///
/// Chunks are dropped from the FRONT as whole units and at most one is sliced,
/// so appending is O(chunk) rather than the O(total) a `removeRange` over a
/// flat buffer would cost per write.
class _RollingTail {
  _RollingTail(this.maxChars);

  final int maxChars;
  final List<String> _chunks = [];
  int _length = 0;

  void write(String chunk) {
    if (chunk.isEmpty) {
      return;
    }
    _chunks.add(chunk);
    _length += chunk.length;
    while (_chunks.length > 1 && _length - _chunks.first.length >= maxChars) {
      _length -= _chunks.removeAt(0).length;
    }
    if (_length > maxChars) {
      final first = _chunks.removeAt(0);
      final keep = maxChars - (_length - first.length);
      _chunks.insert(0, first.substring(first.length - keep));
      _length = maxChars;
    }
  }

  @override
  String toString() => _chunks.join();
}

/// Test seam for [_isIndexLockContention].
///
/// A detector that quietly stopped matching would turn the retry into dead
/// code and nothing else would notice — the command would simply fail the way
/// it used to.
bool isIndexLockContentionForTesting(String stderr) =>
    _isIndexLockContention(stderr);
