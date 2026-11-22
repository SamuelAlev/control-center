/// The three kinds a notification frame of long-running work carries, so a
/// client can group and filter them (plan section 12): something finished,
/// an agent asked something, or something waits for a person's review.
enum NotificationKind {
  /// Something finished or ended: a goal completed, failed or was
  /// cancelled; a wake rule ended.
  notify,

  /// An agent asked a person something: an approval, a question or a
  /// credential it needs.
  question,

  /// Something waits for a person to decide: a goal needs review, an
  /// improvement was proposed, a pipeline run is held, the daily digest.
  review,
}

/// The params key every such frame carries its [NotificationKind] under.
const String notificationKindKey = 'notification_kind';

/// The params key every frame carries a boolean under: true only for the
/// long-running work's FYI frames (`wake_rule_ended`, a terminal
/// `goal_settled`), which a client shows silently and Web Push sends at low
/// urgency. Quietness is set per frame by the server, never derived from
/// the [NotificationKind]: every other frame, `notify` ones included, is
/// false and sounds as it always did.
const String notificationQuietKey = 'quiet';

/// Wire names of [NotificationKind].
extension NotificationKindWire on NotificationKind {
  /// The snake_case wire name (`notify`, `question`, `review`).
  String get wire => name;

  /// Every wire name.
  static List<String> get wireNames => [
    for (final k in NotificationKind.values) k.wire,
  ];

  /// The kind named [wire], or null.
  static NotificationKind? tryParse(Object? wire) {
    for (final k in NotificationKind.values) {
      if (k.wire == wire) {
        return k;
      }
    }
    return null;
  }
}
