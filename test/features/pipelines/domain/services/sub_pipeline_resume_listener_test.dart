
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:cc_domain/features/pipelines/domain/services/sub_pipeline_resume_listener.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Captures a recorded [PipelineEngine.resumeChildFlow] call.
class _ResumeChildCall {

  const _ResumeChildCall({
    required this.parentRunId,
    required this.parentStepId,
    required this.childRun,
  });
  final String parentRunId;
  final String parentStepId;
  final PipelineRun childRun;
}

/// Pre-seeded [PipelineRun] store that returns a preset run (or null) for
/// [getRun]. Records which ids were queried so tests can assert lookups.
class FakePipelineRunRepository implements PipelineRunRepository {
  /// Run to return from [getRun], or null to simulate not-found.
  PipelineRun? nextRun;

  /// Every run id passed to [getRun], in order.
  final List<String> queriedIds = [];

  @override
  Future<PipelineRun?> getRun(String id) async {
    queriedIds.add(id);
    return nextRun;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records [resumeChildFlow] calls. When [explode] is true, the next
/// [resumeChildFlow] throws so tests can assert the listener catches it.
class _FakePipelineEngine implements PipelineEngine {
  final List<_ResumeChildCall> resumeCalls = [];

  bool explode = false;

  @override
  Future<void> resumeChildFlow({
    required String parentRunId,
    required String parentStepId,
    required PipelineRun childRun,
  }) async {
    if (explode) {
      throw StateError('boom');
    }
    resumeCalls.add(_ResumeChildCall(
      parentRunId: parentRunId,
      parentStepId: parentStepId,
      childRun: childRun,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _now = DateTime(2025, 7, 14, 12, 0);

class _ArbitraryDomainEvent implements DomainEvent {
  @override
  final DateTime occurredAt = DateTime(2025, 7, 14, 12, 0);
}

/// Creates a minimal [PipelineRun] with the given fields.
PipelineRun _makeRun({
  required String id,
  String templateId = 'tpl-test',
  String workspaceId = 'ws-test',
  PipelineRunStatus status = PipelineRunStatus.running,
  String? parentPipelineRunId,
  String? parentStepId,
}) {
  return PipelineRun(
    id: id,
    templateId: templateId,
    workspaceId: workspaceId,
    status: status,
    parentPipelineRunId: parentPipelineRunId,
    parentStepId: parentStepId,
    startedAt: _now,
  );
}

/// Drains the microtask queue so async event handlers triggered by
/// [DomainEventBus.publish] complete before assertions run.
Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SubPipelineResumeListener', () {
    late DomainEventBus eventBus;
    late _FakePipelineEngine engine;
    late FakePipelineRunRepository repository;
    late SubPipelineResumeListener listener;

    setUp(() {
      eventBus = DomainEventBus();
      engine = _FakePipelineEngine();
      repository = FakePipelineRunRepository();
      listener = SubPipelineResumeListener(
        eventBus: eventBus,
        engine: engine,
        repository: repository,
      );
      listener.start();
    });

    tearDown(() {
      listener.dispose();
      eventBus.dispose();
    });

    // -----------------------------------------------------------------------
    // Filtering: non-pipeline events
    // -----------------------------------------------------------------------

    test(
      'ignores non-pipeline events',
      timeout: const Timeout.factor(2),
      () async {
        final child = _makeRun(
          id: 'child-1',
          parentPipelineRunId: 'parent-1',
          parentStepId: 'step-1',
        );
        repository.nextRun = child;

        eventBus.publish(_ArbitraryDomainEvent());
        await _settle();

        expect(engine.resumeCalls, isEmpty);
        expect(repository.queriedIds, isEmpty);
      },
    );

    // -----------------------------------------------------------------------
    // Filtering: PipelineRunCompleted without parent link
    // -----------------------------------------------------------------------

    test(
      'ignores PipelineRunCompleted when child has no parent (parentPipelineRunId null)',
      timeout: const Timeout.factor(2),
      () async {
        final child = _makeRun(
          id: 'child-1',
          parentPipelineRunId: null,
          parentStepId: 'step-1',
        );
        repository.nextRun = child;

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'child-1',
            templateId: 'tpl-test',
            occurredAt: _now,
          ),
        );
        await _settle();

        expect(repository.queriedIds, ['child-1']);
        expect(engine.resumeCalls, isEmpty);
      },
    );

    test(
      'ignores when parentStepId is null',
      timeout: const Timeout.factor(2),
      () async {
        final child = _makeRun(
          id: 'child-1',
          parentPipelineRunId: 'parent-1',
          parentStepId: null,
        );
        repository.nextRun = child;

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'child-1',
            templateId: 'tpl-test',
            occurredAt: _now,
          ),
        );
        await _settle();

        expect(repository.queriedIds, ['child-1']);
        expect(engine.resumeCalls, isEmpty);
      },
    );

    test(
      'ignores when run not found (getRun returns null)',
      timeout: const Timeout.factor(2),
      () async {
        repository.nextRun = null;

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'child-1',
            templateId: 'tpl-test',
            occurredAt: _now,
          ),
        );
        await _settle();

        expect(repository.queriedIds, ['child-1']);
        expect(engine.resumeCalls, isEmpty);
      },
    );

    // -----------------------------------------------------------------------
    // Resume on PipelineRunCompleted
    // -----------------------------------------------------------------------

    test(
      'resumes parent on PipelineRunCompleted when child has parent link',
      timeout: const Timeout.factor(2),
      () async {
        final child = _makeRun(
          id: 'child-1',
          parentPipelineRunId: 'parent-1',
          parentStepId: 'step-a',
        );
        repository.nextRun = child;

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'child-1',
            templateId: 'tpl-test',
            occurredAt: _now,
          ),
        );
        await _settle();

        expect(engine.resumeCalls, hasLength(1));
        final call = engine.resumeCalls.single;
        expect(call.parentRunId, 'parent-1');
        expect(call.parentStepId, 'step-a');
        expect(call.childRun.id, 'child-1');
      },
    );

    test(
      'resumes parent on PipelineRunFailed when child has parent link',
      timeout: const Timeout.factor(2),
      () async {
        final child = _makeRun(
          id: 'child-1',
          parentPipelineRunId: 'parent-1',
          parentStepId: 'step-a',
        );
        repository.nextRun = child;

        eventBus.publish(
          PipelineRunFailed(
            pipelineRunId: 'child-1',
            templateId: 'tpl-test',
            errorMessage: 'boom',
            occurredAt: _now,
          ),
        );
        await _settle();

        expect(engine.resumeCalls, hasLength(1));
        final call = engine.resumeCalls.single;
        expect(call.parentRunId, 'parent-1');
        expect(call.parentStepId, 'step-a');
        expect(call.childRun.id, 'child-1');
      },
    );

    // -----------------------------------------------------------------------
    // Correct forwarding of fields
    // -----------------------------------------------------------------------

    test(
      'forwards correct parentRunId, parentStepId, and childRun',
      timeout: const Timeout.factor(2),
      () async {
        final child = _makeRun(
          id: 'child-xyz',
          templateId: 'tpl-abc',
          workspaceId: 'ws-qrs',
          parentPipelineRunId: 'parent-xyz',
          parentStepId: 'step-call-me',
        );
        repository.nextRun = child;

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'child-xyz',
            templateId: 'tpl-abc',
            occurredAt: _now,
          ),
        );
        await _settle();

        expect(engine.resumeCalls, hasLength(1));
        final call = engine.resumeCalls.single;
        expect(call.parentRunId, 'parent-xyz');
        expect(call.parentStepId, 'step-call-me');
        expect(call.childRun.id, 'child-xyz');
        expect(call.childRun.templateId, 'tpl-abc');
        expect(call.childRun.workspaceId, 'ws-qrs');
        // The exact same object reference is forwarded.
        expect(identical(call.childRun, child), isTrue);
      },
    );

    // -----------------------------------------------------------------------
    // Error in handler doesn't crash
    // -----------------------------------------------------------------------

    test(
      'error in handler caught by try/catch — does not crash',
      timeout: const Timeout.factor(2),
      () async {
        final child = _makeRun(
          id: 'child-1',
          parentPipelineRunId: 'parent-1',
          parentStepId: 'step-a',
        );
        repository.nextRun = child;
        engine.explode = true;

        // Publishing should not throw.
        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'child-1',
            templateId: 'tpl-test',
            occurredAt: _now,
          ),
        );
        await _settle();

        // The listener tried and caught the error. The event bus is still
        // alive and can receive further events.
        engine.explode = false;

        eventBus.publish(
          PipelineRunFailed(
            pipelineRunId: 'child-1',
            templateId: 'tpl-test',
            errorMessage: 'boom',
            occurredAt: _now,
          ),
        );
        await _settle();

        // After the crash was caught, subsequent events are still processed.
        expect(engine.resumeCalls, hasLength(1));
      },
    );

    // -----------------------------------------------------------------------
    // Lifecycle: start() subscribes, dispose() unsubscribes
    // -----------------------------------------------------------------------

    test(
      'dispose() unsubscribes — events are ignored after disposal',
      timeout: const Timeout.factor(2),
      () async {
        final child = _makeRun(
          id: 'child-1',
          parentPipelineRunId: 'parent-1',
          parentStepId: 'step-a',
        );
        repository.nextRun = child;

        listener.dispose();

        eventBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'child-1',
            templateId: 'tpl-test',
            occurredAt: _now,
          ),
        );
        await _settle();

        expect(engine.resumeCalls, isEmpty);
      },
    );

    test(
      'start() subscribes — events are handled',
      timeout: const Timeout.factor(2),
      () async {
        // Use a separate event bus so the setUp listener doesn't interfere.
        final freshBus = DomainEventBus();
        final freshListener = SubPipelineResumeListener(
          eventBus: freshBus,
          engine: engine,
          repository: repository,
        );

        final child = _makeRun(
          id: 'child-1',
          parentPipelineRunId: 'parent-1',
          parentStepId: 'step-a',
        );
        repository.nextRun = child;

        // Before start, events are ignored.
        freshBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'child-1',
            templateId: 'tpl-test',
            occurredAt: _now,
          ),
        );
        await _settle();
        expect(engine.resumeCalls, isEmpty);

        // After start, events are handled.
        freshListener.start();

        freshBus.publish(
          PipelineRunCompleted(
            pipelineRunId: 'child-1',
            templateId: 'tpl-test',
            occurredAt: _now,
          ),
        );
        await _settle();

        expect(engine.resumeCalls, hasLength(1));
        expect(engine.resumeCalls.single.parentRunId, 'parent-1');

        freshListener.dispose();
        freshBus.dispose();
      },
    );
  });
}
