
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_resume_listener.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Captures a recorded [PipelineEngine.resumeStep] call.
class _ResumeCall {
  const _ResumeCall({required this.pipelineRunId, required this.stepId});
  final String pipelineRunId;
  final String stepId;
}

/// Pre-seeded store keyed by ticket id. For [forPipelineStep], returns a
/// preset list regardless of the query parameters (the real repo filters by
/// them; the listener's logic is what we test, not the repo's).
class FakeTicketRepository implements TicketRepository {
  final Map<String, Ticket> _byId = {};
  final List<Ticket> _forStep = [];

  void seedById(Ticket ticket) => _byId[ticket.id] = ticket;
  void seedForStep(List<Ticket> tickets) {
    _forStep
      ..clear()
      ..addAll(tickets);
  }

  @override
  Future<Ticket?> getById(String id) async => _byId[id];

  @override
  Future<List<Ticket>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async => _forStep.toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records [resumeStep] calls and — when [explode] is set — throws.
class _FakePipelineEngine implements PipelineEngine {
  final List<_ResumeCall> resumeCalls = [];

  /// When true the next [resumeStep] throws a [StateError] so the test can
  /// assert the listener catches it.
  bool explode = false;

  @override
  Future<void> resumeStep({
    required String pipelineRunId,
    required String stepId,
  }) async {
    if (explode) {
      throw StateError('boom');
    }
    resumeCalls.add(_ResumeCall(pipelineRunId: pipelineRunId, stepId: stepId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _now = DateTime(2025, 7, 14, 12, 0);

Ticket _makeTicket({
  required String id,
  required String workspaceId,
  required TicketStatus status,
  String? pipelineRunId,
  String? pipelineStepId,
}) {
  return Ticket(
    id: id,
    workspaceId: workspaceId,
    title: 'Ticket $id',
    status: status,
    pipelineRunId: pipelineRunId,
    pipelineStepId: pipelineStepId,
    priority: TicketPriority.none,
    createdAt: _now,
    updatedAt: _now,
  );
}

class _ArbitraryDomainEvent implements DomainEvent {
  @override
  final DateTime occurredAt = DateTime(2025, 7, 14, 12, 0);
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
  group('TicketResumeListener', () {
    late DomainEventBus eventBus;
    late FakeTicketRepository ticketRepo;
    late _FakePipelineEngine engine;
    late TicketResumeListener listener;

    setUp(() {
      eventBus = DomainEventBus();
      ticketRepo = FakeTicketRepository();
      engine = _FakePipelineEngine();
      listener = TicketResumeListener(
        eventBus: eventBus,
        ticketRepository: ticketRepo,
        engine: engine,
      );
      listener.start();
    });

    tearDown(() {
      listener.dispose();
    });

    test(
      'ignores non-ticket events (e.g. arbitrary DomainEvent subclass)',
      () async {
        eventBus.publish(_ArbitraryDomainEvent());
        await _settle();
        expect(engine.resumeCalls, isEmpty);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'ignores when ticket not found (getById returns null)',
      () async {
        eventBus.publish(TicketCompleted(
          ticketId: 'missing',
          occurredAt: DateTime(2025, 7, 14, 12, 0),
        ));
        await _settle();
        expect(engine.resumeCalls, isEmpty);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'ignores when ticket has no pipelineRunId',
      () async {
        final ticket = _makeTicket(
          id: 't1',
          workspaceId: 'ws-1',
          status: TicketStatus.done,
          pipelineRunId: null,
          pipelineStepId: 'step-1',
        );
        ticketRepo.seedById(ticket);

        eventBus.publish(TicketCompleted(
          ticketId: 't1',
          occurredAt: DateTime(2025, 7, 14, 12, 0),
        ));
        await _settle();
        expect(engine.resumeCalls, isEmpty);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'ignores when ticket has no pipelineStepId',
      () async {
        final ticket = _makeTicket(
          id: 't1',
          workspaceId: 'ws-1',
          status: TicketStatus.done,
          pipelineRunId: 'run-1',
          pipelineStepId: null,
        );
        ticketRepo.seedById(ticket);

        eventBus.publish(TicketCompleted(
          ticketId: 't1',
          occurredAt: DateTime(2025, 7, 14, 12, 0),
        ));
        await _settle();
        expect(engine.resumeCalls, isEmpty);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'ignores when forPipelineStep returns empty list',
      () async {
        final ticket = _makeTicket(
          id: 't1',
          workspaceId: 'ws-1',
          status: TicketStatus.done,
          pipelineRunId: 'run-1',
          pipelineStepId: 'step-1',
        );
        ticketRepo.seedById(ticket);
        ticketRepo.seedForStep([]);

        eventBus.publish(TicketCompleted(
          ticketId: 't1',
          occurredAt: DateTime(2025, 7, 14, 12, 0),
        ));
        await _settle();
        expect(engine.resumeCalls, isEmpty);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'ignores when not all siblings are terminal (some still inProgress)',
      () async {
        final ticket = _makeTicket(
          id: 't1',
          workspaceId: 'ws-1',
          status: TicketStatus.done,
          pipelineRunId: 'run-1',
          pipelineStepId: 'step-1',
        );
        ticketRepo.seedById(ticket);

        final siblings = [
          ticket,
          _makeTicket(
            id: 't2',
            workspaceId: 'ws-1',
            status: TicketStatus.done,
            pipelineRunId: 'run-1',
            pipelineStepId: 'step-1',
          ),
          _makeTicket(
            id: 't3',
            workspaceId: 'ws-1',
            status: TicketStatus.inProgress,
            pipelineRunId: 'run-1',
            pipelineStepId: 'step-1',
          ),
        ];
        ticketRepo.seedForStep(siblings);

        eventBus.publish(TicketCompleted(
          ticketId: 't1',
          occurredAt: DateTime(2025, 7, 14, 12, 0),
        ));
        await _settle();
        expect(engine.resumeCalls, isEmpty);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'ignores when not all siblings are terminal (some still open)',
      () async {
        final ticket = _makeTicket(
          id: 't1',
          workspaceId: 'ws-1',
          status: TicketStatus.done,
          pipelineRunId: 'run-1',
          pipelineStepId: 'step-1',
        );
        ticketRepo.seedById(ticket);

        final siblings = [
          ticket,
          _makeTicket(
            id: 't4',
            workspaceId: 'ws-1',
            status: TicketStatus.open,
            pipelineRunId: 'run-1',
            pipelineStepId: 'step-1',
          ),
        ];
        ticketRepo.seedForStep(siblings);

        eventBus.publish(TicketCompleted(
          ticketId: 't1',
          occurredAt: DateTime(2025, 7, 14, 12, 0),
        ));
        await _settle();
        expect(engine.resumeCalls, isEmpty);
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'resumes step when all siblings are terminal (done + failed + cancelled)',
      () async {
        final ticket = _makeTicket(
          id: 't1',
          workspaceId: 'ws-1',
          status: TicketStatus.done,
          pipelineRunId: 'run-1',
          pipelineStepId: 'step-1',
        );
        ticketRepo.seedById(ticket);

        final siblings = [
          ticket,
          _makeTicket(
            id: 't2',
            workspaceId: 'ws-1',
            status: TicketStatus.failed,
            pipelineRunId: 'run-1',
            pipelineStepId: 'step-1',
          ),
          _makeTicket(
            id: 't3',
            workspaceId: 'ws-1',
            status: TicketStatus.cancelled,
            pipelineRunId: 'run-1',
            pipelineStepId: 'step-1',
          ),
        ];
        ticketRepo.seedForStep(siblings);

        eventBus.publish(TicketCompleted(
          ticketId: 't1',
          occurredAt: DateTime(2025, 7, 14, 12, 0),
        ));
        await _settle();

        expect(engine.resumeCalls, hasLength(1));
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'forwards correct pipelineRunId and stepId to engine',
      () async {
        final ticket = _makeTicket(
          id: 't1',
          workspaceId: 'ws-1',
          status: TicketStatus.done,
          pipelineRunId: 'run-42',
          pipelineStepId: 'step-99',
        );
        ticketRepo.seedById(ticket);
        ticketRepo.seedForStep([ticket]);

        eventBus.publish(TicketCompleted(
          ticketId: 't1',
          occurredAt: DateTime(2025, 7, 14, 12, 0),
        ));
        await _settle();

        expect(engine.resumeCalls, hasLength(1));
        expect(engine.resumeCalls.single.pipelineRunId, 'run-42');
        expect(engine.resumeCalls.single.stepId, 'step-99');
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'handles TicketFailed events (triggering resume as well)',
      () async {
        final ticket = _makeTicket(
          id: 't1',
          workspaceId: 'ws-1',
          status: TicketStatus.failed,
          pipelineRunId: 'run-1',
          pipelineStepId: 'step-1',
        );
        ticketRepo.seedById(ticket);
        ticketRepo.seedForStep([ticket]);

        eventBus.publish(TicketFailed(
          ticketId: 't1',
          errorMessage: 'Something went wrong',
          occurredAt: DateTime(2025, 7, 14, 12, 0),
        ));
        await _settle();

        expect(engine.resumeCalls, hasLength(1));
        expect(engine.resumeCalls.single.pipelineRunId, 'run-1');
        expect(engine.resumeCalls.single.stepId, 'step-1');
      },
      timeout: const Timeout.factor(2),
    );

    test(
      'error during resume does not crash (caught by try/catch)',
      () async {
        final ticket = _makeTicket(
          id: 't1',
          workspaceId: 'ws-1',
          status: TicketStatus.done,
          pipelineRunId: 'run-1',
          pipelineStepId: 'step-1',
        );
        ticketRepo.seedById(ticket);
        ticketRepo.seedForStep([ticket]);
        engine.explode = true;

        // Should not throw — the listener catches the error.
        eventBus.publish(TicketCompleted(
          ticketId: 't1',
          occurredAt: DateTime(2025, 7, 14, 12, 0),
        ));
        await _settle();

        // resumeStep was called (it threw, so no call recorded beyond that).
        // The test passes as long as no exception propagated.
        expect(engine.resumeCalls, isEmpty);
      },
      timeout: const Timeout.factor(2),
    );
  });
}
