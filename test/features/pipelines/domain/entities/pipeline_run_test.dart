import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PipelineRun', () {
    final now = DateTime(2025, 1, 1);

    PipelineRun run0({
      PipelineRunStatus status = PipelineRunStatus.pending,
      Map<String, dynamic>? state,
      String? errorMessage,
      DateTime? finishedAt,
      int totalCostCents = 0,
      int totalTokens = 0,
      bool dryRun = false,
    }) =>
        PipelineRun(
          id: 'run-1',
          templateId: 'tpl',
          workspaceId: 'ws',
          status: status,
          state: state,
          startedAt: now,
          finishedAt: finishedAt,
          errorMessage: errorMessage,
          totalCostCents: totalCostCents,
          totalTokens: totalTokens,
          dryRun: dryRun,
        );

    test('state defaults to empty map and is unmodifiable', timeout: const Timeout.factor(2), () {
      final run = run0();
      expect(run.state, isEmpty);
      expect(() => (run.state as Map)['x'] = 1, throwsA(anything));
    });

    test('state is unmodifiable copy of provided map', timeout: const Timeout.factor(2), () {
      final run = run0(state: {'a': 1});
      expect(run.state, {'a': 1});
      expect(() => (run.state as Map)['b'] = 2, throwsA(anything));
    });

    test('isTerminal delegates to status', timeout: const Timeout.factor(2), () {
      expect(run0(status: PipelineRunStatus.pending).isTerminal, isFalse);
      expect(run0(status: PipelineRunStatus.running).isTerminal, isFalse);
      expect(run0(status: PipelineRunStatus.completed).isTerminal, isTrue);
      expect(run0(status: PipelineRunStatus.failed).isTerminal, isTrue);
      expect(run0(status: PipelineRunStatus.cancelled).isTerminal, isTrue);
    });

    test('copyWith overrides specified fields', timeout: const Timeout.factor(2), () {
      final run = run0();
      final copy = run.copyWith(
        status: PipelineRunStatus.completed,
        state: {'x': 1},
        finishedAt: now,
        errorMessage: 'err',
        totalCostCents: 100,
        totalTokens: 500,
      );
      expect(copy.status, PipelineRunStatus.completed);
      expect(copy.state, {'x': 1});
      expect(copy.finishedAt, now);
      expect(copy.errorMessage, 'err');
      expect(copy.totalCostCents, 100);
      expect(copy.totalTokens, 500);
      // Immutable fields preserved
      expect(copy.id, 'run-1');
      expect(copy.templateId, 'tpl');
      expect(copy.dryRun, isFalse);
    });

    test('copyWith preserves fields when not overridden', timeout: const Timeout.factor(2), () {
      final run = run0(
        status: PipelineRunStatus.running,
        state: {'a': 1},
        errorMessage: 'old',
      );
      final copy = run.copyWith(status: PipelineRunStatus.completed);
      expect(copy.state, {'a': 1});
      expect(copy.errorMessage, 'old');
    });

    test('default values', timeout: const Timeout.factor(2), () {
      final run = run0();
      expect(run.triggerEventType, isNull);
      expect(run.triggerPayload, isNull);
      expect(run.dedupKey, isNull);
      expect(run.finishedAt, isNull);
      expect(run.errorMessage, isNull);
      expect(run.errorStackTrace, isNull);
      expect(run.parentPipelineRunId, isNull);
      expect(run.parentStepId, isNull);
      expect(run.templateVersion, 1);
      expect(run.totalCostCents, 0);
      expect(run.totalTokens, 0);
      expect(run.dryRun, isFalse);
    });

    test('equality compares id, templateId, workspaceId, status, finishedAt, errorMessage',
        timeout: const Timeout.factor(2), () {
      final a = run0();
      final b = run0();
      expect(a, equals(b));

      final c = run0(status: PipelineRunStatus.completed);
      expect(a, isNot(equals(c)));

      final d = run0(errorMessage: 'err');
      expect(a, isNot(equals(d)));
    });

    test('equality ignores state and cost differences', timeout: const Timeout.factor(2), () {
      final a = run0(state: {'x': 1}, totalCostCents: 100);
      final b = run0(state: {'y': 2}, totalCostCents: 200);
      // Equality only checks id, templateId, workspaceId, status, finishedAt, errorMessage
      expect(a, equals(b));
    });

    test('hashCode is equal for equal runs', timeout: const Timeout.factor(2), () {
      final a = run0();
      final b = run0();
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs when status differs', timeout: const Timeout.factor(2), () {
      final a = run0();
      final b = run0(status: PipelineRunStatus.completed);
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('hashCode differs when errorMessage differs', timeout: const Timeout.factor(2), () {
      final a = run0();
      final b = run0(errorMessage: 'err');
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('hashCode is unchanged when state differs', timeout: const Timeout.factor(2), () {
      final a = run0(state: {'x': 1});
      final b = run0(state: {'y': 2});
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode is unchanged when cost differs', timeout: const Timeout.factor(2), () {
      final a = run0(totalCostCents: 100);
      final b = run0(totalCostCents: 200);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
