import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/ticket_link_dao.dart';
import 'package:cc_persistence/repositories/dao_ticket_link_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DaoTicketLinkRepository repo;
  late TicketLinkDao dao;

  setUp(() async {
    db = createTestDatabase();
    // Insert parent ticket rows so FK constraints on ticket_links are satisfied.
    for (final ticketId in ['ticket-1', 'ticket-2', 'ticket-3']) {
      await db.into(db.ticketsTable).insert(
            TicketsTableCompanion.insert(
              id: ticketId,
              workspaceId: 'ws-1',
              title: 'Ticket $ticketId',
            ),
          );
    }
    dao = TicketLinkDao(db);
    repo = DaoTicketLinkRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  TicketLink makeLink({
    String id = 'l-1',
    String workspaceId = 'ws-1',
    String source = 'ticket-1',
    String target = 'ticket-2',
    TicketLinkType type = TicketLinkType.blocks,
    DateTime? createdAt,
  }) =>
      TicketLink(
        id: id,
        workspaceId: workspaceId,
        sourceTicketId: source,
        targetTicketId: target,
        type: type,
        createdAt: createdAt ?? DateTime(2025, 1, 1),
      );

  group('insert', () {
    test('inserts and retrieves link', () async {
      final link = makeLink();
      await repo.insert(link);

      final links = await repo.getForTicket('ws-1', 'ticket-1');
      expect(links.length, 1);
      expect(links.first.sourceTicketId, 'ticket-1');
      expect(links.first.targetTicketId, 'ticket-2');
      expect(links.first.type, TicketLinkType.blocks);
    });

    test('insert ignores duplicate (same source, target, type)', () async {
      await repo.insert(makeLink());
      await repo.insert(makeLink());

      final links = await repo.getForTicket('ws-1', 'ticket-1');
      expect(links.length, 1);
    });
  });

  group('getForTicket', () {
    test('returns links where ticket is source', () async {
      await repo.insert(makeLink(id: 'l-1', source: 'ticket-1', target: 'ticket-2'));
      await repo.insert(makeLink(id: 'l-2', source: 'ticket-1', target: 'ticket-3'));

      final links = await repo.getForTicket('ws-1', 'ticket-1');
      expect(links.length, 2);
    });

    test('returns links where ticket is target', () async {
      await repo.insert(makeLink(id: 'l-1', source: 'ticket-2', target: 'ticket-1'));

      final links = await repo.getForTicket('ws-1', 'ticket-1');
      expect(links.length, 1);
      expect(links.first.targetTicketId, 'ticket-1');
    });

    test('scoped to workspace', () async {
      await repo.insert(makeLink(workspaceId: 'ws-1'));
      // Use different source/target so the unique (source, target, type) index
      // does not collide with the first link.
      await repo.insert(makeLink(id: 'l-2', source: 'ticket-2', target: 'ticket-3', workspaceId: 'ws-2'));

      final ws1 = await repo.getForTicket('ws-1', 'ticket-1');
      expect(ws1.length, 1);

      final ws2 = await repo.getForTicket('ws-2', 'ticket-2');
      expect(ws2.length, 1);
    });

    test('returns empty for uninvolved ticket', () async {
      await repo.insert(makeLink());

      final links = await repo.getForTicket('ws-1', 'unrelated');
      expect(links, isEmpty);
    });
  });

  group('deleteById', () {
    test('removes link', () async {
      await repo.insert(makeLink());
      await repo.deleteById('l-1', workspaceId: 'ws-1');

      final links = await repo.getForTicket('ws-1', 'ticket-1');
      expect(links, isEmpty);
    });

    test('scoped to workspace — cannot delete from wrong workspace', () async {
      await repo.insert(makeLink(workspaceId: 'ws-1'));
      final count = await repo.deleteById('l-1', workspaceId: 'ws-2');
      expect(count, 0);

      final links = await repo.getForTicket('ws-1', 'ticket-1');
      expect(links.length, 1);
    });
  });

  group('deleteByEndpoints', () {
    test('removes link by source, target, and type', () async {
      await repo.insert(makeLink());

      final count = await repo.deleteByEndpoints(
        workspaceId: 'ws-1',
        sourceTicketId: 'ticket-1',
        targetTicketId: 'ticket-2',
        type: TicketLinkType.blocks,
      );
      expect(count, 1);

      final links = await repo.getForTicket('ws-1', 'ticket-1');
      expect(links, isEmpty);
    });

    test('link type must match', () async {
      await repo.insert(makeLink(type: TicketLinkType.blocks));

      final count = await repo.deleteByEndpoints(
        workspaceId: 'ws-1',
        sourceTicketId: 'ticket-1',
        targetTicketId: 'ticket-2',
        type: TicketLinkType.relatesTo,
      );
      expect(count, 0);
    });
  });

  group('watchForTicket', () {
    test('emits current links', () async {
      await repo.insert(makeLink());

      final results = await repo.watchForTicket('ws-1', 'ticket-1').first;
      expect(results.length, 1);
    });
  });

  group('different link types', () {
    test('blocks type', () async {
      await repo.insert(makeLink(type: TicketLinkType.blocks));
      final links = await repo.getForTicket('ws-1', 'ticket-1');
      expect(links.first.type, TicketLinkType.blocks);
    });

    test('relatesTo type', () async {
      await repo.insert(makeLink(type: TicketLinkType.relatesTo));
      final links = await repo.getForTicket('ws-1', 'ticket-1');
      expect(links.first.type, TicketLinkType.relatesTo);
    });

    test('duplicateOf type', () async {
      await repo.insert(makeLink(type: TicketLinkType.duplicateOf));
      final links = await repo.getForTicket('ws-1', 'ticket-1');
      expect(links.first.type, TicketLinkType.duplicateOf);
    });
  });
}
