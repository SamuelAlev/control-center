import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_conversation_context_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to create a [ChannelMessage] with minimal fields.
ChannelMessage _msg({
  required String id,
  required String senderId,
  required String content,
  ChannelSenderType senderType = ChannelSenderType.user,
  DateTime? createdAt,
}) =>
    ChannelMessage(
      id: id,
      channelId: 'ch1',
      senderId: senderId,
      senderType: senderType,
      messageType: ChannelMessageType.text,
      content: content,
      createdAt: createdAt ?? DateTime(2025, 6, 1, 12, 0),
    );

void main() {
  group('buildConversationContextPure', () {
    const channelId = 'ch1';
    const selfId = 'agent-self';
    const selfName = 'HelperBot';

    test('returns empty string when all lists empty', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [],
        summaries: [],
        semanticHits: [],
      );
      expect(result, '');
    });

    test('includes summaries section', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [],
        summaries: [
          _msg(id: 's1', senderId: 'user', content: 'Summary of earlier work'),
        ],
        semanticHits: [],
      );
      expect(result, contains('### Earlier (summary)'));
      expect(result, contains('Summary of earlier work'));
      expect(result, startsWith('## Conversation History'));
    });

    test('multiple summaries', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [],
        summaries: [
          _msg(id: 's1', senderId: 'user', content: 'First summary'),
          _msg(id: 's2', senderId: 'user', content: 'Second summary'),
        ],
        semanticHits: [],
      );
      expect(result, contains('First summary'));
      expect(result, contains('Second summary'));
    });

    test('includes semantic hits section', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [],
        summaries: [],
        semanticHits: [
          _msg(id: 'h1', senderId: 'user', content: 'Relevant old message'),
        ],
      );
      expect(result, contains('### Possibly relevant earlier messages'));
      expect(result, contains('Relevant old message'));
    });

    test('includes verbatim window section', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [
          _msg(id: 'v1', senderId: 'user', content: 'Latest message'),
        ],
        summaries: [],
        semanticHits: [],
      );
      expect(result, contains('### Recent messages'));
      expect(result, contains('Latest message'));
    });

    test('labels self as "you"', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [
          _msg(id: 'v1', senderId: selfId, content: 'I will help'),
        ],
        summaries: [],
        semanticHits: [],
      );
      expect(result, contains('[you ·'));
    });

    test('labels user messages as "user"', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [
          _msg(
            id: 'v1',
            senderId: 'someone',
            senderType: ChannelSenderType.user,
            content: 'Hello',
          ),
        ],
        summaries: [],
        semanticHits: [],
      );
      expect(result, contains('[user ·'));
    });

    test('labels other agents by self name', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [
          _msg(
            id: 'v1',
            senderId: 'other-agent',
            senderType: ChannelSenderType.agent,
            content: 'Hi',
          ),
        ],
        summaries: [],
        semanticHits: [],
      );
      expect(result, contains('[$selfName ·'));
    });

    test('includes just now for very recent messages', () {
      final now = DateTime.now();
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [
          _msg(id: 'v1', senderId: 'user', content: 'x', createdAt: now),
        ],
        summaries: [],
        semanticHits: [],
      );
      expect(result, contains('just now'));
    });

    test('includes minutes-ago format', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [
          _msg(
            id: 'v1',
            senderId: 'user',
            content: 'x',
            createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
        summaries: [],
        semanticHits: [],
      );
      expect(result, contains('30m ago'));
    });

    test('includes hours-ago format', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [
          _msg(
            id: 'v1',
            senderId: 'user',
            content: 'x',
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ],
        summaries: [],
        semanticHits: [],
      );
      expect(result, contains('3h ago'));
    });

    test('includes date-time format for old messages', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [
          _msg(
            id: 'v1',
            senderId: 'user',
            content: 'x',
            createdAt: DateTime(2024, 1, 15, 9, 30),
          ),
        ],
        summaries: [],
        semanticHits: [],
      );
      expect(result, contains('2024-01-15 09:30'));
    });

    test('all three sections appear together', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [
          _msg(id: 'v1', senderId: 'user', content: 'Recent'),
        ],
        summaries: [
          _msg(id: 's1', senderId: 'user', content: 'Summary'),
        ],
        semanticHits: [
          _msg(id: 'h1', senderId: 'user', content: 'Old relevant'),
        ],
      );
      expect(result, contains('### Earlier (summary)'));
      expect(result, contains('### Possibly relevant earlier messages'));
      expect(result, contains('### Recent messages'));
      expect(result, contains('Recent'));
      expect(result, contains('Summary'));
      expect(result, contains('Old relevant'));
    });

    test('trims trailing whitespace from content', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [],
        verbatimWindow: [
          _msg(id: 'v1', senderId: 'user', content: 'Hello   \n  '),
        ],
        summaries: [],
        semanticHits: [],
      );
      expect(result, contains('Hello'));
    });

    test('messages list is unused but accepted', () {
      final result = buildConversationContextPure(
        channelId: channelId,
        selfAgentId: selfId,
        selfAgentName: selfName,
        messages: [
          _msg(id: 'm1', senderId: 'user', content: 'raw message'),
        ],
        verbatimWindow: [
          _msg(id: 'v1', senderId: 'user', content: 'in window'),
        ],
        summaries: [],
        semanticHits: [],
      );
      expect(result, contains('in window'));
    });
  });
}
