import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_domain/core/domain/value_objects/editor_layout_cache_kinds.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/editor_layout_cache_ops.dart';
import 'package:test/test.dart';

class _MemoryCache implements CacheRepository {
  final rows = <(String, String, String), String>{};

  @override
  Future<String?> read(String workspaceId, String kind, String key) async =>
      rows[(workspaceId, kind, key)];

  @override
  Future<void> put(
    String workspaceId,
    String kind,
    String key,
    String payload,
  ) async => rows[(workspaceId, kind, key)] = payload;

  @override
  Future<void> deleteEntry(String workspaceId, String kind, String key) async =>
      rows.remove((workspaceId, kind, key));

  @override
  Future<void> deleteKind(String workspaceId, String kind) async =>
      rows.removeWhere((k, _) => k.$1 == workspaceId && k.$2 == kind);

  @override
  Future<void> deleteKindWithPrefix(
    String workspaceId,
    String kind,
    String keyPrefix,
  ) async => rows.removeWhere(
    (k, _) => k.$1 == workspaceId && k.$2 == kind && k.$3.startsWith(keyPrefix),
  );
}

void main() {
  late _MemoryCache cache;
  late Map<String, RepoOp> ops;

  setUp(() {
    cache = _MemoryCache();
    ops = {for (final op in buildEditorLayoutCacheOps(cache)) op.name: op};
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

  test('a layout is the writer\'s own, on every device', () async {
    await write('alice', 'space-1', 'alice-layout');
    await write('bob', 'space-1', 'bob-layout');

    expect(await read('alice', 'space-1'), 'alice-layout');
    expect(await read('bob', 'space-1'), 'bob-layout');
    expect(
      cache.rows.keys.map((k) => k.$3),
      everyElement(startsWith('user:')),
      reason: 'no write may land on the shared, unowned key',
    );
  });

  test('a layout never crosses workspaces', () async {
    await write('alice', 'space-1', 'ws-1-layout');

    expect(await read('alice', 'space-1', workspaceId: 'ws-2'), isNull);
  });

  test('a shared layout from before per-person rows seeds a first read, '
      'then the person\'s own write wins', () async {
    cache.rows[('ws-1', EditorLayoutCacheKinds.space, 'space-1')] = 'legacy';

    expect(await read('alice', 'space-1'), 'legacy');
    await write('alice', 'space-1', 'alice-layout');
    expect(await read('alice', 'space-1'), 'alice-layout');
    expect(await read('bob', 'space-1'), 'legacy');
    expect(
      cache.rows[('ws-1', EditorLayoutCacheKinds.space, 'space-1')],
      'legacy',
    );
  });

  test('a key naming an owner is refused, so the fallback cannot read '
      'another person\'s row', () async {
    await write('alice', 'space-1', 'alice-layout');

    expect(
      () => read('mallory', editorLayoutOwnerKey('alice', 'space-1')),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => write('mallory', editorLayoutOwnerKey('alice', 'space-1'), 'x'),
      throwsA(isA<ValidationException>()),
    );
  });

  test('server-owned cache kinds are unreachable', () async {
    cache.rows[('ws-1', 'approval_routing', 'policy')] = '{"secret":true}';

    expect(
      () => call('cache.read', 'alice', {
        'kind': 'approval_routing',
        'key': 'policy',
      }),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => call('cache.write', 'alice', {
        'kind': 'approval_routing',
        'key': 'policy',
        'payload': '{}',
      }),
      throwsA(isA<ValidationException>()),
    );
    expect(
      cache.rows[('ws-1', 'approval_routing', 'policy')],
      '{"secret":true}',
    );
  });

  test('every client layout kind is reachable', () async {
    for (final kind in EditorLayoutCacheKinds.all) {
      await call('cache.write', 'alice', {
        'kind': kind,
        'key': 'k',
        'payload': kind,
      });
      final result = await call('cache.read', 'alice', {
        'kind': kind,
        'key': 'k',
      });
      expect(result['payload'], kind);
    }
  });
}
