import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/identity/identity_bootstrap.dart';
import 'package:test/test.dart';
import 'helpers/test_database.dart';

void main() {
  const workspaceId = 'ws-1';
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  /// The workspace whose rows the sentinel-adoption tests seed and assert on.
  /// Identity itself is global; everything it re-attributes lives in a workspace.
  late WorkspaceDatabase db;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    // Force beforeOpen pragmas/index setup before raw inserts.
    await global.customSelect('SELECT 1').get();
    await seedTestWorkspace(global, dbs, workspaceId);
    db = dbs.of(workspaceId);
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

  test('workspaces get ownerUserId + an owner membership', () async {
    await global.workspaceRegistryDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(id: 'ws-1', name: 'One'),
    );
    await global.workspaceRegistryDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(id: 'ws-2', name: 'Two'),
    );
    final ownerId = await run();
    for (final wsId in ['ws-1', 'ws-2']) {
      final rows = await global.select(global.workspacesTable).get();
      expect(
        rows.firstWhere((w) => w.id == wsId).ownerUserId,
        ownerId,
        reason: wsId,
      );
      // The membership row lives in that workspace's OWN database, so the
      // assertion has to open the right one — reading `ws-1`'s file would find
      // nothing for `ws-2` no matter what the bootstrap did.
      final member = await dbs
          .of(wsId)
          .workspaceMemberDao
          .getMember(wsId, ownerId);
      expect(member, isNotNull, reason: wsId);
      expect(member!.role, 'owner', reason: wsId);
    }
  });

  test('legacy devices with no user binding are bound to the owner', () async {
    await global.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion.insert(
        id: 'dev-legacy',
        label: 'Old phone',
        pskRef: 'file',
      ),
    );
    final ownerId = await run();
    final device = await global.pairedDeviceDao.getById('dev-legacy');
    expect(device!.userId, ownerId);
  });

  test('sentinel rows are re-attributed to the owner', () async {
    await global.workspaceRegistryDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(id: 'ws-1', name: 'One'),
    );
    await db
        .into(db.spacesTable)
        .insert(
          const SpacesTableCompanion(
            id: Value('c1'),
            name: Value('General'),
            workspaceId: Value('ws-1'),
          ),
        );
    // The space's conversation, keyed on its own id (never the space id) —
    // messages carry a required conversation_id FK, so it must exist first.
    await db
        .into(db.conversationsTable)
        .insert(
          ConversationsTableCompanion.insert(
            id: 'conv-c1',
            spaceId: 'c1',
            workspaceId: const Value('ws-1'),
          ),
        );
    // The 'user' participant sentinel.
    await db
        .into(db.spaceParticipantsTable)
        .insert(
          const SpaceParticipantsTableCompanion(
            id: Value('p1'),
            spaceId: Value('c1'),
            principalId: Value('user'),
            participantType: Value('agent'),
          ),
        );
    // A human message written before identity existed: senderType 'user',
    // senderId the literal sentinel — and one stamped with a device id.
    for (final (id, sender) in [('m1', 'user'), ('m2', 'desktop-thin-local')]) {
      await db
          .into(db.conversationMessagesTable)
          .insert(
            ConversationMessagesTableCompanion(
              id: Value(id),
              spaceId: const Value('c1'),
              conversationId: const Value('conv-c1'),
              senderId: Value(sender),
              senderType: const Value('user'),
              content: const Value('hello'),
            ),
          );
    }
    // An agent message must stay untouched.
    await db
        .into(db.conversationMessagesTable)
        .insert(
          const ConversationMessagesTableCompanion(
            id: Value('m3'),
            spaceId: Value('c1'),
            conversationId: Value('conv-c1'),
            senderId: Value('agent-7'),
            senderType: Value('agent'),
            content: Value('report'),
          ),
        );
    // A ticket assigned to the sentinel + a sentinel collaborator.
    await db.ticketDao.insert(
      TicketsTableCompanion.insert(
        id: 't1',
        workspaceId: 'ws-1',
        title: 'Fix it',
        assignedAgentId: const Value('user'),
      ),
    );
    await db.ticketDao.addCollaborator(
      const TicketCollaboratorsTableCompanion(
        id: Value('tc1'),
        ticketId: Value('t1'),
        principalId: Value('user'),
        collaboratorType: Value('agent'),
      ),
    );

    final ownerId = await run();

    final participants = await db.select(db.spaceParticipantsTable).get();
    expect(participants.single.principalId, ownerId);
    expect(participants.single.participantType, 'user');

    final messages = await db.select(db.conversationMessagesTable).get();
    final byId = {for (final m in messages) m.id: m};
    expect(byId['m1']!.senderId, ownerId);
    expect(byId['m2']!.senderId, ownerId);
    expect(byId['m3']!.senderId, 'agent-7');

    final tickets = await db.select(db.ticketsTable).get();
    expect(tickets.single.assignedAgentId, ownerId);
    expect(tickets.single.assigneeType, 'user');

    final collaborators = await db.ticketDao.getCollaborators('t1');
    expect(collaborators.single.principalId, ownerId);
    expect(collaborators.single.collaboratorType, 'user');
  });
}
