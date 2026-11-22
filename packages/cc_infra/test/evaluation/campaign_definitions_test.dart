import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/value_objects/goal_command.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_arm_settings.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_backend_port.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_outcome.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_schedule.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/evaluation/paired_evaluation.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/evaluation/backends/builtin_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/backends/claude_cli_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/evaluation_artifacts.dart';
import 'package:cc_infra/src/evaluation/evaluation_cli.dart';
import 'package:cc_infra/src/evaluation/evaluation_engine.dart';
import 'package:cc_infra/src/evaluation/evaluation_verifier_runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The four campaigns of the long-running work plan (section 20), as shipped
/// in `eval/plans/campaign-*.json` against `eval/corpus.json`.
///
/// Nothing here calls a model or spends money: definitions are loaded and
/// checked, the engine runs them on a scripted backend whose "verification"
/// is decided by the test, and the CLI is driven only in dry-run mode or into
/// its paid-run refusal.
void main() {
  final evalDir = _repositoryEvalDir();
  late EvaluationCorpus corpus;

  setUpAll(() async {
    corpus = await EvaluationCorpus.read(p.join(evalDir, 'corpus.json'));
  });

  for (final campaign in _campaigns) {
    group(campaign.file, () {
      late Map<String, dynamic> raw;
      late EvaluationPlan plan;

      setUpAll(() {
        raw =
            (jsonDecode(
                      File(
                        p.join(evalDir, 'plans', campaign.file),
                      ).readAsStringSync(),
                    )
                    as Map)
                .cast<String, dynamic>();
        plan = EvaluationPlan.fromJson(raw);
      });

      test('loads, with every axis spelt as declared', () {
        expect(plan.id, p.basenameWithoutExtension(campaign.file));
        expect(plan.violations(corpus.tasks), isEmpty);
        // fromWire falls back to the baseline: a misspelt axis would load as a
        // second baseline, so the raw strings are checked too.
        final rawArms = (raw['arms'] as List).cast<Map<String, dynamic>>();
        expect(
          [for (final arm in rawArms) arm['axis']],
          [for (final arm in plan.arms) arm.axis.wire],
        );
        expect(plan.arms.map((a) => a.id), campaign.armIds);
        expect(plan.baselineArm?.id, campaign.armIds.first);
        // The question each campaign declares (round 7), and that the owner
        // chooses the margin and the cost ceiling.
        expect(plan.hypothesis.wire, campaign.hypothesis);
        expect(plan.primaryOutcome.wire, campaign.outcome);
        expect(plan.nonInferiorityMargin, campaign.margin);
        expect(plan.maxCostRatio, campaign.maxCostRatio);
        expect(plan.minTasks, 10);
        expect(plan.alpha, 0.05);
        expect(plan.notes, contains("owner's to change"));
        expect(plan.notes, contains('10 needed'));
        expect(raw.containsKey('minPairs'), isFalse);
      });

      test('selects its task set by tag', () {
        expect(
          plan.selectTasks(corpus.tasks).map((t) => t.id).toList(),
          campaign.taskIds,
        );
        for (final task in plan.selectTasks(corpus.tasks)) {
          expect(
            task.verifiers.where((v) => v.authoritative),
            isNotEmpty,
            reason: '${task.id} has no hidden check',
          );
        }
      });

      test('its arms differ from the baseline only in the stated setting', () {
        final baseline = EvaluationEffectiveConfig.forArm(
          _manifest(corpus),
          plan.baselineArm!,
        ).toJson();
        final rawArms = (raw['arms'] as List).cast<Map<String, dynamic>>();
        for (final arm in plan.arms.where((a) => !a.isBaseline)) {
          final config = EvaluationEffectiveConfig.forArm(
            _manifest(corpus),
            arm,
          ).toJson();
          final differing = {
            for (final key in {...baseline.keys, ...config.keys})
              if (baseline[key] != config[key]) key,
          };
          expect(differing, {campaign.setting}, reason: arm.id);
          // The declaration itself names nothing else.
          final declared = rawArms.singleWhere((a) => a['id'] == arm.id);
          expect(declared.keys.toSet().difference({'id', 'axis', 'label'}), {
            campaign.setting,
          });
        }
      });

      test('pairs every arm on every task, stratum and repetition', () {
        final tasks = plan.selectTasks(corpus.tasks);
        final trials = plan.schedule(tasks);
        final reps = plan.strata.fold<int>(0, (n, s) => n + s.repetitions);
        expect(trials.length, tasks.length * plan.arms.length * reps);
        final cells = <String, Set<String>>{};
        for (final trial in trials) {
          cells
              .putIfAbsent(
                '${trial.taskId}/${trial.stratum.wire}/${trial.repetition}',
                () => {},
              )
              .add(trial.armId);
        }
        expect(cells.length, tasks.length * reps);
        expect(
          cells.values.every((arms) => arms.length == plan.arms.length),
          isTrue,
        );
        expect(cells.length, campaign.pairsPerTreatment);
      });

      test('a dry run on the fake backend reports through the gate', () async {
        final backend = _FakeBackend(passes: (_) => true);
        final result = await _engine(
          corpus: corpus,
          plan: plan,
          backend: backend,
          dryRun: true,
        ).run();
        expect(backend.executed, 0);
        expect(result.trials, hasLength(campaign.trialCount));
        expect(result.report.attempts, isEmpty);
        expect(result.report.expectedPairs, campaign.pairsPerTreatment);
        final treatments = plan.arms.where((a) => !a.isBaseline).toList();
        expect(result.report.verdicts, hasLength(treatments.length));
        for (final verdict in result.report.verdicts) {
          expect(verdict.baselineArmId, plan.baselineArm!.id);
          expect(verdict.margin, campaign.margin);
          expect(verdict.verdict, QualityVerdict.inconclusive);
          expect(verdict.recommendation, AdoptionRecommendation.noDecision);
        }
        expect(result.report.coverageComplete, isFalse);
        expect(
          result.report.overallRecommendation,
          isNot(AdoptionRecommendation.adoptTreatment),
        );
        final markdown = File(
          result.artifacts.reportMarkdownPath,
        ).readAsStringSync();
        expect(markdown, contains('## Descriptive numbers (not a verdict)'));
        expect(markdown, contains('| per attempt | per completion |'));
      });

      test(
        'a full gate run on the fake backend stays inconclusive',
        timeout: const Timeout(Duration(minutes: 3)),
        () async {
          // Every attempt of the treatment fails its hidden checks and every
          // baseline attempt passes them: the gate must not call it
          // non-inferior, and must never recommend it.
          final losing = await _engine(
            corpus: corpus,
            plan: plan,
            backend: _FakeBackend(passes: (request) => request.arm.isBaseline),
          ).run();
          expect(losing.report.attempts, hasLength(campaign.trialCount));
          expect(losing.report.coverageComplete, isTrue);
          for (final verdict in losing.report.verdicts) {
            expect(verdict.pairs, campaign.pairsPerTreatment);
            expect(verdict.baselineOnlyWins, campaign.pairsPerTreatment);
            // With 3 to 5 tasks the plan's minTasks (10) is not met: even a
            // treatment that loses every pair reads "No decision", never
            // inferior (nor non-inferior), and the reason says why.
            final n = campaign.taskIds.length;
            expect(verdict.effectiveTaskCount, n);
            expect(verdict.observedDelta, -1);
            expect(verdict.verdict, QualityVerdict.inconclusive);
            expect(verdict.reason, '$n tasks, 10 needed');
            expect(verdict.recommendation, AdoptionRecommendation.noDecision);
            expect(
              verdict.recommendation,
              isNot(AdoptionRecommendation.adoptTreatment),
            );
          }
          // A false completion: an attempt that ended as done while its
          // hidden check failed.
          for (final summary in losing.report.armSummaries) {
            final falseCompletions =
                summary.eligible - summary.verifiedSuccesses;
            expect(
              falseCompletions,
              summary.armId == plan.baselineArm!.id
                  ? 0
                  : campaign.pairsPerTreatment,
            );
          }
          // The report says so in its descriptive numbers, beside the
          // Inconclusive verdict.
          final markdown = File(
            losing.artifacts.reportMarkdownPath,
          ).readAsStringSync();
          for (final arm in plan.arms.where((a) => !a.isBaseline)) {
            final n = campaign.pairsPerTreatment;
            expect(
              markdown,
              contains(
                '| ${arm.id} | $n | $n | 0 | 0 | 0 | 0 | 0% | $n | 100% '
                '| 100% |',
              ),
            );
          }
          final n = campaign.pairsPerTreatment;
          expect(
            markdown,
            contains(
              '| ${plan.baselineArm!.id} | $n | $n | 0 | 0 | 0 | $n | 100% '
              '| 0 | 0% | 0% |',
            ),
          );
        },
      );
    });
  }

  group('campaign 1: goal verification', () {
    test('every task prompt is a goal body with a contract the server '
        'parses, and checks the hidden check goes beyond', () {
      final plan = _plan(evalDir, 'campaign-goal-verification.json');
      for (final task in plan.selectTasks(corpus.tasks)) {
        final goal = GoalCommand.parse(task.prompt);
        expect(goal.contract, isNotNull, reason: task.id);
        expect(goal.contract!.criteria, isNotEmpty, reason: task.id);
        expect(goal.contract!.checks, hasLength(1), reason: task.id);
        expect(goal.contract!.checks.single.run, 'bash check.sh');
        expect(task.inlineFiles.keys, contains('check.sh'));
        expect(task.followUps, isEmpty);
      }
    });

    test('the builtin backend runs both arms; the Claude CLI refuses', () {
      final plan = _plan(evalDir, 'campaign-goal-verification.json');
      expect(plan.arms.map((a) => a.goalVerification), [
        GoalVerificationMode.claimOnly,
        GoalVerificationMode.checksReview,
      ]);
      for (final arm in plan.arms) {
        final config = EvaluationEffectiveConfig.forArm(_manifest(corpus), arm);
        expect(BuiltinEvaluationBackend().unsupportedReason(config), isNull);
        expect(
          ClaudeCliEvaluationBackend().unsupportedReason(config),
          contains('builtin harness'),
        );
      }
    });

    test('the engine dry-runs the campaign on the builtin backend', () async {
      final plan = _plan(evalDir, 'campaign-goal-verification.json');
      final result = await _engine(
        corpus: corpus,
        plan: plan,
        backend: BuiltinEvaluationBackend(),
        dryRun: true,
      ).run();
      expect(result.trials, hasLength(18));
      expect(result.report.attempts, isEmpty);
      expect(result.report.verdicts.single.treatmentArmId, 'checks-review');
    });
  });

  group('campaign 2: conversation against --fresh', () {
    test(
      'equal outcomes on every pair stay inconclusive at five tasks',
      timeout: const Timeout(Duration(minutes: 2)),
      () async {
        final plan = _plan(evalDir, 'campaign-goal-fresh-history.json');
        final equal = await _engine(
          corpus: corpus,
          plan: plan,
          backend: _FakeBackend(passes: (_) => true),
        ).run();
        final verdict = equal.report.verdicts.single;
        expect(verdict.bothPass, 10);
        expect(verdict.verdict, QualityVerdict.inconclusive);
        expect(verdict.reason, '5 tasks, 10 needed');
        expect(verdict.margin, isNull);
        expect(verdict.costRatio, closeTo(50000 / 70000, 1e-9));
      },
    );

    test('history_none starts every later turn with no history', () async {
      for (final mode in [null, SessionContinuityMode.historyNone]) {
        final provider = _RecordingProvider();
        final workspace = Directory.systemTemp.createTempSync('cc_campaign_');
        addTearDown(() => workspace.deleteSync(recursive: true));
        final attempt = await BuiltinEvaluationBackend(
          factory: _Factory(provider),
        ).execute(_request(workspace.path, sessionContinuity: mode));
        expect(attempt.completed, isTrue);
        expect(provider.requests, hasLength(3));
        final last = provider.requests.last
            .where((m) => m.role == HarnessRole.user)
            .map((m) => m.textContent)
            .join('\n');
        expect(last, contains('segment three'));
        if (mode == null) {
          expect(last, allOf(contains('segment one'), contains('segment two')));
        } else {
          expect(last, isNot(contains('segment one')));
          expect(last, isNot(contains('segment two')));
          expect(attempt.notes, contains('started with no history'));
        }
      }
    });

    test('both attempt backends accept it; the CLI sends only the turn', () {
      const config = EvaluationEffectiveConfig(
        adapter: 'claude-cli',
        providerId: 'anthropic',
        modelId: 'm',
        sessionContinuity: SessionContinuityMode.historyNone,
      );
      expect(BuiltinEvaluationBackend().unsupportedReason(config), isNull);
      expect(ClaudeCliEvaluationBackend().unsupportedReason(config), isNull);
    });
  });

  group('campaign 3: compaction policies', () {
    test('both treatments are opted in by one experiment', () {
      final plan = _plan(evalDir, 'campaign-compaction-policy.json');
      expect(plan.memoryExperiment?.enabled, isTrue);
      expect(plan.memoryExperiment?.modes, [
        MemoryPolicyMode.masking,
        MemoryPolicyMode.hybridMaskingSummary,
      ]);
      expect(plan.contextWindowTokens, greaterThan(0));
    });

    test('the builtin backend implements both with a window', () {
      final plan = _plan(evalDir, 'campaign-compaction-policy.json');
      final backend = BuiltinEvaluationBackend(
        contextWindowTokens: plan.contextWindowTokens,
      );
      for (final arm in plan.arms) {
        expect(
          backend.unsupportedReason(
            EvaluationEffectiveConfig.forArm(_manifest(corpus), arm),
          ),
          isNull,
          reason: arm.id,
        );
      }
    });
  });

  group('campaign 4: code mode', () {
    test('the repl arm is refused without a runner; without_repl runs', () {
      final plan = _plan(evalDir, 'campaign-code-mode.json');
      final backend = BuiltinEvaluationBackend();
      final reasons = {
        for (final arm in plan.arms)
          arm.id: backend.unsupportedReason(
            EvaluationEffectiveConfig.forArm(_manifest(corpus), arm),
          ),
      };
      expect(reasons['repl'], contains('CC_CODEMODE_RUNNER'));
      expect(reasons['without-repl'], isNull);
      for (final arm in plan.arms) {
        expect(
          ClaudeCliEvaluationBackend().unsupportedReason(
            EvaluationEffectiveConfig.forArm(_manifest(corpus), arm),
          ),
          contains('builtin harness'),
        );
      }
    });
  });

  group('the paid-run policy', () {
    late Directory out;
    setUp(() => out = Directory.systemTemp.createTempSync('cc_campaign_cli'));
    tearDown(() => out.deleteSync(recursive: true));

    List<String> args(String plan, List<String> extra) => [
      'run',
      '--corpus',
      p.join(evalDir, 'corpus.json'),
      '--plan',
      p.join(evalDir, 'plans', plan),
      '--out',
      out.path,
      '--model',
      'pinned-model',
      '--pricing-cache',
      p.join(out.path, 'no-pricing-cache.json'),
      ...extra,
    ];

    for (final campaign in _campaigns) {
      test('${campaign.file} does not start without it', () async {
        for (final extra in [
          const <String>[],
          ['--max-spend-usd', '0'],
          ['--max-spend-usd', 'all'],
          ['--max-spend-usd'],
        ]) {
          final stdoutSink = _Sink();
          final stderrSink = _Sink();
          final code = await runEvaluationCli(
            args(campaign.file, extra),
            out: stdoutSink.sink,
            err: stderrSink.sink,
          );
          expect(code, 1, reason: '$extra');
          expect(await stderrSink.read(), contains('paid-run policy'));
          expect(out.listSync(), isEmpty, reason: 'nothing was written');
        }
      });
    }

    test('a live goal campaign refuses a model the pricing cache does not '
        'price, before anything is resolved', () async {
      // A provider with no credential anywhere: past the price check, the
      // run stops at the credential, so nothing here can reach a model.
      const provider = ['--provider', 'cc-eval-none'];
      Future<String> refusal(String plan, List<String> extra) async {
        final err = _Sink();
        final code = await runEvaluationCli(
          args(plan, ['--max-spend-usd', '5', ...provider, ...extra]),
          out: _Sink().sink,
          err: err.sink,
        );
        expect(code, 1, reason: plan);
        expect(out.listSync(), isEmpty, reason: 'nothing was written');
        return err.read();
      }

      final unpriced = await refusal('campaign-goal-verification.json', []);
      expect(unpriced, contains('needs a price for its model'));
      expect(unpriced, contains('cc-eval-none/pinned-model'));
      expect(unpriced, isNot(contains('no credential')));

      // A campaign with no goal arm is not held to it.
      final plain = await refusal('campaign-goal-fresh-history.json', []);
      expect(plain, isNot(contains('needs a price')));
      expect(plain, contains('no credential'));

      // A priced model passes it.
      final cacheDir = Directory.systemTemp.createTempSync('cc_price_cache');
      addTearDown(() => cacheDir.deleteSync(recursive: true));
      final cache = File(p.join(cacheDir.path, 'api.json'))
        ..writeAsStringSync(
          jsonEncode({
            'cc-eval-none': {
              'id': 'cc-eval-none',
              'name': 'Unpriced test provider',
              'env': <String>[],
              'models': {
                'pinned-model': {
                  'id': 'pinned-model',
                  'name': 'Pinned model',
                  'cost': {'input': 1, 'output': 2},
                },
              },
            },
          }),
        );
      final priced = await refusal('campaign-goal-verification.json', [
        '--pricing-cache',
        cache.path,
      ]);
      expect(priced, isNot(contains('needs a price')));
      expect(priced, contains('no credential'));
    });

    test('--offline refuses a live run before the policy is read', () async {
      final stderrSink = _Sink();
      final code = await runEvaluationCli(
        args('campaign-compaction-policy.json', [
          '--offline',
          '--max-spend-usd',
          '1',
        ]),
        out: _Sink().sink,
        err: stderrSink.sink,
      );
      expect(code, 1);
      expect(await stderrSink.read(), contains('--offline'));
      expect(out.listSync(), isEmpty);
    });

    test('a dry run needs no policy and no credential', () async {
      for (final file in [
        'campaign-goal-fresh-history.json',
        'campaign-compaction-policy.json',
      ]) {
        final stdoutSink = _Sink();
        final code = await runEvaluationCli(
          args(file, ['--dry-run']),
          out: stdoutSink.sink,
          err: _Sink().sink,
        );
        expect(code, 0, reason: file);
        final printed = await stdoutSink.read();
        expect(printed, contains('run directory:'));
        expect(printed, contains('trial(s)'));
        expect(printed, contains('mode live'));
      }
      final goalOut = _Sink();
      final goal = await runEvaluationCli(
        args('campaign-goal-verification.json', ['--dry-run']),
        out: goalOut.sink,
        err: _Sink().sink,
      );
      expect(goal, 0);
      final printed = await goalOut.read();
      expect(printed, contains('18 trial(s)'));
      expect(printed, contains('checks-review'));
      if (Platform.environment['CC_CODEMODE_RUNNER'] == null) {
        final codeErr = _Sink();
        final code = await runEvaluationCli(
          args('campaign-code-mode.json', ['--dry-run']),
          out: _Sink().sink,
          err: codeErr.sink,
        );
        expect(code, 1);
        expect(await codeErr.read(), contains('CC_CODEMODE_RUNNER'));
      }
    });

    test(
      'the ceiling stops scheduling once the known spend reaches it',
      () async {
        final plan = _plan(evalDir, 'campaign-goal-fresh-history.json');
        // 0.1 USD at 50,000 or 70,000 micro-USD an attempt: any two attempts
        // reach it, so the third never starts.
        final ceiling = EvaluationSpendCeiling.fromFlag('0.1', planUsd: null);
        final backend = _FakeBackend(passes: (_) => true);
        final result = await _engine(
          corpus: corpus,
          plan: plan,
          backend: backend,
          cancelled: ceiling.reached,
          onAttempt: ceiling.record,
        ).run();
        expect(backend.executed, 2);
        expect(result.report.coverageComplete, isFalse);

        final unpriced = EvaluationSpendCeiling.fromFlag('100', planUsd: null);
        final unpricedBackend = _FakeBackend(
          passes: (_) => true,
          priced: false,
        );
        await _engine(
          corpus: corpus,
          plan: plan,
          backend: unpricedBackend,
          cancelled: unpriced.reached,
          onAttempt: unpriced.record,
        ).run();
        expect(unpricedBackend.executed, 1);
      },
    );

    test("a plan's own spend ceiling lowers --max-spend-usd, never raises "
        'it', () {
      expect(EvaluationSpendCeiling.fromFlag('10', planUsd: 2).micros, 2000000);
      expect(EvaluationSpendCeiling.fromFlag('1', planUsd: 5).micros, 1000000);
      expect(
        () => EvaluationSpendCeiling.fromFlag(null, planUsd: 5),
        throwsStateError,
      );
    });
  });

  group('the calibration plan', () {
    test('runs every corpus task three times on one arm and reaches no '
        'verdict (dry run)', () async {
      final raw =
          (jsonDecode(
                    File(
                      p.join(evalDir, 'plans', 'calibration-baseline.json'),
                    ).readAsStringSync(),
                  )
                  as Map)
              .cast<String, dynamic>();
      // The spend ceiling is a field the owner sets.
      expect(raw.containsKey('maxSpendUsd'), isTrue);
      final plan = EvaluationPlan.fromJson(raw);
      expect(plan.hypothesis, EvaluationHypothesis.calibration);
      expect(plan.arms, hasLength(1));
      expect(plan.taskTags, isEmpty);
      expect(plan.violations(corpus.tasks), isEmpty);
      final backend = _FakeBackend(passes: (_) => true);
      final result = await _engine(
        corpus: corpus,
        plan: plan,
        backend: backend,
        dryRun: true,
      ).run();
      expect(backend.executed, 0);
      expect(result.trials, hasLength(corpus.tasks.length * 3));
      expect(result.report.verdicts, isEmpty);
      expect(
        result.report.overallRecommendation,
        AdoptionRecommendation.noDecision,
      );
    });

    test(
      'its report prints pass rates per task and notes saturated ones',
      () async {
        final plan = _plan(evalDir, 'calibration-baseline.json');
        final tasks = corpus.tasks.take(2).map((t) => t.id).toSet();
        final result = await _engine(
          corpus: EvaluationCorpus(
            id: corpus.id,
            tasks: [
              for (final t in corpus.tasks)
                if (tasks.contains(t.id)) t,
            ],
          ),
          plan: plan,
          backend: _FakeBackend(passes: (_) => true),
        ).run();
        expect(result.report.attempts, hasLength(6));
        final markdown = File(
          result.artifacts.reportMarkdownPath,
        ).readAsStringSync();
        expect(markdown, contains('## Per-task scores (verified_success)'));
        expect(markdown, contains('saturated: 3 of 3 in every arm'));
        expect(markdown, contains('calibration plan runs one arm'));
      },
    );
  });
}

/// One shipped campaign and what its definition must be.
class _Campaign {
  const _Campaign({
    required this.file,
    required this.armIds,
    required this.setting,
    required this.taskIds,
    required this.pairsPerTreatment,
    required this.hypothesis,
    required this.outcome,
    this.margin,
    this.maxCostRatio = 1.0,
  });

  /// The question the plan declares (wire name).
  final String hypothesis;

  /// What attempts are scored on (wire name).
  final String outcome;

  /// The non-inferiority margin, absolute points; null for superiority.
  final double? margin;

  /// The owner's cost ceiling.
  final double maxCostRatio;

  final String file;
  final List<String> armIds;

  /// The one effective-config key the treatments change.
  final String setting;
  final List<String> taskIds;
  final int pairsPerTreatment;

  int get trialCount => pairsPerTreatment * armIds.length;
}

const _campaigns = [
  _Campaign(
    file: 'campaign-goal-verification.json',
    armIds: ['claim-only', 'checks-review'],
    setting: 'goalVerification',
    taskIds: ['goal-verify-duration', 'goal-verify-slug', 'goal-verify-total'],
    pairsPerTreatment: 9,
    hypothesis: 'superiority',
    outcome: 'false_completion',
    maxCostRatio: 3.0,
  ),
  _Campaign(
    file: 'campaign-goal-fresh-history.json',
    armIds: ['conversation', 'history-none'],
    setting: 'sessionContinuity',
    taskIds: [
      'long-context-short-turns',
      'cc-long-accounting-to-scheduler',
      'goal-segments-greet',
      'goal-segments-rename',
      'goal-segments-count',
    ],
    pairsPerTreatment: 10,
    hypothesis: 'superiority',
    outcome: 'verified_success',
  ),
  _Campaign(
    file: 'campaign-compaction-policy.json',
    armIds: ['current', 'masking', 'hybrid'],
    setting: 'memoryPolicy',
    taskIds: [
      'long-context-short-turns',
      'long-context-fold',
      'cc-long-accounting-to-scheduler',
    ],
    pairsPerTreatment: 9,
    hypothesis: 'non_inferiority',
    outcome: 'verified_success',
    margin: 0.15,
  ),
  _Campaign(
    file: 'campaign-code-mode.json',
    armIds: ['repl', 'without-repl'],
    setting: 'codeMode',
    taskIds: [
      'long-context-fold',
      'tool-heavy-search-and-retry',
      'barrier-mutation-order',
      'cc-long-accounting-to-scheduler',
      'cc-tool-heavy-correct-evaluator-surface',
    ],
    pairsPerTreatment: 10,
    hypothesis: 'superiority',
    outcome: 'verified_success',
  ),
];

EvaluationPlan _plan(String evalDir, String file) => EvaluationPlan.fromJson(
  (jsonDecode(File(p.join(evalDir, 'plans', file)).readAsStringSync()) as Map)
      .cast<String, dynamic>(),
);

EvaluationManifest _manifest(EvaluationCorpus corpus) => EvaluationManifest(
  corpusId: corpus.id,
  corpusHash: corpus.corpusHash,
  adapter: 'fake',
  providerId: 'anthropic',
  modelId: 'pinned-model',
);

EvaluationEngine _engine({
  required EvaluationCorpus corpus,
  required EvaluationPlan plan,
  required EvaluationBackendPort backend,
  bool dryRun = false,
  bool Function()? cancelled,
  Future<void> Function(EvaluationAttempt attempt)? onAttempt,
}) {
  final out = Directory.systemTemp.createTempSync('cc_campaign_run');
  addTearDown(() => out.deleteSync(recursive: true));
  return EvaluationEngine(
    config: EvaluationEngineConfig(
      corpus: corpus,
      manifest: _manifest(corpus),
      plan: plan,
      backend: backend,
      outDir: out.path,
      dryRun: dryRun,
      cancelled: cancelled,
      onAttempt: onAttempt,
    ),
    verifierRunner: _FakeVerifiers(backend is _FakeBackend ? backend : null),
  );
}

/// The fake backend: no model, no tool; it records whether the test wants
/// this attempt's hidden checks to pass, by workspace.
class _FakeBackend implements EvaluationBackendPort {
  _FakeBackend({required this.passes, this.priced = true});

  final bool Function(EvaluationAttemptRequest request) passes;
  final bool priced;
  final Map<String, bool> verdicts = {};
  int executed = 0;

  @override
  String get id => 'fake';

  @override
  bool get callsModel => true;

  @override
  String? unsupportedReason(EvaluationEffectiveConfig effective) => null;

  @override
  Future<EvaluationAttempt> execute(EvaluationAttemptRequest request) async {
    executed++;
    verdicts[request.workspaceRoot] = passes(request);
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
      end: EvaluationAttemptEnd.finished,
      cost: priced
          ? EvaluationCostRoles(
              estimatedApiMicros: request.arm.isBaseline ? 70000 : 50000,
            )
          : const EvaluationCostRoles(),
      metrics: const EvaluationAttemptMetrics(modelRoundTrips: 1),
      verification: const [],
    );
  }
}

/// Answers every declared check with the fake backend's verdict for the
/// workspace, so the gate sees exactly the outcomes the test chose.
class _FakeVerifiers extends EvaluationVerifierRunner {
  const _FakeVerifiers(this.backend);

  final _FakeBackend? backend;

  @override
  Future<List<EvaluationVerificationResult>> run({
    required List<EvaluationVerifier> verifiers,
    required String workspaceRoot,
    String? gitRoot,
    String? trustedScriptDir,
    EvaluationExecutionMode mode = EvaluationExecutionMode.live,
    bool controlled = false,
    CancellationToken? cancellation,
  }) async {
    final passed = backend?.verdicts[workspaceRoot] ?? false;
    return [
      for (final verifier in verifiers)
        EvaluationVerificationResult(
          verifierId: verifier.id,
          kind: verifier.kind,
          passed: passed,
          authoritative: verifier.authoritative,
        ),
    ];
  }
}

class _Factory extends HarnessProviderFactory {
  _Factory(this.provider);

  final LlmProviderPort provider;

  @override
  LlmProviderPort create({
    required String providerId,
    String? model,
    ProviderCredential? credential,
    ProviderTokenResolver? tokenResolver,
  }) => provider;
}

/// Records the messages of every request and answers each with text.
class _RecordingProvider extends LlmProviderPort {
  final List<List<HarnessMessage>> requests = [];

  @override
  String get displayName => 'recording';

  @override
  String get defaultModel => 'recording';

  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    requests.add(List.of(messages));
    yield const LlmTextDelta('done');
    yield const LlmDone(stopReason: LlmStopReason.endTurn);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

EvaluationAttemptRequest _request(
  String workspace, {
  required SessionContinuityMode? sessionContinuity,
}) {
  final arm = EvaluationArm(
    id: sessionContinuity == null ? 'conversation' : 'history-none',
    axis: sessionContinuity == null
        ? EvaluationAxis.baseline
        : EvaluationAxis.sessionContinuity,
    sessionContinuity: sessionContinuity,
  );
  const manifest = EvaluationManifest(
    corpusId: 'segments',
    corpusHash: 'scripted',
    adapter: 'builtin',
    providerId: 'anthropic',
    modelId: 'recording',
  );
  return EvaluationAttemptRequest(
    task: const EvaluationTask(
      id: 'segments',
      kind: EvaluationTaskKind.longContext,
      prompt: 'Goal: finish TODO.md. This is segment one.',
      followUps: [
        'Goal: finish TODO.md. This is segment two.',
        'Goal: finish TODO.md. This is segment three.',
      ],
      verifiers: [],
    ),
    arm: arm,
    effective: EvaluationEffectiveConfig.forArm(manifest, arm),
    manifest: manifest,
    workspaceRoot: workspace,
    stratum: CacheStratum.cold,
    repetition: 0,
    seed: 1,
    ordinal: 0,
    attemptId: 'segments-${arm.id}',
  );
}

/// Collects what the CLI writes.
class _Sink implements StreamConsumer<List<int>> {
  final _bytes = <int>[];
  late final IOSink sink = IOSink(this);

  /// Everything written so far, once the sink has delivered it.
  Future<String> read() async {
    await sink.flush();
    return utf8.decode(_bytes);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _bytes.addAll(chunk);
    }
  }

  @override
  Future<void> close() async {}
}

String _repositoryEvalDir() {
  for (final candidate in [
    p.join(Directory.current.path, 'eval'),
    p.join(Directory.current.path, 'packages', 'cc_infra', 'eval'),
  ]) {
    if (File(p.join(candidate, 'corpus.json')).existsSync()) {
      return candidate;
    }
  }
  throw StateError('could not locate the evaluation corpus');
}
