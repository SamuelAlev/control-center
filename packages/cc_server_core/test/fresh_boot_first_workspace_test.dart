import 'dart:async';
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

/// First-run regression: a FRESH data dir (zero workspaces; the identity
/// bootstrap mints the first user at boot) must let the connected client run
/// the whole onboarding flow WITHOUT a server restart.
///
/// Guards the `workspace.create` path: the creating principal becomes the
/// workspace owner (ownerUserId + an owner membership row) in the same op.
/// Without it the freshly created workspace has no members, so
/// `session/list_workspaces` stays empty and every workspace-scoped op the
/// creator issues next is denied with "Not a member of this workspace".
void main() {
  if (!hostHasServerNatives) {
    test(
      'native libraries are staged for server boot',
      () {
        fail(
          'Native libraries not found — run scripts/natives/build_natives.sh. '
          'They are REQUIRED; '
          'cc_server refuses to boot without them.',
        );
      },
      skip: skipServerBootWithoutNatives(
        reason: 'Native libraries are not built on CI runners',
      ),
    );
    return;
  }

  test(
    'fresh server: creating the first workspace makes it usable immediately',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_server_fresh');
      // The boot preflight refuses to start without the native libraries;
      // stage whatever this machine has into the data dir (see the helper).
      await stageServerNatives(tmp.path);
      addTearDown(() => deleteDirBestEffort(tmp));

      const deviceId = 'web-test-device';
      final psk = RemoteControlCrypto.generatePsk();

      // Seed ONLY the owner and their paired device (no workspace) — the
      // state of a brand-new install after `cc_server pair`.
      final seed = openSeedDatabases(tmp.path);
      final seededOwnerId = await seedServerOwner(seed);
      await seed.global.pairedDeviceDao.upsert(
        PairedDevicesTableCompanion(
          id: const Value(deviceId),
          label: const Value('fresh-boot test'),
          pskRef: const Value('file'),
          status: const Value(PairedDeviceStatus.active),
          userId: Value(seededOwnerId),
          expiresAt: Value(seededDeviceExpiry()),
        ),
      );
      await seed.close();
      await FileSecretsStore(dataDir: tmp.path).writePsk(deviceId, psk);

      final server = await runCcServer(
        args: ['--data-dir', tmp.path, '--port', '0'],
      );
      addTearDown(server.shutdown);

      final client = await connectBootedServer(
        uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
        deviceId: deviceId,
        psk: psk,
      );
      addTearDown(client.close);
      await client.initialize();

      // The onboarding gate's inputs on a fresh server: no workspaces yet.
      expect(await client.listWorkspaces(), isEmpty);
      final snapshot = await client
          .subscribe('workspace.watchAll', const {})
          .first
          .timeout(const Duration(seconds: 10));
      expect(snapshot['workspaces'], isEmpty);

      // A LIVE subscription, opened while the user belongs to NOTHING — which
      // is what the app actually holds throughout onboarding. The
      // membership-scoped filter resolves the subscriber's workspace set once
      // and re-resolves only on their WorkspaceMemberAdded/Removed events, so
      // a create that announced no membership left this stream filtering the
      // user's own new workspace out of every later emission: the client's
      // list stayed empty for the whole session, the onboarding gate stayed
      // "incomplete", and Finish bounced straight back into the flow.
      final liveIds = <String>{};
      final firstLiveFrame = Completer<void>();
      final liveSub = client.subscribe('workspace.watchAll', const {}).listen((
        frame,
      ) {
        for (final w
            in (frame['workspaces'] as List).cast<Map<String, dynamic>>()) {
          liveIds.add(w['id'] as String);
        }
        if (!firstLiveFrame.isCompleted) {
          firstLiveFrame.complete();
        }
      });
      addTearDown(liveSub.cancel);
      await firstLiveFrame.future.timeout(const Duration(seconds: 10));
      expect(liveIds, isEmpty);

      // Create the first workspace exactly the way onboarding does.
      final created = await client.call('workspace.create', {'name': 'Fresh'});
      final freshId = (created['workspace'] as Map)['id'] as String;

      // The already-open stream must catch up on its own.
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (!liveIds.contains(freshId) && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(
        liveIds,
        contains(freshId),
        reason:
            'the subscription held across the create never saw the workspace',
      );

      // The creator is a member: the membership-scoped session list sees it…
      final visible = await client.listWorkspaces();
      expect(visible.map((w) => w['id']), contains(freshId));

      // …the row carries the creator as owner…
      final all = await client
          .subscribe('workspace.watchAll', const {})
          .first
          .timeout(const Duration(seconds: 10));
      final row = (all['workspaces'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((w) => w['id'] == freshId);
      expect(row['owner_user_id'], isNotNull);
      expect(row['connect_mode'], 'inherit');
      // …and says whether its database takes writes.
      expect(row['storage_state'], 'ok');

      // The generic update never changes the Connect choice: only
      // `workspaceConnect.set` does.
      await client.call('workspace.upsert', {
        'workspace': {
          'id': freshId,
          'name': 'Fresh',
          'connect_mode': 'custom',
          'connect_url': 'https://connect.example.com',
        },
      });
      final updated =
          ((await client
                      .subscribe('workspace.watchAll', const {})
                      .first
                      .timeout(const Duration(seconds: 10)))['workspaces']
                  as List)
              .cast<Map<String, dynamic>>()
              .singleWhere((w) => w['id'] == freshId);
      expect(updated['connect_mode'], 'inherit');
      expect(updated.containsKey('connect_url'), isFalse);

      // …and workspace-scoped ops work immediately (no restart needed).
      client.activeWorkspaceId = freshId;
      final tickets = await client.call('tickets.list', const {});
      expect(tickets['tickets'], isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'stale workspace id is refused without materialising a ghost database',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_server_ghost');
      await stageServerNatives(tmp.path);
      addTearDown(() => deleteDirBestEffort(tmp));

      const deviceId = 'ghost-test-device';
      final psk = RemoteControlCrypto.generatePsk();

      // Same fresh-install state as above: the owner's paired device, no
      // workspace. The client below acts as one whose persisted active
      // workspace id predates the data-dir reset — the id is stale: nothing
      // on this server ever registered it.
      final seed = openSeedDatabases(tmp.path);
      final seededOwnerId = await seedServerOwner(seed);
      await seed.global.pairedDeviceDao.upsert(
        PairedDevicesTableCompanion(
          id: const Value(deviceId),
          label: const Value('ghost-id test'),
          pskRef: const Value('file'),
          status: const Value(PairedDeviceStatus.active),
          userId: Value(seededOwnerId),
          expiresAt: Value(seededDeviceExpiry()),
        ),
      );
      await seed.close();
      await FileSecretsStore(dataDir: tmp.path).writePsk(deviceId, psk);

      final server = await runCcServer(
        args: ['--data-dir', tmp.path, '--port', '0'],
      );
      addTearDown(server.shutdown);

      final client = await connectBootedServer(
        uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
        deviceId: deviceId,
        psk: psk,
      );
      addTearDown(client.close);
      await client.initialize();

      // A workspace-scoped op naming an unregistered workspace is refused as
      // not-found BEFORE the membership lookup — that lookup opens the named
      // workspace's database and opening CREATES the file.
      await expectLater(
        client.call('tickets.list', const {'workspace_id': 'ws-ghost'}),
        throwsA(
          isA<RemoteRpcException>().having(
            (e) => e.code,
            'code',
            RpcErrorCodes.notFound,
          ),
        ),
      );

      // A workspace-scoped subscription is refused the same way: the
      // subscribe ack lands first, then the refusal arrives as the stream's
      // first (error) event — its handler never ran.
      await expectLater(
        client.subscribe('tickets.watchForWorkspace', const {
          'workspace_id': 'ws-ghost',
        }).first,
        throwsA(
          isA<RemoteRpcException>().having(
            (e) => e.code,
            'code',
            RpcErrorCodes.notFound,
          ),
        ),
      );

      // The point of the gate: no ghost workspace database was materialised
      // (previously each request created `<dataDir>/ws-ghost/workspace.db`).
      expect(Directory('${tmp.path}/ws-ghost').existsSync(), isFalse);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('onboarding is recorded on the user, monotonically', () async {
    // The gate that picks between "sign in again" and "run the first-run
    // flow" reads this flag. It was a synced PREFERENCE, and the preference
    // sync promotes a device's local values onto whichever account first
    // signs in there — so a machine that had onboarded once marked a
    // brand-new user as already set up, and they got the re-auth screen
    // instead of the setup they had never done. It is a column on the user
    // now, reachable only through the caller's own session.
    final tmp = Directory.systemTemp.createTempSync('cc_server_onboarded');
    await stageServerNatives(tmp.path);
    addTearDown(() => deleteDirBestEffort(tmp));

    const deviceId = 'onboarded-test-device';
    final psk = RemoteControlCrypto.generatePsk();

    // The fresh-install state: the owner's paired device. Nobody has
    // onboarded on this server.
    final seed = openSeedDatabases(tmp.path);
    final seededOwnerId = await seedServerOwner(seed);
    await seed.global.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: const Value(deviceId),
        label: const Value('onboarding flag test'),
        pskRef: const Value('file'),
        status: const Value(PairedDeviceStatus.active),
        userId: Value(seededOwnerId),
        expiresAt: Value(seededDeviceExpiry()),
      ),
    );
    await seed.close();
    await FileSecretsStore(dataDir: tmp.path).writePsk(deviceId, psk);

    final server = await runCcServer(
      args: ['--data-dir', tmp.path, '--port', '0'],
    );
    addTearDown(server.shutdown);

    final client = await connectBootedServer(
      uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
      deviceId: deviceId,
      psk: psk,
    );
    addTearDown(client.close);
    await client.initialize();

    Future<String?> finishedAt() async {
      final me = await client.call('identity.me', const {});
      return (me['user'] as Map)['onboarding_finished_at'] as String?;
    }

    // A brand-new account has never onboarded — the flag is absent, not
    // false-y-by-accident, and the client reads "no" from that.
    expect(await finishedAt(), isNull);

    final stamped = await client.call('users.markOnboardingFinished', const {});
    final at = stamped['onboarding_finished_at'] as String;
    expect(at, isNotEmpty);
    expect(await finishedAt(), at);

    // Monotonic: the gate re-records the flag on every launch that observes a
    // complete setup, so a second call must not move the date.
    final again = await client.call('users.markOnboardingFinished', const {});
    expect(again['onboarding_finished_at'], at);
    expect(await finishedAt(), at);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a non-member cannot see, read, mutate, or watch another user\'s '
      'workspace', () async {
    final tmp = Directory.systemTemp.createTempSync('cc_server_nonmember');
    await stageServerNatives(tmp.path);
    addTearDown(() => deleteDirBestEffort(tmp));

    const ownerDeviceId = 'owner-device';
    final ownerPsk = RemoteControlCrypto.generatePsk();
    const guestDeviceId = 'guest-device';
    final guestPsk = RemoteControlCrypto.generatePsk();

    // Seed ONLY the owner and their device; the guest user + device are
    // inserted after boot.
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
    // The guest PSK is written NOW, pre-boot: the server's secrets store
    // caches the file at first read, so a PSK written after boot would be
    // invisible to it. Only the guest's user/device ROWS go in post-boot.
    await secrets.writePsk(guestDeviceId, guestPsk);

    final server = await runCcServer(
      args: ['--data-dir', tmp.path, '--port', '0'],
    );
    addTearDown(server.shutdown);

    // The owner connects and creates a workspace.
    final owner = await connectBootedServer(
      uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
      deviceId: ownerDeviceId,
      psk: ownerPsk,
    );
    addTearDown(owner.close);
    await owner.initialize();
    final privateId =
        ((await owner.call('workspace.create', {
                  'name': 'Private',
                }))['workspace']
                as Map)['id']
            as String;

    // Now register the second user with their own active device.
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

    // The guest connects: authenticated, but a member of NOTHING.
    final guest = await connectBootedServer(
      uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
      deviceId: guestDeviceId,
      psk: guestPsk,
    );
    addTearDown(guest.close);
    await guest.initialize();

    // 1. The workspace picker is membership-scoped: ws-private is invisible.
    expect(await guest.listWorkspaces(), isEmpty);
    final pickerSnapshot = await guest
        .subscribe('workspace.watchAll', const {})
        .first
        .timeout(const Duration(seconds: 10));
    expect(pickerSnapshot['workspaces'], isEmpty);

    Matcher unauthorized() => throwsA(
      isA<RemoteRpcException>().having(
        (e) => e.code,
        'code',
        RpcErrorCodes.unauthorized,
      ),
    );

    // 2. A workspace-scoped op naming the foreign workspace is denied.
    await expectLater(
      guest.call('tickets.list', {'workspace_id': privateId}),
      unauthorized(),
    );

    // 3. A workspace-scoped subscription is refused as a stream error.
    await expectLater(
      guest.subscribe('tickets.watchForWorkspace', {
        'workspace_id': privateId,
      }).first,
      unauthorized(),
    );

    // 4. The registry ops a non-member could previously abuse are denied:
    //    deleting or reordering a workspace they do not belong to.
    await expectLater(
      guest.call('workspace.delete', {'id': privateId}),
      unauthorized(),
    );
    await expectLater(
      guest.call('workspace.reorder', {
        'workspace_ids': [privateId],
      }),
      unauthorized(),
    );

    // 5. Control: the owner's session still sees and reads the workspace.
    expect(
      (await owner.listWorkspaces()).map((w) => w['id']),
      contains(privateId),
    );
    owner.activeWorkspaceId = privateId;
    final tickets = await owner.call('tickets.list', const {});
    expect(tickets['tickets'], isEmpty);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
