import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/ticketing/data/mappers/ticket_link_mapper.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_link.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  const mapper = TicketLinkMapper();

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// Inserts two tickets (for FK constraints) and a link between them,
  /// then returns the generated link row.
  Future<TicketLinksTableData> insertLink({
    String id = 'link-1',
    String workspaceId = 'ws-1',
    String sourceTicketId = 'ticket-src',
    String targetTicketId = 'ticket-tgt',
    String type = 'blocks',
  }) async {
    // Ensure both tickets exist (FK constraint).
    for (final ticketId in {sourceTicketId, targetTicketId}) {
      final existing = await db.ticketDao.getById(ticketId);
      if (existing == null) {
        await db.ticketDao.insert(
          TicketsTableCompanion.insert(
            id: ticketId,
            workspaceId: workspaceId,
            title: 'Ticket $ticketId',
          ),
        );
      }
    }
    await db.ticketLinkDao.insert(
      TicketLinksTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        sourceTicketId: sourceTicketId,
        targetTicketId: targetTicketId,
        type: type,
      ),
    );
    final links = await db.ticketLinkDao.getForTicket(workspaceId, sourceTicketId);
    return links.firstWhere((l) => l.id == id);
  }

  group('TicketLinkMapper', () {
    test('fromRowOrNull maps all fields correctly', timeout: const Timeout.factor(2),
        () async {
      final row = await insertLink();

      final link = mapper.fromRowOrNull(row)!;

      expect(link.id, 'link-1');
      expect(link.workspaceId, 'ws-1');
      expect(link.sourceTicketId, 'ticket-src');
      expect(link.targetTicketId, 'ticket-tgt');
      expect(link.type, TicketLinkType.blocks);
      expect(link.createdAt, isA<DateTime>());
    });

    test('fromRowOrNull returns null for unknown type', timeout: const Timeout.factor(2),
        () async {
      // Insert a link row with a type that is not recognized.
      // We need to bypass the DAO since it uses valid types.
      await insertLink(type: 'blocks');
      // Construct a fake Data object by using the row but changing type.
      // Since TicketsTableData is immutable and generated, we test through the
      // companion: create a companion with the bad type, re-insert via custom
      // select. Actually easier: test directly with a manually-constructed
      // companion and a raw insert.
      // However, we can't construct TicketLinksTableData directly.
      // Instead, insert via companion with bad type using the DAO and then
      // verify fromRowOrNull returns null. But the DAO won't validate types.
      // Let's insert directly via custom statement.
      await db.customStatement(
        'INSERT INTO ticket_links (id, workspace_id, source_ticket_id, target_ticket_id, type) '
        "VALUES ('link-bad', 'ws-1', 'ticket-src', 'ticket-tgt', 'unknown_type')",
      );
      final rows = await db.ticketLinkDao.getForTicket('ws-1', 'ticket-src');
      final badRow = rows.firstWhere((r) => r.id == 'link-bad');

      final result = mapper.fromRowOrNull(badRow);

      expect(result, isNull);
    });

    test('fromRowOrNull maps all TicketLinkType values', timeout: const Timeout.factor(2),
        () async {
      const typeMap = {
        'blocks': TicketLinkType.blocks,
        'relates_to': TicketLinkType.relatesTo,
        'duplicate_of': TicketLinkType.duplicateOf,
      };
      for (final entry in typeMap.entries) {
        final row = await insertLink(
          id: 'link-${entry.key}',
          sourceTicketId: 'ticket-src',
          targetTicketId: 'ticket-tgt-${entry.key}',
          type: entry.key,
        );
        final link = mapper.fromRowOrNull(row);
        expect(link, isNotNull, reason: 'fromRowOrNull returned null for ${entry.key}');
        expect(link!.type, entry.value);
      }
    });

    test('toCompanion round-trips through fromRowOrNull', timeout: const Timeout.factor(2),
        () async {
      final original = TicketLink(
        id: 'link-rt',
        workspaceId: 'ws-1',
        sourceTicketId: 'ticket-src',
        targetTicketId: 'ticket-tgt',
        type: TicketLinkType.relatesTo,
        createdAt: DateTime(2025, 3, 15),
      );

      final companion = mapper.toCompanion(original);

      expect(companion.id.value, 'link-rt');
      expect(companion.workspaceId.value, 'ws-1');
      expect(companion.sourceTicketId.value, 'ticket-src');
      expect(companion.targetTicketId.value, 'ticket-tgt');
      expect(companion.type.value, 'relates_to');
      expect(companion.createdAt.value, DateTime(2025, 3, 15));

      // Ensure both endpoint tickets exist for FK constraint.
      for (final tid in {'ticket-src', 'ticket-tgt'}) {
        final existing = await db.ticketDao.getById(tid);
        if (existing == null) {
          await db.ticketDao.insert(
            TicketsTableCompanion.insert(
              id: tid,
              workspaceId: 'ws-1',
              title: 'Ticket $tid',
            ),
          );
        }
      }

      // Insert and read back
      await db.ticketLinkDao.insert(companion);
      final links =
          await db.ticketLinkDao.getForTicket('ws-1', 'ticket-src');
      final row = links.firstWhere((l) => l.id == 'link-rt');
      final roundTripped = mapper.fromRowOrNull(row)!;

      expect(roundTripped.id, original.id);
      expect(roundTripped.workspaceId, original.workspaceId);
      expect(roundTripped.sourceTicketId, original.sourceTicketId);
      expect(roundTripped.targetTicketId, original.targetTicketId);
      expect(roundTripped.type, original.type);
    });

    test('toCompanion serializes blocks type correctly', timeout: const Timeout.factor(2),
        () async {
      final link = TicketLink(
        id: 'l1',
        workspaceId: 'ws',
        sourceTicketId: 'a',
        targetTicketId: 'b',
        type: TicketLinkType.blocks,
        createdAt: DateTime(2025),
      );

      expect(mapper.toCompanion(link).type.value, 'blocks');
    });

    test('toCompanion serializes relatesTo type correctly', timeout: const Timeout.factor(2),
        () async {
      final link = TicketLink(
        id: 'l2',
        workspaceId: 'ws',
        sourceTicketId: 'a',
        targetTicketId: 'b',
        type: TicketLinkType.relatesTo,
        createdAt: DateTime(2025),
      );

      expect(mapper.toCompanion(link).type.value, 'relates_to');
    });

    test('toCompanion serializes duplicateOf type correctly', timeout: const Timeout.factor(2),
        () async {
      final link = TicketLink(
        id: 'l3',
        workspaceId: 'ws',
        sourceTicketId: 'a',
        targetTicketId: 'b',
        type: TicketLinkType.duplicateOf,
        createdAt: DateTime(2025),
      );

      expect(mapper.toCompanion(link).type.value, 'duplicate_of');
    });

    test('fromRowOrNull for null type returns null', timeout: const Timeout.factor(2),
        () async {
      // TicketLinkType.fromStorage(null) returns null
      expect(TicketLinkType.fromStorage(null), isNull);
    });
  });
}
