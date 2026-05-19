import 'package:cc_persistence/database/app_database.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('CacheDao - put and read', () {
    test('put and read a cache entry', () async {
      await db.cacheDao.put('ws-1', 'prDetail', '42', '{"title":"PR 42"}');

      final result = await db.cacheDao.read('ws-1', 'prDetail', '42');
      expect(result, '{"title":"PR 42"}');
    });

    test('read returns null for nonexistent entry', () async {
      final result = await db.cacheDao.read('ws-1', 'prDetail', '99');
      expect(result, isNull);
    });

    test('put overwrites existing entry with same key', () async {
      await db.cacheDao.put('ws-1', 'prDetail', '42', 'v1');
      await db.cacheDao.put('ws-1', 'prDetail', '42', 'v2');

      final result = await db.cacheDao.read('ws-1', 'prDetail', '42');
      expect(result, 'v2');
    });

    test('different workspaceId are isolated', () async {
      await db.cacheDao.put('ws-1', 'prDetail', '42', 'ws1-data');
      await db.cacheDao.put('ws-2', 'prDetail', '42', 'ws2-data');

      expect(await db.cacheDao.read('ws-1', 'prDetail', '42'), 'ws1-data');
      expect(await db.cacheDao.read('ws-2', 'prDetail', '42'), 'ws2-data');
    });

    test('different kind are isolated', () async {
      await db.cacheDao.put('ws-1', 'prDetail', '42', 'detail');
      await db.cacheDao.put('ws-1', 'prFiles', '42', 'files');

      expect(await db.cacheDao.read('ws-1', 'prDetail', '42'), 'detail');
      expect(await db.cacheDao.read('ws-1', 'prFiles', '42'), 'files');
    });

    test('different key are isolated', () async {
      await db.cacheDao.put('ws-1', 'prDetail', '42', 'data42');
      await db.cacheDao.put('ws-1', 'prDetail', '99', 'data99');

      expect(await db.cacheDao.read('ws-1', 'prDetail', '42'), 'data42');
      expect(await db.cacheDao.read('ws-1', 'prDetail', '99'), 'data99');
    });
  });

  group('CacheDao - watch', () {
    test('watch emits null when no entry exists', () async {
      final stream = db.cacheDao.watch('ws-1', 'kind', 'key');
      final first = await stream.first;
      expect(first, isNull);
    });

    test('watch emits payload after put', () async {
      await db.cacheDao.put('ws-1', 'kind', 'key', 'hello');
      final stream = db.cacheDao.watch('ws-1', 'kind', 'key');
      final first = await stream.first;
      expect(first, 'hello');
    });

    test('watch emits updated payload after overwrite', () async {
      await db.cacheDao.put('ws-1', 'kind', 'key', 'v1');
      final sub = db.cacheDao.watch('ws-1', 'kind', 'key');
      expect(await sub.first, 'v1');

      await db.cacheDao.put('ws-1', 'kind', 'key', 'v2');
      expect(await sub.first, 'v2');
    });
  });

  group('CacheDao - deleteEntry', () {
    test('deletes a single entry', () async {
      await db.cacheDao.put('ws-1', 'kind', 'key', 'data');
      await db.cacheDao.deleteEntry('ws-1', 'kind', 'key');

      final result = await db.cacheDao.read('ws-1', 'kind', 'key');
      expect(result, isNull);
    });

    test('deleteEntry is no-op when entry does not exist', () async {
      await db.cacheDao.deleteEntry('ws-1', 'kind', 'nonexistent');
      // Should not throw
    });

    test('deleteEntry does not affect other entries', () async {
      await db.cacheDao.put('ws-1', 'kind', 'key1', 'data1');
      await db.cacheDao.put('ws-1', 'kind', 'key2', 'data2');

      await db.cacheDao.deleteEntry('ws-1', 'kind', 'key1');

      expect(await db.cacheDao.read('ws-1', 'kind', 'key1'), isNull);
      expect(await db.cacheDao.read('ws-1', 'kind', 'key2'), 'data2');
    });
  });

  group('CacheDao - deleteKind', () {
    test('deletes all entries for a kind', () async {
      await db.cacheDao.put('ws-1', 'kind', 'key1', 'd1');
      await db.cacheDao.put('ws-1', 'kind', 'key2', 'd2');
      await db.cacheDao.put('ws-1', 'other', 'key1', 'd3');

      await db.cacheDao.deleteKind('ws-1', 'kind');

      expect(await db.cacheDao.read('ws-1', 'kind', 'key1'), isNull);
      expect(await db.cacheDao.read('ws-1', 'kind', 'key2'), isNull);
      expect(await db.cacheDao.read('ws-1', 'other', 'key1'), 'd3');
    });

    test('deleteKind does not affect other workspaces', () async {
      await db.cacheDao.put('ws-1', 'kind', 'key', 'ws1');
      await db.cacheDao.put('ws-2', 'kind', 'key', 'ws2');

      await db.cacheDao.deleteKind('ws-1', 'kind');

      expect(await db.cacheDao.read('ws-1', 'kind', 'key'), isNull);
      expect(await db.cacheDao.read('ws-2', 'kind', 'key'), 'ws2');
    });

    test('deleteKind is no-op when no entries exist', () async {
      await db.cacheDao.deleteKind('ws-1', 'nonexistent');
      // Should not throw
    });
  });

  group('CacheDao - deleteKindWithPrefix', () {
    test('deletes entries whose key starts with prefix', () async {
      await db.cacheDao.put('ws-1', 'kind', 'pr-42-detail', 'detail');
      await db.cacheDao.put('ws-1', 'kind', 'pr-42-files', 'files');
      await db.cacheDao.put('ws-1', 'kind', 'pr-99-detail', 'other');

      await db.cacheDao.deleteKindWithPrefix('ws-1', 'kind', 'pr-42');

      expect(await db.cacheDao.read('ws-1', 'kind', 'pr-42-detail'), isNull);
      expect(await db.cacheDao.read('ws-1', 'kind', 'pr-42-files'), isNull);
      expect(await db.cacheDao.read('ws-1', 'kind', 'pr-99-detail'), 'other');
    });

    test('deleteKindWithPrefix does not match partial prefixes', () async {
      await db.cacheDao.put('ws-1', 'kind', 'pr-4', 'data');

      await db.cacheDao.deleteKindWithPrefix('ws-1', 'kind', 'pr-42');

      expect(await db.cacheDao.read('ws-1', 'kind', 'pr-4'), 'data');
    });

    test('deleteKindWithPrefix is limited to workspace and kind', () async {
      await db.cacheDao.put('ws-1', 'kind1', 'pr-42-x', 'data');
      await db.cacheDao.put('ws-2', 'kind1', 'pr-42-x', 'other');

      await db.cacheDao.deleteKindWithPrefix('ws-1', 'kind1', 'pr-42');

      expect(await db.cacheDao.read('ws-1', 'kind1', 'pr-42-x'), isNull);
      expect(await db.cacheDao.read('ws-2', 'kind1', 'pr-42-x'), 'other');
    });

    test('deleteKindWithPrefix is no-op when no entries match', () async {
      await db.cacheDao.deleteKindWithPrefix('ws-1', 'kind', 'nonexistent');
      // Should not throw
    });
  });

  group('CacheDao - empty and special values', () {
    test('put and read empty payload', () async {
      await db.cacheDao.put('ws-1', 'kind', 'key', '');
      final result = await db.cacheDao.read('ws-1', 'kind', 'key');
      expect(result, '');
    });

    test('put and read payload with special characters', () async {
      const payload = '{"key": "value with / slashes and \\ backslashes"}';
      await db.cacheDao.put('ws-1', 'kind', 'key', payload);
      final result = await db.cacheDao.read('ws-1', 'kind', 'key');
      expect(result, payload);
    });

    test('put and read payload with newlines', () async {
      const payload = 'line1\nline2\nline3';
      await db.cacheDao.put('ws-1', 'kind', 'key', payload);
      final result = await db.cacheDao.read('ws-1', 'kind', 'key');
      expect(result, payload);
    });

    test('put and read long payload', () async {
      final payload = 'x' * 10000;
      await db.cacheDao.put('ws-1', 'kind', 'key', payload);
      final result = await db.cacheDao.read('ws-1', 'kind', 'key');
      expect(result, payload);
    });
  });

  group('CacheDao composite key', () {
    test('primary key constraint prevents duplicates with same composite key',
        () async {
      await db.cacheDao.put('ws-1', 'kind', 'key', 'first');
      await db.cacheDao.put('ws-1', 'kind', 'key', 'second');

      final count = await (db.select(db.cachesTable)
            ..where(
              (t) => t.workspaceId.equals('ws-1') & t.kind.equals('kind') & t
                  .key.equals('key'),
            ))
          .get();
      // Since we use insertOnConflictUpdate, there should be one row
      expect(count, hasLength(1));
    });

    test('updatedAt is set on put', () async {
      final before = DateTime.now();
      await db.cacheDao.put('ws-1', 'kind', 'key', 'data');
      final row = await (db.select(db.cachesTable)
            ..where(
              (t) => t.workspaceId.equals('ws-1') & t.kind.equals('kind') & t
                  .key.equals('key'),
            ))
          .getSingleOrNull();
      expect(row, isNotNull);
      expect(
        row!.updatedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });
}
