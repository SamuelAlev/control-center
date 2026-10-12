import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:test/test.dart';

EvaluationTask task(String id, {List<String> tags = const []}) =>
    EvaluationTask(
      id: id,
      kind: EvaluationTaskKind.bugfix,
      prompt: 'do $id',
      tags: tags,
      verifiers: const [
        EvaluationVerifier(
          id: 'v',
          kind: EvaluationVerifierKind.commandExit,
          params: {'command': 'true'},
        ),
      ],
    );

const baseline = EvaluationArm(id: 'baseline', axis: EvaluationAxis.baseline);

EvaluationPlan planWith({
  List<EvaluationArm> arms = const [
    baseline,
    EvaluationArm(
      id: 'cheap',
      axis: EvaluationAxis.effortRouting,
      effortLevel: 'low',
    ),
  ],
  List<StratumSpec> strata = const [
    StratumSpec(stratum: CacheStratum.cold, repetitions: 1),
    StratumSpec(stratum: CacheStratum.warm, repetitions: 1),
  ],
  TaskRoutePolicy? routePolicy,
  MemoryPolicyExperiment? memoryExperiment,
  ToolOverlapExperiment? overlapExperiment,
  int seed = 7,
  int? contextWindowTokens,
}) => EvaluationPlan(
  id: 'p',
  seed: seed,
  arms: arms,
  strata: strata,
  routePolicy: routePolicy,
  memoryExperiment: memoryExperiment,
  overlapExperiment: overlapExperiment,
  contextWindowTokens: contextWindowTokens,
);

void main() {
  group('schedule', () {
    test('emits every (task, arm, stratum, repetition) exactly once', () {
      final tasks = [task('a'), task('b')];
      final plan = planWith(
        strata: const [
          StratumSpec(stratum: CacheStratum.cold, repetitions: 2),
          StratumSpec(stratum: CacheStratum.warm, repetitions: 1),
        ],
      );
      final trials = plan.schedule(tasks);
      expect(trials, hasLength(2 * 2 * 2 + 2 * 2 * 1));
      for (var ordinal = 0; ordinal < trials.length; ordinal++) {
        expect(trials[ordinal].ordinal, ordinal);
      }
      final keys = trials
          .map(
            (t) => '${t.taskId}|${t.armId}|${t.stratum.wire}|${t.repetition}',
          )
          .toSet();
      expect(keys, hasLength(trials.length));
      // Strata stay in canonical order even though each bucket is shuffled.
      final stratumOrder = trials.map((t) => t.stratum).toList();
      expect(
        stratumOrder.indexOf(CacheStratum.cold) <
            stratumOrder.lastIndexOf(CacheStratum.cold),
        isTrue,
      );
      expect(stratumOrder.last, CacheStratum.warm);
    });

    test('is deterministic for a seed and different for another seed', () {
      final tasks = [task('a'), task('b'), task('c')];
      final first = planWith(seed: 1).schedule(tasks);
      final again = planWith(seed: 1).schedule(tasks);
      final other = planWith(seed: 2).schedule(tasks);
      expect(
        [for (final t in first) '${t.taskId}${t.armId}${t.repetition}'],
        [for (final t in again) '${t.taskId}${t.armId}${t.repetition}'],
      );
      final firstOrder = [for (final t in first) t.taskId + t.armId].join(',');
      final otherOrder = [for (final t in other) t.taskId + t.armId].join(',');
      expect(otherOrder, isNot(firstOrder));
    });

    test('per-trial seeds do not depend on the execution order', () {
      final tasks = [task('a'), task('b')];
      final randomized = planWith(seed: 5).schedule(tasks);
      final stable = EvaluationPlan(
        id: 'p',
        seed: 5,
        arms: planWith().arms,
        strata: planWith().strata,
        randomizedOrder: false,
      ).schedule(tasks);
      int seedOf(List<EvaluationTrial> trials, String key) => trials
          .firstWhere(
            (t) =>
                '${t.taskId}|${t.armId}|${t.stratum.wire}|${t.repetition}' ==
                key,
          )
          .seed;
      for (final trial in randomized) {
        expect(
          trial.seed,
          seedOf(
            stable,
            '${trial.taskId}|${trial.armId}|${trial.stratum.wire}'
            '|${trial.repetition}',
          ),
        );
      }
    });

    test('replay mode stamps every trial offline', () {
      final trials = planWith().schedule([
        task('a'),
      ], executionMode: EvaluationExecutionMode.offlineReplay);
      expect(
        trials.every(
          (t) => t.executionMode == EvaluationExecutionMode.offlineReplay,
        ),
        isTrue,
      );
    });
  });

  group('plan violations', () {
    test('a sound plan has none', () {
      expect(planWith().violations([task('a')]), isEmpty);
    });

    test('refuses a single arm and a missing baseline', () {
      final one = planWith(
        arms: const [
          EvaluationArm(id: 't', axis: EvaluationAxis.effortRouting),
        ],
      ).violations([task('a')]);
      expect(one.join(), contains('at least two arms'));
      expect(one.join(), contains('no baseline'));
    });

    test('refuses duplicate arm ids and an undersized pair budget', () {
      final violations = const EvaluationPlan(
        id: 'p',
        arms: [baseline, baseline],
        minPairs: 1,
      ).violations([task('a')]);
      expect(violations.join(), contains('duplicate arm id'));
      expect(violations.join(), contains('minPairs'));
    });

    test('refuses a post-idle stratum with no idle duration', () {
      final violations = planWith(
        strata: const [
          StratumSpec(stratum: CacheStratum.cold, repetitions: 1),
          StratumSpec(stratum: CacheStratum.postIdle, repetitions: 1),
        ],
      ).violations([task('a')]);
      expect(violations.join(), contains('post-idle'));
    });

    test('a routing policy must be opted in AND applied by an arm', () {
      const policy = TaskRoutePolicy(
        id: 'r',
        enabled: true,
        optedInBy: 'operator',
        byTaskKind: {
          EvaluationTaskKind.bugfix: RoutingDecision(effortLevel: 'low'),
        },
      );
      final unapplied = planWith(routePolicy: policy).violations([task('a')]);
      expect(unapplied.join(), contains('no arm applies it'));

      final applied = planWith(
        routePolicy: policy,
        arms: [
          baseline,
          const EvaluationArm(
            id: 'routed',
            axis: EvaluationAxis.effortRouting,
            taskRoutePolicyId: 'r',
          ),
        ],
      ).violations([task('a')]);
      expect(applied, isEmpty);
    });

    test('routing refuses a task whose evidence is not behavioral', () {
      const weak = EvaluationTask(
        id: 'weak',
        kind: EvaluationTaskKind.exploration,
        prompt: 'x',
        verifiers: [
          EvaluationVerifier(
            id: 'judge',
            kind: EvaluationVerifierKind.fileContains,
            params: {'path': 'a', 'needle': 'b'},
            authoritative: false,
          ),
        ],
      );
      final violations = planWith(
        routePolicy: const TaskRoutePolicy(
          id: 'r',
          enabled: true,
          optedInBy: 'operator',
          byTaskKind: {
            EvaluationTaskKind.exploration: RoutingDecision(effortLevel: 'low'),
          },
        ),
        arms: [
          baseline,
          const EvaluationArm(
            id: 'routed',
            axis: EvaluationAxis.effortRouting,
            taskRoutePolicyId: 'r',
          ),
        ],
      ).violations([weak]);
      expect(violations.join(), contains('not fully behavioral'));
    });

    test('an enabled policy with no opt-in record is refused', () {
      final violations = planWith(
        routePolicy: const TaskRoutePolicy(
          id: 'r',
          enabled: true,
          byTaskKind: {
            EvaluationTaskKind.bugfix: RoutingDecision(effortLevel: 'low'),
          },
        ),
        arms: [
          baseline,
          const EvaluationArm(
            id: 'routed',
            axis: EvaluationAxis.effortRouting,
            taskRoutePolicyId: 'r',
          ),
        ],
      ).violations([task('a')]);
      expect(violations.join(), contains('opt-in record'));
    });

    test('a disabled policy is inert and never a violation', () {
      expect(
        planWith(
          routePolicy: const TaskRoutePolicy(id: 'r'),
        ).violations([task('a')]),
        isEmpty,
      );
    });

    test('a memory-policy arm needs a matching enabled experiment', () {
      const arm = EvaluationArm(
        id: 'masking',
        axis: EvaluationAxis.memoryPolicy,
        memoryPolicy: MemoryPolicyMode.masking,
      );
      final without = planWith(arms: [baseline, arm]).violations([task('a')]);
      expect(without.join(), contains('memory experiment'));

      final mismatched = planWith(
        arms: [baseline, arm],
        memoryExperiment: const MemoryPolicyExperiment(
          id: 'e',
          enabled: true,
          mode: MemoryPolicyMode.snapshotImages,
          fidelityVerifiers: [
            EvaluationVerifier(id: 'f', kind: EvaluationVerifierKind.noWrites),
          ],
        ),
      ).violations([task('a')]);
      expect(mismatched.join(), contains('memory experiment'));

      final matched = planWith(
        arms: [baseline, arm],
        contextWindowTokens: 4096,
        memoryExperiment: const MemoryPolicyExperiment(
          id: 'e',
          enabled: true,
          mode: MemoryPolicyMode.masking,
        ),
      ).violations([task('a')]);
      expect(matched, isEmpty);
    });

    test('snapshot compaction requires a fidelity check and verifiers', () {
      final violations = const MemoryPolicyExperiment(
        id: 'snap',
        enabled: true,
        mode: MemoryPolicyMode.snapshotImages,
        requireSnapshotFidelityCheck: false,
      ).violations();
      expect(violations.join(), contains('fidelity check'));

      final noVerifiers = const MemoryPolicyExperiment(
        id: 'snap',
        enabled: true,
        mode: MemoryPolicyMode.snapshotImages,
      ).violations();
      expect(noVerifiers.join(), contains('fidelity verifiers'));
    });

    test('tool overlap needs a matching experiment and a barrier task', () {
      const arm = EvaluationArm(
        id: 'overlap',
        axis: EvaluationAxis.toolOverlap,
        toolOverlap: ToolOverlapMode.overlapReadOnly,
      );
      final without = planWith(arms: [baseline, arm]).violations([task('a')]);
      expect(without.join(), contains('overlap experiment'));

      final noBarrier = planWith(
        arms: [baseline, arm],
        overlapExperiment: const ToolOverlapExperiment(
          id: 'o',
          enabled: true,
          mode: ToolOverlapMode.overlapReadOnly,
        ),
      ).violations([task('a')]);
      expect(noBarrier.join(), contains('barrier'));

      final sound =
          planWith(
            arms: [baseline, arm],
            overlapExperiment: const ToolOverlapExperiment(
              id: 'o',
              enabled: true,
              mode: ToolOverlapMode.overlapReadOnly,
            ),
          ).violations([
            task('a', tags: ['barrier']),
          ]);
      expect(sound, isEmpty);
    });
  });

  group('effective config and JSON', () {
    test('a baseline arm applies no deviation', () {
      const manifest = EvaluationManifest(
        corpusId: 'c',
        corpusHash: 'h',
        adapter: 'builtin',
        providerId: 'anthropic',
        modelId: 'claude-opus-4-8',
        effortLevel: 'high',
      );
      final effective = EvaluationEffectiveConfig.forArm(manifest, baseline);
      expect(effective.modelId, 'claude-opus-4-8');
      expect(effective.effortLevel, 'high');
      expect(effective.memoryPolicy, MemoryPolicyMode.textCurrent);
      expect(effective.toolOverlap, ToolOverlapMode.serial);
      expect(baseline.isBaseline, isTrue);
    });

    test('plan and arms round-trip through JSON', () {
      const plan = EvaluationPlan(
        id: 'p',
        seed: 3,
        arms: [
          baseline,
          EvaluationArm(
            id: 'overlap',
            axis: EvaluationAxis.toolOverlap,
            toolOverlap: ToolOverlapMode.overlapReadOnly,
            sessionContinuity: SessionContinuityMode.nativeResume,
            mcpDiscoveryCache: McpDiscoveryCacheMode.enabled,
            memoryPolicy: MemoryPolicyMode.masking,
          ),
        ],
        overlapExperiment: ToolOverlapExperiment(
          id: 'o',
          enabled: true,
          mode: ToolOverlapMode.overlapReadOnly,
        ),
      );
      final restored = EvaluationPlan.fromJson(plan.toJson());
      expect(restored.arms, plan.arms);
      expect(restored.overlapExperiment, plan.overlapExperiment);
      expect(restored.seed, plan.seed);
    });

    test('withAdditionalCaveats appends without mutating the original', () {
      final plan = planWith();
      final augmented = plan.withAdditionalCaveats(const [
        EvaluationCaveat(code: 'a', message: 'first'),
        EvaluationCaveat(code: 'a', message: 'duplicate code is dropped'),
      ]);
      expect(plan.caveats, isEmpty);
      expect(augmented.caveats, hasLength(1));
      expect(augmented.arms, plan.arms);
      expect(augmented.overlapExperiment, plan.overlapExperiment);
    });
  });
  test('skill axis preserves exposure without changing pinned model', () {
    final plan = planWith(
      arms: const [
        EvaluationArm(
          id: 'baseline',
          axis: EvaluationAxis.baseline,
          skillExposure: SkillExposure.absent,
        ),
        EvaluationArm(
          id: 'candidate',
          axis: EvaluationAxis.skillIntervention,
          skillExposure: SkillExposure.available,
        ),
      ],
    );
    expect(plan.violations([task('a')]), isEmpty);
    final restored = EvaluationPlan.fromJson(plan.toJson());
    expect(restored.arms[1].skillExposure, SkillExposure.available);
    const manifest = EvaluationManifest(
      corpusId: 'x',
      corpusHash: 'h',
      adapter: 'builtin',
      providerId: 'openai',
      modelId: 'm',
    );
    final effective = EvaluationEffectiveConfig.forArm(
      manifest,
      restored.arms[1],
    );
    expect(effective.modelId, 'm');
    expect(effective.skillExposure, SkillExposure.available);
  });

  test('skill exposure cannot be camouflaged as model routing', () {
    final plan = planWith(
      arms: const [
        baseline,
        EvaluationArm(
          id: 'mixed',
          axis: EvaluationAxis.modelRouting,
          modelId: 'other',
          skillExposure: SkillExposure.available,
        ),
      ],
    );
    expect(
      plan.violations([task('a')]),
      contains(contains('changes skill exposure on another axis')),
    );
  });
}
