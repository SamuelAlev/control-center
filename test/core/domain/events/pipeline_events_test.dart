import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 18);

  group('PipelineRunStarted',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = PipelineRunStarted(
        pipelineRunId: 'run-1',
        templateId: 'tmpl-1',
        occurredAt: now,
      );

      expect(event.pipelineRunId, 'run-1');
      expect(event.templateId, 'tmpl-1');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = PipelineRunStarted(
        pipelineRunId: 'run-1',
        templateId: 'tmpl-1',
        occurredAt: now,
      );

      expect(event, isA<DomainEvent>());
    });
  });

  group('PipelineStepStarted',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = PipelineStepStarted(
        pipelineRunId: 'run-1',
        stepRunId: 'step-run-1',
        stepId: 'step-1',
        occurredAt: now,
      );

      expect(event.pipelineRunId, 'run-1');
      expect(event.stepRunId, 'step-run-1');
      expect(event.stepId, 'step-1');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = PipelineStepStarted(
        pipelineRunId: 'r',
        stepRunId: 'sr',
        stepId: 's',
        occurredAt: now,
      );

      expect(event, isA<DomainEvent>());
    });
  });

  group('PipelineStepCompleted',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = PipelineStepCompleted(
        pipelineRunId: 'run-1',
        stepRunId: 'step-run-1',
        stepId: 'step-1',
        occurredAt: now,
      );

      expect(event.pipelineRunId, 'run-1');
      expect(event.stepRunId, 'step-run-1');
      expect(event.stepId, 'step-1');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = PipelineStepCompleted(
        pipelineRunId: 'r',
        stepRunId: 'sr',
        stepId: 's',
        occurredAt: now,
      );

      expect(event, isA<DomainEvent>());
    });
  });

  group('PipelineStepFailed',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = PipelineStepFailed(
        pipelineRunId: 'run-1',
        stepRunId: 'step-run-1',
        stepId: 'step-1',
        errorMessage: 'OOM killed',
        occurredAt: now,
      );

      expect(event.pipelineRunId, 'run-1');
      expect(event.stepRunId, 'step-run-1');
      expect(event.stepId, 'step-1');
      expect(event.errorMessage, 'OOM killed');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = PipelineStepFailed(
        pipelineRunId: 'r',
        stepRunId: 'sr',
        stepId: 's',
        errorMessage: 'err',
        occurredAt: now,
      );

      expect(event, isA<DomainEvent>());
    });
  });

  group('PipelineRunCompleted',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = PipelineRunCompleted(
        pipelineRunId: 'run-1',
        templateId: 'tmpl-1',
        occurredAt: now,
      );

      expect(event.pipelineRunId, 'run-1');
      expect(event.templateId, 'tmpl-1');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = PipelineRunCompleted(
        pipelineRunId: 'r',
        templateId: 't',
        occurredAt: now,
      );

      expect(event, isA<DomainEvent>());
    });
  });

  group('PipelineRunFailed',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = PipelineRunFailed(
        pipelineRunId: 'run-1',
        templateId: 'tmpl-1',
        errorMessage: 'Timeout',
        occurredAt: now,
      );

      expect(event.pipelineRunId, 'run-1');
      expect(event.templateId, 'tmpl-1');
      expect(event.errorMessage, 'Timeout');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = PipelineRunFailed(
        pipelineRunId: 'r',
        templateId: 't',
        errorMessage: 'e',
        occurredAt: now,
      );

      expect(event, isA<DomainEvent>());
    });
  });

  group('Pipeline events on bus',() {
    test('each type filters independently', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final started = <PipelineRunStarted>[];
      final completed = <PipelineRunCompleted>[];
      final failed = <PipelineRunFailed>[];

      bus.on<PipelineRunStarted>().listen(started.add);
      bus.on<PipelineRunCompleted>().listen(completed.add);
      bus.on<PipelineRunFailed>().listen(failed.add);

      bus.publish(
        PipelineRunStarted(
          pipelineRunId: 'run-1',
          templateId: 'tmpl-1',
          occurredAt: now,
        ),
      );
      bus.publish(
        PipelineRunCompleted(
          pipelineRunId: 'run-1',
          templateId: 'tmpl-1',
          occurredAt: now,
        ),
      );
      bus.publish(
        PipelineRunFailed(
          pipelineRunId: 'run-2',
          templateId: 'tmpl-1',
          errorMessage: 'fail',
          occurredAt: now,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(started, hasLength(1));
      expect(completed, hasLength(1));
      expect(failed, hasLength(1));
    });

    test('step events are distinct from run events', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final stepStarted = <PipelineStepStarted>[];
      final runStarted = <PipelineRunStarted>[];

      bus.on<PipelineStepStarted>().listen(stepStarted.add);
      bus.on<PipelineRunStarted>().listen(runStarted.add);

      bus.publish(
        PipelineStepStarted(
          pipelineRunId: 'run-1',
          stepRunId: 'sr-1',
          stepId: 's-1',
          occurredAt: now,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(stepStarted, hasLength(1));
      expect(runStarted, isEmpty);
    });
  });
}
