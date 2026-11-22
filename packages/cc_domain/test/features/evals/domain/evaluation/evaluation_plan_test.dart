import 'package:cc_domain/features/evals/domain/evaluation/evaluation_arm_settings.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_outcome.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_schedule.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/evaluation/routing_decision.dart';
import 'package:cc_domain/features/evals/domain/evaluation/task_route_policy.dart';
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
  EvaluationHypothesis hypothesis = EvaluationHypothesis.superiority,
  int? minTasks = 10,
  double? margin,
  int? interimAtTasks,
  double maxCostRatio = 1.0,
}) => EvaluationPlan(
  id: 'p',
  hypothesis: hypothesis,
  primaryOutcome: EvaluationOutcomeMeasure.verifiedSuccess,
  minTasks: minTasks,
  nonInferiorityMargin: margin,
  interimAtTasks: interimAtTasks,
  maxCostRatio: maxCostRatio,
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
    });

    test('runs task blocks: cold before warm, arms adjacent, the first arm '
        'alternating', () {
      final tasks = [for (var i = 0; i < 6; i++) task('t$i')];
      final plan = planWith(
        strata: const [
          StratumSpec(stratum: CacheStratum.cold, repetitions: 1),
          StratumSpec(stratum: CacheStratum.warm, repetitions: 2),
        ],
      );
      final trials = plan.schedule(tasks);
      const block = 2 * 3;
      final taskOrder = <String>[];
      for (var start = 0; start < trials.length; start += block) {
        final slice = trials.sublist(start, start + block);
        // One task per block: a ceiling that stops between blocks stops on
        // a task boundary.
        expect(slice.map((t) => t.taskId).toSet(), hasLength(1));
        taskOrder.add(slice.first.taskId);
        expect(
          slice.take(2).every((t) => t.stratum == CacheStratum.cold),
          isTrue,
        );
        expect(
          slice.skip(2).every((t) => t.stratum == CacheStratum.warm),
          isTrue,
        );
        final firsts = <String>[];
        for (var pair = 0; pair < block; pair += 2) {
          expect(
            {slice[pair].armId, slice[pair + 1].armId},
            {'baseline', 'cheap'},
          );
          expect(slice[pair].repetition, slice[pair + 1].repetition);
          firsts.add(slice[pair].armId);
        }
        expect(firsts[0], isNot(firsts[1]));
        expect(firsts[1], isNot(firsts[2]));
      }
      expect(taskOrder.toSet(), hasLength(6));
      expect(taskOrder, isNot([for (final t in tasks) t.id]));
    });

    test('a plan with a post-idle stratum keeps the global stratum order', () {
      final trials = planWith(
        strata: const [
          StratumSpec(stratum: CacheStratum.cold, repetitions: 1),
          StratumSpec(
            stratum: CacheStratum.postIdle,
            repetitions: 1,
            idleFor: Duration(minutes: 5),
          ),
        ],
      ).schedule([task('a'), task('b'), task('c')]);
      final strata = trials.map((t) => t.stratum).toList();
      expect(strata.take(6).every((s) => s == CacheStratum.cold), isTrue);
      expect(strata.skip(6).every((s) => s == CacheStratum.postIdle), isTrue);
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
        hypothesis: EvaluationHypothesis.superiority,
        primaryOutcome: EvaluationOutcomeMeasure.verifiedSuccess,
        minTasks: 10,
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

    test('refuses duplicate arm ids and too few tasks for the question', () {
      final violations = const EvaluationPlan(
        id: 'p',
        hypothesis: EvaluationHypothesis.superiority,
        primaryOutcome: EvaluationOutcomeMeasure.verifiedSuccess,
        minTasks: 9,
        arms: [baseline, baseline],
      ).violations([task('a')]);
      expect(violations.join(), contains('duplicate arm id'));
      expect(violations.join(), contains('minTasks must be at least 10'));
      expect(
        planWith(minTasks: null).violations([task('a')]).join(),
        contains('minTasks must be at least 10'),
      );
      expect(
        planWith(
          hypothesis: EvaluationHypothesis.regressionScreen,
          minTasks: 3,
        ).violations([task('a')]),
        isEmpty,
      );
    });

    test('a margin belongs to non-inferiority, in absolute points', () {
      final tasks = [task('a')];
      expect(
        planWith(margin: 0.1).violations(tasks).join(),
        contains('without the non_inferiority hypothesis'),
      );
      for (final margin in [null, 0.0, 0.6]) {
        expect(
          planWith(
            hypothesis: EvaluationHypothesis.nonInferiority,
            margin: margin,
          ).violations(tasks).join(),
          contains('nonInferiorityMargin must be in (0, 0.5]'),
        );
      }
      expect(
        planWith(
          hypothesis: EvaluationHypothesis.nonInferiority,
          margin: 0.15,
        ).violations(tasks),
        isEmpty,
      );
      expect(
        planWith(
          hypothesis: EvaluationHypothesis.nonInferiority,
          margin: 0.15,
          maxCostRatio: 1.5,
        ).violations(tasks).join(),
        contains('needs a saving'),
      );
      expect(planWith(maxCostRatio: 3).violations(tasks), isEmpty);
    });

    test('the interim look sits between minTasks and the planned tasks', () {
      final tasks = [for (var i = 0; i < 12; i++) task('t$i')];
      expect(planWith(interimAtTasks: 10).violations(tasks), isEmpty);
      for (final at in [9, 12]) {
        expect(
          planWith(interimAtTasks: at).violations(tasks).join(),
          contains('interimAtTasks must be at least minTasks'),
        );
      }
      expect(
        planWith(
          interimAtTasks: 10,
          strata: const [
            StratumSpec(stratum: CacheStratum.cold, repetitions: 1),
            StratumSpec(
              stratum: CacheStratum.postIdle,
              repetitions: 1,
              idleFor: Duration(minutes: 1),
            ),
          ],
        ).violations(tasks).join(),
        contains('analysed only when complete'),
      );
    });

    test('a calibration plan runs one arm and asks no question', () {
      final tasks = [task('a')];
      final one = planWith(
        hypothesis: EvaluationHypothesis.calibration,
        minTasks: null,
        arms: const [baseline],
      );
      expect(one.violations(tasks), isEmpty);
      expect(
        planWith(
          hypothesis: EvaluationHypothesis.calibration,
          minTasks: null,
        ).violations(tasks).join(),
        contains('runs exactly one arm'),
      );
      expect(
        planWith(
          hypothesis: EvaluationHypothesis.calibration,
          arms: const [baseline],
        ).violations(tasks).join(),
        contains('reaches no verdict'),
      );
    });

    test('a plan must say what it asks and how many tasks it needs', () {
      final json = planWith().toJson();
      expect(
        () => EvaluationPlan.fromJson({...json}..remove('hypothesis')),
        throwsFormatException,
      );
      expect(
        () => EvaluationPlan.fromJson({...json}..remove('primaryOutcome')),
        throwsFormatException,
      );
      // The replaced pair count is not read: a plan that names only it
      // has no minTasks, which is refused.
      final noTasks = EvaluationPlan.fromJson(
        {...json, 'minPairs': 8}..remove('minTasks'),
      );
      expect(noTasks.minTasks, isNull);
      expect(
        noTasks.violations([task('a')]).join(),
        contains('minTasks must be at least 10'),
      );
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
          modes: [MemoryPolicyMode.snapshotImages],
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
          modes: [MemoryPolicyMode.masking],
        ),
      ).violations([task('a')]);
      expect(matched, isEmpty);
    });

    test('snapshot compaction requires a fidelity check and verifiers', () {
      final violations = const MemoryPolicyExperiment(
        id: 'snap',
        enabled: true,
        modes: [MemoryPolicyMode.snapshotImages],
        requireSnapshotFidelityCheck: false,
      ).violations();
      expect(violations.join(), contains('fidelity check'));

      final noVerifiers = const MemoryPolicyExperiment(
        id: 'snap',
        enabled: true,
        modes: [MemoryPolicyMode.snapshotImages],
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
        hypothesis: EvaluationHypothesis.nonInferiority,
        primaryOutcome: EvaluationOutcomeMeasure.falseCompletion,
        minTasks: 12,
        nonInferiorityMargin: 0.15,
        interimAtTasks: 14,
        maxCostRatio: 0.9,
        maxSpendUsd: 25,
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
      expect(restored.hypothesis, EvaluationHypothesis.nonInferiority);
      expect(restored.primaryOutcome, EvaluationOutcomeMeasure.falseCompletion);
      expect(restored.minTasks, 12);
      expect(restored.nonInferiorityMargin, 0.15);
      expect(restored.interimAtTasks, 14);
      expect(restored.maxCostRatio, 0.9);
      expect(restored.maxSpendUsd, 25);
      expect(plan.toJson().containsKey('minPairs'), isFalse);
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

  group('run-setting axes (goal verification, code mode, history)', () {
    const claimOnly = EvaluationArm(
      id: 'claim-only',
      axis: EvaluationAxis.baseline,
      goalVerification: GoalVerificationMode.claimOnly,
    );
    const checksReview = EvaluationArm(
      id: 'checks-review',
      axis: EvaluationAxis.goalVerification,
      goalVerification: GoalVerificationMode.checksReview,
    );

    test('a baseline may name the default; a treatment deviates once', () {
      expect(claimOnly.isBaseline, isTrue);
      expect(checksReview.isBaseline, isFalse);
      expect(
        planWith(arms: const [claimOnly, checksReview]).violations([task('a')]),
        isEmpty,
      );
      expect(
        planWith(
          arms: const [
            EvaluationArm(
              id: 'repl',
              axis: EvaluationAxis.baseline,
              codeMode: CodeModeSurface.repl,
            ),
            EvaluationArm(
              id: 'none',
              axis: EvaluationAxis.codeMode,
              codeMode: CodeModeSurface.withoutRepl,
            ),
          ],
        ).violations([task('a')]),
        isEmpty,
      );
    });

    test('an arm that does not deviate on its axis is refused', () {
      final plan = planWith(
        arms: const [
          claimOnly,
          EvaluationArm(
            id: 'same',
            axis: EvaluationAxis.goalVerification,
            goalVerification: GoalVerificationMode.claimOnly,
          ),
        ],
      );
      expect(
        plan.violations([task('a')]),
        contains(contains('does not deviate on goal_verification')),
      );
    });

    test('a run setting cannot ride on another axis, or mix with one', () {
      final offAxis = planWith(
        arms: const [
          baseline,
          EvaluationArm(
            id: 'low',
            axis: EvaluationAxis.effortRouting,
            effortLevel: 'low',
            codeMode: CodeModeSurface.withoutRepl,
          ),
        ],
      ).violations([task('a')]);
      expect(offAxis, contains(contains('sets code_mode off its axis')));

      final mixed = planWith(
        arms: const [
          claimOnly,
          EvaluationArm(
            id: 'mixed',
            axis: EvaluationAxis.goalVerification,
            goalVerification: GoalVerificationMode.checksReview,
            effortLevel: 'low',
          ),
        ],
      ).violations([task('a')]);
      expect(mixed, contains(contains('mixes goal_verification')));
    });

    test('settings round-trip through JSON and unknown values refuse', () {
      final arm = EvaluationArm.fromJson(checksReview.toJson());
      expect(arm, checksReview);
      expect(
        EvaluationArm.fromJson(const {
          'id': 'fresh',
          'axis': 'session_continuity',
          'sessionContinuity': 'history_none',
        }).sessionContinuity,
        SessionContinuityMode.historyNone,
      );
      expect(
        () => EvaluationArm.fromJson(const {
          'id': 'x',
          'axis': 'code_mode',
          'codeMode': 'off',
        }),
        throwsArgumentError,
      );
      final config = EvaluationEffectiveConfig.forArm(
        const EvaluationManifest(
          corpusId: 'c',
          corpusHash: 'h',
          adapter: 'builtin',
          providerId: 'p',
          modelId: 'm',
        ),
        checksReview,
      );
      expect(config.goalVerification, GoalVerificationMode.checksReview);
      expect(config.toJson()['goalVerification'], 'checks_review');
      expect(config.label, contains('goal=checks_review'));
      expect(EvaluationEffectiveConfig.fromJson(config.toJson()), config);
    });
  });

  group('task tags', () {
    test('a plan runs only the tasks carrying one of its tags', () {
      final tasks = [
        task('a', tags: const ['x']),
        task('b', tags: const ['y']),
        task('c', tags: const ['x', 'z']),
      ];
      final plan = EvaluationPlan.fromJson({
        ...planWith().toJson(),
        'taskTags': ['x'],
      });
      expect(plan.selectTasks(tasks).map((t) => t.id), ['a', 'c']);
      expect(plan.toJson()['taskTags'], ['x']);
      expect(planWith().selectTasks(tasks), hasLength(3));
      expect(
        EvaluationPlan.fromJson({
          ...planWith().toJson(),
          'taskTags': ['missing'],
        }).violations(tasks),
        contains(contains('selects no task')),
      );
    });
  });

  group('memory experiment with several policies', () {
    const masking = EvaluationArm(
      id: 'masking',
      axis: EvaluationAxis.memoryPolicy,
      memoryPolicy: MemoryPolicyMode.masking,
    );
    const hybrid = EvaluationArm(
      id: 'hybrid',
      axis: EvaluationAxis.memoryPolicy,
      memoryPolicy: MemoryPolicyMode.hybridMaskingSummary,
    );
    const experiment = MemoryPolicyExperiment(
      id: 'both',
      enabled: true,
      modes: [MemoryPolicyMode.masking, MemoryPolicyMode.hybridMaskingSummary],
    );

    test('pairs both treatments against the baseline in one plan', () {
      expect(
        planWith(
          arms: const [baseline, masking, hybrid],
          memoryExperiment: experiment,
          contextWindowTokens: 6000,
        ).violations([task('a')]),
        isEmpty,
      );
      expect(MemoryPolicyExperiment.fromJson(experiment.toJson()), experiment);
    });

    test('a named policy no arm uses, or none at all, is refused', () {
      expect(
        planWith(
          arms: const [baseline, masking],
          memoryExperiment: experiment,
          contextWindowTokens: 6000,
        ).violations([task('a')]),
        contains(contains('uses hybrid_masking_summary')),
      );
      expect(
        const MemoryPolicyExperiment(
          id: 'none',
          enabled: true,
          modes: [],
        ).violations(),
        contains(contains('names no memory policy')),
      );
    });
  });
}
