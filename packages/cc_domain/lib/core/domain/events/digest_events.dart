import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// What one line of a [WaitingDigest] is about.
enum WaitingDigestItemType {
  /// A goal paused for a person's review (`hold: needsReview`).
  goalReview,

  /// A goal waiting on a person's answer (`hold: person`).
  goalPerson,

  /// A wake held until a person releases or delivers it.
  heldWake,

  /// An improvement proposal waiting to be accepted or rejected.
  improvement,

  /// An approval or question of a run the server started, waiting on a
  /// person until its deadline ([WaitingDigestItem.expiresAt]).
  request,
}

/// Wire names of [WaitingDigestItemType].
extension WaitingDigestItemTypeWire on WaitingDigestItemType {
  /// The snake_case wire name.
  String get wire => switch (this) {
    WaitingDigestItemType.goalReview => 'goal_review',
    WaitingDigestItemType.goalPerson => 'goal_person',
    WaitingDigestItemType.heldWake => 'held_wake',
    WaitingDigestItemType.improvement => 'improvement',
    WaitingDigestItemType.request => 'request',
  };
}

/// One thing that waits for a person, as the digest lists it.
class WaitingDigestItem {
  /// Creates an item. Throws [ArgumentError] for an empty id.
  WaitingDigestItem({
    required this.type,
    required this.id,
    required this.summary,
    this.spaceId,
    this.conversationId,
    this.agentId,
    this.expiresAt,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
  }

  /// What the item is.
  final WaitingDigestItemType type;

  /// The goal, wake or proposal id.
  final String id;

  /// A short server-written line (a goal's objective, a proposal's title).
  final String summary;

  /// The space it is in, when it has one.
  final String? spaceId;

  /// The conversation it is in, when it has one.
  final String? conversationId;

  /// The agent it concerns, when it has one.
  final String? agentId;

  /// When a [WaitingDigestItemType.request] stops waiting (its approval is
  /// then denied, its question withdrawn); null for the other types.
  final DateTime? expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaitingDigestItem &&
          type == other.type &&
          id == other.id &&
          summary == other.summary &&
          spaceId == other.spaceId &&
          conversationId == other.conversationId &&
          agentId == other.agentId &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(
    type,
    id,
    summary,
    spaceId,
    conversationId,
    agentId,
    expiresAt,
  );
}

/// The once-a-day digest of what waits for one person in one workspace:
/// goals that need review or an answer, held wakes, pending improvement
/// proposals and the requests of runs the server started. Published only
/// when something waits, at most once per local day (plan section 12, "One
/// digest a day lists what is waiting").
class WaitingDigest implements DomainEvent {
  /// Creates a digest. Throws [ArgumentError] when [items] is empty.
  WaitingDigest({
    required this.workspaceId,
    required this.forUserId,
    required this.day,
    required this.items,
    required this.occurredAt,
  }) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'a digest lists something');
    }
  }

  /// The workspace.
  final String workspaceId;

  /// The person the digest is for.
  final String forUserId;

  /// The local day (`YYYY-MM-DD` in the workspace's time zone) it is for.
  final String day;

  /// What waits, oldest first.
  final List<WaitingDigestItem> items;

  @override
  final DateTime occurredAt;
}
