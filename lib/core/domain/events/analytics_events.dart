import 'package:control_center/core/domain/events/domain_event_bus.dart';

/// Achievement unlocked event.
class AchievementUnlocked implements DomainEvent {
  /// Creates an [AchievementUnlocked].
  const AchievementUnlocked({
    required this.agentId,
    required this.badgeKey,
    required this.occurredAt,
  });

  /// Agent that earned the badge.
  final String agentId;

  /// Badge key (e.g., 'first_pr').
  final String badgeKey;

  @override
  final DateTime occurredAt;
}
