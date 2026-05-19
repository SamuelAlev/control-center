import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory repo with version-checked updates so the optimistic-lock contract
/// is exercised end-to-end.
class _FakeRepo implements TicketRepository {
  final Map<String, Ticket> store = {};

  @override
  Future<void> insert(Ticket ticket) async => store[ticket.id] = ticket;

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async {
    final current = store[ticket.id];
    if (expectedVersion != null &&
        current != null &&
        current.version != expectedVersion) {
      throw ConcurrencyConflictException('stale write on ${ticket.id}');
    }
    store[ticket.id] = ticket;
  }

  @override
  Future<Ticket?> getById(String workspaceId, String id) async {
    final ticket = store[id];
    return ticket?.workspaceId == workspaceId ? ticket : null;
  }

  @override
  Future<List<Ticket>> forAgent(String w, String a) async => store.values
      .where((t) => t.workspaceId == w && t.assignedAgentId == a)
      .toList();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
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

  Future<Ticket> seedOpen() async {
    final t = Ticket(
      id: 't1',
      workspaceId: 'ws1',
      provider: TicketProvider.local,
      title: 'Do the thing',
      status: TicketStatus.open,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    await repo.insert(t);
    return t;
  }

  test('checkout claims the task and moves it to in_progress', () async {
    await seedOpen();
    final acquired = await service.tryCheckout(
      't1',
      workspaceId: 'ws1',
      agentId: 'agentA',
    );
    expect(acquired, isTrue);
    final t = await repo.getById('ws1', 't1');
    expect(t!.status, TicketStatus.inProgress);
    expect(t.assignedAgentId, 'agentA');
  });

  test('a second agent checking out the same task gets a conflict', () async {
    await seedOpen();
    await service.tryCheckout('t1', workspaceId: 'ws1', agentId: 'agentA');
    expect(
      () => service.tryCheckout('t1', workspaceId: 'ws1', agentId: 'agentB'),
      throwsA(isA<CheckoutConflictException>()),
    );
  });

  test('the holder re-checking out is idempotent (still holds)', () async {
    await seedOpen();
    await service.tryCheckout('t1', workspaceId: 'ws1', agentId: 'agentA');
    final again = await service.tryCheckout(
      't1',
      workspaceId: 'ws1',
      agentId: 'agentA',
    );
    expect(again, isTrue);
    final t = await repo.getById('ws1', 't1');
    expect(t!.assignedAgentId, 'agentA');
  });

  test(
    'releasing returns the task to open so another agent can claim it',
    () async {
      await seedOpen();
      await service.tryCheckout('t1', workspaceId: 'ws1', agentId: 'agentA');
      final released = await service.releaseCheckout(
        't1',
        workspaceId: 'ws1',
        agentId: 'agentA',
      );
      expect(released, isTrue);
      final t = await repo.getById('ws1', 't1');
      expect(t!.status, TicketStatus.open);
      expect(t.assignedAgentId, isNull);

      final acquiredByB = await service.tryCheckout(
        't1',
        workspaceId: 'ws1',
        agentId: 'agentB',
      );
      expect(acquiredByB, isTrue);
    },
  );

  test('checkout of a terminal task is unavailable (false)', () async {
    final t = Ticket(
      id: 't2',
      workspaceId: 'ws1',
      provider: TicketProvider.local,
      title: 'Done',
      status: TicketStatus.done,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    await repo.insert(t);
    final acquired = await service.tryCheckout(
      't2',
      workspaceId: 'ws1',
      agentId: 'agentA',
    );
    expect(acquired, isFalse);
  });

  test('cross-workspace checkout is denied: the id does not resolve', () async {
    final seeded = await seedOpen();

    // A workspace id selects the database file, so 'ws1''s ticket id is absent
    // in 'ws2'. The checkout finds nothing and claims nothing — it must not
    // reach across, and the ticket in its own workspace stays untouched.
    expect(
      await service.tryCheckout('t1', workspaceId: 'ws2', agentId: 'agentA'),
      isFalse,
    );
    final untouched = (await repo.getById('ws1', 't1'))!;
    expect(untouched.status, TicketStatus.open);
    expect(untouched.assignedAgentId, isNull);
    expect(untouched.version, seeded.version);
  });
}
