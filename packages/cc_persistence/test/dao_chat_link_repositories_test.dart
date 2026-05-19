import 'package:cc_domain/features/chat_bridge/domain/entities/chat_space_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_user_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_link_method.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// The chat-bridge link repositories against the real Drift databases.
///
/// Three properties carry weight beyond the round-trip. The links are the
/// bridge's only memory of *who* an external chat account is and *where* a
/// thread goes, so a cross-workspace read here would let one workspace's chat
/// app act inside another; both tables are unique on their external key, so a
/// bridge that re-links an existing thread must update the row rather than
/// collide; and every key carries `provider`, so two providers whose id spaces
/// overlap cannot resolve each other's conversations.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoChatSpaceLinkRepository spaces;
  late DaoChatUserLinkRepository users;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    spaces = DaoChatSpaceLinkRepository(dbs);
    users = DaoChatUserLinkRepository(dbs);
    // `cc_space_id` is a real foreign key (deleting the space unbridges the
    // external thread), so the spaces have to exist before a link can point
    // at them.
    for (final workspaceId in ['w-1', 'w-2']) {
      final db = dbs.of(workspaceId);
      for (final spaceId in ['chan-1', 'chan-2']) {
        await db
            .into(db.spacesTable)
            .insert(
              SpacesTableCompanion.insert(
                id: spaceId,
                name: 'Bridged $spaceId',
                workspaceId: Value(workspaceId),
              ),
            );
      }
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  group('DaoChatSpaceLinkRepository', () {
    test(
      'round-trips a thread link and reads it from both directions',
      () async {
        await spaces.upsert(_spaceLink());

        final byThread = await spaces.forExternalThread(
          'w-1',
          provider: ChatProvider.slack,
          externalChannelId: 'C1',
          externalThreadId: '1700.1',
        );
        expect(byThread?.id, 'cl-1');
        expect(byThread?.provider, ChatProvider.slack);
        expect(byThread?.externalTeamId, 'T1');
        expect(byThread?.externalThreadId, '1700.1');
        expect(byThread?.ccSpaceId, 'chan-1');
        expect(byThread?.createdByUserId, 'u-1');
        expect(byThread?.createdAt.toUtc(), DateTime.utc(2026));
        // The reverse lookup is how an agent turn finds its external thread.
        expect((await spaces.forCcSpace('w-1', 'chan-1'))?.id, 'cl-1');
        expect(await spaces.forWorkspace('w-1'), hasLength(1));
        expect(
          await spaces.forWorkspace('w-1', provider: ChatProvider.slack),
          hasLength(1),
        );
      },
    );

    test('a DM link (null thread) is distinct from a thread link', () async {
      await spaces.upsert(_spaceLink(threadId: null, id: 'cl-dm'));
      await spaces.upsert(_spaceLink(id: 'cl-thread'));

      expect(
        (await spaces.forExternalThread(
          'w-1',
          provider: ChatProvider.slack,
          externalChannelId: 'C1',
        ))?.id,
        'cl-dm',
      );
      expect(
        (await spaces.forExternalThread(
          'w-1',
          provider: ChatProvider.slack,
          externalChannelId: 'C1',
          externalThreadId: '1700.1',
        ))?.id,
        'cl-thread',
      );
    });

    test('re-linking the same thread updates instead of colliding', () async {
      await spaces.upsert(_spaceLink());
      await spaces.upsert(
        _spaceLink(ccSpaceId: 'chan-2', lastActivityAt: DateTime.utc(2026, 2)),
      );

      final rows = await spaces.forWorkspace('w-1');
      expect(rows, hasLength(1));
      expect(rows.single.ccSpaceId, 'chan-2');
      expect(rows.single.lastActivityAt.toUtc(), DateTime.utc(2026, 2));
    });

    test('links do not leak across workspaces', () async {
      await spaces.upsert(_spaceLink());
      // The same external thread bridged in a second workspace is a separate
      // row in a separate file — and neither can see the other.
      await spaces.upsert(
        _spaceLink(id: 'cl-2', workspaceId: 'w-2', ccSpaceId: 'chan-2'),
      );

      expect(await spaces.forWorkspace('w-1'), hasLength(1));
      expect(await spaces.forWorkspace('w-2'), hasLength(1));
      expect(
        (await spaces.forExternalThread(
          'w-2',
          provider: ChatProvider.slack,
          externalChannelId: 'C1',
          externalThreadId: '1700.1',
        ))?.ccSpaceId,
        'chan-2',
      );
      // w-1's space id is not addressable from w-2.
      expect(await spaces.forCcSpace('w-2', 'chan-1'), isNull);
    });

    test('delete is scoped to the workspace', () async {
      await spaces.upsert(_spaceLink());

      expect(await spaces.delete('cl-1', workspaceId: 'w-2'), 0);
      expect(await spaces.forWorkspace('w-1'), hasLength(1));
      expect(await spaces.delete('cl-1', workspaceId: 'w-1'), 1);
      expect(await spaces.forWorkspace('w-1'), isEmpty);
    });

    test('deleting the Control Center space unbridges the thread', () async {
      await spaces.upsert(_spaceLink());
      final db = dbs.of('w-1');

      await (db.delete(
        db.spacesTable,
      )..where((t) => t.id.equals('chan-1'))).go();

      // The cascade is what lets the next @mention open a fresh space instead
      // of resolving to a link pointing at nothing.
      expect(await spaces.forWorkspace('w-1'), isEmpty);
    });
  });

  group('DaoChatUserLinkRepository', () {
    test('round-trips a link and reads it from both directions', () async {
      await users.upsert(_userLink());

      final byExternal = await users.forExternalUser(
        'w-1',
        provider: ChatProvider.slack,
        externalTeamId: 'T1',
        externalUserId: 'U1',
      );
      expect(byExternal?.id, 'ul-1');
      expect(byExternal?.userId, 'u-1');
      expect(byExternal?.provider, ChatProvider.slack);
      expect(byExternal?.method, ChatLinkMethod.email);
      expect(byExternal?.linkedAt.toUtc(), DateTime.utc(2026));
      expect(
        (await users.forUser(
          'w-1',
          'u-1',
          provider: ChatProvider.slack,
        ))?.externalUserId,
        'U1',
      );
    });

    test('re-linking the same external member replaces the mapping', () async {
      await users.upsert(_userLink());
      // The same chat account claimed by a different Control Center user (a
      // laptop handover, a corrected link) must not leave two rows behind.
      await users.upsert(
        _userLink(id: 'ul-2', userId: 'u-2', method: ChatLinkMethod.code),
      );

      final rows = await users.forWorkspace('w-1');
      expect(rows, hasLength(1));
      expect(rows.single.userId, 'u-2');
      expect(rows.single.method, ChatLinkMethod.code);
    });

    test('a link in another workspace is invisible here', () async {
      await users.upsert(_userLink(workspaceId: 'w-2'));

      expect(
        await users.forExternalUser(
          'w-1',
          provider: ChatProvider.slack,
          externalTeamId: 'T1',
          externalUserId: 'U1',
        ),
        isNull,
      );
      expect(
        await users.forUser('w-1', 'u-1', provider: ChatProvider.slack),
        isNull,
      );
      expect(await users.forWorkspace('w-1'), isEmpty);
      expect(await users.forWorkspace('w-2'), hasLength(1));
    });

    test('unlinking is scoped and the roster stream reports it', () async {
      await users.upsert(_userLink());
      final seen = users.watchForWorkspace('w-1');

      expect(
        await users.deleteForUser('w-2', 'u-1', provider: ChatProvider.slack),
        0,
      );
      expect(
        await users.deleteForUser('w-1', 'u-1', provider: ChatProvider.slack),
        1,
      );
      expect(await users.forWorkspace('w-1'), isEmpty);
      await expectLater(seen, emitsThrough(isEmpty));
    });
  });
}

ChatSpaceLink _spaceLink({
  String id = 'cl-1',
  String workspaceId = 'w-1',
  String ccSpaceId = 'chan-1',
  String? threadId = '1700.1',
  DateTime? lastActivityAt,
}) => ChatSpaceLink(
  id: id,
  workspaceId: workspaceId,
  provider: ChatProvider.slack,
  externalTeamId: 'T1',
  externalChannelId: 'C1',
  externalThreadId: threadId,
  ccSpaceId: ccSpaceId,
  createdByUserId: 'u-1',
  createdAt: DateTime.utc(2026),
  lastActivityAt: lastActivityAt ?? DateTime.utc(2026),
);

ChatUserLink _userLink({
  String id = 'ul-1',
  String workspaceId = 'w-1',
  String userId = 'u-1',
  ChatLinkMethod method = ChatLinkMethod.email,
}) => ChatUserLink(
  id: id,
  workspaceId: workspaceId,
  provider: ChatProvider.slack,
  externalTeamId: 'T1',
  externalUserId: 'U1',
  userId: userId,
  method: method,
  linkedAt: DateTime.utc(2026),
);
