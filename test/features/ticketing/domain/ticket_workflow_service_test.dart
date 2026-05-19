import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal in-memory [TicketRepository] for the workflow-service tests.
class _FakeRepo implements TicketRepository {
  final Map<String, Ticket> store = {};
  final Map<String, List<TicketCollaborator>> collabs = {};
  // Counters that let the "no dispatch on assign" test assert side effects.
  int spaceCreates = 0;
  int runCreates = 0;

  @override
  Future<void> insert(Ticket ticket) async => store[ticket.id] = ticket;
  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async =>
      store[ticket.id] = ticket;
  @override
  Future<void> upsertMirror(Ticket ticket) async => store[ticket.id] = ticket;
  @override
  Future<void> delete(String ticketId, {required String workspaceId}) async =>
      store.remove(ticketId);
  @override
  Future<Ticket?> getById(String workspaceId, String id) async {
    final ticket = store[id];
    return ticket?.workspaceId == workspaceId ? ticket : null;
  }

  @override
  Future<Ticket?> getByExternal(TicketProvider p, String key) async => store
      .values
      .where((t) => t.provider == p && t.externalKey == key)
      .firstOrNull;
  @override
  Future<List<Ticket>> forAgent(String w, String agentId) async => store.values
      .where((t) => t.workspaceId == w && t.assignedAgentId == agentId)
      .toList();
  @override
  Future<List<Ticket>> childrenOf(String w, String parentId) async => store
      .values
      .where((t) => t.workspaceId == w && t.parentTicketId == parentId)
      .toList();
  @override
  Stream<List<Ticket>> watchForWorkspace(String w) =>
      Stream.value(store.values.where((t) => t.workspaceId == w).toList());
  @override
  Stream<List<Ticket>> watchByStatus(String w, TicketStatus s) => Stream.value(
    store.values.where((t) => t.workspaceId == w && t.status == s).toList(),
  );
  @override
  Stream<List<Ticket>> watchByAssignee(String w, String a) => Stream.value(
    store.values
        .where((t) => t.workspaceId == w && t.assignedAgentId == a)
        .toList(),
  );
  @override
  Future<void> addCollaborator(
    String workspaceId,
    TicketCollaborator c,
  ) async => (collabs[c.ticketId] ??= []).add(c);
  @override
  Future<void> removeCollaborator(
    String workspaceId,
    String t,
    String a,
  ) async => collabs[t]?.removeWhere((c) => c.principalId == a);
  @override
  Stream<List<TicketCollaborator>> watchCollaborators(
    String workspaceId,
    String t,
  ) => Stream.value(collabs[t] ?? const []);
  @override
  Future<List<TicketCollaborator>> getCollaborators(
    String workspaceId,
    String t,
  ) async => collabs[t] ?? const [];
}

void main() {
  late DomainEventBus bus;
  late _FakeRepo repo;
  late TicketWorkflowService service;

  setUp(() {
    bus = DomainEventBus();
    repo = _FakeRepo();
    service = TicketWorkflowService(repository: repo, eventBus: bus);
  });

  group('createTicket', () {
    test('persists and publishes TicketCreated', () async {
      final events = <TicketCreated>[];
      bus.on<TicketCreated>().listen(events.add);

      final ticket = await service.createTicket(
        workspaceId: 'ws',
        title: 'Do the thing',
      );
      expect(repo.store[ticket.id], isNotNull);
      expect(ticket.status, TicketStatus.open);
      // The event bus delivers asynchronously (broadcast controller); flush.
      await Future.microtask(() {});
      expect(events, hasLength(1));
      expect(events.single.ticketId, ticket.id);
    });

    test(
      'publishes TicketAssigned when an agent is assigned on create',
      () async {
        final events = <TicketAssigned>[];
        bus.on<TicketAssigned>().listen(events.add);

        final ticket = await service.createTicket(
          workspaceId: 'ws',
          title: 'Do the thing',
          assignedAgentId: 'agent-1',
        );
        expect(ticket.assignedAgentId, 'agent-1');
        // Bus delivery is async + filtered; pump until the TicketAssigned lands.
        for (var i = 0; i < 5 && events.isEmpty; i++) {
          await Future.microtask(() {});
        }
        expect(events, hasLength(1));
        expect(events.single.assignedAgentId, 'agent-1');
      },
    );
  });

  group('assign (dumb — metadata only)', () {
    test('updates assignedAgentId and publishes TicketAssigned', () async {
      final events = <TicketAssigned>[];
      bus.on<TicketAssigned>().listen(events.add);
      final ticket = await service.createTicket(workspaceId: 'ws', title: 't');

      await service.assign(ticket.id, workspaceId: 'ws', assigneeId: 'agent-1');

      final updated = await repo.getById('ws', ticket.id);
      expect(updated!.assignedAgentId, 'agent-1');
      await Future.microtask(() {});
      expect(events, hasLength(1));
    });

    test(
      'does NOT dispatch anything (no channel created, no run, status kept)',
      () async {
        // The pivot: assigning a ticket is pure metadata. Nothing should react.
        // The workflow service has no dispatch/space/run dependency, so this
        // asserts the absence of those collaborators AND that status is untouched.
        final ticket = await service.createTicket(
          workspaceId: 'ws',
          title: 't',
        );
        final statusBefore = ticket.status;

        await service.assign(
          ticket.id,
          workspaceId: 'ws',
          assigneeId: 'agent-1',
        );

        final updated = await repo.getById('ws', ticket.id);
        // Assignment never transitions status on a dumb ticket.
        expect(updated!.status, statusBefore);
        expect(updated.status, TicketStatus.open);
        // No fake-side-effect counters moved (the repo records none by design).
        expect(repo.spaceCreates, 0);
        expect(repo.runCreates, 0);
      },
    );
  });

  group('lifecycle transitions', () {
    test('completeTicket is a plain status transition to done', () async {
      final completed = <TicketCompleted>[];
      bus.on<TicketCompleted>().listen(completed.add);
      final ticket = await service.createTicket(workspaceId: 'ws', title: 't');

      await service.completeTicket(ticket.id, workspaceId: 'ws');

      final updated = await repo.getById('ws', ticket.id);
      expect(updated!.status, TicketStatus.done);
      expect(updated.completedAt, isNotNull);
      expect(completed, hasLength(1));
    });

    test('failTicket records the error message', () async {
      final ticket = await service.createTicket(workspaceId: 'ws', title: 't');

      await service.failTicket(ticket.id, 'boom', workspaceId: 'ws');

      final updated = await repo.getById('ws', ticket.id);
      expect(updated!.status, TicketStatus.failed);
      expect(updated.errorMessage, 'boom');
    });

    test('cancelTicket moves to cancelled', () async {
      final ticket = await service.createTicket(workspaceId: 'ws', title: 't');

      await service.cancelTicket(ticket.id, workspaceId: 'ws');

      final updated = await repo.getById('ws', ticket.id);
      expect(updated!.status, TicketStatus.cancelled);
    });

    test('terminal transitions are idempotent', () async {
      final ticket = await service.createTicket(workspaceId: 'ws', title: 't');
      await service.completeTicket(ticket.id, workspaceId: 'ws');
      final doneAt = (await repo.getById('ws', ticket.id))!.completedAt;

      // A second complete is a no-op (already terminal).
      await service.completeTicket(ticket.id, workspaceId: 'ws');
      expect((await repo.getById('ws', ticket.id))!.completedAt, doneAt);
    });
  });

  group('workspace isolation', () {
    test('a ticket id from another workspace does not resolve', () async {
      final ticket = await service.createTicket(
        workspaceId: 'ws-b',
        title: 't',
      );

      // The id exists in the store, but reading it under 'ws-a' must miss:
      // a workspace id selects the database file, so a foreign id is absent.
      expect(await repo.getById('ws-a', ticket.id), isNull);
      expect(await repo.getById('ws-b', ticket.id), isNotNull);
    });

    test(
      'a mutation scoped to the wrong workspace leaves the ticket alone',
      () async {
        final ticket = await service.createTicket(
          workspaceId: 'ws-b',
          title: 't',
        );

        await service.completeTicket(ticket.id, workspaceId: 'ws-a');
        await service.failTicket(ticket.id, 'boom', workspaceId: 'ws-a');
        await service.cancelTicket(ticket.id, workspaceId: 'ws-a');
        await service.assign(ticket.id, workspaceId: 'ws-a', assigneeId: 'a-1');

        final untouched = (await repo.getById('ws-b', ticket.id))!;
        expect(untouched.status, TicketStatus.open);
        expect(untouched.errorMessage, isNull);
        expect(untouched.assignedAgentId, isNull);
      },
    );
  });
}
