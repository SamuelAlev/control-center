import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import 'helpers/best_effort_delete.dart';
import 'helpers/booted_rpc.dart';
import 'helpers/native_staging.dart';
import 'helpers/test_database.dart';

/// Who may create a workspace, and what an existing one's id and owner can
/// become, against a booted server.
///
/// - Only the server owner creates a workspace (`workspace.create`); anyone
///   else is refused with `data.kind: server_owner_required`, and
///   `identity.me` says so up front (`can_create_workspaces`).
/// - The server mints the id, so an id that ever named a workspace here never
///   names a new one; `workspace.upsert` only updates a live workspace.
/// - On update the stored owner, deletion and creation time stand; the
///   wire's are ignored, so nothing restores a deleted workspace.
void main() {
  if (!hostHasServerNatives) {
    test(
      'native libraries are staged for server boot',
      () {
        fail(
          'Native libraries not found — run scripts/natives/build_natives.sh. '
          'They are REQUIRED; cc_server refuses to boot without them.',
        );
      },
      skip: skipServerBootWithoutNatives(
        reason: 'Native libraries are not built on CI runners',
      ),
    );
    return;
  }

  late Directory tmp;
  late CcServer server;
  late RemoteRpcClient owner;
  late RemoteRpcClient guest;
  late String ownerUserId;

  setUpAll(() async {
    tmp = Directory.systemTemp.createTempSync('cc_ws_create_policy');
    await stageServerNatives(tmp.path);

    const ownerDeviceId = 'owner-device';
    final ownerPsk = RemoteControlCrypto.generatePsk();
    const guestDeviceId = 'guest-device';
    final guestPsk = RemoteControlCrypto.generatePsk();

    // A fresh install: the owner and their paired device. The guest's PSK goes in now (the secrets store reads
    // the file once); the guest's rows go in after boot.
    final seed = openSeedDatabases(tmp.path);
    final seededOwnerId = await seedServerOwner(seed);
    await seed.global.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: const Value(ownerDeviceId),
        label: const Value('owner'),
        pskRef: const Value('file'),
        status: const Value(PairedDeviceStatus.active),
        userId: Value(seededOwnerId),
        expiresAt: Value(seededDeviceExpiry()),
      ),
    );
    await seed.close();
    final secrets = FileSecretsStore(dataDir: tmp.path);
    await secrets.writePsk(ownerDeviceId, ownerPsk);
    await secrets.writePsk(guestDeviceId, guestPsk);

    server = await runCcServer(args: ['--data-dir', tmp.path, '--port', '0']);
    final uri = Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc');

    owner = await connectBootedServer(
      uri: uri,
      deviceId: ownerDeviceId,
      psk: ownerPsk,
    );
    await owner.initialize();
    ownerUserId =
        ((await owner.call('identity.me', const {}))['user'] as Map)['id']
            as String;

    // Any other authenticated account: an invited member, an SSO login.
    final guestSeed = openSeedDatabases(tmp.path);
    await guestSeed.global.userDao.upsert(
      const UsersTableCompanion(
        id: Value('user-guest'),
        handle: Value('guest'),
        displayName: Value('Guest'),
      ),
    );
    await guestSeed.global.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: const Value(guestDeviceId),
        userId: const Value('user-guest'),
        label: const Value('guest'),
        pskRef: const Value('file'),
        status: const Value(PairedDeviceStatus.active),
        expiresAt: Value(seededDeviceExpiry()),
      ),
    );
    await guestSeed.close();
    guest = await connectBootedServer(
      uri: uri,
      deviceId: guestDeviceId,
      psk: guestPsk,
    );
    await guest.initialize();
  });

  tearDownAll(() async {
    await guest.close();
    await owner.close();
    await server.shutdown();
    await deleteDirBestEffort(tmp);
  });

  Matcher refused(int code, {String? kind}) => throwsA(
    isA<RemoteRpcException>()
        .having((e) => e.code, 'code', code)
        .having(
          (e) => (e.data as Map?)?['kind'],
          'data.kind',
          kind == null ? anything : equals(kind),
        ),
  );

  Future<Map<String, dynamic>> row(String id) async {
    final all = await owner
        .subscribe('workspace.watchAll', const {})
        .first
        .timeout(const Duration(seconds: 10));
    return (all['workspaces'] as List).cast<Map<String, dynamic>>().singleWhere(
      (w) => w['id'] == id,
    );
  }

  // Waits out the seeding a create starts in the background, then requires
  // the workspace's directory to be gone.
  Future<void> filesGone(String id) async {
    final dir = Directory('${tmp.path}/$id');
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (dir.existsSync() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(dir.existsSync(), isFalse, reason: 'files of deleted workspace $id');
  }

  Future<String> create(String name, [Map<String, dynamic> extra = const {}]) =>
      owner
          .call('workspace.create', {'name': name, ...extra})
          .then((r) => (r['workspace'] as Map)['id'] as String);

  test('identity.me says who may create a workspace', () async {
    final mine = await owner.call('identity.me', const {});
    expect(mine['can_create_workspaces'], isTrue);
    final theirs = await guest.call('identity.me', const {});
    expect(theirs['can_create_workspaces'], isFalse);
  });

  test('an account that is not the server owner cannot create a workspace, '
      'and is told why', () async {
    await expectLater(
      guest.call('workspace.create', const {'name': 'Mine'}),
      refused(RpcErrorCodes.unauthorized, kind: 'server_owner_required'),
    );
    expect(await guest.listWorkspaces(), isEmpty);
  });

  test('the server owner creates a workspace with a server-minted id and owns '
      'it', () async {
    final id = await create('Team', const {'id': 'ws-chosen'});
    expect(id, isNot('ws-chosen'));
    expect((await row(id))['owner_user_id'], ownerUserId);
    expect((await owner.listWorkspaces()).map((w) => w['id']), contains(id));
  });

  test('workspace.upsert never creates a workspace, not even for the owner, '
      'and leaves no database behind', () async {
    for (final client in [owner, guest]) {
      await expectLater(
        client.call('workspace.upsert', const {
          'workspace': {'id': 'ws-proposed', 'name': 'Proposed'},
        }),
        refused(RpcErrorCodes.notFound),
      );
    }
    expect(Directory('${tmp.path}/ws-proposed').existsSync(), isFalse);
  });

  test('an update keeps the stored owner, deletion and creation time; only '
      'the settings change', () async {
    final id = await create('Stamped');
    final before = await row(id);
    await owner.call('workspace.upsert', {
      'workspace': {
        'id': id,
        'name': 'Renamed',
        'owner_user_id': 'user-guest',
        'deleted_at': DateTime.utc(2026).toIso8601String(),
        'created_at': DateTime.utc(2001).toIso8601String(),
      },
    });
    final after = await row(id);
    expect(after['name'], 'Renamed');
    expect(after['owner_user_id'], ownerUserId);
    expect(after.containsKey('deleted_at'), isFalse);
    expect(after['created_at'], before['created_at']);
  });

  test('an account that is not an admin of the workspace cannot update or '
      'delete it', () async {
    final id = await create('Guarded');
    await expectLater(
      guest.call('workspace.upsert', {
        'workspace': {'id': id, 'name': 'Taken'},
      }),
      refused(RpcErrorCodes.unauthorized),
    );
    await expectLater(
      guest.call('workspace.delete', {'id': id}),
      refused(RpcErrorCodes.unauthorized),
    );
    expect((await row(id))['name'], 'Guarded');
  });

  test('a deleted workspace id never names a workspace again: no restore, no '
      're-create, no second delete', () async {
    final id = await create('Doomed');
    // Deleted straight after creation, while the server is still seeding it:
    // the seeder's late writes must not leave its files behind.
    await owner.call('workspace.delete', {'id': id});
    await filesGone(id);

    // An update naming it, with or without clearing `deleted_at`, is a
    // restore by another name: not found, for the owner as for anyone.
    for (final client in [owner, guest]) {
      await expectLater(
        client.call('workspace.upsert', {
          'workspace': {'id': id, 'name': 'Doomed', 'deleted_at': null},
        }),
        refused(RpcErrorCodes.notFound),
      );
    }
    await expectLater(
      owner.call('workspace.delete', {'id': id}),
      refused(RpcErrorCodes.notFound),
    );
    // Creating cannot pick it either.
    expect(await create('Again', {'id': id}), isNot(id));

    expect(
      (await owner.listWorkspaces()).map((w) => w['id']),
      isNot(contains(id)),
    );
    await filesGone(id);
  });
}
