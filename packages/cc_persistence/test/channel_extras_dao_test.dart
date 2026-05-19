import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
    // Seed workspaces + channels the extras FK-reference.
    for (final (id, ws) in [('c-1', 'w-1'), ('c-2', 'w-1'), ('c-3', 'w-2')]) {
      await db
          .into(db.channelsTable)
          .insert(
            ChannelsTableCompanion.insert(
              id: id,
              name: id,
              workspaceId: Value(ws),
            ),
          );
      // Seed the `main` conversation (id == channel id) for the FK on messages.
      await db
          .into(db.conversationsTable)
          .insert(
            ConversationsTableCompanion.insert(
              id: id,
              channelId: id,
              workspaceId: Value(ws),
            ),
          );
    }
    // Reactions FK-reference channel_messages — seed one per channel.
    for (final (id, ch) in [('m-1', 'c-1'), ('m-2', 'c-2'), ('m-3', 'c-3')]) {
      await db
          .into(db.channelMessagesTable)
          .insert(
            ChannelMessagesTableCompanion.insert(
              id: id,
              channelId: ch,
              conversationId: ch,
              senderId: 'user:u',
              senderType: 'user',
              content: 'hello',
            ),
          );
    }
  });

  tearDown(() async {
    await db.close();
  });

  group('ChannelExtrasDao — channel notes', () {
    test('upsert inserts a new note and reads it back', () async {
      final row = await db.channelExtrasDao.upsertNote(
        id: 'n-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        contentMarkdown: '# title',
        updatedByPrincipal: 'user:u',
      );
      expect(row.contentMarkdown, '# title');
      expect(row.updatedByPrincipal, 'user:u');
      expect(row.version, 1);

      final read = await db.channelExtrasDao.noteForChannel('w-1', 'c-1');
      expect(read, isNotNull);
      expect(read!.contentMarkdown, '# title');
    });

    test(
      'upsert on an existing note replaces content and bumps version',
      () async {
        await db.channelExtrasDao.upsertNote(
          id: 'n-1',
          workspaceId: 'w-1',
          channelId: 'c-1',
          contentMarkdown: 'first',
          updatedByPrincipal: 'user:u',
        );
        final updated = await db.channelExtrasDao.upsertNote(
          id: 'n-1',
          workspaceId: 'w-1',
          channelId: 'c-1',
          contentMarkdown: 'second',
          updatedByPrincipal: 'agent:a',
        );
        expect(updated.contentMarkdown, 'second');
        expect(updated.updatedByPrincipal, 'agent:a');
        expect(updated.version, 2);
        // Same row (one doc per channel).
        expect(updated.id, 'n-1');
      },
    );

    test('noteForChannel is workspace-isolated', () async {
      await db.channelExtrasDao.upsertNote(
        id: 'n-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        contentMarkdown: 'w1 notes',
        updatedByPrincipal: 'user:u',
      );
      // Same channel id but foreign workspace — isolation invariant.
      expect(await db.channelExtrasDao.noteForChannel('w-2', 'c-1'), isNull);
      // Different channel, same workspace — also null.
      expect(await db.channelExtrasDao.noteForChannel('w-1', 'c-2'), isNull);
    });

    test('watchNoteForChannel emits the note then updates', () async {
      await db.channelExtrasDao.upsertNote(
        id: 'n-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        contentMarkdown: 'v1',
        updatedByPrincipal: 'user:u',
      );
      final first = await db.channelExtrasDao
          .watchNoteForChannel('w-1', 'c-1')
          .first;
      expect(first?.contentMarkdown, 'v1');

      await db.channelExtrasDao.upsertNote(
        id: 'n-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        contentMarkdown: 'v2',
        updatedByPrincipal: 'user:u',
      );
      final second = await db.channelExtrasDao
          .watchNoteForChannel('w-1', 'c-1')
          .first;
      expect(second?.contentMarkdown, 'v2');
    });

    test('watchNoteForChannel emits null for a foreign workspace', () async {
      await db.channelExtrasDao.upsertNote(
        id: 'n-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        contentMarkdown: 'w1',
        updatedByPrincipal: 'user:u',
      );
      final row = await db.channelExtrasDao
          .watchNoteForChannel('w-2', 'c-1')
          .first;
      expect(row, isNull);
    });
  });

  group('ChannelExtrasDao — per-channel agent autonomy', () {
    test('set then get a single agent dial', () async {
      await db.channelExtrasDao.setAutonomy(
        id: 'a-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        agentId: 'agent:1',
        autonomyLevel: 'actFreely',
      );
      final row = await db.channelExtrasDao.autonomyFor(
        'w-1',
        'c-1',
        'agent:1',
      );
      expect(row, isNotNull);
      expect(row!.autonomyLevel, 'actFreely');
    });

    test('setAutonomy upserts — second set updates the level', () async {
      await db.channelExtrasDao.setAutonomy(
        id: 'a-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        agentId: 'agent:1',
        autonomyLevel: 'proposeOnly',
      );
      await db.channelExtrasDao.setAutonomy(
        id: 'a-2',
        workspaceId: 'w-1',
        channelId: 'c-1',
        agentId: 'agent:1',
        autonomyLevel: 'actWithApproval',
      );
      final row = await db.channelExtrasDao.autonomyFor(
        'w-1',
        'c-1',
        'agent:1',
      );
      expect(row, isNotNull);
      expect(row!.autonomyLevel, 'actWithApproval');
      // Still one row per (ws, channel, agent) unique key.
      final all = await db.channelExtrasDao.autonomyForChannel('w-1', 'c-1');
      expect(all, hasLength(1));
    });

    test('autonomyForChannel lists every dial in the channel', () async {
      await db.channelExtrasDao.setAutonomy(
        id: 'a-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        agentId: 'agent:1',
        autonomyLevel: 'proposeOnly',
      );
      await db.channelExtrasDao.setAutonomy(
        id: 'a-2',
        workspaceId: 'w-1',
        channelId: 'c-1',
        agentId: 'agent:2',
        autonomyLevel: 'actFreely',
      );
      final all = await db.channelExtrasDao.autonomyForChannel('w-1', 'c-1');
      expect(all, hasLength(2));
    });

    test('autonomy is workspace-isolated', () async {
      await db.channelExtrasDao.setAutonomy(
        id: 'a-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        agentId: 'agent:1',
        autonomyLevel: 'actFreely',
      );
      // Foreign workspace sees nothing.
      expect(
        await db.channelExtrasDao.autonomyFor('w-2', 'c-1', 'agent:1'),
        isNull,
      );
      expect(
        await db.channelExtrasDao.autonomyForChannel('w-2', 'c-1'),
        isEmpty,
      );
    });

    test('autonomyFor is channel-scoped within a workspace', () async {
      await db.channelExtrasDao.setAutonomy(
        id: 'a-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        agentId: 'agent:1',
        autonomyLevel: 'actFreely',
      );
      // Same ws + agent, different channel — not found.
      expect(
        await db.channelExtrasDao.autonomyFor('w-1', 'c-2', 'agent:1'),
        isNull,
      );
    });

    test('setAutonomy with null clears the dial', () async {
      await db.channelExtrasDao.setAutonomy(
        id: 'a-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        agentId: 'agent:1',
        autonomyLevel: 'actFreely',
      );
      await db.channelExtrasDao.setAutonomy(
        id: 'a-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        agentId: 'agent:1',
        autonomyLevel: null,
      );
      expect(
        await db.channelExtrasDao.autonomyFor('w-1', 'c-1', 'agent:1'),
        isNull,
      );
      expect(
        await db.channelExtrasDao.autonomyForChannel('w-1', 'c-1'),
        isEmpty,
      );
    });

    test('watchAutonomyForChannel emits the current dials', () async {
      await db.channelExtrasDao.setAutonomy(
        id: 'a-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        agentId: 'agent:1',
        autonomyLevel: 'proposeOnly',
      );
      final first = await db.channelExtrasDao
          .watchAutonomyForChannel('w-1', 'c-1')
          .first;
      expect(first, hasLength(1));
      expect(first.single.autonomyLevel, 'proposeOnly');
    });
  });

  group('ChannelExtrasDao — message reactions', () {
    test('toggle adds a reaction and returns true', () async {
      final added = await db.channelExtrasDao.toggleReaction(
        id: 'r-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        messageId: 'm-1',
        principalId: 'user:u',
        principalType: 'user',
        emoji: '👍',
      );
      expect(added, isTrue);

      final reactions = await db.channelExtrasDao
          .watchReactionsForChannel('w-1', 'c-1')
          .first;
      expect(reactions, hasLength(1));
      expect(reactions.single.emoji, '👍');
      expect(reactions.single.principalType, 'user');
    });

    test(
      'toggling the same reaction again removes it and returns false',
      () async {
        await db.channelExtrasDao.toggleReaction(
          id: 'r-1',
          workspaceId: 'w-1',
          channelId: 'c-1',
          messageId: 'm-1',
          principalId: 'user:u',
          principalType: 'user',
          emoji: '👍',
        );
        final removed = await db.channelExtrasDao.toggleReaction(
          id: 'r-1',
          workspaceId: 'w-1',
          channelId: 'c-1',
          messageId: 'm-1',
          principalId: 'user:u',
          principalType: 'user',
          emoji: '👍',
        );
        expect(removed, isFalse);
        final reactions = await db.channelExtrasDao
            .watchReactionsForChannel('w-1', 'c-1')
            .first;
        expect(reactions, isEmpty);
      },
    );

    test(
      'two principals can react with the same emoji independently',
      () async {
        await db.channelExtrasDao.toggleReaction(
          id: 'r-1',
          workspaceId: 'w-1',
          channelId: 'c-1',
          messageId: 'm-1',
          principalId: 'user:u',
          principalType: 'user',
          emoji: '👍',
        );
        await db.channelExtrasDao.toggleReaction(
          id: 'r-2',
          workspaceId: 'w-1',
          channelId: 'c-1',
          messageId: 'm-1',
          principalId: 'agent:a',
          principalType: 'agent',
          emoji: '👍',
        );
        final reactions = await db.channelExtrasDao
            .watchReactionsForChannel('w-1', 'c-1')
            .first;
        expect(reactions, hasLength(2));
      },
    );

    test('reactions are workspace-isolated', () async {
      await db.channelExtrasDao.toggleReaction(
        id: 'r-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        messageId: 'm-1',
        principalId: 'user:u',
        principalType: 'user',
        emoji: '👍',
      );
      // Foreign workspace sees no reactions.
      final foreign = await db.channelExtrasDao
          .watchReactionsForChannel('w-2', 'c-3')
          .first;
      expect(foreign, isEmpty);
    });

    test('toggle is scoped by principalId and emoji, not channel', () async {
      // m-1 is in c-1; m-2 is in c-2. Toggling m-1 should not touch m-2.
      await db.channelExtrasDao.toggleReaction(
        id: 'r-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        messageId: 'm-1',
        principalId: 'user:u',
        principalType: 'user',
        emoji: '👍',
      );
      await db.channelExtrasDao.toggleReaction(
        id: 'r-2',
        workspaceId: 'w-1',
        channelId: 'c-2',
        messageId: 'm-2',
        principalId: 'user:u',
        principalType: 'user',
        emoji: '👍',
      );
      // Removing m-1's reaction leaves m-2's intact.
      final removed = await db.channelExtrasDao.toggleReaction(
        id: 'r-1',
        workspaceId: 'w-1',
        channelId: 'c-1',
        messageId: 'm-1',
        principalId: 'user:u',
        principalType: 'user',
        emoji: '👍',
      );
      expect(removed, isFalse);
      final all = await db.channelExtrasDao
          .watchReactionsForChannel('w-1', 'c-1')
          .first;
      expect(all, isEmpty);
      final c2 = await db.channelExtrasDao
          .watchReactionsForChannel('w-1', 'c-2')
          .first;
      expect(c2, hasLength(1));
    });
  });
}
