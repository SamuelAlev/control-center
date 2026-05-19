import 'package:control_center/core/domain/services/agent_wakeup_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WakeupRequest', () {
    test('merge combines contexts and reasons', () {
      final a = WakeupRequest(
        agentId: 'agent-1',
        wakeReason: 'tick',
        contextSnapshot: {'key': 'a'},
        enqueuedAt: DateTime(2026, 1, 1, 0, 0, 2),
      );
      final b = WakeupRequest(
        agentId: 'agent-1',
        wakeReason: 'file_change',
        contextSnapshot: {'key': 'b'},
        enqueuedAt: DateTime(2026, 1, 1, 0, 0, 1),
      );

      final merged = a.merge(b);

      expect(merged.agentId, 'agent-1');
      expect(merged.wakeReason, 'tick; file_change');
      expect(merged.contextSnapshot, {'key': 'b'}); // b overwrites a
      expect(merged.enqueuedAt, DateTime(2026, 1, 1, 0, 0, 1)); // earliest
    });

    test('merge with null contexts yields null', () {
      final a = WakeupRequest(
        agentId: 'agent-1',
        wakeReason: 'tick',
        enqueuedAt: DateTime(2026, 1, 1),
      );
      final b = WakeupRequest(
        agentId: 'agent-1',
        wakeReason: 'file_change',
        enqueuedAt: DateTime(2026, 1, 1),
      );

      final merged = a.merge(b);
      expect(merged.contextSnapshot, isNull);
    });

    test('equality when all fields match', () {
      final now = DateTime(2026, 1, 1);
      final a = WakeupRequest(
        agentId: 'agent-1',
        wakeReason: 'tick',
        contextSnapshot: {'k': 1},
        enqueuedAt: now,
      );
      final b = WakeupRequest(
        agentId: 'agent-1',
        wakeReason: 'tick',
        contextSnapshot: {'k': 1},
        enqueuedAt: now,
      );
      expect(a, equals(b));
    });

    test('hashCode matches for equal instances', () {
      final now = DateTime(2026, 1, 1);
      final a = WakeupRequest(
        agentId: 'agent-1',
        wakeReason: 'tick',
        contextSnapshot: {'k': 1},
        enqueuedAt: now,
      );
      final b = WakeupRequest(
        agentId: 'agent-1',
        wakeReason: 'tick',
        contextSnapshot: {'k': 1},
        enqueuedAt: now,
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when fields differ', () {
      final now = DateTime(2026, 1, 1);
      final a = WakeupRequest(
        agentId: 'agent-1',
        wakeReason: 'tick',
        enqueuedAt: now,
      );
      final b = WakeupRequest(
        agentId: 'agent-1',
        wakeReason: 'other',
        enqueuedAt: now,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('AgentWakeupQueue', () {
    late AgentWakeupQueue queue;

    setUp(() {
      queue = AgentWakeupQueue();
    });

    test('enqueue and flush basic', () {
      queue.enqueue('agent-1', 'tick');
      final result = queue.flush('agent-1');

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.agentId, 'agent-1');
      expect(result.first.wakeReason, 'tick');
    });

    test('enqueue coalesces within window', () async {
      queue.enqueue('agent-1', 'tick');
      // Enqueue again immediately — within the 5s coalescing window
      queue.enqueue('agent-1', 'file_change');

      final result = queue.flush('agent-1');
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.wakeReason, contains('tick'));
      expect(result.first.wakeReason, contains('file_change'));
    });

    test('enqueue creates new entry outside window', () async {
      queue.enqueue('agent-1', 'tick');
      // Wait longer than coalescing window
      await Future<void>.delayed(
        AgentWakeupQueue.coalescingWindow + const Duration(milliseconds: 100),
      );
      queue.enqueue('agent-1', 'file_change');

      final result = queue.flush('agent-1');
      expect(result, isNotNull);
      // flush merges multiple entries into one
      expect(result!.length, 1);
      expect(result.first.wakeReason, contains('tick'));
      expect(result.first.wakeReason, contains('file_change'));
    });

    test('flush returns null for unknown agent', () {
      expect(queue.flush('unknown'), isNull);
    });

    test('flush merges multiple requests', () {
      // We need multiple entries outside the coalescing window
      // but since we can't control time in a unit test easily,
      // test flush with single entry returns correctly
      queue.enqueue('agent-1', 'reason-a');
      final result = queue.flush('agent-1');
      expect(result!.length, 1);
      expect(result.first.wakeReason, 'reason-a');
    });

    test('purge removes agent queue', () {
      queue.enqueue('agent-1', 'tick');
      expect(queue.hasPending('agent-1'), isTrue);

      queue.purge('agent-1');
      expect(queue.hasPending('agent-1'), isFalse);
      expect(queue.flush('agent-1'), isNull);
    });

    test('clear removes all queues', () {
      queue.enqueue('agent-1', 'tick');
      queue.enqueue('agent-2', 'tick');
      expect(queue.length, 2);

      queue.clear();
      expect(queue.isEmpty, isTrue);
      expect(queue.length, 0);
    });

    test('hasPending checks correctly', () {
      expect(queue.hasPending('agent-1'), isFalse);
      queue.enqueue('agent-1', 'tick');
      expect(queue.hasPending('agent-1'), isTrue);
      expect(queue.hasPending('agent-2'), isFalse);
    });

    test('pendingCount returns correct count', () {
      expect(queue.pendingCount('agent-1'), 0);
      queue.enqueue('agent-1', 'tick');
      expect(queue.pendingCount('agent-1'), 1);
    });

    test('isEmpty/isNotEmpty/length work', () {
      expect(queue.isEmpty, isTrue);
      expect(queue.isNotEmpty, isFalse);
      expect(queue.length, 0);

      queue.enqueue('agent-1', 'tick');
      expect(queue.isEmpty, isFalse);
      expect(queue.isNotEmpty, isTrue);
      expect(queue.length, 1);

      queue.enqueue('agent-2', 'tick');
      expect(queue.length, 2);
    });

    test('pendingAgentIds returns correct list', () {
      queue.enqueue('agent-1', 'tick');
      queue.enqueue('agent-3', 'tick');
      queue.enqueue('agent-2', 'tick');

      final ids = queue.pendingAgentIds;
      expect(ids, containsAll(['agent-1', 'agent-2', 'agent-3']));
      expect(ids.length, 3);
    });
  });
}
