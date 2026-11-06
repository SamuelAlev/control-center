import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/host/editor_layout_codec.dart';
import 'package:control_center/shared/editor/host/editor_layout_memo.dart';
import 'package:control_center/shared/editor/host/editor_layout_persistence.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records cache calls; every call throws [readError]/[putError] when set.
class _FakeCache implements CacheRepository {
  Object? readError;
  Object? putError;
  int readCalls = 0;
  int putCalls = 0;
  String? readPayload;

  @override
  Future<String?> read(String workspaceId, String kind, String key) async {
    readCalls++;
    final error = readError;
    if (error != null) {
      throw error;
    }
    return readPayload;
  }

  @override
  Future<void> put(
    String workspaceId,
    String kind,
    String key,
    String payload,
  ) async {
    putCalls++;
    final error = putError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> deleteEntry(String workspaceId, String kind, String key) async {}

  @override
  Future<void> deleteKind(String workspaceId, String kind) async {}

  @override
  Future<void> deleteKindWithPrefix(
    String workspaceId,
    String kind,
    String keyPrefix,
  ) async {}
}

/// Records decode input; encode returns a constant (the payload content is
/// the cache's business, not the persistence wrapper's).
class _RecordingCodec extends EditorLayoutCodec {
  _RecordingCodec() : super(restorableKinds: const {}, iconFor: (_) => null);

  String? lastDecoded;

  @override
  String encode(EditorLayoutController layout) => 'seed-payload';

  @override
  EditorLayoutController? decode(String payload) {
    lastDecoded = payload;
    return null;
  }
}

void main() {
  group('EditorLayoutPersistence transient-failure contract', () {
    test('restore returns null when the read is refused (-32005)', () async {
      final cache = _FakeCache()
        ..readError = RemoteRpcException(
          RpcErrorCodes.rateLimited,
          'Too many concurrent requests — retry shortly',
        );
      final codec = _RecordingCodec();
      final persistence = EditorLayoutPersistence(
        codec: codec,
        cache: cache,
        cacheKind: 'editorLayout',
      );

      final restored = await persistence.restore(
        workspaceId: 'ws1',
        cacheKey: 'space1',
      );

      expect(restored, isNull);
      expect(codec.lastDecoded, isNull, reason: 'a failed read never decodes');
    });

    test(
      'restore returns null when the read times out or the client closed',
      () async {
        for (final error in [
          TimeoutException('RPC repo/call timed out'),
          const RemoteRpcClientClosedException('RPC client closed'),
        ]) {
          final cache = _FakeCache()..readError = error;
          final persistence = EditorLayoutPersistence(
            codec: _RecordingCodec(),
            cache: cache,
            cacheKind: 'editorLayout',
          );
          expect(
            await persistence.restore(workspaceId: 'ws1', cacheKey: 'space1'),
            isNull,
          );
        }
      },
    );

    test('restore decodes a successfully read payload', () async {
      final cache = _FakeCache()..readPayload = 'cached-layout';
      final codec = _RecordingCodec();
      final persistence = EditorLayoutPersistence(
        codec: codec,
        cache: cache,
        cacheKind: 'editorLayout',
      );

      await persistence.restore(workspaceId: 'ws1', cacheKey: 'space1');

      expect(codec.lastDecoded, 'cached-layout');
    });

    test(
      'a refused write is swallowed, not surfaced as an async error',
      () async {
        final cache = _FakeCache()
          ..putError = RemoteRpcException(
            RpcErrorCodes.rateLimited,
            'Too many concurrent requests — retry shortly',
          );
        final persistence = EditorLayoutPersistence(
          codec: _RecordingCodec(),
          cache: cache,
          cacheKind: 'editorLayout',
        );

        // Fire-and-forget: nothing throws here, and the put attempt actually
        // runs (an unhandled async error would fail the test on its own).
        persistence.flushNow(
          workspaceId: 'ws1',
          cacheKey: 'space1',
          layout: EditorLayoutController.single(),
        );
        await pumpEventQueue(times: 10);

        expect(cache.putCalls, 1);
      },
    );
  });

  group('EditorLayoutPersistence memo', () {
    EditorLayoutPersistence withMemo(
      _FakeCache cache,
      EditorLayoutMemo memo, {
      EditorLayoutCodec? codec,
    }) => EditorLayoutPersistence(
      codec: codec ?? _RecordingCodec(),
      cache: cache,
      cacheKind: 'editorLayout',
      memo: memo,
    );

    test('peek is unknown until the layout was read or written', () {
      final persistence = withMemo(_FakeCache(), EditorLayoutMemo());
      expect(persistence.peek(workspaceId: 'ws1', cacheKey: 'space1'), isNull);
    });

    test('a flushed layout peeks back without a read', () {
      final cache = _FakeCache();
      final codec = _RecordingCodec();
      final persistence = withMemo(cache, EditorLayoutMemo(), codec: codec);

      persistence.flushNow(
        workspaceId: 'ws1',
        cacheKey: 'space1',
        layout: EditorLayoutController.single(),
      );
      final warm = persistence.peek(workspaceId: 'ws1', cacheKey: 'space1');

      expect(warm, isNotNull);
      expect(codec.lastDecoded, 'seed-payload');
      expect(cache.readCalls, 0);
    });

    test('a read absence is remembered, so the seed is final', () async {
      final cache = _FakeCache();
      final persistence = withMemo(cache, EditorLayoutMemo());

      await persistence.restore(workspaceId: 'ws1', cacheKey: 'space1');
      final warm = persistence.peek(workspaceId: 'ws1', cacheKey: 'space1');
      await persistence.restore(workspaceId: 'ws1', cacheKey: 'space1');

      expect(warm, isNotNull);
      expect(warm!.layout, isNull);
      expect(cache.readCalls, 1, reason: 'the second restore is the memo');
    });

    test('a failed read stays unknown, so the next open retries', () async {
      final cache = _FakeCache()..readError = TimeoutException('slow');
      final persistence = withMemo(cache, EditorLayoutMemo());

      await persistence.restore(workspaceId: 'ws1', cacheKey: 'space1');

      expect(persistence.peek(workspaceId: 'ws1', cacheKey: 'space1'), isNull);
    });

    test('an unchanged layout is never written back', () async {
      // Another device may have saved since: re-sending the copy this client
      // remembers would replace the person's newer layout.
      final cache = _FakeCache()..readPayload = 'seed-payload';
      final persistence = withMemo(cache, EditorLayoutMemo());

      await persistence.restore(workspaceId: 'ws1', cacheKey: 'space1');
      persistence.flushNow(
        workspaceId: 'ws1',
        cacheKey: 'space1',
        layout: EditorLayoutController.single(),
      );
      await pumpEventQueue();

      expect(cache.putCalls, 0);
    });

    test('a changed layout is written once', () async {
      final cache = _FakeCache()..readPayload = 'server-payload';
      final persistence = withMemo(cache, EditorLayoutMemo());
      await persistence.restore(workspaceId: 'ws1', cacheKey: 'space1');

      for (var i = 0; i < 2; i++) {
        persistence.flushNow(
          workspaceId: 'ws1',
          cacheKey: 'space1',
          layout: EditorLayoutController.single(),
        );
        await pumpEventQueue();
      }

      expect(cache.putCalls, 1);
    });

    test('a failed write is sent again by the next save', () async {
      final cache = _FakeCache()..putError = TimeoutException('slow');
      final persistence = withMemo(cache, EditorLayoutMemo());
      void save() => persistence.flushNow(
        workspaceId: 'ws1',
        cacheKey: 'space1',
        layout: EditorLayoutController.single(),
      );

      save();
      await pumpEventQueue();
      cache.putError = null;
      save();
      await pumpEventQueue();

      expect(cache.putCalls, 2);
    });

    test('fetch sees a save from another device the memo predates', () async {
      final memo = EditorLayoutMemo()
        ..put('ws1', 'editorLayout', 'space1', 'old', synced: true);
      final cache = _FakeCache()..readPayload = 'newer';
      final codec = _RecordingCodec();
      final persistence = withMemo(cache, memo, codec: codec);

      final fetched = await persistence.fetch(
        workspaceId: 'ws1',
        cacheKey: 'space1',
      );

      expect(fetched.failed, isFalse);
      expect(fetched.changed, isTrue);
      expect(codec.lastDecoded, 'newer');
      expect(memo.get('ws1', 'editorLayout', 'space1'), 'newer');
    });

    test('fetch of the copy the memo holds is no change', () async {
      final memo = EditorLayoutMemo()
        ..put('ws1', 'editorLayout', 'space1', 'same', synced: true);
      final persistence = withMemo(_FakeCache()..readPayload = 'same', memo);

      final fetched = await persistence.fetch(
        workspaceId: 'ws1',
        cacheKey: 'space1',
      );

      expect(fetched.changed, isFalse);
    });

    test('a failed fetch is reported and leaves the memo alone', () async {
      final memo = EditorLayoutMemo()
        ..put('ws1', 'editorLayout', 'space1', 'old', synced: true);
      final cache = _FakeCache()..readError = TimeoutException('slow');
      final persistence = withMemo(cache, memo);

      final fetched = await persistence.fetch(
        workspaceId: 'ws1',
        cacheKey: 'space1',
      );

      expect(fetched.failed, isTrue);
      expect(fetched.changed, isFalse);
      expect(memo.get('ws1', 'editorLayout', 'space1'), 'old');
    });

    test(
      'an unconfirmed save is not undone by the older server copy',
      () async {
        // The save failed (or has not landed): the server still answers with
        // what it had, which must not read as a newer save from elsewhere.
        final memo = EditorLayoutMemo();
        final cache = _FakeCache()
          ..putError = TimeoutException('slow')
          ..readPayload = 'older';
        final persistence = withMemo(cache, memo);
        persistence.flushNow(
          workspaceId: 'ws1',
          cacheKey: 'space1',
          layout: EditorLayoutController.single(),
        );
        await pumpEventQueue();

        final fetched = await persistence.fetch(
          workspaceId: 'ws1',
          cacheKey: 'space1',
        );

        expect(fetched.changed, isFalse);
        expect(memo.get('ws1', 'editorLayout', 'space1'), 'seed-payload');
      },
    );

    test('a save while a fetch is in flight wins over its answer', () async {
      final gate = Completer<void>();
      final memo = EditorLayoutMemo();
      final cache = _GatedCache(gate)..readPayload = 'server';
      final persistence = withMemo(cache, memo);

      final read = persistence.fetch(workspaceId: 'ws1', cacheKey: 'space1');
      persistence.flushNow(
        workspaceId: 'ws1',
        cacheKey: 'space1',
        layout: EditorLayoutController.single(),
      );
      gate.complete();
      await read;

      expect(memo.get('ws1', 'editorLayout', 'space1'), 'seed-payload');
    });

    test('entries never cross workspaces', () {
      final memo = EditorLayoutMemo();
      withMemo(_FakeCache(), memo).flushNow(
        workspaceId: 'ws1',
        cacheKey: 'space1',
        layout: EditorLayoutController.single(),
      );
      expect(memo.knows('ws1', 'editorLayout', 'space1'), isTrue);
      expect(memo.knows('ws2', 'editorLayout', 'space1'), isFalse);
    });
  });

  group('EditorLayoutMemo', () {
    test('drops the least recently used entry past capacity', () {
      final memo = EditorLayoutMemo(capacity: 2)
        ..put('ws', 'k', 'a', '1')
        ..put('ws', 'k', 'b', '2');
      // Touch a so b is the oldest.
      expect(memo.get('ws', 'k', 'a'), '1');
      memo.put('ws', 'k', 'c', '3');

      expect(memo.knows('ws', 'k', 'a'), isTrue);
      expect(memo.knows('ws', 'k', 'b'), isFalse);
      expect(memo.knows('ws', 'k', 'c'), isTrue);
    });

    test('prefetch reads once, even when asked twice at once', () async {
      final cache = _FakeCache()..readPayload = 'p';
      final memo = EditorLayoutMemo();

      await Future.wait([
        memo.prefetch(cache, 'ws', 'k', 'a'),
        memo.prefetch(cache, 'ws', 'k', 'a'),
      ]);
      await memo.prefetch(cache, 'ws', 'k', 'a');

      expect(cache.readCalls, 1);
      expect(memo.get('ws', 'k', 'a'), 'p');
    });

    test('a write during a prefetch wins over the read', () async {
      final gate = Completer<void>();
      final cache = _GatedCache(gate)..readPayload = 'server';
      final memo = EditorLayoutMemo();

      final read = memo.prefetch(cache, 'ws', 'k', 'a');
      memo.put('ws', 'k', 'a', 'local');
      gate.complete();
      await read;

      expect(memo.get('ws', 'k', 'a'), 'local');
    });
  });
}

class _GatedCache extends _FakeCache {
  _GatedCache(this._gate);
  final Completer<void> _gate;

  @override
  Future<String?> read(String workspaceId, String kind, String key) async {
    await _gate.future;
    return super.read(workspaceId, kind, key);
  }
}
