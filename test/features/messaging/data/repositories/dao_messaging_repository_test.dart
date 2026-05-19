import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/messaging_dao.dart';
import 'package:cc_persistence/repositories/dao_messaging_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late MessagingDao dao;
  late DaoMessagingRepository repo;

  setUp(() async {
    db = createTestDatabase();
    dao = MessagingDao(db);
    repo = DaoMessagingRepository(dao);

    await db.into(db.agentsTable).insert(
      const AgentsTableCompanion(
        id: Value('user'),
        name: Value('User'),
        title: Value('Human User'),
        agentMdPath: Value(''),
        skills: Value(''),
        workspaceId: Value('ws-1'),
      ),
    );
    for (var i = 1; i <= 3; i++) {
      await db.into(db.agentsTable).insert(
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
    await db.close();
  });

  group('openDm', () {
    test('creates a new DM channel', () async {
      final channel = await repo.openDm('agent-1');

      expect(channel.id, isNotEmpty);
      expect(channel.isDm, isTrue);
      expect(channel.isDm, true);
    });

    test('returns existing DM channel if one exists', () async {
      final first = await repo.openDm('agent-1');
      final second = await repo.openDm('agent-1');

      expect(second.id, equals(first.id));
    });

    test('creates separate DMs for different agents', () async {
      final dm1 = await repo.openDm('agent-1');
      final dm2 = await repo.openDm('agent-2');

      expect(dm1.id, isNot(equals(dm2.id)));
    });

    test('automatically adds user and agent as participants', () async {
      final channel = await repo.openDm('agent-1');
      final participants = await repo.getParticipants(channel.id);

      final agentIds = participants.map((p) => p.agentId).toList();
      expect(agentIds, contains('user'));
      expect(agentIds, contains('agent-1'));
    });
  });

  group('createGroup', () {
    test('creates a group channel', () async {
      final channel = await repo.createGroup('Team Chat', ['agent-1', 'agent-2']);

      expect(channel.id, isNotEmpty);
      expect(channel.name, 'Team Chat');
      expect(channel.isDm, false);
      expect(channel.isDm, isFalse);
    });

    test('adds user and all agents as participants', () async {
      final channel = await repo.createGroup('Team', [
        'agent-1',
        'agent-2',
      ]);
      final participants = await repo.getParticipants(channel.id);

      final agentIds = participants.map((p) => p.agentId).toList();
      expect(agentIds, contains('user'));
      expect(agentIds, contains('agent-1'));
      expect(agentIds, contains('agent-2'));
      expect(participants.length, 3);
    });

    test('creates group with single agent', () async {
      final channel = await repo.createGroup('Solo', ['agent-1']);
      final participants = await repo.getParticipants(channel.id);

      expect(participants.length, 2);
    });

    test('creates group with no agents', () async {
      final channel = await repo.createGroup('Empty', []);
      final participants = await repo.getParticipants(channel.id);

      expect(participants.length, 1);
      expect(participants.first.agentId, 'user');
    });
  });

  group('addParticipant', () {
    test('adds agent to channel', () async {
      final channel = await repo.createGroup('Group', []);

      await repo.addParticipant(channel.id, 'agent-3');

      final participants = await repo.getParticipants(channel.id);
      final agentIds = participants.map((p) => p.agentId).toList();
      expect(agentIds, contains('agent-3'));
    });
  });

  group('getParticipants', () {
    test('returns participants for a channel', () async {
      final channel = await repo.openDm('agent-1');
      final participants = await repo.getParticipants(channel.id);

      expect(participants.length, 2);
      expect(
        participants.every((p) => p.channelId == channel.id),
        isTrue,
      );
    });

    test('returns empty list for channel with no participants', () async {
      final participants = await repo.getParticipants('non-existent');
      expect(participants, isEmpty);
    });
  });

  group('sendMessage', () {
    test('sends a message to a channel', () async {
      final channel = await repo.openDm('agent-1');

      await repo.sendMessage(
        channelId: channel.id,
        content: 'Hello',
        senderId: 'user',
        senderType: 'user',
      );

      final messages = await repo.getMessages(channel.id);
      expect(messages.length, 1);
      expect(messages.first.content, 'Hello');
      expect(messages.first.messageType.name, 'text');
    });

    test('sends multiple messages in order', () async {
      final channel = await repo.openDm('agent-1');

      await repo.sendMessage(
        channelId: channel.id,
        content: 'First',
        senderId: 'user',
        senderType: 'user',
      );
      await repo.sendMessage(
        channelId: channel.id,
        content: 'Second',
        senderId: 'agent-1',
        senderType: 'agent',
      );

      final messages = await repo.getMessages(channel.id);
      expect(messages.length, 2);
    });

    test('sends a message with metadata', () async {
      final channel = await repo.openDm('agent-1');

      await repo.sendMessage(
        channelId: channel.id,
        content: 'System',
        senderId: 'system',
        senderType: 'agent',
        messageType: 'system',
        metadata: {'key': 'value'},
      );

      final messages = await repo.getMessages(channel.id);
      expect(messages.first.metadata, {'key': 'value'});
    });

    test('uses provided message id', () async {
      final channel = await repo.openDm('agent-1');

      await repo.sendMessage(
        channelId: channel.id,
        content: 'Custom ID',
        senderId: 'user',
        senderType: 'user',
        id: 'custom-id-123',
      );

      final messages = await repo.getMessages(channel.id);
      expect(messages.first.id, 'custom-id-123');
    });
  });

  group('updateMessage', () {
    test('updates message content', () async {
      final channel = await repo.openDm('agent-1');
      await repo.sendMessage(
        channelId: channel.id,
        content: 'Original',
        senderId: 'agent-1',
        senderType: 'agent',
      );

      final messages = await repo.getMessages(channel.id);
      final msgId = messages.first.id;

      await repo.updateMessage(msgId, content: 'Updated');

      final updated = await repo.getMessages(channel.id);
      expect(updated.first.content, 'Updated');
    });

    test('updates message metadata', () async {
      final channel = await repo.openDm('agent-1');
      await repo.sendMessage(
        channelId: channel.id,
        content: 'Message',
        senderId: 'agent-1',
        senderType: 'agent',
        messageType: 'thinking',
      );

      final messages = await repo.getMessages(channel.id);
      final msgId = messages.first.id;

      await repo.updateMessage(msgId, metadata: {'done': true});

      final updated = await repo.getMessages(channel.id);
      expect(updated.first.metadata, {'done': true});
    });
  });

  group('markCompacted', () {
    test('marks messages as compacted', () async {
      final channel = await repo.openDm('agent-1');
      await repo.sendMessage(
        channelId: channel.id,
        content: 'Msg 1',
        senderId: 'user',
        senderType: 'user',
      );
      await repo.sendMessage(
        channelId: channel.id,
        content: 'Msg 2',
        senderId: 'agent-1',
        senderType: 'agent',
      );

      final messages = await repo.getMessages(channel.id);
      final ids = messages.map((m) => m.id).toList();

      await repo.markCompacted(ids);

      final compacted = await repo.getMessages(channel.id);
      expect(compacted.every((m) => m.compacted), isTrue);
    });
  });

  group('deleteChannel', () {
    test('deletes channel', () async {
      final channel = await repo.openDm('agent-1');
      await repo.deleteChannel(channel.id);

      final channels = await (db.select(db.channelsTable)
            ..where((t) => t.id.equals(channel.id)))
          .get();
      expect(channels, isEmpty);
    });
  });

  group('updateChannelName', () {
    test('updates channel name', () async {
      final channel = await repo.openDm('agent-1');
      await repo.updateChannelName(channel.id, 'New Name');

      final channels = await (db.select(db.channelsTable)
            ..where((t) => t.id.equals(channel.id)))
          .get();
      expect(channels.single.name, 'New Name');
    });
  });

  group('clearChannelMessages', () {
    test('clears all messages from a channel', () async {
      final channel = await repo.openDm('agent-1');
      await repo.sendMessage(
        channelId: channel.id,
        content: 'Message',
        senderId: 'user',
        senderType: 'user',
      );

      await repo.clearChannelMessages(channel.id);

      final messages = await repo.getMessages(channel.id);
      expect(messages, isEmpty);
    });
  });

  group('removeParticipant', () {
    test('removes participant from channel', () async {
      final channel = await repo.createGroup('Group', ['agent-1', 'agent-2']);

      await repo.removeParticipant(channel.id, 'agent-1');

      final participants = await repo.getParticipants(channel.id);
      final agentIds = participants.map((p) => p.agentId).toList();
      expect(agentIds, isNot(contains('agent-1')));
      expect(agentIds, contains('agent-2'));
    });
  });
}
