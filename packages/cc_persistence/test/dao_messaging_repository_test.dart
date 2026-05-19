import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  /// `ws-1`'s own database file — where every space/message below lands and
  /// what the direct-table assertions read back.
  late WorkspaceDatabase db;
  late DaoMessagingRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    // Registered so the cross-workspace `watchSpaces()` fan-out can see it.
    await seedTestWorkspace(global, dbs, 'ws-1');
    db = dbs.of('ws-1');
    repo = DaoMessagingRepository(dbs);

    for (var i = 1; i <= 3; i++) {
      await db
          .into(db.agentsTable)
          .insert(
            AgentsTableCompanion(
              id: Value('agent-$i'),
              name: Value('Agent $i'),
              title: Value('Test Agent $i'),
              agentMdPath: const Value(''),
              skills: const Value(''),
              workspaceId: const Value('ws-1'),
            ),
          );
    }
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  group('createSpace', () {
    test('creates a space', () async {
      final space = await repo.createSpace('ws-1', 'Team Chat', [
        'agent-1',
        'agent-2',
      ]);

      expect(space.id, isNotEmpty);
      expect(space.name, 'Team Chat');
    });

    test('adds creating user and all agents as participants', () async {
      final space = await repo.createSpace('ws-1', 'Team', [
        'agent-1',
        'agent-2',
      ], createdByUserId: 'user-1');
      final participants = await repo.getParticipants('ws-1', space.id);

      final principalIds = participants.map((p) => p.principalId).toList();
      expect(principalIds, contains('user-1'));
      expect(principalIds, contains('agent-1'));
      expect(principalIds, contains('agent-2'));
      expect(participants.length, 3);
    });

    test('creates space with single agent and no user when createdByUserId '
        'is null', () async {
      final space = await repo.createSpace('ws-1', 'Solo', ['agent-1']);
      final participants = await repo.getParticipants('ws-1', space.id);

      expect(participants.length, 1);
      expect(participants.single.principalId, 'agent-1');
      expect(participants.single.isUser, isFalse);
    });

    test('creates space with no agents', () async {
      final space = await repo.createSpace(
        'ws-1',
        'Empty',
        [],
        createdByUserId: 'user-1',
      );
      final participants = await repo.getParticipants('ws-1', space.id);

      expect(participants.length, 1);
      expect(participants.first.principalId, 'user-1');
      expect(participants.first.isUser, isTrue);
    });

    test('records a scoped repo selection for provisioning', () async {
      await db
          .into(db.reposTable)
          .insert(
            ReposTableCompanion.insert(id: 'r-1', name: 'o/r1', path: '/r1'),
          );
      await db
          .into(db.reposTable)
          .insert(
            ReposTableCompanion.insert(id: 'r-2', name: 'o/r2', path: '/r2'),
          );

      final space = await repo.createSpace(
        'ws-1',
        'Scoped',
        [],
        repoIds: const ['r-1'],
      );

      expect(await db.spaceRepoDao.repoIdsForSpace('ws-1', space.id), ['r-1']);
    });

    test('refuses a repo id that is not registered in the workspace', () async {
      // A foreign (or stale) repo id must never land in space_repos: the
      // provisioner would clone a repo this workspace does not own.
      await expectLater(
        repo.createSpace('ws-1', 'Foreign', [], repoIds: const ['r-x']),
        throwsA(isA<ValidationException>()),
      );
    });

    test('an EMPTY repo selection sets the noRepos flag', () async {
      // "No rows in space_repos" already means "all repos", so a space
      // created with every repo deselected carries its own flag instead.
      final space = await repo.createSpace(
        'ws-1',
        'No repos',
        [],
        repoIds: const [],
      );

      final row = await db.messagingDao.getSpaceById(space.id);
      expect(row?.noRepos, isTrue);
      expect(await db.spaceRepoDao.repoIdsForSpace('ws-1', space.id), isEmpty);
    });

    test('a null repo selection stays on the all-repos default', () async {
      final space = await repo.createSpace('ws-1', 'All repos', []);

      final row = await db.messagingDao.getSpaceById(space.id);
      expect(row?.noRepos, isFalse);
      expect(await db.spaceRepoDao.repoIdsForSpace('ws-1', space.id), isEmpty);
    });
  });

  group('addParticipant', () {
    test('adds agent to space', () async {
      final space = await repo.createSpace('ws-1', 'Group', []);

      await repo.addParticipant('ws-1', space.id, 'agent-3');

      final participants = await repo.getParticipants('ws-1', space.id);
      final principalIds = participants.map((p) => p.principalId).toList();
      expect(principalIds, contains('agent-3'));
    });
  });

  group('getParticipants', () {
    test('returns participants for a space', () async {
      final space = await repo.createSpace('ws-1', 'Chat', [
        'agent-1',
      ], createdByUserId: 'user-1');
      final participants = await repo.getParticipants('ws-1', space.id);

      expect(participants.length, 2);
      expect(participants.every((p) => p.spaceId == space.id), isTrue);
    });

    test('returns empty list for space with no participants', () async {
      final participants = await repo.getParticipants('ws-1', 'non-existent');
      expect(participants, isEmpty);
    });
  });

  group('sendMessage', () {
    test('sends a message to a space', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);

      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'Hello',
        senderId: 'user',
        senderType: 'user',
      );

      final messages = await repo.getMessages('ws-1', space.id);
      expect(messages.length, 1);
      expect(messages.first.content, 'Hello');
      expect(messages.first.messageType.name, 'text');
    });

    test('sends multiple messages in order', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);

      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'First',
        senderId: 'user',
        senderType: 'user',
      );
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'Second',
        senderId: 'agent-1',
        senderType: 'agent',
      );

      final messages = await repo.getMessages('ws-1', space.id);
      expect(messages.length, 2);
    });

    test('sends a message with metadata', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);

      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'System',
        senderId: 'system',
        senderType: 'agent',
        messageType: 'system',
        metadata: {'key': 'value'},
      );

      final messages = await repo.getMessages('ws-1', space.id);
      expect(messages.first.metadata, {'key': 'value'});
    });

    test('uses provided message id', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);

      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'Custom ID',
        senderId: 'user',
        senderType: 'user',
        id: 'custom-id-123',
      );

      final messages = await repo.getMessages('ws-1', space.id);
      expect(messages.first.id, 'custom-id-123');
    });
  });

  group('updateMessage', () {
    test('updates message content', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'Original',
        senderId: 'agent-1',
        senderType: 'agent',
      );

      final messages = await repo.getMessages('ws-1', space.id);
      final msgId = messages.first.id;

      await repo.updateMessage('ws-1', msgId, content: 'Updated');

      final updated = await repo.getMessages('ws-1', space.id);
      expect(updated.first.content, 'Updated');
    });

    test('updates message metadata', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'Message',
        senderId: 'agent-1',
        senderType: 'agent',
        messageType: 'thinking',
      );

      final messages = await repo.getMessages('ws-1', space.id);
      final msgId = messages.first.id;

      await repo.updateMessage('ws-1', msgId, metadata: {'done': true});

      final updated = await repo.getMessages('ws-1', space.id);
      expect(updated.first.metadata, {'done': true});
    });
  });

  group('markCompacted', () {
    test('marks messages as compacted', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'Msg 1',
        senderId: 'user',
        senderType: 'user',
      );
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'Msg 2',
        senderId: 'agent-1',
        senderType: 'agent',
      );

      final messages = await repo.getMessages('ws-1', space.id);
      final ids = messages.map((m) => m.id).toList();

      await repo.markCompacted('ws-1', ids);

      final compacted = await repo.getMessages('ws-1', space.id);
      expect(compacted.every((m) => m.compacted), isTrue);
    });
  });

  group('deleteSpace', () {
    test('deletes space', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.deleteSpace('ws-1', space.id);

      final spaces = await (db.select(
        db.spacesTable,
      )..where((t) => t.id.equals(space.id))).get();
      expect(spaces, isEmpty);
    });
  });

  group('archiveSpace', () {
    test('archive then restore keeps the row and its data', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      expect(space.isArchived, isFalse);

      await repo.archiveSpace('ws-1', space.id);
      var row = await (db.select(
        db.spacesTable,
      )..where((t) => t.id.equals(space.id))).getSingle();
      expect(row.archivedAt, isNotNull);

      // The domain read carries the flag (the client filters on it).
      final archived = await repo.getSpaceById('ws-1', space.id);
      expect(archived!.isArchived, isTrue);
      expect(archived.archivedAt, isNotNull);

      await repo.unarchiveSpace('ws-1', space.id);
      row = await (db.select(
        db.spacesTable,
      )..where((t) => t.id.equals(space.id))).getSingle();
      expect(row.archivedAt, isNull);

      final restored = await repo.getSpaceById('ws-1', space.id);
      expect(restored!.isArchived, isFalse);
    });

    test('archiving does not touch updatedAt (restores at its recency '
        'position)', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      final before = (await (db.select(
        db.spacesTable,
      )..where((t) => t.id.equals(space.id))).getSingle()).updatedAt;

      await repo.archiveSpace('ws-1', space.id);
      await repo.unarchiveSpace('ws-1', space.id);

      final after = (await (db.select(
        db.spacesTable,
      )..where((t) => t.id.equals(space.id))).getSingle()).updatedAt;
      expect(after, before);
    });

    test('unarchiving a space that is not archived is a no-op', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);

      await repo.unarchiveSpace('ws-1', space.id);

      final row = await (db.select(
        db.spacesTable,
      )..where((t) => t.id.equals(space.id))).getSingle();
      expect(row.archivedAt, isNull);
    });
  });

  group('updateSpaceName', () {
    test('updates space name', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.updateSpaceName('ws-1', space.id, 'New Name');

      final spaces = await (db.select(
        db.spacesTable,
      )..where((t) => t.id.equals(space.id))).get();
      expect(spaces.single.name, 'New Name');
    });
  });

  group('setSpaceRepos', () {
    setUp(() async {
      for (final id in ['r-1', 'r-2', 'r-3']) {
        await db
            .into(db.reposTable)
            .insert(
              ReposTableCompanion.insert(id: id, name: 'o/$id', path: '/s/$id'),
            );
      }
    });

    test('a fresh space reads as all-repos (null)', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      expect(await repo.spaceRepoSelection('ws-1', space.id), isNull);
    });

    test('a subset selection round-trips and replaces', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);

      await repo.setSpaceRepos('ws-1', space.id, ['r-1', 'r-2']);
      expect(await repo.spaceRepoSelection('ws-1', space.id), ['r-1', 'r-2']);

      await repo.setSpaceRepos('ws-1', space.id, ['r-3']);
      expect(await repo.spaceRepoSelection('ws-1', space.id), ['r-3']);
      // The replaced rows left no residue behind.
      expect(
        await db.spaceRepoDao.repoIdsForSpace('ws-1', space.id),
        ['r-3'],
      );
      expect((await db.messagingDao.getSpaceById(space.id))!.noRepos, isFalse);
    });

    test('an empty selection is an explicit none, not the all-repos default',
        () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);

      await repo.setSpaceRepos('ws-1', space.id, const []);

      expect(await repo.spaceRepoSelection('ws-1', space.id), isEmpty);
      expect((await db.messagingDao.getSpaceById(space.id))!.noRepos, isTrue);
    });

    test('null restores the all-repos default from an explicit none',
        () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.setSpaceRepos('ws-1', space.id, const []);
      expect(await repo.spaceRepoSelection('ws-1', space.id), isEmpty);

      await repo.setSpaceRepos('ws-1', space.id, null);

      expect(await repo.spaceRepoSelection('ws-1', space.id), isNull);
      expect((await db.messagingDao.getSpaceById(space.id))!.noRepos, isFalse);
    });

    test('a foreign or unknown repo id is refused before any write', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.setSpaceRepos('ws-1', space.id, ['r-1']);

      await expectLater(
        repo.setSpaceRepos('ws-1', space.id, ['r-1', 'r-foreign']),
        throwsA(isA<ValidationException>()),
      );
      // The failed write left the prior selection untouched.
      expect(await repo.spaceRepoSelection('ws-1', space.id), ['r-1']);
    });
  });

  group('clearSpaceMessages', () {
    test('clears all messages from a space', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'Message',
        senderId: 'user',
        senderType: 'user',
      );

      await repo.clearSpaceMessages('ws-1', space.id);

      final messages = await repo.getMessages('ws-1', space.id);
      expect(messages, isEmpty);
    });
  });

  group('removeParticipant', () {
    test('removes participant from space', () async {
      final space = await repo.createSpace('ws-1', 'Group', [
        'agent-1',
        'agent-2',
      ]);

      await repo.removeParticipant('ws-1', space.id, 'agent-1');

      final participants = await repo.getParticipants('ws-1', space.id);
      final principalIds = participants.map((p) => p.principalId).toList();
      expect(principalIds, isNot(contains('agent-1')));
      expect(principalIds, contains('agent-2'));
    });
  });

  group('spaceExists & getSpaceById & getMessageById', () {
    test('spaceExists is true for an existing space', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      expect(await repo.spaceExists('ws-1', space.id), isTrue);
      expect(await repo.spaceExists('ws-1', 'no-such'), isFalse);
    });

    test('getSpaceById returns null for unknown id', () async {
      expect(await repo.getSpaceById('ws-1', 'no-such'), isNull);
    });

    test('getSpaceById returns the space', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      final loaded = await repo.getSpaceById('ws-1', space.id);
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Chat');
    });

    test('getMessageById returns null for unknown id', () async {
      expect(await repo.getMessageById('ws-1', 'no-such'), isNull);
    });

    test('getMessageById returns the message', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'hi',
        senderId: 'user',
        senderType: 'user',
      );
      final messages = await repo.getMessages('ws-1', space.id);
      final loaded = await repo.getMessageById('ws-1', messages.first.id);
      expect(loaded, isNotNull);
      expect(loaded!.content, 'hi');
    });
  });

  group('ensureStandingConversation', () {
    test(
      'is idempotent — the same space hands back one conversation',
      () async {
        final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
        final first = await repo.ensureStandingConversation('ws-1', space.id);
        final second = await repo.ensureStandingConversation('ws-1', space.id);
        expect(second, first);
      },
    );

    test(
      'names the space that does not exist instead of failing on the FK',
      () async {
        // A CONVERSATION id in the space slot is the mistake that actually
        // happens (the two ids used to be aliased to one value). Minting a
        // conversation whose `space_id` points at a conversation used to raise a
        // bare `FOREIGN KEY constraint failed` naming neither column nor id.
        final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
        final conversationId = await repo.ensureStandingConversation(
          'ws-1',
          space.id,
        );

        expect(
          () => repo.ensureStandingConversation('ws-1', conversationId),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              allOf(contains(conversationId), contains('no such space')),
            ),
          ),
        );
      },
    );
  });

  group('addParticipant with explicit type', () {
    test('adds a user participant', () async {
      final space = await repo.createSpace('ws-1', 'Chat', []);
      await repo.addParticipant(
        'ws-1',
        space.id,
        'user-9',
        participantType: PrincipalType.user,
      );
      final participants = await repo.getParticipants('ws-1', space.id);
      final added = participants.firstWhere((p) => p.principalId == 'user-9');
      expect(added.isUser, isTrue);
    });
  });

  group('watch streams', () {
    test('watchSpaces emits spaces', () async {
      await repo.createSpace('ws-1', 'A', []);
      final spaces = await repo.watchSpaces().first;
      expect(spaces.map((c) => c.name), contains('A'));
    });

    test('watchParticipants emits participants', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      final participants = await repo.watchParticipants('ws-1', space.id).first;
      expect(participants.map((p) => p.principalId), contains('agent-1'));
    });

    test('watchSpacesByWorkspace filters by workspace', () async {
      // Seed through ws-9's own database — the workspace id now routes to a
      // file before the DAO's `WHERE workspace_id = ?` even runs, so the
      // `ws-other` read below proves the routing rather than the filter.
      final ws9 = dbs.of('ws-9');
      await ws9
          .into(ws9.spacesTable)
          .insert(
            const SpacesTableCompanion(
              id: Value('ws-ch'),
              name: Value('Scoped'),
              workspaceId: Value('ws-9'),
            ),
          );
      final spaces = await repo.watchSpacesByWorkspace('ws-9').first;
      expect(spaces.map((c) => c.id), contains('ws-ch'));
      final other = await repo.watchSpacesByWorkspace('ws-other').first;
      expect(other.map((c) => c.id), isNot(contains('ws-ch')));
    });

    test('watchMessages emits newly sent messages', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      unawaited(
        expectLater(
          repo.watchMessages(
            'ws-1',
            space.id,
            await repo.ensureStandingConversation('ws-1', space.id),
          ),
          emitsInOrder([
            isEmpty,
            predicate<List<Message>>(
              (list) => list.length == 1 && list.first.content == 'hi',
            ),
          ]),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'hi',
        senderId: 'user',
        senderType: 'user',
      );
    });

    test('watchMessages returns the conversation in order', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'first',
        senderId: 'user',
        senderType: 'user',
        id: 'p1',
      );
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'second',
        senderId: 'agent-1',
        senderType: 'agent',
        id: 'r1',
      );
      final all = await repo
          .watchMessages(
            'ws-1',
            space.id,
            await repo.ensureStandingConversation('ws-1', space.id),
          )
          .first;
      expect(all.map((m) => m.id), ['p1', 'r1']);
    });

    test('watchTopLevelMessagesWindow trims to the newest limit', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      for (var i = 0; i < 5; i++) {
        await repo.sendMessage(
          workspaceId: 'ws-1',
          spaceId: space.id,
          content: 'm$i',
          senderId: 'user',
          senderType: 'user',
          id: 'm$i',
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      final window = await repo
          .watchMessagesWindow(
            'ws-1',
            space.id,
            await repo.ensureStandingConversation('ws-1', space.id),
            limit: 3,
          )
          .first;
      expect(window.hasMore, isTrue);
      expect(window.messages, hasLength(3));
      // Oldest-first; the newest 3 are m2..m4.
      expect(window.messages.first.content, 'm2');
      expect(window.messages.last.content, 'm4');
    });

    test(
      'watchTopLevelMessagesWindow hasMore is false under the limit',
      () async {
        final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
        await repo.sendMessage(
          workspaceId: 'ws-1',
          spaceId: space.id,
          content: 'only',
          senderId: 'user',
          senderType: 'user',
        );
        final window = await repo
            .watchMessagesWindow(
              'ws-1',
              space.id,
              await repo.ensureStandingConversation('ws-1', space.id),
              limit: 3,
            )
            .first;
        expect(window.hasMore, isFalse);
        expect(window.messages, hasLength(1));
      },
    );
  });

  group('searchInSpace', () {
    test('returns matching messages', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'deploy the service',
        senderId: 'user',
        senderType: 'user',
      );
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'unrelated note',
        senderId: 'agent-1',
        senderType: 'agent',
      );
      final hits = await repo.searchInSpace('ws-1', space.id, 'deploy');
      expect(hits, hasLength(1));
      expect(hits.first.content, 'deploy the service');
    });

    test('returns empty for no usable tokens', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      final hits = await repo.searchInSpace('ws-1', space.id, '   ');
      expect(hits, isEmpty);
    });
  });

  group('getTopLevelMessagePage (backfill)', () {
    test('paginates and reports hasMore / nextCursor', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      for (var i = 0; i < 5; i++) {
        await repo.sendMessage(
          workspaceId: 'ws-1',
          spaceId: space.id,
          content: 'm$i',
          senderId: 'user',
          senderType: 'user',
          id: 'm$i',
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      final page1 = await repo.getMessagePage(
        'ws-1',
        space.id,
        await repo.ensureStandingConversation('ws-1', space.id),
        limit: 2,
      );
      expect(page1.hasMore, isTrue);
      expect(page1.messages, hasLength(2));
      expect(page1.nextCursor, isNotNull);

      final page2 = await repo.getMessagePage(
        'ws-1',
        space.id,
        await repo.ensureStandingConversation('ws-1', space.id),
        limit: 2,
        cursor: page1.nextCursor,
      );
      expect(page2.messages, isNotEmpty);
    });

    test(
      'backfills to a user-message boundary when the oldest is an agent msg',
      () async {
        final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
        // Seed: user, agent, agent, agent — a page of 2 ending in an agent msg
        // must pull older rows until it reaches the user message.
        await repo.sendMessage(
          workspaceId: 'ws-1',
          spaceId: space.id,
          content: 'user-q',
          senderId: 'user',
          senderType: 'user',
          id: 'm0',
        );
        for (var i = 1; i <= 3; i++) {
          await repo.sendMessage(
            workspaceId: 'ws-1',
            spaceId: space.id,
            content: 'agent-$i',
            senderId: 'agent-1',
            senderType: 'agent',
            id: 'm$i',
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        final page = await repo.getMessagePage(
          'ws-1',
          space.id,
          await repo.ensureStandingConversation('ws-1', space.id),
          limit: 2,
        );
        // The backfill pulls the older user message into the page.
        expect(page.messages.map((m) => m.id), contains('m0'));
      },
    );

    test('returns empty page for a space with no messages', () async {
      final space = await repo.createSpace('ws-1', 'Chat', []);
      final page = await repo.getMessagePage(
        'ws-1',
        space.id,
        await repo.ensureStandingConversation('ws-1', space.id),
      );
      expect(page.messages, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });
  });

  group('revert / unrevert', () {
    test(
      'revertConversationTo with inclusive=false keeps the target',
      () async {
        final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
        for (var i = 0; i < 3; i++) {
          await repo.sendMessage(
            workspaceId: 'ws-1',
            spaceId: space.id,
            content: 'm$i',
            senderId: 'user',
            senderType: 'user',
            id: 'm$i',
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        final reverted = await repo.revertConversationTo(
          'ws-1',
          space.id,
          'm1',
        );
        expect(reverted, ['m2']);
        final live = await repo.getMessages('ws-1', space.id);
        expect(live.map((m) => m.id), ['m0', 'm1']);
      },
    );

    test(
      'revertConversationTo inclusive=true reverts the target too',
      () async {
        final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
        for (var i = 0; i < 3; i++) {
          await repo.sendMessage(
            workspaceId: 'ws-1',
            spaceId: space.id,
            content: 'm$i',
            senderId: 'user',
            senderType: 'user',
            id: 'm$i',
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        final reverted = await repo.revertConversationTo(
          'ws-1',
          space.id,
          'm1',
          inclusive: true,
        );
        expect(reverted, ['m1', 'm2']);
      },
    );

    test('revertConversationTo returns empty when the id is unknown', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'only',
        senderId: 'user',
        senderType: 'user',
      );
      expect(
        await repo.revertConversationTo('ws-1', space.id, 'no-such'),
        isEmpty,
      );
    });

    test('unrevertConversation restores the latest reverted batch', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      for (var i = 0; i < 3; i++) {
        await repo.sendMessage(
          workspaceId: 'ws-1',
          spaceId: space.id,
          content: 'm$i',
          senderId: 'user',
          senderType: 'user',
          id: 'm$i',
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await repo.revertConversationTo('ws-1', space.id, 'm0');
      // m0 stays live; m1 + m2 are reverted.
      expect((await repo.getMessages('ws-1', space.id)).map((m) => m.id), [
        'm0',
      ]);

      final restored = await repo.unrevertConversation('ws-1', space.id);
      expect(restored, ['m1', 'm2']);
      expect((await repo.getMessages('ws-1', space.id)).map((m) => m.id), [
        'm0',
        'm1',
        'm2',
      ]);
    });

    test('unrevertConversation returns empty with no reverted batch', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      expect(await repo.unrevertConversation('ws-1', space.id), isEmpty);
    });
  });

  group('space mutations', () {
    test('setSpaceMode updates the mode', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.setSpaceMode('ws-1', space.id, Mode.orchestrate);
      final row = await (db.select(
        db.spacesTable,
      )..where((t) => t.id.equals(space.id))).getSingle();
      expect(row.mode, Mode.orchestrate.toDbValue());
    });

    test('createSpace forwards origin + workspaceId + pipelineRunId', () async {
      // `workspaceId` is now the leading positional argument and it also picks
      // the database file the row lands in — so the assertion reads ws-77's own
      // database, not ws-1's.
      final space = await repo.createSpace(
        'ws-77',
        'Managed',
        [],
        pipelineRunId: 'run-1',
        kind: SpaceKind.agentPeer,
        mode: Mode.orchestrate,
      );
      final ws77 = dbs.of('ws-77');
      final row = await (ws77.select(
        ws77.spacesTable,
      )..where((t) => t.id.equals(space.id))).getSingle();
      expect(row.workspaceId, 'ws-77');
      expect(row.pipelineRunId, 'run-1');
      expect(row.kind, SpaceKind.agentPeer.wire);
      expect(row.mode, Mode.orchestrate.toDbValue());
    });
  });

  group('embeddings', () {
    test('updateMessageEmbedding + getMessagesWithEmbedding', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'with embedding',
        senderId: 'user',
        senderType: 'user',
        id: 'e1',
      );
      final embedding = Uint8List.fromList([1, 2, 3, 4]);
      await repo.updateMessageEmbedding('ws-1', 'e1', embedding);
      final withEmb = await repo.getMessagesWithEmbedding('ws-1', space.id);
      expect(withEmb, hasLength(1));
      expect(withEmb.first.message.id, 'e1');
    });

    test(
      'getMessagesWithoutEmbedding returns un-embedded text messages',
      () async {
        final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
        await repo.sendMessage(
          workspaceId: 'ws-1',
          spaceId: space.id,
          content: 'no embedding',
          senderId: 'user',
          senderType: 'user',
          id: 'ne1',
        );
        final without = await repo.getMessagesWithoutEmbedding(
          'ws-1',
          limit: 10,
        );
        expect(without.map((m) => m.id), contains('ne1'));
      },
    );
  });

  group('updateMessage no-op', () {
    test('updateMessage with no content/metadata is a no-op write', () async {
      final space = await repo.createSpace('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        spaceId: space.id,
        content: 'original',
        senderId: 'agent-1',
        senderType: 'agent',
      );
      final messages = await repo.getMessages('ws-1', space.id);
      // Call with neither content nor metadata — should not throw / not change.
      await repo.updateMessage('ws-1', messages.first.id);
      final after = await repo.getMessages('ws-1', space.id);
      expect(after.first.content, 'original');
    });
  });
}
