import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_proposal_validator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/tools/propose_orchestration_tool.dart';
import 'package:test/test.dart';

void main() {
  late _FakeTickets tickets;
  late ProposeOrchestrationTool tool;

  setUp(() {
    tickets = _FakeTickets();
    tool = ProposeOrchestrationTool(
      orchestrations: _FakeOrchestrations(),
      validator: const OrchestrationProposalValidator(),
      tickets: tickets,
      ticketWorkflow: TicketWorkflowService(
        repository: tickets,
        eventBus: DomainEventBus(),
      ),
      messaging: _FakeMessaging(),
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'ticket_id': 't1', 'goal': 'Ship it'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('unknown ticket is refused', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'ticket_id': 'missing',
      'goal': 'Ship it',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('not found'));
  });
}

class _FakeTickets implements TicketRepository {
  @override
  Future<Ticket?> getById(String workspaceId, String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeOrchestrations implements OrchestrationRepository {
  @override
  Future<Orchestration?> getById(String workspaceId, String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeMessaging implements MessagingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
