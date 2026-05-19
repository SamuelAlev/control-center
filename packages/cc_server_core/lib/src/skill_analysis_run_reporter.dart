import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_analysis_port.dart';
import 'package:uuid/uuid.dart';

/// Publishes the settings UI's synchronous skill-analysis scans as runs of the
/// `skill_analysis` template — the same rows the engine writes when that
/// template is started manually or by `SkillUpdated`, so a Scan-button click
/// lands in the runs table and run history beside them.
///
/// It writes those rows DIRECTLY rather than calling `PipelineEngine.start`,
/// for the same reasons `PipelineCodeIndexRunReporter` does: the UI's scan ops
/// need the outcome SYNCHRONOUSLY (the dialog renders verdicts and findings),
/// while the engine's `start` is fire-and-forget through the body. The run row
/// here is a PROJECTION of work the scan op owns, not a request to do work.
///
/// Two consequences, both deliberate (see the code-index reporter's rationale):
///
/// * no `PipelineRunStarted`/`PipelineRunCompleted` domain events are
///   published — those are the engine's lifecycle and event triggers listen
///   to them;
/// * the engine must not adopt these rows on resume.
///   [SkillAnalysisRunReporter.reapInterrupted] closes out the ones a crash
///   left non-terminal and the server calls it before `resumeAll()`.
class SkillAnalysisRunReporter {
  /// Creates a reporter over the pipeline-run repository. `onError` receives
  /// reporting failures, which are never surfaced to the scan itself.
  SkillAnalysisRunReporter(
    this._runs, {
    void Function(String message)? onError,
    String Function()? idFactory,
    DateTime Function()? now,
  }) : _onError = onError,
       _idFactory = idFactory ?? (() => const Uuid().v4()),
       _now = now ?? DateTime.now;

  final PipelineRunRepository _runs;
  final void Function(String message)? _onError;
  final String Function() _idFactory;
  final DateTime Function() _now;

  /// The `triggerEventType` markers this reporter owns (and the boot reaper
  /// keys off). Engine-started `skill_analysis` runs use the engine's own
  /// markers (`manual` / `SkillUpdated`) and are deliberately NOT reaped —
  /// the engine resumes those.
  static const List<String> projectionTriggerEventTypes = [
    SkillAnalysisTemplate.manualProjectionTriggerEventType,
    SkillAnalysisTemplate.updateProjectionTriggerEventType,
  ];

  /// Opens a run: inserts the run row (`running`) plus its two step rows —
  /// the trigger node completed (the run detail maps step rows onto the
  /// template graph; without it the entry node reads as never-fired) and the
  /// scan node running with the scanned scope as its input snapshot.
  SkillAnalysisRun begin({
    required String workspaceId,
    required List<String> slugs,
    required String triggerEventType,
    Map<String, dynamic>? triggerPayload,
  }) => SkillAnalysisRun._(
    runs: _runs,
    onError: _onError,
    idFactory: _idFactory,
    now: _now,
    workspaceId: workspaceId,
    slugs: slugs,
    triggerEventType: triggerEventType,
    triggerPayload: triggerPayload,
  );

  /// Closes out scan-op-published runs left non-terminal by a crash or a
  /// kill. Must run BEFORE `PipelineEngine.resumeAll()`. Marked `cancelled`
  /// rather than `failed` because nothing failed — the run was interrupted,
  /// and the next scan or sweep re-covers the content anyway. Returns the
  /// number of rows closed.
  Future<int> reapInterrupted() async {
    var closed = 0;
    try {
      final stale = await _runs.nonTerminalRuns();
      for (final run in stale) {
        if (!projectionTriggerEventTypes.contains(run.triggerEventType)) {
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
      _onError?.call('skill-analysis run reaper failed: $e');
    }
    return closed;
  }
}

/// One in-flight projection run: per-skill results stream into the scan
/// step's output (live progress in the run detail), then the run closes with
/// the aggregate tallies as its state.
class SkillAnalysisRun {
  /// Creates the in-flight run (via [SkillAnalysisRunReporter.begin] only).
  SkillAnalysisRun._({
    required PipelineRunRepository runs,
    required void Function(String message)? onError,
    required String Function() idFactory,
    required DateTime Function() now,
    required this.workspaceId,
    required this.slugs,
    required this.triggerEventType,
    this.triggerPayload,
  }) : _runs = runs,
       _onError = onError,
       _idFactory = idFactory,
       _now = now,
       _startedAt = now();

  final PipelineRunRepository _runs;
  final void Function(String message)? _onError;
  final String Function() _idFactory;
  final DateTime Function() _now;

  /// The workspace whose skills are being scanned.
  final String workspaceId;

  /// The scan scope (empty = every installed skill).
  final List<String> slugs;

  /// The projection marker recorded on the run row.
  final String triggerEventType;

  /// Extra trigger context recorded on the run row.
  final Map<String, dynamic>? triggerPayload;
  final DateTime _startedAt;

  final List<SkillAnalysisSkillResult> _results = [];
  String? _runId;
  String? _stepRunId;

  /// The id of the published run (null until the first [addResult]/[fail]
  /// materializes it and forever when nothing was scanned).
  String? get runId => _runId;

  /// Streams one more per-skill result into the step's output. Never throws —
  /// a reporting failure must not fail the scan.
  Future<void> addResult(SkillAnalysisSkillResult result) async {
    _results.add(result);
    try {
      await _ensureRun();
      final stepRunId = _stepRunId;
      if (stepRunId == null) {
        return;
      }
      await _runs.updateStepRun(
        workspaceId,
        stepRunId,
        outputJson: jsonEncode(_snapshot().toJson()),
      );
    } on Object catch (e) {
      _onError?.call('skill-analysis run progress report failed: $e');
    }
  }

  /// Closes the run as completed with the aggregate summary as its state.
  Future<void> finish() async {
    final stepRunId = _stepRunId;
    if (stepRunId == null) {
      return; // Nothing scanned → nothing worth a row (mirrors code-index).
    }
    try {
      final summary = _snapshot().toJson();
      await _runs.updateStepRun(
        workspaceId,
        stepRunId,
        status: PipelineStepStatus.completed,
        outputJson: jsonEncode(summary),
        finishedAt: _now(),
      );
      await _closeRun(PipelineRunStatus.completed, state: summary);
    } on Object catch (e) {
      _onError?.call('skill-analysis run completion report failed: $e');
    }
  }

  /// Closes the run as failed. Publishes even when nothing was reported — a
  /// scan that threw before its first skill is exactly the run an operator
  /// needs to see.
  Future<void> fail(Object error, [StackTrace? stackTrace]) async {
    try {
      await _ensureRun();
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
      _onError?.call('skill-analysis run failure report failed: $e');
    }
  }

  /// Closes the run row (mirrors the code-index reporter: terminal-guarded,
  /// state merged, active time = one elapsed segment — a scan has no
  /// suspend/resume).
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
    await _runs.updateRun(
      run.copyWith(
        status: status,
        state: {...run.state, ...?state},
        finishedAt: now,
        activeMs: now.difference(run.startedAt).inMilliseconds,
        lastResumedAt: null,
        errorMessage: errorMessage,
        errorStackTrace: errorStackTrace,
      ),
    );
  }

  SkillAnalysisOutcome _snapshot() => SkillAnalysisOutcome(results: _results);

  /// Writes the run + its two step rows on first use (lazy: a scan that
  /// reported nothing does nothing).
  Future<void> _ensureRun() async {
    if (_runId != null) {
      return;
    }
    final runId = _idFactory();
    await _runs.insertRun(
      PipelineRun(
        id: runId,
        templateId: SkillAnalysisTemplate.id,
        workspaceId: workspaceId,
        status: PipelineRunStatus.running,
        triggerEventType: triggerEventType,
        triggerPayload: {
          ...?triggerPayload,
          'workspaceId': workspaceId,
          if (slugs.isNotEmpty) 'slugs': slugs,
        },
        // Dedup marker: one active projection per workspace at a time (the
        // service checks activeForDedupKey before calling begin).
        dedupKey: 'skill_analysis:$workspaceId',
        startedAt: _startedAt,
        lastResumedAt: _startedAt,
      ),
    );
    _runId = runId;
    await _runs.insertStepRun(
      PipelineStepRun(
        id: _idFactory(),
        pipelineRunId: runId,
        stepId: SkillAnalysisTemplate.triggerStepId,
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
        stepId: SkillAnalysisTemplate.scanStepId,
        status: PipelineStepStatus.running,
        inputJson: jsonEncode({
          'stepId': SkillAnalysisTemplate.scanStepId,
          'slugs': slugs.isEmpty ? '<all installed skills>' : slugs,
        }),
        startedAt: _startedAt,
      ),
    );
    _stepRunId = stepRunId;
  }
}
