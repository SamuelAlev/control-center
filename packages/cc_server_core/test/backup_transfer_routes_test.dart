import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/cc_persistence.dart' show PairedDevicesTableData;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
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
  const psk = 'test-psk-12345';
  const userId = 'user-1';
  const ownerId = 'user-owner';

  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cc_backup_routes_test');
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
      workspaceResolver: (_) async => const [],
      resolveRole: role == null ? null : (_, _) async => role,
      backupExport: export,
      backupSnapshotArchive: snapshot,
      backupRestore: restore,
      backupUploadDir: uploadDir ?? '${tmp.path}/transfer',
      isServerOwner: owner == null ? null : (u) async => u == owner,
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

  Future<HttpClientResponse> get(LocalRpcServer server, String path) async {
    final client = HttpClient();
    addTearDown(client.close);
    return (await client.getUrl(
      Uri.parse('http://127.0.0.1:${server.boundPort}$path'),
    )).close();
  }

  Future<HttpClientResponse> post(
    LocalRpcServer server,
    String path,
    List<int> body,
  ) async {
    final client = HttpClient();
    addTearDown(client.close);
    final req = await client.postUrl(
      Uri.parse('http://127.0.0.1:${server.boundPort}$path'),
    );
    req.headers.contentType = ContentType.binary;
    req.add(body);
    return req.close();
  }

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
      final bytes = await resp.expand((c) => c).toList();

      expect(resp.statusCode, 200);
      expect(bytes, const [1, 2, 3, 4, 5]);
      // Named so it lands in Downloads as a file, not as a page.
      expect(
        resp.headers.value('content-disposition'),
        'attachment; filename="ws-1-export.db"',
      );
      // Every request mints a FRESH copy, so a cached or resumed response would
      // splice two different exports into one file that looks valid.
      expect(resp.headers.value('cache-control'), 'no-store');
      expect(resp.headers.value(HttpHeaders.acceptRangesHeader), 'none');
      // A download's destination is the caller's disk. Leaving a second copy
      // per download is how a data directory fills with files nobody asked for.
      await expectDeleted(produced);
    });

    test('refuses a signature made with another key', () async {
      final server = await serve(
        export: ({required workspaceId}) async =>
            File('${tmp.path}/x.db')..writeAsBytesSync(const [1]),
      );

      final resp = await get(
        server,
        '/backup/workspace?w=$workspaceId&d=$deviceId&s=not-a-signature',
      );
      await resp.drain<void>();

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
      await refused.drain<void>();
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
      await served.drain<void>();
      expect(served.statusCode, 200);
    });

    test('404s on a host with no backup port (a demo server)', () async {
      final server = await serve();

      final resp = await get(
        server,
        '/backup/workspace?w=$workspaceId&d=$deviceId'
        '&s=${sign('backup-workspace:$workspaceId')}',
      );
      await resp.drain<void>();

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
      final bytes = await resp.expand((c) => c).toList();

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
      await resp.drain<void>();

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
      final body = await resp.transform(utf8.decoder).join();

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
      await resp.drain<void>();

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
      final body = await resp.transform(utf8.decoder).join();

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
      await resp.drain<void>();

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
      await resp.drain<void>();

      expect(resp.statusCode, 405);
    });
  });

  group('BackupSnapshotArchiveBuilder', () {
    test('packs the snapshot layout a restore expects', () async {
      final snapshot = Directory('${tmp.path}/2026-08-31T09-00-00-000Z')
        ..createSync(recursive: true);
      File('${snapshot.path}/manifest.json').writeAsStringSync('{"version":1}');
      File('${snapshot.path}/global.db').writeAsBytesSync(const [1, 2]);
      Directory('${snapshot.path}/ws-1').createSync();
      File('${snapshot.path}/ws-1/workspace.db').writeAsBytesSync(const [3, 4]);

      final archive = await BackupSnapshotArchiveBuilder(
        stagingDir: '${tmp.path}/transfer',
      ).build(snapshot: snapshot, name: 'snap');

      expect(archive, isNotNull);
      expect(archive!.existsSync(), isTrue);
      expect(archive.path, endsWith('snap.zip'));
      expect(archive.lengthSync(), greaterThan(0));
    });

    test('returns nothing for a snapshot that is gone', () async {
      final archive = await BackupSnapshotArchiveBuilder(
        stagingDir: '${tmp.path}/transfer',
      ).build(snapshot: Directory('${tmp.path}/missing'), name: 'snap');

      expect(archive, isNull);
    });
  });
}

/// Minimal no-op RPC dispatcher (no backup route dispatches RPC).
class _StubDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      const {};
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
