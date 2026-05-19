import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/space_turn_relay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ActiveStreamRegistry registry;
  final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  setUp(() {
    registry = ActiveStreamRegistry();
  });

  Future<void> settle([int ms = 5]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  test(
    'seed frame carries every active turn snapshot, even when empty',
    () async {
      final frames = <Map<String, dynamic>>[];
      final sub = watchSpaceTurnFrames(registry, 'c1').listen(frames.add);
      await settle();
      expect(frames, hasLength(1));
      expect(frames.first['kind'], 'seed');
      expect(frames.first['turns'], isEmpty);
      await sub.cancel();

      registry.register('m1', spaceId: 'c1');
      registry.apply(
        'm1',
        SegmentOpened(0, ReasoningSegment(text: 'hel', startedAt: ts)),
      );
      registry.apply('m1', const SegmentDelta(0, 'lo'));

      final frames2 = <Map<String, dynamic>>[];
      final sub2 = watchSpaceTurnFrames(registry, 'c1').listen(frames2.add);
      await settle();
      expect(frames2, hasLength(1));
      final seed = frames2.first;
      expect(seed['kind'], 'seed');
      final turns = seed['turns'] as List;
      expect(turns, hasLength(1));
      final turn = turns.first as Map<String, dynamic>;
      expect(turn['message_id'], 'm1');
      final segments = turn['segments'] as List;
      expect(segments, hasLength(1));
      // The seed materializes buffered deltas into the snapshot.
      expect((segments.first as Map)['text'], 'hello');
      await sub2.cancel();
    },
  );

  test(
    'consecutive same-segment deltas coalesce into one merged update',
    () async {
      registry.register('m1', spaceId: 'c1');
      registry.apply(
        'm1',
        SegmentOpened(0, TextSegment(text: '', startedAt: ts)),
      );

      final frames = <Map<String, dynamic>>[];
      final sub = watchSpaceTurnFrames(
        registry,
        'c1',
        coalesce: const Duration(milliseconds: 20),
      ).listen(frames.add);
      await settle();
      frames.clear(); // drop the seed

      registry.apply('m1', const SegmentDelta(0, 'a'));
      registry.apply('m1', const SegmentDelta(0, 'b'));
      registry.apply('m1', const SegmentDelta(0, 'c'));
      // Inside the coalescing window nothing has flushed yet.
      await settle(2);
      expect(frames, isEmpty);
      await settle(40);
      expect(frames, hasLength(1));
      final updates = frames.first['updates'] as List;
      expect(updates, hasLength(1));
      expect((updates.first as Map)['t'], 'delta');
      expect((updates.first as Map)['d'], 'abc');
      await sub.cancel();
    },
  );

  test(
    'structural updates flush immediately, carrying buffered deltas',
    () async {
      registry.register('m1', spaceId: 'c1');
      registry.apply(
        'm1',
        SegmentOpened(0, TextSegment(text: '', startedAt: ts)),
      );

      final frames = <Map<String, dynamic>>[];
      final sub = watchSpaceTurnFrames(
        registry,
        'c1',
        coalesce: const Duration(seconds: 10), // would never flush on its own
      ).listen(frames.add);
      await settle();
      frames.clear();

      registry.apply('m1', const SegmentDelta(0, 'hi'));
      registry.apply(
        'm1',
        SegmentClosed(0, TextSegment(text: 'hi', startedAt: ts, durationMs: 5)),
      );
      await settle();
      expect(frames, hasLength(1));
      final updates = frames.first['updates'] as List;
      expect(updates, hasLength(2));
      expect((updates[0] as Map)['t'], 'delta');
      expect((updates[1] as Map)['t'], 'close');
      await sub.cancel();
    },
  );

  test('TurnFinished is relayed with its outcome', () async {
    registry.register('m1', spaceId: 'c1');

    final frames = <Map<String, dynamic>>[];
    final sub = watchSpaceTurnFrames(registry, 'c1').listen(frames.add);
    await settle();
    frames.clear();

    registry.apply('m1', const TurnFinished(0, TurnOutcome.completed));
    await settle();
    expect(frames, hasLength(1));
    final updates = frames.first['updates'] as List;
    expect((updates.single as Map)['t'], 'finish');
    expect((updates.single as Map)['outcome'], 'completed');
    await sub.cancel();
  });

  test('updates for different messages land in separate frames', () async {
    registry.register('m1', spaceId: 'c1');
    registry.register('m2', spaceId: 'c1');
    registry.apply(
      'm1',
      SegmentOpened(0, TextSegment(text: '', startedAt: ts)),
    );
    registry.apply(
      'm2',
      SegmentOpened(0, TextSegment(text: '', startedAt: ts)),
    );

    final frames = <Map<String, dynamic>>[];
    final sub = watchSpaceTurnFrames(
      registry,
      'c1',
      coalesce: const Duration(milliseconds: 10),
    ).listen(frames.add);
    await settle();
    frames.clear();

    registry.apply('m1', const SegmentDelta(0, 'a'));
    registry.apply('m2', const SegmentDelta(0, 'b'));
    await settle(40);
    expect(frames, hasLength(2));
    expect(frames.map((f) => f['message_id']), unorderedEquals(['m1', 'm2']));
    await sub.cancel();
  });
}
