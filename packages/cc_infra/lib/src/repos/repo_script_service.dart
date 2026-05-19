import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show RepoScriptException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/repo_script_run.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/ports/repo_script_port.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_script_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_scripts.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/sandboxing/env_sanitizer.dart';
import 'package:uuid/uuid.dart';

/// Executes per-repo lifecycle scripts (see [RepoScripts]) on the server.
///
/// Scripts run via `bash -lc` (a login shell, so tools installed under
/// Homebrew/nvm are on PATH) with the worktree as the working directory and
/// these environment variables set:
///
/// - `CC_WORKSPACE_PATH` — the provisioned worktree (the script's cwd)
/// - `CC_ROOT_PATH` — the registered source repo (the operator's checkout)
/// - `CC_SPACE_ID` / `CC_SPACE_NAME` — the space the worktree belongs to
/// - `CC_REPO_NAME` — the repo's display name
///
/// Every execution is recorded as a [RepoScriptRun] row with a bounded,
/// throttled live output tail (the pattern of the pipeline bash step), so a
/// chatty install neither grows the row without limit nor hammers the
/// database.
class RepoScriptService implements RepoScriptPort {
  /// Creates a [RepoScriptService].
  RepoScriptService({
    required RepoScriptRepository scripts,
    required RepoScriptRunRecorder runs,
    RepoRepository? repos,
    Future<String?> Function(String workspaceId, String spaceId)?
    spaceNameResolver,
    RepoIsolationPort? repoIsolation,
    Future<String> Function(String workspaceId)? testCloneParentDir,
    Uuid uuid = const Uuid(),
    this.setupTimeout = defaultSetupTimeout,
    this.archiveTimeout = defaultArchiveTimeout,
  }) : _scripts = scripts,
       _runs = runs,
       _repos = repos,
       _spaceNameResolver = spaceNameResolver,
       _repoIsolation = repoIsolation,
       _testCloneParentDir = testCloneParentDir,
       _uuid = uuid;

  /// Default ceiling for setup scripts — long enough for a cold dependency
  /// install, short enough that a wedged one fails the provisioning visibly
  /// instead of hanging the space in `provisioning` forever. The space
  /// provisioning watchdog budgets for this per scripted repo.
  static const Duration defaultSetupTimeout = Duration(minutes: 5);

  /// Default ceiling for archive scripts. Deliberately much shorter than
  /// setup: archive runs on GC paths (space deleted, PR merged, scheduled
  /// sweep) where every second held is a second before the disk comes back.
  static const Duration defaultArchiveTimeout = Duration(minutes: 2);

  /// Minimum gap between successive output writes.
  static const Duration _minFlushInterval = Duration(milliseconds: 500);

  /// Retained characters of combined output per run.
  static const int _maxOutputChars = 64 * 1024;

  /// Grace between SIGTERM and SIGKILL on timeout.
  static const Duration _killGrace = Duration(seconds: 3);

  final RepoScriptRepository _scripts;
  final RepoScriptRunRecorder _runs;
  final RepoRepository? _repos;
  final Future<String?> Function(String workspaceId, String spaceId)?
  _spaceNameResolver;
  final RepoIsolationPort? _repoIsolation;
  final Future<String> Function(String workspaceId)? _testCloneParentDir;
  final Uuid _uuid;

  /// Ceiling for setup runs.
  final Duration setupTimeout;

  /// Ceiling for archive runs.
  final Duration archiveTimeout;

  @override
  Future<bool> hasSetupScript(String workspaceId, String repoId) async =>
      (await _scripts.getScripts(workspaceId, repoId)).setup != null;

  @override
  Future<void> runSetup(RepoScriptContext context) =>
      _run(context, RepoScriptKind.setup, setupTimeout);

  @override
  Future<void> runArchive(RepoScriptContext context) =>
      _run(context, RepoScriptKind.archive, archiveTimeout);

  @override
  Future<String> runTest({
    required String workspaceId,
    required String repoId,
    required RepoScriptKind kind,
    required String body,
  }) async {
    // The run row is the whole answer, so it exists even for a refusal —
    // the dialog's run list is where every outcome lands.
    Future<String> refused(String reason) async {
      final runId = _uuid.v4();
      await _runs.insert(
        RepoScriptRun(
          id: runId,
          workspaceId: workspaceId,
          repoId: repoId,
          repoName: repoId,
          kind: RepoScriptKind.test,
          status: RepoScriptRunStatus.failed,
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
          error: reason,
        ),
      );
      return runId;
    }

    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return refused('empty script body');
    }
    final isolation = _repoIsolation;
    final parentDir = _testCloneParentDir;
    if (isolation == null || parentDir == null) {
      return refused(
        'test runs are unavailable on this server (no repo isolation backend '
        'or scratch directory is wired)',
      );
    }
    final repo = await _repos?.getById(workspaceId, repoId);
    if (repo == null || repo.path.isEmpty) {
      return refused('repo not found or has no local checkout path');
    }

    final runId = _uuid.v4();
    await _runs.insert(
      RepoScriptRun(
        id: runId,
        workspaceId: workspaceId,
        repoId: repoId,
        repoName: repo.name,
        kind: RepoScriptKind.test,
        status: RepoScriptRunStatus.running,
        startedAt: DateTime.now(),
      ),
    );
    // The caller gets its id now; the clone, execution and teardown continue
    // in the background, streaming into the row (the dispatchAgent shape).
    unawaited(
      _runTestNow(
        runId: runId,
        workspaceId: workspaceId,
        repo: repo,
        body: trimmed,
        isolation: isolation,
        parentDir: parentDir,
      ),
    );
    return runId;
  }

  Future<void> _runTestNow({
    required String runId,
    required String workspaceId,
    required Repo repo,
    required String body,
    required RepoIsolationPort isolation,
    required Future<String> Function(String workspaceId) parentDir,
  }) async {
    final parent = await parentDir(workspaceId);
    await _sweepStaleTestClones(parent);
    RepoIsolationResult? clone;
    try {
      clone = await isolation.provision(
        sourcePath: repo.path,
        destParentDir: parent,
        name: 'script-test-${_uuid.v4().substring(0, 8)}',
        branch: 'cc-script-test-${_uuid.v4().substring(0, 8)}',
        // Pristine matches what a freshly provisioned worktree looks like —
        // the state the setup script contract promises — instead of the
        // operator's dirty checkout.
        pristine: true,
      );
      await _execute(
        runId: runId,
        context: RepoScriptContext(
          workspaceId: workspaceId,
          spaceId: null,
          repoId: repo.id,
          worktreePath: clone.path,
          sourcePath: repo.path,
        ),
        kind: RepoScriptKind.test,
        repoName: repo.name,
        body: body,
        timeout: setupTimeout,
      );
    } on Object catch (e, st) {
      CcInfraLog.error('script test run $runId failed', e, st);
      await _runs.finish(
        workspaceId,
        runId,
        status: RepoScriptRunStatus.failed,
        error: e.toString(),
      );
    } finally {
      final done = clone;
      if (done != null) {
        try {
          await isolation.destroy(
            path: done.path,
            sourcePath: repo.path,
            backend: done.backend,
          );
        } on Object catch (e) {
          CcInfraLog.warning(
            'script test clone teardown failed for ${done.path}: $e',
          );
        }
      }
    }
  }

  /// Best-effort removal of test clones a crashed server left behind: any
  /// `script-test-*` sibling older than an hour is not a live run (the test
  /// timeout is shorter) and only holds disk.
  Future<void> _sweepStaleTestClones(String parent) async {
    try {
      final dir = Directory(parent);
      if (!dir.existsSync()) {
        return;
      }
      final cutoff = DateTime.now().subtract(const Duration(hours: 1));
      await for (final entry in dir.list()) {
        final name = entry.uri.pathSegments.lastOrNull;
        if (name == null || !name.startsWith('script-test-')) {
          continue;
        }
        if (entry.statSync().modified.isAfter(cutoff)) {
          continue;
        }
        try {
          if (entry is Directory) {
            await entry.delete(recursive: true);
          }
        } on Object catch (_) {}
      }
    } on Object catch (_) {}
  }

  Future<void> _run(
    RepoScriptContext context,
    RepoScriptKind kind,
    Duration timeout,
  ) async {
    final scripts = await _scripts.getScripts(
      context.workspaceId,
      context.repoId,
    );
    final body = kind == RepoScriptKind.setup ? scripts.setup : scripts.archive;
    if (body == null) {
      return;
    }

    final repoName = await _resolveRepoName(context);
    final runId = _uuid.v4();
    final startedAt = DateTime.now();
    await _runs.insert(
      RepoScriptRun(
        id: runId,
        workspaceId: context.workspaceId,
        spaceId: context.spaceId,
        repoId: context.repoId,
        repoName: repoName,
        kind: kind,
        status: RepoScriptRunStatus.running,
        startedAt: startedAt,
      ),
    );

    final outcome = await _execute(
      runId: runId,
      context: context,
      kind: kind,
      repoName: repoName,
      body: body,
      timeout: timeout,
    );

    switch (outcome.status) {
      case _RunStatus.succeeded:
        return;
      case _RunStatus.failed:
      case _RunStatus.timedOut:
        final message = outcome.status == _RunStatus.timedOut
            ? '$repoName ${kind.wireName} script timed out after '
                  '${timeout.inMinutes} min'
            : '$repoName ${kind.wireName} script exited ${outcome.exitCode}';
        // Setup failure must fail the provisioning (retryable); archive is
        // best-effort by contract — record + log, never propagate.
        if (kind == RepoScriptKind.setup) {
          throw RepoScriptException(message, outputTail: outcome.outputTail);
        }
        CcInfraLog.warning(
          '$message (archive continues): ${outcome.outputTail}',
        );
    }
  }

  Future<_Outcome> _execute({
    required String runId,
    required RepoScriptContext context,
    required RepoScriptKind kind,
    required String repoName,
    required String body,
    required Duration timeout,
  }) async {
    final lines = _BoundedLineBuffer(maxChars: _maxOutputChars);
    Timer? pendingFlush;
    var dirty = false;

    void scheduleFlush() {
      dirty = true;
      pendingFlush ??= Timer(_minFlushInterval, () {
        pendingFlush = null;
        if (dirty) {
          dirty = false;
          _runs
              .updateOutput(context.workspaceId, runId, lines.toString())
              .catchError(
                (Object e) => CcInfraLog.warning(
                  'script output write failed for $runId: $e',
                ),
              );
        }
      });
    }

    try {
      final spaceId = context.spaceId;
      final env = const EnvSanitizer().hardenPlatform({
        'CC_WORKSPACE_PATH': context.worktreePath,
        'CC_ROOT_PATH': context.sourcePath,
        'CC_SPACE_ID': ?spaceId,
        'CC_REPO_NAME': repoName,
        if (spaceId != null && _spaceNameResolver != null)
          'CC_SPACE_NAME':
              await _spaceNameResolver(context.workspaceId, spaceId) ?? '',
        // Set only for TEST runs: the flag an archive script checks to skip
        // the steps that are only safe against a worktree really going away.
        if (kind == RepoScriptKind.test) 'CC_SCRIPT_TEST': '1',
      });

      CcInfraLog.info(
        'running $kind script for $repoName in ${context.worktreePath}',
      );
      final process = await Process.start(
        'bash',
        ['-lc', body],
        workingDirectory: context.worktreePath,
        environment: env,
        runInShell: false,
      );

      final stdoutDone = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            lines.addLine(line);
            scheduleFlush();
          })
          .asFuture<void>();
      final stderrDone = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            lines.addLine('[stderr] $line');
            scheduleFlush();
          })
          .asFuture<void>();

      var timedOut = false;
      final exitCode = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          timedOut = true;
          _escalateKill(process);
          return process.exitCode;
        },
      );
      await Future.wait([stdoutDone, stderrDone]).timeout(_killGrace * 2);

      final status = timedOut
          ? _RunStatus.timedOut
          : exitCode == 0
          ? _RunStatus.succeeded
          : _RunStatus.failed;
      await _runs.finish(
        context.workspaceId,
        runId,
        status: timedOut
            ? RepoScriptRunStatus.timedOut
            : exitCode == 0
            ? RepoScriptRunStatus.succeeded
            : RepoScriptRunStatus.failed,
        exitCode: timedOut ? null : exitCode,
        error: timedOut ? 'timed out after ${timeout.inMinutes} min' : null,
        output: lines.toString(),
      );
      return _Outcome(
        status: status,
        exitCode: exitCode,
        outputTail: lines.toString(),
      );
    } on Object catch (e, st) {
      // Spawn failure (bash missing, worktree dir gone, …): close the row.
      CcInfraLog.error('script run $runId failed to execute', e, st);
      await _runs.finish(
        context.workspaceId,
        runId,
        status: RepoScriptRunStatus.failed,
        error: e.toString(),
        output: lines.toString(),
      );
      return _Outcome(
        status: _RunStatus.failed,
        exitCode: null,
        outputTail: lines.toString(),
      );
    } finally {
      pendingFlush?.cancel();
    }
  }

  /// SIGTERM, a short grace, then SIGKILL — the same ladder the process
  /// control service uses, so a script trapping TERM gets to clean up.
  void _escalateKill(Process process) {
    try {
      process.kill(ProcessSignal.sigterm);
      Timer(_killGrace, () {
        try {
          process.kill(ProcessSignal.sigkill);
        } on Object catch (_) {}
      });
    } on Object catch (_) {}
  }

  Future<String> _resolveRepoName(RepoScriptContext context) async {
    final repo = await _repos?.getById(context.workspaceId, context.repoId);
    if (repo != null && repo.name.isNotEmpty) {
      return repo.name;
    }
    // The repo row may already be gone (archive after an unlink); fall back
    // to the source checkout's directory name.
    final fallback = context.sourcePath
        .split(Platform.pathSeparator)
        .where((segment) => segment.isNotEmpty)
        .lastOrNull;
    return fallback ?? context.repoId;
  }
}

enum _RunStatus { succeeded, failed, timedOut }

class _Outcome {
  const _Outcome({required this.status, this.exitCode, this.outputTail = ''});

  final _RunStatus status;
  final int? exitCode;
  final String outputTail;
}

/// Line buffer keeping only the most recent [maxChars] characters, prefixed
/// with a truncation notice once older lines were dropped (same contract as
/// the pipeline bash step's buffer).
class _BoundedLineBuffer {
  _BoundedLineBuffer({required this.maxChars});

  final int maxChars;

  final List<String> _lines = [];
  int _chars = 0;
  bool _truncated = false;

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

  @override
  String toString() {
    final body = _lines.join('\n');
    return _truncated ? '[…output truncated…]\n$body' : body;
  }
}
