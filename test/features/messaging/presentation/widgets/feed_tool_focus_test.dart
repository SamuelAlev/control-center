import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_plan.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_items.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/feed_rows.dart';
import 'package:flutter_test/flutter_test.dart';

final _ts = DateTime.utc(2026, 11, 17);

TurnPartRow _scriptRow(
  String messageId,
  String toolCallId, {
  String toolName = 'repl',
}) {
  final segments = <TranscriptSegment>[
    ToolSegment(
      toolName: toolName,
      toolCallId: toolCallId,
      status: ToolSegmentStatus.ok,
      startedAt: _ts,
    ),
  ];
  return TurnPartRow(
    item: MessageItem(
      Message(
        id: messageId,
        spaceId: 'space',
        conversationId: 'conversation',
        senderId: 'agent',
        senderType: SenderType.agent,
        content: '',
        messageType: MessageType.text,
        createdAt: _ts,
      ),
    ),
    plan: SegmentRowPlan(
      index: 0,
      segment: segments.single,
      open: false,
      gapBefore: 0,
    ),
    segments: segments,
    isLive: false,
    isFirst: true,
  );
}

void main() {
  test('"Show script" finds the newest row with a repeated id', () {
    // Local models reuse `call_0` on every turn; the request comes from the
    // script running now, the latest row with that id.
    final rows = <FeedRow>[
      _scriptRow('m1', 'call_0'),
      _scriptRow('m2', 'call_1'),
      _scriptRow('m3', 'call_0'),
      _scriptRow('m4', 'call_2'),
    ];
    expect(latestRowShowingToolCall(rows, 'call_0'), 2);
    expect(latestRowShowingToolCall(rows, 'call_1'), 1);
    expect(latestRowShowingToolCall(rows, 'missing'), -1);
  });

  test('"Show script" lands only on a script row with the id', () {
    // On MCP the caller names the script's id. An id another call of the
    // run also holds (an earlier `Bash`, a later `read`) must never put the
    // person on that call's row instead of the script's. Only `repl` runs a
    // script: an `eval` cell calls no tools, so its row is not one.
    final rows = <FeedRow>[
      _scriptRow('m1', 'call_x', toolName: 'Bash'),
      _scriptRow('m2', 'call_y', toolName: 'mcp__cc__repl'),
      _scriptRow('m3', 'call_y', toolName: 'read'),
      _scriptRow('m4', 'call_e', toolName: 'eval'),
    ];
    expect(latestRowShowingToolCall(rows, 'call_x'), -1);
    expect(latestRowShowingToolCall(rows, 'call_y'), 1);
    expect(latestRowShowingToolCall(rows, 'call_e'), -1);
  });
}
