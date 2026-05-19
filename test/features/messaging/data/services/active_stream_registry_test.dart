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
      registry.apply('m1', SegmentOpened(0, ToolSegment(toolName: 'Read', toolCallId: 'c', startedAt: ts)));
      expect(registry.snapshot('m1'), hasLength(1));
      expect(registry.snapshot('m1')!.first, isA<ToolSegment>());
    });

    test('SegmentDelta appends text into the open reasoning segment', () {
      registry.register('m1');
      registry.apply('m1', SegmentOpened(0, ReasoningSegment(text: 'hel', startedAt: ts)));
      registry.apply('m1', const SegmentDelta(0, 'lo'));
      final seg = registry.snapshot('m1')!.first as ReasoningSegment;
      expect(seg.text, 'hello');
    });

    test('SegmentDelta appends into open tool outputs', () {
      registry.register('m1');
      registry.apply('m1', SegmentOpened(0, ToolSegment(toolName: 'Bash', toolCallId: 'c', startedAt: ts)));
      registry.apply('m1', const SegmentDelta(0, 'line1'));
      registry.apply('m1', const SegmentDelta(0, 'line2'));
      final seg = registry.snapshot('m1')!.first as ToolSegment;
      expect(seg.outputs, 'line1line2');
    });

    test('SegmentClosed replaces the segment at index', () {
      registry.register('m1');
      registry.apply('m1', SegmentOpened(0, ToolSegment(toolName: 'Read', toolCallId: 'c', startedAt: ts)));
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
      registry.apply('m1', SegmentOpened(0, ReasoningSegment(text: 'a', startedAt: ts)));
      final snap = registry.snapshot('m1')!;
      expect(() => snap.add(ReasoningSegment(text: 'x', startedAt: ts)), throwsUnsupportedError);
    });

    test('does nothing for unregistered messageId', () {
      registry.apply('nope', SegmentOpened(0, ReasoningSegment(text: 'a', startedAt: ts)));
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
      registry.apply('m1', SegmentOpened(0, TextSegment(text: 'fresh', startedAt: ts)));
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));
    });
  });

  group('independence', () {
    test('streams and snapshots are independent per messageId', () {
      registry.register('m1');
      registry.register('m2');
      registry.apply('m1', SegmentOpened(0, TextSegment(text: 'a', startedAt: ts)));
      expect(registry.snapshot('m1'), hasLength(1));
      expect(registry.snapshot('m2'), isEmpty);
    });
  });
}
