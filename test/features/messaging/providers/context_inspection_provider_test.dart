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

ContextInspection _inspection(
  List<ContextSegment> segments, {
  ContextRunner runner = ContextRunner.harness,
}) => ContextInspection(
  workspaceId: 'ws-1',
  spaceId: 'sp-1',
  agentId: 'ag-1',
  agentName: 'Aria',
  mode: 'chat',
  runner: runner,
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

    test('a harness reading is the total; the conversation takes the rest', () {
      final inspection = _inspection([
        _segment(ContextSegmentKind.systemPrompt, 20000),
        _segment(ContextSegmentKind.toolDefinitions, 30000),
      ]);
      final breakdown = composeContextBreakdown(
        inspection,
        // The stored transcript estimate — what the meter used to show.
        _segment(ContextSegmentKind.conversation, 310000),
        0,
        reported: (tokens: 140000, windowTokens: 200000),
        isLoading: false,
        hasError: false,
      );

      expect(breakdown.isMeasured, isTrue);
      expect(breakdown.totalTokens, 140000);
      expect(breakdown.windowTokens, 200000);
      final conversation = breakdown.segments.singleWhere(
        (s) => s.kind == ContextSegmentKind.conversation,
      );
      expect(conversation.tokens, 90000);
    });

    test('a Claude Code reading sizes the runner, not the conversation', () {
      final inspection = _inspection([
        _segment(ContextSegmentKind.systemPrompt, 3000),
        const ContextSegment(
          kind: ContextSegmentKind.conversation,
          tokens: 12000,
          chars: 48000,
          parts: [
            ContextPart(
              id: 'conversation:history-block',
              title: 'Conversation history',
              tokens: 12000,
              chars: 48000,
            ),
          ],
        ),
        const ContextSegment(
          kind: ContextSegmentKind.runner,
          tokens: 0,
          chars: 0,
          parts: [
            ContextPart(
              id: 'runner:claude-code',
              title: 'Claude Code',
              tokens: 0,
              chars: 0,
            ),
          ],
        ),
      ], runner: ContextRunner.claudeCode);
      final breakdown = composeContextBreakdown(
        inspection,
        _segment(ContextSegmentKind.conversation, 310000),
        0,
        reported: (tokens: 60000, windowTokens: 1000000),
        isLoading: false,
        hasError: false,
      );

      expect(breakdown.totalTokens, 60000);
      expect(breakdown.windowTokens, 1000000);
      // The history block the run receives, never the stored transcript.
      expect(
        breakdown.segments
            .singleWhere((s) => s.kind == ContextSegmentKind.conversation)
            .tokens,
        12000,
      );
      final runner = breakdown.segments.singleWhere(
        (s) => s.kind == ContextSegmentKind.runner,
      );
      expect(runner.tokens, 45000);
      expect(runner.parts.single.tokens, 45000);
      // The bar's segments add up to the reported total.
      expect(
        breakdown.segments.fold<int>(0, (sum, s) => sum + s.tokens),
        60000,
      );
    });

    test('estimates stay estimates until a run reports', () {
      final breakdown = composeContextBreakdown(
        _inspection([_segment(ContextSegmentKind.systemPrompt, 20)]),
        _segment(ContextSegmentKind.conversation, 7),
        0,
        isLoading: false,
        hasError: false,
      );
      expect(breakdown.isMeasured, isFalse);
      expect(breakdown.totalTokens, 27);
    });

    test('a reading below the known parts never goes negative', () {
      final breakdown = composeContextBreakdown(
        _inspection([_segment(ContextSegmentKind.systemPrompt, 5000)]),
        _segment(ContextSegmentKind.conversation, 7),
        0,
        reported: (tokens: 4000, windowTokens: null),
        isLoading: false,
        hasError: false,
      );
      expect(
        breakdown.segments
            .singleWhere((s) => s.kind == ContextSegmentKind.conversation)
            .tokens,
        0,
      );
      // No reported window: the inspection's stands.
      expect(breakdown.windowTokens, 256000);
    });
  });
}
