import 'dart:convert';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/messaging/domain/services/conversation_export.dart';
import 'package:test/test.dart';

Message user(String content) => Message(
  id: 'm-${content.hashCode}',
  spaceId: 'sp',
  conversationId: 'c1',
  senderId: 'u1',
  senderType: SenderType.user,
  messageType: MessageType.text,
  content: content,
  createdAt: DateTime.utc(2026, 1, 1, 12),
);

/// A complete agent turn. `transcript` is decoded from `metadata['segments']`,
/// so the fixture has to go in the way the real write path does.
Message agent(String content, {List<TranscriptSegment> segments = const []}) =>
    Message(
      id: 'a-${content.hashCode}',
      spaceId: 'sp',
      conversationId: 'c1',
      senderId: 'agent-1',
      senderType: SenderType.agent,
      messageType: MessageType.agentTurn,
      content: content,
      metadata: {
        'agentName': 'Architect',
        if (segments.isNotEmpty)
          'segments': jsonDecode(
            jsonEncode([for (final s in segments) s.toJson()]),
          ),
      },
      createdAt: DateTime.utc(2026, 1, 1, 12, 1),
    );

void main() {
  group('renderConversationHtml', () {
    test('is a complete document with no external references', () {
      // An export that needs the network stops working the moment it leaves
      // the machine it was made on — which is the only reason anyone exports.
      final html = renderConversationHtml(
        title: 'Fixing auth',
        messages: [user('hello'), agent('hi')],
      );
      expect(html, startsWith('<!doctype html>'));
      expect(html, contains('</html>'));
      expect(html, contains('<style>'));
      expect(html, isNot(contains('<script src=')));
      expect(html, isNot(contains('href="http')));
      expect(html, isNot(contains('<img src="http')));
    });

    test('escapes content rather than letting it become markup', () {
      // A transcript is full of tool arguments and file contents, which is to
      // say arbitrary text that regularly contains `<` and `&`.
      final html = renderConversationHtml(
        title: 'x',
        messages: [user('if (a < b && c) { }')],
      );
      expect(html, contains('a &lt; b &amp;&amp; c'));
      expect(html, isNot(contains('<b &&')));
    });

    test('escapes the title too', () {
      final html = renderConversationHtml(
        title: '<script>alert(1)</script>',
        messages: const [],
      );
      expect(html, isNot(contains('<script>alert')));
      expect(html, contains('&lt;script&gt;'));
    });

    test('names the agent from its metadata', () {
      final html = renderConversationHtml(
        title: 'x',
        messages: [agent('done')],
      );
      expect(html, contains('Architect'));
    });

    test('renders a tool call as a collapsed card with both sides', () {
      final html = renderConversationHtml(
        title: 'x',
        messages: [
          agent('', segments: [
            ToolSegment(
              startedAt: DateTime.utc(2026),
              toolName: 'read',
              toolCallId: 't1',
              inputs: {'path': 'lib/auth.dart'},
              outputs: 'class Auth {}',
            ),
          ]),
        ],
      );
      expect(html, contains('<details class="tool"'));
      expect(html, contains('lib/auth.dart'));
      expect(html, contains('class Auth {}'));
    });

    test('marks a failed tool so a skim finds it', () {
      final html = renderConversationHtml(
        title: 'x',
        messages: [
          agent('', segments: [
            ToolSegment(
              startedAt: DateTime.utc(2026),
              toolName: 'bash',
              toolCallId: 't1',
              outputs: 'command not found',
              status: ToolSegmentStatus.error,
            ),
          ]),
        ],
      );
      expect(html, contains('tool err'));
      expect(html, contains('— failed'));
    });

    test('an empty conversation still produces a valid page', () {
      final html = renderConversationHtml(title: 'empty', messages: const []);
      expect(html, contains('0 messages'));
      expect(html, contains('</html>'));
    });
  });

  group('renderConversationMarkdown', () {
    test('keeps speaker, text and tool detail', () {
      final md = renderConversationMarkdown(
        title: 'Fixing auth',
        messages: [
          user('why is login failing?'),
          agent('looking', segments: [
            ToolSegment(
              startedAt: DateTime.utc(2026),
              toolName: 'grep',
              toolCallId: 't1',
              inputs: {'pattern': 'login'},
              outputs: 'lib/auth.dart:12',
            ),
          ]),
        ],
      );
      expect(md, startsWith('# Fixing auth'));
      expect(md, contains('## You —'));
      expect(md, contains('## Architect —'));
      expect(md, contains('why is login failing?'));
      expect(md, contains('<summary>grep</summary>'));
      expect(md, contains('lib/auth.dart:12'));
    });

    test('does not paste raw reasoning into an issue', () {
      // Thinking is the model's scratch space; a transcript pasted into a bug
      // report is read by a person, and it is not what they asked for.
      final md = renderConversationMarkdown(
        title: 'x',
        messages: [
          agent('the answer', segments: [
            ReasoningSegment(startedAt: DateTime.utc(2026), text: 'private deliberation'),
          ]),
        ],
      );
      expect(md, isNot(contains('private deliberation')));
      expect(md, contains('the answer'));
    });
  });
}
