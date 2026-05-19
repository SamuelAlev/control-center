import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises [DaoCacheRepository] end-to-end against an in-memory database.
/// The repository is a thin pass-through over [CacheDao]; these tests cover
/// every method and assert workspace isolation is preserved.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoCacheRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    repo = DaoCacheRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  group('DaoCacheRepository read/put round-trip', () {
    test('read returns null when the entry is absent', () async {
      expect(await repo.read('w-1', 'kind', 'key'), isNull);
    });

    test('put then read returns the stored payload', () async {
      await repo.put('w-1', 'kind', 'key', 'payload-1');
      expect(await repo.read('w-1', 'kind', 'key'), 'payload-1');
    });

    test('put upserts (replaces) the payload for the same key', () async {
      await repo.put('w-1', 'kind', 'key', 'first');
      await repo.put('w-1', 'kind', 'key', 'second');
      expect(await repo.read('w-1', 'kind', 'key'), 'second');
    });
  });

  group('DaoCacheRepository workspace isolation', () {
    test('read is scoped by workspace', () async {
      await repo.put('w-1', 'kind', 'key', 'only-in-w-1');
      expect(await repo.read('w-2', 'kind', 'key'), isNull);
    });

    test('the same key in two workspaces does not collide', () async {
      await repo.put('w-1', 'kind', 'key', 'one');
      await repo.put('w-2', 'kind', 'key', 'two');
      expect(await repo.read('w-1', 'kind', 'key'), 'one');
      expect(await repo.read('w-2', 'kind', 'key'), 'two');
    });
  });

  group('DaoCacheRepository deletes', () {
    test('deleteEntry removes a single row', () async {
      await repo.put('w-1', 'kind', 'key-a', 'a');
      await repo.put('w-1', 'kind', 'key-b', 'b');
      await repo.deleteEntry('w-1', 'kind', 'key-a');
      expect(await repo.read('w-1', 'kind', 'key-a'), isNull);
      expect(await repo.read('w-1', 'kind', 'key-b'), 'b');
    });

    test('deleteEntry is workspace-scoped', () async {
      await repo.put('w-1', 'kind', 'key', 'one');
      await repo.deleteEntry('w-2', 'kind', 'key');
      expect(await repo.read('w-1', 'kind', 'key'), 'one');
    });

    test('deleteKind removes every entry of a kind in the workspace', () async {
      await repo.put('w-1', 'kind-a', 'k1', 'v1');
      await repo.put('w-1', 'kind-a', 'k2', 'v2');
      await repo.put('w-1', 'kind-b', 'k1', 'v3');
      await repo.deleteKind('w-1', 'kind-a');
      expect(await repo.read('w-1', 'kind-a', 'k1'), isNull);
      expect(await repo.read('w-1', 'kind-a', 'k2'), isNull);
      expect(await repo.read('w-1', 'kind-b', 'k1'), 'v3');
    });

    test('deleteKind is workspace-scoped', () async {
      await repo.put('w-1', 'kind', 'key', 'one');
      await repo.put('w-2', 'kind', 'key', 'two');
      await repo.deleteKind('w-2', 'kind');
      expect(await repo.read('w-1', 'kind', 'key'), 'one');
      expect(await repo.read('w-2', 'kind', 'key'), isNull);
    });

    test('deleteKindWithPrefix removes only matching keys', () async {
      await repo.put('w-1', 'kind', 'pr-1-msg-1', 'a');
      await repo.put('w-1', 'kind', 'pr-1-msg-2', 'b');
      await repo.put('w-1', 'kind', 'pr-2-msg-1', 'c');
      await repo.deleteKindWithPrefix('w-1', 'kind', 'pr-1-');
      expect(await repo.read('w-1', 'kind', 'pr-1-msg-1'), isNull);
      expect(await repo.read('w-1', 'kind', 'pr-1-msg-2'), isNull);
      expect(await repo.read('w-1', 'kind', 'pr-2-msg-1'), 'c');
    });

    test('deleteKindWithPrefix is workspace-scoped', () async {
      await repo.put('w-1', 'kind', 'prefix-key', 'one');
      await repo.put('w-2', 'kind', 'prefix-key', 'two');
      await repo.deleteKindWithPrefix('w-1', 'kind', 'prefix-');
      expect(await repo.read('w-1', 'kind', 'prefix-key'), isNull);
      expect(await repo.read('w-2', 'kind', 'prefix-key'), 'two');
    });
  });
}
