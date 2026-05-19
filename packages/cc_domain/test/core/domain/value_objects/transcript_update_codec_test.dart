import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:test/test.dart';

void main() {
  final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  group('transcriptUpdateToWire / transcriptUpdateFromWire round-trip', () {
    test('SegmentOpened round-trips (tool segment)', () {
      final update = SegmentOpened(
        2,
        ToolSegment(
          toolName: 'Read',
          toolCallId: 'call-1',
          inputs: const {'file_path': '/tmp/a.dart'},
          startedAt: ts,
        ),
      );
      final wire = transcriptUpdateToWire(update);
      expect(wire['t'], 'open');
      expect(wire['i'], 2);
      expect(transcriptUpdateFromWire(wire), update);
    });

    test('SegmentOpened round-trips (reasoning segment)', () {
      final update = SegmentOpened(
        0,
        ReasoningSegment(text: 'hm', startedAt: ts),
      );
      expect(transcriptUpdateFromWire(transcriptUpdateToWire(update)), update);
    });

    test('SegmentDelta round-trips', () {
      const update = SegmentDelta(1, 'hello');
      final wire = transcriptUpdateToWire(update);
      expect(wire, {'t': 'delta', 'i': 1, 'd': 'hello'});
      expect(transcriptUpdateFromWire(wire), update);
    });

    test('SegmentClosed round-trips', () {
      final update = SegmentClosed(
        3,
        ToolSegment(
          toolName: 'Bash',
          toolCallId: 'call-2',
          outputs: 'done',
          status: ToolSegmentStatus.ok,
          startedAt: ts,
          durationMs: 42,
        ),
      );
      final wire = transcriptUpdateToWire(update);
      expect(wire['t'], 'close');
      expect(transcriptUpdateFromWire(wire), update);
    });

    test('TurnFinished round-trips for every outcome', () {
      for (final outcome in TurnOutcome.values) {
        final update = TurnFinished(4, outcome);
        final wire = transcriptUpdateToWire(update);
        expect(wire['t'], 'finish');
        expect(wire['outcome'], turnOutcomeToString(outcome));
        expect(transcriptUpdateFromWire(wire), update);
      }
    });
  });

  group('transcriptUpdateFromWire malformed-frame tolerance', () {
    test('missing index yields null', () {
      expect(transcriptUpdateFromWire(const {'t': 'delta', 'd': 'x'}), isNull);
    });

    test('unknown kind yields null', () {
      expect(transcriptUpdateFromWire(const {'t': 'wat', 'i': 0}), isNull);
    });

    test('missing kind yields null', () {
      expect(transcriptUpdateFromWire(const {'i': 0}), isNull);
    });

    test('delta with non-string payload yields null', () {
      expect(
        transcriptUpdateFromWire(const {'t': 'delta', 'i': 0, 'd': 3}),
        isNull,
      );
    });

    test('open/close with non-map segment yields null', () {
      expect(
        transcriptUpdateFromWire(const {'t': 'open', 'i': 0, 'seg': 'x'}),
        isNull,
      );
      expect(transcriptUpdateFromWire(const {'t': 'close', 'i': 0}), isNull);
    });

    test('finish with unknown outcome yields null', () {
      expect(
        transcriptUpdateFromWire(const {
          't': 'finish',
          'i': 0,
          'outcome': 'nope',
        }),
        isNull,
      );
      expect(transcriptUpdateFromWire(const {'t': 'finish', 'i': 0}), isNull);
    });
  });

  group('spaceTurnEventFromWire', () {
    test('decodes a seed frame with turns and their snapshots', () {
      final frame = {
        'kind': 'seed',
        'turns': [
          {
            'message_id': 'm1',
            'segments': encodeTranscript([
              ReasoningSegment(text: 'thinking', startedAt: ts),
              TextSegment(text: 'answer', startedAt: ts),
            ]),
          },
          // Malformed entry (no message_id) is skipped, not thrown.
          {'segments': const <Object>[]},
        ],
      };
      final event = spaceTurnEventFromWire(frame);
      expect(event, isA<TurnRelaySeed>());
      final seed = event! as TurnRelaySeed;
      expect(seed.turns, hasLength(1));
      expect(seed.turns.single.messageId, 'm1');
      expect(seed.turns.single.segments, hasLength(2));
      expect(
        (seed.turns.single.segments.first as ReasoningSegment).text,
        'thinking',
      );
    });

    test('seed frame with a non-list turns payload degrades to empty', () {
      final event = spaceTurnEventFromWire(const {'kind': 'seed'});
      expect(event, isA<TurnRelaySeed>());
      expect((event! as TurnRelaySeed).turns, isEmpty);
    });

    test('decodes an updates frame, skipping malformed updates', () {
      final frame = {
        'kind': 'updates',
        'message_id': 'm1',
        'updates': [
          const {'t': 'delta', 'i': 0, 'd': 'ab'},
          const {'t': 'nope', 'i': 0}, // unknown → skipped
          const {'t': 'finish', 'i': 0, 'outcome': 'completed'},
        ],
      };
      final event = spaceTurnEventFromWire(frame);
      expect(event, isA<TurnRelayUpdates>());
      final updates = event! as TurnRelayUpdates;
      expect(updates.messageId, 'm1');
      expect(updates.updates, [
        const SegmentDelta(0, 'ab'),
        const TurnFinished(0, TurnOutcome.completed),
      ]);
    });

    test('updates frame without a message id yields null', () {
      expect(
        spaceTurnEventFromWire(const {'kind': 'updates', 'updates': []}),
        isNull,
      );
    });

    test('unknown frame kinds yield null', () {
      expect(spaceTurnEventFromWire(const {'kind': 'wat'}), isNull);
      expect(spaceTurnEventFromWire(const {}), isNull);
    });
  });

  group('runTranscriptEventFromWire', () {
    test('seed frame carries the segments and the live flag', () {
      final event = runTranscriptEventFromWire({
        'kind': 'seed',
        'live': true,
        'segments': encodeTranscript([
          TextSegment(text: 'planning', startedAt: ts),
          ToolSegment(toolName: 'Read', toolCallId: 'c1', startedAt: ts),
        ]),
      });

      expect(event, isA<RunTranscriptSeed>());
      final seed = event! as RunTranscriptSeed;
      expect(seed.live, isTrue);
      expect(seed.segments, hasLength(2));
      expect((seed.segments.first as TextSegment).text, 'planning');
    });

    test('a replay seed reports live: false so streaming affordances stop', () {
      final seed =
          runTranscriptEventFromWire(const {
                'kind': 'seed',
                'segments': <Object?>[],
                'live': false,
              })!
              as RunTranscriptSeed;

      expect(seed.live, isFalse);
      expect(seed.segments, isEmpty);
    });

    test('live defaults to true when the server omits it', () {
      final seed =
          runTranscriptEventFromWire(const {
                'kind': 'seed',
                'segments': <Object?>[],
              })!
              as RunTranscriptSeed;

      expect(seed.live, isTrue);
    });

    test('an updates frame decodes in order and skips unknown kinds', () {
      final event = runTranscriptEventFromWire({
        'kind': 'updates',
        'updates': [
          const {'t': 'delta', 'i': 0, 'd': 'ab'},
          const {'t': 'nope', 'i': 0},
          const {'t': 'finish', 'i': 0, 'outcome': 'completed'},
        ],
      });

      expect(event, isA<RunTranscriptUpdates>());
      expect((event! as RunTranscriptUpdates).updates, [
        const SegmentDelta(0, 'ab'),
        const TurnFinished(0, TurnOutcome.completed),
      ]);
    });

    test('a malformed seed degrades to an empty transcript', () {
      final seed =
          runTranscriptEventFromWire(const {
                'kind': 'seed',
                'segments': 'nope',
              })!
              as RunTranscriptSeed;

      expect(seed.segments, isEmpty);
    });

    test('unknown and malformed frames yield null', () {
      expect(runTranscriptEventFromWire(const {'kind': 'wat'}), isNull);
      expect(runTranscriptEventFromWire(const {}), isNull);
      expect(
        runTranscriptEventFromWire(const {
          'kind': 'updates',
          'updates': 'nope',
        }),
        isNull,
      );
    });
  });
}
