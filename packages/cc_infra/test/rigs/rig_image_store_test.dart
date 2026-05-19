import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/src/rigs/rig_image_store.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The image store is the supply chain for everything that runs inside a rig,
/// so what it will and will not install is the part worth pinning.
void main() {
  late Directory dataDir;
  late HttpServer server;
  late List<int> payload;
  late String payloadHash;

  setUp(() async {
    dataDir = await Directory.systemTemp.createTemp('cc-rig-images-');
    // Big enough to clear the "that is not a disk image" floor in importFrom
    // and to exercise the chunked read path.
    // Prefixed with the qcow2 magic (`QFI\xFB`): the import path refuses
    // anything that is not a qcow2, because a tarball or a truncated download
    // becomes `disk.qcow2`, reports `present`, and fails minutes later inside
    // a boot that says nothing more useful than "timeout".
    payload = [
      0x51, 0x46, 0x49, 0xFB,
      ...List<int>.generate(2 * 1024 * 1024 - 4, (i) => i % 251),
    ];
    payloadHash = sha256.convert(payload).toString();

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.uri.path == '/missing') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      if (request.uri.path == '/truncated') {
        // Promises the whole image, delivers a fraction, then drops the
        // connection: the mid-stream failure a long download actually hits.
        // Hand-rolled on the raw socket because HttpResponse will not let a
        // handler close short of the Content-Length it announced.
        final socket = await request.response.detachSocket(writeHeaders: false);
        socket.add(
          utf8.encode(
            'HTTP/1.1 200 OK\r\n'
            'Content-Length: ${payload.length}\r\n'
            '\r\n',
          ),
        );
        socket.add(payload.sublist(0, 64 * 1024));
        await socket.flush();
        socket.destroy();
        return;
      }
      request.response.add(payload);
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    if (dataDir.existsSync()) {
      await dataDir.delete(recursive: true);
    }
  });

  String urlFor(String path) => 'https://127.0.0.1:${server.port}$path';

  RigImageSpec spec({
    String id = 'test-image',
    required String hash,
    String path = '/image.qcow2',
  }) => RigImageSpec(
    id: id,
    surface: RigSurface.computer,
    description: 'test',
    sizeBytes: payload.length,
    artifacts: {
      hostArchitecture: RigImageArtifact(url: urlFor(path), sha256: hash),
    },
  );

  /// The server speaks plain HTTP; the store builds a real [HttpClient], so
  /// the test hands it one that will talk to a loopback listener over http.
  RigImageStore storeFor(List<RigImageSpec> catalog) => RigImageStore(
    dataDir: dataDir.path,
    catalog: catalog,
    httpClientFactory: _PlainHttpClient.new,
  );

  group('download', () {
    test('a matching checksum installs the image', () async {
      final image = spec(hash: payloadHash);
      final store = storeFor([image]);
      expect(store.isPresent(image), isFalse);

      final stages = <String>[];
      await for (final progress in store.download(image)) {
        stages.add(progress.stage);
      }

      expect(stages, contains('verifying'));
      expect(stages.last, 'done');
      expect(store.isPresent(image), isTrue);
      expect(
        File(store.diskPathFor(image)).lengthSync(),
        payload.length,
        reason: 'The installed file must be the bytes that were verified.',
      );
    });

    test('a mismatched checksum is refused and nothing is left behind',
        () async {
      // The whole point of the pin: bytes nobody vouched for never become the
      // root of trust for what runs inside the boundary.
      final image = spec(hash: 'f' * 64);
      final store = storeFor([image]);

      await expectLater(
        store.download(image).drain<void>(),
        throwsA(isA<RigImageException>()),
      );
      expect(store.isPresent(image), isFalse);
      expect(
        File('${store.diskPathFor(image)}.part').existsSync(),
        isFalse,
        reason: 'A rejected download must not leave a partial file behind.',
      );
    });

    test('an unpublished image refuses before touching the network', () async {
      const image = RigImageSpec(
        id: 'unbuilt',
        surface: RigSurface.computer,
        description: 'not built yet',
        sizeBytes: 1,
        artifacts: {},
      );
      final store = storeFor([image]);
      expect(image.isPublished, isFalse);
      await expectLater(
        store.download(image).drain<void>(),
        throwsA(
          isA<RigImageException>().having(
            (e) => e.message,
            'message',
            // The fix is named without referencing any shipped script — the
            // import flow is the whole user-facing story.
            contains('Import a compatible disk image'),
          ),
        ),
      );
    });

    test('an HTTP error is reported, not installed', () async {
      final image = spec(hash: payloadHash, path: '/missing');
      final store = storeFor([image]);
      await expectLater(
        store.download(image).drain<void>(),
        throwsA(isA<RigImageException>()),
      );
      expect(store.isPresent(image), isFalse);
    });

    test('a connection that dies mid-stream leaves neither file behind',
        () async {
      // The atomicity that matters: bytes land in a temp file beside the
      // destination and are renamed into place only after the hash matches, so
      // an interrupted download can never leave something that looks bootable
      // at the path a rig would boot from.
      final image = spec(hash: payloadHash, path: '/truncated');
      final store = storeFor([image]);

      await expectLater(
        store.download(image).drain<void>(),
        throwsA(isA<RigImageException>()),
      );
      expect(File(store.diskPathFor(image)).existsSync(), isFalse);
      expect(
        File('${store.diskPathFor(image)}.part').existsSync(),
        isFalse,
        reason:
            'A surviving .part is reported as download progress, so the next '
            'run looks like it can resume from bytes nobody verified.',
      );
      expect(store.isPresent(image), isFalse);
    });

    test('the verified bytes are the installed bytes', () async {
      final image = spec(hash: payloadHash);
      final store = storeFor([image]);
      await store.download(image).drain<void>();
      expect(
        sha256.convert(File(store.diskPathFor(image)).readAsBytesSync()).toString(),
        payloadHash,
      );
    });
  });

  group('remove', () {
    test('deleting nothing at all is an error, not a success', () async {
      // Cua's lesson: a remove that quietly no-ops makes a typo — a stale id,
      // the wrong store root — indistinguishable from a real deletion, and the
      // operator walks away believing gigabytes were reclaimed.
      final image = spec(hash: payloadHash);
      final store = storeFor([image]);
      expect(store.isPresent(image), isFalse);

      await expectLater(
        store.remove(image),
        throwsA(
          isA<RigImageException>().having(
            (e) => e.message,
            'message',
            contains('Nothing to remove'),
          ),
        ),
      );
    });

    test('an id that is not catalogued is an error', () async {
      final store = storeFor([spec(hash: payloadHash)]);
      await expectLater(
        store.removeById('typo-in-the-id'),
        throwsA(isA<RigImageException>()),
      );
    });

    test('a real removal takes the directory with it', () async {
      final image = spec(hash: payloadHash);
      final store = storeFor([image]);
      await store.download(image).drain<void>();
      expect(store.isPresent(image), isTrue);

      await store.removeById(image.id);

      expect(store.isPresent(image), isFalse);
      expect(Directory(store.directoryFor(image)).existsSync(), isFalse);
    });

    test('a second removal reports that there is nothing left', () async {
      final image = spec(hash: payloadHash);
      final store = storeFor([image]);
      await store.download(image).drain<void>();
      await store.remove(image);
      await expectLater(
        store.remove(image),
        throwsA(isA<RigImageException>()),
      );
    });
  });

  group('import', () {
    test('a local image is copied in and becomes present', () async {
      final image = spec(hash: payloadHash);
      final store = storeFor([image]);
      final source = File(p.join(dataDir.path, 'source.qcow2'))
        ..writeAsBytesSync(payload);

      await store.importFrom(image, source.path).drain<void>();

      expect(store.isPresent(image), isTrue);
      expect(File(store.diskPathFor(image)).lengthSync(), payload.length);
      expect(
        source.existsSync(),
        isTrue,
        reason: 'Importing copies; it must not consume the operator\'s file.',
      );
    });

    test('a missing file is reported', () async {
      final image = spec(hash: payloadHash);
      final store = storeFor([image]);
      await expectLater(
        store.importFrom(image, '/nope/does-not-exist.qcow2').drain<void>(),
        throwsA(isA<RigImageException>()),
      );
    });

    test('something far too small to be a disk image is refused', () async {
      // Catching it here beats a QEMU error three minutes into a first boot.
      final image = spec(hash: payloadHash);
      final store = storeFor([image]);
      final tiny = File(p.join(dataDir.path, 'tiny.qcow2'))
        ..writeAsStringSync('not an image');
      await expectLater(
        store.importFrom(image, tiny.path).drain<void>(),
        throwsA(isA<RigImageException>()),
      );
      expect(store.isPresent(image), isFalse);
    });

    test('an import abandoned part-way leaves no partial file behind',
        () async {
      // The RPC caller going away mid-copy is the ordinary case, and it must
      // not leave a short file at the path a rig would boot from — nor a
      // `.part` that `_sizeOrNull` will later report as progress.
      final image = spec(hash: payloadHash);
      final store = storeFor([image]);
      final big = [
        0x51, 0x46, 0x49, 0xFB,
        ...List<int>.generate(9 * 1024 * 1024 - 4, (i) => i % 251),
      ];
      final source = File(p.join(dataDir.path, 'big.qcow2'))
        ..writeAsBytesSync(big);

      // `take(1)` cancels the subscription after the first progress event,
      // part-way through the copy.
      await store.importFrom(image, source.path).take(1).drain<void>();

      expect(File(store.diskPathFor(image)).existsSync(), isFalse);
      expect(
        File('${store.diskPathFor(image)}.part').existsSync(),
        isFalse,
        reason: 'A half-copied image must not survive an abandoned import.',
      );
      expect(store.isPresent(image), isFalse);
    });

    test('a file that is not a qcow2 is refused', () async {
      // The import path is the PRODUCTION path for the desktop and browser
      // images (their artifacts are not published), so "install whatever the
      // operator named" meant the checksum-pinning invariant did not hold
      // where it is actually used. A tarball of the image, a truncated
      // download or the wrong file entirely otherwise becomes `disk.qcow2`,
      // reports `present`, and fails minutes later inside a boot.
      final image = spec(hash: payloadHash);
      final store = storeFor([image]);
      final notAnImage = File(p.join(dataDir.path, 'archive.qcow2'))
        ..writeAsBytesSync([
          0x1F, 0x8B, 0x08, 0x00, // gzip magic
          ...List<int>.filled(2 * 1024 * 1024, 0x41),
        ]);

      await expectLater(
        store.importFrom(image, notAnImage.path).drain<void>(),
        throwsA(
          isA<RigImageException>().having(
            (e) => e.message,
            'message',
            contains('qcow2'),
          ),
        ),
      );
      expect(store.isPresent(image), isFalse);
    });

    test('a qcow2 whose hash does not match the pin is refused', () async {
      final image = spec(hash: payloadHash);
      final store = storeFor([image]);
      final other = File(p.join(dataDir.path, 'other.qcow2'))
        ..writeAsBytesSync([
          0x51, 0x46, 0x49, 0xFB,
          ...List<int>.generate(2 * 1024 * 1024 - 4, (i) => (i + 7) % 251),
        ]);

      await expectLater(
        store.importFrom(image, other.path).drain<void>(),
        throwsA(
          isA<RigImageException>().having(
            (e) => e.message,
            'message',
            contains('Checksum mismatch'),
          ),
        ),
      );
      expect(store.isPresent(image), isFalse);
      expect(
        File('${store.diskPathFor(image)}.part').existsSync(),
        isFalse,
        reason: 'A rejected import must not leave a partial behind.',
      );
    });

    test('an UNPINNED image still imports (the working path today)', () async {
      // The desktop/browser images have no published artifact, so their spec
      // carries no hash. Refusing those would leave no way to install them at
      // all; the digest is logged instead.
      final image = RigImageSpec(
        id: 'unpinned',
        surface: RigSurface.computer,
        description: 'locally built',
        sizeBytes: payload.length,
        artifacts: const {},
      );
      final store = storeFor([image]);
      final source = File(p.join(dataDir.path, 'local.qcow2'))
        ..writeAsBytesSync(payload);

      await store.importFrom(image, source.path).drain<void>();
      expect(store.isPresent(image), isTrue);
    });
  });

  group('catalogue', () {
    test('every published artifact is pinned to an immutable URL', () {
      // A `.../release/` pointer is republished on each point release, so a
      // hash pinned against it starts failing the moment upstream rebuilds.
      for (final image in kRigImageCatalog) {
        for (final arch in const ['arm64', 'x64']) {
          if (!image.supportsArchitecture(arch)) {
            continue;
          }
          final artifact = image.artifacts[arch]!;
          expect(artifact.url, startsWith('https://'));
          expect(
            artifact.sha256,
            hasLength(64),
            reason: '${image.id}/$arch must carry a full SHA-256.',
          );
          expect(
            artifact.url,
            isNot(contains('/release/')),
            reason:
                '${image.id}/$arch points at a rolling path; pin a versioned '
                'one or the hash goes stale on the next upstream rebuild.',
          );
        }
      }
    });

    test('an image with no artifacts reads as unpublished', () {
      for (final image in kRigImageCatalog) {
        if (image.artifacts.isEmpty) {
          expect(image.isPublished, isFalse);
        }
      }
    });

    test('the default for the computer surface is the desktop image', () {
      final store = RigImageStore(dataDir: dataDir.path);
      expect(store.defaultFor(RigSurface.computer)?.id, 'cc-desktop-linux');
    });
  });
}

/// An [HttpClient] that rewrites the store's https URLs to the loopback http
/// listener, so the download path is exercised without a TLS certificate.
class _PlainHttpClient implements HttpClient {
  _PlainHttpClient() : _inner = HttpClient();

  final HttpClient _inner;

  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      _inner.getUrl(url.replace(scheme: 'http'));

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '${invocation.memberName} is not used by the image store',
  );
}
