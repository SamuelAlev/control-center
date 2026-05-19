import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PipelineStepRun', () {
    final now = DateTime(2025, 1, 1);

    PipelineStepRun step0({
      PipelineStepStatus status = PipelineStepStatus.pending,
      String? inputJson,
      String? outputJson,
      String? errorMessage,
      int? branchIndex,
      int attemptCount = 0,
      DateTime? finishedAt,
    }) =>
        PipelineStepRun(
          id: 'sr-1',
          pipelineRunId: 'pr-1',
          stepId: 'step-a',
          status: status,
          inputJson: inputJson,
          outputJson: outputJson,
          errorMessage: errorMessage,
          branchIndex: branchIndex,
          attemptCount: attemptCount,
          startedAt: now,
          finishedAt: finishedAt,
        );

    test('default values', timeout: const Timeout.factor(2), () {
      final step = step0();
      expect(step.inputJson, isNull);
      expect(step.outputJson, isNull);
      expect(step.errorMessage, isNull);
      expect(step.branchIndex, isNull);
      expect(step.attemptCount, 0);
      expect(step.finishedAt, isNull);
    });

    test('isTerminal delegates to status', timeout: const Timeout.factor(2), () {
      expect(step0(status: PipelineStepStatus.pending).isTerminal, isFalse);
      expect(step0(status: PipelineStepStatus.running).isTerminal, isFalse);
      expect(step0(status: PipelineStepStatus.completed).isTerminal, isTrue);
      expect(step0(status: PipelineStepStatus.failed).isTerminal, isTrue);
      expect(step0(status: PipelineStepStatus.skipped).isTerminal, isTrue);
      expect(step0(status: PipelineStepStatus.cancelled).isTerminal, isTrue);
    });

    test('stores all fields', timeout: const Timeout.factor(2), () {
      final step = PipelineStepRun(
        id: 'sr-2',
        pipelineRunId: 'pr-2',
        stepId: 'review',
        status: PipelineStepStatus.completed,
        inputJson: '{"a":1}',
        outputJson: '{"b":2}',
        errorMessage: null,
        branchIndex: 3,
        attemptCount: 2,
        startedAt: now,
        finishedAt: now.add(const Duration(seconds: 10)),
      );
      expect(step.id, 'sr-2');
      expect(step.pipelineRunId, 'pr-2');
      expect(step.stepId, 'review');
      expect(step.inputJson, '{"a":1}');
      expect(step.outputJson, '{"b":2}');
      expect(step.branchIndex, 3);
      expect(step.attemptCount, 2);
    });

    test('equality compares id, pipelineRunId, stepId, status, branchIndex',
        timeout: const Timeout.factor(2), () {
      final a = step0();
      final b = step0();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      final c = step0(status: PipelineStepStatus.completed);
      expect(a, isNot(equals(c)));

      final d = step0(branchIndex: 1);
      expect(a, isNot(equals(d)));
    });

    test('equality ignores inputJson, outputJson, errorMessage, attemptCount',
        timeout: const Timeout.factor(2), () {
      final a = step0(
        inputJson: '{"a":1}',
        outputJson: '{"b":2}',
        errorMessage: 'err',
        attemptCount: 5,
      );
      final b = step0();
      // These fields are NOT part of equality
      expect(a, equals(b));
    });

    test('identical instances are equal', timeout: const Timeout.factor(2), () {
      final step = step0();
      expect(step, equals(step));
    });
  });
}
