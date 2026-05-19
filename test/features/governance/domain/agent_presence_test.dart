import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/features/governance/domain/value_objects/agent_presence.dart';
import 'package:cc_domain/features/governance/domain/value_objects/runtime_health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deriveAgentPresence', () {
    test('online + working with capacity counts (acceptance)', () {
      final p = deriveAgentPresence(
        health: RuntimeHealth.online,
        lifecycle: AgentLifecycleStatus.active,
        runningCount: 2,
        queuedCount: 1,
        capacity: 3,
      );
      expect(p.availability, AgentAvailability.online);
      expect(p.workload, Workload.working);
      expect(p.summary, 'online + working (2/3)');
      expect(p.isAtCapacity, isFalse);
      expect(p.hasFreeSlot, isTrue);
    });

    test('at capacity has no free slot', () {
      final p = deriveAgentPresence(
        health: RuntimeHealth.online,
        lifecycle: AgentLifecycleStatus.active,
        runningCount: 3,
        queuedCount: 0,
        capacity: 3,
      );
      expect(p.isAtCapacity, isTrue);
      expect(p.hasFreeSlot, isFalse);
    });

    test('recently-lost runtime reads as unstable', () {
      final p = deriveAgentPresence(
        health: RuntimeHealth.recentlyLost,
        lifecycle: AgentLifecycleStatus.active,
        runningCount: 0,
        queuedCount: 0,
        capacity: 1,
      );
      expect(p.availability, AgentAvailability.unstable);
      expect(p.workload, Workload.idle);
    });

    test('offline runtime is offline; queued work shows queued workload', () {
      final p = deriveAgentPresence(
        health: RuntimeHealth.offline,
        lifecycle: AgentLifecycleStatus.active,
        runningCount: 0,
        queuedCount: 2,
        capacity: 1,
      );
      expect(p.availability, AgentAvailability.offline);
      expect(p.workload, Workload.queued);
    });

    test('archived lifecycle wins over runtime health', () {
      final p = deriveAgentPresence(
        health: RuntimeHealth.online,
        lifecycle: AgentLifecycleStatus.archived,
        runningCount: 0,
        queuedCount: 0,
        capacity: 1,
      );
      expect(p.availability, AgentAvailability.archived);
    });
  });
}
