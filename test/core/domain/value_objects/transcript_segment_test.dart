import 'package:control_center/core/domain/value_objects/transcript_segment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  group('ToolSegmentStatus', () {
    test('has 4 values', () {
      expect(ToolSegmentStatus.values, hasLength(4));
    });
  });

  group('TurnOutcome codec', () {
    test('roundtrips each value', () {
      for (final o in TurnOutcome.values) {
        expect(turnOutcomeFromString(turnOutcomeToString(o)), o);
      }
    });

    test('returns null for unknown/absent', () {
      expect(turnOutcomeFromString(null), isNull);
      expect(turnOutcomeFromString('nope'), isNull);
    });
  });

  group('ReasoningSegment', () {
    test('JSON roundtrip', () {
      final seg = ReasoningSegment(text: 'pondering', startedAt: ts, durationMs: 1200);
      final decoded = TranscriptSegment.fromJson(seg.toJson());
      expect(decoded, isA<ReasoningSegment>());
      expect((decoded as ReasoningSegment).text, 'pondering');
      expect(decoded.durationMs, 1200);
      expect(decoded.startedAt, ts);
      expect(decoded, seg);
    });

    test('copyWith preserves startedAt', () {
      final seg = ReasoningSegment(text: 'a', startedAt: ts);
      final updated = seg.copyWith(text: 'ab', durationMs: 50);
      expect(updated.text, 'ab');
      expect(updated.durationMs, 50);
      expect(updated.startedAt, ts);
    });
  });

  group('TextSegment', () {
    test('JSON roundtrip', () {
      final seg = TextSegment(text: 'the answer', startedAt: ts);
      final decoded = TranscriptSegment.fromJson(seg.toJson());
      expect(decoded, isA<TextSegment>());
      expect((decoded as TextSegment).text, 'the answer');
      expect(decoded, seg);
    });
  });

  group('ToolSegment', () {
    test('JSON roundtrip with all fields', () {
      final seg = ToolSegment(
        toolName: 'Edit',
        toolCallId: 'call_1',
        inputs: {'file_path': 'lib/x.dart', 'old_string': 'a', 'new_string': 'b'},
        outputs: 'ok',
        status: ToolSegmentStatus.ok,
        startedAt: ts,
        durationMs: 320,
      );
      final decoded = TranscriptSegment.fromJson(seg.toJson()) as ToolSegment;
      expect(decoded.toolName, 'Edit');
      expect(decoded.toolCallId, 'call_1');
      expect(decoded.inputs, {'file_path': 'lib/x.dart', 'old_string': 'a', 'new_string': 'b'});
      expect(decoded.outputs, 'ok');
      expect(decoded.status, ToolSegmentStatus.ok);
      expect(decoded.durationMs, 320);
      expect(decoded, seg);
    });

    test('empty toolCallId omitted from JSON and decoded back to empty', () {
      final seg = ToolSegment(toolName: 'Read', toolCallId: '', startedAt: ts);
      final json = seg.toJson();
      expect(json.containsKey('toolCallId'), isFalse);
      final decoded = TranscriptSegment.fromJson(json) as ToolSegment;
      expect(decoded.toolCallId, '');
      expect(decoded.status, ToolSegmentStatus.running);
    });

    test('inputs deep equality', () {
      final a = ToolSegment(
        toolName: 'X',
        toolCallId: 'c',
        inputs: {'k': [1, 2, 3]},
        startedAt: ts,
      );
      final b = ToolSegment(
        toolName: 'X',
        toolCallId: 'c',
        inputs: {'k': [1, 2, 3]},
        startedAt: ts,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith updates status and outputs', () {
      final seg = ToolSegment(toolName: 'Bash', toolCallId: 'c', startedAt: ts);
      final done = seg.copyWith(
        outputs: 'done',
        status: ToolSegmentStatus.error,
        durationMs: 99,
      );
      expect(done.outputs, 'done');
      expect(done.isError, isTrue);
      expect(done.durationMs, 99);
      expect(done.toolCallId, 'c');
    });
  });

  group('ErrorSegment / ViolationSegment', () {
    test('error JSON roundtrip', () {
      final seg = ErrorSegment(
        message: 'rate limited',
        code: 'rate_limit_error',
        source: 'anthropic',
        startedAt: ts,
      );
      final decoded = TranscriptSegment.fromJson(seg.toJson()) as ErrorSegment;
      expect(decoded.message, 'rate limited');
      expect(decoded.code, 'rate_limit_error');
      expect(decoded.source, 'anthropic');
      expect(decoded, seg);
    });

    test('violation JSON roundtrip', () {
      final seg = ViolationSegment(
        message: 'blocked network',
        action: 'network-connect',
        target: 'example.com',
        suggestedCapability: 'network',
        startedAt: ts,
      );
      final decoded = TranscriptSegment.fromJson(seg.toJson()) as ViolationSegment;
      expect(decoded.action, 'network-connect');
      expect(decoded.target, 'example.com');
      expect(decoded.suggestedCapability, 'network');
      expect(decoded, seg);
    });
  });

  group('decode/encode transcript', () {
    test('encodes and decodes a mixed ordered list', () {
      final segments = <TranscriptSegment>[
        ReasoningSegment(text: 'think', startedAt: ts, durationMs: 10),
        ToolSegment(toolName: 'Read', toolCallId: 'c1', outputs: 'x', status: ToolSegmentStatus.ok, startedAt: ts),
        TextSegment(text: 'here', startedAt: ts),
      ];
      final encoded = encodeTranscript(segments);
      final decoded = decodeTranscript(encoded);
      expect(decoded, segments);
    });

    test('tolerant decode: non-list yields empty', () {
      expect(decodeTranscript(null), isEmpty);
      expect(decodeTranscript('nope'), isEmpty);
      expect(decodeTranscript(42), isEmpty);
    });

    test('tolerant decode: skips non-map entries', () {
      final decoded = decodeTranscript([
        {'type': 'text', 'text': 'ok', 'ts': ts.millisecondsSinceEpoch},
        'garbage',
        42,
      ]);
      expect(decoded, hasLength(1));
      expect(decoded.first, isA<TextSegment>());
    });

    test('unknown type decodes as reasoning fallback', () {
      final decoded = decodeTranscript([
        {'type': 'wat', 'text': 'fallback', 'ts': ts.millisecondsSinceEpoch},
      ]);
      expect(decoded.single, isA<ReasoningSegment>());
      expect((decoded.single as ReasoningSegment).text, 'fallback');
    });
  });
}
