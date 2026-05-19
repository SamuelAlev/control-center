import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/lease_protocol.dart';
import 'package:cc_worker/src/fleet_client.dart';
import 'package:path/path.dart' as p;

/// The terminal outcome of a job's execution body.
typedef _ExecOutcome = ({bool success, String? error, String? resultJson});

/// Executes a single leased job and streams its progress back to the server.
///
/// Owns a monotonic per-job [WorkerEventFrame] sequence, batches events and
/// flushes them every 250ms or every 32 events; on termination it emits a
/// [DoneEvent] and sends a [JobCompletionReport]. Holds no durable state — the
/// event buffer and any subprocess live only for the job's lifetime.
class JobExecutor {
  /// Creates a [JobExecutor] for [lease], reporting through [client] and
  /// materializing worktrees under [cacheDir].
  JobExecutor({
    required this.lease,
    required FleetClient client,
    required String cacheDir,
  })  : _client = client,
        _cacheDir = cacheDir;

  static const Duration _flushInterval = Duration(milliseconds: 250);
  static const int _flushThreshold = 32;

  /// The lease this executor is running.
  final LeaseOffer lease;

  final FleetClient _client;
  final String _cacheDir;
  final List<WorkerEventFrame> _buffer = <WorkerEventFrame>[];
  final Completer<void> _done = Completer<void>();

  Timer? _flushTimer;
  Process? _process;
  int _seq = 0;
  int _eventsLost = 0;
  bool _cancelled = false;
  bool _flushing = false;

  /// Completes once the job has finished and its completion report was sent.
  Future<void> get done => _done.future;

  /// Starts execution. Returns immediately; observe [done] for completion.
  void start() {
    unawaited(_run());
  }

  /// Requests cancellation: kills any live subprocess (SIGTERM → grace →
  /// SIGKILL) and WAITS for it to exit, so the run terminates and reports
  /// failure.
  ///
  /// The single un-awaited SIGTERM this replaces let a child that traps or
  /// ignores the signal keep running after `stop()` returned — consuming a
  /// lease the server had already written off, on a host the operator believed
  /// was idle.
  ///
  /// A cancel that lands BETWEEN `_run` deciding to spawn and `_runStreaming`
  /// assigning `_process` finds `_process == null` and cannot kill anything —
  /// but `_cancelled` is already set, so `_runStreaming` kills the child the
  /// moment it exists. Without that second half, a cancel racing a slow spawn
  /// left a `sleep 30`-shaped child running to completion after `cancel()`
  /// reported success.
  Future<void> cancel() async {
    _cancelled = true;
    final process = _process;
    if (process == null) {
      return;
    }
    await _killAndWait(process);
  }

  /// SIGTERM → grace → SIGKILL, bounded so [cancel] always returns.
  Future<void> _killAndWait(Process process) async {
    process.kill();
    try {
      await process.exitCode.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      try {
        await process.exitCode.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        // Unreapable — nothing further this layer can do.
      }
    }
  }

  Future<void> _run() async {
    _flushTimer = Timer.periodic(_flushInterval, (_) => unawaited(_flush()));
    var success = false;
    String? error;
    String? resultJson;
    try {
      _emit(DebugEvent(
        content: 'worker accepted job ${lease.jobId} (kind=${lease.kind})',
      ));
      final workDir = await _materialize();
      final outcome = await _execute(workDir);
      success = outcome.success;
      error = outcome.error;
      resultJson = outcome.resultJson;
    } catch (e) {
      success = false;
      error = 'execution error: $e';
      _emit(ErrorEvent(content: error));
    } finally {
      _emit(DoneEvent());
      _flushTimer?.cancel();
      await _flush();
      await _report(success: success, error: error, resultJson: resultJson);
      if (!_done.isCompleted) {
        _done.complete();
      }
    }
  }

  /// Appends [event] to the buffer under the next sequence number, flushing
  /// eagerly once the batch threshold is reached.
  void _emit(AgentProcessEvent event) {
    _seq += 1;
    _buffer.add(WorkerEventFrame(jobId: lease.jobId, seq: _seq, event: event));
    if (_buffer.length >= _flushThreshold) {
      unawaited(_flush());
    }
  }

  /// Ships the buffered frames to the server. A failed send is counted as lost
  /// so the completion report stays honest (PRD 20 §8 — never a silent drop).
  Future<void> _flush() async {
    if (_flushing || _buffer.isEmpty) {
      return;
    }
    _flushing = true;
    final batch = List<WorkerEventFrame>.of(_buffer);
    _buffer.clear();
    try {
      await _client.sendEvents(batch);
    } catch (_) {
      _eventsLost += batch.length;
    } finally {
      _flushing = false;
    }
  }

  /// Materializes the lease's repo into a remote+SHA-keyed cache dir. Returns
  /// null when the lease carries no repo or materialization fails (the job then
  /// runs without a worktree). Never logs [LeaseOffer.env].
  Future<Directory?> _materialize() async {
    final remote = lease.repoRemote;
    if (remote == null || remote.isEmpty) {
      return null;
    }
    final sha = lease.headSha ?? '';
    final dir = Directory(p.join(_cacheDir, _cacheKey(remote, sha)));
    try {
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
        await _git(<String>['clone', '--depth', '1', remote, dir.path], _cacheDir);
      }
      if (sha.isNotEmpty) {
        await _git(<String>['fetch', '--depth', '1', 'origin', sha], dir.path);
        await _git(<String>['checkout', sha], dir.path);
      }
      _emit(DebugEvent(
        content: 'materialized $remote@${sha.isEmpty ? 'HEAD' : sha}',
      ));
      return dir;
    } catch (e) {
      _emit(DebugEvent(content: 'materialize failed for $remote: $e'));
      return null;
    }
  }

  /// Runs `git` quietly (output not streamed), throwing on a non-zero exit.
  Future<void> _git(List<String> args, String cwd) async {
    final result = await Process.run(
      'git',
      args,
      workingDirectory: cwd,
      environment: lease.env,
      runInShell: true,
    );
    if (result.exitCode != 0) {
      throw ProcessException('git', args, 'git ${args.first} failed', result.exitCode);
    }
  }

  /// A filesystem-safe, deterministic cache key for a `(remote, sha)` pair.
  String _cacheKey(String remote, String sha) {
    final name = p
        .basenameWithoutExtension(remote)
        .replaceAll(RegExp('[^A-Za-z0-9_.-]'), '_');
    final shaPart =
        sha.isEmpty ? 'head' : sha.substring(0, sha.length < 12 ? sha.length : 12);
    return '${name}_${_stableHash(remote)}_$shaPart';
  }

  /// A stable 32-bit FNV-1a hash of [input], as 8 hex digits. Deterministic
  /// across runs so the same remote reuses its cache dir (unlike `hashCode`).
  String _stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Dispatches execution by job kind.
  Future<_ExecOutcome> _execute(Directory? workDir) async {
    final kind = JobKind.fromWire(lease.kind);
    switch (kind) {
      case JobKind.agentRun:
        return _executeAgentRun(workDir);
      case JobKind.pipelineStep:
      case JobKind.codeIndex:
      case JobKind.goldenRender:
      case JobKind.benchmark:
      case JobKind.evalBatch:
        return _executeProbe(workDir, kind);
    }
  }

  /// Runs an `agentRun`: if the lease env carries a runnable command
  /// (`CC_JOB_COMMAND`) run it and stream its output; otherwise echo the prompt
  /// so the streaming path is still exercised end-to-end.
  Future<_ExecOutcome> _executeAgentRun(Directory? workDir) async {
    final spec = JobSpec.fromJsonString(JobKind.agentRun, lease.specJson)
        as AgentRunJobSpec;
    final command = lease.env['CC_JOB_COMMAND'];
    if (command == null || command.trim().isEmpty) {
      final prompt = spec.prompt?.trim();
      _emit(TextEvent(
        content: prompt == null || prompt.isEmpty
            ? 'agent ${spec.agentId}: no command and no prompt supplied'
            : 'agent ${spec.agentId} prompt: $prompt',
      ));
      return (
        success: true,
        error: null,
        resultJson: _resultJson('echoed prompt'),
      );
    }
    final (executable, args) = _shellCommand(command);
    final code = await _runStreaming(executable, args, workDir: workDir?.path);
    if (_cancelled) {
      return (success: false, error: 'cancelled by server', resultJson: null);
    }
    return (
      success: code == 0,
      error: code == 0 ? null : 'command exited with code $code',
      resultJson: _resultJson('exit $code'),
    );
  }

  /// Runs a small real command for kinds this subprocess-only worker does not
  /// yet fully implement, proving the streaming path without faking output.
  Future<_ExecOutcome> _executeProbe(Directory? workDir, JobKind kind) async {
    final args = workDir == null
        ? const <String>['--version']
        : const <String>['rev-parse', 'HEAD'];
    // `runInShell` for the same reason `_git` uses it: on Windows `git` is
    // often a `.cmd` shim that bare `Process.start` will not resolve.
    final code = await _runStreaming(
      'git',
      args,
      workDir: workDir?.path,
      runInShell: Platform.isWindows,
    );
    if (_cancelled) {
      return (success: false, error: 'cancelled by server', resultJson: null);
    }
    return (
      success: code == 0,
      error: code == 0 ? null : '${kind.wire} probe exited with code $code',
      resultJson: _resultJson('${kind.wire} probe exit $code'),
    );
  }

  /// Splits a COMMAND LINE into the argv that runs it through a shell.
  ///
  /// `CC_JOB_COMMAND` is a command line, not a program name — `bash build.sh
  /// --release`, `pytest -q`. It used to be passed to `Process.start` as the
  /// *executable* with `runInShell: true` and no arguments, which does not mean
  /// what it looks like: Dart QUOTES the executable before handing it to
  /// `/bin/sh -c`, so the shell looked for a program literally named
  /// `bash build.sh --release` and every job with an argument in its command
  /// died with exit 127 (`command not found`) — reported to the server as an
  /// ordinary non-zero exit, so it looked like the job's own failure.
  ///
  /// Building the argv here says what was always meant: hand the whole string
  /// to a shell as one script.
  static (String, List<String>) _shellCommand(String command) =>
      Platform.isWindows
          ? ('cmd.exe', <String>['/c', command])
          : ('/bin/sh', <String>['-c', command]);

  /// Starts a subprocess with the lease env injected, translating stdout lines
  /// to [TextEvent]s and stderr lines to [ErrorEvent]s. Returns the exit code.
  Future<int> _runStreaming(
    String executable,
    List<String> args, {
    String? workDir,
    bool runInShell = false,
  }) async {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workDir,
      environment: lease.env,
      runInShell: runInShell,
    );
    _process = process;
    // Cancelled while the spawn was in flight (cancel() saw `_process == null`
    // and could only set the flag): kill NOW so no child outlives a cancel()
    // that already returned. See [cancel].
    if (_cancelled) {
      unawaited(_killAndWait(process));
    }
    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) => _emit(TextEvent(content: line)));
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) => _emit(ErrorEvent(content: line)));
    final code = await process.exitCode;
    // Drain the pipes, but do not wait on EOF past the exit: a grandchild
    // that inherited the stdout/stderr fds (e.g. `sh -c 'sleep 30'` where the
    // shell spawned instead of exec-tailing) keeps the pipe open long after
    // OUR child died — the report must not wait on orphans.
    try {
      await stdoutDone.timeout(const Duration(seconds: 2));
      await stderrDone.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      // Orphaned pipe holder; nothing more to read.
    }
    _process = null;
    return code;
  }

  /// Builds the completion `resultJson` payload for [summary].
  String _resultJson(String summary) => jsonEncode(<String, dynamic>{
        'jobId': lease.jobId,
        'kind': lease.kind,
        'summary': summary,
      });

  /// Sends the terminal [JobCompletionReport]. Best-effort: on a send failure
  /// the server reaps the lease when it expires.
  Future<void> _report({
    required bool success,
    String? error,
    String? resultJson,
  }) async {
    final report = JobCompletionReport(
      jobId: lease.jobId,
      success: success,
      error: error,
      resultJson: resultJson,
      eventsLost: _eventsLost,
      lastSeq: _seq,
    );
    try {
      await _client.complete(report);
    } catch (_) {
      // Best-effort — a lost report falls back to server-side lease expiry.
    }
  }
}
