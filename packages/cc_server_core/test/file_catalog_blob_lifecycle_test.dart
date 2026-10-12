import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/blobs/blob_store.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late GlobalDatabase global;
  late WorkspaceDatabaseManager databases;
  late DaoFileCatalogRepository catalog;
  late BlobStore blobs;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('file-catalog-lifecycle-');
    global = GlobalDatabase.forTesting(NativeDatabase.memory());
    databases = WorkspaceDatabaseManager(
      dataDir: root.path,
      global: global,
      executorFactory: (_) => NativeDatabase.memory(),
    );
    catalog = DaoFileCatalogRepository(databases);
    blobs = BlobStore(
      workspaceDir: (ws) => p.join(root.path, ws),
      onArtifactStored: (ws, blob, creatorId) async {
        await catalog.recordArtifact(
          workspaceId: ws,
          name: 'screen.png',
          path: blob.ref,
          mediaType: blob.mediaType,
          bytes: blob.bytes,
          creatorId: creatorId,
        );
      },
      isProtectedHash: (ws, hash) => catalog.hasPath(ws, 'blob:sha256:$hash'),
    );
  });
  tearDown(() async {
    await databases.closeAll();
    await global.close();
    await root.delete(recursive: true);
  });

  Future<CatalogFileReceipt> upload(
    String workspaceId,
    String userId,
    String label,
    Uint8List bytes,
  ) async {
    final receipt = await blobs.putUpload(
      workspaceId,
      bytes,
      mediaType: 'image/png',
      register: (blob, ownedBytes) async {
        final file = await catalog.createUpload(
          workspaceId: workspaceId,
          uploaderUserId: userId,
          name: label,
          path: blob.ref,
          mediaType: blob.mediaType,
          bytes: blob.bytes,
          ownedBytes: ownedBytes,
        );
        return CatalogFileReceipt(file.id, blob.hash, blob.ref);
      },
    );
    return receipt!;
  }

  Future<void> discard(
    String workspaceId,
    String userId,
    CatalogFileReceipt receipt,
  ) => blobs.withHashLock(workspaceId, receipt.hash, () async {
    await catalog.discard(workspaceId, userId, receipt.id);
    if (await catalog.canReclaim(workspaceId, receipt.ref)) {
      await blobs.deleteHash(workspaceId, receipt.hash);
    }
  });

  test(
    'upload completion has draft row and only its own workspace bytes',
    () async {
      final content = Uint8List.fromList([1, 2, 3]);
      final file = await upload('ws1', 'alice', 'first.png', content);
      expect((await catalog.byId('ws1', file.id))!.name, 'first.png');
      expect(await catalog.byId('ws2', file.id), isNull);
      expect(await blobs.read('ws1', file.hash), content);
      expect(await blobs.read('ws2', file.hash), isNull);
    },
  );

  test('discard leaves shared hash until final draft is removed', () async {
    final content = Uint8List.fromList([1, 2, 3]);
    final first = await upload('ws', 'alice', 'first.png', content);
    final second = await upload('ws', 'alice', 'second.png', content);
    await discard('ws', 'alice', first);
    expect(blobs.fileFor('ws', first.hash), isNotNull);
    await discard('ws', 'alice', second);
    expect(blobs.fileFor('ws', first.hash), isNull);
    await discard('ws', 'alice', second);
  });

  test('attached and generated artifact content cannot be reclaimed', () async {
    final content = Uint8List.fromList([4, 5, 6]);
    final first = await upload('ws', 'alice', 'a.png', content);
    final second = await upload('ws', 'alice', 'b.png', content);
    await catalog.claim('ws', 'alice', [(fileId: first.id, path: first.ref)]);
    await discard('ws', 'alice', second);
    expect(blobs.fileFor('ws', first.hash), isNotNull);
    final screen = await blobs.put(
      'ws',
      Uint8List.fromList([7, 8, 9]),
      creatorId: 'agent-1',
    );
    expect((await catalog.hasPath('ws', screen!.ref)), isTrue);
    final cache = await blobs.put(
      'ws',
      Uint8List.fromList([11, 11]),
      catalogArtifact: false,
    );
    expect(await blobs.evictTo('ws', 0), 2);
    expect(blobs.fileFor('ws', cache!.hash), isNull);
    expect(blobs.fileFor('ws', first.hash), isNotNull);
    expect(blobs.fileFor('ws', screen.hash), isNotNull);
  });

  test(
    'upload deduplicated against pre-catalog content never unlinks legacy bytes',
    () async {
      final content = Uint8List.fromList([12, 13, 14]);
      final old = await blobs.put('ws', content, catalogArtifact: false);
      final draft = await upload('ws', 'alice', 'same.png', content);
      expect((await catalog.byId('ws', draft.id))!.ownedBytes, isFalse);
      await discard('ws', 'alice', draft);
      expect(blobs.fileFor('ws', old!.hash), isNotNull);
    },
  );
}

class CatalogFileReceipt {
  const CatalogFileReceipt(this.id, this.hash, this.ref);
  final String id;
  final String hash;
  final String ref;
}
