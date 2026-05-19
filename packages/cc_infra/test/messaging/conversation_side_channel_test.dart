import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_infra/src/messaging/conversation_side_channel_service.dart';
import 'package:test/test.dart';

Message _user(String text) => Message(
  id: 'u',
  spaceId: 's',
  conversationId: 'c',
  senderId: 'me',
  senderType: SenderType.user,
  content: text,
  messageType: MessageType.text,
  createdAt: DateTime(2026),
);

Message _agent({String content = '', List<TranscriptSegment> segments = const []}) =>
    Message(
      id: 'a',
      spaceId: 's',
      conversationId: 'c',
      senderId: 'agent-1',
      senderType: SenderType.agent,
      messageType: MessageType.agentTurn,
      content: content,
      createdAt: DateTime(2026),
      metadata: {
        'agentName': 'Scout',
        if (segments.isNotEmpty) 'segments': encodeTranscript(segments),
      },
    );

void main() {
  group('renderConversationForSideChannel', () {
    test('labels each speaker', () {
      final out = renderConversationForSideChannel([
        _user('fix the tests'),
        _agent(content: 'done'),
      ]);
      expect(out, contains('User: fix the tests'));
      expect(out, contains('Scout: done'));
    });

    test('renders an agent turn from its transcript segments', () {
      // Agent turns carry their substance in segments, not `content`.
      final out = renderConversationForSideChannel([
        _agent(
          segments: [
            TextSegment(text: 'I looked at auth.', startedAt: DateTime(2026)),
            ToolSegment(
              toolName: 'edit',
              toolCallId: 't1',
              inputs: const {'path': 'lib/auth.dart'},
              startedAt: DateTime(2026),
            ),
          ],
        ),
      ]);
      expect(out, contains('I looked at auth.'));
      expect(
        out,
        contains('[edit lib/auth.dart]'),
        reason: 'the tool CALL is the useful signal for a handoff',
      );
    });

    test('keeps the NEWEST messages when it must cut', () {
      // A handoff is about where the work stands; dropping the tail to keep
      // the opening answers about the wrong end of the conversation.
      final messages = [
        for (var i = 0; i < 50; i++) _user('message number $i with padding'),
      ];
      final out = renderConversationForSideChannel(messages, maxChars: 200);
      expect(out, contains('message number 49'));
      expect(out, isNot(contains('message number 0 ')));
      expect(out, contains('earlier conversation omitted'));
    });

    test('preserves chronological order after truncation', () {
      final messages = [for (var i = 0; i < 10; i++) _user('m$i')];
      final out = renderConversationForSideChannel(messages, maxChars: 60);
      final positions = [
        for (final m in ['m7', 'm8', 'm9'])
          if (out.contains(m)) out.indexOf(m),
      ];
      expect(
        positions,
        orderedEquals([...positions]..sort()),
        reason: 'reading backwards would confuse the model about what came '
            'first',
      );
    });

    test('skips empty messages', () {
      final out = renderConversationForSideChannel([
        _user('   '),
        _user('real'),
      ]);
      expect(out.trim(), 'User: real');
    });

    test('an empty conversation renders empty', () {
      expect(renderConversationForSideChannel(const []), isEmpty);
    });
  });
}
