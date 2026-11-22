import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_domain/features/ticketing/domain/value_objects/delegation_brief.dart';
import 'package:cc_mcp/src/tools/delegate_task_tool.dart';
import 'package:test/test.dart';

import 'peer_tool_kit.dart';

/// `delegate_task`'s structured brief: `done_means`, `constraints` and
/// `references`, rendered under fixed headings after the free text and kept
/// in the ticket's metadata.
void main() {
  late _Tickets tickets;
  late DelegateTaskTool tool;

  setUp(() {
    tickets = _Tickets();
    tool = DelegateTaskTool(
      service: TicketWorkflowService(
        repository: tickets,
        eventBus: DomainEventBus(),
        resolveEffectiveAutonomy:
            ({required workspaceId, required agentId, spaceId}) async =>
                AutonomyLevel.actWithApproval,
        resolveRemainingBudgetMicros:
            ({required workspaceId, required agentId}) async => null,
      ),
      peerAsks: PeerKit().service,
    );
  });

  Map<String, dynamic> call(Map<String, dynamic> extra) => {
    'workspace_id': 'ws-1',
    'title': 'Index audit',
    'from_agent_id': 'agent-a',
    'to_agent_id': 'agent-b',
    ...extra,
  };

  test('renders each section under its heading after the free text and '
      'stores the brief in the ticket metadata', () async {
    final result = await tool.run(
      call({
        'description': 'Audit the indexes of the orders table.',
        'acceptance_criteria': 'No full scans in the slow log.',
        'done_means': ['Every index has an owner', 'Unused ones\nare listed'],
        'constraints': 'Do not drop anything.',
        'references': ['db/schema.sql', 'TICKET-12'],
      }),
    );

    expect(result.isError, isFalse, reason: result.content.first.text);
    final ticket = tickets.store.values.single;
    expect(
      ticket.description,
      'Audit the indexes of the orders table.\n\n'
      'Acceptance criteria:\nNo full scans in the slow log.\n\n'
      '## Done means\n'
      '1. Every index has an owner\n'
      '2. Unused ones are listed\n\n'
      '## Constraints\n'
      'Do not drop anything.\n\n'
      '## References\n'
      '- db/schema.sql\n'
      '- TICKET-12',
    );
    expect(ticket.metadata[DelegationBrief.metadataKey], {
      'done_means': ['Every index has an owner', 'Unused ones are listed'],
      'constraints': 'Do not drop anything.',
      'references': ['db/schema.sql', 'TICKET-12'],
    });
    expect(
      DelegationBrief.fromMetadata(ticket.metadata)!.doneMeans,
      hasLength(2),
    );
  });

  test('an old-style call is unchanged: no headings, no metadata', () async {
    final result = await tool.run(
      call({
        'description': 'Audit the indexes.',
        'acceptance_criteria': 'No full scans.',
      }),
    );

    expect(result.isError, isFalse);
    final ticket = tickets.store.values.single;
    expect(
      ticket.description,
      'Audit the indexes.\n\nAcceptance criteria:\nNo full scans.',
    );
    expect(ticket.metadata, isEmpty);
  });

  test('the sections stand alone without free text', () async {
    await tool.run(
      call({
        'done_means': ['Report filed'],
      }),
    );
    expect(
      tickets.store.values.single.description,
      '## Done means\n1. Report filed',
    );
  });

  group('limits refuse before any ticket exists', () {
    for (final (name, extra, problem)
        in <(String, Map<String, dynamic>, String)>[
          (
            'more than 12 done_means items',
            {
              'done_means': [for (var i = 0; i < 13; i++) 'Item $i'],
            },
            'at most 12',
          ),
          (
            'a done_means item over 300 characters',
            {
              'done_means': ['x' * 301],
            },
            'at most 300',
          ),
          (
            'a blank done_means item',
            {
              'done_means': ['  '],
            },
            'empty',
          ),
          (
            'constraints over 2,000 characters',
            {'constraints': 'c' * 2001},
            'at most 2000',
          ),
          (
            'more than 20 references',
            {
              'references': [for (var i = 0; i < 21; i++) 'ref-$i'],
            },
            'at most 20',
          ),
          (
            'done_means that is not a list of strings',
            {'done_means': 'Report filed'},
            'done_means',
          ),
          (
            'constraints that is not a string',
            {
              'constraints': ['a'],
            },
            'constraints',
          ),
        ]) {
      test(name, () async {
        final result = await tool.run(call(extra));
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains(problem));
        expect(tickets.store, isEmpty);
      });
    }

    test('exactly at every limit is accepted', () async {
      final result = await tool.run(
        call({
          'done_means': [for (var i = 0; i < 12; i++) 'd' * 300],
          'constraints': 'c' * 2000,
          'references': [for (var i = 0; i < 20; i++) 'ref-$i'],
        }),
      );
      expect(result.isError, isFalse, reason: result.content.first.text);
    });
  });

  test('the schema declares the fields with their limits, and the '
      'description asks for a self-contained brief', () {
    final props = tool.inputSchema['properties'] as Map<String, dynamic>;
    expect((props['done_means'] as Map)['maxItems'], 12);
    expect(((props['done_means'] as Map)['items'] as Map)['maxLength'], 300);
    expect((props['constraints'] as Map)['maxLength'], 2000);
    expect((props['references'] as Map)['maxItems'], 20);
    expect(
      tool.description,
      contains(
        'The recipient works from the brief alone, so make it '
        'self-contained, with acceptance criteria in done_means.',
      ),
    );
  });
}

class _Tickets implements TicketRepository {
  final Map<String, Ticket> store = {};

  @override
  Future<void> insert(Ticket ticket) async => store[ticket.id] = ticket;

  @override
  Future<Ticket?> getById(String workspaceId, String id) async {
    final ticket = store[id];
    return ticket?.workspaceId == workspaceId ? ticket : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
