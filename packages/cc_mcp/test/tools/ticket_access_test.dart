import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/tools/ticket_access.dart';
import 'package:test/test.dart';

void main() {
  TicketWorkflowService service(Map<String, Ticket> store) =>
      TicketWorkflowService(
        repository: _UnscopedTickets(store),
        eventBus: DomainEventBus(),
      );

  Ticket ticket(String id, String workspaceId) => Ticket(
    id: id,
    workspaceId: workspaceId,
    title: 'Fix login',
    status: TicketStatus.open,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  test('a missing ticket is an error', () async {
    final result = await ticketMutationError(service({}), 'ws-1', 'missing');
    expect(result, isNotNull);
    expect(result!.isError, isTrue);
    expect(result.content.single.text, 'Ticket not found.');
  });

  test('a ticket from another workspace is refused', () async {
    final result = await ticketMutationError(
      service({'t1': ticket('t1', 'ws-other')}),
      'ws-1',
      't1',
    );
    expect(result, isNotNull);
    expect(result!.isError, isTrue);
    expect(
      result.content.single.text,
      'Ticket belongs to a different workspace.',
    );
  });

  test('a ticket in the caller workspace is allowed through', () async {
    final result = await ticketMutationError(
      service({'t1': ticket('t1', 'ws-1')}),
      'ws-1',
      't1',
    );
    expect(result, isNull);
  });
}

/// Returns the stored row even when its workspace disagrees with the query.
///
/// The production repository hides that row. This stub does not, so the
/// helper's own workspace check is what the test observes.
class _UnscopedTickets implements TicketRepository {
  _UnscopedTickets(this.store);

  final Map<String, Ticket> store;

  @override
  Future<Ticket?> getById(String workspaceId, String id) async => store[id];

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
