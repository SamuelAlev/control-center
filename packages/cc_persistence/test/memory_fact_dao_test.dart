import 'dart:typed_data';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  MemoryFactsTableCompanion fact({
    required String id,
    required String workspaceId,
    String topic = 'deploy',
    String content = 'deployment runbook details',
  }) => MemoryFactsTableCompanion.insert(
    id: id,
    workspaceId: workspaceId,
    domain: 'ops',
    topic: topic,
    content: content,
  );

  setUp(() async {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('MemoryFactDao workspace isolation', () {
    test(
      'searchFts returns only the caller workspace, even when content collides',
      () async {
        // Identical topic + content in two workspaces. The FTS MATCH is scoped
        // to the caller at the index level, and the post-join workspace filter
        // is the authoritative boundary — neither may leak the other workspace.
        await db.memoryFactDao.upsert(fact(id: 'f-1', workspaceId: 'ws-1'));
        await db.memoryFactDao.upsert(fact(id: 'f-2', workspaceId: 'ws-2'));

        final ws1 = await db.memoryFactDao.searchFts('ws-1', 'deployment');
        expect(ws1.map((f) => f.id), ['f-1']);

        final ws2 = await db.memoryFactDao.searchFts('ws-2', 'deployment');
        expect(ws2.map((f) => f.id), ['f-2']);
      },
    );

    test('searchFts excludes superseded facts', () async {
      await db.memoryFactDao.upsert(
        fact(
          id: 'f-1',
          workspaceId: 'ws-1',
        ).copyWith(supersededBy: const Value('f-x')),
      );
      expect(await db.memoryFactDao.searchFts('ws-1', 'deployment'), isEmpty);
    });

    test('getById is scoped to the workspace', () async {
      await db.memoryFactDao.upsert(fact(id: 'f-1', workspaceId: 'ws-1'));
      expect(await db.memoryFactDao.getById('ws-1', 'f-1'), isNotNull);
      // The id is a global UUID, but a foreign workspace must not resolve it.
      expect(await db.memoryFactDao.getById('ws-2', 'f-1'), isNull);
    });

    test('deleteById cannot delete another workspace fact', () async {
      await db.memoryFactDao.upsert(fact(id: 'f-1', workspaceId: 'ws-1'));

      await db.memoryFactDao.deleteById('ws-2', 'f-1'); // wrong workspace
      expect(await db.memoryFactDao.getById('ws-1', 'f-1'), isNotNull);

      await db.memoryFactDao.deleteById('ws-1', 'f-1'); // owning workspace
      expect(await db.memoryFactDao.getById('ws-1', 'f-1'), isNull);
    });

    test(
      'searchFts short-circuits to [] when the query has no usable tokens',
      () async {
        await db.memoryFactDao.upsert(fact(id: 'f-1', workspaceId: 'ws-1'));
        // Pure punctuation/stopwords → empty MATCH → early return (no SQL run).
        expect(await db.memoryFactDao.searchFts('ws-1', '??? the a'), isEmpty);
      },
    );

    test('upsert is an update-in-place on matching id', () async {
      await db.memoryFactDao.upsert(fact(id: 'f-1', workspaceId: 'ws-1'));
      await db.memoryFactDao.upsert(
        fact(id: 'f-1', workspaceId: 'ws-1', content: 'new content'),
      );
      final row = await db.memoryFactDao.getById('ws-1', 'f-1');
      expect(row!.content, 'new content');
    });
  });

  group('MemoryFactDao read methods + isolation', () {
    test('getByWorkspace returns rows newest-first, scoped', () async {
      await db.memoryFactDao.upsert(
        MemoryFactsTableCompanion.insert(
          id: 'older',
          workspaceId: 'ws-1',
          domain: 'ops',
          topic: 't',
          content: 'old',
          updatedAt: Value(DateTime(2026, 1, 1)),
        ),
      );
      await db.memoryFactDao.upsert(
        MemoryFactsTableCompanion.insert(
          id: 'newer',
          workspaceId: 'ws-1',
          domain: 'ops',
          topic: 't',
          content: 'new',
          updatedAt: Value(DateTime(2026, 1, 2)),
        ),
      );
      await db.memoryFactDao.upsert(fact(id: 'other-ws', workspaceId: 'ws-2'));

      final rows = await db.memoryFactDao.getByWorkspace('ws-1');
      expect(rows.map((f) => f.id), ['newer', 'older']);
      // watchByWorkspace returns the same ordering, scoped.
      final watched = await db.memoryFactDao.watchByWorkspace('ws-1').first;
      expect(watched.map((f) => f.id), ['newer', 'older']);
    });

    test('getActiveByTopic returns only active rows for that topic', () async {
      await db.memoryFactDao.upsert(
        MemoryFactsTableCompanion.insert(
          id: 'active',
          workspaceId: 'ws-1',
          domain: 'ops',
          topic: 'deploy',
          content: 'c',
        ),
      );
      await db.memoryFactDao.upsert(
        MemoryFactsTableCompanion.insert(
          id: 'superseded',
          workspaceId: 'ws-1',
          domain: 'ops',
          topic: 'deploy',
          content: 'c',
          supersededBy: const Value('active'),
        ),
      );
      await db.memoryFactDao.upsert(
        MemoryFactsTableCompanion.insert(
          id: 'other-topic',
          workspaceId: 'ws-1',
          domain: 'ops',
          topic: 'other',
          content: 'c',
        ),
      );
      await db.memoryFactDao.upsert(
        MemoryFactsTableCompanion.insert(
          id: 'foreign-ws',
          workspaceId: 'ws-2',
          domain: 'ops',
          topic: 'deploy',
          content: 'c',
        ),
      );

      final rows = await db.memoryFactDao.getActiveByTopic('ws-1', 'deploy');
      expect(rows.map((f) => f.id), ['active']);
    });

    test(
      'watchActiveByWorkspace returns only non-superseded rows, scoped',
      () async {
        await db.memoryFactDao.upsert(fact(id: 'active', workspaceId: 'ws-1'));
        await db.memoryFactDao.upsert(
          fact(
            id: 'gone',
            workspaceId: 'ws-1',
          ).copyWith(supersededBy: const Value('active')),
        );
        await db.memoryFactDao.upsert(
          fact(id: 'other-ws', workspaceId: 'ws-2'),
        );

        final rows = await db.memoryFactDao
            .watchActiveByWorkspace('ws-1')
            .first;
        expect(rows.map((f) => f.id), ['active']);
      },
    );

    test('getByAuthor returns rows by agent id, scoped', () async {
      await db.memoryFactDao.upsert(
        MemoryFactsTableCompanion.insert(
          id: 'a1',
          workspaceId: 'ws-1',
          domain: 'ops',
          topic: 't',
          content: 'c',
          authoredByAgentId: const Value('agent-1'),
        ),
      );
      await db.memoryFactDao.upsert(
        MemoryFactsTableCompanion.insert(
          id: 'a2',
          workspaceId: 'ws-1',
          domain: 'ops',
          topic: 't',
          content: 'c',
          authoredByAgentId: const Value('agent-2'),
        ),
      );
      // Foreign workspace, same agent id — must not surface.
      await db.memoryFactDao.upsert(
        MemoryFactsTableCompanion.insert(
          id: 'foreign',
          workspaceId: 'ws-2',
          domain: 'ops',
          topic: 't',
          content: 'c',
          authoredByAgentId: const Value('agent-1'),
        ),
      );

      final rows = await db.memoryFactDao.getByAuthor('ws-1', 'agent-1');
      expect(rows.map((f) => f.id), ['a1']);
    });

    test('getActiveByWorkspace returns non-superseded rows, scoped', () async {
      await db.memoryFactDao.upsert(fact(id: 'active', workspaceId: 'ws-1'));
      await db.memoryFactDao.upsert(
        fact(
          id: 'gone',
          workspaceId: 'ws-1',
        ).copyWith(supersededBy: const Value('active')),
      );
      await db.memoryFactDao.upsert(fact(id: 'other-ws', workspaceId: 'ws-2'));

      final rows = await db.memoryFactDao.getActiveByWorkspace('ws-1');
      expect(rows.map((f) => f.id), ['active']);
    });

    test(
      'getActiveByIds returns matching active rows, scoped + empty-list noop',
      () async {
        await db.memoryFactDao.upsert(fact(id: 'f-1', workspaceId: 'ws-1'));
        await db.memoryFactDao.upsert(
          fact(
            id: 'f-2',
            workspaceId: 'ws-1',
          ).copyWith(supersededBy: const Value('f-1')),
        );
        await db.memoryFactDao.upsert(fact(id: 'f-3', workspaceId: 'ws-2'));

        // Empty list short-circuits to [].
        expect(
          await db.memoryFactDao.getActiveByIds('ws-1', const []),
          isEmpty,
        );

        final rows = await db.memoryFactDao.getActiveByIds('ws-1', [
          'f-1',
          'f-2',
          'f-3',
        ]);
        // f-1 active + in ws; f-2 superseded; f-3 foreign workspace.
        expect(rows.map((f) => f.id), ['f-1']);
      },
    );

    test(
      'recentActive returns newest-first active rows, limit + scoped',
      () async {
        for (var i = 0; i < 5; i++) {
          await db.memoryFactDao.upsert(
            MemoryFactsTableCompanion.insert(
              id: 'f-$i',
              workspaceId: 'ws-1',
              domain: 'ops',
              topic: 't',
              content: 'c',
              createdAt: Value(DateTime(2026, 1, 1 + i)),
            ),
          );
        }
        // A superseded row should be excluded from the candidate pool.
        await db.memoryFactDao.upsert(
          fact(
            id: 'gone',
            workspaceId: 'ws-1',
          ).copyWith(supersededBy: const Value('f-0')),
        );
        await db.memoryFactDao.upsert(fact(id: 'foreign', workspaceId: 'ws-2'));

        final limited = await db.memoryFactDao.recentActive('ws-1', limit: 3);
        expect(limited.map((f) => f.id), ['f-4', 'f-3', 'f-2']);
        // Default limit surfaces the full active set, newest-first.
        final all = await db.memoryFactDao.recentActive('ws-1');
        expect(all.map((f) => f.id), ['f-4', 'f-3', 'f-2', 'f-1', 'f-0']);
      },
    );

    test(
      'markRecalled bumps recallCount + lastRecalledAt, scoped + empty noop',
      () async {
        await db.memoryFactDao.upsert(fact(id: 'f-1', workspaceId: 'ws-1'));

        // Empty list short-circuits to a no-op.
        await db.memoryFactDao.markRecalled(
          'ws-1',
          const [],
          DateTime(2026, 1, 2),
        );
        expect((await db.memoryFactDao.getById('ws-1', 'f-1'))!.recallCount, 0);

        final at = DateTime.utc(2026, 1, 5, 9);
        await db.memoryFactDao.markRecalled('ws-1', ['f-1'], at);
        final row = await db.memoryFactDao.getById('ws-1', 'f-1');
        expect(row!.recallCount, 1);
        expect(row.lastRecalledAt!.isAtSameMomentAs(at), isTrue);
      },
    );

    test(
      'markRecalled only touches scoped ids (foreign id untouched)',
      () async {
        await db.memoryFactDao.upsert(fact(id: 'f-1', workspaceId: 'ws-1'));
        await db.memoryFactDao.upsert(fact(id: 'f-2', workspaceId: 'ws-2'));

        // Pass both ids under ws-1; ws-2's row must not be bumped.
        await db.memoryFactDao.markRecalled('ws-1', [
          'f-1',
          'f-2',
        ], DateTime(2026, 1, 5));
        expect((await db.memoryFactDao.getById('ws-1', 'f-1'))!.recallCount, 1);
        expect((await db.memoryFactDao.getById('ws-2', 'f-2'))!.recallCount, 0);
      },
    );

    test(
      'searchVector / searchHybrid throw without sqlite_vector, or complete '
      'when a sibling test already loaded it',
      () async {
        await db.memoryFactDao.upsert(fact(id: 'f-1', workspaceId: 'ws-1'));
        // createTestDatabase does not register sqlite_vector, so both paths
        // raise when the extension is absent. `openGlobalDatabase` in
        // server_database_test.dart registers it as a process-global SQLite
        // auto-extension, so a concurrent file in this process can make the
        // functions appear — then the queries complete (typically empty for a
        // 1-d probe against the 384-d index) instead of throwing.
        final query = Float32List.fromList([0.1]);
        try {
          final vector = await db.memoryFactDao.searchVector('ws-1', query);
          expect(vector, isA<List<MemoryFactsTableData>>());
          final hybrid = await db.memoryFactDao.searchHybrid(
            'ws-1',
            'deployment',
            query,
          );
          expect(hybrid, isA<List<MemoryFactsTableData>>());
        } on Exception {
          await expectLater(
            db.memoryFactDao.searchHybrid('ws-1', 'deployment', query),
            throwsA(isA<Exception>()),
          );
        }
      },
    );
  });
}
