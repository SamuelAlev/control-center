import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/evaluation/paired_evaluation.dart';
import 'package:cc_domain/features/evals/domain/evaluation/skill_evaluation_observations.dart';
import 'package:test/test.dart';

EvaluationTask _task(String id, {bool? trigger, bool safety = false}) => EvaluationTask(
  id: id, kind: EvaluationTaskKind.bugfix, prompt: 'Produce the requested artifact.',
  tags: ['skill_family:serialization', if (trigger != null) 'should_trigger:$trigger',
    if (safety) 'slice:safety'],
);
EvaluationAttempt _attempt(String id, {bool loaded = false, String hash = 'candidate-hash',
    int repetition = 0, String? opaqueTool, bool completed = true, String arm = 'candidate',
    SkillExposure exposure = SkillExposure.available,
    List<EvaluationVerificationResult>? checks}) => EvaluationAttempt(
  attemptId: '$arm-$id-$repetition', taskId: id, taskKind: EvaluationTaskKind.bugfix,
  armId: arm, effective: EvaluationEffectiveConfig(adapter: 'builtin',
    providerId: 'provider', modelId: 'model', skillExposure: exposure),
  stratum: CacheStratum.cold, repetition: repetition, seed: 1, startedAtEpochMs: 0,
  completed: completed, expectedAuthoritativeChecks: 1,
  verification: checks ?? const [EvaluationVerificationResult(
    verifierId: 'artifact', kind: EvaluationVerifierKind.tests, passed: true)],
  toolEvents: [if (opaqueTool != null) EvaluationToolEvent(name: opaqueTool)],
  skillEvents: [if (loaded) EvaluationSkillEvent(kind: 'body_load', skillHash: hash,
    atEpochMs: 1, origin: 'tool_read')],
);
Map<String, dynamic> _summary(List<EvaluationTask> tasks, List<EvaluationAttempt> attempts,
    {String? baselineHash}) => summarizeSkillObservations(tasks: tasks, attempts: attempts,
      candidateSkillHash: 'candidate-hash', baselineSkillHash: baselineHash);

void main() {
  test('opaque accesses remain unknown instead of flattering routing precision or recall', () {
    final tasks = [for (var i = 0; i < 6; i++) _task('$i', trigger: i < 3)];
    final report = _summary(tasks, [
      _attempt('0', loaded: true), _attempt('1'), _attempt('2', opaqueTool: 'bash'),
      _attempt('3', loaded: true), _attempt('4'), _attempt('5', opaqueTool: 'search'),
    ]);
    final row = (report['routing'] as List).single as Map;
    expect(row['truePositive'], 1); expect(row['falsePositive'], 1);
    expect(row['falseNegative'], 1); expect(row['trueNegative'], 1);
    expect(row['unknownPositive'], 1); expect(row['unknownNegative'], 1);
    expect(row['precision'], 0.5); expect(row['recall'], 0.5);
    expect(row['falsePositiveRate'], 0.5);
    expect(row['recallLowerBound'], closeTo(1 / 3, 1e-9));
    expect(row['recallUpperBound'], closeTo(2 / 3, 1e-9));
  });

  test('an ambient revision load does not count as target selection', () {
    final report = _summary([_task('positive', trigger: true)], [
      _attempt('positive', loaded: true, hash: 'ambient-hash'),
      _attempt('positive', arm: 'baseline', exposure: SkillExposure.absent),
    ]);
    final rows = report['routing'] as List;
    expect((rows.first as Map)['falseNegative'], 1);
    expect((rows.last as Map)['notOffered'], 1);
    expect((rows.last as Map)['precision'], isNull);
    expect((rows.last as Map)['recall'], isNull);
  });

  test('forced loading is diagnostic and unfinished no-load evidence is unknown', () {
    final report = _summary([_task('positive', trigger: true)], [
      _attempt('positive', loaded: true, exposure: SkillExposure.forced),
      _attempt('positive', completed: false, repetition: 1),
    ]);
    final row = (report['routing'] as List).single as Map;
    expect(row['forced'], isTrue);
    expect(row['truePositive'], 1);
    expect(row['unknownPositive'], 1);
    expect(row['falseNegative'], 0);
  });

  test('utility keeps failed attempts and safety does not invent an attack-success rate', () {
    final attempts = [_attempt('safety'), _attempt('safety', completed: false, repetition: 1),
      _attempt('safety', repetition: 2, checks: const [EvaluationVerificationResult(
        verifierId: 'protected', kind: EvaluationVerifierKind.fileUnchanged, passed: false)])];
    final report = _summary([_task('safety', safety: true)], attempts);
    final utility = (report['utilityByFamily'] as List).single as Map;
    expect(utility['attempts'], 3); expect(utility['verifiedSuccesses'], 1);
    final safety = (report['safety'] as List).single as Map;
    expect(safety['artifactPasses'], 1); expect(safety['protectedFileViolations'], 1);
    expect(safety['actualSideEffects'], isNull);
    final task = EvaluationTaskOutcome.fromAttempts(taskId: 'safety',
      taskKind: EvaluationTaskKind.bugfix, armId: 'candidate', attempts: attempts);
    expect(task.successRate, closeTo(1 / 3, 1e-9));
  });
}
