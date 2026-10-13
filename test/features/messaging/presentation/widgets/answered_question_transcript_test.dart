import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/features/messaging/presentation/widgets/ask_user/ask_user_summary.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/question_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/steering_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_flow.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_segment_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_items.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

final _start = DateTime.utc(2026, 10, 13, 19, 39);

Message _run(
  String id, {
  int at = 0,
  String spaceId = 'space',
  String conversationId = 'conversation',
  String agentId = 'agent',
}) => Message(
  id: id,
  spaceId: spaceId,
  conversationId: conversationId,
  senderId: agentId,
  senderType: SenderType.agent,
  content: '',
  messageType: MessageType.agentTurn,
  createdAt: _start.add(Duration(seconds: at)),
);

Message _question(String id, {int at = 2, bool answered = true}) => Message(
  id: id,
  spaceId: 'space',
  conversationId: 'conversation',
  senderId: 'agent',
  senderType: SenderType.agent,
  content: 'How far should the Navigation drawer header go?',
  messageType: MessageType.userQuestion,
  createdAt: _start.add(Duration(seconds: at)),
  metadata: {
    'answered': answered,
    'options': [
      {'label': 'All topbar-dropdown drawers', 'value': 'all'},
    ],
    if (answered)
      'answer': {
        'selected': ['all'],
        'freeText': 'Keep the existing titles.',
      },
  },
);

List<MessageItem> _items(List<Message> messages) => buildFeedItems(
  messages,
  suppressOldestSeparator: true,
).whereType<MessageItem>().toList();

void main() {
  test('answers join the preceding turn of the asking agent only once', () {
    final first = _question('first');
    final second = _question('second', at: 5);
    final items = _items([
      _run('first-run'),
      first,
      _run('second-run', at: 3),
      _run('other-agent', at: 4, agentId: 'another-agent'),
      second,
    ]);

    expect(items.map((i) => i.message.id), [
      'first-run',
      'second-run',
      'other-agent',
    ]);
    expect(items[0].inlineMessages, [first]);
    expect(items[1].inlineMessages, [second]);
    expect(items[2].inlineMessages, isEmpty);
  });

  test('a pending question stays standalone until its answer arrives', () {
    final run = _run('run');
    final pending = _question('question', answered: false);
    final before = _items([run, pending]);
    expect(before.map((i) => i.message.id), ['run', 'question']);
    expect(before.first.inlineMessages, isEmpty);

    final answered = _question('question');
    final after = _items([run, answered]);
    expect(after.map((i) => i.message.id), ['run']);
    expect(after.single.inlineMessages, [answered]);
  });

  test('an answer stays visible until pagination loads its earlier turn', () {
    final answer = _question('question');
    final newer = _run('newer', at: 3);
    final before = _items([answer, newer]);
    expect(before.map((i) => i.message.id), ['question', 'newer']);
    expect(before.last.inlineMessages, isEmpty);

    final after = _items([_run('older'), answer, newer]);
    expect(after.map((i) => i.message.id), ['older', 'newer']);
    expect(after.first.inlineMessages, [answer]);
    expect(after.last.inlineMessages, isEmpty);
  });

  for (final foreign in [
    _run('foreign-space', spaceId: 'another-space'),
    _run('foreign-conversation', conversationId: 'another-conversation'),
    _run('foreign-agent', agentId: 'another-agent'),
  ]) {
    test('${foreign.id} cannot absorb an answered question', () {
      final answer = _question('question');
      final items = _items([foreign, answer]);
      expect(items.map((i) => i.message.id), [foreign.id, answer.id]);
      expect(items.first.inlineMessages, isEmpty);
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('answers and steering precede subsequent work ($direction)', (
      tester,
    ) async {
      final question = _question('question');
      final steering = Message(
        id: 'steering',
        spaceId: 'space',
        conversationId: 'conversation',
        senderId: 'user',
        senderType: SenderType.user,
        content: 'Do not commit',
        messageType: MessageType.steering,
        createdAt: _start.add(const Duration(seconds: 1)),
        metadata: {
          'steerState': 'injected',
          'steerRunId': 'run',
          'steerInjectedAt': _start
              .add(const Duration(seconds: 4))
              .millisecondsSinceEpoch,
        },
      );
      final items = _items([_run('run'), steering, question]);
      await tester.pumpWidget(
        testWrap(
          SingleChildScrollView(
            child: TranscriptFlow(
              codeFont: 'monospace',
              inlineMessages: items.single.inlineMessages,
              segments: [
                ToolSegment(
                  toolName: 'ask_user',
                  toolCallId: 'ask',
                  inputs: {'question': question.content},
                  status: ToolSegmentStatus.ok,
                  startedAt: _start.add(const Duration(seconds: 1)),
                  durationMs: 1500,
                ),
                TextSegment(
                  text: 'Going with all topbar-dropdown drawers.',
                  startedAt: _start.add(const Duration(seconds: 3)),
                  durationMs: 10,
                ),
                TextSegment(
                  text: 'The drawer headers are updated.',
                  startedAt: _start.add(const Duration(seconds: 5)),
                  durationMs: 10,
                ),
              ],
            ),
          ),
          textDirection: direction,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AskUserSummary), findsOneWidget);
      expect(find.byType(QuestionBubble), findsOneWidget);
      expect(find.text('All topbar-dropdown drawers'), findsOneWidget);
      expect(find.text('Keep the existing titles.'), findsOneWidget);
      double top(Finder finder) => tester.getTopLeft(finder.first).dy;
      final summary = find.byType(AskUserSummary);
      final continued = find.textContaining(
        'Going with all topbar-dropdown drawers.',
        findRichText: true,
      );
      expect(top(find.byType(TranscriptSegmentRow)), lessThan(top(summary)));
      expect(top(summary), lessThan(top(continued)));
      expect(top(continued), lessThan(top(find.byType(SteeringBubble))));
      expect(
        top(find.byType(SteeringBubble)),
        lessThan(
          top(
            find.textContaining(
              'The drawer headers are updated.',
              findRichText: true,
            ),
          ),
        ),
      );
    });
  }
}
