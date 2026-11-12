import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/editor_layout_cache_kinds.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/editor_layout_cache_ops.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late Map<String, RepoOp> ops;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    await seedTestWorkspace(global, dbs, 'ws-2');
    ops = {
      for (final op in buildEditorLayoutCacheOps(
        DaoEditorLayoutRepository(dbs),
      ))
        op.name: op,
    };
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Future<Map<String, dynamic>> call(
    String op,
    String userId,
    Map<String, dynamic> args, {
    String workspaceId = 'ws-1',
  }) => ops[op]!.handler(
    RepoOpContext(
      args: args,
      workspaceId: workspaceId,
      deviceId: 'device-$userId',
      userId: userId,
      role: WorkspaceRole.member,
    ),
  );

  Future<String?> read(String userId, String key, {String? workspaceId}) async {
    final result = await call('cache.read', userId, {
      'kind': EditorLayoutCacheKinds.space,
      'key': key,
    }, workspaceId: workspaceId ?? 'ws-1');
    return result['payload'] as String?;
  }

  Future<void> write(
    String userId,
    String key,
    String payload, {
    String? workspaceId,
  }) => call('cache.write', userId, {
    'kind': EditorLayoutCacheKinds.space,
    'key': key,
    'payload': payload,
  }, workspaceId: workspaceId ?? 'ws-1');

  test("a layout is the writer's own, on every device", () async {
    await write('alice', 'space-1', '{"who":"alice"}');
    await write('bob', 'space-1', '{"who":"bob"}');

    expect(await read('alice', 'space-1'), '{"who":"alice"}');
    expect(await read('bob', 'space-1'), '{"who":"bob"}');
  });

  test('a layout never crosses workspaces', () async {
    await write('alice', 'space-1', '{"ws":1}');

    expect(await read('alice', 'space-1', workspaceId: 'ws-2'), isNull);
  });

  test('a layout is stored in editor_layouts, not in the cache', () async {
    await write('alice', 'space-1', '{"ws":1}');

    final db = dbs.of('ws-1');
    final layouts = await db
        .customSelect('SELECT user_id, surface, target FROM editor_layouts')
        .get();
    expect(layouts.single.data, {
      'user_id': 'alice',
      'surface': 'space',
      'target': 'space-1',
    });
    final cached = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM caches WHERE kind = ?',
          variables: [Variable.withString(EditorLayoutCacheKinds.space)],
        )
        .getSingle();
    expect(cached.read<int>('n'), 0);
  });

  test('a payload that is not JSON is refused', () async {
    expect(
      () => write('alice', 'space-1', 'not json'),
      throwsA(isA<ValidationException>()),
    );
  });

  test('any other kind is unreachable', () async {
    expect(
      () => call('cache.read', 'alice', {'kind': 'prDetail', 'key': 'o/r#1'}),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => call('cache.write', 'alice', {
        'kind': 'prDetail',
        'key': 'o/r#1',
        'payload': '{}',
      }),
      throwsA(isA<ValidationException>()),
    );
  });

  test('every client layout kind is reachable', () async {
    for (final kind in EditorLayoutCacheKinds.all) {
      await call('cache.write', 'alice', {
        'kind': kind,
        'key': 'k',
        'payload': '"$kind"',
      });
      final result = await call('cache.read', 'alice', {
        'kind': kind,
        'key': 'k',
      });
      expect(result['payload'], '"$kind"');
    }
  });
}
