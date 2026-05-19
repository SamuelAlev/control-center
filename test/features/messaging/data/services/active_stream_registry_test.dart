import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ActiveStreamRegistry registry;
  final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  setUp(() {
    registry = ActiveStreamRegistry();
  });

  group('register / isActive', () {
    test('register opens a stream and snapshot', () {
      registry.register('m1');
      expect(registry.isActive('m1'), isTrue);
      expect(registry.updatesFor('m1'), isNotNull);
      expect(registry.snapshot('m1'), isEmpty);
    });

    test('isActive false for unknown and after unregister', () async {
      expect(registry.isActive('nope'), isFalse);
      registry.register('m1');
      await registry.unregister('m1');
      expect(registry.isActive('m1'), isFalse);
      expect(registry.snapshot('m1'), isNull);
      expect(registry.updatesFor('m1'), isNull);
    });
  });

  group('apply', () {
    test('broadcasts updates to listeners', () async {
      registry.register('m1');
      final received = <TranscriptUpdate>[];
      registry.updatesFor('m1')!.listen(received.add);

      final seg = ReasoningSegment(text: 'a', startedAt: ts);
      registry.apply('m1', SegmentOpened(0, seg));
      registry.apply('m1', const SegmentDelta(0, 'b'));

      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(2));
      expect(received[0], isA<SegmentOpened>());
      expect(received[1], isA<SegmentDelta>());
    });

    test('SegmentOpened appends to snapshot', () {
      registry.register('m1');
      registry.apply(
        'm1',
        SegmentOpened(
          0,
          ToolSegment(toolName: 'Read', toolCallId: 'c', startedAt: ts),
        ),
      );
      expect(registry.snapshot('m1'), hasLength(1));
      expect(registry.snapshot('m1')!.first, isA<ToolSegment>());
    });

    test('SegmentDelta appends text into the open reasoning segment', () {
      registry.register('m1');
      registry.apply(
        'm1',
        SegmentOpened(0, ReasoningSegment(text: 'hel', startedAt: ts)),
      );
      registry.apply('m1', const SegmentDelta(0, 'lo'));
      final seg = registry.snapshot('m1')!.first as ReasoningSegment;
      expect(seg.text, 'hello');
    });

    test('SegmentDelta appends into open tool outputs', () {
      registry.register('m1');
      registry.apply(
        'm1',
        SegmentOpened(
          0,
          ToolSegment(toolName: 'Bash', toolCallId: 'c', startedAt: ts),
        ),
      );
      registry.apply('m1', const SegmentDelta(0, 'line1'));
      registry.apply('m1', const SegmentDelta(0, 'line2'));
      final seg = registry.snapshot('m1')!.first as ToolSegment;
      expect(seg.outputs, 'line1line2');
    });

    test('SegmentClosed replaces the segment at index', () {
      registry.register('m1');
      registry.apply(
        'm1',
        SegmentOpened(
          0,
          ToolSegment(toolName: 'Read', toolCallId: 'c', startedAt: ts),
        ),
      );
      final closed = ToolSegment(
        toolName: 'Read',
        toolCallId: 'c',
        outputs: 'done',
        status: ToolSegmentStatus.ok,
        startedAt: ts,
        durationMs: 10,
      );
      registry.apply('m1', SegmentClosed(0, closed));
      expect(registry.snapshot('m1')!.single, closed);
    });

    test('snapshot returned is unmodifiable and is a copy', () {
      registry.register('m1');
      registry.apply(
        'm1',
        SegmentOpened(0, ReasoningSegment(text: 'a', startedAt: ts)),
      );
      final snap = registry.snapshot('m1')!;
      expect(
        () => snap.add(ReasoningSegment(text: 'x', startedAt: ts)),
        throwsUnsupportedError,
      );
    });

    test('does nothing for unregistered messageId', () {
      registry.apply(
        'nope',
        SegmentOpened(0, ReasoningSegment(text: 'a', startedAt: ts)),
      );
      expect(registry.snapshot('nope'), isNull);
    });
  });

  group('unregister', () {
    test('closes the stream and allows re-registration', () async {
      registry.register('m1');
      await registry.unregister('m1');
      expect(registry.isActive('m1'), isFalse);

      registry.register('m1');
      final received = <TranscriptUpdate>[];
      registry.updatesFor('m1')!.listen(received.add);
      registry.apply(
        'm1',
        SegmentOpened(0, TextSegment(text: 'fresh', startedAt: ts)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));
    });
  });

  group('independence', () {
    test('streams and snapshots are independent per messageId', () {
      registry.register('m1');
      registry.register('m2');
      registry.apply(
        'm1',
        SegmentOpened(0, TextSegment(text: 'a', startedAt: ts)),
      );
      expect(registry.snapshot('m1'), hasLength(1));
      expect(registry.snapshot('m2'), isEmpty);
    });
  });

  group('channel index', () {
    test('register with a channelId indexes the turn in activeIn', () {
      registry.register('m1', channelId: 'c1');
      registry.register('m2', channelId: 'c1');
      registry.register('m3', channelId: 'c2');
      expect(registry.activeIn('c1'), unorderedEquals(['m1', 'm2']));
      expect(registry.activeIn('c2'), ['m3']);
      expect(registry.activeIn('unknown'), isEmpty);
    });

    test('unregister removes the turn from the channel index', () async {
      registry.register('m1', channelId: 'c1');
      registry.register('m2', channelId: 'c1');
      await registry.unregister('m1');
      expect(registry.activeIn('c1'), ['m2']);
      await registry.unregister('m2');
      expect(registry.activeIn('c1'), isEmpty);
    });

    test('register without a channelId stays out of the channel index', () {
      registry.register('m1');
      expect(registry.activeIn('c1'), isEmpty);
    });
  });

  group('channelUpdates', () {
    test(
      'relays every active turn in the channel with its messageId',
      () async {
        final received = <ChannelTurnUpdate>[];
        final sub = registry.channelUpdates('c1').listen(received.add);
        addTearDown(sub.cancel);

        registry.register('m1', channelId: 'c1');
        registry.register('m2', channelId: 'c1');
        registry.register('other', channelId: 'c2');

        registry.apply(
          'm1',
          SegmentOpened(0, TextSegment(text: 'a', startedAt: ts)),
        );
        registry.apply('m2', const SegmentDelta(0, 'x'));
        registry.apply('other', const SegmentDelta(0, 'y'));

        await Future<void>.delayed(Duration.zero);
        expect(received, hasLength(2));
        expect(received[0].messageId, 'm1');
        expect(received[0].update, isA<SegmentOpened>());
        expect(received[1].messageId, 'm2');
        expect(received[1].update, const SegmentDelta(0, 'x'));
      },
    );
  });

  group('seed', () {
    test('adopts a snapshot as an active turn', () {
      final segments = [
        ReasoningSegment(text: 'so far', startedAt: ts),
        TextSegment(text: 'partial', startedAt: ts),
      ];
      registry.seed('m1', segments, channelId: 'c1');

      expect(registry.isActive('m1'), isTrue);
      expect(registry.snapshot('m1'), segments);
      expect(registry.activeIn('c1'), ['m1']);
    });

    test('seeded turn keeps accumulating deltas from the adopted prefix', () {
      registry.seed('m1', [ReasoningSegment(text: 'pre', startedAt: ts)]);
      registry.apply('m1', const SegmentDelta(0, 'fix'));
      final seg = registry.snapshot('m1')!.single as ReasoningSegment;
      expect(seg.text, 'prefix');
    });
  });

  group('registrations', () {
    test('emits the message id on register and on seed', () async {
      final ids = <String>[];
      final sub = registry.registrations.listen(ids.add);
      addTearDown(sub.cancel);

      registry.register('m1');
      registry.seed('m2', const []);

      await Future<void>.delayed(Duration.zero);
      expect(ids, ['m1', 'm2']);
    });
  });

  group('segmentAt', () {
    test('materializes only the asked index', () {
      registry.register('m1');
      registry.apply(
        'm1',
        SegmentOpened(0, ReasoningSegment(text: 'a', startedAt: ts)),
      );
      registry.apply(
        'm1',
        SegmentOpened(1, TextSegment(text: 'x', startedAt: ts)),
      );
      registry.apply('m1', const SegmentDelta(0, 'b'));
      registry.apply('m1', const SegmentDelta(1, 'y'));

      final tail = registry.segmentAt('m1', 1)! as TextSegment;
      expect(tail.text, 'xy');
      final head = registry.segmentAt('m1', 0)! as ReasoningSegment;
      expect(head.text, 'ab');
    });

    test('returns null for unknown message or out-of-range index', () {
      expect(registry.segmentAt('nope', 0), isNull);
      registry.register('m1');
      registry.apply(
        'm1',
        SegmentOpened(0, TextSegment(text: 'a', startedAt: ts)),
      );
      expect(registry.segmentAt('m1', -1), isNull);
      expect(registry.segmentAt('m1', 1), isNull);
    });
  });

  group('delta accumulation', () {
    test('many deltas materialize to the exact concatenation', () {
      registry.register('m1');
      registry.apply(
        'm1',
        SegmentOpened(0, TextSegment(text: '', startedAt: ts)),
      );
      final parts = List.generate(50, (i) => 'tok$i ');
      for (final part in parts) {
        registry.apply('m1', SegmentDelta(0, part));
      }
      final seg = registry.snapshot('m1')!.single as TextSegment;
      expect(seg.text, parts.join());
    });
  });

  group('snapshot view identity', () {
    test('is stable between applies and changes after an apply', () {
      registry.register('m1');
      registry.apply(
        'm1',
        SegmentOpened(0, TextSegment(text: 'a', startedAt: ts)),
      );

      final first = registry.snapshot('m1');
      final second = registry.snapshot('m1');
      expect(identical(first, second), isTrue);

      registry.apply('m1', const SegmentDelta(0, 'b'));
      final third = registry.snapshot('m1');
      expect(identical(second, third), isFalse);
      expect((third!.single as TextSegment).text, 'ab');
    });
  });
}
