import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/user_profile_ops.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

/// The username ops: the rule every name goes through, uniqueness at the
/// write and one event per rename.
void main() {
  late GlobalDatabase global;
  late DaoUserRepository users;
  late DomainEventBus bus;
  late List<RepoOp> ops;

  User user(String id, String handle) => User(
    id: id,
    handle: handle,
    displayName: 'User $id',
    createdAt: DateTime.utc(2026),
  );

  setUp(() async {
    global = GlobalDatabase.forTesting(NativeDatabase.memory());
    users = DaoUserRepository(global.userDao);
    bus = DomainEventBus();
    await users.upsert(user('u-1', 'sam'));
    await users.upsert(user('u-2', 'ada'));
    ops = buildUserProfileOps(users: users);
  });

  tearDown(() => global.close());

  RepoOpContext ctx(String userId, [Map<String, dynamic> args = const {}]) =>
      RepoOpContext(
        args: args,
        workspaceId: null,
        deviceId: 'dev-$userId',
        userId: userId,
      );

  Future<Map<String, Object?>> run(
    String name,
    String userId, [
    Map<String, dynamic> args = const {},
  ]) async =>
      (await ops.singleWhere((o) => o.name == name).handler(ctx(userId, args)))
          as Map<String, Object?>;

  Matcher refused(UsernameRefusal reason) => throwsA(
    isA<UsernameRefusedException>().having((e) => e.reason, 'reason', reason),
  );

  test('the op is an unscoped, self-service read that names nobody', () {
    expect(ops.map((o) => o.name), ['users.checkHandle']);
    for (final op in ops) {
      expect(op.workspaceScoped, isFalse, reason: op.name);
      expect(op.kind, RepoOpKind.read, reason: op.name);
      expect(op.minRole, isNull, reason: op.name);
    }
  });

  group('users.checkHandle', () {
    Future<Map<String, Object?>> check(String userId, String handle) =>
        run('users.checkHandle', userId, {'handle': handle});

    test('a free valid name is available, normalised', () async {
      expect(await check('u-1', '  Grace '), {
        'available': true,
        'normalized': 'grace',
      });
    });

    test('the caller\'s own name is available to them', () async {
      expect((await check('u-1', 'SAM'))['available'], isTrue);
    });

    test('taken, invalid and reserved answer with a reason', () async {
      expect(await check('u-1', 'ada'), {
        'available': false,
        'normalized': 'ada',
        'reason': 'taken',
      });
      expect((await check('u-1', 'a'))['reason'], 'invalid');
      expect((await check('u-1', 'sam smith'))['reason'], 'invalid');
      expect((await check('u-1', 'Everyone'))['reason'], 'reserved');
    });

    test('a missing handle is a plain validation error', () async {
      await expectLater(
        run('users.checkHandle', 'u-1'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e,
            'not a username refusal',
            isNot(isA<UsernameRefusedException>()),
          ),
        ),
      );
    });
  });

  group('users.updateProfile (updateOwnProfile)', () {
    late List<UserProfileChanged> events;

    setUp(() {
      events = [];
      bus.on<UserProfileChanged>().listen(events.add);
    });

    Future<Map<String, Object?>> update(
      String userId,
      Map<String, dynamic> args,
    ) => updateOwnProfile(
      ctx(userId, args),
      users: users,
      serverOwnerUserId: 'u-owner',
      eventBus: bus,
    );

    test('renames the caller, normalised, and announces it once', () async {
      final result = await update('u-1', {
        'handle': ' Grace.H ',
        'display_name': ' Grace ',
      });
      expect((result['user']! as Map)['handle'], 'grace.h');
      expect((result['user']! as Map)['display_name'], 'Grace');
      expect((await users.getById('u-1'))!.handle, 'grace.h');
      await pumpEventQueue();
      expect(events, hasLength(1));
      expect(events.single.userId, 'u-1');
      expect(events.single.previousHandle, 'sam');
      expect(events.single.handle, 'grace.h');
      expect(events.single.renamed, isTrue);
      expect(events.single.displayName, 'Grace');
    });

    test('the rename reaches the presence roster through the event', () async {
      final presence = PresenceHub();
      addTearDown(presence.dispose);
      // The runtime's wiring, verbatim.
      bus.on<UserProfileChanged>().listen(
        (change) => presence.renameUser(change.userId, change.displayName),
      );
      presence.publishHuman(
        workspaceId: 'ws-1',
        userId: 'u-1',
        displayName: 'User u-1',
        update: const {'a': 'active'},
      );
      await update('u-1', {'display_name': 'Grace'});
      await pumpEventQueue();
      expect(
        await presence.displayNameFor('u-1', () async => 'stale lookup'),
        'Grace',
      );
    });

    test('nothing changed, nothing announced', () async {
      await update('u-1', {'handle': 'sam', 'email': 'sam@example.com'});
      await pumpEventQueue();
      expect(events, isEmpty);
    });

    test(
      'refuses a taken, invalid or reserved name and writes nothing',
      () async {
        await expectLater(
          update('u-1', {'handle': 'ADA', 'display_name': 'X'}),
          refused(UsernameRefusal.taken),
        );
        await expectLater(
          update('u-1', {'handle': 'a b'}),
          refused(UsernameRefusal.invalid),
        );
        await expectLater(
          update('u-1', {'handle': 'here'}),
          refused(UsernameRefusal.reserved),
        );
        final stored = (await users.getById('u-1'))!;
        expect(stored.handle, 'sam');
        expect(stored.displayName, 'User u-1');
        await pumpEventQueue();
        expect(events, isEmpty);
      },
    );

    test('a refusal reaches the client as validation + data.kind', () async {
      for (final reason in UsernameRefusal.values) {
        final mapped = mapAppExceptionToRpc(UsernameRefusedException(reason))!;
        expect(mapped.code, RpcErrorCodes.validation);
        expect(mapped.data, {'kind': reason.errorKind});
      }
    });

    test('self-service: no argument reaches another user', () async {
      await update('u-1', {
        'user_id': 'u-2',
        'id': 'u-2',
        'display_name': 'Mine',
      });
      expect((await users.getById('u-2'))!.displayName, 'User u-2');
      expect((await users.getById('u-1'))!.displayName, 'Mine');
    });

    test('two people racing for one name: exactly one gets it', () async {
      final outcomes = await Future.wait([
        for (final id in ['u-1', 'u-2'])
          update(id, {'handle': 'grace'}).then(
            (_) => 'ok',
            onError: (Object e) => (e as UsernameRefusedException).reason.wire,
          ),
      ]);
      expect(outcomes..sort(), ['ok', 'taken']);
      final all = await users.getAll();
      expect(all.where((u) => u.handle == 'grace'), hasLength(1));
    });
  });
}
