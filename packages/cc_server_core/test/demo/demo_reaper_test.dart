import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:cc_server_core/src/demo/demo_visitor_service.dart';
import 'package:cc_server_core/src/redeem_capacity_exception.dart';
import 'package:test/test.dart';

import '../helpers/best_effort_delete.dart';
import '../helpers/test_database.dart';

/// The reaper is the demo's whole safety margin on storage AND on privacy: a
/// visitor's workspace has to go away completely, and their session has to be
/// CLOSED rather than merely starved.
///
/// It drives [DemoVisitorService] directly against a real on-disk data
/// directory with a controllable clock, because the TTL floor (5 minutes) is
/// deliberately longer than any test should wait.
void main() {
  late Directory tmp;
  late SeedDatabases dbs;
  late DateTime clock;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cc_demo_reaper');
    dbs = openSeedDatabases(tmp.path);
    clock = DateTime.utc(2026, 3, 1, 12);
    addTearDown(() async {
      await dbs.close();
      await deleteDirBestEffort(tmp);
    });
  });

  /// A service whose only seeding is enough to make a workspace real.
  DemoVisitorService buildService({
    DemoLimits? limits,
    DomainEventBus? bus,
    List<String>? seededWorkspaces,
  }) => DemoVisitorService(
    limits: limits ?? DemoLimits(poolSize: 0),
    dataDir: tmp.path,
    globalDb: dbs.global,
    workspaceDbs: dbs.workspaces,
    workspaceRepository: DaoWorkspaceRepository(
      dbs.global.workspaceRegistryDao,
      dbs.workspaces,
    ),
    userRepository: DaoUserRepository(dbs.global.userDao),
    membershipRepository: DaoWorkspaceMembershipRepository(dbs.workspaces),
    secrets: FileSecretsStore(dataDir: tmp.path),
    eventBus: bus ?? DomainEventBus(),
    seedWorkspace: (id) async => seededWorkspaces?.add(id),
    seedUser: (userId, workspaceId) async {},
    describeDescriptor: () async => const {'v': 1},
    relayRoom: () => 'demo-room',
    publicUrl: '',
    signalingUrl: '',
    now: () => clock,
  );

  test(
    'a redeemed visitor is fully taken back when their TTL expires',
    () async {
      final removals = <WorkspaceMemberRemoved>[];
      final bus = DomainEventBus();
      bus.on<WorkspaceMemberRemoved>().listen(removals.add);
      final service = buildService(bus: bus);

      final envelope = await service.redeem(const {'code': 'demo'});
      final workspaceId = envelope['workspace_id'] as String;
      final userId = (envelope['user'] as Map)['id'] as String;
      final deviceId = envelope['device_id'] as String;

      // Everything they were given exists.
      expect(Directory('${tmp.path}/$workspaceId').existsSync(), isTrue);
      expect(await dbs.global.pairedDeviceDao.getById(deviceId), isNotNull);
      expect(
        await FileSecretsStore(dataDir: tmp.path).readPsk(deviceId),
        isNotNull,
      );
      expect(service.visitors, hasLength(1));

      // Walk past the TTL and sweep. `start()` arms a 60s timer; redeeming
      // sweeps first, which is the same code path.
      clock = clock.add(const Duration(hours: 2));
      await service.redeem(const {'code': 'demo'});

      // The FIRST visitor is gone, root and branch.
      expect(
        Directory('${tmp.path}/$workspaceId').existsSync(),
        isFalse,
        reason:
            'the workspace directory must be unlinked, not just soft-deleted',
      );
      expect(
        await dbs.global.pairedDeviceDao.getById(deviceId),
        isNull,
        reason:
            'the paired-device row is what CLOSES the socket — LocalRpcServer '
            'watches it and drops any session whose device left the active set. '
            'Publishing WorkspaceMemberRemoved alone only drops subscriptions.',
      );
      expect(
        await FileSecretsStore(dataDir: tmp.path).readPsk(deviceId),
        isNull,
        reason: 'the PSK must not outlive the device',
      );

      // Global rows a workspace file cannot reach.
      final user = await DaoUserRepository(dbs.global.userDao).getById(userId);
      expect(user, isNull, reason: 'the guest user row leaks otherwise');

      // The newsfeed is the visitor's largest footprint in `global.db` — one
      // feed row per default subscription and, once the refresh lands, a couple
      // of hundred articles behind them. They live in the GLOBAL database, so
      // unlinking the workspace directory cannot reach them; only the explicit
      // delete (and the `users` FK cascade behind it) does.
      expect(
        await dbs.global.rssDao.getEnabledFeeds(userId),
        isEmpty,
        reason: 'feeds and their articles must go with the visitor',
      );

      // The registry row is HARD-deleted: `workspaceRepository.delete` only
      // soft-deletes, and at demo scale tombstones accrete forever.
      final registry = await dbs.global.workspaceRegistryDao.getById(
        workspaceId,
      );
      expect(registry, isNull);

      // And the member-removed event fired, so live subscriptions are dropped
      // before the database disappears underneath them.
      expect(removals.map((e) => e.workspaceId), contains(workspaceId));
    },
  );

  test('a live visitor inside their TTL is left alone', () async {
    final service = buildService();
    final envelope = await service.redeem(const {'code': 'demo'});
    final workspaceId = envelope['workspace_id'] as String;

    clock = clock.add(const Duration(minutes: 10));
    await service.redeem(const {'code': 'demo'});

    expect(Directory('${tmp.path}/$workspaceId').existsSync(), isTrue);
    expect(service.visitors, hasLength(2));
  });

  // There is deliberately no GLOBAL visitor cap — a demo exists to be entered,
  // and the guards that remain bound the cost per ADDRESS rather than the
  // number of people who may walk in. The per-IP cap below is what still
  // produces a capacity refusal, and the point it pins is the same one: a full
  // demo must never tell a visitor their link is invalid, because that sends
  // them away for good.
  test('the per-IP cap bounds one address', () async {
    final service = buildService(limits: DemoLimits(maxPerIp: 2, poolSize: 0));
    await service.redeem(const {'code': 'demo'}, remoteIp: '10.0.0.1');
    await service.redeem(const {'code': 'demo'}, remoteIp: '10.0.0.1');
    // A different address is unaffected.
    await service.redeem(const {'code': 'demo'}, remoteIp: '10.0.0.2');

    await expectLater(
      service.redeem(const {'code': 'demo'}, remoteIp: '10.0.0.1'),
      throwsA(isA<RedeemCapacityException>()),
    );
  });

  /// Waits for the background pool fill, which [DemoVisitorService.start]
  /// deliberately does NOT await (seeding must not sit on the boot path).
  ///
  /// Polls to a DEADLINE rather than a fixed iteration count, so a fast host
  /// still pays only as long as the fill takes. The budget is generous because
  /// filling one slot writes a real SQLite file — create, install the FTS
  /// tables and the sync triggers, `vector_init` — and a Windows CI runner
  /// takes well over the 2s (200 × 10ms) this used to allow. That is precisely
  /// how it failed: "the warm pool never filled", on Windows and nowhere else,
  /// for a pool that was merely still filling.
  Future<void> awaitPool(DemoVisitorService service, int size) async {
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (service.pool.length < size && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(service.pool, hasLength(size), reason: 'the warm pool never filled');
  }

  group('the warm pool never goes stale', () {
    // The demo world is anchored to the moment it was seeded: the fixtures
    // carry relative markers (`@-3d`, `@-20h`) that the seeder resolves ONCE.
    // An unclaimed workspace therefore ages, and the pool used to be
    // write-once — a workspace seeded at boot sat there for the life of the
    // process and handed its eventual visitor a calendar week that had already
    // ended. The invariant these pin: no demo database on disk outlives the
    // TTL, claimed or not.

    test(
      'an unclaimed workspace is refreshed once it passes the TTL',
      () async {
        final seeded = <String>[];
        final service = buildService(
          limits: DemoLimits(poolSize: 1, maxPerIp: 25),
          seededWorkspaces: seeded,
        );
        await service.start();
        addTearDown(service.stop);
        await awaitPool(service, 1);
        final original = service.pool.single;
        expect(Directory('${tmp.path}/$original').existsSync(), isTrue);

        // Inside the TTL nothing moves — a pool that churned every sweep would
        // seed continuously for no reason.
        clock = clock.add(const Duration(minutes: 20));
        await service.redeem(const {'code': 'demo'}, remoteIp: '10.0.0.9');
        expect(
          seeded.where((id) => id == original),
          hasLength(1),
          reason: 'a fresh-enough workspace is not reseeded',
        );

        // Past it, the stale one is deleted and a fresh one takes its place.
        clock = clock.add(const Duration(hours: 2));
        await service.redeem(const {'code': 'demo'}, remoteIp: '10.0.0.10');

        expect(
          service.pool.contains(original),
          isFalse,
          reason: 'the stale entry must leave the pool',
        );
        expect(
          Directory('${tmp.path}/$original').existsSync(),
          isFalse,
          reason: 'and its database must be unlinked, not merely forgotten',
        );
        expect(
          await dbs.global.workspaceRegistryDao.getById(original),
          isNull,
          reason: 'its registry row goes too, or the id accretes forever',
        );
      },
    );

    test('a visitor is never handed a workspace older than the TTL', () async {
      final service = buildService(
        limits: DemoLimits(poolSize: 1, maxPerIp: 25),
      );
      await service.start();
      addTearDown(service.stop);
      await awaitPool(service, 1);
      final warm = service.pool.single;

      // Jump past the TTL and redeem. The claim path checks staleness itself
      // rather than trusting the 60s sweep to have run first.
      clock = clock.add(const Duration(hours: 3));
      final envelope = await service.redeem(const {
        'code': 'demo',
      }, remoteIp: '10.0.0.11');

      expect(
        envelope['workspace_id'],
        isNot(warm),
        reason: 'the stale warm workspace must not be handed out',
      );
      expect(Directory('${tmp.path}/$warm').existsSync(), isFalse);
    });

    test('a pre-stamp state file is treated as stale, not as fresh', () async {
      // State written before pool entries carried a `seeded_at` is a bare list
      // of ids. Their real age is unknowable, so they are read as expired:
      // reseeding one needlessly is free, shipping a week-old demo is not.
      final first = buildService(limits: DemoLimits(poolSize: 1));
      await first.start();
      await awaitPool(first, 1);
      final legacyId = first.pool.single;
      await first.stop();

      final stateFile = File('${tmp.path}/demo/state.json');
      final raw = jsonDecode(stateFile.readAsStringSync()) as Map;
      expect(
        raw['pool'],
        isNotEmpty,
        reason: 'the pool must survive a clean stop for this to test anything',
      );
      stateFile.writeAsStringSync(
        jsonEncode({
          'pool': [legacyId],
          'visitors': const [],
        }),
      );

      final second = buildService(limits: DemoLimits(poolSize: 1));
      await second.start();
      addTearDown(second.stop);

      expect(
        second.pool,
        isNot(contains(legacyId)),
        reason: 'an unstamped entry is not trusted to be fresh',
      );
      expect(Directory('${tmp.path}/$legacyId').existsSync(), isFalse);
    });
  });

  test('a wrong code is an auth failure, not a capacity one', () async {
    final service = buildService();
    await expectLater(
      service.redeem(const {'code': 'wrong'}),
      throwsA(isA<AuthException>()),
    );
  });

  test('shutdown reaps every live visitor', () async {
    final service = buildService();
    final first = await service.redeem(const {'code': 'demo'});
    final second = await service.redeem(const {'code': 'demo'});

    await service.stop();

    for (final envelope in [first, second]) {
      expect(
        Directory('${tmp.path}/${envelope['workspace_id']}').existsSync(),
        isFalse,
        reason:
            'a restart must never leave a workspace whose owner can no longer '
            'reach it',
      );
    }
    expect(service.visitors, isEmpty);
  });

  test('state survives a restart and orphans self-heal', () async {
    final seeded = <String>[];
    final service = buildService(seededWorkspaces: seeded);
    final envelope = await service.redeem(const {'code': 'demo'});
    final workspaceId = envelope['workspace_id'] as String;

    // A fresh service over the same data dir — the restart case.
    final restarted = buildService();
    await restarted.start();
    addTearDown(restarted.stop);

    expect(
      restarted.visitors.map((v) => v.workspaceId),
      contains(workspaceId),
      reason: 'a live visitor must survive a restart with their time intact',
    );
    expect(
      File('${tmp.path}/demo/state.json').existsSync(),
      isTrue,
      reason: 'bookkeeping lives beside the data, not in workspace_meta',
    );
  });
}
