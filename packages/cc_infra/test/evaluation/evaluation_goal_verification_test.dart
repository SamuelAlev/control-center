import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/prompts/goal_review_prompt.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_verification_notice.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_arm_settings.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_backend_port.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_goal_outcome.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_outcome.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/evaluation/backends/builtin_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/evaluation_artifacts.dart';
import 'package:cc_infra/src/evaluation/evaluation_engine.dart';
import 'package:cc_infra/src/evaluation/isolated_task_workspace.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Campaign 1's attempt on the builtin backend with a scripted model: the
/// goal is run by the product's verifier, check runner and turn texts. No
/// model is called and nothing is spent.
void main() {
  test(
    'a claim with a failing hidden check is a false completion under '
    'claim_only and is caught under checks_review, where the findings go '
    'back and the second claim is verified',
    timeout: const Timeout(Duration(minutes: 3)),
    // The hidden check and the fixture's scripts run under bash.
    skip: Platform.isWindows ? 'needs a POSIX bash' : null,
    () async {
      final scripts = <_GoalScript>[];
      final out = Directory.systemTemp.createTempSync('cc_goal_engine');
      addTearDown(() => out.deleteSync(recursive: true));
      final result = await EvaluationEngine(
        config: EvaluationEngineConfig(
          corpus: _corpus,
          manifest: EvaluationManifest(
            corpusId: _corpus.id,
            corpusHash: _corpus.corpusHash,
            adapter: 'builtin',
            providerId: 'anthropic',
            modelId: 'scripted',
          ),
          plan: const EvaluationPlan(
            id: 'goal',
            hypothesis: EvaluationHypothesis.superiority,
            primaryOutcome: EvaluationOutcomeMeasure.falseCompletion,
            minTasks: 10,
            maxCostRatio: 3,
            seed: 1,
            arms: [
              EvaluationArm(
                id: 'claim-only',
                axis: EvaluationAxis.baseline,
                goalVerification: GoalVerificationMode.claimOnly,
              ),
              EvaluationArm(
                id: 'checks-review',
                axis: EvaluationAxis.goalVerification,
                goalVerification: GoalVerificationMode.checksReview,
              ),
            ],
            strata: [StratumSpec(stratum: CacheStratum.cold, repetitions: 1)],
          ),
          backend: BuiltinEvaluationBackend(
            factory: _Factory(() {
              final script = _GoalScript(fixFromSegment: 2);
              scripts.add(script);
              return script;
            }),
          ),
          outDir: out.path,
        ),
      ).run();

      final byArm = {for (final a in result.report.attempts) a.armId: a};
      final claimOnly = byArm['claim-only']!;
      expect(claimOnly.goal!.claims, 1);
      expect(claimOnly.goal!.accepted, isTrue);
      expect(claimOnly.goal!.verification, GoalVerificationResult.notRun);
      expect(claimOnly.completed, isTrue);
      expect(claimOnly.end, EvaluationAttemptEnd.finished);
      expect(claimOnly.verificationFailed, isTrue, reason: 'hidden check');
      expect(claimOnly.score(EvaluationOutcomeMeasure.falseCompletion), 1);
      expect(claimOnly.verifiedSuccess, isFalse);

      final checked = byArm['checks-review']!;
      expect(checked.error, isNull);
      expect(checked.goal!.claims, 2);
      expect(checked.goal!.accepted, isTrue);
      expect(checked.goal!.verification, GoalVerificationResult.passed);
      expect(checked.goal!.rounds, 1);
      expect(checked.goal!.segments, 2);
      expect(checked.verifiedSuccess, isTrue);

      final verified = scripts.singleWhere((s) => s.reviews > 0);
      // Segment 2 opened with the product's failed-verification notice and
      // the check's output; the review got the product's reviewer prompt.
      expect(verified.segmentPrompts, hasLength(2));
      expect(verified.segmentPrompts.first, contains('## Your goal'));
      expect(
        verified.segmentPrompts.last,
        allOf(
          contains(goalVerificationFailedTag),
          contains('`bash check.sh` exited 1'),
          contains(goalVerificationClosing),
        ),
      );
      expect(verified.reviewPrompt, contains(goalReviewIntro));
      expect(verified.reviewPrompt, contains('passed (exit 0)'));
      expect(verified.reviewTools, isNot(contains('bash')));
      expect(verified.reviewTools, contains('submit_output'));

      final markdown = File(
        result.artifacts.reportMarkdownPath,
      ).readAsStringSync();
      expect(markdown, contains('## Descriptive numbers (not a verdict)'));
      // attempts, completions, agent stopped, harness faults, ceiling stops,
      // verified, rate, false completions per attempt and per completion.
      expect(
        markdown,
        contains(
          '| claim-only | 1 | 1 | 0 | 0 | 0 | 0 | 0% | 1 | 100% | 100% |',
        ),
      );
      expect(
        markdown,
        contains(
          '| checks-review | 1 | 1 | 0 | 0 | 0 | 1 | 100% | 0 | 0% | 0% |',
        ),
      );
      expect(markdown, contains('| checks-review | 1 | 1 | 1 | 1 | 0 | 1.0 |'));
    },
  );

  test(
    'the verification rounds cap ends the attempt as not verified',
    timeout: const Timeout(Duration(minutes: 2)),
    () async {
      final root = Directory.systemTemp.createTempSync('cc_goal_rounds');
      addTearDown(() => root.deleteSync(recursive: true));
      final workspace = await IsolatedTaskWorkspace.create(
        task: _task,
        parentDir: Directory(p.join(root.path, 'space', 'repos')),
      );
      final script = _GoalScript(fixFromSegment: null);
      final attempt = await BuiltinEvaluationBackend(
        factory: _Factory(() => script),
      ).execute(_request(workspace.root, GoalVerificationMode.checksReview));

      expect(attempt.completed, isFalse);
      // Its claims were refused: the agent stopped, scored as a failure.
      expect(attempt.end, EvaluationAttemptEnd.agentStopped);
      expect(attempt.score(EvaluationOutcomeMeasure.falseCompletion), 0);
      expect(attempt.goal!.claims, 3);
      expect(attempt.goal!.accepted, isFalse);
      expect(attempt.goal!.verification, GoalVerificationResult.failedRounds);
      expect(attempt.goal!.holdDetail, 'verification_failed');
      expect(attempt.goal!.rounds, 3);
      expect(attempt.goal!.segments, 3);
      expect(script.reviews, 0, reason: 'a failed check asks no reviewer');
      expect(attempt.metrics.userTurns, 3);
    },
  );

  test(
    'a goal attempt stops inside what is left of the campaign ceiling',
    timeout: const Timeout(Duration(minutes: 2)),
    () async {
      Future<(EvaluationAttempt, _GoalScript)> run({
        required int? Function()? remainder,
        required ProviderCallCost? Function(ProviderCallRecord)? price,
      }) async {
        final root = Directory.systemTemp.createTempSync('cc_goal_ceiling');
        addTearDown(() => root.deleteSync(recursive: true));
        final workspace = await IsolatedTaskWorkspace.create(
          task: _task,
          parentDir: Directory(p.join(root.path, 'space', 'repos')),
        );
        final script = _GoalScript(fixFromSegment: null);
        final attempt = await BuiltinEvaluationBackend(
          factory: _Factory(() => script),
          priceLookup: price,
          ceilingRemainderMicros: remainder,
        ).execute(_request(workspace.root, GoalVerificationMode.checksReview));
        return (attempt, script);
      }

      // Every call costs 0.40 USD; a segment is two calls.
      ProviderCallCost? price(ProviderCallRecord _) =>
          const ProviderCallCost(400000);

      // Without a remainder the attempt runs all three failing rounds.
      final (unbounded, _) = await run(remainder: null, price: price);
      expect(unbounded.goal!.segments, 3);
      expect(unbounded.cost.allAttemptMicros, 2400000);

      // With 1 USD left it stops at the first call that reaches it.
      final (bounded, script) = await run(
        remainder: () => 1000000,
        price: price,
      );
      expect(bounded.completed, isFalse);
      expect(bounded.end, EvaluationAttemptEnd.ceilingStopped);
      expect(bounded.error, isNotNull);
      expect(bounded.goal!.accepted, isFalse);
      expect(bounded.cost.allAttemptMicros, 1200000);
      expect(script.segmentPrompts, hasLength(2));

      // An unpriced call cannot be held under it: the attempt stops there.
      final (unpriced, unpricedScript) = await run(
        remainder: () => 1000000,
        price: (_) => null,
      );
      expect(unpriced.completed, isFalse);
      // Spend it could not price is the harness's failure, not the agent's.
      expect(unpriced.end, EvaluationAttemptEnd.harnessFault);
      expect(unpriced.error, isNotNull);
      expect(unpricedScript.segmentPrompts, hasLength(1));
      expect(unpriced.metrics.modelRoundTrips, 1);
    },
  );

  test('a goal attempt outside a space layout is refused, not run', () async {
    final root = Directory.systemTemp.createTempSync('cc_goal_flat');
    addTearDown(() => root.deleteSync(recursive: true));
    final script = _GoalScript(fixFromSegment: null);
    final attempt = await BuiltinEvaluationBackend(
      factory: _Factory(() => script),
    ).execute(_request(root.path, GoalVerificationMode.claimOnly));
    expect(attempt.completed, isFalse);
    expect(attempt.error, contains('space checkout'));
    expect(script.segmentPrompts, isEmpty);
  });
}

const _criterion = '`bash add.sh 2 3` prints 5.';

const _task = EvaluationTask(
  id: 'goal-add',
  kind: EvaluationTaskKind.bugfix,
  prompt:
      'add.sh should print the sum of its two arguments.\n\n'
      '## Success criteria\n'
      '- $_criterion\n\n'
      '## Checks\n'
      '- `bash check.sh` (60 s)\n',
  inlineFiles: {
    'add.sh': 'echo 0\n',
    'check.sh': '[ "\$(bash add.sh 2 3)" = 5 ]\n',
  },
  verifiers: [
    EvaluationVerifier(
      id: 'hidden_add',
      kind: EvaluationVerifierKind.tests,
      params: {
        'trustedScript':
            '#!/usr/bin/env bash\n'
            'cd "\$CC_EVAL_WORKSPACE"\n'
            '[ "\$(bash add.sh 40 2)" = 42 ]\n',
        'expectExit': [0],
        'timeoutSeconds': 30,
      },
    ),
  ],
);

const _usage = LlmUsage(inputTokens: 10, outputTokens: 5);

const _corpus = EvaluationCorpus(id: 'goal', tasks: [_task]);

const _manifest = EvaluationManifest(
  corpusId: 'goal',
  corpusHash: 'scripted',
  adapter: 'builtin',
  providerId: 'anthropic',
  modelId: 'scripted',
);

EvaluationAttemptRequest _request(String root, GoalVerificationMode mode) {
  final arm = EvaluationArm(
    id: mode.wire,
    axis: mode == GoalVerificationMode.claimOnly
        ? EvaluationAxis.baseline
        : EvaluationAxis.goalVerification,
    goalVerification: mode,
  );
  return EvaluationAttemptRequest(
    task: _task,
    arm: arm,
    effective: EvaluationEffectiveConfig.forArm(_manifest, arm),
    manifest: _manifest,
    workspaceRoot: root,
    stratum: CacheStratum.cold,
    repetition: 0,
    seed: 1,
    ordinal: 0,
    attemptId: 'goal-${mode.wire}',
  );
}

class _Factory extends HarnessProviderFactory {
  _Factory(this.next);

  final LlmProviderPort Function() next;

  @override
  LlmProviderPort create({
    required String providerId,
    String? model,
    ProviderCredential? credential,
    ProviderTokenResolver? tokenResolver,
  }) => next();
}

/// A scripted agent: each worker segment claims completion; from segment
/// [fixFromSegment] on (never when null) it first writes a correct add.sh.
/// A review run answers `pass` through `submit_output`.
class _GoalScript extends LlmProviderPort {
  _GoalScript({required this.fixFromSegment});

  final int? fixFromSegment;
  final segmentPrompts = <String>[];
  String reviewPrompt = '';
  List<String> reviewTools = const [];
  int reviews = 0;
  bool _endNext = false;
  int _calls = 0;

  @override
  String get displayName => 'scripted';

  @override
  String get defaultModel => 'scripted';

  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    _calls++;
    yield _usage;
    if (_endNext) {
      _endNext = false;
      yield const LlmTextDelta('done');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
      return;
    }
    _endNext = true;
    final prompt = messages.last.textContent;
    if (prompt.contains(goalReviewIntro)) {
      reviews++;
      reviewPrompt = prompt;
      reviewTools = [for (final t in tools) t.name];
      yield LlmToolUseDelta(
        id: 'submit-$_calls',
        name: 'submit_output',
        argumentsJson: jsonEncode({
          'output': {
            'verdict': 'pass',
            'items': [
              {
                'criterion': _criterion,
                'state': 'met',
                'evidence': 'add.sh adds its arguments',
              },
            ],
            'concerns': <String>[],
          },
        }),
      );
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
      return;
    }
    segmentPrompts.add(prompt);
    final fix = fixFromSegment;
    if (fix != null && segmentPrompts.length >= fix) {
      yield LlmToolUseDelta(
        id: 'write-$_calls',
        name: 'write',
        argumentsJson: jsonEncode({
          'path': 'add.sh',
          'content':
              r'echo $(( $1 + $2 ))'
              '\n',
        }),
      );
    }
    yield LlmToolUseDelta(
      id: 'claim-$_calls',
      name: 'complete_goal',
      argumentsJson: jsonEncode({
        'summary': 'add.sh prints the sum',
        'evidence': [
          {'criterion': '1', 'evidence': 'bash add.sh 2 3 prints 5'},
        ],
      }),
    );
    yield const LlmDone(stopReason: LlmStopReason.toolUse);
  }
}
