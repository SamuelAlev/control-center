import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_link_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/tools/ticket_link_tools.dart';
import 'package:test/test.dart';

void main() {
  late _FakeTickets tickets;
  late TicketRelationTool tool;

  setUp(() {
    tickets = _FakeTickets();
    tool = TicketRelationTool(
      linkService: TicketLinkService(
        linkRepository: _FakeLinks(),
        ticketRepository: tickets,
      ),
      workflow: TicketWorkflowService(
        repository: tickets,
        eventBus: DomainEventBus(),
      ),
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({
      'ticket_id': 't1',
      'related_ticket_id': 't2',
      'relation': 'related_to',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('unknown tickets are refused', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'ticket_id': 't1',
      'related_ticket_id': 't2',
      'relation': 'related_to',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('does not exist'));
  });
}

class _FakeTickets implements TicketRepository {
  @override
  Future<Ticket?> getById(String workspaceId, String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeLinks implements TicketLinkRepository {
  @override
  Future<List<TicketLink>> getForTicket(
    String workspaceId,
    String ticketId,
  ) async => const <TicketLink>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
