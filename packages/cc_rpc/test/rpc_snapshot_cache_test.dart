import 'dart:async';
import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

void main() {
  test('bounds count and bytes, retaining recently read entries', () async {
    final cache = RpcSnapshotCache(maxEntries: 2, maxBytes: 42);
    cache.write('one', {'n': 1});
    cache.write('two', {'n': 2});
    expect(cache.read('one'), {'n': 1});
    cache.write('three', {'n': 3});
    expect(cache.read('two'), isNull);
    expect(cache.read('one'), {'n': 1});
    expect(cache.read('three'), {'n': 3});
    cache.write('too-large', {'data': List.filled(100, 'x').join()});
    expect(cache.read('too-large'), isNull);
    expect(cache.read('one'), {'n': 1});
  });

  test('persists empty maps and detached nested JSON values', () async {
    final store = _Store();
    final cache = RpcSnapshotCache(store: store);
    final original = <String, dynamic>{
      'rows': <dynamic>[
        <String, dynamic>{'n': 1},
      ],
    };
    cache.write('rows', original);
    (original['rows'] as List).clear();
    cache.write('empty', {});
    await cache.flush();

    final restored = RpcSnapshotCache(store: store);
    await restored.hydrate();
    expect(restored.read('rows'), {
      'rows': [
        {'n': 1},
      ],
    });
    (restored.read('rows')!['rows'] as List).clear();
    expect(restored.read('rows'), {
      'rows': [
        {'n': 1},
      ],
    });
    expect(restored.read('empty'), <String, dynamic>{});
  });

  test(
    'late hydration cannot resurrect removals or overwrite fresh values',
    () async {
      final store = _Store();
      store.payload = jsonEncode({
        'version': 1,
        'entries': [
          {
            'key': 'changed',
            'value': {'n': 1},
          },
          {
            'key': 'removed',
            'value': {'n': 1},
          },
          {
            'key': 'untouched',
            'value': {'n': 1},
          },
        ],
      });
      store.blockLoad = Completer<void>();
      final cache = RpcSnapshotCache(store: store);
      final hydration = cache.hydrate();
      cache.write('changed', {'n': 2});
      cache.remove('removed');
      final flushing = cache.flush();
      store.blockLoad!.complete();
      await hydration;
      await flushing;
      expect(cache.read('changed'), {'n': 2});
      expect(cache.read('removed'), isNull);
      expect(cache.read('untouched'), {'n': 1});
      final restored = RpcSnapshotCache(store: store);
      await restored.hydrate();
      expect(restored.read('changed'), {'n': 2});
      expect(restored.read('removed'), isNull);
      expect(restored.read('untouched'), {'n': 1});
    },
  );

  test(
    'clear during hydration keeps old entries out of memory and storage',
    () async {
      final store = _Store()
        ..payload = jsonEncode({
          'version': 1,
          'entries': [
            {
              'key': 'old',
              'value': {'n': 1},
            },
          ],
        });
      store.blockLoad = Completer<void>();
      final cache = RpcSnapshotCache(store: store);
      final hydration = cache.hydrate();
      cache.clear();
      final flushing = cache.flush();
      store.blockLoad!.complete();
      await hydration;
      await flushing;
      expect(cache.read('old'), isNull);
      final restored = RpcSnapshotCache(store: store);
      await restored.hydrate();
      expect(restored.read('old'), isNull);
    },
  );

  test(
    'malformed entries and failed storage do not prevent live snapshots',
    () async {
      final store = _Store()
        ..payload = jsonEncode({
          'version': 1,
          'entries': [
            {'key': 'bad', 'value': 'not a map'},
            {'key': 'valid', 'value': <String, dynamic>{}},
          ],
        });
      final cache = RpcSnapshotCache(store: store);
      await cache.hydrate();
      expect(cache.read('bad'), isNull);
      expect(cache.read('valid'), <String, dynamic>{});
      store.failSave = true;
      cache.write('live', {'n': 3});
      await cache.flush();
      expect(cache.read('live'), {'n': 3});
      cache.remove('live');
      expect(cache.read('live'), isNull);
      store.failSave = false;
      await cache.flush();
    },
  );

  test(
    'fresh workspace membership removes revoked rows, retaining safe global rows',
    () async {
      final store = _Store();
      final cache = RpcSnapshotCache(store: store);
      String key(String query, String? workspace) => jsonEncode([
        'sub',
        query,
        {'workspace_id': workspace},
      ]);
      final allowed = key('meeting.watchByWorkspace', 'ws-allowed');
      final revoked = key('meeting.watchByWorkspace', 'ws-revoked');
      final global = key('workspace.watchAll', 'ws-allowed');
      cache.write(allowed, {
        'meetings': [1],
      });
      cache.write(global, {
        'workspaces': [
          {'id': 'ws-allowed'},
          {'id': 'ws-revoked'},
        ],
      });
      cache.write(revoked, {
        'meetings': [2],
      });
      cache.retainWorkspaces({'ws-allowed'});
      await cache.flush();
      final restored = RpcSnapshotCache(store: store);
      await restored.hydrate();
      expect(restored.read(allowed), {
        'meetings': [1],
      });
      expect(restored.read(revoked), isNull);
      expect(restored.read(global), {
        'workspaces': [
          {'id': 'ws-allowed'},
        ],
      });
    },
  );

  test('workspace denial evicts its inactive screens and global views', () {
    final cache = RpcSnapshotCache();
    String key(String query, String workspace) => jsonEncode([
      'sub',
      query,
      {'workspace_id': workspace},
    ]);
    final denied = key('calendar.watchAccounts', 'ws-revoked');
    final otherScreen = key('meeting.watchByWorkspace', 'ws-revoked');
    final retained = key('meeting.watchByWorkspace', 'ws-allowed');
    final global = key('workspace.watchAll', 'ws-allowed');
    cache.write(denied, {
      'accounts': [1],
    });
    cache.write(otherScreen, {
      'meetings': [1],
    });
    cache.write(retained, {
      'meetings': [2],
    });
    cache.write(global, {
      'workspaces': [1, 2],
    });
    cache.evictWorkspace('ws-revoked');
    expect(cache.read(denied), isNull);
    expect(cache.read(otherScreen), isNull);
    expect(cache.read(global), isNull);
    expect(cache.read(retained), {
      'meetings': [2],
    });
  });
}

class _Store implements RpcSnapshotStore {
  String? payload;
  Completer<void>? blockLoad;
  bool failSave = false;

  @override
  Future<String?> load() async {
    final value = payload;
    if (blockLoad != null) {
      await blockLoad!.future;
    }
    return value;
  }

  @override
  Future<void> save(String value) async {
    if (failSave) {
      throw StateError('disk full');
    }
    payload = value;
  }
}
