import 'package:control_center/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PipelineStepStatus', () {
    test('has seven values', timeout: const Timeout.factor(2), () {
      expect(PipelineStepStatus.values.length, 7);
      expect(PipelineStepStatus.values, containsAll([
        PipelineStepStatus.pending,
        PipelineStepStatus.running,
        PipelineStepStatus.suspended,
        PipelineStepStatus.completed,
        PipelineStepStatus.failed,
        PipelineStepStatus.skipped,
        PipelineStepStatus.cancelled,
      ]));
    });

    test('isTerminal is true for completed, failed, skipped, cancelled',
        timeout: const Timeout.factor(2), () {
      expect(PipelineStepStatus.pending.isTerminal, isFalse);
      expect(PipelineStepStatus.running.isTerminal, isFalse);
      expect(PipelineStepStatus.suspended.isTerminal, isFalse);
      expect(PipelineStepStatus.completed.isTerminal, isTrue);
      expect(PipelineStepStatus.failed.isTerminal, isTrue);
      expect(PipelineStepStatus.skipped.isTerminal, isTrue);
      expect(PipelineStepStatus.cancelled.isTerminal, isTrue);
    });

    test('fromString parses all known values', timeout: const Timeout.factor(2), () {
      expect(PipelineStepStatus.fromString('pending'), PipelineStepStatus.pending);
      expect(PipelineStepStatus.fromString('running'), PipelineStepStatus.running);
      expect(PipelineStepStatus.fromString('suspended'), PipelineStepStatus.suspended);
      expect(PipelineStepStatus.fromString('completed'), PipelineStepStatus.completed);
      expect(PipelineStepStatus.fromString('failed'), PipelineStepStatus.failed);
      expect(PipelineStepStatus.fromString('skipped'), PipelineStepStatus.skipped);
      expect(PipelineStepStatus.fromString('cancelled'), PipelineStepStatus.cancelled);
    });

    test('fromString defaults to pending for unknown', timeout: const Timeout.factor(2), () {
      expect(PipelineStepStatus.fromString('bogus'), PipelineStepStatus.pending);
      expect(PipelineStepStatus.fromString(''), PipelineStepStatus.pending);
    });

    test('toStorageString returns name', timeout: const Timeout.factor(2), () {
      for (final s in PipelineStepStatus.values) {
        expect(s.toStorageString(), s.name);
      }
    });

    test('round-trip fromString/toStorageString', timeout: const Timeout.factor(2), () {
      for (final s in PipelineStepStatus.values) {
        expect(PipelineStepStatus.fromString(s.toStorageString()), s);
      }
    });
  });
}
