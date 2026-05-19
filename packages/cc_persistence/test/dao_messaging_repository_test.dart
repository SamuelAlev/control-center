import 'dart:async';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  /// `ws-1`'s own database file — where every channel/message below lands, and
  /// what the direct-table assertions read back.
  late WorkspaceDatabase db;
  late DaoMessagingRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    // Registered so the cross-workspace `watchChannels()` fan-out can see it.
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

  group('createChannel', () {
    test('creates a channel', () async {
      final channel = await repo.createChannel('ws-1', 'Team Chat', [
        'agent-1',
        'agent-2',
      ]);

      expect(channel.id, isNotEmpty);
      expect(channel.name, 'Team Chat');
    });

    test('adds creating user and all agents as participants', () async {
      final channel = await repo.createChannel('ws-1', 'Team', [
        'agent-1',
        'agent-2',
      ], createdByUserId: 'user-1');
      final participants = await repo.getParticipants('ws-1', channel.id);

      final principalIds = participants.map((p) => p.principalId).toList();
      expect(principalIds, contains('user-1'));
      expect(principalIds, contains('agent-1'));
      expect(principalIds, contains('agent-2'));
      expect(participants.length, 3);
    });

    test('creates channel with single agent and no user when createdByUserId '
        'is null', () async {
      final channel = await repo.createChannel('ws-1', 'Solo', ['agent-1']);
      final participants = await repo.getParticipants('ws-1', channel.id);

      expect(participants.length, 1);
      expect(participants.single.principalId, 'agent-1');
      expect(participants.single.isUser, isFalse);
    });

    test('creates channel with no agents', () async {
      final channel = await repo.createChannel(
        'ws-1',
        'Empty',
        [],
        createdByUserId: 'user-1',
      );
      final participants = await repo.getParticipants('ws-1', channel.id);

      expect(participants.length, 1);
      expect(participants.first.principalId, 'user-1');
      expect(participants.first.isUser, isTrue);
    });
  });

  group('addParticipant', () {
    test('adds agent to channel', () async {
      final channel = await repo.createChannel('ws-1', 'Group', []);

      await repo.addParticipant('ws-1', channel.id, 'agent-3');

      final participants = await repo.getParticipants('ws-1', channel.id);
      final principalIds = participants.map((p) => p.principalId).toList();
      expect(principalIds, contains('agent-3'));
    });
  });

  group('getParticipants', () {
    test('returns participants for a channel', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', [
        'agent-1',
      ], createdByUserId: 'user-1');
      final participants = await repo.getParticipants('ws-1', channel.id);

      expect(participants.length, 2);
      expect(participants.every((p) => p.channelId == channel.id), isTrue);
    });

    test('returns empty list for channel with no participants', () async {
      final participants = await repo.getParticipants('ws-1', 'non-existent');
      expect(participants, isEmpty);
    });
  });

  group('sendMessage', () {
    test('sends a message to a channel', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);

      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'Hello',
        senderId: 'user',
        senderType: 'user',
      );

      final messages = await repo.getMessages('ws-1', channel.id);
      expect(messages.length, 1);
      expect(messages.first.content, 'Hello');
      expect(messages.first.messageType.name, 'text');
    });

    test('sends multiple messages in order', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);

      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'First',
        senderId: 'user',
        senderType: 'user',
      );
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'Second',
        senderId: 'agent-1',
        senderType: 'agent',
      );

      final messages = await repo.getMessages('ws-1', channel.id);
      expect(messages.length, 2);
    });

    test('sends a message with metadata', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);

      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'System',
        senderId: 'system',
        senderType: 'agent',
        messageType: 'system',
        metadata: {'key': 'value'},
      );

      final messages = await repo.getMessages('ws-1', channel.id);
      expect(messages.first.metadata, {'key': 'value'});
    });

    test('uses provided message id', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);

      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'Custom ID',
        senderId: 'user',
        senderType: 'user',
        id: 'custom-id-123',
      );

      final messages = await repo.getMessages('ws-1', channel.id);
      expect(messages.first.id, 'custom-id-123');
    });
  });

  group('updateMessage', () {
    test('updates message content', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'Original',
        senderId: 'agent-1',
        senderType: 'agent',
      );

      final messages = await repo.getMessages('ws-1', channel.id);
      final msgId = messages.first.id;

      await repo.updateMessage('ws-1', msgId, content: 'Updated');

      final updated = await repo.getMessages('ws-1', channel.id);
      expect(updated.first.content, 'Updated');
    });

    test('updates message metadata', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'Message',
        senderId: 'agent-1',
        senderType: 'agent',
        messageType: 'thinking',
      );

      final messages = await repo.getMessages('ws-1', channel.id);
      final msgId = messages.first.id;

      await repo.updateMessage('ws-1', msgId, metadata: {'done': true});

      final updated = await repo.getMessages('ws-1', channel.id);
      expect(updated.first.metadata, {'done': true});
    });
  });

  group('markCompacted', () {
    test('marks messages as compacted', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'Msg 1',
        senderId: 'user',
        senderType: 'user',
      );
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'Msg 2',
        senderId: 'agent-1',
        senderType: 'agent',
      );

      final messages = await repo.getMessages('ws-1', channel.id);
      final ids = messages.map((m) => m.id).toList();

      await repo.markCompacted('ws-1', ids);

      final compacted = await repo.getMessages('ws-1', channel.id);
      expect(compacted.every((m) => m.compacted), isTrue);
    });
  });

  group('deleteChannel', () {
    test('deletes channel', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      await repo.deleteChannel('ws-1', channel.id);

      final channels = await (db.select(
        db.channelsTable,
      )..where((t) => t.id.equals(channel.id))).get();
      expect(channels, isEmpty);
    });
  });

  group('updateChannelName', () {
    test('updates channel name', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      await repo.updateChannelName('ws-1', channel.id, 'New Name');

      final channels = await (db.select(
        db.channelsTable,
      )..where((t) => t.id.equals(channel.id))).get();
      expect(channels.single.name, 'New Name');
    });
  });

  group('clearChannelMessages', () {
    test('clears all messages from a channel', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'Message',
        senderId: 'user',
        senderType: 'user',
      );

      await repo.clearChannelMessages('ws-1', channel.id);

      final messages = await repo.getMessages('ws-1', channel.id);
      expect(messages, isEmpty);
    });
  });

  group('removeParticipant', () {
    test('removes participant from channel', () async {
      final channel = await repo.createChannel('ws-1', 'Group', [
        'agent-1',
        'agent-2',
      ]);

      await repo.removeParticipant('ws-1', channel.id, 'agent-1');

      final participants = await repo.getParticipants('ws-1', channel.id);
      final principalIds = participants.map((p) => p.principalId).toList();
      expect(principalIds, isNot(contains('agent-1')));
      expect(principalIds, contains('agent-2'));
    });
  });

  group('channelExists & getChannelById & getMessageById', () {
    test('channelExists is true for an existing channel', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      expect(await repo.channelExists('ws-1', channel.id), isTrue);
      expect(await repo.channelExists('ws-1', 'no-such'), isFalse);
    });

    test('getChannelById returns null for unknown id', () async {
      expect(await repo.getChannelById('ws-1', 'no-such'), isNull);
    });

    test('getChannelById returns the channel', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      final loaded = await repo.getChannelById('ws-1', channel.id);
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Chat');
    });

    test('getMessageById returns null for unknown id', () async {
      expect(await repo.getMessageById('ws-1', 'no-such'), isNull);
    });

    test('getMessageById returns the message', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'hi',
        senderId: 'user',
        senderType: 'user',
      );
      final messages = await repo.getMessages('ws-1', channel.id);
      final loaded = await repo.getMessageById('ws-1', messages.first.id);
      expect(loaded, isNotNull);
      expect(loaded!.content, 'hi');
    });
  });

  group('addParticipant with explicit type', () {
    test('adds a user participant', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', []);
      await repo.addParticipant(
        'ws-1',
        channel.id,
        'user-9',
        participantType: PrincipalType.user,
      );
      final participants = await repo.getParticipants('ws-1', channel.id);
      final added = participants.firstWhere((p) => p.principalId == 'user-9');
      expect(added.isUser, isTrue);
    });
  });

  group('watch streams', () {
    test('watchChannels emits channels', () async {
      await repo.createChannel('ws-1', 'A', []);
      final channels = await repo.watchChannels().first;
      expect(channels.map((c) => c.name), contains('A'));
    });

    test('watchParticipants emits participants', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      final participants = await repo
          .watchParticipants('ws-1', channel.id)
          .first;
      expect(participants.map((p) => p.principalId), contains('agent-1'));
    });

    test('watchChannelsByWorkspace filters by workspace', () async {
      // Seed through ws-9's own database — the workspace id now routes to a
      // file before the DAO's `WHERE workspace_id = ?` even runs, so the
      // `ws-other` read below proves the routing rather than the filter.
      final ws9 = dbs.of('ws-9');
      await ws9
          .into(ws9.channelsTable)
          .insert(
            const ChannelsTableCompanion(
              id: Value('ws-ch'),
              name: Value('Scoped'),
              workspaceId: Value('ws-9'),
            ),
          );
      final channels = await repo.watchChannelsByWorkspace('ws-9').first;
      expect(channels.map((c) => c.id), contains('ws-ch'));
      final other = await repo.watchChannelsByWorkspace('ws-other').first;
      expect(other.map((c) => c.id), isNot(contains('ws-ch')));
    });

    test('watchMessages emits newly sent messages', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      unawaited(
        expectLater(
          repo.watchMessages('ws-1', channel.id, channel.id),
          emitsInOrder([
            isEmpty,
            predicate<List<ChannelMessage>>(
              (list) => list.length == 1 && list.first.content == 'hi',
            ),
          ]),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'hi',
        senderId: 'user',
        senderType: 'user',
      );
    });

    test('watchMessages returns the conversation in order', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'first',
        senderId: 'user',
        senderType: 'user',
        id: 'p1',
      );
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'second',
        senderId: 'agent-1',
        senderType: 'agent',
        id: 'r1',
      );
      final all = await repo
          .watchMessages('ws-1', channel.id, channel.id)
          .first;
      expect(all.map((m) => m.id), ['p1', 'r1']);
    });

    test('watchTopLevelMessagesWindow trims to the newest limit', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      for (var i = 0; i < 5; i++) {
        await repo.sendMessage(
          workspaceId: 'ws-1',
          channelId: channel.id,
          content: 'm$i',
          senderId: 'user',
          senderType: 'user',
          id: 'm$i',
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      final window = await repo
          .watchMessagesWindow('ws-1', channel.id, channel.id, limit: 3)
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
        final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
        await repo.sendMessage(
          workspaceId: 'ws-1',
          channelId: channel.id,
          content: 'only',
          senderId: 'user',
          senderType: 'user',
        );
        final window = await repo
            .watchMessagesWindow('ws-1', channel.id, channel.id, limit: 3)
            .first;
        expect(window.hasMore, isFalse);
        expect(window.messages, hasLength(1));
      },
    );
  });

  group('searchInChannel', () {
    test('returns matching messages', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'deploy the service',
        senderId: 'user',
        senderType: 'user',
      );
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'unrelated note',
        senderId: 'agent-1',
        senderType: 'agent',
      );
      final hits = await repo.searchInChannel('ws-1', channel.id, 'deploy');
      expect(hits, hasLength(1));
      expect(hits.first.content, 'deploy the service');
    });

    test('returns empty for no usable tokens', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      final hits = await repo.searchInChannel('ws-1', channel.id, '   ');
      expect(hits, isEmpty);
    });
  });

  group('getTopLevelMessagePage (backfill)', () {
    test('paginates and reports hasMore / nextCursor', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      for (var i = 0; i < 5; i++) {
        await repo.sendMessage(
          workspaceId: 'ws-1',
          channelId: channel.id,
          content: 'm$i',
          senderId: 'user',
          senderType: 'user',
          id: 'm$i',
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      final page1 = await repo.getMessagePage(
        'ws-1',
        channel.id,
        channel.id,
        limit: 2,
      );
      expect(page1.hasMore, isTrue);
      expect(page1.messages, hasLength(2));
      expect(page1.nextCursor, isNotNull);

      final page2 = await repo.getMessagePage(
        'ws-1',
        channel.id,
        channel.id,
        limit: 2,
        cursor: page1.nextCursor,
      );
      expect(page2.messages, isNotEmpty);
    });

    test(
      'backfills to a user-message boundary when the oldest is an agent msg',
      () async {
        final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
        // Seed: user, agent, agent, agent — a page of 2 ending in an agent msg
        // must pull older rows until it reaches the user message.
        await repo.sendMessage(
          workspaceId: 'ws-1',
          channelId: channel.id,
          content: 'user-q',
          senderId: 'user',
          senderType: 'user',
          id: 'm0',
        );
        for (var i = 1; i <= 3; i++) {
          await repo.sendMessage(
            workspaceId: 'ws-1',
            channelId: channel.id,
            content: 'agent-$i',
            senderId: 'agent-1',
            senderType: 'agent',
            id: 'm$i',
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        final page = await repo.getMessagePage(
          'ws-1',
          channel.id,
          channel.id,
          limit: 2,
        );
        // The backfill pulls the older user message into the page.
        expect(page.messages.map((m) => m.id), contains('m0'));
      },
    );

    test('returns empty page for a channel with no messages', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', []);
      final page = await repo.getMessagePage('ws-1', channel.id, channel.id);
      expect(page.messages, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });
  });

  group('revert / unrevert', () {
    test(
      'revertConversationTo with inclusive=false keeps the target',
      () async {
        final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
        for (var i = 0; i < 3; i++) {
          await repo.sendMessage(
            workspaceId: 'ws-1',
            channelId: channel.id,
            content: 'm$i',
            senderId: 'user',
            senderType: 'user',
            id: 'm$i',
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        final reverted = await repo.revertConversationTo(
          'ws-1',
          channel.id,
          'm1',
        );
        expect(reverted, ['m2']);
        final live = await repo.getMessages('ws-1', channel.id);
        expect(live.map((m) => m.id), ['m0', 'm1']);
      },
    );

    test(
      'revertConversationTo inclusive=true reverts the target too',
      () async {
        final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
        for (var i = 0; i < 3; i++) {
          await repo.sendMessage(
            workspaceId: 'ws-1',
            channelId: channel.id,
            content: 'm$i',
            senderId: 'user',
            senderType: 'user',
            id: 'm$i',
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        final reverted = await repo.revertConversationTo(
          'ws-1',
          channel.id,
          'm1',
          inclusive: true,
        );
        expect(reverted, ['m1', 'm2']);
      },
    );

    test('revertConversationTo returns empty when the id is unknown', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'only',
        senderId: 'user',
        senderType: 'user',
      );
      expect(
        await repo.revertConversationTo('ws-1', channel.id, 'no-such'),
        isEmpty,
      );
    });

    test('unrevertConversation restores the latest reverted batch', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      for (var i = 0; i < 3; i++) {
        await repo.sendMessage(
          workspaceId: 'ws-1',
          channelId: channel.id,
          content: 'm$i',
          senderId: 'user',
          senderType: 'user',
          id: 'm$i',
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await repo.revertConversationTo('ws-1', channel.id, 'm0');
      // m0 stays live; m1 + m2 are reverted.
      expect((await repo.getMessages('ws-1', channel.id)).map((m) => m.id), [
        'm0',
      ]);

      final restored = await repo.unrevertConversation('ws-1', channel.id);
      expect(restored, ['m1', 'm2']);
      expect((await repo.getMessages('ws-1', channel.id)).map((m) => m.id), [
        'm0',
        'm1',
        'm2',
      ]);
    });

    test('unrevertConversation returns empty with no reverted batch', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      expect(await repo.unrevertConversation('ws-1', channel.id), isEmpty);
    });
  });

  group('channel mutations', () {
    test('setChannelMode updates the mode', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      await repo.setChannelMode('ws-1', channel.id, Mode.orchestrate);
      final row = await (db.select(
        db.channelsTable,
      )..where((t) => t.id.equals(channel.id))).getSingle();
      expect(row.mode, Mode.orchestrate.toDbValue());
    });

    test('createChannel forwards origin + workspaceId + pipelineRunId', () async {
      // `workspaceId` is now the leading positional argument, and it also picks
      // the database file the row lands in — so the assertion reads ws-77's own
      // database, not ws-1's.
      final channel = await repo.createChannel(
        'ws-77',
        'Managed',
        [],
        pipelineRunId: 'run-1',
        origin: ChannelOrigin.agentDm,
        mode: Mode.orchestrate,
      );
      final ws77 = dbs.of('ws-77');
      final row = await (ws77.select(
        ws77.channelsTable,
      )..where((t) => t.id.equals(channel.id))).getSingle();
      expect(row.workspaceId, 'ws-77');
      expect(row.pipelineRunId, 'run-1');
      expect(row.origin, ChannelOrigin.agentDm.wire);
      expect(row.mode, Mode.orchestrate.toDbValue());
    });
  });

  group('embeddings', () {
    test('updateMessageEmbedding + getMessagesWithEmbedding', () async {
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'with embedding',
        senderId: 'user',
        senderType: 'user',
        id: 'e1',
      );
      final embedding = Uint8List.fromList([1, 2, 3, 4]);
      await repo.updateMessageEmbedding('ws-1', 'e1', embedding);
      final withEmb = await repo.getMessagesWithEmbedding('ws-1', channel.id);
      expect(withEmb, hasLength(1));
      expect(withEmb.first.message.id, 'e1');
    });

    test(
      'getMessagesWithoutEmbedding returns un-embedded text messages',
      () async {
        final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
        await repo.sendMessage(
          workspaceId: 'ws-1',
          channelId: channel.id,
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
      final channel = await repo.createChannel('ws-1', 'Chat', ['agent-1']);
      await repo.sendMessage(
        workspaceId: 'ws-1',
        channelId: channel.id,
        content: 'original',
        senderId: 'agent-1',
        senderType: 'agent',
      );
      final messages = await repo.getMessages('ws-1', channel.id);
      // Call with neither content nor metadata — should not throw / not change.
      await repo.updateMessage('ws-1', messages.first.id);
      final after = await repo.getMessages('ws-1', channel.id);
      expect(after.first.content, 'original');
    });
  });
}
