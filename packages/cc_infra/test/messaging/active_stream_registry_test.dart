import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:test/test.dart';

/// Exercises the in-flight turn registry's segment snapshotting: the lazy
/// delta accumulation buffers (O(delta) per delta instead of O(accumulated)),
/// the memoized unmodifiable snapshot views, per-segment materialization, the
/// channel relay index, and the registration broadcast stream.

void main() {
  late ActiveStreamRegistry registry;

  setUp(() => registry = ActiveStreamRegistry());

  group('ActiveStreamRegistry register / isActive / updatesFor', () {
    test('register opens a broadcast stream and marks the turn active', () {
      registry.register('m1');
      expect(registry.isActive('m1'), isTrue);
      expect(registry.updatesFor('m1'), isNotNull);
      expect(registry.isActive('absent'), isFalse);
      expect(registry.updatesFor('absent'), isNull);
    });

    test('isActive is false once unregistered', () async {
      registry.register('m1');
      await registry.unregister('m1');
      expect(registry.isActive('m1'), isFalse);
      expect(registry.snapshot('m1'), isNull);
    });
  });

  group('ActiveStreamRegistry snapshot + delta materialization', () {
    test('snapshot returns null for an unknown message', () {
      expect(registry.snapshot('nope'), isNull);
      expect(registry.segmentAt('nope', 0), isNull);
    });

    test('SegmentOpened appends; snapshot returns the segment', () {
      registry.register('m1');
      final seg = TextSegment(text: 'a', startedAt: DateTime(2026, 1, 1));
      registry.apply('m1', SegmentOpened(0, seg));
      expect(registry.snapshot('m1')?.single, seg);
      // The same unmodifiable view is returned until the next apply.
      final view1 = registry.snapshot('m1');
      final view2 = registry.snapshot('m1');
      expect(identical(view1, view2), isTrue);
    });

    test('SegmentDelta accumulates in a buffer and materializes lazily', () {
      registry.register('m1');
      final seg = TextSegment(text: 'h', startedAt: DateTime(2026, 1, 1));
      registry.apply('m1', SegmentOpened(0, seg));
      registry.apply('m1', const SegmentDelta(0, 'ello'));
      registry.apply('m1', const SegmentDelta(0, ' world'));
      // The buffer materializes on snapshot.
      expect(
        (registry.snapshot('m1')!.single as TextSegment).text,
        'hello world',
      );
      // segmentAt also materializes the dirty index.
      expect((registry.segmentAt('m1', 0) as TextSegment).text, 'hello world');
    });

    test('SegmentClosed replaces the segment and clears its buffer', () {
      registry.register('m1');
      final open = TextSegment(text: 'a', startedAt: DateTime(2026, 1, 1));
      registry.apply('m1', SegmentOpened(0, open));
      registry.apply('m1', const SegmentDelta(0, 'bc'));
      final closed = TextSegment(
        text: 'abc',
        startedAt: DateTime(2026, 1, 1),
        durationMs: 5,
      );
      registry.apply('m1', SegmentClosed(0, closed));
      expect(registry.snapshot('m1')!.single, closed);
    });

    test('SegmentOpened at an existing index overwrites it', () {
      registry.register('m1');
      final first = TextSegment(text: 'a', startedAt: DateTime(2026, 1, 1));
      final second = TextSegment(text: 'b', startedAt: DateTime(2026, 1, 2));
      registry.apply('m1', SegmentOpened(0, first));
      registry.apply('m1', SegmentOpened(0, second)); // replace
      expect(registry.snapshot('m1')!.length, 1);
      expect(registry.snapshot('m1')!.single, second);
    });

    test('SegmentOpened with an out-of-range index is dropped', () {
      registry.register('m1');
      final seg = TextSegment(text: 'a', startedAt: DateTime(2026, 1, 1));
      registry.apply('m1', SegmentOpened(5, seg));
      expect(registry.snapshot('m1'), isEmpty);
    });

    test('SegmentDelta on a seeded (mid-flight) segment adopts its text', () {
      // seed registers + pre-populates; a delta without an opened buffer
      // should adopt the seeded segment's existing text.
      final seg = ToolSegment(
        toolName: 't',
        toolCallId: '1',
        outputs: 'partial-',
        startedAt: DateTime(2026, 1, 1),
      );
      registry.seed('m1', [seg]);
      registry.apply('m1', const SegmentDelta(0, 'more'));
      expect(
        (registry.snapshot('m1')!.single as ToolSegment).outputs,
        'partial-more',
      );
    });

    test('TurnFinished does not mutate the snapshot', () {
      registry.register('m1');
      final seg = TextSegment(text: 'a', startedAt: DateTime(2026, 1, 1));
      registry.apply('m1', SegmentOpened(0, seg));
      registry.apply('m1', const TurnFinished(0, TurnOutcome.completed));
      expect(registry.snapshot('m1')!.single, seg);
    });
  });

  group('ActiveStreamRegistry segmentAt bounds', () {
    test('returns null for out-of-range indices', () {
      registry.register('m1');
      expect(registry.segmentAt('m1', -1), isNull);
      expect(registry.segmentAt('m1', 0), isNull); // empty snapshot
      registry.apply(
        'm1',
        SegmentOpened(
          0,
          TextSegment(text: 'a', startedAt: DateTime(2026, 1, 1)),
        ),
      );
      expect(registry.segmentAt('m1', 5), isNull);
    });
  });

  group('ActiveStreamRegistry channel relay', () {
    test('activeIn returns the message ids in a channel', () {
      registry.register('m1', channelId: 'c1');
      registry.register('m2', channelId: 'c1');
      registry.register('m3', channelId: 'c2');
      expect(registry.activeIn('c1').toSet(), {'m1', 'm2'});
      expect(registry.activeIn('c2').toSet(), {'m3'});
      expect(registry.activeIn('nope'), isEmpty);
    });

    test(
      'channelUpdates relays updates tagged with their message id',
      () async {
        registry.register('m1', channelId: 'c1');
        final events = <ChannelTurnUpdate>[];
        final sub = registry.channelUpdates('c1').listen(events.add);
        final seg = TextSegment(text: 'a', startedAt: DateTime(2026, 1, 1));
        registry.apply('m1', SegmentOpened(0, seg));
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();
        expect(events, isNotEmpty);
        expect(events.first.messageId, 'm1');
        expect(events.first.update, isA<SegmentOpened>());
      },
    );
  });

  group('ActiveStreamRegistry registrations stream', () {
    test('emits message ids as they register (incl. seeds)', () async {
      final ids = <String>[];
      final sub = registry.registrations.listen(ids.add);
      registry.register('m1');
      registry.seed('m2', const []);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(ids, ['m1', 'm2']);
    });
  });

  group('ActiveStreamRegistry updatesFor broadcasts', () {
    test('multiple listeners each receive the updates', () async {
      registry.register('m1');
      final a = registry.updatesFor('m1')!.toList();
      final b = registry.updatesFor('m1')!.toList();
      final seg = TextSegment(text: 'a', startedAt: DateTime(2026, 1, 1));
      registry.apply('m1', SegmentOpened(0, seg));
      await registry.unregister('m1');
      expect((await a).last, isA<SegmentOpened>());
      expect((await b).last, isA<SegmentOpened>());
    });
  });
}
