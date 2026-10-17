import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_infra/src/blobs/blob_store.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Noise-authenticated meeting, blob and soundscape resources', () {
    late Directory dataDir;
    late LocalRpcServer server;
    late RemoteRpcClient remote;
    late _Devices devices;
    late DomainEventBus events;
    late HttpClient publicClient;
    late File audio;
    late File blobFile;
    late String psk;
    BlobStore? realBlobStore;
    late String blobMime;
    late String secondPsk;
    late bool workspaceRegistered;
    late bool member;
    late int audioLookups;
    late int blobLookups;
    late int blobWrites;
    late List<int>? uploadedBytes;
    late String? uploadedType;
    late String? uploadedName;
    late String? uploadedUserId;
    late bool uploadCatalogFails;
    late int streamLookups;
    late int playlistLookups;
    late int segmentLookups;
    late Stream<List<int>>? liveAudio;

    const workspace = 'studio';
    const device = 'desktop-a';
    const secondDevice = 'desktop-b';
    const hash =
        'a0b1c2d3e4f5060708090a0b0c0d0e0f102030405060708090a0b0c0d0e0f10';
    const meetingBytes = [0x52, 0x49, 0x46, 0x46, 0, 1, 2, 3, 4, 5];
    const blobBytes = [0x89, 0x50, 0x4e, 0x47, 7, 8, 9, 10];

    String sign(String target) =>
        RemoteControlCrypto.signProxyTarget(target, psk);

    Uri audioUrl({
      String ws = workspace,
      String id = 'meeting-1',
      String? signature,
      String d = device,
    }) => Uri(
      path: '/meeting/audio',
      queryParameters: {
        'w': ws,
        'm': id,
        'd': d,
        's': signature ?? sign('meeting-audio:$ws/$id'),
      },
    );

    Uri blobUrl({
      String ws = workspace,
      String h = hash,
      String? signature,
      String d = device,
      String? downloadName,
    }) => Uri(
      path: '/blob',
      queryParameters: {
        'w': ws,
        'h': h,
        'd': d,
        's': signature ?? sign('blob:$ws:$h'),
        if (downloadName != null) 'download': '1',
        'name': ?downloadName,
      },
    );

    Uri blobPutUrl({String ws = workspace, String? signature}) => Uri(
      path: '/blob',
      queryParameters: {
        'w': ws,
        'd': device,
        's': signature ?? sign('blob-put:$ws'),
      },
    );

    Uri soundUrl(
      String path, {
      String ws = workspace,
      String mood = 'focus',
      String? signature,
      String d = device,
      int? segment,
    }) => Uri(
      path: path,
      queryParameters: {
        'w': ws,
        'mood': mood,
        'd': d,
        's': signature ?? sign('soundscape:$ws/$mood'),
        if (segment != null) 'n': '$segment',
      },
    );

    Future<RemoteResourceResponse> get(Uri uri, {String? range}) =>
        remote.resources.request(
          'GET',
          uri,
          headers: {
            if (range != null) 'range': [range],
          },
        );

    Future<int> status(Uri uri, {String method = 'GET'}) async {
      final response = await remote.resources.request(method, uri);
      await response.body.drain<void>();
      return response.statusCode;
    }

    Future<List<int>> bytes(RemoteResourceResponse response) => response.body
        .fold<List<int>>([], (result, chunk) => result..addAll(chunk));

    setUp(() async {
      dataDir = await Directory.systemTemp.createTemp(
        'sealed-media-resources-',
      );
      addTearDown(() => dataDir.delete(recursive: true));
      audio = File('${dataDir.path}/mixed.wav');
      blobFile = File('${dataDir.path}/image.png');
      await audio.writeAsBytes(meetingBytes);
      await blobFile.writeAsBytes(blobBytes);
      blobMime = 'image/png';
      realBlobStore = null;
      psk = RemoteControlCrypto.generatePsk();
      secondPsk = RemoteControlCrypto.generatePsk();
      devices = _Devices({device: psk, secondDevice: secondPsk});
      addTearDown(devices.close);
      events = DomainEventBus();
      publicClient = HttpClient();
      addTearDown(() => publicClient.close(force: true));
      workspaceRegistered = true;
      member = true;
      audioLookups = 0;
      blobLookups = 0;
      blobWrites = 0;
      uploadedBytes = null;
      uploadedType = null;
      uploadedName = null;
      uploadedUserId = null;
      uploadCatalogFails = false;
      streamLookups = 0;
      playlistLookups = 0;
      segmentLookups = 0;
      liveAudio = null;
      server = LocalRpcServer(
        dispatcher: _Dispatcher(),
        devicesDao: devices,
        secrets: _Secrets({device: psk, secondDevice: secondPsk}),
        identity: await ServerIdentityStore.load(dataDir.path),
        eventBus: events,
        workspaceResolver: (_) async => const [],
        workspaceExists: (ws) async => ws == workspace && workspaceRegistered,
        resolveRole: (ws, user) async =>
            ws == workspace && member && user == 'member-a'
            ? WorkspaceRole.member
            : null,
        meetingAudio:
            ({required String workspaceId, required String meetingId}) async {
              audioLookups++;
              return workspaceId == workspace && meetingId == 'meeting-1'
                  ? audio
                  : null;
            },
        blob: ({required String workspaceId, required String hash}) async {
          blobLookups++;
          final store = realBlobStore;
          if (store != null) {
            final file = store.fileFor(workspaceId, hash);
            return file == null
                ? null
                : (
                    file: file,
                    contentType: await store.mediaTypeFor(workspaceId, hash),
                  );
          }
          return workspaceId == workspace &&
                  hash ==
                      'a0b1c2d3e4f5060708090a0b0c0d0e0f102030405060708090a0b0c0d0e0f10'
              ? (file: blobFile, contentType: blobMime)
              : null;
        },
        blobPut:
            ({
              required String workspaceId,
              required String uploaderUserId,
              required String name,
              required List<int> bytes,
              required String mediaType,
            }) async {
              blobWrites++;
              uploadedBytes = List.of(bytes);
              uploadedType = mediaType;
              uploadedName = name;
              if (uploadCatalogFails) {
                throw StateError('catalog write failed');
              }
              uploadedUserId = uploaderUserId;
              return (
                ref: 'blob:sha256:$hash',
                bytes: bytes.length,
                mediaType: mediaType,
                fileId: 'file-1',
              );
            },
        soundscapeStream:
            ({required String workspaceId, required String mood}) {
              streamLookups++;
              if (workspaceId != workspace || mood != 'focus') {
                return null;
              }
              return liveAudio ??
                  Stream<List<int>>.fromIterable([
                    [0x49, 0x44, 0x33],
                    [4, 5, 6],
                  ]);
            },
        soundscapePlaylist:
            ({
              required String workspaceId,
              required String mood,
              required String segmentQuery,
            }) {
              playlistLookups++;
              if (workspaceId != workspace || mood != 'focus') {
                return null;
              }
              return '#EXTM3U\n#EXTINF:2,\nseg?$segmentQuery&n=7\n';
            },
        soundscapeSegment:
            ({
              required String workspaceId,
              required String mood,
              required int index,
            }) {
              segmentLookups++;
              return workspaceId == workspace && mood == 'focus' && index == 7
                  ? [0x49, 0x44, 0x33, 7]
                  : null;
            },
        mediaCacheDir: '${dataDir.path}/media_cache',
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      addTearDown(server.stop);
      await server.start();
      remote = await connectRemoteRpc(
        uri: Uri.parse('ws://127.0.0.1:${server.boundPort}/rpc'),
        deviceId: device,
        psk: psk,
        insecureAllowed: true,
      );
      addTearDown(() => remote.close());
    });

    test(
      'meeting audio streams full and partial WAV with actual bytes and Range headers',
      () async {
        final full = await get(audioUrl());
        expect(full.statusCode, HttpStatus.ok);
        expect(full.headers['content-type']?.single, startsWith('audio/wav'));
        expect(full.headers['accept-ranges'], contains('bytes'));
        expect(await bytes(full), meetingBytes);

        final partial = await get(audioUrl(), range: 'bytes=2-5');
        expect(partial.statusCode, HttpStatus.partialContent);
        expect(partial.headers['content-range'], contains('bytes 2-5/10'));
        expect(await bytes(partial), meetingBytes.sublist(2, 6));

        final unsatisfiable = await get(audioUrl(), range: 'bytes=100-');
        expect(
          unsatisfiable.statusCode,
          HttpStatus.requestedRangeNotSatisfiable,
        );
        expect(unsatisfiable.headers['content-range'], contains('bytes */10'));
        await unsatisfiable.body.drain<void>();
        expect(audioLookups, 3);
      },
    );

    test(
      'blob streams signed content-addressed bytes with range support',
      () async {
        final full = await get(blobUrl());
        expect(full.statusCode, HttpStatus.ok);
        expect(full.headers['content-type']?.single, startsWith('image/png'));
        expect(await bytes(full), blobBytes);

        final partial = await get(blobUrl(), range: 'bytes=3-6');
        expect(partial.statusCode, HttpStatus.partialContent);
        expect(partial.headers['content-range'], contains('bytes 3-6/8'));
        expect(await bytes(partial), blobBytes.sublist(3, 7));
        expect(blobLookups, 2);
      },
    );

    test(
      'desktop catalog attachment resolves actual PNG over encrypted resource channel',
      () async {
        final global = GlobalDatabase.forTesting(NativeDatabase.memory());
        final databases = WorkspaceDatabaseManager(
          dataDir: dataDir.path,
          global: global,
          executorFactory: (_) => NativeDatabase.memory(),
        );
        addTearDown(() async {
          await databases.closeAll();
          await global.close();
        });
        final catalog = DaoFileCatalogRepository(databases);
        final store = BlobStore(
          workspaceDir: (ws) => p.join(dataDir.path, ws),
          isProtectedHash: (ws, hash) =>
              catalog.hasPath(ws, 'blob:sha256:$hash'),
        );
        realBlobStore = store;
        final png = Uint8List.fromList(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=',
          ),
        );
        final uploaded = await store.putUpload(
          workspace,
          png,
          mediaType: 'image/png',
          register: (blob, ownedBytes) async => catalog.createUpload(
            workspaceId: workspace,
            uploaderUserId: 'member-a',
            name: 'screen.png',
            path: blob.ref,
            mediaType: blob.mediaType,
            bytes: blob.bytes,
            ownedBytes: ownedBytes,
          ),
        );
        expect(uploaded, isNotNull);
        final metadata = {
          'attachments': [
            {
              'id': 'desktop-draft-1',
              'fileId': uploaded!.id,
              'path': uploaded.path,
              'name': uploaded.name,
              'kind': 'image',
              'mediaType': uploaded.mediaType,
              'size': uploaded.bytes,
              'order': 0,
            },
          ],
        };
        final attachment = MessageAttachment.attachmentsFromMetadata(
          metadata,
        ).single;
        expect(attachment.fileId, uploaded.id);
        expect(attachment.isUploaded, isTrue);
        await catalog.claim(workspace, 'member-a', [
          (fileId: attachment.fileId!, path: attachment.path),
        ]);
        final response = await get(blobUrl(h: attachment.blobHash!));
        expect(response.statusCode, HttpStatus.ok);
        expect(
          response.headers['content-type']?.single,
          startsWith('image/png'),
        );
        expect(await bytes(response), png);
        expect(
          await status(blobUrl(ws: 'other', h: attachment.blobHash!)),
          HttpStatus.forbidden,
        );
        expect(await store.read('other', attachment.blobHash!), isNull);
      },
    );

    test('blob download stays scoped and cannot execute SVG inline', () async {
      blobMime = 'image/svg+xml';
      final inline = await get(blobUrl());
      expect(
        inline.headers['content-security-policy']?.single,
        contains('sandbox'),
      );
      expect(inline.headers['x-content-type-options']?.single, 'nosniff');
      expect(inline.headers['content-disposition'], isNull);
      await inline.body.drain<void>();

      final download = await get(
        blobUrl(downloadName: '../drawing\r\nX-Injected: yes.svg'),
      );
      expect(download.statusCode, HttpStatus.ok);
      expect(
        download.headers['content-disposition']?.single,
        "attachment; filename*=UTF-8''drawing__X-Injected%3A%20yes.svg",
      );
      expect(download.headers['x-injected'], isNull);
      expect(await bytes(download), blobBytes);

      expect(
        await status(
          blobUrl(
            downloadName: 'drawing.svg',
            signature: sign('blob:$workspace:wrong'),
          ),
        ),
        HttpStatus.forbidden,
      );
      member = false;
      expect(
        await status(blobUrl(downloadName: 'drawing.svg')),
        HttpStatus.forbidden,
      );
      expect(blobLookups, 2);
    });

    test(
      'blob upload crosses the sealed lane in chunks and needs a distinct write signature',
      () async {
        final payload = List<int>.generate(80 * 1024, (index) => index % 256);
        final upload = await remote.resources.request(
          'POST',
          blobPutUrl(),
          headers: const {
            'content-type': ['image/png'],
            'x-cc-file-name': ['site%20shot.png'],
          },
          body: Stream<List<int>>.fromIterable([
            payload.sublist(0, 32 * 1024),
            payload.sublist(32 * 1024, 64 * 1024),
            payload.sublist(64 * 1024),
          ]),
        );
        expect(upload.statusCode, HttpStatus.ok);
        final receipt =
            jsonDecode(utf8.decode(await bytes(upload)))
                as Map<String, dynamic>;
        expect(receipt['ref'], 'blob:sha256:$hash');
        expect(receipt['bytes'], payload.length);
        expect(receipt['file_id'], 'file-1');
        expect(uploadedName, 'site shot.png');
        expect(uploadedUserId, 'member-a');
        expect(uploadedBytes, payload);
        expect(uploadedType, 'image/png');

        final rejected = await remote.resources.request(
          'POST',
          blobPutUrl(signature: sign('blob:$workspace:$hash')),
          body: Stream<List<int>>.value([1, 2]),
        );
        expect(rejected.statusCode, HttpStatus.forbidden);
        await rejected.body.drain<void>();
        expect(blobWrites, 1);
      },
    );

    test('upload rejects absent or unsafe filename before writing', () async {
      for (final headers in <Map<String, List<String>>>[
        {
          'content-type': ['application/octet-stream'],
        },
        {
          'x-cc-file-name': ['..%2Fprivate.txt'],
        },
        {
          'x-cc-file-name': ['%00bad'],
        },
        {
          'x-cc-file-name': ['%ZZ'],
        },
        {
          'x-cc-file-name': ['%FF'],
        },
      ]) {
        final response = await remote.resources.request(
          'POST',
          blobPutUrl(),
          headers: headers,
          body: Stream<List<int>>.value([1, 2, 3]),
        );
        expect(
          response.statusCode,
          HttpStatus.badRequest,
          reason: 'Filename header: ${headers['x-cc-file-name']}',
        );
        await response.body.drain<void>();
      }
      expect(blobWrites, 0);
    });

    test(
      'upload never returns a receipt when catalog insertion fails',
      () async {
        uploadCatalogFails = true;
        final response = await remote.resources.request(
          'POST',
          blobPutUrl(),
          headers: const {
            'x-cc-file-name': ['failed.png'],
          },
          body: Stream<List<int>>.value([1, 2, 3]),
        );
        expect(response.statusCode, HttpStatus.internalServerError);
        await response.body.drain<void>();
        expect(blobWrites, 1);
      },
    );

    test(
      'soundscape stream, playlist and segment preserve audio payload and signed segment URL',
      () async {
        final stream = await get(soundUrl('/soundscape/stream'));
        expect(stream.statusCode, HttpStatus.ok);
        expect(
          stream.headers['content-type']?.single,
          startsWith('audio/mpeg'),
        );
        expect(stream.headers['cache-control']?.single, 'no-store');
        expect(await bytes(stream), [0x49, 0x44, 0x33, 4, 5, 6]);

        final playlist = await get(soundUrl('/soundscape/playlist.m3u8'));
        expect(playlist.statusCode, HttpStatus.ok);
        expect(
          playlist.headers['content-type']?.single,
          startsWith('application/vnd.apple.mpegurl'),
        );
        final text = utf8.decode(await bytes(playlist));
        expect(text, startsWith('#EXTM3U'));
        final relativeSegment = text
            .split('\n')
            .firstWhere((line) => line.startsWith('seg?'));
        final segmentUri = Uri(
          path: '/soundscape/playlist.m3u8',
        ).resolve(relativeSegment);
        expect(segmentUri.path, '/soundscape/seg');
        expect(
          segmentUri.queryParameters['s'],
          sign('soundscape:$workspace/focus'),
        );
        final segment = await get(segmentUri);
        expect(segment.statusCode, HttpStatus.ok);
        expect(
          segment.headers['content-type']?.single,
          startsWith('audio/mpeg'),
        );
        expect(await bytes(segment), [0x49, 0x44, 0x33, 7]);
        expect(streamLookups, 1);
        expect(playlistLookups, 1);
        expect(segmentLookups, 1);
      },
    );

    test(
      'wrong signed targets fail before lookup; unknown signed IDs are not found',
      () async {
        expect(
          await status(
            audioUrl(signature: sign('meeting-audio:$workspace/another')),
          ),
          HttpStatus.forbidden,
        );
        expect(
          await status(blobUrl(signature: sign('blob:$workspace:another'))),
          HttpStatus.forbidden,
        );
        for (final path in [
          '/soundscape/stream',
          '/soundscape/playlist.m3u8',
          '/soundscape/seg',
        ]) {
          expect(
            await status(
              soundUrl(
                path,
                signature: sign('soundscape:$workspace/sleep'),
                segment: path.endsWith('/seg') ? 7 : null,
              ),
            ),
            HttpStatus.forbidden,
          );
        }
        expect(
          await status(audioUrl(id: 'unknown-meeting')),
          HttpStatus.notFound,
        );
        expect(
          await status(blobUrl(h: List.filled(64, 'f').join())),
          HttpStatus.notFound,
        );
        expect(
          await status(soundUrl('/soundscape/seg', segment: 99)),
          HttpStatus.notFound,
        );
        expect(audioLookups, 1);
        expect(blobLookups, 1);
        expect(streamLookups, 0);
        expect(playlistLookups, 0);
        expect(segmentLookups, 1);
      },
    );

    test(
      'authenticated device cannot replay a different device signed query',
      () async {
        final other = await connectRemoteRpc(
          uri: Uri.parse('ws://127.0.0.1:${server.boundPort}/rpc'),
          deviceId: secondDevice,
          psk: secondPsk,
          insecureAllowed: true,
        );
        try {
          for (final uri in [
            audioUrl(),
            blobUrl(),
            soundUrl('/soundscape/stream'),
            soundUrl('/soundscape/playlist.m3u8'),
            soundUrl('/soundscape/seg', segment: 7),
          ]) {
            final response = await other.resources.request('GET', uri);
            expect(response.statusCode, HttpStatus.forbidden, reason: uri.path);
            await response.body.drain<void>();
          }
          expect(audioLookups, 0);
          expect(blobLookups, 0);
          expect(streamLookups, 0);
          expect(playlistLookups, 0);
          expect(segmentLookups, 0);
        } finally {
          await other.close();
        }
      },
    );

    test(
      'unknown, deleted and unjoined workspace are refused before reading bytes',
      () async {
        for (final uri in [
          audioUrl(ws: 'ghost'),
          blobUrl(ws: 'ghost'),
          soundUrl('/soundscape/stream', ws: 'ghost'),
          soundUrl('/soundscape/playlist.m3u8', ws: 'ghost'),
          soundUrl('/soundscape/seg', ws: 'ghost', segment: 7),
        ]) {
          expect(
            await status(uri),
            HttpStatus.forbidden,
            reason: '${uri.path} unknown workspace',
          );
        }
        expect(
          await status(blobPutUrl(ws: 'ghost'), method: 'POST'),
          HttpStatus.forbidden,
        );
        workspaceRegistered = false;
        for (final uri in [
          audioUrl(),
          blobUrl(),
          soundUrl('/soundscape/stream'),
          soundUrl('/soundscape/playlist.m3u8'),
          soundUrl('/soundscape/seg', segment: 7),
        ]) {
          expect(
            await status(uri),
            HttpStatus.forbidden,
            reason: '${uri.path} deleted workspace',
          );
        }
        expect(
          await status(blobPutUrl(), method: 'POST'),
          HttpStatus.forbidden,
        );
        workspaceRegistered = true;
        member = false;
        for (final uri in [
          audioUrl(),
          blobUrl(),
          soundUrl('/soundscape/stream'),
          soundUrl('/soundscape/playlist.m3u8'),
          soundUrl('/soundscape/seg', segment: 7),
        ]) {
          expect(
            await status(uri),
            HttpStatus.forbidden,
            reason: '${uri.path} nonmember',
          );
        }
        expect(
          await status(blobPutUrl(), method: 'POST'),
          HttpStatus.forbidden,
        );
        expect(audioLookups, 0);
        expect(blobWrites, 0);
        expect(blobLookups, 0);
        expect(streamLookups, 0);
        expect(playlistLookups, 0);
        expect(segmentLookups, 0);
      },
    );

    test('missing workspace is not treated as the current workspace', () async {
      expect(
        await status(
          Uri(
            path: '/meeting/audio',
            queryParameters: {
              'm': 'meeting-1',
              'd': device,
              's': sign('meeting-audio:$workspace/meeting-1'),
            },
          ),
        ),
        HttpStatus.badRequest,
      );
      expect(audioLookups, 0);
    });

    test(
      'sealed slow images stop upstream on session close while shared consumers survive',
      () async {
        // This public-literal URL passes the production SSRF and signature
        // checks unchanged. Only test HttpClients proxy it to this fixture.
        const host = '93.184.216.34';
        final proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final arrivals = StreamController<void>.broadcast();
        final releaseShared = Completer<void>();
        var active = 0;
        var peak = 0;
        var opened = 0;
        proxy.listen((req) async {
          active++;
          opened++;
          if (active > peak) {
            peak = active;
          }
          arrivals.add(null);
          Socket? socket;
          StreamSubscription<List<int>>? incoming;
          try {
            // A real upstream observes TCP close independently of finishing
            // its response. HttpResponse.done alone cannot model that while
            // the Dart HTTP parser is paused behind an open response.
            req.response.headers
              ..contentType = ContentType('image', 'png')
              ..chunkedTransferEncoding = false;
            req.response.persistentConnection = false;
            socket = await req.response.detachSocket();
            final disconnected = Completer<void>();
            void finish() {
              if (!disconnected.isCompleted) {
                disconnected.complete();
              }
            }

            incoming = socket.listen(
              (_) {},
              onDone: finish,
              onError: (Object _) => finish(),
            );
            socket.add(const [0x89, 0x50, 0x4e, 0x47]);
            await socket.flush();
            if (req.uri.path == '/shared.png') {
              await releaseShared.future;
              socket.add(const [1, 2, 3, 4]);
              await socket.flush();
            } else {
              var flushing = false;
              final writer = socket;
              final ticker = Timer.periodic(const Duration(milliseconds: 10), (
                _,
              ) {
                if (flushing) {
                  return;
                }
                flushing = true;
                try {
                  writer.add(const [1]);
                  unawaited(
                    writer.flush().then<void>(
                      (_) => flushing = false,
                      onError: (Object _) {
                        flushing = false;
                        finish();
                      },
                    ),
                  );
                } on Object {
                  flushing = false;
                  finish();
                }
              });
              try {
                await disconnected.future;
              } finally {
                ticker.cancel();
              }
            }
          } on Object {
            // Aborting the outbound HTTP connection is the expected end.
          } finally {
            socket?.destroy();
            await incoming?.cancel();
            active--;
          }
        });
        final overrides = _SlowMediaProxyOverrides(proxy.port, host);
        Future<void> nextArrival(int previous) async {
          if (opened > previous) {
            return;
          }
          await arrivals.stream.first.timeout(const Duration(seconds: 5));
        }

        Uri image(String name, String id, String secret, {int? width}) {
          final url = 'http://$host/$name.png';
          return Uri(
            path: '/proxy/media',
            queryParameters: {
              'u': base64Url.encode(utf8.encode(url)),
              'd': id,
              's': RemoteControlCrypto.signProxyTarget(url, secret),
              if (width != null) 'w': '$width',
            },
          );
        }

        await remote.close();
        await server.stop();
        try {
          await HttpOverrides.runZoned(() async {
            await server.start();
            remote = await connectRemoteRpc(
              uri: Uri.parse('ws://127.0.0.1:${server.boundPort}/rpc'),
              deviceId: device,
              psk: psk,
              insecureAllowed: true,
            );
            final other = await connectRemoteRpc(
              uri: Uri.parse('ws://127.0.0.1:${server.boundPort}/rpc'),
              deviceId: secondDevice,
              psk: secondPsk,
              insecureAllowed: true,
            );
            try {
              final abandoned = remote.resources
                  .request('GET', image('shared', device, psk, width: 128))
                  .then<void>(
                    (response) => response.close(),
                    onError: (Object _) {},
                  );
              await nextArrival(0);
              final shared = other.resources.request(
                'GET',
                image('shared', secondDevice, secondPsk, width: 128),
              );
              await Future<void>.delayed(const Duration(milliseconds: 30));
              await remote.close();
              await abandoned.timeout(const Duration(seconds: 5));
              expect(
                active,
                1,
                reason: 'the other signed consumer needs the fetch',
              );
              expect(opened, 1, reason: 'identical URLs stay single-flight');
              releaseShared.complete();
              final response = await shared.timeout(const Duration(seconds: 5));
              expect(response.statusCode, HttpStatus.ok);
              expect(await bytes(response), const [
                0x89,
                0x50,
                0x4e,
                0x47,
                1,
                2,
                3,
                4,
              ]);
              final sharedDeadline = DateTime.now().add(
                const Duration(seconds: 5),
              );
              while (active != 0 && DateTime.now().isBefore(sharedDeadline)) {
                await Future<void>.delayed(const Duration(milliseconds: 10));
              }
              expect(active, 0);

              for (var i = 0; i < 5; i++) {
                remote = await connectRemoteRpc(
                  uri: Uri.parse('ws://127.0.0.1:${server.boundPort}/rpc'),
                  deviceId: device,
                  psk: psk,
                  insecureAllowed: true,
                );
                final previous = opened;
                final pending = remote.resources
                    .request('GET', image('slow-$i', device, psk))
                    .then<void>(
                      (response) => response.close(),
                      onError: (Object _) {},
                    );
                await nextArrival(previous);
                await remote.close();
                await pending.timeout(const Duration(seconds: 5));
                final deadline = DateTime.now().add(const Duration(seconds: 5));
                while (active != 0 && DateTime.now().isBefore(deadline)) {
                  await Future<void>.delayed(const Duration(milliseconds: 10));
                }
                expect(
                  active,
                  0,
                  reason: 'cancel/reopen must leave no trickling image',
                );
              }
              // Revocation also aborts an image still buffering before HTTP
              // response headers are available to the remote client.
              remote = await connectRemoteRpc(
                uri: Uri.parse('ws://127.0.0.1:${server.boundPort}/rpc'),
                deviceId: device,
                psk: psk,
                insecureAllowed: true,
              );
              final previous = opened;
              final revoked = remote.resources
                  .request('GET', image('revoked', device, psk))
                  .then<void>(
                    (response) => response.close(),
                    onError: (Object _) {},
                  );
              await nextArrival(previous);
              devices.revoke(device);
              await revoked.timeout(const Duration(seconds: 5));
              final revokedDeadline = DateTime.now().add(
                const Duration(seconds: 5),
              );
              while (active != 0 && DateTime.now().isBefore(revokedDeadline)) {
                await Future<void>.delayed(const Duration(milliseconds: 10));
              }
              expect(
                active,
                0,
                reason: 'revocation must close the original upstream socket',
              );
              expect(peak, 1);
            } finally {
              if (!releaseShared.isCompleted) {
                releaseShared.complete();
              }
              await other.close();
              await remote.close();
              await server.stop();
            }
          }, createHttpClient: overrides.createHttpClient);
        } finally {
          await arrivals.close();
          await proxy.close(force: true);
        }
      },
    );

    test(
      'public listener returns 426 for signed GET and POST resource routes',
      () async {
        for (final (method, uri) in [
          ('GET', audioUrl()),
          ('GET', blobUrl()),
          ('POST', blobPutUrl()),
          ('GET', soundUrl('/soundscape/stream')),
          ('GET', soundUrl('/soundscape/playlist.m3u8')),
          ('GET', soundUrl('/soundscape/seg', segment: 7)),
        ]) {
          final request = await publicClient.openUrl(
            method,
            Uri.parse('http://127.0.0.1:${server.boundPort}').resolveUri(uri),
          );
          final response = await request.close();
          expect(
            response.statusCode,
            HttpStatus.upgradeRequired,
            reason: '$method ${uri.path}',
          );
          await response.drain<void>();
        }
        expect(audioLookups, 0);
        expect(blobLookups, 0);
        expect(streamLookups, 0);
      },
    );

    test(
      'membership removal cancels live soundscape and denies new resource requests',
      () async {
        final listened = Completer<void>();
        final cancelled = Completer<void>();
        final source = StreamController<List<int>>(
          onListen: listened.complete,
          onCancel: cancelled.complete,
        );
        liveAudio = source.stream;
        addTearDown(source.close);
        final open = get(soundUrl('/soundscape/stream'));
        // The server's addStream subscribes before the first HTTP headers flush.
        await listened.future.timeout(const Duration(seconds: 5));
        source.add([0x49, 0x44, 0x33]);
        final response = await open;
        expect(response.statusCode, HttpStatus.ok);
        final first = Completer<List<int>>();
        final ended = Completer<void>();
        final subscription = response.body.listen(
          (chunk) {
            if (!first.isCompleted) {
              first.complete(chunk);
            }
          },
          onError: (Object error) {
            if (!first.isCompleted) {
              first.completeError(error);
            }
            if (!ended.isCompleted) {
              ended.complete();
            }
          },
          onDone: () {
            if (!ended.isCompleted) {
              ended.complete();
            }
          },
        );
        expect(await first.future.timeout(const Duration(seconds: 5)), [
          0x49,
          0x44,
          0x33,
        ]);
        member = false;
        events.publish(
          WorkspaceMemberRemoved(
            workspaceId: workspace,
            userId: 'member-a',
            occurredAt: DateTime.now(),
          ),
        );
        await cancelled.future.timeout(const Duration(seconds: 5));
        await ended.future.timeout(const Duration(seconds: 5));
        await subscription.cancel();
        expect(await status(blobUrl()), HttpStatus.forbidden);
        expect(blobLookups, 0);
      },
    );

    test('device revocation terminates an active soundscape stream', () async {
      final listened = Completer<void>();
      final cancelled = Completer<void>();
      final source = StreamController<List<int>>(
        onListen: listened.complete,
        onCancel: cancelled.complete,
      );
      liveAudio = source.stream;
      addTearDown(source.close);
      final open = get(soundUrl('/soundscape/stream'));
      await listened.future.timeout(const Duration(seconds: 5));
      source.add([0x49, 0x44, 0x33]);
      final response = await open;
      expect(response.statusCode, HttpStatus.ok);
      final first = Completer<void>();
      final ended = Completer<void>();
      final subscription = response.body.listen(
        (_) {
          if (!first.isCompleted) {
            first.complete();
          }
        },
        onError: (Object error) {
          if (!first.isCompleted) {
            first.completeError(error);
          }
          if (!ended.isCompleted) {
            ended.complete();
          }
        },
        onDone: () {
          if (!ended.isCompleted) {
            ended.complete();
          }
        },
      );
      await first.future.timeout(const Duration(seconds: 5));
      devices.revoke(device);
      await cancelled.future.timeout(const Duration(seconds: 5));
      await ended.future.timeout(const Duration(seconds: 5));
      await subscription.cancel();
    });
  });
}

class _Dispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      request.id == null
      ? const {}
      : {'jsonrpc': '2.0', 'id': request.id, 'result': <String, dynamic>{}};
}

class _Devices implements PairedDeviceDao {
  _Devices(this.psks);
  final Map<String, String> psks;
  final _changes = StreamController<List<PairedDevicesTableData>>.broadcast();
  final _revoked = <String>{};

  PairedDevicesTableData _row(String id) => PairedDevicesTableData(
    id: id,
    userId: 'member-a',
    label: 'test device',
    platform: 'macos',
    pskRef: 'paired_device_psk_$id',
    status: 'active',
    pairedAt: DateTime.now(),
    lastSeenAt: DateTime.now(),
  );

  @override
  Future<PairedDevicesTableData?> getById(String id) async =>
      psks.containsKey(id) && !_revoked.contains(id) ? _row(id) : null;

  @override
  Stream<List<PairedDevicesTableData>> watchAll() => _changes.stream;

  @override
  Future<int> markSeen(String id, DateTime at) async =>
      psks.containsKey(id) && !_revoked.contains(id) ? 1 : 0;

  void revoke(String id) {
    _revoked.add(id);
    _changes.add([
      for (final id in psks.keys)
        if (!_revoked.contains(id)) _row(id),
    ]);
  }

  @override
  Future<void> close() => _changes.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Secrets implements PairedDeviceSecretsPort {
  _Secrets(this.psks);
  final Map<String, String> psks;

  @override
  Future<String?> readPsk(String deviceId) async => psks[deviceId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Test-only forward proxy for a public IP; never changes SSRF policy.
final class _SlowMediaProxyOverrides extends HttpOverrides {
  _SlowMediaProxyOverrides(this.port, this.host);
  final int port;
  final String host;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) =>
        uri.host == host ? 'PROXY 127.0.0.1:$port' : 'DIRECT';
    return client;
  }
}
