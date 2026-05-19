import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/mappers/ticket_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  const mapper = TicketMapper();

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Ticket fullTicket() => Ticket(
        id: 'ticket-1',
        workspaceId: 'ws-1',
        provider: TicketProvider.local,
        externalKey: 'ext-1',
        url: 'https://example.com/t/1',
        title: 'Test ticket',
        description: 'body',
        priority: TicketPriority.high,
        labels: const ['bug', 'ui'],
        status: TicketStatus.inProgress,
        rawStatus: 'In Progress',
        parentTicketId: null,
        projectId: 'proj-1',
        assignedAgentId: 'agent-1',
        assignedTeamId: 'team-1',
        delegatedByAgentId: 'agent-0',
        channelId: 'chan-1',
        errorMessage: null,
        linkedPrIds: const ['PR_1'],
        metadata: const {'k': 'v'},
        createdAt: DateTime.utc(2024, 1, 1),
        startedAt: DateTime.utc(2024, 1, 2),
        updatedAt: DateTime.utc(2024, 1, 3),
        version: 7,
        originKind: TicketOriginKind.manual,
        collaborators: const [],
      );

  test('toCompanion writes every kept column', () {
    final companion = mapper.toCompanion(fullTicket());
    expect(companion.status.value, TicketStatus.inProgress.toStorageString());
    expect(companion.assignedAgentId.value, 'agent-1');
    expect(companion.title.value, 'Test ticket');
    expect(companion.channelId.value, 'chan-1');
    expect(companion.version.value, 7);
  });

  test('toMirrorCompanion writes only mirror columns', () {
    final companion = mapper.toMirrorCompanion(fullTicket());

    expect(companion.title.value, 'Test ticket');
    expect(companion.status.value, TicketStatus.inProgress.toStorageString());
  });

  test('round-trips through the database keeping all fields', () async {
    final ticket = fullTicket();
    await db.ticketDao.insert(mapper.toCompanion(ticket));
    final row = await db.ticketDao.getById(ticket.id);
    expect(row, isNotNull);

    final restored = mapper.fromRow(row!, collaborators: const []);

    expect(restored.id, ticket.id);
    expect(restored.workspaceId, ticket.workspaceId);
    expect(restored.title, ticket.title);
    expect(restored.description, ticket.description);
    expect(restored.status, ticket.status);
    expect(restored.priority, ticket.priority);
    expect(restored.labels, ticket.labels);
    expect(restored.assignedAgentId, ticket.assignedAgentId);
    expect(restored.assignedTeamId, ticket.assignedTeamId);
    expect(restored.delegatedByAgentId, ticket.delegatedByAgentId);
    expect(restored.channelId, ticket.channelId);
    expect(restored.projectId, ticket.projectId);
    expect(restored.linkedPrIds, ticket.linkedPrIds);
    expect(restored.metadata, ticket.metadata);
    expect(restored.version, ticket.version);
    expect(restored.originKind, ticket.originKind);
    expect(restored.url, ticket.url);
    expect(restored.externalKey, ticket.externalKey);
    expect(restored.rawStatus, ticket.rawStatus);
  });

  test('collaborator round-trips', () {
    final c = TicketCollaborator(
      id: 'c1',
      ticketId: 't1',
      agentId: 'a1',
      role: TicketCollaboratorRole.reviewer,
      joinedAt: DateTime.utc(2024, 1, 1),
    );
    final companion = mapper.collaboratorToCompanion(c);
    expect(companion.agentId.value, 'a1');
    expect(companion.role.value, 'reviewer');
  });
}
