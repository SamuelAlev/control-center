import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/repositories/dao_ticket_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

/// Constructs a [Ticket] with defaults suitable for testing.
Ticket _ticket({
  String id = 't-1',
  String workspaceId = 'ws-1',
  String title = 'Test ticket',
  TicketStatus status = TicketStatus.open,
  TicketProvider provider = TicketProvider.local,
  DateTime? createdAt,
  DateTime? updatedAt,
  int version = 0,
  String? assignedAgentId,
  String? assignedTeamId,
  String? parentTicketId,
  String? channelId,
  String? externalKey,
  String? url,
  String? description,
  List<String> labels = const [],
  TicketPriority priority = TicketPriority.none,
  TicketOriginKind originKind = TicketOriginKind.manual,
}) {
  final now = DateTime(2026, 6, 1);
  return Ticket(
    id: id,
    workspaceId: workspaceId,
    title: title,
    status: status,
    provider: provider,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
    version: version,
    assignedAgentId: assignedAgentId,
    assignedTeamId: assignedTeamId,
    parentTicketId: parentTicketId,
    channelId: channelId,
    externalKey: externalKey,
    url: url,
    description: description,
    labels: labels,
    priority: priority,
    originKind: originKind,
  );
}

TicketCollaborator _collaborator({
  String id = 'c-1',
  String ticketId = 't-1',
  String agentId = 'agent-1',
  DateTime? joinedAt,
}) {
  return TicketCollaborator(
    id: id,
    ticketId: ticketId,
    agentId: agentId,
    joinedAt: joinedAt ?? DateTime(2026, 6, 1),
  );
}

void main() {
  late AppDatabase db;
  late DaoTicketRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = DaoTicketRepository(db.ticketDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('insert + getById', () {
    test('round-trips a ticket', () async {
      await repo.insert(_ticket(id: 't-1', title: 'Hello'));
      final ticket = await repo.getById('t-1');
      expect(ticket, isNotNull);
      expect(ticket!.title, 'Hello');
      expect(ticket.workspaceId, 'ws-1');
    });

    test('getById returns null for unknown id', () async {
      expect(await repo.getById('no-such'), isNull);
    });
  });

  group('update (optimistic concurrency)', () {
    test('update with correct expectedVersion succeeds', () async {
      await repo.insert(_ticket(id: 't-1', title: 'v1', version: 1));
      await repo.update(
        _ticket(id: 't-1', title: 'v2', version: 2),
        expectedVersion: 1,
      );
      expect((await repo.getById('t-1'))!.title, 'v2');
    });

    test('update with stale expectedVersion throws', () async {
      await repo.insert(_ticket(id: 't-1', title: 'v1', version: 1));
      await expectLater(
        repo.update(
          _ticket(id: 't-1', title: 'v2', version: 2),
          expectedVersion: 0,
        ),
        throwsA(isA<ConcurrencyConflictException>()),
      );
    });

    test('update on non-existent ticket throws', () async {
      await expectLater(
        repo.update(
          _ticket(id: 'no-such', title: 'Ghost', version: 1),
          expectedVersion: 0,
        ),
        throwsA(isA<ConcurrencyConflictException>()),
      );
    });
  });

  group('delete', () {
    test('deletes a ticket so getById returns null', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.delete('t-1', workspaceId: 'ws-1');
      expect(await repo.getById('t-1'), isNull);
    });

    test('delete with wrong workspace does not delete', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1'));
      await repo.delete('t-1', workspaceId: 'ws-2');
      expect(await repo.getById('t-1'), isNotNull);
    });

    test('delete cascades to collaborators', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(_collaborator(ticketId: 't-1', agentId: 'alice'));
      await repo.delete('t-1', workspaceId: 'ws-1');
      expect(await repo.getCollaborators('t-1'), isEmpty);
    });
  });

  group('forAgent', () {
    test('returns tickets assigned to the agent in the workspace', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1', assignedAgentId: 'a1'));
      await repo.insert(_ticket(id: 't-2', workspaceId: 'ws-1', assignedAgentId: 'a2'));
      await repo.insert(_ticket(id: 't-3', workspaceId: 'ws-2', assignedAgentId: 'a1'));

      final result = await repo.forAgent('ws-1', 'a1');
      expect(result.map((t) => t.id), ['t-1']);
    });
  });

  group('collaborators', () {
    test('add + get + remove', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(_collaborator(id: 'c1', ticketId: 't-1', agentId: 'alice'));
      await repo.addCollaborator(_collaborator(id: 'c2', ticketId: 't-1', agentId: 'bob'));

      var collabs = await repo.getCollaborators('t-1');
      expect(collabs.map((c) => c.agentId), containsAll(['alice', 'bob']));

      await repo.removeCollaborator('t-1', 'alice');
      collabs = await repo.getCollaborators('t-1');
      expect(collabs.map((c) => c.agentId), ['bob']);
    });
  });
}
