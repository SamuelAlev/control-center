import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:test/test.dart';

/// Exercises [TranscriptSegment.fromJson] — the sealed-union dispatcher that
/// decodes a wire map into the right segment subtype — plus each subtype's
/// `toJson` round-trip and equality.
void main() {
  // A fixed epoch so const constructors aren't needed and equality is stable.
  final t0 = DateTime.fromMillisecondsSinceEpoch(100);

  group('TranscriptSegment.fromJson dispatcher', () {
    test('decodes a reasoning segment', () {
      final s = TranscriptSegment.fromJson({
        'type': 'reasoning',
        'text': 'hmm',
      });
      expect(s, isA<ReasoningSegment>());
      expect((s as ReasoningSegment).text, 'hmm');
    });

    test('defaults to reasoning for an unknown/missing type', () {
      final s = TranscriptSegment.fromJson({'type': 'mystery', 'text': 'x'});
      expect(s, isA<ReasoningSegment>());
    });

    test('decodes a text segment', () {
      final s = TranscriptSegment.fromJson({'type': 'text', 'text': 'hello'});
      expect(s, isA<TextSegment>());
      expect((s as TextSegment).text, 'hello');
    });

    test('decodes a tool segment with all fields', () {
      final s = TranscriptSegment.fromJson({
        'type': 'tool',
        'toolName': 'edit_file',
        'toolCallId': 'tc-1',
        'inputs': {'path': '/x'},
        'outputs': 'done',
        'status': 'completed',
        'ts': 1000,
        'durationMs': 50,
      });
      expect(s, isA<ToolSegment>());
      final t = s as ToolSegment;
      expect(t.toolName, 'edit_file');
      expect(t.toolCallId, 'tc-1');
      expect(t.inputs?['path'], '/x');
      expect(t.outputs, 'done');
      expect(t.startedAt, DateTime.fromMillisecondsSinceEpoch(1000));
      expect(t.durationMs, 50);
    });

    test('decodes a tool segment with a prunedAt timestamp', () {
      final s = TranscriptSegment.fromJson({
        'type': 'tool',
        'toolName': 't',
        'prunedAt': 5000,
      });
      expect(
        (s as ToolSegment).prunedAt,
        DateTime.fromMillisecondsSinceEpoch(5000),
      );
    });

    test('decodes an error segment', () {
      final s = TranscriptSegment.fromJson({
        'type': 'error',
        'message': 'boom',
        'code': 'E1',
        'source': 'harness',
      });
      expect(s, isA<ErrorSegment>());
      final e = s as ErrorSegment;
      expect(e.message, 'boom');
      expect(e.code, 'E1');
      expect(e.source, 'harness');
    });

    test('decodes a violation segment', () {
      final s = TranscriptSegment.fromJson({
        'type': 'violation',
        'message': 'denied',
        'action': 'fileDelete',
        'target': '/secret',
      });
      expect(s, isA<ViolationSegment>());
      final v = s as ViolationSegment;
      expect(v.message, 'denied');
      expect(v.action, 'fileDelete');
      expect(v.target, '/secret');
    });

    test('missing fields fall back to safe defaults', () {
      final s = TranscriptSegment.fromJson({'type': 'text'});
      expect((s as TextSegment).text, '');
    });
  });

  group('TranscriptSegment toJson round-trip', () {
    test('text segment round-trips', () {
      final original = TextSegment(text: 'hi', startedAt: t0, durationMs: 5);
      final roundTripped = TranscriptSegment.fromJson(original.toJson());
      expect(roundTripped, original);
    });

    test('reasoning segment round-trips', () {
      final original = ReasoningSegment(
        text: 'thinking',
        startedAt: t0,
        durationMs: 10,
      );
      final roundTripped = TranscriptSegment.fromJson(original.toJson());
      expect(roundTripped, original);
    });

    test('tool segment round-trips', () {
      final original = ToolSegment(
        toolName: 'bash',
        toolCallId: 'tc-1',
        inputs: {'command': 'ls'},
        outputs: 'output',
        startedAt: t0,
      );
      final roundTripped = TranscriptSegment.fromJson(original.toJson());
      expect(roundTripped, original);
    });
  });

  group('TranscriptSegment equality', () {
    test('text segments equal when fields match', () {
      expect(
        TextSegment(text: 'a', startedAt: t0),
        TextSegment(text: 'a', startedAt: t0),
      );
    });

    test('text segments unequal when text differs', () {
      expect(
        TextSegment(text: 'a', startedAt: t0),
        isNot(TextSegment(text: 'b', startedAt: t0)),
      );
    });
  });

  group('copyWith', () {
    test('TextSegment copyWith preserves other fields', () {
      final base = TextSegment(text: 'a', startedAt: t0, durationMs: 10);
      final next = base.copyWith(text: 'b');
      expect(next.text, 'b');
      expect(next.durationMs, 10);
    });

    test('ReasoningSegment copyWith overrides text + durationMs', () {
      final base = ReasoningSegment(text: 'x', startedAt: t0);
      final next = base.copyWith(text: 'y', durationMs: 7);
      expect(next.text, 'y');
      expect(next.durationMs, 7);
      expect(next.startedAt, t0);
    });

    test('ToolSegment copyWith overrides outputs + status + prunedAt', () {
      final base = ToolSegment(
        toolName: 'bash',
        toolCallId: 'c',
        startedAt: t0,
      );
      final next = base.copyWith(
        outputs: 'out',
        status: ToolSegmentStatus.ok,
        prunedAt: t0,
        inputs: {'k': 'v'},
      );
      expect(next.outputs, 'out');
      expect(next.status, ToolSegmentStatus.ok);
      expect(next.isPruned, isTrue);
      expect(next.inputs?['k'], 'v');
    });
  });

  group('ErrorSegment', () {
    test('toJson round-trips with code + source + durationMs', () {
      final original = ErrorSegment(
        message: 'boom',
        code: 'E1',
        source: 'harness',
        startedAt: t0,
        durationMs: 9,
      );
      final out = original.toJson();
      expect(out['type'], 'error');
      expect(out['code'], 'E1');
      expect(out['source'], 'harness');
      expect(out['durationMs'], 9);
      final rt = TranscriptSegment.fromJson(out) as ErrorSegment;
      expect(rt, original);
    });

    test('equality + hashCode by message/code/source/startedAt', () {
      final a = ErrorSegment(
        message: 'm',
        code: 'c',
        source: 's',
        startedAt: t0,
      );
      final b = ErrorSegment(
        message: 'm',
        code: 'c',
        source: 's',
        startedAt: t0,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        ErrorSegment(message: 'm', code: 'c', source: 's', startedAt: t0),
        isNot(
          ErrorSegment(message: 'm2', code: 'c', source: 's', startedAt: t0),
        ),
      );
    });

    test('omits null code/source', () {
      final out = ErrorSegment(message: 'm', startedAt: t0).toJson();
      expect(out.containsKey('code'), isFalse);
      expect(out.containsKey('source'), isFalse);
    });
  });

  group('ViolationSegment', () {
    test('toJson round-trips all fields', () {
      final original = ViolationSegment(
        message: 'denied',
        action: 'fileDelete',
        target: '/secret',
        suggestedCapability: 'write',
        startedAt: t0,
        durationMs: 3,
      );
      final out = original.toJson();
      expect(out['type'], 'violation');
      expect(out['action'], 'fileDelete');
      expect(out['target'], '/secret');
      expect(out['suggestedCapability'], 'write');
      expect(out['durationMs'], 3);
      final rt = TranscriptSegment.fromJson(out) as ViolationSegment;
      expect(rt, original);
    });

    test('equality + hashCode by all fields', () {
      final a = ViolationSegment(
        message: 'm',
        action: 'a',
        target: 't',
        suggestedCapability: 'cap',
        startedAt: t0,
      );
      final b = ViolationSegment(
        message: 'm',
        action: 'a',
        target: 't',
        suggestedCapability: 'cap',
        startedAt: t0,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          ViolationSegment(
            message: 'm',
            action: 'a',
            target: 't',
            suggestedCapability: 'other',
            startedAt: t0,
          ),
        ),
      );
    });

    test('omits null action/target/suggestedCapability', () {
      final out = ViolationSegment(message: 'm', startedAt: t0).toJson();
      expect(out.containsKey('action'), isFalse);
      expect(out.containsKey('target'), isFalse);
      expect(out.containsKey('suggestedCapability'), isFalse);
    });
  });

  group('ToolSegment equality + hashCode', () {
    test('equal when all fields match', () {
      final a = ToolSegment(
        toolName: 'bash',
        toolCallId: 'c',
        inputs: {'k': 'v'},
        outputs: 'o',
        status: ToolSegmentStatus.ok,
        startedAt: t0,
        durationMs: 5,
        prunedAt: t0,
      );
      final b = ToolSegment(
        toolName: 'bash',
        toolCallId: 'c',
        inputs: {'k': 'v'},
        outputs: 'o',
        status: ToolSegmentStatus.ok,
        startedAt: t0,
        durationMs: 5,
        prunedAt: t0,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.isError, isFalse);
    });

    test('unequal when inputs differ', () {
      expect(
        ToolSegment(
          toolName: 't',
          toolCallId: 'c',
          inputs: {'a': 1},
          startedAt: t0,
        ),
        isNot(
          ToolSegment(
            toolName: 't',
            toolCallId: 'c',
            inputs: {'a': 2},
            startedAt: t0,
          ),
        ),
      );
    });

    test('isError true when status is error', () {
      expect(
        ToolSegment(
          toolName: 't',
          toolCallId: 'c',
          status: ToolSegmentStatus.error,
          startedAt: t0,
        ).isError,
        isTrue,
      );
    });

    test('interrupted status round-trips', () {
      final s = ToolSegment(
        toolName: 't',
        toolCallId: 'c',
        status: ToolSegmentStatus.interrupted,
        startedAt: t0,
      );
      final out = s.toJson();
      expect(out['status'], 'interrupted');
      final rt = TranscriptSegment.fromJson(out) as ToolSegment;
      expect(rt.status, ToolSegmentStatus.interrupted);
    });
  });

  group('ReasoningSegment equality', () {
    test('equal + hashCode when fields match', () {
      final a = ReasoningSegment(text: 'x', startedAt: t0, durationMs: 2);
      final b = ReasoningSegment(text: 'x', startedAt: t0, durationMs: 2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('unequal when durationMs differs', () {
      expect(
        ReasoningSegment(text: 'x', startedAt: t0, durationMs: 2),
        isNot(ReasoningSegment(text: 'x', startedAt: t0, durationMs: 3)),
      );
    });
  });

  group('decodeTranscript / encodeTranscript', () {
    test('non-list returns empty', () {
      expect(decodeTranscript('nope'), isEmpty);
      expect(decodeTranscript(null), isEmpty);
    });

    test('skips non-map entries, decodes maps', () {
      final decoded = decodeTranscript([
        {'type': 'text', 'text': 'a'},
        'garbage',
        {'type': 'tool', 'toolName': 't'},
      ]);
      expect(decoded.length, 2);
      expect(decoded[0], isA<TextSegment>());
      expect(decoded[1], isA<ToolSegment>());
    });

    test('encodeTranscript round-trips a list', () {
      final segs = <TranscriptSegment>[
        TextSegment(text: 'a', startedAt: t0),
        ReasoningSegment(text: 'r', startedAt: t0),
      ];
      final encoded = encodeTranscript(segs);
      expect(encoded.length, 2);
      expect(encoded[0]['type'], 'text');
    });
  });

  group('TurnOutcome (de)serialization', () {
    test('turnOutcomeFromString parses each value + null default', () {
      expect(turnOutcomeFromString('completed'), TurnOutcome.completed);
      expect(turnOutcomeFromString('failed'), TurnOutcome.failed);
      expect(turnOutcomeFromString('interrupted'), TurnOutcome.interrupted);
      expect(turnOutcomeFromString('max_turns'), TurnOutcome.maxTurns);
      expect(turnOutcomeFromString('nope'), isNull);
      expect(turnOutcomeFromString(null), isNull);
    });

    test('turnOutcomeToString covers each value', () {
      expect(turnOutcomeToString(TurnOutcome.completed), 'completed');
      expect(turnOutcomeToString(TurnOutcome.failed), 'failed');
      expect(turnOutcomeToString(TurnOutcome.interrupted), 'interrupted');
      expect(turnOutcomeToString(TurnOutcome.maxTurns), 'max_turns');
    });
  });

  group('ToolSegment images', () {
    test('round-trips image references through JSON', () {
      final seg = ToolSegment(
        toolName: 'browser_use',
        toolCallId: 'tc1',
        outputs: 'navigated',
        startedAt: t0,
        images: const [
          ToolImageRef(
            ref: 'blob:sha256:abc',
            mediaType: 'image/png',
            bytes: 2048,
            width: 1280,
            height: 800,
          ),
        ],
      );

      final decoded = TranscriptSegment.fromJson(seg.toJson()) as ToolSegment;
      expect(decoded.images, hasLength(1));
      expect(decoded.images.single.ref, 'blob:sha256:abc');
      expect(decoded.images.single.bytes, 2048);
      expect(decoded.images.single.width, 1280);
      expect(decoded.images.single.height, 800);
      expect(decoded, seg);
    });

    test('omits the key entirely when there are no images', () {
      final seg = ToolSegment(
        toolName: 'read',
        toolCallId: 'tc1',
        startedAt: t0,
      );
      expect(
        seg.toJson().containsKey('images'),
        isFalse,
        reason: 'every existing transcript must serialize exactly as before',
      );
    });

    test('a malformed entry is skipped, not fatal', () {
      final decoded =
          TranscriptSegment.fromJson({
                'type': 'tool',
                'ts': t0.millisecondsSinceEpoch,
                'toolName': 'browser_use',
                'images': [
                  {'mediaType': 'image/png'},
                  'not a map',
                  {'ref': 'blob:sha256:ok'},
                ],
              })
              as ToolSegment;
      expect(decoded.images.map((i) => i.ref), ['blob:sha256:ok']);
    });

    test('images participate in equality', () {
      final base = ToolSegment(
        toolName: 'browser_use',
        toolCallId: 'tc1',
        startedAt: t0,
      );
      final withImage = base.copyWith(
        images: const [ToolImageRef(ref: 'blob:sha256:abc')],
      );
      expect(withImage, isNot(base));
      expect(withImage.hashCode, isNot(base.hashCode));
      expect(
        withImage.copyWith(outputs: 'done').images,
        withImage.images,
        reason: 'copyWith must not silently drop them',
      );
    });
  });
}
