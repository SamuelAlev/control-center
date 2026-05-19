import 'package:control_center/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _seedAgent(AppDatabase db, String id, String name) async {
  await db.agentDao.upsert(
    AgentsTableCompanion.insert(
      id: id,
      name: name,
      title: name,
      agentMdPath: '.kilo/agent/$name.md',
      skills: 'generic',
      workspaceId: 'ws-test',
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('MessagingDao — channels', () {
    test('insert and watch channels', () async {
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'ch-1',
          name: 'general',

        ),
      );
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'ch-2',
          name: 'random',

        ),
      );

      final channels = await db.messagingDao.watchChannels().first;
      expect(channels.length, 2);
    });

    test('watchChannels returns empty when no channels', () async {
      final channels = await db.messagingDao.watchChannels().first;
      expect(channels, isEmpty);
    });

    test('updateChannelUpdatedAt sets timestamp', () async {
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(id: 'ch-ts', name: 'ts', ),
      );

      final now = DateTime(2026, 1, 1, 12, 0);
      await db.messagingDao.updateChannelUpdatedAt('ch-ts', now);

      final channels = await db.messagingDao.watchChannels().first;
      expect(channels.first.data.id, 'ch-ts');
    });

    test('updateChannelName changes name', () async {
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(id: 'ch-ren', name: 'old', ),
      );

      await db.messagingDao.updateChannelName('ch-ren', 'new-name');

      final channels = await db.messagingDao.watchChannels().first;
      expect(channels.first.data.name, 'new-name');
    });



    test('deleteChannelCascade removes channel, messages, participants',
        () async {
      await _seedAgent(db, 'agent-1', 'Agent 1');
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(id: 'ch-cascade', name: 'c', ),
      );
      await db.messagingDao.insertParticipant(
        ChannelParticipantsTableCompanion.insert(
          id: 'cp-1',
          channelId: 'ch-cascade',
          agentId: 'agent-1',
        ),
      );
      await db.messagingDao.insertMessage(
        ChannelMessagesTableCompanion.insert(
          id: 'msg-1',
          channelId: 'ch-cascade',
          senderId: 'agent-1',
          senderType: 'user',
          content: 'hello',
        ),
      );

      await db.messagingDao.deleteChannelCascade('ch-cascade');

      final channels = await db.messagingDao.watchChannels().first;
      expect(channels, isEmpty);

      final msgs = await db.messagingDao.watchMessages('ch-cascade').first;
      expect(msgs, isEmpty);

      final pts = await db.messagingDao.getParticipants('ch-cascade');
      expect(pts, isEmpty);
    });

    test('getChannelByDmParticipant finds existing DM channel', () async {
      await _seedAgent(db, 'user', 'User Agent');
      await _seedAgent(db, 'target-agent', 'Target Agent');
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'dm-1',
          name: '',

        ),
      );
      await db.messagingDao.insertParticipant(
        ChannelParticipantsTableCompanion.insert(
          id: 'cp-user',
          channelId: 'dm-1',
          agentId: 'user',
        ),
      );
      await db.messagingDao.insertParticipant(
        ChannelParticipantsTableCompanion.insert(
          id: 'cp-agent',
          channelId: 'dm-1',
          agentId: 'target-agent',
        ),
      );

      final ch = await db.messagingDao.getChannelByDmParticipant('target-agent');
      expect(ch, isNotNull);
      expect(ch!.data.id, 'dm-1');
    });

    test('getChannelByDmParticipant returns null when no DM exists', () async {
      final ch = await db.messagingDao.getChannelByDmParticipant('nonexistent');
      expect(ch, isNull);
    });
  });

  group('MessagingDao — participants', () {
    test('insert and watch participants', () async {
      await _seedAgent(db, 'agent-a', 'Agent A');
      await _seedAgent(db, 'agent-b', 'Agent B');
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'ch-p',
          name: 'p',

        ),
      );
      await db.messagingDao.insertParticipant(
        ChannelParticipantsTableCompanion.insert(
          id: 'cp-a',
          channelId: 'ch-p',
          agentId: 'agent-a',
        ),
      );
      await db.messagingDao.insertParticipant(
        ChannelParticipantsTableCompanion.insert(
          id: 'cp-b',
          channelId: 'ch-p',
          agentId: 'agent-b',
        ),
      );

      final pts = await db.messagingDao.watchParticipants('ch-p').first;
      expect(pts.length, 2);
    });

    test('insertParticipant ignores duplicates', () async {
      await _seedAgent(db, 'agent-d', 'Agent D');
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'ch-dup',
          name: 'dup',

        ),
      );
      await db.messagingDao.insertParticipant(
        ChannelParticipantsTableCompanion.insert(
          id: 'cp-d',
          channelId: 'ch-dup',
          agentId: 'agent-d',
        ),
      );
      await db.messagingDao.insertParticipant(
        ChannelParticipantsTableCompanion.insert(
          id: 'cp-d',
          channelId: 'ch-dup',
          agentId: 'agent-d',
        ),
      );

      final pts = await db.messagingDao.watchParticipants('ch-dup').first;
      expect(pts.length, 1);
    });

    test('getParticipants returns all participants for channel', () async {
      await _seedAgent(db, 'a1', 'Agent A1');
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'ch-gp',
          name: 'gp',

        ),
      );
      await db.messagingDao.insertParticipant(
        ChannelParticipantsTableCompanion.insert(
          id: 'cp-1',
          channelId: 'ch-gp',
          agentId: 'a1',
        ),
      );

      final pts = await db.messagingDao.getParticipants('ch-gp');
      expect(pts.length, 1);
      expect(pts.first.agentId, 'a1');
    });

    test('removeParticipant deletes participant', () async {
      await _seedAgent(db, 'agent-x', 'Agent X');
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'ch-rm',
          name: 'rm',

        ),
      );
      await db.messagingDao.insertParticipant(
        ChannelParticipantsTableCompanion.insert(
          id: 'cp-x',
          channelId: 'ch-rm',
          agentId: 'agent-x',
        ),
      );

      await db.messagingDao.removeParticipant('ch-rm', 'agent-x');

      final pts = await db.messagingDao.getParticipants('ch-rm');
      expect(pts, isEmpty);
    });
  });

  group('MessagingDao — messages', () {
    test('insert and watch messages', () async {
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'ch-msg',
          name: 'msg',

        ),
      );
      await db.messagingDao.insertMessage(
        ChannelMessagesTableCompanion.insert(
          id: 'msg-1',
          channelId: 'ch-msg',
          senderId: 'user',
          senderType: 'user',
          content: 'Hello',
        ),
      );
      await db.messagingDao.insertMessage(
        ChannelMessagesTableCompanion.insert(
          id: 'msg-2',
          channelId: 'ch-msg',
          senderId: 'agent',
          senderType: 'assistant',
          content: 'Hi!',
        ),
      );

      final msgs = await db.messagingDao.watchMessages('ch-msg').first;
      expect(msgs.length, 2);
      expect(msgs[0].content, 'Hello');
      expect(msgs[1].content, 'Hi!');
    });

    test('getMessages returns future list', () async {
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'ch-get',
          name: 'get',

        ),
      );
      await db.messagingDao.insertMessage(
        ChannelMessagesTableCompanion.insert(
          id: 'msg-a',
          channelId: 'ch-get',
          senderId: 'user',
          senderType: 'user',
          content: 'A',
        ),
      );

      final msgs = await db.messagingDao.getMessages('ch-get');
      expect(msgs.length, 1);
    });

    test('markCompacted sets compacted flag', () async {
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'ch-comp',
          name: 'comp',

        ),
      );
      await db.messagingDao.insertMessage(
        ChannelMessagesTableCompanion.insert(
          id: 'msg-c1',
          channelId: 'ch-comp',
          senderId: 'user',
          senderType: 'user',
          content: 'old',
        ),
      );
      await db.messagingDao.insertMessage(
        ChannelMessagesTableCompanion.insert(
          id: 'msg-c2',
          channelId: 'ch-comp',
          senderId: 'assistant',
          senderType: 'assistant',
          content: 'old reply',
        ),
      );

      await db.messagingDao.markCompacted(['msg-c1']);

      final msgs = await db.messagingDao.getMessages('ch-comp');
      final compacted = msgs.where((m) => m.compacted).toList();
      expect(compacted.length, 1);
      expect(compacted.first.id, 'msg-c1');
    });

    test('clearChannelMessages removes all messages', () async {
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'ch-clear',
          name: 'clear',

        ),
      );
      await db.messagingDao.insertMessage(
        ChannelMessagesTableCompanion.insert(
          id: 'msg-x',
          channelId: 'ch-clear',
          senderId: 'user',
          senderType: 'user',
          content: 'x',
        ),
      );
      await db.messagingDao.insertMessage(
        ChannelMessagesTableCompanion.insert(
          id: 'msg-y',
          channelId: 'ch-clear',
          senderId: 'user',
          senderType: 'user',
          content: 'y',
        ),
      );

      await db.messagingDao.clearChannelMessages('ch-clear');

      final msgs = await db.messagingDao.getMessages('ch-clear');
      expect(msgs, isEmpty);
    });

    test('updateMessage updates content', () async {
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'ch-upd',
          name: 'upd',

        ),
      );
      await db.messagingDao.insertMessage(
        ChannelMessagesTableCompanion.insert(
          id: 'msg-u',
          channelId: 'ch-upd',
          senderId: 'user',
          senderType: 'user',
          content: 'original',
        ),
      );

      await db.messagingDao.updateMessage('msg-u', content: 'updated');

      final msgs = await db.messagingDao.getMessages('ch-upd');
      expect(msgs.first.content, 'updated');
    });

    test('updateMessage updates metadata', () async {
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'ch-meta',
          name: 'meta',

        ),
      );
      await db.messagingDao.insertMessage(
        ChannelMessagesTableCompanion.insert(
          id: 'msg-m',
          channelId: 'ch-meta',
          senderId: 'user',
          senderType: 'user',
          content: 'msg',
        ),
      );

      await db.messagingDao.updateMessage('msg-m', metadata: {'key': 'value'});

      final msgs = await db.messagingDao.getMessages('ch-meta');
      expect(msgs.first.metadata, '{"key":"value"}');
    });

    test('updateMessage partially updates content only', () async {
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(
          id: 'ch-part',
          name: 'part',

        ),
      );
      await db.messagingDao.insertMessage(
        ChannelMessagesTableCompanion.insert(
          id: 'msg-p',
          channelId: 'ch-part',
          senderId: 'user',
          senderType: 'user',
          content: 'original',
          metadata: const Value('{"a":1}'),
        ),
      );

      await db.messagingDao.updateMessage('msg-p', content: 'new content');

      final msgs = await db.messagingDao.getMessages('ch-part');
      expect(msgs.first.content, 'new content');
      expect(msgs.first.metadata, '{"a":1}');
    });
  });
}
