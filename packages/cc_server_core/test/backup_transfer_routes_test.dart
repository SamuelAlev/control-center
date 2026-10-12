import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/cc_persistence.dart' show PairedDevicesTableData;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:test/test.dart';

/// The byte half of the backup surface: `/backup/workspace`, `/backup/snapshot`
/// and `POST /backup/restore`.
///
/// `workspace.export` returns a PATH and `workspace.import` takes one, which is
/// a complete answer only when the server is the operator's own machine. These
/// routes carry the bytes instead — so what has to hold is that they carry them
/// only for someone entitled to them, and that they leave nothing behind on the
/// server afterwards.
void main() {
  const deviceId = 'device-a';
  const workspaceId = 'ws-1';
  late String psk;
  const userId = 'user-1';
  const ownerId = 'user-owner';

  late Directory tmp;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('cc_backup_routes_test');
    psk = RemoteControlCrypto.generatePsk();
  });

  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } on Object {
      // Windows holds handles briefly; the OS reclaims the temp dir.
    }
  });

  /// A server with whichever backup hooks the test needs.
  Future<LocalRpcServer> serve({
    BackupExportWriter? export,
    BackupSnapshotArchiver? snapshot,
    BackupRestoreReader? restore,
    WorkspaceRole? role,
    String? owner,
    String? uploadDir,
  }) async {
    final server = LocalRpcServer(
      dispatcher: _StubDispatcher(),
      devicesDao: _StubDevicesDao(deviceId: deviceId, userId: userId),
      secrets: _StubSecrets(psk: psk),
      eventBus: DomainEventBus(),
      workspaceResolver: (user) async => user == userId
          ? const [(id: workspaceId, name: 'Test workspace')]
          : const <({String id, String name})>[],
      workspaceExists: (workspace) async => workspace == workspaceId,
      resolveRole: (workspace, user) async =>
          workspace == workspaceId && user == userId
          ? (role ?? WorkspaceRole.owner)
          : null,
      backupExport: export,
      backupSnapshotArchive: snapshot,
      backupRestore: restore,
      backupUploadDir: uploadDir ?? '${tmp.path}/transfer',
      isServerOwner: (u) async => u == (owner ?? userId),
      identity: await ServerIdentityStore.load(tmp.path),
      address: InternetAddress.loopbackIPv4,
      port: 0,
    );
    addTearDown(server.stop);
    await server.start();
    return server;
  }

  String sign(String target) =>
      RemoteControlCrypto.signProxyTarget(target, psk);

  /// The handler deletes the copy AFTER the response has been handed to the
  /// socket; the client can observe the bytes a tick before the unlink. Poll
  /// rather than asserting on the next line, which lost on Windows (and on
  /// macOS once the download path started closing its handle explicitly).
  Future<void> expectDeleted(File file) async {
    for (var i = 0; i < 50; i++) {
      if (!file.existsSync()) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(file.existsSync(), isFalse, reason: '${file.path} was not removed');
  }

  Future<RemoteResourceResponse> requestResource(
    LocalRpcServer server,
    String method,
    String path, {
    Stream<List<int>>? body,
  }) async {
    final client = await connectRemoteRpc(
      uri: Uri.parse('ws://127.0.0.1:${server.boundPort}/rpc'),
      deviceId: deviceId,
      psk: psk,
      insecureAllowed: true,
    );
    addTearDown(client.close);
    return client.resources.request(
      method,
      Uri.parse(path),
      body: body,
      headers: body == null
          ? const {}
          : const {
              HttpHeaders.contentTypeHeader: ['application/octet-stream'],
            },
    );
  }

  Future<RemoteResourceResponse> get(LocalRpcServer server, String path) =>
      requestResource(server, 'GET', path);

  Future<RemoteResourceResponse> post(
    LocalRpcServer server,
    String path,
    List<int> body,
  ) => requestResource(server, 'POST', path, body: Stream.value(body));

  Future<HttpClientResponse> publicGet(
    LocalRpcServer server,
    String path,
  ) async {
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    return (await client.getUrl(
      Uri.parse('http://127.0.0.1:${server.boundPort}$path'),
    )).close();
  }

  test('public HTTP refuses signed backup downloads and uploads', () async {
    var exported = false;
    var archived = false;
    var restored = false;
    final server = await serve(
      export: ({required workspaceId}) async {
        exported = true;
        return null;
      },
      snapshot: ({required name}) async {
        archived = true;
        return null;
      },
      restore: ({required workspaceId, required sourcePath}) async {
        restored = true;
      },
    );
    for (final path in [
      '/backup/workspace?w=$workspaceId&d=$deviceId&s=${sign('backup-workspace:$workspaceId')}',
      '/backup/snapshot?n=snap&d=$deviceId&s=${sign('backup-snapshot:snap')}',
    ]) {
      final response = await publicGet(server, path);
      await response.drain<void>();
      expect(response.statusCode, HttpStatus.upgradeRequired);
    }
    final http = HttpClient();
    addTearDown(() => http.close(force: true));
    final request = await http.postUrl(
      Uri.parse(
        'http://127.0.0.1:${server.boundPort}'
        '/backup/restore?w=$workspaceId&d=$deviceId'
        '&s=${sign('backup-restore:$workspaceId')}',
      ),
    );
    request.add(const [42, 43, 44]);
    final response = await request.close();
    await response.drain<void>();
    expect(response.statusCode, HttpStatus.upgradeRequired);
    expect(exported, isFalse);
    expect(archived, isFalse);
    expect(restored, isFalse);
  });

  group('GET /backup/workspace', () {
    test('streams the export and removes the server-side copy', () async {
      final produced = File('${tmp.path}/ws-1-export.db')
        ..writeAsBytesSync(const [1, 2, 3, 4, 5]);
      final server = await serve(
        export: ({required workspaceId}) async => produced,
      );

      final resp = await get(
        server,
        '/backup/workspace?w=$workspaceId&d=$deviceId'
        '&s=${sign('backup-workspace:$workspaceId')}',
      );
      final bytes = await resp.body.expand((c) => c).toList();

      expect(resp.statusCode, 200);
      expect(bytes, const [1, 2, 3, 4, 5]);
      // Named so it lands in Downloads as a file, not as a page.
      expect(
        resp.headers['content-disposition']?.single,
        'attachment; filename="ws-1-export.db"',
      );
      // Every request mints a FRESH copy, so a cached or resumed response would
      // splice two different exports into one file that looks valid.
      expect(resp.headers['cache-control']?.single, 'no-store');
      expect(resp.headers[HttpHeaders.acceptRangesHeader]?.single, 'none');
      // A download's destination is the caller's disk. Leaving a second copy
      // per download is how a data directory fills with files nobody asked for.
      await expectDeleted(produced);
    });

    test('canceling an in-flight download cleans up its server copy', () async {
      final produced = File('${tmp.path}/cancelled-export.db')
        ..writeAsBytesSync(List<int>.filled(1024 * 1024, 73));
      final server = await serve(
        export: ({required workspaceId}) async => produced,
      );
      final response = await get(
        server,
        '/backup/workspace?w=$workspaceId&d=$deviceId'
        '&s=${sign('backup-workspace:$workspaceId')}',
      );
      expect(response.statusCode, 200);
      await response.close();
      await expectDeleted(produced);
    });

    test('binds the requested device and workspace to the session', () async {
      var exported = false;
      final server = await serve(
        export: ({required workspaceId}) async {
          exported = true;
          return null;
        },
      );
      final wrongDevice = await get(
        server,
        '/backup/workspace?w=$workspaceId&d=device-other'
        '&s=${sign('backup-workspace:$workspaceId')}',
      );
      await wrongDevice.body.drain<void>();
      expect(wrongDevice.statusCode, 403);
      final wrongWorkspace = await get(
        server,
        '/backup/workspace?w=ws-other&d=$deviceId'
        '&s=${sign('backup-workspace:ws-other')}',
      );
      await wrongWorkspace.body.drain<void>();
      expect(wrongWorkspace.statusCode, 403);
      expect(exported, isFalse);
    });

    test('refuses a signature made with another key', () async {
      final server = await serve(
        export: ({required workspaceId}) async =>
            File('${tmp.path}/x.db')..writeAsBytesSync(const [1]),
      );

      final resp = await get(
        server,
        '/backup/workspace?w=$workspaceId&d=$deviceId'
        '&s=${RemoteControlCrypto.signProxyTarget('backup-workspace:$workspaceId', RemoteControlCrypto.generatePsk())}',
      );
      await resp.body.drain<void>();

      expect(resp.statusCode, 403);
    });

    test('requires admin, not merely membership', () async {
      // A viewer holding a paired device must not be able to walk off with the
      // workspace's entire history.
      final denied = await serve(
        export: ({required workspaceId}) async =>
            File('${tmp.path}/y.db')..writeAsBytesSync(const [1]),
        role: WorkspaceRole.member,
      );
      final refused = await get(
        denied,
        '/backup/workspace?w=$workspaceId&d=$deviceId'
        '&s=${sign('backup-workspace:$workspaceId')}',
      );
      await refused.body.drain<void>();
      expect(refused.statusCode, 403);

      final allowed = await serve(
        export: ({required workspaceId}) async =>
            File('${tmp.path}/z.db')..writeAsBytesSync(const [1]),
        role: WorkspaceRole.admin,
      );
      final served = await get(
        allowed,
        '/backup/workspace?w=$workspaceId&d=$deviceId'
        '&s=${sign('backup-workspace:$workspaceId')}',
      );
      await served.body.drain<void>();
      expect(served.statusCode, 200);
    });

    test('404s on a host with no backup port (a demo server)', () async {
      final server = await serve();

      final resp = await get(
        server,
        '/backup/workspace?w=$workspaceId&d=$deviceId'
        '&s=${sign('backup-workspace:$workspaceId')}',
      );
      await resp.body.drain<void>();

      expect(resp.statusCode, 404);
    });
  });

  group('GET /backup/snapshot', () {
    test('serves the archive to the install operator', () async {
      final archive = File('${tmp.path}/snap.zip')
        ..writeAsBytesSync(const [9, 8, 7]);
      final server = await serve(
        snapshot: ({required name}) async => archive,
        owner: userId,
      );

      final resp = await get(
        server,
        '/backup/snapshot?n=snap&d=$deviceId&s=${sign('backup-snapshot:snap')}',
      );
      final bytes = await resp.body.expand((c) => c).toList();

      expect(resp.statusCode, 200);
      expect(bytes, const [9, 8, 7]);
      await expectDeleted(archive);
    });

    test('refuses anyone who is not the install operator', () async {
      // A snapshot holds EVERY workspace plus global.db, so a role in one of
      // them authorizes nothing here.
      final server = await serve(
        snapshot: ({required name}) async =>
            File('${tmp.path}/s.zip')..writeAsBytesSync(const [1]),
        owner: ownerId,
        role: WorkspaceRole.owner,
      );

      final resp = await get(
        server,
        '/backup/snapshot?n=snap&d=$deviceId&s=${sign('backup-snapshot:snap')}',
      );
      await resp.body.drain<void>();

      expect(resp.statusCode, 403);
    });
  });

  group('POST /backup/restore', () {
    test('stages the upload, adopts it, and leaves nothing behind', () async {
      final adopted = <({String workspaceId, List<int> bytes})>[];
      String? stagedPath;
      final server = await serve(
        restore: ({required workspaceId, required sourcePath}) async {
          stagedPath = sourcePath;
          adopted.add((
            workspaceId: workspaceId,
            bytes: File(sourcePath).readAsBytesSync(),
          ));
        },
        role: WorkspaceRole.owner,
      );

      final resp = await post(
        server,
        '/backup/restore?w=$workspaceId&d=$deviceId'
        '&s=${sign('backup-restore:$workspaceId')}',
        const [42, 43, 44],
      );
      final body = await utf8.decoder.bind(resp.body).join();

      expect(resp.statusCode, 200);
      expect(jsonDecode(body), {'ok': true, 'workspace_id': workspaceId});
      // The bytes reached the adopter as a real file on the server's disk —
      // which is what `workspace.import` needs and a remote client cannot make.
      expect(adopted.single.workspaceId, workspaceId);
      expect(adopted.single.bytes, const [42, 43, 44]);
      // And the staged copy is gone: it is somebody's whole workspace, and
      // nothing else sweeps that directory.
      await expectDeleted(File(stagedPath!));
    });

    test('streams multiple upload chunks into the staged database', () async {
      String? stagedPath;
      List<int>? adopted;
      final server = await serve(
        restore: ({required workspaceId, required sourcePath}) async {
          stagedPath = sourcePath;
          adopted = await File(sourcePath).readAsBytes();
        },
      );
      final first = List<int>.filled(48 * 1024, 17);
      const second = [42, 43, 44];
      final response = await requestResource(
        server,
        'POST',
        '/backup/restore?w=$workspaceId&d=$deviceId'
            '&s=${sign('backup-restore:$workspaceId')}',
        body: Stream<List<int>>.fromIterable([first, second]),
      );
      final body = await utf8.decoder.bind(response.body).join();
      expect(response.statusCode, 200);
      expect(jsonDecode(body), {'ok': true, 'workspace_id': workspaceId});
      expect(adopted, [...first, ...second]);
      await expectDeleted(File(stagedPath!));
    });

    test('refuses restore for a different device or workspace', () async {
      var adopted = false;
      final server = await serve(
        restore: ({required workspaceId, required sourcePath}) async {
          adopted = true;
        },
      );
      final wrongDevice = await post(
        server,
        '/backup/restore?w=$workspaceId&d=device-other'
        '&s=${sign('backup-restore:$workspaceId')}',
        const [1],
      );
      await wrongDevice.body.drain<void>();
      expect(wrongDevice.statusCode, 403);
      final wrongWorkspace = await post(
        server,
        '/backup/restore?w=ws-other&d=$deviceId'
        '&s=${sign('backup-restore:ws-other')}',
        const [1],
      );
      await wrongWorkspace.body.drain<void>();
      expect(wrongWorkspace.statusCode, 403);
      expect(adopted, isFalse);
    });

    test('requires owner, not merely admin', () async {
      var adopted = false;
      final server = await serve(
        restore: ({required workspaceId, required sourcePath}) async {
          adopted = true;
        },
        role: WorkspaceRole.admin,
      );

      final resp = await post(
        server,
        '/backup/restore?w=$workspaceId&d=$deviceId'
        '&s=${sign('backup-restore:$workspaceId')}',
        const [1, 2, 3],
      );
      await resp.body.drain<void>();

      expect(resp.statusCode, 403);
      expect(adopted, isFalse);
    });

    test('reports what the adopter refused, and stages nothing', () async {
      String? stagedPath;
      final server = await serve(
        restore: ({required workspaceId, required sourcePath}) async {
          stagedPath = sourcePath;
          throw ArgumentError.value(
            sourcePath,
            'sourcePath',
            'not a Control Center workspace database',
          );
        },
        role: WorkspaceRole.owner,
      );

      final resp = await post(
        server,
        '/backup/restore?w=$workspaceId&d=$deviceId'
        '&s=${sign('backup-restore:$workspaceId')}',
        const [0, 0, 0],
      );
      final body = await utf8.decoder.bind(resp.body).join();

      // The adopter's own sentence reaches the operator — "the file you picked
      // is not a workspace database" is the only useful thing to say here.
      expect(resp.statusCode, 400);
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      expect(
        decoded['error'],
        contains('not a Control Center workspace database'),
      );
      await expectDeleted(File(stagedPath!));
    });

    test('refuses an empty body', () async {
      final server = await serve(
        restore: ({required workspaceId, required sourcePath}) async {},
        role: WorkspaceRole.owner,
      );

      final resp = await post(
        server,
        '/backup/restore?w=$workspaceId&d=$deviceId'
        '&s=${sign('backup-restore:$workspaceId')}',
        const [],
      );
      await resp.body.drain<void>();

      expect(resp.statusCode, 400);
    });

    test('refuses a GET', () async {
      final server = await serve(
        restore: ({required workspaceId, required sourcePath}) async {},
        role: WorkspaceRole.owner,
      );

      final resp = await get(
        server,
        '/backup/restore?w=$workspaceId&d=$deviceId'
        '&s=${sign('backup-restore:$workspaceId')}',
      );
      await resp.body.drain<void>();

      expect(resp.statusCode, 405);
    });
  });

  group('BackupSnapshotArchiveBuilder', () {
    // A snapshot with the layout a restore expects: manifest + global db at the
    // top level, one workspace directory.
    Directory writeSnapshot() {
      final snapshot = Directory('${tmp.path}/2026-08-31T09-00-00-000Z')
        ..createSync(recursive: true);
      File('${snapshot.path}/manifest.json').writeAsStringSync('{"version":1}');
      File('${snapshot.path}/global.db').writeAsBytesSync(const [1, 2]);
      Directory('${snapshot.path}/ws-1').createSync();
      File('${snapshot.path}/ws-1/workspace.db').writeAsBytesSync(const [3, 4]);
      return snapshot;
    }

    test('packs the snapshot layout a restore expects', () async {
      final snapshot = writeSnapshot();

      final archive = await BackupSnapshotArchiveBuilder(
        stagingDir: '${tmp.path}/transfer',
      ).build(snapshot: snapshot, name: 'snap');

      expect(archive, isNotNull);
      expect(archive!.existsSync(), isTrue);
      expect(archive.path, endsWith('snap.zip'));
      expect(archive.lengthSync(), greaterThan(0));

      // The download unpacks to the same shape a restore copies back, each
      // entry's bytes intact.
      final input = InputFileStream(archive.path);
      try {
        final decoded = ZipDecoder().decodeStream(input);
        expect(
          decoded.map((entry) => entry.name),
          containsAll(<String>[
            'manifest.json',
            'global.db',
            'ws-1/workspace.db',
          ]),
        );
        expect(
          decoded.find('manifest.json')!.readBytes(),
          utf8.encode('{"version":1}'),
        );
        expect(decoded.find('global.db')!.readBytes(), const [1, 2]);
        expect(decoded.find('ws-1/workspace.db')!.readBytes(), const [3, 4]);
      } finally {
        input.closeSync();
      }
    });

    test('is readable by an external unzip', () async {
      // The archive package's own writer is what regressed (7-Zip reported
      // header errors; `unzip` rejected stored directory entries), and the
      // package's reader cannot see that class of bug. Only an outside reader
      // can, so this is a deliberate dependency on a host tool.
      final unzip = _findUnzip();
      if (unzip == null) {
        markTestSkipped('unzip is not installed');
        return;
      }
      final archive = await BackupSnapshotArchiveBuilder(
        stagingDir: '${tmp.path}/transfer',
      ).build(snapshot: writeSnapshot(), name: 'snap');

      final result = await Process.run(unzip, ['-t', archive!.path]);
      expect(
        result.exitCode,
        0,
        reason: 'unzip -t reported: ${result.stdout}${result.stderr}',
      );
    });

    test('returns nothing for a snapshot that is gone', () async {
      final archive = await BackupSnapshotArchiveBuilder(
        stagingDir: '${tmp.path}/transfer',
      ).build(snapshot: Directory('${tmp.path}/missing'), name: 'snap');

      expect(archive, isNull);
    });
  });
}

/// The host's `unzip`, or null when it has none.
String? _findUnzip() {
  for (final candidate in const ['/usr/bin/unzip', '/bin/unzip']) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }
  try {
    final which = Process.runSync('which', ['unzip']);
    final path = (which.stdout as String).trim();
    return which.exitCode == 0 && path.isNotEmpty ? path : null;
  } on ProcessException {
    return null;
  }
}

/// Answers session initialization; resource handlers are exercised separately.
class _StubDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      request.id == null
      ? const {}
      : {'jsonrpc': '2.0', 'id': request.id, 'result': <String, dynamic>{}};
}

class _StubDevicesDao implements PairedDeviceDao {
  _StubDevicesDao({required this.deviceId, required this.userId});

  final String deviceId;
  final String userId;

  @override
  Stream<List<PairedDevicesTableData>> watchAll() => const Stream.empty();

  @override
  Future<PairedDevicesTableData?> getById(String id) async {
    if (id != deviceId) {
      return null;
    }
    return PairedDevicesTableData(
      id: id,
      userId: userId,
      label: 'Test',
      pskRef: 'paired_device_psk_$id',
      status: PairedDeviceStatus.active,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      pairedAt: DateTime.now(),
      platform: 'web',
    );
  }

  @override
  Future<int> markSeen(String id, DateTime at) async => id == deviceId ? 1 : 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubSecrets implements PairedDeviceSecretsPort {
  _StubSecrets({required this.psk});

  final String psk;

  @override
  Future<String?> readPsk(String deviceId) async => psk;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
