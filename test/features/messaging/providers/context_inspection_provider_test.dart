import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_harness/context.dart';
import 'package:control_center/features/messaging/providers/context_inspection_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Message _message(
  String id,
  String content, {
  bool compacted = false,
  SenderType senderType = SenderType.user,
}) => Message(
  id: id,
  spaceId: 'sp-1',
  conversationId: 'cv-1',
  senderId: 'sender-$id',
  senderType: senderType,
  content: content,
  messageType: MessageType.text,
  compacted: compacted,
  createdAt: DateTime(2026),
);

ContextSegment _segment(ContextSegmentKind kind, int tokens) =>
    ContextSegment(kind: kind, tokens: tokens, chars: tokens * 4);

ContextInspection _inspection(List<ContextSegment> segments) =>
    ContextInspection(
      workspaceId: 'ws-1',
      spaceId: 'sp-1',
      agentId: 'ag-1',
      agentName: 'Aria',
      mode: 'chat',
      windowTokens: 256000,
      segments: segments,
    );

void main() {
  group('formatContextTokenCount', () {
    test('keeps small counts verbatim', () {
      expect(formatContextTokenCount(832), '832');
      expect(formatContextTokenCount(0), '0');
      expect(formatContextTokenCount(999), '999');
    });

    test('scales thousands to one decimal', () {
      expect(formatContextTokenCount(177274), '177.3K');
      expect(formatContextTokenCount(1234), '1.2K');
    });

    test('drops a trailing .0', () {
      expect(formatContextTokenCount(256000), '256K');
      expect(formatContextTokenCount(1000), '1K');
    });

    test('scales millions', () {
      expect(formatContextTokenCount(1500000), '1.5M');
      expect(formatContextTokenCount(2000000), '2M');
    });
  });

  group('buildConversationContextSegment', () {
    test('skips compacted messages and carries content', () {
      final live = _message('m-1', 'hello world');
      final dead = _message('m-2', 'compacted away', compacted: true);

      final segment = buildConversationContextSegment([live, dead], 'Aria');

      expect(segment.kind, ContextSegmentKind.conversation);
      expect(segment.parts, hasLength(1));
      expect(segment.parts.single.id, 'm-1');
      expect(segment.parts.single.content, 'hello world');
      expect(segment.tokens, TokenEstimator.instance.estimate('hello world'));
    });

    test('labels agent turns with the agent name when known', () {
      final turn = Message(
        id: 'm-3',
        spaceId: 'sp-1',
        conversationId: 'cv-1',
        senderId: 'ag-1',
        senderType: SenderType.agent,
        content: '',
        messageType: MessageType.agentTurn,
        metadata: const {'transcriptChars': 380},
        createdAt: DateTime(2026),
      );

      final named = buildConversationContextSegment([turn], 'Aria');
      final anonymous = buildConversationContextSegment([turn], null);

      expect(named.parts.single.title, 'Aria');
      expect(anonymous.parts.single.title, 'ag-1');
    });
  });

  group('composeContextBreakdown', () {
    test(
      'orders segments by kind declaration order regardless of wire order',
      () {
        final inspection = _inspection([
          _segment(ContextSegmentKind.memory, 10),
          _segment(ContextSegmentKind.systemPrompt, 20),
          _segment(ContextSegmentKind.rules, 5),
        ]);
        final conversation = _segment(ContextSegmentKind.conversation, 7);

        final breakdown = composeContextBreakdown(
          inspection,
          conversation,
          0,
          isLoading: false,
          hasError: false,
        );

        expect(breakdown.segments.map((s) => s.kind), [
          ContextSegmentKind.systemPrompt,
          ContextSegmentKind.rules,
          ContextSegmentKind.memory,
          ContextSegmentKind.conversation,
        ]);
        // Persistent (20+5+10) + conversation (7), with NO synthetic overhead.
        expect(breakdown.totalTokens, 42);
        expect(breakdown.windowTokens, 256000);
        expect(breakdown.fraction, closeTo(42 / 256000, 1e-9));
      },
    );

    test('falls back to the client window estimate until the server lands', () {
      final breakdown = composeContextBreakdown(
        null,
        _segment(ContextSegmentKind.conversation, 7),
        100000,
        isLoading: true,
        hasError: false,
      );

      expect(breakdown.inspection, isNull);
      expect(breakdown.segments.single.kind, ContextSegmentKind.conversation);
      expect(breakdown.totalTokens, 7);
      expect(breakdown.windowTokens, 100000);
    });
  });
}
