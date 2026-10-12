import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/observability/domain/run_verification.dart';
import 'package:test/test.dart';

const _effective = EvaluationEffectiveConfig(
  adapter: 'builtin',
  providerId: 'anthropic',
  modelId: 'claude-opus-4-8',
);

EvaluationAttempt attempt({
  bool completed = true,
  String? error,
  EvaluationTokenBreakdown tokens = const EvaluationTokenBreakdown(),
  EvaluationCostRoles cost = const EvaluationCostRoles(),
  EvaluationAttemptMetrics metrics = const EvaluationAttemptMetrics(),
  List<EvaluationVerificationResult> verification = const [],
  int? expectedChecks,
  List<String> identityMismatches = const [],
  EvaluationExecutionMode mode = EvaluationExecutionMode.live,
  List<EvaluationToolEvent> toolEvents = const [],
}) => EvaluationAttempt(
  attemptId: 'a1',
  taskId: 't',
  taskKind: EvaluationTaskKind.bugfix,
  armId: 'baseline',
  effective: _effective,
  stratum: CacheStratum.cold,
  repetition: 0,
  seed: 1,
  startedAtEpochMs: 0,
  executionMode: mode,
  completed: completed,
  error: error,
  tokens: tokens,
  cost: cost,
  metrics: metrics,
  toolEvents: toolEvents,
  verification: verification,
  expectedAuthoritativeChecks: expectedChecks,
  identityMismatches: identityMismatches,
);

EvaluationVerificationResult passing({String id = 'v'}) =>
    EvaluationVerificationResult(
      verifierId: id,
      kind: EvaluationVerifierKind.tests,
      passed: true,
    );

void main() {
  group('units', () {
    test('a cent is 10,000 micro-USD in both directions', () {
      expect(microsPerCent, 10000);
      const micros = EvaluationCostRoles(estimatedApiMicros: 10000);
      expect(micros.budgetCents, 1);
      const subCent = EvaluationCostRoles(estimatedApiMicros: 4200);
      // 4200 µ$ rounds to 0 cents for display, but the arithmetic keeps 4200.
      expect(subCent.budgetCents, 0);
      expect(subCent.budgetMicros, 4200);
      expect(subCent.isComplete, isTrue);
    });

    test('unknown cost stays null and is never free work', () {
      const none = EvaluationCostRoles();
      expect(none.isEmpty, isTrue);
      expect(none.isComplete, isFalse);
      expect(none.budgetMicros, isNull);
      expect(none.allAttemptMicros, isNull);
      expect(none.budgetCents, 0);
    });

    test('a missing primary leg makes the attempt total unknown', () {
      const roles = EvaluationCostRoles(auxMicros: 5000, advisorMicros: 3000);
      expect(roles.isComplete, isFalse);
      expect(roles.allAttemptMicros, isNull);
    });

    test('auxiliary and advisor spend join a complete total', () {
      const roles = EvaluationCostRoles(
        estimatedApiMicros: 10000,
        auxMicros: 2000,
        advisorMicros: 3000,
      );
      expect(roles.isComplete, isTrue);
      expect(roles.allAttemptMicros, 15000);
      expect(roles.allAttemptCents, 2);
    });

    test('prefers billed over estimated over subscription', () {
      const roles = EvaluationCostRoles(
        subscriptionMicros: 1000,
        estimatedApiMicros: 2000,
        billedMicros: 4000,
      );
      expect(roles.budgetMicros, 4000);
    });

    test('summing treats an unobserved leg as absent, not zero', () {
      const a = EvaluationCostRoles(billedMicros: 1000);
      const b = EvaluationCostRoles();
      expect((a + b).billedMicros, 1000);
      expect((b + b).billedMicros, isNull);
      expect((a + b).isComplete, isTrue);
    });
  });

  group('token axes', () {
    test('reasoning is not double-counted when folded into output', () {
      const folded = EvaluationTokenBreakdown(
        uncachedInput: 100,
        output: 50,
        reasoning: 40,
      );
      expect(folded.reasoningSeparatelyReported, isFalse);
      expect(folded.totalTokens, 150);
    });

    test('reasoning is its own axis when reported separately', () {
      const separate = EvaluationTokenBreakdown(
        uncachedInput: 100,
        cacheWrite: 10,
        cacheRead: 20,
        output: 50,
        reasoning: 40,
        reasoningSeparatelyReported: true,
      );
      expect(separate.inputTokens, 130);
      expect(separate.totalTokens, 220);
      expect(separate.cacheReadFraction, closeTo(20 / 130, 1e-9));
    });
  });

  group('tool metrics', () {
    test('counts reads of read_output as reads and re-reads', () {
      final metrics = EvaluationAttemptMetrics.fromToolEvents([
        const EvaluationToolEvent(
          name: 'read_output',
          target: 'h1',
          isError: false,
        ),
        const EvaluationToolEvent(
          name: 'read_output',
          target: 'h1',
          isError: false,
        ),
        const EvaluationToolEvent(name: 'read', target: 'a.dart'),
        const EvaluationToolEvent(name: 'bash', target: 'dart', isError: true),
        const EvaluationToolEvent(name: 'bash', target: 'dart', isError: true),
        const EvaluationToolEvent(name: 'apply_patch', isError: true),
        const EvaluationToolEvent(name: 'bash', invalidArgs: true),
      ]);
      expect(metrics.toolCalls, 7);
      expect(metrics.reReads, 1);
      expect(metrics.repeatedFailedCalls, 1);
      expect(metrics.failedToolCalls, 3);
      expect(metrics.invalidToolCalls, 1);
      expect(metrics.patchFailures, 1);
    });

    test('intervention evidence is explicit', () {
      const none = EvaluationAttemptMetrics(contextWindowTokens: 8000);
      expect(none.rewritesHistory, isFalse);
      expect(none.renderedSnapshots, isFalse);
      const masked = EvaluationAttemptMetrics(
        contextWindowTokens: 8000,
        maskedObservations: 3,
        compactions: 1,
      );
      expect(masked.rewritesHistory, isTrue);
      const snapped = EvaluationAttemptMetrics(
        contextWindowTokens: 8000,
        snapshotFrames: 2,
      );
      expect(snapped.renderedSnapshots, isTrue);
    });
  });

  group('verified success', () {
    test('a completed run with no proving check is NOT a success', () {
      final noChecks = attempt(expectedChecks: 1);
      expect(noChecks.completed, isTrue);
      expect(noChecks.verifiedSuccess, isFalse);
      expect(noChecks.verificationComplete, isFalse);
      expect(
        noChecks.toRunVerification().status,
        VerificationStatus.unverified,
      );
    });

    test('a SKIPPED declared check blocks verified success', () {
      final skipped = attempt(
        expectedChecks: 2,
        verification: [
          passing(),
          const EvaluationVerificationResult(
            verifierId: 'no_writes',
            kind: EvaluationVerifierKind.noWrites,
            passed: false,
            skippedReason: 'noWrites needs a git workspace',
          ),
        ],
      );
      expect(skipped.proving, hasLength(1));
      expect(skipped.verificationComplete, isFalse);
      expect(skipped.verifiedSuccess, isFalse);
      expect(skipped.toRunVerification().status, VerificationStatus.unverified);
    });

    test('every declared check running and passing IS a success', () {
      final ok = attempt(
        expectedChecks: 2,
        verification: [
          passing(),
          passing(id: 'v2'),
        ],
      );
      expect(ok.verificationComplete, isTrue);
      expect(ok.verifiedSuccess, isTrue);
      expect(ok.toRunVerification().status, VerificationStatus.passed);
    });

    test('an identity mismatch makes the attempt ineligible evidence', () {
      final drifted = attempt(
        expectedChecks: 1,
        verification: [passing()],
        identityMismatches: const ['served model X (pinned Y)'],
      );
      expect(drifted.verifiedSuccess, isFalse);
      expect(drifted.toRunVerification().status, VerificationStatus.unverified);
    });

    test('a judge verdict never proves success', () {
      final judged = attempt(
        expectedChecks: 1,
        verification: const [
          EvaluationVerificationResult(
            verifierId: 'judge',
            passed: true,
            authoritative: false,
            provenance: VerificationProvenance.judgeAdvisory,
          ),
        ],
      );
      expect(judged.proving, isEmpty);
      expect(judged.verifiedSuccess, isFalse);
    });

    test('a replay-stamped behavioral check still proves success', () {
      final replayed = attempt(
        mode: EvaluationExecutionMode.offlineReplay,
        expectedChecks: 1,
        verification: const [
          EvaluationVerificationResult(
            verifierId: 'v',
            kind: EvaluationVerifierKind.tests,
            passed: true,
            provenance: VerificationProvenance.replayDeterministic,
          ),
        ],
      );
      expect(replayed.verifiedSuccess, isTrue);
      expect(replayed.live, isFalse);
    });

    test('a failed check keeps the run verified-false even when completed', () {
      final failed = attempt(
        expectedChecks: 1,
        verification: [
          const EvaluationVerificationResult(
            verifierId: 'v',
            kind: EvaluationVerifierKind.tests,
            passed: false,
          ),
        ],
      );
      expect(failed.verificationFailed, isTrue);
      expect(failed.verifiedSuccess, isFalse);
      expect(failed.toRunVerification().status, VerificationStatus.failed);
    });

    test('a harness fault is unverified, never a pass', () {
      final faulted = attempt(
        completed: false,
        error: 'boom',
        expectedChecks: 1,
        verification: [passing()],
      );
      expect(faulted.verifiedSuccess, isFalse);
      expect(faulted.toRunVerification().notes, 'boom');
    });
  });

  group('JSON', () {
    test('round-trips every field', () {
      const original = EvaluationAttempt(
        attemptId: 'a1',
        taskId: 't',
        taskKind: EvaluationTaskKind.longContext,
        armId: 'masking',
        effective: EvaluationEffectiveConfig(
          adapter: 'claude-cli',
          providerId: 'anthropic',
          modelId: 'claude-sonnet-4-5',
          effortLevel: 'low',
          memoryPolicy: MemoryPolicyMode.masking,
          sessionContinuity: SessionContinuityMode.nativeResume,
          mcpDiscoveryCache: McpDiscoveryCacheMode.enabled,
          toolOverlap: ToolOverlapMode.overlapReadOnly,
        ),
        stratum: CacheStratum.postIdle,
        repetition: 2,
        seed: 99,
        ordinal: 11,
        startedAtEpochMs: 1234,
        executionMode: EvaluationExecutionMode.offlineReplay,
        resumedSession: true,
        sessionId: 'sess-1',
        servedModel: 'claude-sonnet-4-5',
        servedEffort: 'low',
        observedCliVersion: '2.1.293',
        observedToolSurfaceHash: 'sha256:abc',
        completed: true,
        tokens: EvaluationTokenBreakdown(
          uncachedInput: 10,
          cacheWrite: 2,
          cacheRead: 3,
          output: 4,
          reasoning: 5,
          reasoningSeparatelyReported: true,
        ),
        cost: EvaluationCostRoles(estimatedApiMicros: 4200),
        latency: EvaluationLatency(
          transportTtfbMs: 12,
          firstModelEventMs: 20,
          firstUsefulTextMs: 40,
          providerTotalMs: 300,
          totalMs: 900,
        ),
        metrics: EvaluationAttemptMetrics(
          toolCalls: 3,
          reReads: 1,
          maskedObservations: 2,
          foldedSummaries: 1,
          snapshotFrames: 1,
          contextWindowTokens: 6000,
          providerCalls: 4,
          userTurns: 3,
          initMetadataMs: 15,
        ),
        toolEvents: [
          EvaluationToolEvent(
            name: 'read_output',
            target: 'h1',
            isError: false,
          ),
        ],
        verification: [
          EvaluationVerificationResult(
            verifierId: 'v',
            kind: EvaluationVerifierKind.tests,
            passed: true,
          ),
        ],
        expectedAuthoritativeChecks: 1,
        identityMismatches: ['tool surface differs'],
        filesTouched: ['a.txt'],
        transcriptRef: '/tmp/a.diff',
      );
      final restored = EvaluationAttempt.fromJson(original.toJson());
      expect(restored, original);
      expect(restored.metrics.maskedObservations, 2);
      expect(restored.metrics.contextWindowTokens, 6000);
      expect(restored.cost.budgetMicros, 4200);
      expect(restored.latency.firstUsefulTextMs, 40);
      expect(restored.observedCliVersion, '2.1.293');
    });
  });
  test('skill exposure and direct observations survive attempt JSON', () {
    const original = EvaluationAttempt(
      attemptId: 'skill-a',
      taskId: 'task',
      taskKind: EvaluationTaskKind.bugfix,
      armId: 'candidate',
      effective: EvaluationEffectiveConfig(
        adapter: 'builtin',
        providerId: 'openai',
        modelId: 'm',
        skillExposure: SkillExposure.available,
      ),
      stratum: CacheStratum.cold,
      repetition: 0,
      seed: 1,
      startedAtEpochMs: 100,
      skillEvents: [
        EvaluationSkillEvent(
          kind: 'available',
          skillHash: 'abc',
          atEpochMs: 100,
          origin: 'catalog',
        ),
        EvaluationSkillEvent(
          kind: 'body_load',
          skillHash: 'abc',
          atEpochMs: 101,
          origin: 'tool_read',
          toolUseId: 'u1',
          path: '.agents/skills/demo/SKILL.md',
        ),
      ],
    );
    final copy = EvaluationAttempt.fromJson(original.toJson());
    expect(copy.effective.skillExposure, SkillExposure.available);
    expect(copy.skillEvents, original.skillEvents);
    expect(copy, original);
  });
}
