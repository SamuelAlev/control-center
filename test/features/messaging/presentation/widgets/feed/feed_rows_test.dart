import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_plan.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_items.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_rows.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 1, 1, 12);

Message _message(
  String id, {
  MessageType type = MessageType.agentTurn,
  SenderType sender = SenderType.agent,
  DateTime? at,
}) => Message(
  id: id,
  spaceId: 's',
  conversationId: 's',
  senderId: sender == SenderType.agent ? 'agent-1' : 'user-1',
  senderType: sender,
  content: 'answer',
  messageType: type,
  createdAt: at ?? _t0,
);

TextSegment _text(String text, int second, {bool closed = true}) => TextSegment(
  text: text,
  startedAt: _t0.add(Duration(seconds: second)),
  durationMs: closed ? 10 : null,
);

ToolSegment _tool(int second, {bool running = false}) => ToolSegment(
  toolName: 'Bash',
  toolCallId: 'call-$second',
  status: running ? ToolSegmentStatus.running : ToolSegmentStatus.ok,
  startedAt: _t0.add(Duration(seconds: second)),
);

void main() {
  group('expandFeedRows', () {
    test('an agent turn with a known transcript spans head, parts, foot', () {
      final turn = MessageItem(_message('a'));
      final rows = expandFeedRows(
        [
          MessageItem(
            _message('u', type: MessageType.text, sender: SenderType.user),
          ),
          turn,
        ],
        transcriptOf: (item) => item.message.id == 'a'
            ? (
                segments: [_text('hi', 1), _tool(2), _text('done', 3)],
                isLive: false,
              )
            : null,
      );
      expect(rows.map((r) => r.key), [
        'm:u',
        'm:a#h',
        'm:a#s0',
        'm:a#s1',
        'm:a#s2',
        'm:a#f',
      ]);
      final parts = rows.whereType<TurnPartRow>().toList();
      expect(parts.first.isFirst, isTrue);
      expect(parts.skip(1).every((p) => !p.isFirst), isTrue);
    });

    test('a turn whose transcript is unknown stays one row', () {
      final rows = expandFeedRows([
        MessageItem(_message('a')),
      ], transcriptOf: (_) => null);
      expect(rows.single, isA<ItemRow>());
      expect(rows.single.key, 'm:a');
    });

    test('a transcript of only blank prose stays one row', () {
      final rows = expandFeedRows([
        MessageItem(_message('a')),
      ], transcriptOf: (_) => (segments: [_text('  ', 1)], isLive: false));
      expect(rows.single, isA<ItemRow>());
    });

    test('separators and the unread divider are single rows', () {
      final rows = expandFeedRows([
        DayItem(DateTime(2026, 1, 1)),
        const UnreadItem(),
      ], transcriptOf: (_) => null);
      expect(rows.map((r) => r.key), ['d:2026-1-1', 'unread']);
    });
  });

  group('row keys', () {
    test('every row of a message maps back to it', () {
      expect(messageIdOfRowKey('m:abc'), 'abc');
      expect(messageIdOfRowKey('m:abc#h'), 'abc');
      expect(messageIdOfRowKey('m:abc#s12'), 'abc');
      expect(messageIdOfRowKey('m:abc#qxyz'), 'abc');
      expect(messageIdOfRowKey('d:2026-1-1'), isNull);
      expect(messageIdOfRowKey('unread'), isNull);
      expect(messageIdOfRowKey('more'), isNull);
    });
  });

  group('planTranscriptRows', () {
    test('steering lands at its point in the run', () {
      final steer = _message(
        'q1',
        type: MessageType.text,
        sender: SenderType.user,
        at: _t0.add(const Duration(milliseconds: 1500)),
      );
      final plan = planTranscriptRows(
        segments: [_text('first', 1), _text('second', 2)],
        inlineMessages: [steer],
        isLive: false,
      );
      expect(plan.map((p) => p.id), ['s0', 'qq1', 's1']);
      expect(plan.first.gapBefore, 0);
    });

    test('a live turn closes with the status line unless prose streams', () {
      final working = planTranscriptRows(
        segments: [_text('first', 1), _tool(2, running: true)],
        inlineMessages: const [],
        isLive: true,
      );
      expect(working.last, isA<LiveStatusRowPlan>());
      expect((working[1] as SegmentRowPlan).open, isTrue);

      final settled = planTranscriptRows(
        segments: [_text('first', 1), _tool(2)],
        inlineMessages: const [],
        isLive: false,
      );
      expect(settled.whereType<LiveStatusRowPlan>(), isEmpty);
      expect(settled.whereType<SegmentRowPlan>().any((p) => p.open), isFalse);
    });

    test('open prose is kept while blank, closed blank prose is dropped', () {
      final live = planTranscriptRows(
        segments: [_text('', 1, closed: false)],
        inlineMessages: const [],
        isLive: true,
      );
      expect(live.whereType<SegmentRowPlan>().single.open, isTrue);

      final done = planTranscriptRows(
        segments: [_text('', 1), _text('kept', 2)],
        inlineMessages: const [],
        isLive: false,
      );
      expect(done.map((p) => p.id), ['s1']);
    });
  });
}
