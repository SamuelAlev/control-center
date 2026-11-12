import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/value_objects/activity_cursor.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late GlobalDatabase db;
  late DaoServerAuditRepository audit;

  setUp(() {
    db = GlobalDatabase.forTesting(NativeDatabase.memory());
    audit = DaoServerAuditRepository(db.serverAuditDao);
  });

  tearDown(() => db.close());

  ServerAuditEntry entry(
    String id, {
    DateTime? at,
    AuditOutcome outcome = AuditOutcome.ok,
    String userId = 'u-1',
    String op = 'connect.setChoice',
  }) => ServerAuditEntry(
    id: id,
    userId: userId,
    deviceId: 'd-1',
    ip: '127.0.0.1',
    op: op,
    argNames: const ['mode', 'url'],
    outcome: outcome,
    createdAt: at ?? DateTime.utc(2026, 11, 10),
  );

  test('reads back what it wrote, newest first', () async {
    await audit.append(entry('a', at: DateTime.utc(2026, 11, 9)));
    await audit.append(
      entry('b', at: DateTime.utc(2026, 11, 10), outcome: .denied),
    );
    await audit.append(
      entry('c', at: DateTime.utc(2026, 11, 8), outcome: .failed),
    );

    expect(await audit.pageRows(limit: 10), [
      entry('b', at: DateTime.utc(2026, 11, 10), outcome: .denied),
      entry('a', at: DateTime.utc(2026, 11, 9)),
      entry('c', at: DateTime.utc(2026, 11, 8), outcome: .failed),
    ]);
    expect(await audit.pageRows(limit: 1), hasLength(1));
  });

  test('rows written in the same second keep their write order', () async {
    for (final id in ['a', 'b', 'c']) {
      await audit.append(entry(id));
    }

    expect(
      [for (final e in await audit.pageRows(limit: 10)) e.id],
      ['c', 'b', 'a'],
    );
  });

  test('argument names are stored sorted and nothing else of the call', () {
    final e = ServerAuditEntry(
      id: 'x',
      userId: 'u-1',
      op: 'connect.rotateKey',
      argNames: const ['url', 'key'],
      outcome: .ok,
      createdAt: DateTime.utc(2026),
    );
    expect(e.argNames, ['key', 'url']);
  });

  test('keeps only the newest rows past the cap', () async {
    // Fill straight to the cap so the test does not pay 20000 transactions.
    await db.customStatement(
      'WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n '
      'WHERE i < ${ServerAuditDao.kept}) '
      'INSERT INTO server_audit '
      '(id, user_id, op, arg_names, outcome, created_at) '
      "SELECT 'old-' || i, 'u-1', 'connect.setChoice', '[]', 'ok', i FROM n",
    );

    await audit.append(entry('new'));

    final count = await db
        .customSelect('SELECT COUNT(*) AS c FROM server_audit')
        .getSingle();
    expect(count.read<int>('c'), ServerAuditDao.kept);
    final ids = await db
        .customSelect(
          "SELECT id FROM server_audit WHERE id IN ('old-1', 'new')",
        )
        .get();
    expect(ids.map((r) => r.read<String>('id')), ['new']);
  });

  test('prunes once per batch of appends, not on every append', () async {
    await db.customStatement(
      'WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n '
      'WHERE i < ${ServerAuditDao.kept}) '
      'INSERT INTO server_audit '
      '(id, user_id, op, arg_names, outcome, created_at) '
      "SELECT 'old-' || i, 'u-1', 'connect.setChoice', '[]', 'ok', i FROM n",
    );
    Future<int> rows() async =>
        (await db
                .customSelect('SELECT COUNT(*) AS c FROM server_audit')
                .getSingle())
            .read<int>('c');

    // The first append of a process prunes.
    await audit.append(entry('first'));
    expect(await rows(), ServerAuditDao.kept);
    // The rest of the batch only inserts.
    for (var i = 1; i < ServerAuditDao.pruneEvery; i++) {
      await audit.append(entry('batch-$i'));
    }
    expect(await rows(), ServerAuditDao.kept + ServerAuditDao.pruneEvery - 1);
    // The next batch starts with a prune back to the cap, newest kept.
    await audit.append(entry('next'));
    expect(await rows(), ServerAuditDao.kept);
    final newest = await audit.pageRows(limit: 1);
    expect(newest.single.id, 'next');
  });

  test('refuses an entry that names nobody or no op', () {
    expect(
      () => ServerAuditEntry(
        id: 'x',
        userId: '',
        op: 'connect.setChoice',
        argNames: const [],
        outcome: .ok,
        createdAt: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
    expect(
      () => ServerAuditEntry(
        id: 'x',
        userId: 'u-1',
        op: '',
        argNames: const [],
        outcome: .ok,
        createdAt: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
  });

  group('paging and filters', () {
    setUp(() async {
      await audit.append(entry('a', at: DateTime.utc(2026, 11, 1)));
      await audit.append(
        entry(
          'b',
          at: DateTime.utc(2026, 11, 2),
          outcome: .denied,
          userId: 'u-2',
          op: 'sso.configure',
        ),
      );
      await audit.append(
        entry('c', at: DateTime.utc(2026, 11, 3), outcome: .failed),
      );
    });

    List<String> ids(List<ServerAuditEntry> rows) => [
      for (final r in rows) r.id,
    ];

    test('keyset pages walk older and newer from a cursor', () async {
      final first = await audit.pageRows(limit: 2);
      expect(ids(first), ['c', 'b']);
      final cursor = ActivityCursor(
        createdAtMs: first.last.createdAt.millisecondsSinceEpoch,
        id: first.last.id,
      );
      expect(ids(await audit.pageRows(olderThan: cursor, limit: 2)), ['a']);
      expect(ids(await audit.newerRows(newerThan: cursor, limit: 5)), ['c']);
      expect(await audit.count(newerThan: cursor), 1);
    });

    test('actors, outcomes, text and time all narrow the rows', () async {
      Future<List<String>> where(AuditLogFilter f) async =>
          ids(await audit.pageRows(limit: 10, filter: f));

      expect(await where(const AuditLogFilter(actorIds: {'u-2'})), ['b']);
      expect(await where(const AuditLogFilter(outcomes: {AuditOutcome.ok})), [
        'a',
      ]);
      expect(await where(const AuditLogFilter(query: 'SSO')), ['b']);
      expect(await where(const AuditLogFilter(query: 'mode')), ['c', 'b', 'a']);
      expect(
        await where(const AuditLogFilter(searchUserIds: {'u-2'}, query: 'zz')),
        ['b'],
      );
      final nov2 = DateTime.utc(2026, 11, 2);
      expect(
        await where(
          AuditLogFilter(
            time: [AuditTimeCondition(op: .atOrAfter, at: nov2)],
          ),
        ),
        ['c', 'b'],
      );
      expect(
        await where(
          AuditLogFilter(
            time: [AuditTimeCondition(op: .after, at: nov2)],
          ),
        ),
        ['c'],
      );
      expect(
        await where(
          AuditLogFilter(
            time: [AuditTimeCondition(op: .before, at: nov2)],
          ),
        ),
        ['a'],
      );
      expect(
        await where(
          AuditLogFilter(
            time: [AuditTimeCondition(op: .atOrBefore, at: nov2)],
          ),
        ),
        ['b', 'a'],
      );
      // The server trail records no country: a country filter matches none.
      expect(await where(const AuditLogFilter(countryCode: 'FR')), isEmpty);
      expect(await where(const AuditLogFilter(localNetwork: true)), isEmpty);
    });

    test('facets count per actor and per outcome', () async {
      expect(await audit.countByActor(), {'u-1': 2, 'u-2': 1});
      expect(await audit.countByOutcome(), {
        AuditOutcome.ok: 1,
        AuditOutcome.denied: 1,
        AuditOutcome.failed: 1,
      });
      expect(
        await audit.count(filter: const AuditLogFilter(actorIds: {'u-1'})),
        2,
      );
    });

    test('an append wakes the change stream', () async {
      final next = audit.watchChanges().first;
      await audit.append(entry('d'));
      await expectLater(next, completes);
    });
  });
}
