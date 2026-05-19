import 'package:cc_harness/loop.dart';
import 'package:test/test.dart';

/// Covers enqueue routing, the push* helpers, drain* (FIFO + clear), peek
/// (non-destructive) and the has*/isEmpty predicates of [SteeringQueue].
void main() {
  final t0 = DateTime(2025, 6, 1);
  final t1 = DateTime(2025, 6, 2);

  SteeringMessage msg(
    String content,
    SteeringChannel channel, {
    DateTime? at,
    String? source,
  }) => SteeringMessage(
    content: content,
    channel: channel,
    enqueuedAt: at ?? t0,
    source: source,
  );

  group('SteeringQueue construction + emptiness', () {
    test('a fresh queue is empty and every lane reports empty', () {
      final queue = SteeringQueue();
      expect(queue.isEmpty, isTrue);
      expect(queue.hasSteering, isFalse);
      expect(queue.hasAside, isFalse);
      expect(queue.hasFollowUp, isFalse);
    });
  });

  group('enqueue routing', () {
    test('routes each message into the lane named by its channel', () {
      final queue = SteeringQueue()
        ..enqueue(msg('s', SteeringChannel.steering))
        ..enqueue(msg('a', SteeringChannel.aside))
        ..enqueue(msg('f', SteeringChannel.followUp));

      expect(queue.hasSteering, isTrue);
      expect(queue.hasAside, isTrue);
      expect(queue.hasFollowUp, isTrue);
      expect(queue.isEmpty, isFalse);

      expect(queue.peek(SteeringChannel.steering).single.content, 's');
      expect(queue.peek(SteeringChannel.aside).single.content, 'a');
      expect(queue.peek(SteeringChannel.followUp).single.content, 'f');
    });

    test('multiple messages stack in the same lane', () {
      final queue = SteeringQueue()
        ..enqueue(msg('s1', SteeringChannel.steering))
        ..enqueue(msg('s2', SteeringChannel.steering));
      expect(queue.peek(SteeringChannel.steering).map((m) => m.content), [
        's1',
        's2',
      ]);
    });
  });

  group('push* helpers stamp content + channel', () {
    test('pushSteering enqueues onto the steering lane', () {
      final queue = SteeringQueue()
        ..pushSteering('hello', source: 'agent-1', now: t0);
      final lane = queue.peek(SteeringChannel.steering);
      expect(lane, hasLength(1));
      expect(lane.single.content, 'hello');
      expect(lane.single.source, 'agent-1');
      expect(lane.single.enqueuedAt, t0);
      expect(lane.single.channel, SteeringChannel.steering);
    });

    test('pushAside enqueues onto the aside lane', () {
      final queue = SteeringQueue()..pushAside('bg', source: 'job', now: t1);
      final lane = queue.peek(SteeringChannel.aside);
      expect(lane.single.content, 'bg');
      expect(lane.single.channel, SteeringChannel.aside);
      expect(lane.single.enqueuedAt, t1);
      expect(lane.single.source, 'job');
    });

    test('pushFollowUp enqueues onto the follow-up lane', () {
      final queue = SteeringQueue()..pushFollowUp('foll', now: t0);
      final lane = queue.peek(SteeringChannel.followUp);
      expect(lane.single.content, 'foll');
      expect(lane.single.channel, SteeringChannel.followUp);
      expect(lane.single.source, isNull);
    });

    test('push* default to the wall-clock when now is omitted', () {
      final before = DateTime.now();
      final queue = SteeringQueue()..pushSteering('x');
      final after = DateTime.now();
      final at = queue.peek(SteeringChannel.steering).single.enqueuedAt;
      // [before, after] brackets DateTime.now() used internally.
      expect(!at.isBefore(before), isTrue);
      expect(!at.isAfter(after), isTrue);
    });
  });

  group('drain* returns FIFO order and clears only that lane', () {
    test(
      'drainSteering returns messages in enqueue order and clears the lane',
      () {
        final queue = SteeringQueue()
          ..pushSteering('first', now: t0)
          ..pushSteering('second', now: t1);

        final drained = queue.drainSteering();
        expect(drained.map((m) => m.content), ['first', 'second']);
        expect(queue.hasSteering, isFalse, reason: 'lane cleared');
        expect(queue.peek(SteeringChannel.steering), isEmpty);
      },
    );

    test(
      'drainAside returns messages in enqueue order and clears the lane',
      () {
        final queue = SteeringQueue()
          ..pushAside('a1', now: t0)
          ..pushAside('a2', now: t1);
        expect(queue.drainAside().map((m) => m.content), ['a1', 'a2']);
        expect(queue.hasAside, isFalse);
      },
    );

    test(
      'drainFollowUp returns messages in enqueue order and clears the lane',
      () {
        final queue = SteeringQueue()
          ..pushFollowUp('f1', now: t0)
          ..pushFollowUp('f2', now: t1);
        expect(queue.drainFollowUp().map((m) => m.content), ['f1', 'f2']);
        expect(queue.hasFollowUp, isFalse);
      },
    );

    test('draining one lane leaves the others intact', () {
      final queue = SteeringQueue()
        ..pushSteering('s', now: t0)
        ..pushAside('a', now: t0)
        ..pushFollowUp('f', now: t0);

      queue.drainSteering();
      expect(queue.hasSteering, isFalse);
      expect(queue.hasAside, isTrue, reason: 'aside untouched');
      expect(queue.hasFollowUp, isTrue, reason: 'follow-up untouched');
      expect(queue.isEmpty, isFalse);
    });

    test('draining an empty lane returns an empty list (no throw)', () {
      final queue = SteeringQueue();
      expect(queue.drainSteering(), isEmpty);
      expect(queue.drainAside(), isEmpty);
      expect(queue.drainFollowUp(), isEmpty);
    });

    test('draining every lane makes the queue empty', () {
      final queue = SteeringQueue()
        ..pushSteering('s', now: t0)
        ..pushAside('a', now: t0)
        ..pushFollowUp('f', now: t0)
        ..drainSteering()
        ..drainAside()
        ..drainFollowUp();
      expect(queue.isEmpty, isTrue);
    });
  });

  group('peek is non-destructive', () {
    test('repeated peek returns the same lane contents', () {
      final queue = SteeringQueue()
        ..pushSteering('s1', now: t0)
        ..pushSteering('s2', now: t1);
      final first = queue.peek(SteeringChannel.steering);
      final second = queue.peek(SteeringChannel.steering);
      expect(second.map((m) => m.content), first.map((m) => m.content));
      expect(queue.hasSteering, isTrue, reason: 'peek did not consume');
    });

    test('peek on an empty lane returns an empty unmodifiable list', () {
      final queue = SteeringQueue();
      final lane = queue.peek(SteeringChannel.steering);
      expect(lane, isEmpty);
      expect(
        () => lane.add(msg('x', SteeringChannel.steering)),
        throwsUnsupportedError,
      );
    });
  });

  group('ref correlation', () {
    test('pushSteering carries the ref through to the drain', () {
      final queue = SteeringQueue()..pushSteering('nudge', ref: 'row-1');
      final drained = queue.drainSteering();
      expect(drained.single.ref, 'row-1');
    });

    test('equality and hashCode include ref', () {
      final a = SteeringMessage(
        content: 'x',
        channel: SteeringChannel.steering,
        enqueuedAt: t0,
      );
      final b = SteeringMessage(
        content: 'x',
        channel: SteeringChannel.steering,
        enqueuedAt: t0,
        ref: 'row-1',
      );
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
    });
  });

  group('onDrained', () {
    test('reports every message a drain* call hands out, in order', () {
      final seen = <String>[];
      final queue = SteeringQueue();
      queue.onDrained = (m) {
        seen.add('${m.channel.name}:${m.content}');
      };
      queue
        ..pushSteering('s1', now: t0)
        ..pushAside('a1', now: t0)
        ..pushFollowUp('f1', now: t0);

      queue.drainSteering();
      queue.drainAside();
      queue.drainFollowUp();
      expect(seen, ['steering:s1', 'aside:a1', 'followUp:f1']);
    });

    test('does not fire for lanes the call did not drain', () {
      var fired = 0;
      final queue = SteeringQueue();
      queue.onDrained = (_) {
        fired++;
      };
      queue
        ..pushSteering('s', now: t0)
        ..pushAside('a', now: t0);

      queue.drainSteering();
      expect(fired, 1);
    });

    test('does not fire when a lane is empty', () {
      var fired = 0;
      final queue = SteeringQueue();
      queue.onDrained = (_) {
        fired++;
      };
      queue.drainSteering();
      expect(fired, 0);
    });
  });

  group('removeByRef', () {
    test('removes the matching message from the steering lane', () {
      final queue = SteeringQueue()
        ..pushSteering('keep', now: t0, ref: 'row-keep')
        ..pushSteering('drop', now: t1, ref: 'row-drop');

      expect(queue.removeByRef('row-drop'), isTrue);
      expect(
        queue.peek(SteeringChannel.steering).map((m) => m.content),
        ['keep'],
      );
      expect(queue.removeByRef('row-drop'), isFalse, reason: 'already gone');
    });

    test('searches aside and follow-up lanes too', () {
      final queue = SteeringQueue()
        ..pushAside('a', now: t0, ref: 'row-a')
        ..pushFollowUp('f', now: t0, ref: 'row-f');

      expect(queue.removeByRef('row-f'), isTrue);
      expect(queue.hasAside, isTrue);
      expect(queue.removeByRef('row-a'), isTrue);
      expect(queue.isEmpty, isTrue);
    });

    test('a null ref removes nothing (internal messages stay)', () {
      final queue = SteeringQueue()..pushSteering('internal', now: t0);
      expect(queue.removeByRef(null), isFalse);
      expect(queue.hasSteering, isTrue);
    });

    test('an unknown ref removes nothing', () {
      final queue = SteeringQueue()..pushSteering('s', now: t0, ref: 'row-1');
      expect(queue.removeByRef('row-other'), isFalse);
      expect(queue.hasSteering, isTrue);
    });
  });

  group('pushFront', () {
    test('inserts at the front of the steering lane', () {
      final queue = SteeringQueue()
        ..pushSteering('first', now: t0)
        ..pushFront(
          SteeringMessage(
            content: 'urgent',
            channel: SteeringChannel.steering,
            enqueuedAt: t1,
            ref: 'row-urgent',
          ),
        );

      expect(
        queue.peek(SteeringChannel.steering).map((m) => m.content),
        ['urgent', 'first'],
      );
    });

    test('routes by the message channel, like enqueue', () {
      final queue = SteeringQueue()
        ..pushAside('existing', now: t0)
        ..pushFront(
          SteeringMessage(
            content: 'urgent-aside',
            channel: SteeringChannel.aside,
            enqueuedAt: t1,
          ),
        );

      expect(
        queue.peek(SteeringChannel.aside).map((m) => m.content),
        ['urgent-aside', 'existing'],
      );
      expect(queue.hasSteering, isFalse);
    });

    test('removeByRef + pushFront moves a message to the front', () {
      final urgent = SteeringMessage(
        content: 'urgent',
        channel: SteeringChannel.steering,
        enqueuedAt: t0,
        ref: 'row-urgent',
      );
      final queue = SteeringQueue()
        ..pushSteering('a', now: t0, ref: 'row-a')
        ..enqueue(urgent)
        ..pushSteering('b', now: t1, ref: 'row-b');

      expect(queue.removeByRef('row-urgent'), isTrue);
      queue.pushFront(urgent);

      expect(
        queue.drainSteering().map((m) => m.content),
        ['urgent', 'a', 'b'],
      );
    });
  });
}
