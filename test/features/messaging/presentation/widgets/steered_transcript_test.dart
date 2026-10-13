import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/steering_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_flow.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_items.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  final start = DateTime.utc(2026, 10, 12, 9, 52);
  Message steering(String id, int injected, {String state = 'injected'}) =>
      Message(
        id: id,
        spaceId: 'space',
        conversationId: 'conversation',
        senderId: 'user',
        senderType: SenderType.user,
        content: id,
        messageType: MessageType.steering,
        createdAt: start,
        metadata: {
          'steerState': state,
          'steerRunId': 'run',
          'steerInjectedAt': start
              .add(Duration(seconds: injected))
              .millisecondsSinceEpoch,
        },
      );
  final run = Message(
    id: 'run',
    spaceId: 'space',
    conversationId: 'conversation',
    senderId: 'agent',
    senderType: SenderType.agent,
    content: 'Answer',
    messageType: MessageType.agentTurn,
    createdAt: start,
  );

  test('injected messages belong to their run in injection order', () {
    final earlier = steering('earlier injection', 2);
    final later = steering('later injection', 4);
    final items = buildFeedItems([
      run,
      later,
      steering('still queued', 1, state: 'queued'),
      earlier,
    ], suppressOldestSeparator: true).whereType<MessageItem>().toList();
    expect(items.map((i) => i.message.id), ['run']);
    expect(items.single.inlineMessages.map((m) => m.id), [
      earlier.id,
      later.id,
    ]);
  });

  test('steering stays visible when its run is outside the loaded window', () {
    final message = steering('injected', 2);
    final items = buildFeedItems([
      message,
    ], suppressOldestSeparator: true).whereType<MessageItem>().toList();
    expect(items.single.message, message);
    expect(items.single.inlineMessages, isEmpty);
  });

  test('a foreign conversation cannot absorb the steering message', () {
    final foreign = Message(
      id: run.id,
      spaceId: run.spaceId,
      conversationId: 'another-conversation',
      senderId: run.senderId,
      senderType: run.senderType,
      content: run.content,
      messageType: run.messageType,
      createdAt: run.createdAt,
    );
    final message = steering('injected', 2);
    final items = buildFeedItems([
      foreign,
      message,
    ], suppressOldestSeparator: true).whereType<MessageItem>().toList();
    expect(items.map((i) => i.message.id), [foreign.id, message.id]);
    expect(items.first.inlineMessages, isEmpty);
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'persisted steering stays between preceding work and reply ($direction)',
      (tester) async {
        final first = steering('Use the staging configuration', 2);
        final second = steering('Do not commit', 4);
        await tester.pumpWidget(
          testWrap(
            SingleChildScrollView(
              child: TranscriptFlow(
                codeFont: 'monospace',
                inlineMessages: [first, second],
                segments: [
                  TextSegment(
                    text: 'Checking the changed files.',
                    startedAt: start,
                    durationMs: 10,
                  ),
                  TextSegment(
                    text: 'Running the requested configuration.',
                    startedAt: start.add(const Duration(seconds: 3)),
                    durationMs: 10,
                  ),
                  TextSegment(
                    text: 'Checks passed; nothing committed.',
                    startedAt: start.add(const Duration(seconds: 5)),
                    durationMs: 10,
                  ),
                ],
              ),
            ),
            textDirection: direction,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SteeringBubble), findsNWidgets(2));
        double top(String text) => tester
            .getTopLeft(find.textContaining(text, findRichText: true).first)
            .dy;
        expect(
          top('Checking the changed files.'),
          lessThan(top(first.content)),
        );
        expect(
          top(first.content),
          lessThan(top('Running the requested configuration.')),
        );
        expect(
          top('Running the requested configuration.'),
          lessThan(top(second.content)),
        );
        expect(
          top(second.content),
          lessThan(top('Checks passed; nothing committed.')),
        );
      },
    );
  }
}
