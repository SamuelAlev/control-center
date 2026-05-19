import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises the generated `TableData` data-class methods (`toJson`,
/// `toString`, `hashCode`, `operator ==`, `copyWith`, `toCompanion`) for the
/// largest tables. These methods are generated for every table but only the
/// row-construction factory runs when a DAO reads a row — the serialization /
/// equality / copy branches stay uncovered unless a test calls them directly.
/// Rows are inserted via their companions and read back so the exact data-class
/// constructors are never hand-constructed (which keeps the test robust to
/// schema additions).
void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
  });

  tearDown(() async => db.close());

  /// Runs every generated data-class method on [row] and asserts equality +
  /// copyWith identity behave sanely. Newer drift generates `copyWith` with
  /// plain nullable fields (not `Value<T>`), so [identityCopy] passes the row's
  /// own field values back through copyWith to reconstruct an equal row.
  /// [jsonKey] is the column whose value must survive `toJson`.
  void exercise<T>(
    T row,
    String contained,
    String jsonKey,
    T Function() identityCopy,
  ) {
    expect(row.toString(), contains(contained));
    expect(row == row, isTrue);
    expect(row.hashCode, row.hashCode);
    // ignore: avoid_dynamic_calls
    expect((row as dynamic).toJson()[jsonKey], isNotNull);
    expect(identityCopy() == row, isTrue);
  }

  group('MemoryFactsTableData generated methods', () {
    test('serialization + equality + copyWith run', () async {
      await db
          .into(db.memoryFactsTable)
          .insert(
            MemoryFactsTableCompanion.insert(
              id: 'mf-1',
              workspaceId: 'ws',
              domain: 'general',
              topic: 't',
              content: 'c',
            ),
          );
      final row = await (db.select(
        db.memoryFactsTable,
      )..where((t) => t.id.equals('mf-1'))).getSingle();
      exercise<MemoryFactsTableData>(
        row,
        'mf-1',
        'id',
        () => row.copyWith(id: row.id),
      );
    });
  });

  group('WebhookDeliveriesTableData generated methods', () {
    test('serialization + equality + copyWith run', () async {
      await db
          .into(db.webhookDeliveriesTable)
          .insert(
            WebhookDeliveriesTableCompanion.insert(
              id: 'wd-1',
              workspaceId: 'ws',
              triggerId: 'trg-1',
              status: 'delivered',
              signatureStatus: 'verified',
            ),
          );
      final row = await (db.select(
        db.webhookDeliveriesTable,
      )..where((t) => t.id.equals('wd-1'))).getSingle();
      exercise<WebhookDeliveriesTableData>(
        row,
        'wd-1',
        'id',
        () => row.copyWith(id: row.id),
      );
    });
  });

  group('CodeSymbolsTableData generated methods', () {
    test('serialization + equality + copyWith run', () async {
      await db
          .into(db.reposTable)
          .insert(
            ReposTableCompanion.insert(
              id: 'repo-1',
              name: 'repo-1',
              path: '/repo-1',
            ),
          );
      await db
          .into(db.codeSymbolsTable)
          .insert(
            CodeSymbolsTableCompanion.insert(
              id: 'sym-1',
              workspaceId: 'ws',
              repoId: 'repo-1',
              kind: 'function',
              name: 'bar',
              qualifiedName: 'lib.foo.bar',
              filePath: 'lib/foo.dart',
              language: 'dart',
              startLine: 1,
              endLine: 2,
            ),
          );
      final row = await (db.select(
        db.codeSymbolsTable,
      )..where((t) => t.id.equals('sym-1'))).getSingle();
      exercise<CodeSymbolsTableData>(
        row,
        'sym-1',
        'id',
        () => row.copyWith(id: row.id),
      );
    });
  });

  group('CalendarEventsTableData generated methods', () {
    test('serialization + equality + copyWith run', () async {
      await db
          .into(db.calendarAccountsTable)
          .insert(
            CalendarAccountsTableCompanion.insert(
              id: 'acc-1',
              workspaceId: 'ws',
              accountEmail: 'a@b.com',
            ),
          );
      await db
          .into(db.calendarEventsTable)
          .insert(
            CalendarEventsTableCompanion.insert(
              id: 'ce-1',
              workspaceId: 'ws',
              accountId: 'acc-1',
              externalEventId: 'ext-1',
              calendarId: 'cal-1',
              title: 'sync',
              startTime: DateTime(2026, 1, 1, 9),
              endTime: DateTime(2026, 1, 1, 10),
            ),
          );
      final row = await (db.select(
        db.calendarEventsTable,
      )..where((t) => t.id.equals('ce-1'))).getSingle();
      exercise<CalendarEventsTableData>(
        row,
        'ce-1',
        'id',
        () => row.copyWith(id: row.id),
      );
    });
  });

  group('SyncChangesTableData generated methods', () {
    test('serialization + equality + copyWith run', () async {
      await db
          .into(db.syncChangesTable)
          .insert(
            SyncChangesTableCompanion.insert(
              workspaceId: 'ws',
              seq: 1,
              store: 'tickets',
              tbl: 'tickets',
              pk: 't-1',
              op: 'upsert',
              createdAtMs: DateTime(2026, 1, 1).millisecondsSinceEpoch,
            ),
          );
      final row = await (db.select(
        db.syncChangesTable,
      )..where((t) => t.pk.equals('t-1'))).getSingle();
      exercise<SyncChangesTableData>(
        row,
        'tickets',
        'pk',
        () => row.copyWith(pk: row.pk),
      );
    });
  });

  group('ApprovalsTableData generated methods', () {
    test('serialization + equality + copyWith run', () async {
      await db.approvalDao.upsert(
        ApprovalsTableCompanion.insert(
          id: 'ap-1',
          workspaceId: 'ws',
          title: 'merge',
        ),
      );
      final row = await (db.select(
        db.approvalsTable,
      )..where((t) => t.id.equals('ap-1'))).getSingle();
      exercise<ApprovalsTableData>(
        row,
        'ap-1',
        'id',
        () => row.copyWith(id: row.id),
      );
    });
  });
}
