import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/database/utils/fts_query_utils.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  group('toFtsOrQuery', () {
    test('keeps letters of every script and quotes each token', () {
      expect(toFtsOrQuery('東京 タワー'), '"東京"* OR "タワー"*');
      expect(toFtsOrQuery('مرحبا بالعالم'), '"مرحبا"* OR "بالعالم"*');
      expect(toFtsOrQuery("what's my name?"), '"name"*');
    });

    test('FTS5 syntax in the input cannot leak into the expression', () {
      final q = toFtsOrQuery('foo" OR NEAR(bar) * baz:qux ^start -x');
      expect(q, '"foo"* OR "near"* OR "bar"* OR "baz"* OR "qux"* OR "start"*');
    });

    test('a one-character word survives outside ASCII only', () {
      expect(toFtsOrQuery('猫'), '"猫"*');
      expect(toFtsOrQuery('x'), '');
    });
  });

  group('workspace-scoped search over a real FTS table', () {
    late WorkspaceDatabase db;

    setUp(() async {
      db = createTestDatabase(workspaceId: 'w-1');
      var n = 0;
      for (final (topic, content) in [
        ('travel', '東京タワーに行きました'),
        ('greeting', 'مرحبا بالعالم'),
        ('hindi', 'हिन्दी भाषा'),
        ('english', 'plain english note'),
      ]) {
        await db.memoryFactDao.upsert(
          MemoryFactsTableCompanion.insert(
            id: 'f-${n++}',
            workspaceId: 'w-1',
            domain: 'test',
            topic: topic,
            content: content,
          ),
        );
      }
    });

    tearDown(() async {
      await db.close();
    });

    Future<List<String>> search(String query) async => [
      for (final row in await db.memoryFactDao.searchFts('w-1', query))
        row.topic,
    ];

    test('a Japanese query matches', () async {
      expect(await search('東京'), ['travel']);
    });

    test('an Arabic query matches', () async {
      expect(await search('مرحبا'), ['greeting']);
    });

    test('a word with combining marks stays whole', () async {
      expect(await search('हिन्दी'), ['hindi']);
    });

    test('operator characters in the query do not break the match', () async {
      expect(await search('english" OR (plain'), ['english']);
    });
  });
}
