import 'package:control_center/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDatabase();
    // Endpoints must exist (FK ON DELETE CASCADE references tickets).
    for (final id in ['t-1', 't-2', 't-3']) {
      await db.ticketDao.insert(
        TicketsTableCompanion.insert(id: id, workspaceId: 'w-1', title: id),
      );
    }
    await db.ticketDao.insert(
      TicketsTableCompanion.insert(id: 't-x', workspaceId: 'w-2', title: 'x'),
    );
  });

  tearDown(() async {
    await db.close();
  });

  TicketLinksTableCompanion link(
    String id,
    String ws,
    String src,
    String tgt,
    String type,
  ) =>
      TicketLinksTableCompanion.insert(
        id: id,
        workspaceId: ws,
        sourceTicketId: src,
        targetTicketId: tgt,
        type: type,
      );

  test('getForTicket returns links on either endpoint, scoped to workspace',
      () async {
    await db.ticketLinkDao.insert(link('l-1', 'w-1', 't-1', 't-2', 'blocks'));
    await db.ticketLinkDao
        .insert(link('l-2', 'w-1', 't-3', 't-1', 'relates_to'));

    final forT1 = await db.ticketLinkDao.getForTicket('w-1', 't-1');
    expect(forT1.map((l) => l.id), unorderedEquals(['l-1', 'l-2']));

    // A foreign workspace sees nothing.
    final foreign = await db.ticketLinkDao.getForTicket('w-2', 't-1');
    expect(foreign, isEmpty);
  });

  test('insert is idempotent on (source, target, type)', () async {
    await db.ticketLinkDao.insert(link('l-1', 'w-1', 't-1', 't-2', 'blocks'));
    // Same edge, different id — ignored by the unique index.
    await db.ticketLinkDao.insert(link('l-2', 'w-1', 't-1', 't-2', 'blocks'));

    final all = await db.ticketLinkDao.getForTicket('w-1', 't-1');
    expect(all.length, 1);
    expect(all.single.id, 'l-1');
  });

  test('deleteByEndpoints removes the matching edge, scoped to workspace',
      () async {
    await db.ticketLinkDao.insert(link('l-1', 'w-1', 't-1', 't-2', 'blocks'));

    final foreign = await db.ticketLinkDao.deleteByEndpoints(
      workspaceId: 'w-2',
      sourceTicketId: 't-1',
      targetTicketId: 't-2',
      type: 'blocks',
    );
    expect(foreign, 0);

    final removed = await db.ticketLinkDao.deleteByEndpoints(
      workspaceId: 'w-1',
      sourceTicketId: 't-1',
      targetTicketId: 't-2',
      type: 'blocks',
    );
    expect(removed, 1);
    expect(await db.ticketLinkDao.getForTicket('w-1', 't-1'), isEmpty);
  });

  test('links cascade when an endpoint ticket is deleted', () async {
    await db.ticketLinkDao.insert(link('l-1', 'w-1', 't-1', 't-2', 'blocks'));
    await db.ticketDao.deleteTicket('t-2', 'w-1');
    expect(await db.ticketLinkDao.getForTicket('w-1', 't-1'), isEmpty);
  });
}
