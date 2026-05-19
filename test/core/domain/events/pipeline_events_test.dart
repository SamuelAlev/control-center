import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 18);

  group('PipelineRunCompleted', () {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = PipelineRunCompleted(
        workspaceId: 'ws-1',
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
        workspaceId: 'ws-1',
        pipelineRunId: 'r',
        templateId: 't',
        occurredAt: now,
      );

      expect(event, isA<DomainEvent>());
    });
  });

  group('PipelineRunFailed', () {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final event = PipelineRunFailed(
        workspaceId: 'ws-1',
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
        workspaceId: 'ws-1',
        pipelineRunId: 'r',
        templateId: 't',
        errorMessage: 'e',
        occurredAt: now,
      );

      expect(event, isA<DomainEvent>());
    });
  });

  group('Pipeline events on bus', () {
    test(
      'each type filters independently',
      timeout: const Timeout.factor(2),
      () async {
        final bus = DomainEventBus();
        addTearDown(bus.dispose);

        final cancelled = <PipelineRunCancelled>[];
        final completed = <PipelineRunCompleted>[];
        final failed = <PipelineRunFailed>[];

        bus.on<PipelineRunCancelled>().listen(cancelled.add);
        bus.on<PipelineRunCompleted>().listen(completed.add);
        bus.on<PipelineRunFailed>().listen(failed.add);

        bus.publish(
          PipelineRunCancelled(
            workspaceId: 'ws-1',
            pipelineRunId: 'run-3',
            templateId: 'tmpl-1',
            occurredAt: now,
          ),
        );
        bus.publish(
          PipelineRunCompleted(
            workspaceId: 'ws-1',
            pipelineRunId: 'run-1',
            templateId: 'tmpl-1',
            occurredAt: now,
          ),
        );
        bus.publish(
          PipelineRunFailed(
            workspaceId: 'ws-1',
            pipelineRunId: 'run-2',
            templateId: 'tmpl-1',
            errorMessage: 'fail',
            occurredAt: now,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 10));
        expect(cancelled, hasLength(1));
        expect(completed, hasLength(1));
        expect(failed, hasLength(1));
      },
    );

  });
}
