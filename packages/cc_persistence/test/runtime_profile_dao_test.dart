import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed({
    required String id,
    required String ws,
    required String name,
    String command = 'claude',
  }) => db.runtimeProfileDao.upsert(
    RuntimeProfilesTableCompanion.insert(
      id: id,
      workspaceId: ws,
      name: name,
      command: command,
    ),
  );

  group('RuntimeProfileDao workspace isolation', () {
    test('getByWorkspace returns only the workspace rows', () async {
      await seed(id: 'rp-1', ws: 'w-1', name: 'alpha');
      await seed(id: 'rp-2', ws: 'w-2', name: 'beta');

      final rows = await db.runtimeProfileDao.getByWorkspace('w-1');
      expect(rows, hasLength(1));
      expect(rows.first.id, 'rp-1');
    });

    test('watchByWorkspace emits sorted + scoped rows', () async {
      await seed(id: 'rp-b', ws: 'w-1', name: 'zulu');
      await seed(id: 'rp-a', ws: 'w-1', name: 'alpha');
      await seed(id: 'rp-c', ws: 'w-2', name: 'other');

      final rows = await db.runtimeProfileDao.watchByWorkspace('w-1').first;
      expect(rows.map((r) => r.name).toList(), ['alpha', 'zulu']);
    });

    test('upsert replaces on conflict (same id PK)', () async {
      await seed(id: 'rp-1', ws: 'w-1', name: 'first');
      await seed(id: 'rp-1', ws: 'w-1', name: 'second', command: 'codex');
      final row = await db.runtimeProfileDao.getById('w-1', 'rp-1');
      expect(row?.name, 'second');
      expect(row?.command, 'codex');
    });

    test('getById is workspace-scoped', () async {
      await seed(id: 'rp-1', ws: 'w-1', name: 'alpha');
      expect(
        (await db.runtimeProfileDao.getById('w-1', 'rp-1'))?.name,
        'alpha',
      );
      expect(await db.runtimeProfileDao.getById('w-2', 'rp-1'), isNull);
      expect(await db.runtimeProfileDao.getById('w-1', 'missing'), isNull);
    });

    test(
      'deleteById is workspace-scoped — foreign workspace is a no-op',
      () async {
        await seed(id: 'rp-1', ws: 'w-1', name: 'alpha');
        expect(await db.runtimeProfileDao.deleteById('w-2', 'rp-1'), 0);
        expect(await db.runtimeProfileDao.getById('w-1', 'rp-1'), isNotNull);

        expect(await db.runtimeProfileDao.deleteById('w-1', 'rp-1'), 1);
        expect(await db.runtimeProfileDao.getById('w-1', 'rp-1'), isNull);
      },
    );
  });
}
