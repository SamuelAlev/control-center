import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/evaluation/paired_evaluation.dart';
import 'package:cc_domain/features/observability/domain/benchmark.dart';
import 'package:cc_infra/src/evaluation/evaluation_artifacts.dart';
import 'package:cc_infra/src/evaluation/evaluation_benchmark_bridge.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Guards the SHIPPED corpus and plans: they are executable artifacts, so a
/// plan that would be rejected at run time, a task with no independent
/// evidence, or a missing task class is a bug in the repository, not a runtime
/// surprise in someone's paid campaign.
void main() {
  final root = _repositoryEvalDir();
  late EvaluationCorpus corpus;

  setUpAll(() async {
    corpus = await EvaluationCorpus.read(p.join(root, 'corpus.json'));
  });

  test('the corpus is well formed', () {
    expect(corpus.id, isNotEmpty);
    expect(corpus.idsAreUnique, isTrue);
    expect(corpus.tasks, isNotEmpty);
    expect(corpus.corpusHash, startsWith('sha256:'));
  });

  test('covers every task class the report requires', () {
    final kinds = {for (final task in corpus.tasks) task.kind};
    for (final kind in EvaluationTaskKind.values) {
      expect(
        kinds,
        contains(kind),
        reason: 'corpus must cover ${kind.wire} (HARNESS_RESEARCH §6)',
      );
    }
  });

  test('every task carries independent behavioral evidence', () {
    for (final task in corpus.tasks) {
      expect(
        task.verifiers.where((v) => v.authoritative),
        isNotEmpty,
        reason: '${task.id} has no authoritative acceptance check',
      );
      expect(
        task.prompt.trim(),
        isNotEmpty,
        reason: '${task.id} has no prompt',
      );
      for (final verifier in task.verifiers) {
        expect(
          _requiredParams(verifier).every(verifier.params.containsKey),
          isTrue,
          reason:
              '${task.id}/${verifier.id} is missing a required '
              '${verifier.kind.wire} parameter',
        );
      }
    }
  });

  test('authoritative command checks run programs outside the workspace', () {
    for (final task in corpus.tasks) {
      for (final verifier in task.effectiveVerifiers()) {
        if (!verifier.authoritative) {
          continue;
        }
        if (verifier.kind != EvaluationVerifierKind.commandExit &&
            verifier.kind != EvaluationVerifierKind.tests) {
          continue;
        }
        expect(
          verifier.params['trustedScript'],
          isA<String>(),
          reason:
              '${task.id}/${verifier.id} is an authoritative command check '
              'without a trustedScript, so the candidate could replace it',
        );
        expect(
          (verifier.params['trustedScript']! as String).trim(),
          isNotEmpty,
          reason: '${task.id}/${verifier.id} has an empty trustedScript',
        );
      }
    }
  });

  test('protected fixtures carry real sha256 digests', () {
    var protected = 0;
    for (final task in corpus.tasks) {
      for (final entry in task.protectedFiles.entries) {
        protected++;
        expect(
          RegExp(r'^[0-9a-f]{64}$').hasMatch(entry.value),
          isTrue,
          reason: '${task.id}/${entry.key} has no real sha256 digest',
        );
        expect(
          task.inlineFiles.containsKey(entry.key),
          isTrue,
          reason:
              '${task.id}/${entry.key} is protected but not part of the '
              'fixture, so its digest cannot be pinned',
        );
      }
    }
    // The corpus must actually use the mechanism it relies on.
    expect(protected, greaterThan(0));
  });

  test('the corpus exercises the retry and barrier scenarios', () {
    expect(corpus.tasks.any((t) => t.tags.contains('barrier')), isTrue);
    expect(corpus.tasks.any((t) => t.tags.contains('retry')), isTrue);
    expect(corpus.tasks.any((t) => t.tags.contains('overlap_safe')), isTrue);
  });

  test('at least one multi-turn task exercises session continuity', () {
    expect(corpus.tasks.any((t) => t.followUps.isNotEmpty), isTrue);
  });

  test('every shipped plan is runnable against the corpus', () async {
    final plansDir = Directory(p.join(root, 'plans'));
    final planFiles = plansDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();
    expect(planFiles, isNotEmpty);
    for (final file in planFiles) {
      final plan = EvaluationPlan.fromJson(
        (jsonDecode(await file.readAsString()) as Map).cast<String, dynamic>(),
      );
      expect(
        plan.violations(corpus.tasks),
        isEmpty,
        reason: '${p.basename(file.path)} would be refused at run time',
      );
      // Every plan must contain a baseline so non-inferiority is decidable.
      expect(plan.baselineArm, isNotNull);
      // The scheduled trial set must be non-empty and paired.
      final trials = plan.schedule(corpus.tasks);
      expect(trials, isNotEmpty);
      expect(trials.length % plan.arms.length, 0);
    }
  });

  test('opt-in experiments ship switched on only with their guard rails', () {
    final files = Directory(p.join(root, 'plans')).listSync().whereType<File>();
    for (final file in files) {
      final plan = EvaluationPlan.fromJson(
        (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>(),
      );
      final experiment = plan.memoryExperiment;
      if (experiment != null && experiment.enabled) {
        expect(
          plan.arms.any((a) => a.memoryPolicy == experiment.mode),
          isTrue,
          reason:
              '${p.basename(file.path)} enables ${experiment.id} with no arm',
        );
        if (experiment.mode == MemoryPolicyMode.snapshotImages) {
          expect(experiment.fidelityVerifiers, isNotEmpty);
        }
      }
      final overlap = plan.overlapExperiment;
      if (overlap != null && overlap.enabled) {
        expect(overlap.requiresBarrierCoverage, isTrue);
      }
      final policy = plan.routePolicy;
      if (policy != null && policy.enabled) {
        expect(policy.optedInBy, isNotEmpty);
        expect(plan.arms.any((a) => a.taskRoutePolicyId == policy.id), isTrue);
        // Routing may only touch classes whose evidence is behavioral.
        for (final task in corpus.tasks) {
          if (policy.decisionFor(task) == null) {
            continue;
          }
          expect(
            task.independentlyCheckable,
            isTrue,
            reason:
                'plan routes ${task.id}, whose evidence is not fully '
                'behavioral',
          );
        }
      }
    }
  });

  test('an example report renders for a two-arm attempt set', () async {
    final artifacts = await EvaluationArtifacts.create(
      Directory.systemTemp.createTempSync('cc_eval_report').path,
      'render',
    );
    addTearDown(() {
      final dir = Directory(artifacts.runDir).parent;
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });
    final task = corpus.tasks.first;
    final attempts = [
      for (final arm in ['baseline', 'cheap'])
        for (var i = 0; i < 9; i++)
          EvaluationAttempt(
            attemptId: '$arm-$i',
            taskId: task.id,
            taskKind: task.kind,
            armId: arm,
            effective: const EvaluationEffectiveConfig(
              adapter: 'builtin',
              providerId: 'anthropic',
              modelId: 'm',
            ),
            stratum: CacheStratum.cold,
            repetition: i,
            seed: i,
            startedAtEpochMs: 0,
            completed: true,
            cost: EvaluationCostRoles(
              estimatedApiMicros: arm == 'cheap' ? 20000 : 50000,
            ),
            // Synthetic check data exercises rendering, not independent
            // evidence sufficient to change the quality default.
            expectedAuthoritativeChecks: 1,
            verification: [
              const EvaluationVerificationResult(
                verifierId: 'v',
                kind: EvaluationVerifierKind.commandExit,
                passed: true,
              ),
            ],
          ),
    ];
    final report = const EvaluationReportBuilder().build(
      manifest: EvaluationManifest(
        corpusId: corpus.id,
        corpusHash: corpus.corpusHash,
        adapter: 'builtin',
        providerId: 'anthropic',
        modelId: 'm',
      ),
      plan: const EvaluationPlan(
        id: 'render',
        seed: 1,
        arms: [
          EvaluationArm(id: 'baseline', axis: EvaluationAxis.baseline),
          EvaluationArm(id: 'cheap', axis: EvaluationAxis.effortRouting),
        ],
        // One stratum of nine repetitions, so the campaign is fully covered
        // (the coverage gate blocks adoption for a partial campaign).
        strata: [StratumSpec(stratum: CacheStratum.cold, repetitions: 9)],
        minPairs: 4,
      ),
      tasks: [task],
      attempts: attempts,
      generatedAtEpochMs: 1,
    );
    await artifacts.writeReport(report);
    expect(File(artifacts.reportMarkdownPath).existsSync(), isTrue);
    expect(report.verdicts.single.effectiveTaskCount, 1);
    expect(report.verdicts.single.verdict, QualityVerdict.inconclusive);
    expect(
      report.overallRecommendation,
      AdoptionRecommendation.keepQualityDefault,
    );
    final benchmark = const EvaluationBenchmarkBridge().toBenchmarkRun(report);
    expect(benchmark.passCount, attempts.length);
    expect(
      const BenchmarkScorer().successAdjustedCostCents(benchmark),
      isNotNull,
    );
  });
}

List<String> _requiredParams(EvaluationVerifier verifier) {
  switch (verifier.kind) {
    case EvaluationVerifierKind.commandExit:
    case EvaluationVerifierKind.tests:
      return verifier.authoritative
          ? const ['trustedScript']
          : const ['command'];
    case EvaluationVerifierKind.fileContains:
    case EvaluationVerifierKind.fileExcludes:
      return const ['path'];
    case EvaluationVerifierKind.diffApplies:
      return const ['patch'];
    case EvaluationVerifierKind.declarationExists:
      return const ['pattern'];
    case EvaluationVerifierKind.noWrites:
      return const [];
    case EvaluationVerifierKind.fileUnchanged:
      return const ['path', 'sha256'];
  }
}

/// Locates `packages/cc_infra/eval` regardless of the directory the test runner
/// was started from.
String _repositoryEvalDir() {
  final candidates = [
    p.join(Directory.current.path, 'eval'),
    p.join(Directory.current.path, 'packages', 'cc_infra', 'eval'),
  ];
  for (final candidate in candidates) {
    if (File(p.join(candidate, 'corpus.json')).existsSync()) {
      return candidate;
    }
  }
  throw StateError(
    'could not locate the evaluation corpus from ${Directory.current.path}',
  );
}
