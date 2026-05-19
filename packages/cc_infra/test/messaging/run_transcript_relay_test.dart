import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/run_transcript_relay.dart';
import 'package:test/test.dart';

TextSegment _text(String t) =>
    TextSegment(text: t, startedAt: DateTime.utc(2026, 7, 26));

ToolSegment _tool(String name) => ToolSegment(
  toolName: name,
  toolCallId: 'call-$name',
  startedAt: DateTime.utc(2026, 7, 26),
);

/// Long enough for the relay's 30ms coalescing window to fire.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 60));

void main() {
  late ActiveStreamRegistry registry;

  setUp(() => registry = ActiveStreamRegistry());

  group('live run', () {
    test('seeds from the registry snapshot with live: true', () async {
      registry.register('run-1');
      registry.apply('run-1', SegmentOpened(0, _text('planning')));

      final frames = <Map<String, dynamic>>[];
      final sub = watchRunTranscriptFrames(
        registry,
        'run-1',
      ).listen(frames.add);
      await _settle();
      await sub.cancel();

      expect(frames.first['kind'], 'seed');
      expect(frames.first['live'], isTrue);
      expect(frames.first['segments'], hasLength(1));
    });

    test(
      'relays updates after the seed, structural ones immediately',
      () async {
        registry.register('run-1');

        final frames = <Map<String, dynamic>>[];
        final sub = watchRunTranscriptFrames(
          registry,
          'run-1',
        ).listen(frames.add);
        registry.apply('run-1', SegmentOpened(0, _tool('Read')));
        await _settle();
        await sub.cancel();

        expect(frames.first['kind'], 'seed');
        final updates = frames
            .where((f) => f['kind'] == 'updates')
            .expand((f) => f['updates'] as List)
            .toList();
        expect(updates, hasLength(1));
        expect((updates.first as Map)['t'], 'open');
      },
    );

    test('no update is lost between the seed and the relayed stream', () async {
      registry.register('run-1');

      final frames = <Map<String, dynamic>>[];
      final sub = watchRunTranscriptFrames(
        registry,
        'run-1',
      ).listen(frames.add);
      // Applied in the same turn the subscription was opened.
      registry.apply('run-1', SegmentOpened(0, _text('a')));
      registry.apply('run-1', const SegmentDelta(0, 'b'));
      await _settle();
      await sub.cancel();

      final seeded = (frames.first['segments']! as List).length;
      final relayed = frames
          .where((f) => f['kind'] == 'updates')
          .expand((f) => f['updates'] as List)
          .length;
      // Either seeded or relayed, never dropped: one open + one delta.
      expect(seeded + relayed, 2);
    });

    test('merges consecutive deltas for the same segment', () async {
      registry.register('run-1');
      registry.apply('run-1', SegmentOpened(0, _text('')));

      final frames = <Map<String, dynamic>>[];
      final sub = watchRunTranscriptFrames(
        registry,
        'run-1',
      ).listen(frames.add);
      registry.apply('run-1', const SegmentDelta(0, 'a'));
      registry.apply('run-1', const SegmentDelta(0, 'b'));
      registry.apply('run-1', const SegmentDelta(0, 'c'));
      await _settle();
      await sub.cancel();

      final deltas = frames
          .where((f) => f['kind'] == 'updates')
          .expand((f) => f['updates'] as List)
          .where((u) => (u as Map)['t'] == 'delta')
          .toList();
      expect(deltas, hasLength(1));
      expect((deltas.first as Map)['d'], 'abc');
    });

    test('completes when the run unregisters', () async {
      registry.register('run-1');

      var done = false;
      final sub = watchRunTranscriptFrames(
        registry,
        'run-1',
      ).listen((_) {}, onDone: () => done = true);
      addTearDown(sub.cancel);
      registry.apply('run-1', const TurnFinished(0, TurnOutcome.completed));
      await registry.unregister('run-1');
      await _settle();

      expect(done, isTrue);
    });
  });

  group('replay', () {
    test('a finished run seeds from persisted with live: false', () async {
      final frames = <Map<String, dynamic>>[];
      final sub = watchRunTranscriptFrames(
        registry,
        'run-1',
        persisted: [_text('done'), _tool('Read')],
      ).listen(frames.add);
      await _settle();
      await sub.cancel();

      expect(frames, hasLength(1));
      expect(frames.first['kind'], 'seed');
      expect(frames.first['live'], isFalse);
      expect(frames.first['segments'], hasLength(2));
    });

    test(
      'an unrecorded run still seeds, so the subscription is marked established',
      () async {
        final frames = <Map<String, dynamic>>[];
        final sub = watchRunTranscriptFrames(
          registry,
          'run-1',
        ).listen(frames.add);
        await _settle();
        await sub.cancel();

        expect(frames, hasLength(1));
        expect(frames.first['kind'], 'seed');
        expect(frames.first['segments'], isEmpty);
        expect(frames.first['live'], isFalse);
      },
    );
  });

  group('late registration', () {
    test('a subscription opened before the run registers adopts it', () async {
      final frames = <Map<String, dynamic>>[];
      final sub = watchRunTranscriptFrames(
        registry,
        'run-1',
      ).listen(frames.add);
      await _settle();
      expect(frames.single['live'], isFalse);

      // The run goes live a beat after the tab was opened.
      registry.register('run-1');
      registry.apply('run-1', SegmentOpened(0, _tool('Read')));
      await _settle();
      await sub.cancel();

      final seeds = frames.where((f) => f['kind'] == 'seed').toList();
      expect(seeds, hasLength(2), reason: 're-seeds when the run goes live');
      expect(seeds.last['live'], isTrue);
      final updates = frames
          .where((f) => f['kind'] == 'updates')
          .expand((f) => f['updates'] as List)
          .length;
      expect(
        (seeds.last['segments']! as List).length + updates,
        1,
        reason: 'the tool call is delivered exactly once',
      );
    });

    test(
      'another run registering does not disturb this subscription',
      () async {
        final frames = <Map<String, dynamic>>[];
        final sub = watchRunTranscriptFrames(
          registry,
          'run-1',
        ).listen(frames.add);
        await _settle();
        registry.register('run-2');
        registry.apply('run-2', SegmentOpened(0, _tool('Read')));
        await _settle();
        await sub.cancel();

        expect(frames, hasLength(1));
      },
    );
  });
}
