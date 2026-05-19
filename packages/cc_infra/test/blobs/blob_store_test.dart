import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/blobs/blob_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late BlobStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc_blob_store');
    store = BlobStore(
      workspaceDir: (workspaceId) => p.join(root.path, workspaceId),
    );
  });
  tearDown(() => root.deleteSync(recursive: true));

  Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

  group('put', () {
    test('stores content and returns a canonical reference', () async {
      final stored = await store.put(
        'ws1',
        bytes('screenshot'),
        mediaType: 'image/png',
      );

      expect(stored, isNotNull);
      expect(stored!.ref, startsWith('blob:sha256:'));
      expect(stored.hash.length, 64);
      expect(stored.bytes, 10);
      expect(stored.mediaType, 'image/png');
      expect(await store.read('ws1', stored.hash), bytes('screenshot'));
    });

    test('is idempotent at the content level', () async {
      final a = await store.put('ws1', bytes('same'));
      final b = await store.put('ws1', bytes('same'));

      expect(a!.hash, b!.hash);
      final files = Directory(store.directoryFor('ws1'))
          .listSync()
          .whereType<File>()
          .where((f) => !f.path.endsWith('.type'))
          .toList();
      expect(files, hasLength(1), reason: 'identical bytes are one file');
    });

    test('refuses an empty payload', () async {
      expect(await store.put('ws1', Uint8List(0)), isNull);
    });

    test('refuses a payload over the cap', () async {
      final small = BlobStore(
        workspaceDir: (ws) => p.join(root.path, ws),
        maxBytes: 8,
      );
      expect(await small.put('ws1', bytes('0123456789')), isNull);
      expect(await small.put('ws1', bytes('01234567')), isNotNull);
    });

    test('leaves no temp file behind', () async {
      await store.put('ws1', bytes('x'));
      final leftovers = Directory(store.directoryFor('ws1'))
          .listSync()
          .where((e) => e.path.endsWith('.tmp'))
          .toList();
      expect(leftovers, isEmpty);
    });
  });

  group('putBase64', () {
    test('decodes and stores', () async {
      final stored = await store.putBase64(
        'ws1',
        base64Encode(utf8.encode('png bytes')),
        mediaType: 'image/jpeg',
      );
      expect(stored, isNotNull);
      expect(await store.read('ws1', stored!.hash), bytes('png bytes'));
      expect(await store.mediaTypeFor('ws1', stored.hash), 'image/jpeg');
    });

    test('returns null for malformed base64 rather than throwing', () async {
      // A provider returning junk must cost the preview, not the tool call.
      expect(await store.putBase64('ws1', 'not base64 !!!'), isNull);
    });
  });

  group('workspace isolation', () {
    test('the same bytes in two workspaces are two files', () async {
      final a = await store.put('ws1', bytes('shared'));
      final b = await store.put('ws2', bytes('shared'));

      expect(a!.hash, b!.hash, reason: 'content addressing is global');
      expect(
        store.fileFor('ws1', a.hash)!.path,
        isNot(store.fileFor('ws2', b.hash)!.path),
        reason: 'but storage is per workspace, so a delete cannot cross over',
      );
    });

    test('a blob is not readable from another workspace', () async {
      final stored = await store.put('ws1', bytes('secret screenshot'));
      expect(await store.read('ws2', stored!.hash), isNull);
      expect(store.fileFor('ws2', stored.hash), isNull);
    });

    test('blobs live inside the workspace directory', () async {
      final stored = await store.put('ws1', bytes('x'));
      expect(
        store.fileFor('ws1', stored!.hash)!.path,
        startsWith(p.join(root.path, 'ws1')),
        reason: 'so deleting the workspace deletes its screenshots',
      );
    });
  });

  group('path safety', () {
    test('a non-hex hash never becomes a path', () {
      // The hash is a filename, so this is the traversal guard.
      expect(store.pathFor('ws1', '../../etc/passwd'), isNull);
      expect(store.pathFor('ws1', 'a' * 63), isNull);
      expect(store.pathFor('ws1', 'A' * 64), isNull, reason: 'lowercase only');
      expect(store.pathFor('ws1', 'g' * 64), isNull, reason: 'hex only');
      expect(store.pathFor('ws1', 'a' * 64), isNotNull);
    });

    test('blobHashOf rejects anything that is not a clean reference', () {
      expect(blobHashOf('blob:sha256:${'a' * 64}'), 'a' * 64);
      expect(blobHashOf('blob:sha256:../x'), isNull);
      expect(blobHashOf('https://example.test/x.png'), isNull);
      expect(blobHashOf(null), isNull);
    });

    test('fileFor and read are null for an unknown hash', () async {
      expect(store.fileFor('ws1', 'b' * 64), isNull);
      expect(await store.read('ws1', 'b' * 64), isNull);
    });
  });

  group('media type', () {
    test('defaults to image/png when the sidecar is missing', () async {
      final stored = await store.put('ws1', bytes('x'), mediaType: 'image/gif');
      File('${store.pathFor('ws1', stored!.hash)}.type').deleteSync();
      expect(await store.mediaTypeFor('ws1', stored.hash), 'image/png');
    });
  });

  group('eviction', () {
    test('sizeOf reports only blob bytes, not sidecars', () async {
      await store.put('ws1', bytes('12345'));
      expect(store.sizeOf('ws1'), 5);
      expect(store.sizeOf('never-used'), 0);
    });

    test('evicts oldest-first down to the budget', () async {
      final first = await store.put('ws1', bytes('aaaaaaaaaa'));
      // Distinct mtimes so "oldest" is unambiguous on a coarse-grained fs.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final second = await store.put('ws1', bytes('bbbbbbbbbb'));

      final reclaimed = await store.evictTo('ws1', 10);
      expect(reclaimed, 10);
      expect(store.fileFor('ws1', first!.hash), isNull);
      expect(store.fileFor('ws1', second!.hash), isNotNull);
      expect(
        File('${store.pathFor('ws1', first.hash)}.type').existsSync(),
        isFalse,
        reason: 'the sidecar goes with its blob',
      );
    });

    test('evicts nothing when already under budget', () async {
      await store.put('ws1', bytes('small'));
      expect(await store.evictTo('ws1', 1000), 0);
    });

    test('an absent workspace directory is not an error', () async {
      expect(await store.evictTo('never-used', 0), 0);
    });
  });
}
