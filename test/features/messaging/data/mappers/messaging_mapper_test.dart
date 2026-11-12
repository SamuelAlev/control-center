import 'package:cc_domain/core/domain/entities/message.dart' show SenderType;
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/mappers/messaging_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MessagingMapper mapper;

  setUp(() {
    mapper = const MessagingMapper();
  });

  group('spaceToDomain', () {
    test('maps an empty-named space correctly', () {
      final now = DateTime(2026, 5, 18);
      final row = SpacesTableData(
        id: 'ch-1',
        name: '',

        workspaceId: 'ws-1',
        createdAt: now,
        updatedAt: now,
        mode: 'chat',
        provisioningStatus: 'ready',
        kind: 'user',
        noRepos: false,
      );

      final space = mapper.spaceToDomain(row);

      expect(space.id, 'ch-1');
      expect(space.name, '');
      expect(space.workspaceId, 'ws-1');
      expect(space.createdAt, now);
      expect(space.updatedAt, now);
    });

    test('maps a named space correctly', () {
      final now = DateTime(2026, 5, 18);
      final row = SpacesTableData(
        id: 'ch-2',
        name: 'Team Chat',
        workspaceId: 'ws-1',
        createdAt: now,
        updatedAt: now,
        mode: 'chat',
        provisioningStatus: 'ready',
        kind: 'user',
        noRepos: false,
      );

      final space = mapper.spaceToDomain(row);

      expect(space.id, 'ch-2');
      expect(space.name, 'Team Chat');
    });
  });

  group('spacesToDomain', () {
    test('maps list of spaces', () {
      final now = DateTime(2026, 5, 18);
      final rows = [
        SpacesTableData(
          id: 'ch-1',
          name: 'First',
          workspaceId: 'ws-1',
          createdAt: now,
          updatedAt: now,
          mode: 'chat',
          provisioningStatus: 'ready',
          kind: 'user',
          noRepos: false,
        ),
        SpacesTableData(
          id: 'ch-2',
          name: 'Second',
          workspaceId: 'ws-1',
          createdAt: now,
          updatedAt: now,
          mode: 'chat',
          provisioningStatus: 'ready',
          kind: 'user',
          noRepos: false,
        ),
      ];

      final spaces = mapper.spacesToDomain(rows);

      expect(spaces.length, 2);
      expect(spaces[0].id, 'ch-1');
      expect(spaces[1].id, 'ch-2');
    });

    test('returns empty list for empty input', () {
      expect(mapper.spacesToDomain([]), isEmpty);
    });
  });

  group('participantToDomain', () {
    test('maps participant correctly', () {
      final now = DateTime(2026, 5, 18);
      final row = SpaceParticipantsTableData(
        id: 'p-1',
        spaceId: 'ch-1',
        principalId: 'agent-1',
        participantType: 'agent',
        role: 'member',
        joinedAt: now,
        lastReadSeq: 0,
      );

      final participant = mapper.participantToDomain(row);

      expect(participant.id, 'p-1');
      expect(participant.spaceId, 'ch-1');
      expect(participant.principalId, 'agent-1');
      expect(participant.participantType, PrincipalType.agent);
      expect(participant.role, 'member');
      expect(participant.joinedAt, now);
    });

    test('maps user participant', () {
      final now = DateTime(2026, 5, 18);
      final row = SpaceParticipantsTableData(
        id: 'p-2',
        spaceId: 'ch-1',
        principalId: 'user-1',
        participantType: 'user',
        role: 'owner',
        joinedAt: now,
        lastReadSeq: 0,
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
        SpaceParticipantsTableData(
          id: 'p-1',
          spaceId: 'ch-1',
          principalId: 'user-1',
          participantType: 'user',
          role: 'owner',
          joinedAt: now,
          lastReadSeq: 0,
        ),
        SpaceParticipantsTableData(
          id: 'p-2',
          spaceId: 'ch-1',
          principalId: 'agent-1',
          participantType: 'agent',
          role: 'member',
          joinedAt: now,
          lastReadSeq: 0,
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
      final row = ConversationMessagesTableData(
        id: 'm-1',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'user',
        senderType: 'user',
        content: 'Hello',
        messageType: 'text',
        answered: false,
        compacted: false,
        reverted: false,
        contentChars: 0,
        transcriptChars: 0,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.id, 'm-1');
      expect(message.spaceId, 'ch-1');
      expect(message.senderId, 'user');
      expect(message.senderType.name, 'user');
      expect(message.isUser, isTrue);
      expect(message.content, 'Hello');
      expect(message.messageType.name, 'text');
      expect(message.compacted, isFalse);
      expect(message.createdAt, now);
    });

    test('maps agent sender correctly', () {
      final row = ConversationMessagesTableData(
        id: 'm-2',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: 'agent',
        content: 'Response',
        messageType: 'text',
        answered: false,
        compacted: false,
        reverted: false,
        contentChars: 0,
        transcriptChars: 0,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.senderType.name, 'agent');
      expect(message.isUser, isFalse);
    });

    test('maps system message type', () {
      final row = ConversationMessagesTableData(
        id: 'm-3',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'system',
        senderType: 'system',
        content: 'System message',
        messageType: 'system',
        answered: false,
        compacted: false,
        reverted: false,
        contentChars: 0,
        transcriptChars: 0,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.messageType.name, 'system');
      expect(message.isSystem, isTrue);
      expect(message.senderType, SenderType.system);
    });

    test('decodes stored sender types, unknown never as a human', () {
      ConversationMessagesTableData row(String senderId, String senderType) =>
          ConversationMessagesTableData(
            id: 'm-5',
            spaceId: 'ch-1',
            conversationId: 'ch-1',
            senderId: senderId,
            senderType: senderType,
            content: 'x',
            messageType: 'text',
            answered: false,
            compacted: false,
            reverted: false,
            contentChars: 0,
            transcriptChars: 0,
            createdAt: now,
          );
      SenderType decode(String senderId, String senderType) =>
          mapper.messageToDomain(row(senderId, senderType)).senderType;

      expect(decode('u-1', 'user'), SenderType.user);
      expect(decode('agent-1', 'agent'), SenderType.agent);
      expect(decode('system', 'system'), SenderType.system);
      expect(decode('agent-1', 'robot'), SenderType.agent);
    });

    test('maps ticket_card message type', () {
      final row = ConversationMessagesTableData(
        id: 'm-4',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'system',
        senderType: 'agent',
        content: 'Ticket',
        messageType: 'ticket_card',
        answered: false,
        compacted: false,
        reverted: false,
        contentChars: 0,
        transcriptChars: 0,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.messageType.name, 'ticketCard');
      expect(message.isTicket, isTrue);
    });

    test('maps agent turn message type', () {
      final row = ConversationMessagesTableData(
        id: 'm-5',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: 'agent',
        content: '',
        messageType: 'agent_turn',
        answered: false,
        compacted: false,
        reverted: false,
        contentChars: 0,
        transcriptChars: 0,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.messageType.name, 'agentTurn');
      expect(message.isAgentTurn, isTrue);
    });

    test('falls back to text for unknown message type', () {
      final row = ConversationMessagesTableData(
        id: 'm-6',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'user',
        senderType: 'user',
        content: 'Content',
        messageType: 'bogus',
        answered: false,
        compacted: false,
        reverted: false,
        contentChars: 0,
        transcriptChars: 0,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.messageType.name, 'text');
    });

    test('parses valid JSON metadata', () {
      final row = ConversationMessagesTableData(
        id: 'm-7',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: 'agent',
        content: '',
        messageType: 'agent_turn',
        answered: false,
        metadata: '{"agentName":"TestAgent","streamComplete":true}',
        compacted: false,
        reverted: false,
        contentChars: 0,
        transcriptChars: 0,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.metadata, isNotNull);
      expect(message.metadata!['agentName'], 'TestAgent');
      expect(message.isStreamingComplete, isTrue);
    });

    test('handles null metadata', () {
      final row = ConversationMessagesTableData(
        id: 'm-8',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'user',
        senderType: 'user',
        content: 'No metadata',
        messageType: 'text',
        answered: false,
        metadata: null,
        compacted: false,
        reverted: false,
        contentChars: 0,
        transcriptChars: 0,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.metadata, isNull);
    });

    test('handles invalid JSON metadata gracefully', () {
      final row = ConversationMessagesTableData(
        id: 'm-9',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'agent-1',
        senderType: 'agent',
        content: '',
        messageType: 'agent_turn',
        answered: false,
        metadata: '{invalid json}',
        compacted: false,
        reverted: false,
        contentChars: 0,
        transcriptChars: 0,
        createdAt: now,
      );

      final message = mapper.messageToDomain(row);

      expect(message.metadata, isNull);
    });

    test('maps compacted flag correctly', () {
      final row = ConversationMessagesTableData(
        id: 'm-10',
        spaceId: 'ch-1',
        conversationId: 'ch-1',
        senderId: 'user',
        senderType: 'user',
        content: 'Compacted',
        messageType: 'text',
        answered: false,
        compacted: true,
        reverted: false,
        contentChars: 0,
        transcriptChars: 0,
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
        ConversationMessagesTableData(
          id: 'm-1',
          spaceId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'user',
          senderType: 'user',
          content: 'First',
          messageType: 'text',
          answered: false,
          compacted: false,
          reverted: false,
          contentChars: 0,
          transcriptChars: 0,
          createdAt: now,
        ),
        ConversationMessagesTableData(
          id: 'm-2',
          spaceId: 'ch-1',
          conversationId: 'ch-1',
          senderId: 'agent-1',
          senderType: 'agent',
          content: 'Second',
          messageType: 'text',
          answered: false,
          compacted: false,
          reverted: false,
          contentChars: 0,
          transcriptChars: 0,
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
