import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event_codec.dart';
import 'package:test/test.dart';

/// A tool result's `outcome` (denied, cancelled, timed out, or a script's
/// status) is carried end to end, so a client never parses result text.
void main() {
  group('ToolResultEvent.outcome', () {
    test('round-trips through the codec and the metadata', () {
      final event = ToolResultEvent(
        toolCallId: 'call-1/2',
        outputs: 'User denied: not now',
        isError: true,
        parentToolCallId: 'call-1',
        outcome: 'denied',
        timestamp: DateTime.utc(2026),
      );
      final wire = AgentProcessEventCodec.toWire(event);
      expect(wire['outcome'], 'denied');
      final back = AgentProcessEventCodec.fromWire(wire) as ToolResultEvent;
      expect(back.outcome, 'denied');
      expect(back.parentToolCallId, 'call-1');
      expect(event.metadata['outcome'], 'denied');
    });

    test('is omitted when there is nothing finer to say', () {
      final event = ToolResultEvent(toolCallId: 'c', outputs: 'ok');
      expect(event.outcome, isNull);
      expect(event.metadata.containsKey('outcome'), isFalse);
      expect(
        AgentProcessEventCodec.toWire(event).containsKey('outcome'),
        isFalse,
      );
      final back =
          AgentProcessEventCodec.fromWire(AgentProcessEventCodec.toWire(event))
              as ToolResultEvent;
      expect(back.outcome, isNull);
    });
  });

  group('ToolSegment.outcome', () {
    final started = DateTime.fromMillisecondsSinceEpoch(1000);

    test('round-trips through JSON, equality and copyWith', () {
      final segment = ToolSegment(
        toolName: 'repl',
        toolCallId: 'call-1',
        startedAt: started,
        status: ToolSegmentStatus.error,
        outcome: 'timed_out',
      );
      expect(segment.toJson()['outcome'], 'timed_out');
      final back = TranscriptSegment.fromJson(segment.toJson()) as ToolSegment;
      expect(back, segment);
      expect(back.hashCode, segment.hashCode);
      expect(segment.copyWith(outputs: 'more').outcome, 'timed_out');
      expect(segment.copyWith(outcome: 'cancelled').outcome, 'cancelled');
    });

    test('is part of equality and omitted when null', () {
      final plain = ToolSegment(
        toolName: 'edit',
        toolCallId: 'x',
        startedAt: started,
      );
      final denied = ToolSegment(
        toolName: 'edit',
        toolCallId: 'x',
        startedAt: started,
        outcome: 'denied',
      );
      expect(plain, isNot(denied));
      expect(plain.toJson().containsKey('outcome'), isFalse);
      expect(
        (TranscriptSegment.fromJson(plain.toJson()) as ToolSegment).outcome,
        isNull,
      );
    });
  });
}
