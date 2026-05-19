import 'dart:convert';

import 'package:cc_domain/features/evals/domain/entities/evals_entities.dart';
import 'package:cc_domain/features/evals/domain/repositories/evals_repository.dart';
import 'package:cc_domain/features/evals/domain/services/eval_graders.dart';
import 'package:cc_domain/features/evals/domain/value_objects/eval_outcome.dart';
import 'package:cc_domain/features/evals/domain/value_objects/eval_scorecard.dart';
import 'package:cc_domain/features/evals/domain/value_objects/eval_task.dart';

/// Executes one repetition of an eval task and returns its observed outcome.
/// The runtime injects this (dispatch into a throwaway worktree, live model);
/// the domain runner stays pure and testable.
typedef EvalTaskExecutor =
    Future<EvalOutcome> Function(EvalTask task, int repetitionIndex);

/// Grades an outcome with an LLM-rubric judge (PRD 21 §5). Optional — injected
/// only when the runtime has an LLM; deterministic graders never need it.
typedef JudgeGraderRunner =
    Future<GradeResult> Function(GraderSpec spec, EvalOutcome outcome);

/// Runs an eval suite as an N-repetition batch and produces a scorecard
/// (PRD 21 §5). Deterministic graders run in-process (free, exact); judge
/// graders defer to the judge runner when provided. Batch statistics only —
/// never
/// a single-run verdict (spec adversarial review).
class EvalRunner {
  /// Creates an [EvalRunner].
  EvalRunner({
    required EvalsRepository repository,
    required EvalTaskExecutor executor,
    JudgeGraderRunner? judgeRunner,
    DateTime Function()? now,
    String Function()? newId,
  }) : _repo = repository,
       _executor = executor,
       _judgeRunner = judgeRunner,
       _now = now ?? DateTime.now,
       _newId = newId ?? _defaultId;

  final EvalsRepository _repo;
  final EvalTaskExecutor _executor;
  final JudgeGraderRunner? _judgeRunner;
  final DateTime Function() _now;
  final String Function() _newId;

  static int _counter = 0;
  static String _defaultId() =>
      'eval-${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

  /// Runs [suite] as a batch against [configHash] and returns the scorecard.
  /// Persists an [EvalRun] row (queued → running → done) and the scorecard.
  Future<EvalScorecard> runSuite({
    required EvalSuite suite,
    required String configHash,
    int? batchSize,
    String triggeredBy = 'manual',
    String? runId,
    String? jobId,
  }) async {
    final size = batchSize ?? suite.defaultBatchSize;
    final id = runId ?? _newId();
    final task = EvalTask.fromJsonString(suite.taskJson);
    final graderSpecs = _parseGraders(suite.gradersJson);

    await _repo.upsertRun(
      EvalRun(
        id: id,
        workspaceId: suite.workspaceId,
        suiteId: suite.id,
        configHash: configHash,
        batchSize: size,
        status: 'running',
        triggeredBy: triggeredBy,
        jobId: jobId,
        createdAt: _now(),
        startedAt: _now(),
      ),
    );

    final reps = <EvalRepetitionResult>[];
    var totalCost = 0;
    try {
      for (var i = 0; i < size; i++) {
        final outcome = await _executor(task, i);
        totalCost += outcome.costCents;
        final grades = await _gradeOutcome(graderSpecs, outcome);
        reps.add(EvalRepetitionResult(outcome: outcome, grades: grades));
      }
    } on Object catch (e) {
      // A batch-level failure still records what ran; never leaves it "running".
      final partial = EvalScorecard.fromReps(reps);
      await _repo.updateRunResult(
        suite.workspaceId,
        id,
        status: 'failed',
        scorecardJson: jsonEncode({...partial.toJson(), 'error': e.toString()}),
        passRate: partial.passRate,
        costCents: totalCost,
        finishedAt: _now(),
      );
      rethrow;
    }

    final scorecard = EvalScorecard.fromReps(reps);
    await _repo.updateRunResult(
      suite.workspaceId,
      id,
      status: 'done',
      scorecardJson: scorecard.toJsonString(),
      passRate: scorecard.passRate,
      costCents: totalCost,
      finishedAt: _now(),
    );
    return scorecard;
  }

  Future<List<GradeResult>> _gradeOutcome(
    List<GraderSpec> specs,
    EvalOutcome outcome,
  ) async {
    final results = <GradeResult>[];
    for (final spec in specs) {
      final deterministic = spec.build();
      if (deterministic != null) {
        results.add(deterministic.grade(outcome));
      } else if (_judgeRunner != null) {
        results.add(await _judgeRunner(spec, outcome));
      } else {
        // No judge available — record an explicit skip, never a silent pass.
        results.add(
          GradeResult(
            graderId: spec.id,
            passed: false,
            score: 0,
            detail: 'Judge grader skipped (no LLM judge wired).',
          ),
        );
      }
    }
    return results;
  }

  List<GraderSpec> _parseGraders(String gradersJson) {
    final decoded = gradersJson.trim().isEmpty
        ? const []
        : jsonDecode(gradersJson) as List;
    if (decoded.isEmpty) {
      // A suite with no graders still checks the run completed.
      return const [GraderSpec(type: 'outcome_success', id: 'outcome_success')];
    }
    return decoded
        .map((e) => GraderSpec.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
