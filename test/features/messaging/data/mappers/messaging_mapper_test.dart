import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/mappers/messaging_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MessagingMapper mapper;

  setUp(() {
    mapper = const MessagingMapper();
  });

  group('channelToDomain', () {
    test('maps an empty-named channel correctly', () {
      final now = DateTime(2026, 5, 18);
      final row = ChannelsTableData(
        id: 'ch-1',
        name: '',

        workspaceId: 'ws-1',
        createdAt: now,
        updatedAt: now,
        mode: 'chat',
        provisioningStatus: 'ready',
        origin: 'user',
      );

      final channel = mapper.channelToDomain(row);

      expect(channel.id, 'ch-1');
      expect(channel.name, '');
      expect(channel.workspaceId, 'ws-1');
      expect(channel.createdAt, now);
      expect(channel.updatedAt, now);
    });

    test('maps a named channel correctly', () {
      final now = DateTime(2026, 5, 18);
      final row = ChannelsTableData(
        id: 'ch-2',
        name: 'Team Chat',

        createdAt: now,
        updatedAt: now,
        mode: 'chat',
        provisioningStatus: 'ready',
        origin: 'user',
      );

      final channel = mapper.channelToDomain(row);

      expect(channel.id, 'ch-2');
      expect(channel.name, 'Team Chat');
    });

    test('maps channel with null workspaceId', () {
      final now = DateTime(2026, 5, 18);
      final row = ChannelsTableData(
        id: 'ch-3',
        name: 'Channel',

        workspaceId: null,
        createdAt: now,
        updatedAt: now,
        mode: 'chat',
        provisioningStatus: 'ready',
        origin: 'user',
      );

      final channel = mapper.channelToDomain(row);

      expect(channel.workspaceId, isNull);
    });
  });

  group('channelsToDomain', () {
    test('maps list of channels', () {
      final now = DateTime(2026, 5, 18);
      final rows = [
        ChannelsTableData(
          id: 'ch-1',
          name: 'First',

          createdAt: now,
          updatedAt: now,
          mode: 'chat',
          provisioningStatus: 'ready',
          origin: 'user',
        ),
        ChannelsTableData(
          id: 'ch-2',
          name: 'Second',

          createdAt: now,
          updatedAt: now,
          mode: 'chat',
          provisioningStatus: 'ready',
          origin: 'user',
        ),
      ];

      final channels = mapper.channelsToDomain(rows);

      expect(channels.length, 2);
      expect(channels[0].id, 'ch-1');
      expect(channels[1].id, 'ch-2');
    });

    test('returns empty list for empty input', () {
      expect(mapper.channelsToDomain([]), isEmpty);
    });
  });

  group('participantToDomain', () {
    test('maps participant correctly', () {
      final now = DateTime(2026, 5, 18);
      final row = ChannelParticipantsTableData(
        id: 'p-1',
        channelId: 'ch-1',
        principalId: 'agent-1',
        participantType: 'agent',
        role: 'member',
        joinedAt: now,
      );

      final participant = mapper.participantToDomain(row);

      expect(participant.id, 'p-1');
      expect(participant.channelId, 'ch-1');
      expect(participant.principalId, 'agent-1');
      expect(participant.participantType, PrincipalType.agent);
      expect(participant.role, 'member');
      expect(participant.joinedAt, now);
    });

    test('maps user participant', () {
      final now = DateTime(2026, 5, 18);
      final row = ChannelParticipantsTableData(
        id: 'p-2',
        channelId: 'ch-1',
        principalId: 'user-1',
        participantType: 'user',
        role: 'owner',
        joinedAt: now,
      );

      final participant = mapper.participantToDomain(row);

      expect(participant.principalId, 'user-1');
      expect(participant.participantType, PrincipalType.user);
      expect(participant.isUser, isTrue);
    });
  });

  group('participantsToDomain', () {
    test('maps list of participants', () {
      final now = DateTime(2026, 5, 18);
      final rows = [
        ChannelParticipantsTableData(
          id: 'p-1',
          channelId: 'ch-1',
          principalId: 'user-1',
          participantType: 'user',
          role: 'owner',
          joinedAt: now,
        ),
        ChannelParticipantsTableData(
          id: 'p-2',
          channelId: 'ch-1',
          principalId: 'agent-1',
          participantType: 'agent',
          role: 'member',
          joinedAt: now,
        ),
      ];

      final participants = mapper.participantsToDomain(rows);

      expect(participants.length, 2);
      expect(participants[0].id, 'p-1');
      expect(participants[1].id, 'p-2');
    });

    test('returns empty list for empty input', () {
      expect(mapper.participantsToDomain([]), isEmpty);
    });
  });

  group('messageToDomain', () {
    final now = DateTime(2026, 5, 18);

    test('maps text message correctly', () {
      final row = ChannelMessagesTableData(
        id: 'm-1',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'user',
        senderType: 'user',
        content: 'Hello',
        messageType: 'text',
        compacted: false,
        reverted: false,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.id, 'm-1');
      expect(message.channelId, 'ch-1');
      expect(message.senderId, 'user');
      expect(message.senderType.name, 'user');
      expect(message.isUser, isTrue);
      expect(message.content, 'Hello');
      expect(message.messageType.name, 'text');
      expect(message.compacted, isFalse);
      expect(message.createdAt, now);
    });

    test('maps agent sender correctly', () {
      final row = ChannelMessagesTableData(
        id: 'm-2',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: 'agent',
        content: 'Response',
        messageType: 'text',
        compacted: false,
        reverted: false,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.senderType.name, 'agent');
      expect(message.isUser, isFalse);
    });

    test('maps system message type', () {
      final row = ChannelMessagesTableData(
        id: 'm-3',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'system',
        senderType: 'agent',
        content: 'System message',
        messageType: 'system',
        compacted: false,
        reverted: false,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.messageType.name, 'system');
      expect(message.isSystem, isTrue);
    });

    test('maps ticket_card message type', () {
      final row = ChannelMessagesTableData(
        id: 'm-4',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'system',
        senderType: 'agent',
        content: 'Ticket',
        messageType: 'ticket_card',
        compacted: false,
        reverted: false,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.messageType.name, 'ticketCard');
      expect(message.isTicket, isTrue);
    });

    test('maps agent turn message type', () {
      final row = ChannelMessagesTableData(
        id: 'm-5',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: 'agent',
        content: '',
        messageType: 'agent_turn',
        compacted: false,
        reverted: false,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.messageType.name, 'agentTurn');
      expect(message.isAgentTurn, isTrue);
    });

    test('falls back to text for unknown message type', () {
      final row = ChannelMessagesTableData(
        id: 'm-6',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'user',
        senderType: 'user',
        content: 'Content',
        messageType: 'bogus',
        compacted: false,
        reverted: false,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.messageType.name, 'text');
    });

    test('parses valid JSON metadata', () {
      final row = ChannelMessagesTableData(
        id: 'm-7',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: 'agent',
        content: '',
        messageType: 'agent_turn',
        metadata: '{"agentName":"TestAgent","streamComplete":true}',
        compacted: false,
        reverted: false,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.metadata, isNotNull);
      expect(message.metadata!['agentName'], 'TestAgent');
      expect(message.isStreamingComplete, isTrue);
    });

    test('handles null metadata', () {
      final row = ChannelMessagesTableData(
        id: 'm-8',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'user',
        senderType: 'user',
        content: 'No metadata',
        messageType: 'text',
        metadata: null,
        compacted: false,
        reverted: false,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.metadata, isNull);
    });

    test('handles invalid JSON metadata gracefully', () {
      final row = ChannelMessagesTableData(
        id: 'm-9',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: 'agent',
        content: '',
        messageType: 'agent_turn',
        metadata: '{invalid json}',
        compacted: false,
        reverted: false,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.metadata, isNull);
    });

    test('maps compacted flag correctly', () {
      final row = ChannelMessagesTableData(
        id: 'm-10',
        channelId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'user',
        senderType: 'user',
        content: 'Compacted',
        messageType: 'text',
        compacted: true,
        reverted: false,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.compacted, isTrue);
    });
  });

  group('messagesToDomain', () {
    test('maps list of messages', () {
      final now = DateTime(2026, 5, 18);
      final rows = [
        ChannelMessagesTableData(
          id: 'm-1',
          channelId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'user',
          senderType: 'user',
          content: 'First',
          messageType: 'text',
          compacted: false,
          reverted: false,
          createdAt: now,
        ),
        ChannelMessagesTableData(
          id: 'm-2',
          channelId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'agent-1',
          senderType: 'agent',
          content: 'Second',
          messageType: 'text',
          compacted: false,
          reverted: false,
          createdAt: now,
        ),
      ];

      final messages = mapper.messagesToDomain(rows);

      expect(messages.length, 2);
      expect(messages[0].id, 'm-1');
      expect(messages[1].id, 'm-2');
    });

    test('returns empty list for empty input', () {
      expect(mapper.messagesToDomain([]), isEmpty);
    });
  });
}
