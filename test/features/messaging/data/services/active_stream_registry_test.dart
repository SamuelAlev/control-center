import 'package:control_center/core/domain/value_objects/thinking_event.dart';
import 'package:control_center/features/messaging/data/services/active_stream_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ActiveStreamRegistry registry;

  setUp(() {
    registry = ActiveStreamRegistry();
  });

  group('ActiveStreamRegistry', () {
    group('register', () {
      test('returns a broadcast StreamController', () async {
        final controller = registry.register('msg-1');
        addTearDown(controller.close);
        expect(controller.isClosed, isFalse);
        expect(registry.streamFor('msg-1'), isNotNull);
      });

      test('makes isActive return true', () async {
        registry.register('msg-1');
        expect(registry.isActive('msg-1'), isTrue);
      });
    });

    group('streamFor', () {
      test('returns null for unknown messageId', () async {
        expect(registry.streamFor('unknown'), isNull);
      });

      test('returns the stream after register', () async {
        registry.register('msg-1');
        expect(registry.streamFor('msg-1'), isNotNull);
      });
    });

    group('eventStreamFor', () {
      test('returns null for unknown messageId', () async {
        expect(registry.eventStreamFor('unknown'), isNull);
      });

      test('returns the event stream after register', () async {
        registry.register('msg-1');
        expect(registry.eventStreamFor('msg-1'), isNotNull);
      });
    });

    group('add', () {
      test('delivers text deltas to the stream', () async {
        registry.register('msg-1');
        final received = <String>[];
        registry.streamFor('msg-1')!.listen(received.add);

        registry.add('msg-1', 'hello ');
        registry.add('msg-1', 'world');

        // Allow microtasks to flush
        await Future<void>.delayed(Duration.zero);

        expect(received, ['hello ', 'world']);
      });

      test('does nothing for unregistered messageId', () async {
        // Should not throw
        registry.add('unknown', 'data');
      });
    });

    group('addEvent', () {
      test('delivers thinking events to the event stream', () async {
        registry.register('msg-1');
        final received = <ThinkingEvent>[];
        registry.eventStreamFor('msg-1')!.listen(received.add);

        final event = ThinkingEvent(
          kind: ThinkingEventKind.reasoning,
          content: 'thinking...',
          timestamp: DateTime(2024),
        );
        registry.addEvent('msg-1', event);

        await Future<void>.delayed(Duration.zero);

        expect(received.length, 1);
        expect(received.first.content, 'thinking...');
        expect(received.first.kind, ThinkingEventKind.reasoning);
      });

      test('does nothing for unregistered messageId', () async {
        registry.addEvent(
          'unknown',
          ThinkingEvent(
            kind: ThinkingEventKind.error,
            content: 'err',
            timestamp: DateTime(2024),
          ),
        );
      });
    });

    group('unregister', () {
      test('closes both streams', () async {
        registry.register('msg-1');
        expect(registry.isActive('msg-1'), isTrue);

        await registry.unregister('msg-1');

        expect(registry.isActive('msg-1'), isFalse);
        expect(registry.streamFor('msg-1'), isNull);
        expect(registry.eventStreamFor('msg-1'), isNull);
      });

      test('does not throw for unknown messageId', () async {
        await registry.unregister('unknown');
      });

      test('allows re-registration after unregister', () async {
        registry.register('msg-1');
        await registry.unregister('msg-1');

        registry.register('msg-1');
        expect(registry.isActive('msg-1'), isTrue);

        final received = <String>[];
        registry.streamFor('msg-1')!.listen(received.add);
        registry.add('msg-1', 'new data');

        await Future<void>.delayed(Duration.zero);
        expect(received, ['new data']);
      });
    });

    group('isActive', () {
      test('returns false for never-registered messageId', () async {
        expect(registry.isActive('unknown'), isFalse);
      });

      test('returns false after unregister', () async {
        registry.register('msg-1');
        await registry.unregister('msg-1');
        expect(registry.isActive('msg-1'), isFalse);
      });
    });

    group('multiple message ids', () {
      test('streams are independent per messageId', () async {
        registry.register('msg-1');
        registry.register('msg-2');

        final received1 = <String>[];
        final received2 = <String>[];
        registry.streamFor('msg-1')!.listen(received1.add);
        registry.streamFor('msg-2')!.listen(received2.add);

        registry.add('msg-1', 'a');
        registry.add('msg-2', 'b');

        await Future<void>.delayed(Duration.zero);

        expect(received1, ['a']);
        expect(received2, ['b']);
      });

      test('unregistering one does not affect the other', () async {
        registry.register('msg-1');
        registry.register('msg-2');

        await registry.unregister('msg-1');

        expect(registry.isActive('msg-1'), isFalse);
        expect(registry.isActive('msg-2'), isTrue);
      });
    });
  });
}
