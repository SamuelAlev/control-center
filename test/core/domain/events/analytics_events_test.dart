import 'package:control_center/core/domain/events/analytics_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AchievementUnlocked',() {
    test('constructs with all fields', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 5, 18);
      final event = AchievementUnlocked(
        agentId: 'agent-1',
        badgeKey: 'first_pr',
        occurredAt: now,
      );

      expect(event.agentId, 'agent-1');
      expect(event.badgeKey, 'first_pr');
      expect(event.occurredAt, now);
    });

    test('is a DomainEvent', timeout: const Timeout.factor(2), () {
      final event = AchievementUnlocked(
        agentId: 'a1',
        badgeKey: 'badge',
        occurredAt: DateTime.now(),
      );

      expect(event, isA<DomainEvent>());
    });

    test('different badgeKeys produce distinct events', timeout: const Timeout.factor(2), () {
      final now = DateTime(2026, 1, 1);
      final a = AchievementUnlocked(
        agentId: 'a1',
        badgeKey: 'first_pr',
        occurredAt: now,
      );
      final b = AchievementUnlocked(
        agentId: 'a1',
        badgeKey: 'ten_prs',
        occurredAt: now,
      );

      expect(a.badgeKey, isNot(equals(b.badgeKey)));
    });

    test('type filtering on bus', timeout: const Timeout.factor(2), () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);

      final received = <AchievementUnlocked>[];
      bus.on<AchievementUnlocked>().listen(received.add);

      bus.publish(
        AchievementUnlocked(
          agentId: 'a1',
          badgeKey: 'first_pr',
          occurredAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, hasLength(1));
      expect(received.first.badgeKey, 'first_pr');
    });
  });
}
