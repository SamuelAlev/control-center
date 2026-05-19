import 'package:cc_domain/features/dispatch/domain/steering/steering_message.dart';
import 'package:cc_domain/features/dispatch/domain/steering/steering_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A fixed clock so enqueuedAt is deterministic across the suite.
  final t0 = DateTime.utc(2026, 1, 1, 12);

  group('SteeringMessage', () {
    test('asserts non-empty content', () {
      expect(
        () => SteeringMessage(
          content: '',
          channel: SteeringChannel.steering,
          enqueuedAt: t0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality and hashCode use all fields', () {
      final a = SteeringMessage(
        content: 'hello',
        channel: SteeringChannel.aside,
        enqueuedAt: t0,
        source: 'peer-1',
      );
      final b = SteeringMessage(
        content: 'hello',
        channel: SteeringChannel.aside,
        enqueuedAt: t0,
        source: 'peer-1',
      );
      final c = SteeringMessage(
        content: 'hello',
        channel: SteeringChannel.steering,
        enqueuedAt: t0,
        source: 'peer-1',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('SteeringQueue enqueue routing', () {
    test('enqueue routes each message to the matching lane', () {
      final queue = SteeringQueue();

      queue
        ..enqueue(
          SteeringMessage(
            content: 's',
            channel: SteeringChannel.steering,
            enqueuedAt: t0,
          ),
        )
        ..enqueue(
          SteeringMessage(
            content: 'a',
            channel: SteeringChannel.aside,
            enqueuedAt: t0,
          ),
        )
        ..enqueue(
          SteeringMessage(
            content: 'f',
            channel: SteeringChannel.followUp,
            enqueuedAt: t0,
          ),
        );

      expect(queue.peek(SteeringChannel.steering).single.content, 's');
      expect(queue.peek(SteeringChannel.aside).single.content, 'a');
      expect(queue.peek(SteeringChannel.followUp).single.content, 'f');
    });

    test('push helpers route to their lane and stamp the supplied clock', () {
      final queue = SteeringQueue()
        ..pushSteering('go', source: 'boss', now: t0)
        ..pushAside('fyi', now: t0)
        ..pushFollowUp('then this', now: t0);

      final steering = queue.peek(SteeringChannel.steering).single;
      expect(steering.content, 'go');
      expect(steering.channel, SteeringChannel.steering);
      expect(steering.source, 'boss');
      expect(steering.enqueuedAt, t0);

      expect(queue.peek(SteeringChannel.aside).single.content, 'fyi');
      expect(queue.peek(SteeringChannel.followUp).single.content, 'then this');
    });
  });

  group('SteeringQueue drain', () {
    test('drain returns FIFO order', () {
      final queue = SteeringQueue()
        ..pushSteering('first', now: t0)
        ..pushSteering('second', now: t0)
        ..pushSteering('third', now: t0);

      final drained = queue.drainSteering();
      expect(
        drained.map((m) => m.content).toList(),
        <String>['first', 'second', 'third'],
      );
    });

    test('drain clears only the drained lane', () {
      final queue = SteeringQueue()
        ..pushSteering('s', now: t0)
        ..pushAside('a', now: t0)
        ..pushFollowUp('f', now: t0);

      final drainedSteering = queue.drainSteering();

      expect(drainedSteering, hasLength(1));
      expect(queue.hasSteering, isFalse);
      // The other lanes are untouched.
      expect(queue.hasAside, isTrue);
      expect(queue.hasFollowUp, isTrue);
      expect(queue.peek(SteeringChannel.aside).single.content, 'a');
      expect(queue.peek(SteeringChannel.followUp).single.content, 'f');
    });

    test('lanes are independent across all three channels', () {
      final queue = SteeringQueue()
        ..pushSteering('s1', now: t0)
        ..pushAside('a1', now: t0)
        ..pushAside('a2', now: t0)
        ..pushFollowUp('f1', now: t0);

      expect(queue.drainAside().map((m) => m.content).toList(), <String>[
        'a1',
        'a2',
      ]);
      // Aside drained; steering and follow-up remain.
      expect(queue.hasAside, isFalse);
      expect(queue.drainSteering().single.content, 's1');
      expect(queue.drainFollowUp().single.content, 'f1');
    });

    test('draining an empty lane returns an empty list', () {
      final queue = SteeringQueue();

      expect(queue.drainSteering(), isEmpty);
      expect(queue.drainAside(), isEmpty);
      expect(queue.drainFollowUp(), isEmpty);

      // Push to one lane, then drain the others — still empty.
      queue.pushSteering('s', now: t0);
      expect(queue.drainAside(), isEmpty);
      expect(queue.drainFollowUp(), isEmpty);
      // The populated lane survives.
      expect(queue.hasSteering, isTrue);
    });
  });

  group('SteeringQueue state predicates', () {
    test('isEmpty and has* reflect lane state', () {
      final queue = SteeringQueue();

      expect(queue.isEmpty, isTrue);
      expect(queue.hasSteering, isFalse);
      expect(queue.hasAside, isFalse);
      expect(queue.hasFollowUp, isFalse);

      queue.pushAside('a', now: t0);
      expect(queue.isEmpty, isFalse);
      expect(queue.hasAside, isTrue);
      expect(queue.hasSteering, isFalse);

      queue.drainAside();
      expect(queue.isEmpty, isTrue);
      expect(queue.hasAside, isFalse);
    });

    test('peek is non-destructive', () {
      final queue = SteeringQueue()..pushSteering('s', now: t0);

      expect(queue.peek(SteeringChannel.steering), hasLength(1));
      // Peeking again still shows the message; nothing was consumed.
      expect(queue.peek(SteeringChannel.steering), hasLength(1));
      expect(queue.hasSteering, isTrue);
    });
  });
}
