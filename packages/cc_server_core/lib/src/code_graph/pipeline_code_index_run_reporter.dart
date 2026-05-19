import 'dart:convert';

import 'package:cc_domain/features/code_graph/domain/ports/code_index_run_reporter.dart';
import 'package:cc_domain/features/code_graph/domain/services/code_indexer.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:uuid/uuid.dart';

/// [CodeIndexRunReporter] that publishes background index runs as runs of the
/// `index_code` template — the same rows the engine writes when that template is
/// started manually or by `RepoAdded`, so a watcher reindex lands in the runs
/// table, the sidebar's running count and the run history beside them.
///
/// It writes those rows DIRECTLY rather than calling `PipelineEngine.start` and
/// that is the whole design decision here. `start` would run the template's own
/// `code.index` body, which indexes the LINKED checkout — but the watcher's runs
/// are per-checkout (most of them are worktree partitions), already debounced,
/// already gated by a concurrency ceiling the engine knows nothing about and
/// the watcher needs the [CodeIndexResult] back to do its own bookkeeping. Going
/// through the engine would mean a second indexer invocation with the wrong
/// partition, racing the one that reported it. So the run row here is a
/// PROJECTION of work the watcher owns, not a request to do work.
///
/// Two consequences follow from that, both deliberate:
///
/// * no `PipelineRunStarted`/`PipelineRunCompleted` domain events are published.
///   Those events are the engine's lifecycle and event triggers listen to them;
///   a reindex firing them would let a background save cascade into other
///   pipelines and OS notifications;
/// * the engine must not adopt these rows on resume.
///   [PipelineCodeIndexRunReporter.reapInterrupted] closes out the ones a crash
///   left non-terminal and the server calls it before `resumeAll()`.
///
/// Because a projection is FOR an operator, it is also filtered for one: a run
/// publishes only once it crosses
/// [PipelineCodeIndexRunReporter.defaultPublishFileFloor] files or
/// [PipelineCodeIndexRunReporter.defaultPublishAfter] of wall time (a failure
/// always publishes). Every save is a run and every run was a row, which meant
/// the visibility this class exists to provide was drowning in itself.
class PipelineCodeIndexRunReporter implements CodeIndexRunReporter {
  /// Creates a reporter over the pipeline-run repository. `onError` receives
  /// reporting failures, which are never surfaced to the indexer.
  PipelineCodeIndexRunReporter(
    this._runs, {
    void Function(String message)? onError,
    String Function()? idFactory,
    DateTime Function()? now,
    int publishFileFloor = defaultPublishFileFloor,
    Duration publishAfter = defaultPublishAfter,
  }) : _onError = onError,
       _idFactory = idFactory ?? (() => const Uuid().v4()),
       _now = now ?? DateTime.now,
       _publishFileFloor = publishFileFloor,
       _publishAfter = publishAfter;

  /// How many files a run must be about to extract before it earns a row.
  ///
  /// A watcher run exists for every save, and a save is one file. Publishing
  /// those buried the runs table: 30 minutes of ordinary editing produced 77
  /// `index_code` rows, 37 of them a single file finishing in under two
  /// seconds — noise that pushed the runs anyone actually wanted off the
  /// screen. The floor is what separates "the graph kept up with a keystroke"
  /// from "something is indexing and it is going to take a while".
  static const int defaultPublishFileFloor = 25;

  /// How long a run may take before it earns a row regardless of size.
  ///
  /// The file floor alone is not enough: a handful of very large files, a cold
  /// embedder or a loaded machine can make a small run the slow one, and a run
  /// that pins a core for ten seconds must be attributable no matter how few
  /// files it touched. Set below the service's own slow-run log threshold so
  /// anything the log calls slow has a row to point at.
  static const Duration defaultPublishAfter = Duration(seconds: 4);

  final PipelineRunRepository _runs;
  final void Function(String message)? _onError;
  final String Function() _idFactory;
  final DateTime Function() _now;
  final int _publishFileFloor;
  final Duration _publishAfter;

  @override
  CodeIndexRun begin({
    required String workspaceId,
    required String repoId,
    required String repoPath,
    String? checkoutId,
    CodeIndexCause cause = const CodeIndexCause.initial(),
  }) => _PipelineCodeIndexRun(
    runs: _runs,
    onError: _onError,
    idFactory: _idFactory,
    now: _now,
    workspaceId: workspaceId,
    repoId: repoId,
    repoPath: repoPath,
    checkoutId: checkoutId,
    cause: cause,
    publishFileFloor: _publishFileFloor,
    publishAfter: _publishAfter,
  );

  /// Closes out watcher-published runs left non-terminal by a crash or a kill.
  ///
  /// Must run BEFORE `PipelineEngine.resumeAll()`. A row this reporter wrote is
  /// a projection of the watcher's work: nothing about it is resumable and the
  /// engine trying would execute the template's own body against the linked
  /// checkout — indexing the wrong partition, at boot, in the window the "index
  /// only after the ready banner" rule exists to protect. Marked `cancelled`
  /// rather than `failed` because nothing failed; the run was interrupted and
  /// the watcher reindexes on its next sweep anyway.
  ///
  /// Returns the number of rows closed.
  Future<int> reapInterrupted() async {
    var closed = 0;
    try {
      final stale = await _runs.nonTerminalRuns();
      for (final run in stale) {
        if (run.triggerEventType != IndexCodeTemplate.watchTriggerEventType) {
          continue;
        }
        final now = _now();
        await _runs.updateRun(
          run.copyWith(
            status: PipelineRunStatus.cancelled,
            finishedAt: now,
            lastResumedAt: null,
            errorMessage: 'Interrupted by shutdown before it finished.',
          ),
        );
        for (final step in await _runs.stepRunsForPipeline(run.id)) {
          if (step.isTerminal) {
            continue;
          }
          await _runs.updateStepRun(
            run.workspaceId,
            step.id,
            status: PipelineStepStatus.cancelled,
            finishedAt: now,
          );
        }
        closed++;
      }
    } on Object catch (e) {
      _onError?.call('code-index run reaper failed: $e');
    }
    return closed;
  }
}

class _PipelineCodeIndexRun implements CodeIndexRun {
  _PipelineCodeIndexRun({
    required PipelineRunRepository runs,
    required void Function(String message)? onError,
    required String Function() idFactory,
    required DateTime Function() now,
    required this.workspaceId,
    required this.repoId,
    required this.repoPath,
    required this.checkoutId,
    required this.cause,
    required int publishFileFloor,
    required Duration publishAfter,
  }) : _runs = runs,
       _onError = onError,
       _idFactory = idFactory,
       _now = now,
       _publishFileFloor = publishFileFloor,
       _publishAfter = publishAfter,
       _startedAt = now();

  final PipelineRunRepository _runs;
  final void Function(String message)? _onError;
  final String Function() _idFactory;
  final DateTime Function() _now;

  final String workspaceId;
  final String repoId;
  final String repoPath;
  final String? checkoutId;
  final CodeIndexCause cause;
  final int _publishFileFloor;
  final Duration _publishAfter;
  final DateTime _startedAt;

  String? _runId;
  String? _stepRunId;
  var _cancelRequested = false;

  @override
  bool get cancelRequested => _cancelRequested;

  /// Whether this run is big enough or slow enough to be worth a row.
  ///
  /// Checked on every progress report rather than once, because both inputs
  /// move: `filesToIndex` is only known after enumeration, and a run that
  /// starts under the floor still crosses [_publishAfter] if it drags. Once it
  /// publishes, [_runId] short-circuits this for the rest of the run.
  bool _worthPublishing(CodeIndexProgress progress) =>
      progress.filesToIndex >= _publishFileFloor ||
      _now().difference(_startedAt) >= _publishAfter;

  @override
  Future<void> report(CodeIndexProgress progress) async {
    try {
      // A run below the floor reports nothing and therefore writes nothing:
      // `finish` is a no-op without a row, so it leaves no trace at all. That
      // is the same contract `begin` already had for a run that found no work —
      // this only moves the line from "no work" to "no work worth watching".
      if (_runId == null && !_worthPublishing(progress)) {
        return;
      }
      await _ensureRun(PipelineRunStatus.running);
      final stepRunId = _stepRunId;
      if (stepRunId == null) {
        return;
      }
      await _runs.updateStepRun(
        workspaceId,
        stepRunId,
        outputJson: jsonEncode({
          'stepId': IndexCodeTemplate.indexStepId,
          ...progress.toJson(),
        }),
      );
      await _refreshCancellation();
    } on Object catch (e) {
      _onError?.call('code-index run progress report failed: $e');
    }
  }

  @override
  Future<void> finish(CodeIndexResult result) async {
    // Never publishes on its own: a run that reported nothing did nothing worth
    // a row (a matching checkpoint, or every file's hash unchanged) and the
    // watcher fires on every save.
    final runId = _runId;
    final stepRunId = _stepRunId;
    if (runId == null || stepRunId == null) {
      return;
    }
    try {
      final summary = {'index_summary': result.toJson()};
      await _runs.updateStepRun(
        workspaceId,
        stepRunId,
        status: PipelineStepStatus.completed,
        outputJson: jsonEncode(summary),
        finishedAt: _now(),
      );
      await _closeRun(PipelineRunStatus.completed, state: summary);
    } on Object catch (e) {
      _onError?.call('code-index run completion report failed: $e');
    }
  }

  @override
  Future<void> fail(Object error, [StackTrace? stackTrace]) async {
    try {
      // Unlike finish: publish even when nothing was reported. An index that
      // threw before it parsed a file (a missing grammar, an unreadable tree) is
      // exactly the run an operator needs to see.
      await _ensureRun(PipelineRunStatus.running);
      final stepRunId = _stepRunId;
      if (stepRunId == null) {
        return;
      }
      await _runs.updateStepRun(
        workspaceId,
        stepRunId,
        status: PipelineStepStatus.failed,
        errorMessage: '$error',
        errorStackTrace: stackTrace?.toString(),
        finishedAt: _now(),
      );
      await _closeRun(
        PipelineRunStatus.failed,
        errorMessage: '$error',
        errorStackTrace: stackTrace?.toString(),
      );
    } on Object catch (e) {
      _onError?.call('code-index run failure report failed: $e');
    }
  }

  /// Writes the run + its two step rows on first use.
  ///
  /// The `trigger` node gets a completed row it never executed, because the run
  /// detail renders the template's graph and maps step rows onto it: without it
  /// the entry node of every background run reads as never-fired.
  Future<void> _ensureRun(PipelineRunStatus status) async {
    if (_runId != null) {
      return;
    }
    final runId = _idFactory();
    await _runs.insertRun(
      PipelineRun(
        id: runId,
        templateId: IndexCodeTemplate.id,
        workspaceId: workspaceId,
        status: status,
        triggerEventType: IndexCodeTemplate.watchTriggerEventType,
        triggerPayload: {
          'workspace_id': workspaceId,
          'repo_id': repoId,
          'repo_local_path': repoPath,
          if (checkoutId != null) 'checkout_id': checkoutId,
          // What the run is attributed to. Everything above identifies WHICH
          // checkout; this is the only part that answers why it ran, and
          // without it every row in a run of these is indistinguishable.
          ...cause.toJson(),
        },
        startedAt: _startedAt,
        lastResumedAt: _startedAt,
      ),
    );
    _runId = runId;
    await _runs.insertStepRun(
      PipelineStepRun(
        id: _idFactory(),
        pipelineRunId: runId,
        stepId: IndexCodeTemplate.triggerStepId,
        status: PipelineStepStatus.completed,
        startedAt: _startedAt,
        finishedAt: _startedAt,
      ),
    );
    final stepRunId = _idFactory();
    await _runs.insertStepRun(
      PipelineStepRun(
        id: stepRunId,
        pipelineRunId: runId,
        stepId: IndexCodeTemplate.indexStepId,
        status: PipelineStepStatus.running,
        startedAt: _startedAt,
      ),
    );
    _stepRunId = stepRunId;
  }

  Future<void> _closeRun(
    PipelineRunStatus status, {
    Map<String, dynamic>? state,
    String? errorMessage,
    String? errorStackTrace,
  }) async {
    final runId = _runId;
    if (runId == null) {
      return;
    }
    final run = await _runs.getRun(runId);
    if (run == null || run.isTerminal) {
      return;
    }
    final now = _now();
    // State first, and through its own writer: `updateRun` writes the run's
    // LIFECYCLE only and ignores the `state` on the object handed to it (see
    // [PipelineRunRepository.updateRun]). Writing it here also keeps the
    // ordering the reader needs — the summary is on the row before the status
    // says the run is done.
    if (state != null && state.isNotEmpty) {
      await _runs.updateRunState(runId, {...run.state, ...state});
    }
    await _runs.updateRun(
      run.copyWith(
        status: status,
        finishedAt: now,
        // Indexing has no suspend/resume, so its whole life is one active
        // segment: the engine's fold reduces to elapsed time.
        activeMs: now.difference(run.startedAt).inMilliseconds,
        lastResumedAt: null,
        errorMessage: errorMessage,
        errorStackTrace: errorStackTrace,
      ),
    );
  }

  /// Samples the published run for an operator cancel (the Stop button on the
  /// run, or the repo index button's cancel). The watcher hands
  /// [cancelRequested] to the indexer, so a cancel stops the real work at the
  /// next file instead of only relabelling the row.
  Future<void> _refreshCancellation() async {
    final runId = _runId;
    if (runId == null || _cancelRequested) {
      return;
    }
    final run = await _runs.getRun(runId);
    if (run == null) {
      return;
    }
    if (run.status == PipelineRunStatus.cancelled) {
      _cancelRequested = true;
    }
  }
}
