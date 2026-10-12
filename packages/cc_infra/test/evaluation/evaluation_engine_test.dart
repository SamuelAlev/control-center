import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_backend_port.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/services/eval_graders.dart';
import 'package:cc_domain/features/observability/domain/benchmark.dart';
import 'package:cc_infra/src/evaluation/backends/replay_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/evaluation_artifacts.dart';
import 'package:cc_infra/src/evaluation/evaluation_benchmark_bridge.dart';
import 'package:cc_infra/src/evaluation/evaluation_engine.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Orchestration is exercised through a scripted backend: it performs REAL
/// filesystem writes in the REAL isolated workspace, and the engine's real
/// verifiers then decide the outcome. No model is involved, so nothing here
/// claims a model-quality result — the live path is covered by the CLI.
class _ScriptedBackend implements EvaluationBackendPort {
  _ScriptedBackend({
    this.writes = const {},
    this.throwForTask = const {},
    this.refuseNatively = const {},
    this.priced = true,
    this.servedModel,
  }) : completes = true;

  /// Whether the scripted attempt reports priced spend (micro-USD).
  final bool priced;

  /// Memory policies this backend pretends not to implement, for the
  /// preflight-refusal test.
  final Set<MemoryPolicyMode> refuseNatively;

  /// taskId → (workspace-relative path, content) written by the "agent".
  final Map<String, Map<String, String>> writes;

  /// taskIds whose attempt faults in the backend.
  final Set<String> throwForTask;

  /// Whether attempts report a clean terminal state.
  final bool completes;

  final String? servedModel;

  @override
  String get id => 'scripted';

  @override
  bool get callsModel => true;

  @override
  String? unsupportedReason(EvaluationEffectiveConfig effective) =>
      refuseNatively.contains(effective.memoryPolicy)
      ? 'scripted backend cannot run ${effective.memoryPolicy.wire}'
      : null;

  @override
  Future<EvaluationAttempt> execute(EvaluationAttemptRequest request) async {
    if (throwForTask.contains(request.task.id)) {
      throw StateError('scripted harness fault for ${request.task.id}');
    }
    for (final entry in (writes[request.task.id] ?? const {}).entries) {
      final file = File(p.join(request.workspaceRoot, entry.key));
      file.parent.createSync(recursive: true);
      await file.writeAsString(entry.value);
    }
    return EvaluationAttempt(
      attemptId: request.attemptId,
      taskId: request.task.id,
      taskKind: request.task.kind,
      armId: request.arm.id,
      effective: request.effective,
      stratum: request.stratum,
      repetition: request.repetition,
      seed: request.seed,
      ordinal: request.ordinal,
      startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      completed: completes,
      servedModel: servedModel,
      error: completes ? null : 'scripted incomplete',
      cost: priced
          ? const EvaluationCostRoles(estimatedApiMicros: 70000)
          : const EvaluationCostRoles(),
      metrics: const EvaluationAttemptMetrics(modelRoundTrips: 2),
      verification: const [],
    );
  }
}

EvaluationTask answerTask({String id = 'answer'}) => EvaluationTask(
  id: id,
  kind: EvaluationTaskKind.exploration,
  prompt: 'write the answer',
  verifiers: const [
    EvaluationVerifier(
      id: 'answer_is_right',
      kind: EvaluationVerifierKind.fileContains,
      params: {'path': 'answer.txt', 'needle': 'right'},
    ),
  ],
  graders: const [GraderSpec(type: 'outcome_success', id: 'completed')],
);

EvaluationPlan twoArmPlan({
  int repetitions = 2,
  ToolOverlapExperiment? overlapExperiment,
}) => EvaluationPlan(
  id: 'engine-test',
  seed: 11,
  arms: const [
    EvaluationArm(id: 'baseline', axis: EvaluationAxis.baseline),
    EvaluationArm(
      id: 'cheap',
      axis: EvaluationAxis.effortRouting,
      effortLevel: 'low',
    ),
  ],
  strata: [StratumSpec(stratum: CacheStratum.cold, repetitions: repetitions)],
  minPairs: 2,
  overlapExperiment: overlapExperiment,
);

EvaluationManifest manifestFor(EvaluationCorpus corpus) => EvaluationManifest(
  corpusId: corpus.id,
  corpusHash: corpus.corpusHash,
  adapter: 'scripted',
  providerId: 'anthropic',
  modelId: 'test-model',
);

void main() {
  late Directory scratch;

  setUp(() {
    scratch = Directory.systemTemp.createTempSync('cc_eval_engine');
  });

  tearDown(() {
    if (scratch.existsSync()) {
      scratch.deleteSync(recursive: true);
    }
  });

  EvaluationCorpus corpusOf(List<EvaluationTask> tasks) =>
      EvaluationCorpus(id: 'c', tasks: tasks);

  Future<EvaluationRunResult> runEngine({
    required EvaluationBackendPort backend,
    required EvaluationCorpus corpus,
    required EvaluationPlan plan,
    EvaluationManifest? manifest,
    bool dryRun = false,
    String? outDir,
  }) => EvaluationEngine(
    config: EvaluationEngineConfig(
      corpus: corpus,
      manifest: manifest ?? manifestFor(corpus),
      plan: plan,
      backend: backend,
      outDir: outDir ?? p.join(scratch.path, 'runs'),
      dryRun: dryRun,
    ),
  ).run();

  test(
    'native model namespaces remain part of the verified identity',
    () async {
      final corpus = corpusOf([answerTask()]);
      for (final (served, eligible) in [
        ('vendor/model', true),
        ('other/model', false),
      ]) {
        final result = await runEngine(
          backend: _ScriptedBackend(
            servedModel: served,
            writes: const {
              'answer': {'answer.txt': 'right'},
            },
          ),
          corpus: corpus,
          plan: twoArmPlan(),
          manifest: manifestFor(corpus).copyWith(modelId: 'vendor/model'),
          outDir: p.join(scratch.path, eligible ? 'matching' : 'mismatched'),
        );
        expect(
          result.report.attempts.map((attempt) => attempt.verifiedSuccess),
          everyElement(eligible),
        );
      }
    },
  );

  test(
    'verified success comes from the verifier, never from the backend',
    () async {
      final corpus = corpusOf([answerTask()]);
      final result = await runEngine(
        backend: _ScriptedBackend(
          writes: {
            'answer': {'answer.txt': 'the answer is right\n'},
          },
        ),
        corpus: corpus,
        plan: twoArmPlan(),
      );
      expect(result.report.attempts, hasLength(4));
      expect(result.report.attempts.every((a) => a.verifiedSuccess), isTrue);
      expect(
        result.report.attempts.first.verification
            .firstWhere((v) => v.proves)
            .provenance,
        VerificationProvenance.behavioral,
      );
      // The declarative grader is recorded but never authoritative.
      final grader = result.report.attempts.first.verification
          .where((v) => !v.authoritative)
          .toList();
      expect(grader, hasLength(1));
      expect(grader.single.verifierId, 'completed');
    },
  );

  test(
    'a completed run that fails its check is a FAIL, not a success',
    () async {
      final corpus = corpusOf([answerTask()]);
      final result = await runEngine(
        backend: _ScriptedBackend(
          writes: {
            'answer': {'answer.txt': 'the answer is wrong\n'},
          },
        ),
        corpus: corpus,
        plan: twoArmPlan(),
      );
      expect(result.report.attempts.every((a) => a.completed), isTrue);
      expect(result.report.attempts.every((a) => a.verifiedSuccess), isFalse);
      expect(result.report.attempts.first.verificationFailed, isTrue);
      final trial = result.benchmark.trials.first;
      expect(trial.status, TrialStatus.fail);
      expect(trial.reward, 0);
    },
  );

  test(
    'a backend fault is an error attempt and the campaign continues',
    () async {
      final corpus = corpusOf([answerTask(), answerTask(id: 'answer2')]);
      final result = await runEngine(
        backend: _ScriptedBackend(
          writes: {
            'answer2': {'answer.txt': 'right\n'},
          },
          throwForTask: {'answer'},
        ),
        corpus: corpus,
        plan: twoArmPlan(repetitions: 1),
      );
      expect(result.report.attempts, hasLength(4));
      final faulted = result.report.attempts
          .where((a) => !a.completed)
          .toList();
      expect(faulted, hasLength(2));
      expect(faulted.first.error, contains('scripted harness fault'));
      expect(faulted.every((a) => !a.verifiedSuccess), isTrue);
      expect(result.report.unknowns.any((u) => u.contains('faulted')), isTrue);
      // The healthy task still produced verified successes.
      expect(
        result.report.attempts
            .where((a) => a.taskId == 'answer2')
            .every((a) => a.verifiedSuccess),
        isTrue,
      );
    },
  );

  test('writes the manifest, attempts stream, recordings and report', () async {
    final corpus = corpusOf([answerTask()]);
    final result = await runEngine(
      backend: _ScriptedBackend(
        writes: {
          'answer': {'answer.txt': 'right\n'},
        },
      ),
      corpus: corpus,
      plan: twoArmPlan(repetitions: 1),
    );
    final artifacts = result.artifacts;
    expect(
      File(p.join(artifacts.runDir, 'manifest.json')).existsSync(),
      isTrue,
    );
    expect(File(p.join(artifacts.runDir, 'plan.json')).existsSync(), isTrue);
    expect(File(p.join(artifacts.runDir, 'corpus.json')).existsSync(), isTrue);
    expect(File(artifacts.reportJsonPath).existsSync(), isTrue);
    expect(File(artifacts.reportMarkdownPath).existsSync(), isTrue);
    final persisted = await artifacts.readAttempts();
    expect(persisted, hasLength(2));
    expect(
      persisted.first.verification.where((v) => v.proves).isNotEmpty,
      isTrue,
    );
    // The workspace change was recorded as a patch and a cassette, so a replay
    // can re-verify it without the model.
    expect(Directory(artifacts.recordingsDir).listSync(), hasLength(2));
    final patchFile = File(
      p.join(artifacts.patchesDir, '${persisted.first.attemptId}.diff'),
    );
    expect(patchFile.existsSync(), isTrue);
    expect(persisted.first.filesTouched, contains('answer.txt'));
  });

  test('offline replay reproduces verdicts with no model call', () async {
    final corpus = corpusOf([answerTask()]);
    final live = await runEngine(
      backend: _ScriptedBackend(
        writes: {
          'answer': {'answer.txt': 'right\n'},
        },
      ),
      corpus: corpus,
      plan: twoArmPlan(repetitions: 1),
    );
    final replayed = await EvaluationEngine(
      config: EvaluationEngineConfig(
        corpus: corpus,
        manifest: manifestFor(corpus).copyWith(adapter: 'replay'),
        plan: twoArmPlan(repetitions: 1),
        backend: ReplayEvaluationBackend(
          recordingsDir: live.artifacts.recordingsDir,
        ),
        outDir: p.join(scratch.path, 'replay-runs'),
      ),
    ).run();
    expect(replayed.report.liveModelCalls, isFalse);
    expect(
      replayed.report.executionMode,
      EvaluationExecutionMode.offlineReplay,
    );
    expect(replayed.report.attempts.every((a) => a.verifiedSuccess), isTrue);
    expect(
      replayed.report.attempts
          .expand((a) => a.verification)
          .where((v) => v.proves)
          .every(
            (v) => v.provenance == VerificationProvenance.replayDeterministic,
          ),
      isTrue,
    );
  });

  test('a missing cassette is an error, never a synthesized pass', () async {
    final corpus = corpusOf([answerTask()]);
    final empty = p.join(scratch.path, 'empty-recordings');
    Directory(empty).createSync(recursive: true);
    final result = await EvaluationEngine(
      config: EvaluationEngineConfig(
        corpus: corpus,
        manifest: manifestFor(corpus).copyWith(adapter: 'replay'),
        plan: twoArmPlan(repetitions: 1),
        backend: ReplayEvaluationBackend(recordingsDir: empty),
        outDir: p.join(scratch.path, 'replay-missing'),
      ),
    ).run();
    expect(result.report.attempts, hasLength(2));
    expect(result.report.attempts.every((a) => !a.completed), isTrue);
    expect(result.report.attempts.every((a) => !a.verifiedSuccess), isTrue);
    expect(result.report.attempts.first.error, contains('no recording'));
  });

  test('refuses to run a plan that could silently lower the default', () async {
    final corpus = corpusOf([answerTask()]);
    const unsafe = EvaluationPlan(
      id: 'unsafe',
      arms: [
        EvaluationArm(
          id: 'overlap',
          axis: EvaluationAxis.toolOverlap,
          toolOverlap: ToolOverlapMode.overlapReadOnly,
        ),
      ],
    );
    await expectLater(
      runEngine(backend: _ScriptedBackend(), corpus: corpus, plan: unsafe),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('refusing to run'), contains('baseline')),
        ),
      ),
    );
  });

  test('refuses a manifest that does not describe the corpus', () async {
    final corpus = corpusOf([answerTask()]);
    await expectLater(
      runEngine(
        backend: _ScriptedBackend(),
        corpus: corpus,
        plan: twoArmPlan(),
        manifest: manifestFor(corpus).copyWith(corpusHash: 'stale'),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('does not match the corpus'),
        ),
      ),
    );
  });

  test(
    'refuses an arm the backend cannot actually implement, spending nothing',
    () async {
      final corpus = corpusOf([answerTask()]);
      const plan = EvaluationPlan(
        id: 'masking',
        seed: 1,
        arms: [
          EvaluationArm(id: 'baseline', axis: EvaluationAxis.baseline),
          EvaluationArm(
            id: 'masking',
            axis: EvaluationAxis.memoryPolicy,
            memoryPolicy: MemoryPolicyMode.masking,
          ),
        ],
        strata: [StratumSpec(stratum: CacheStratum.cold, repetitions: 1)],
        contextWindowTokens: 8192,
        minPairs: 2,
        memoryExperiment: MemoryPolicyExperiment(
          id: 'masking',
          enabled: true,
          mode: MemoryPolicyMode.masking,
        ),
      );
      final outDir = p.join(scratch.path, 'refused');
      await expectLater(
        runEngine(
          backend: _ScriptedBackend(
            refuseNatively: const {MemoryPolicyMode.masking},
          ),
          corpus: corpus,
          plan: plan,
          outDir: outDir,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('unimplementable'),
              contains('nothing was spent'),
              contains('masking'),
            ),
          ),
        ),
      );
      // Nothing was created, so no attempt and no report could claim the policy ran.
      expect(Directory(outDir).existsSync(), isFalse);
    },
  );

  test('refuses an unpinned model before executing any task', () async {
    final corpus = corpusOf([answerTask()]);
    await expectLater(
      runEngine(
        backend: _ScriptedBackend(),
        corpus: corpus,
        plan: twoArmPlan(),
        manifest: manifestFor(corpus).copyWith(modelId: '  '),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('pins no model'),
        ),
      ),
    );
  });

  test('a dry run records the schedule and executes nothing', () async {
    final corpus = corpusOf([answerTask()]);
    final result = await runEngine(
      backend: _ScriptedBackend(
        writes: {
          'answer': {'answer.txt': 'right\n'},
        },
      ),
      corpus: corpus,
      plan: twoArmPlan(repetitions: 2),
      dryRun: true,
    );
    expect(result.trials, hasLength(4));
    expect(result.report.attempts, isEmpty);
    expect(result.report.liveModelCalls, isFalse);
    expect(
      result.report.unknowns.any((u) => u.contains('no attempts')),
      isTrue,
    );
  });

  test(
    'records the cache-carryover and account caveats it cannot observe',
    () async {
      final corpus = corpusOf([answerTask()]);
      final result = await runEngine(
        backend: _ScriptedBackend(
          writes: {
            'answer': {'answer.txt': 'right\n'},
          },
        ),
        corpus: corpus,
        plan: twoArmPlan(repetitions: 1),
      );
      final codes = result.report.caveats.map((c) => c.code).toList();
      expect(codes, contains('paired_cache_carryover'));
      expect(codes, contains('account_attribution_unobserved'));
    },
  );

  test('an uncosted attempt is reported as unknown cost, not free', () async {
    final corpus = corpusOf([answerTask()]);
    final result = await runEngine(
      backend: _ScriptedBackend(
        priced: false,
        writes: {
          'answer': {'answer.txt': 'right\n'},
        },
      ),
      corpus: corpus,
      plan: EvaluationPlan(
        id: 'nocost',
        seed: 1,
        arms: twoArmPlan().arms,
        strata: [const StratumSpec(stratum: CacheStratum.cold)],
        minPairs: 2,
      ),
    );
    expect(result.report.attempts.first.cost.isEmpty, isTrue);
    expect(result.benchmark.totalCostMicros, isNull);
    expect(
      const BenchmarkScorer().successAdjustedCostCents(result.benchmark),
      isNull,
    );
  });

  test('the benchmark bridge keeps error and failure apart', () async {
    final corpus = corpusOf([answerTask(), answerTask(id: 'answer2')]);
    final result = await runEngine(
      backend: _ScriptedBackend(
        writes: {
          'answer': {'answer.txt': 'wrong\n'},
          'answer2': {'answer.txt': 'right\n'},
        },
        throwForTask: {'answer2'},
      ),
      corpus: corpus,
      plan: twoArmPlan(repetitions: 1),
    );
    final statuses = <TrialStatus>{
      for (final trial in result.benchmark.trials) trial.status,
    };
    expect(statuses, containsAll([TrialStatus.fail, TrialStatus.error]));
    expect(
      const EvaluationBenchmarkBridge()
          .markdown(result.benchmark)
          .contains('success-adjusted cost'),
      isTrue,
    );
    // Harness errors do not become product failures or zero-cost trials.
    expect(result.benchmark.errorCount, 2);
    expect(
      const BenchmarkScorer().successAdjustedCostCents(result.benchmark),
      isNull,
    );
  });
}
