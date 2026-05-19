import 'package:control_center/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PipelineRunStatus', () {
    test('has six values', timeout: const Timeout.factor(2), () {
      expect(PipelineRunStatus.values.length, 6);
      expect(PipelineRunStatus.values, containsAll([
        PipelineRunStatus.pending,
        PipelineRunStatus.running,
        PipelineRunStatus.suspended,
        PipelineRunStatus.completed,
        PipelineRunStatus.failed,
        PipelineRunStatus.cancelled,
      ]));
    });

    test('isTerminal is true only for completed, failed, cancelled',
        timeout: const Timeout.factor(2), () {
      expect(PipelineRunStatus.pending.isTerminal, isFalse);
      expect(PipelineRunStatus.running.isTerminal, isFalse);
      expect(PipelineRunStatus.suspended.isTerminal, isFalse);
      expect(PipelineRunStatus.completed.isTerminal, isTrue);
      expect(PipelineRunStatus.failed.isTerminal, isTrue);
      expect(PipelineRunStatus.cancelled.isTerminal, isTrue);
    });

    test('fromString parses all known values', timeout: const Timeout.factor(2), () {
      expect(PipelineRunStatus.fromString('pending'), PipelineRunStatus.pending);
      expect(PipelineRunStatus.fromString('running'), PipelineRunStatus.running);
      expect(PipelineRunStatus.fromString('suspended'), PipelineRunStatus.suspended);
      expect(PipelineRunStatus.fromString('completed'), PipelineRunStatus.completed);
      expect(PipelineRunStatus.fromString('failed'), PipelineRunStatus.failed);
      expect(PipelineRunStatus.fromString('cancelled'), PipelineRunStatus.cancelled);
    });

    test('fromString defaults to pending for unknown values',
        timeout: const Timeout.factor(2), () {
      expect(PipelineRunStatus.fromString('unknown'), PipelineRunStatus.pending);
      expect(PipelineRunStatus.fromString(''), PipelineRunStatus.pending);
    });

    test('toStorageString returns name', timeout: const Timeout.factor(2), () {
      for (final status in PipelineRunStatus.values) {
        expect(status.toStorageString(), status.name);
      }
    });

    test('fromString/toStorageString round-trip', timeout: const Timeout.factor(2), () {
      for (final status in PipelineRunStatus.values) {
        expect(
          PipelineRunStatus.fromString(status.toStorageString()),
          status,
        );
      }
    });
  });
}
