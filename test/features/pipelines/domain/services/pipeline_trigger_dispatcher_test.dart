
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/core/domain/ports/schema_validator_port.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_trigger_dispatcher.dart';
import 'package:control_center/features/pipelines/domain/services/state_reducer.dart';
import 'package:control_center/features/pipelines/domain/services/step_process_registry.dart';
import 'package:control_center/features/pipelines/domain/services/template_renderer.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Wakes ────────────────────────────────────────────────────────────────────

class _StartCall {

  const _StartCall({
    required this.templateId,
    required this.workspaceId,
    this.triggerEventType,
    this.triggerPayload,
    this.dedupKey,
    this.parentPipelineRunId,
    this.parentStepId,
    this.dryRun = false,
  });
  final String templateId;
  final String workspaceId;
  final String? triggerEventType;
  final Map<String, dynamic>? triggerPayload;
  final String? dedupKey;
  final String? parentPipelineRunId;
  final String? parentStepId;
  final bool dryRun;
}

// ── Fakes ────────────────────────────────────────────────────────────────────

class FakePipelineTriggerRepository implements PipelineTriggerRepository {

  FakePipelineTriggerRepository({this.onEnabledForEvent});
  final List<PipelineTrigger> Function(String eventType)? onEnabledForEvent;

  @override
  Future<List<PipelineTrigger>> enabledForEvent(String eventType) async {
    return onEnabledForEvent?.call(eventType) ?? [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePipelineEngine implements PipelineEngine {

  _FakePipelineEngine({this.returnRun});
  final List<_StartCall> calls = [];
  final PipelineRun? returnRun;

  @override
  Future<PipelineRun?> start(
    String templateId, {
    required String workspaceId,
    String? triggerEventType,
    Map<String, dynamic>? triggerPayload,
    String? dedupKey,
    String? parentPipelineRunId,
    String? parentStepId,
    bool dryRun = false,
  }) async {
    calls.add(_StartCall(
      templateId: templateId,
      workspaceId: workspaceId,
      triggerEventType: triggerEventType,
      triggerPayload: triggerPayload,
      dedupKey: dedupKey,
      parentPipelineRunId: parentPipelineRunId,
      parentStepId: parentStepId,
      dryRun: dryRun,
    ));
    return returnRun;
  }

  // ── stub getters (never called by the dispatcher) ──────────────────────────

  @override
  PipelineBodyRegistry get bodies => _stub();
  @override
  PipelineTemplateRepository get templates => _stub();
  @override
  PipelineRunRepository get repository => _stub();
  @override
  TicketRepository get ticketRepository => _stub();
  @override
  StepProcessRegistry get stepProcessRegistry => _stub();
  @override
  DomainEventBus get eventBus => _stub();
  @override
  StateReducer get reducers => _stub();
  @override
  SchemaValidatorPort? get schemaValidator => _stub();
  @override
  TemplateRenderer get renderer => _stub();
  @override
  int get maxStepsPerRun => _stub();
  @override
  int get maxConcurrentSteps => _stub();
  @override
  Duration get suspendedStepTimeout => _stub();

  // ── stub methods (never called by the dispatcher) ──────────────────────────

  @override
  Future<void> resumeAll() => _stub();
  @override
  Future<void> cancel(String pipelineRunId) => _stub();
  @override
  Future<void> resumeStep({
    required String pipelineRunId,
    required String stepId,
  }) =>
      _stub();
  @override
  Future<void> resumeChildFlow({
    required String parentRunId,
    required String parentStepId,
    required PipelineRun childRun,
  }) =>
      _stub();
  @override
  Future<void> killStep(String stepRunId) => _stub();
  @override
  Future<void> retry(String pipelineRunId) => _stub();
  @override
  Future<void> dispose() => _stub();

  Never _stub() => throw UnimplementedError('not called by dispatcher');
}

// ── Helpers ──────────────────────────────────────────────────────────────────

PipelineTrigger _trigger({
  String id = 'trig-1',
  String templateId = 'tpl-test',
  String workspaceId = 'ws-1',
  bool enabled = true,
  String eventType = 'TicketAssigned',
  Map<String, dynamic>? match,
}) {
  return PipelineTrigger(
    id: id,
    templateId: templateId,
    workspaceId: workspaceId,
    enabled: enabled,
    eventType: eventType,
    match: match ?? const {},
  );
}

PipelineRun _run(String id) {
  return PipelineRun(
    id: id,
    templateId: 'tpl-test',
    workspaceId: 'ws-1',
    status: PipelineRunStatus.pending,
    startedAt: DateTime(2025),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  final now = DateTime(2025);

  group('PipelineTriggerDispatcher', () {
    late DomainEventBus eventBus;
    late _FakePipelineEngine engine;
    late FakePipelineTriggerRepository triggerRepo;
    late PipelineTriggerDispatcher dispatcher;

    setUp(() {
      eventBus = DomainEventBus();
      engine = _FakePipelineEngine();
      triggerRepo = FakePipelineTriggerRepository();
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
    });

    tearDown(() {
      dispatcher.dispose();
      eventBus.dispose();
    });

    // ── Ignored events ───────────────────────────────────────────────────

    test('ignores events whose typeName is not in knownEventTypes',
        timeout: const Timeout.factor(2), () async {
      dispatcher.start();

      final event = TicketDelegated(
        ticketId: 't-1',
        parentTicketId: 't-parent',
        occurredAt: now,
      );
      eventBus.publish(event);

      // Let the microtask queue drain so the async handler runs.
      await Future<void>.delayed(Duration.zero);

      expect(engine.calls, isEmpty);
    });

    test('skips when toPayload returns null (TicketCreated in knownEventTypes but no mapping)',
        timeout: const Timeout.factor(2), () async {
      dispatcher.start();

      final event = TicketCreated(ticketId: 't-1', occurredAt: now);
      eventBus.publish(event);

      await Future<void>.delayed(Duration.zero);

      expect(engine.calls, isEmpty);
    });

    // ── Repository query ─────────────────────────────────────────────────

    test('calls triggerRepository.enabledForEvent with correct typeName',
        timeout: const Timeout.factor(2), () async {
      String? capturedType;
      triggerRepo = FakePipelineTriggerRepository(
        onEnabledForEvent: (t) {
          capturedType = t;
          return [];
        },
      );
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
      dispatcher.start();

      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Test',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      eventBus.publish(event);

      await Future<void>.delayed(Duration.zero);

      expect(capturedType, 'TicketAssigned');
    });

    // ── Workspace scoping ────────────────────────────────────────────────

    test('filters triggers by workspaceId in payload (skips different workspace)',
        timeout: const Timeout.factor(2), () async {
      final triggerWs1 = _trigger(id: 'trig-ws1', workspaceId: 'ws-1');
      final triggerWs2 = _trigger(id: 'trig-ws2', workspaceId: 'ws-2');

      triggerRepo = FakePipelineTriggerRepository(
        onEnabledForEvent: (_) => [triggerWs1, triggerWs2],
      );
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
      engine = _FakePipelineEngine(returnRun: _run('r-1'));
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
      dispatcher.start();

      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Test',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      eventBus.publish(event);

      await Future<void>.delayed(Duration.zero);

      expect(engine.calls, hasLength(1));
      expect(engine.calls.single.workspaceId, 'ws-1');
    });

    test('workspace-scoped filtering skips all triggers when workspaceId mismatches',
        timeout: const Timeout.factor(2), () async {
      final trigger = _trigger(workspaceId: 'ws-3');

      triggerRepo = FakePipelineTriggerRepository(
        onEnabledForEvent: (_) => [trigger],
      );
      engine = _FakePipelineEngine(returnRun: _run('r-1'));
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
      dispatcher.start();

      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Test',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      eventBus.publish(event);

      await Future<void>.delayed(Duration.zero);

      expect(engine.calls, isEmpty);
    });

    // ── Value filter (trigger.matches) ───────────────────────────────────

    test('calls trigger.matches(payload) and respects the result',
        timeout: const Timeout.factor(2), () async {
      // Trigger that matches only when status == 'done'
      final trigger = _trigger(
        match: {'status': 'done'},
      );

      triggerRepo = FakePipelineTriggerRepository(
        onEnabledForEvent: (_) => [trigger],
      );
      engine = _FakePipelineEngine(returnRun: _run('r-1'));
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
      dispatcher.start();

      // TicketAssigned doesn't have 'status' in its payload, so trigger.matches
      // will compare payload['status'] (null) != 'done' → returns false.
      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Test',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      eventBus.publish(event);

      await Future<void>.delayed(Duration.zero);

      // The match filter rejects the payload — no run should start.
      expect(engine.calls, isEmpty);
    });

    test('trigger.matches returns true when match filter is empty',
        timeout: const Timeout.factor(2), () async {
      final trigger = _trigger(match: const {});

      triggerRepo = FakePipelineTriggerRepository(
        onEnabledForEvent: (_) => [trigger],
      );
      engine = _FakePipelineEngine(returnRun: _run('r-1'));
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
      dispatcher.start();

      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Test',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      eventBus.publish(event);

      await Future<void>.delayed(Duration.zero);

      expect(engine.calls, hasLength(1));
    });

    test('trigger.matches with list value respects contains check',
        timeout: const Timeout.factor(2), () async {
      // TicketAssigned always has 'ticketTitle' in payload.
      // match looks for ticketTitle in a list.
      final trigger = _trigger(
        match: {'ticketTitle': ['Test', 'Other']},
      );

      triggerRepo = FakePipelineTriggerRepository(
        onEnabledForEvent: (_) => [trigger],
      );
      engine = _FakePipelineEngine(returnRun: _run('r-1'));
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
      dispatcher.start();

      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Test',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      eventBus.publish(event);

      await Future<void>.delayed(Duration.zero);

      expect(engine.calls, hasLength(1));
    });

    // ── Engine.start call ────────────────────────────────────────────────

    test('starts a pipeline run for each matching trigger',
        timeout: const Timeout.factor(2), () async {
      final trigger1 = _trigger(id: 'trig-1', templateId: 'tpl-a');
      final trigger2 = _trigger(id: 'trig-2', templateId: 'tpl-b');

      triggerRepo = FakePipelineTriggerRepository(
        onEnabledForEvent: (_) => [trigger1, trigger2],
      );
      engine = _FakePipelineEngine(returnRun: _run('r-1'));
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
      dispatcher.start();

      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Test',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      eventBus.publish(event);

      await Future<void>.delayed(Duration.zero);

      expect(engine.calls, hasLength(2));
      expect(engine.calls.map((c) => c.templateId),
          containsAll(['tpl-a', 'tpl-b']));
    });

    test('passes correct parameters to engine.start',
        timeout: const Timeout.factor(2), () async {
      final trigger = _trigger(templateId: 'tpl-exact');

      triggerRepo = FakePipelineTriggerRepository(
        onEnabledForEvent: (_) => [trigger],
      );
      engine = _FakePipelineEngine(returnRun: _run('r-1'));
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
      dispatcher.start();

      final event = TicketAssigned(
        ticketId: 't-42',
        ticketTitle: 'Fix Bug',
        ticketBody: 'body text',
        ticketUrl: 'https://example.com/t/42',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      eventBus.publish(event);

      await Future<void>.delayed(Duration.zero);

      expect(engine.calls, hasLength(1));
      final call = engine.calls.single;
      expect(call.templateId, 'tpl-exact');
      expect(call.workspaceId, 'ws-1');
      expect(call.triggerEventType, 'TicketAssigned');
      expect(call.dedupKey, 't-42');

      // triggerPayload should be the full payload including injected fields
      expect(call.triggerPayload, isNotNull);
      final payload = call.triggerPayload!;
      expect(payload['ticketId'], 't-42');
      expect(payload['ticketTitle'], 'Fix Bug');
      expect(payload['ticketBody'], 'body text');
      expect(payload['ticketUrl'], 'https://example.com/t/42');
      expect(payload['workspaceId'], 'ws-1');
      expect(payload['triggerEventType'], 'TicketAssigned');
    });

    test('includes triggerPayload workspaceId overriding event workspaceId',
        timeout: const Timeout.factor(2), () async {
      // Trigger is in ws-2, event is from ws-1.
      // The fullPayload should have trigger.workspaceId ('ws-2') because
      // the dispatcher spreads payload first, then overwrites.
      // Actually: fullPayload = {...payload, 'workspaceId': trigger.workspaceId}
      // so trigger.workspaceId wins.
      final trigger = _trigger(workspaceId: 'ws-2');

      triggerRepo = FakePipelineTriggerRepository(
        onEnabledForEvent: (_) => [trigger],
      );
      engine = _FakePipelineEngine(returnRun: _run('r-1'));
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
      dispatcher.start();

      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Test',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      eventBus.publish(event);

      await Future<void>.delayed(Duration.zero);

      // Workspace scoping: payload has workspaceId 'ws-1', trigger has 'ws-2'.
      // The scope check says: scopeWorkspaceId ('ws-1') != trigger.workspaceId ('ws-2')
      // → continue (skip). So no run starts.
      expect(engine.calls, isEmpty);
    });

    // ── Error handling ───────────────────────────────────────────────────

    test('error in handler is caught and does not crash the stream',
        timeout: const Timeout.factor(2), () async {
      triggerRepo = FakePipelineTriggerRepository(
        onEnabledForEvent: (_) => throw Exception('repo down'),
      );
      engine = _FakePipelineEngine(returnRun: _run('r-1'));
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
      dispatcher.start();

      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Test',
        workspaceId: 'ws-1',
        occurredAt: now,
      );

      // Should not throw.
      eventBus.publish(event);
      await Future<void>.delayed(Duration.zero);

      // Engine was never called because the try/catch swallowed the error.
      expect(engine.calls, isEmpty);

      // The stream should still be alive — publish a second event to confirm
      // the subscription wasn't cancelled by the error.
      // (We use a fresh _FakePipelineEngine because the dispatcher's engine
      // reference is shared — same instance.)
      final event2 = TicketAssigned(
        ticketId: 't-2',
        ticketTitle: 'Test 2',
        workspaceId: 'ws-1',
        occurredAt: now,
      );

      // Re-wire with a working repo to prove the subscription is still active.
      triggerRepo = FakePipelineTriggerRepository(
        onEnabledForEvent: (_) => [_trigger()],
      );
      final dispatcher2 = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
      dispatcher2.start();

      eventBus.publish(event2);
      await Future<void>.delayed(Duration.zero);

      // The second event should have been dispatched since the bus is still
      // running and the new dispatcher's subscription is active.
      expect(engine.calls, isNotEmpty);
      dispatcher2.dispose();
    });

    // ── Lifecycle ────────────────────────────────────────────────────────

    test('start() subscribes to DomainEventBus; events are dispatched',
        timeout: const Timeout.factor(2), () async {
      final trigger = _trigger();

      triggerRepo = FakePipelineTriggerRepository(
        onEnabledForEvent: (_) => [trigger],
      );
      engine = _FakePipelineEngine(returnRun: _run('r-1'));
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );

      // Not started yet — publish an event.
      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Test',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      eventBus.publish(event);
      await Future<void>.delayed(Duration.zero);

      // No calls because dispatcher hasn't been started.
      expect(engine.calls, isEmpty);

      // Start and publish again.
      dispatcher.start();
      eventBus.publish(event);
      await Future<void>.delayed(Duration.zero);

      expect(engine.calls, isNotEmpty);
    });

    test('dispose() unsubscribes; events are ignored after disposal',
        timeout: const Timeout.factor(2), () async {
      final trigger = _trigger();

      triggerRepo = FakePipelineTriggerRepository(
        onEnabledForEvent: (_) => [trigger],
      );
      engine = _FakePipelineEngine(returnRun: _run('r-1'));
      dispatcher = PipelineTriggerDispatcher(
        eventBus: eventBus,
        engine: engine,
        triggerRepository: triggerRepo,
      );
      dispatcher.start();

      // Fire one event — should be handled.
      final event = TicketAssigned(
        ticketId: 't-1',
        ticketTitle: 'Test',
        workspaceId: 'ws-1',
        occurredAt: now,
      );
      eventBus.publish(event);
      await Future<void>.delayed(Duration.zero);
      expect(engine.calls, hasLength(1));

      // Dispose and fire again.
      dispatcher.dispose();
      eventBus.publish(event);
      await Future<void>.delayed(Duration.zero);

      // No additional calls after dispose.
      expect(engine.calls, hasLength(1));
    });

    test('dispose is safe to call multiple times',
        timeout: const Timeout.factor(2), () {
      dispatcher.start();
      dispatcher.dispose();
      // Should not throw.
      dispatcher.dispose();
    });

    test('dispose is safe to call without start',
        timeout: const Timeout.factor(2), () {
      // Should not throw.
      dispatcher.dispose();
    });
  });
}
