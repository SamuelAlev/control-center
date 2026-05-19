import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/host/editor_layout_codec.dart';
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
}
