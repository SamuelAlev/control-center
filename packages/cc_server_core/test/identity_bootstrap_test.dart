import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/identity/identity_bootstrap.dart';
import 'package:test/test.dart';
import 'helpers/test_database.dart';

void main() {
  const workspaceId = 'ws-1';
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    // Force beforeOpen pragmas/index setup before raw inserts.
    await global.customSelect('SELECT 1').get();
    await seedTestWorkspace(global, dbs, workspaceId);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Future<String> run({Map<String, String> env = const {}}) => IdentityBootstrap(
    global: global,
    workspaces: dbs,
    environment: env,
  ).run();

  test(
    'first boot mints the owner from the OS account (first-user-is-admin)',
    () async {
      // The OS account name is the only hint taken from the environment, and it
      // is a display default: the name and email are edited in Settings, which
      // is where someone looking at them would change them.
      final ownerId = await run(env: {'USER': 'Sam Alev!'});
      final users = await global.userDao.getAll();
      expect(users, hasLength(1));
      expect(users.single.id, ownerId);
      // The handle is sanitized to a mention-safe slug.
      expect(users.single.handle, 'sam-alev');
      expect(users.single.displayName, 'sam-alev');
      expect(users.single.email, isNull);
    },
  );

  test('re-running never mints a second owner (idempotent)', () async {
    final first = await run();
    final second = await run();
    expect(second, first);
    expect(await global.userDao.count(), 1);
  });

  test('the minted owner is recorded, and a later account with an earlier '
      'creation time never replaces it', () async {
    final ownerId = await run();
    expect(
      await global.workspaceRouteDao.meta(GlobalDatabase.serverOwnerKey),
      ownerId,
    );
    // An account created while the clock was wrong (or by a restore) sorts
    // before the owner by creation time; the record still answers.
    await global.userDao.upsert(
      UsersTableCompanion.insert(
        id: 'user-early',
        handle: 'early',
        displayName: 'Early',
        createdAt: Value(DateTime(2000)),
      ),
    );
    expect((await global.userDao.getAll()).first.id, 'user-early');
    expect(await run(), ownerId);
  });

  test('accounts without a recorded owner never become the owner', () async {
    await global.userDao.upsert(
      UsersTableCompanion.insert(
        id: 'user-first',
        handle: 'first',
        displayName: 'First',
        createdAt: Value(DateTime(2024)),
      ),
    );
    final ownerId = await run();
    expect(ownerId, isNot('user-first'));
    expect(
      await global.workspaceRouteDao.meta(GlobalDatabase.serverOwnerKey),
      ownerId,
    );
    expect(await global.userDao.count(), 2);
  });

  test("a workspace's recorded owner gets an owner membership; an ownerless "
      'workspace grants nobody', () async {
    final ownerId = await run();
    await global.workspaceRegistryDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(
        id: 'ws-1',
        name: 'One',
        ownerUserId: Value(ownerId),
      ),
    );
    await global.workspaceRegistryDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(id: 'ws-2', name: 'Two'),
    );
    await run();

    // The membership row lives in that workspace's OWN database.
    final member = await dbs
        .of('ws-1')
        .workspaceMemberDao
        .getMember('ws-1', ownerId);
    expect(member?.role, 'owner');

    final rows = await global.select(global.workspacesTable).get();
    expect(rows.firstWhere((w) => w.id == 'ws-2').ownerUserId, isNull);
    expect(
      await dbs.of('ws-2').workspaceMemberDao.getMember('ws-2', ownerId),
      isNull,
    );
  });
}
