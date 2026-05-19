import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoTicketLinkRepository repo;

  /// Inserts the parent ticket rows in [workspaceId]'s own database so the FK
  /// constraints on `ticket_links` are satisfied. Every workspace mints its own
  /// rows now — a ticket in `ws-1`'s file is invisible from `ws-2`'s.
  Future<void> seedTickets(String workspaceId) async {
    final db = dbs.of(workspaceId);
    for (final ticketId in ['ticket-1', 'ticket-2', 'ticket-3']) {
      await db
          .into(db.ticketsTable)
          .insert(
            TicketsTableCompanion.insert(
              id: ticketId,
              workspaceId: workspaceId,
              title: 'Ticket $ticketId',
            ),
          );
    }
  }

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    await seedTestWorkspace(global, dbs, 'ws-2');
    await seedTickets('ws-1');
    await seedTickets('ws-2');
    repo = DaoTicketLinkRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  TicketLink makeLink({
    String id = 'l-1',
    String workspaceId = 'ws-1',
    String source = 'ticket-1',
    String target = 'ticket-2',
    TicketLinkType type = TicketLinkType.blocks,
    DateTime? createdAt,
  }) => TicketLink(
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
      await repo.insert(
        makeLink(id: 'l-1', source: 'ticket-1', target: 'ticket-2'),
      );
      await repo.insert(
        makeLink(id: 'l-2', source: 'ticket-1', target: 'ticket-3'),
      );

      final links = await repo.getForTicket('ws-1', 'ticket-1');
      expect(links.length, 2);
    });

    test('returns links where ticket is target', () async {
      await repo.insert(
        makeLink(id: 'l-1', source: 'ticket-2', target: 'ticket-1'),
      );

      final links = await repo.getForTicket('ws-1', 'ticket-1');
      expect(links.length, 1);
      expect(links.first.targetTicketId, 'ticket-1');
    });

    /// The repository reads the workspace off the [TicketLink] on write and off
    /// the parameter on read, so this now proves ROUTING (each link landed in
    /// its own workspace's file) rather than a `WHERE workspace_id = ?` filter.
    test('scoped to workspace', () async {
      await repo.insert(makeLink(workspaceId: 'ws-1'));
      await repo.insert(
        makeLink(
          id: 'l-2',
          source: 'ticket-2',
          target: 'ticket-3',
          workspaceId: 'ws-2',
        ),
      );

      final ws1 = await repo.getForTicket('ws-1', 'ticket-1');
      expect(ws1.length, 1);

      final ws2 = await repo.getForTicket('ws-2', 'ticket-2');
      expect(ws2.length, 1);

      // ws-1's link is not reachable from ws-2 and vice versa.
      expect(await repo.getForTicket('ws-2', 'ticket-1'), isEmpty);
      expect(await repo.getForTicket('ws-1', 'ticket-3'), isEmpty);
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
    test('removes link by source, target and type', () async {
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
