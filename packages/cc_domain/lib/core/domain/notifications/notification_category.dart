/// Categories of desktop notifications the app can emit.
///
/// Each category can be independently enabled/disabled by the user.
enum NotificationCategory {
  /// An agent finished a run in a workspace.
  agentRunCompleted,

  /// A pull request was published by an agent.
  pullRequestPublished,

  /// A pull request was merged.
  prMerged,

  /// A new message arrived in a non-active space.
  newMessage,

  /// The user was mentioned in a pull request (GitHub notifications poll,
  /// `reason: mention`). Distinct from [reviewRequested]: a mention is not a
  /// review request. These two are the only PR notifications the user
  /// receives, so they are pinged solely when GitHub decided the thread
  /// concerns them — never merely because a new PR appeared.
  prMentioned,

  /// The user's review was requested on a pull request (GitHub notifications
  /// poll). Draft PRs never fire this — GitHub withholds review-request
  /// notifications until the PR is marked ready.
  reviewRequested,

  /// A finished AI review no longer describes the pull request it reviewed,
  /// because the author has pushed since. Deliberately NOT raised on every
  /// push: only when a review actually exists for the commit that was
  /// replaced, so this stays a signal rather than a per-commit ping.
  reviewStale,

  /// A pull request the user authored became mergeable, or stopped being
  /// mergeable. One category rather than two because they are the two edges of
  /// one state machine answering one question — "can I land this?" — and
  /// muting the blocked edge while keeping the ready one leaves a bell that
  /// only ever lies optimistically.
  prMergeReadiness,

  /// A reviewer decided on a pull request the user authored: approved (with the
  /// count still outstanding), requested changes, or had an approval dismissed.
  /// One category for the same reason as [rigStatusChanged]: the operator
  /// question is always "what did reviewers decide?", and three toggles for one
  /// answer is three chances to mute the one that mattered.
  prReviewDecision,

  /// CI on a pull request the user authored went red, or recovered. Recovery is
  /// only meaningful as the closing edge of a failure they were told about, so
  /// separating them would let the two desynchronise into a green with no
  /// preceding red.
  prChecksStatus,

  /// Someone moved a review conversation the user is in — replied in one of
  /// their threads, or resolved one.
  prThreadActivity,

  /// A ticket was assigned to an agent or team.
  ticketAssigned,

  /// A ticket changed status.
  ticketStatusChanged,

  /// A calendar meeting is starting within the configured lead window.
  meetingStartsSoon,

  /// A connected calendar account's OAuth token expired and the user must
  /// reconnect to resume syncing.
  calendarAuthExpired,

  /// An enclosure (rig) changed hands or went away: a human took control of a
  /// machine an agent was driving, the system reclaimed one, or the hypervisor
  /// died under it. One category rather than three because the operator
  /// question is always the same — "what happened to that machine?" — and
  /// three toggles in Settings for one answer is three chances to mute the
  /// one that mattered.
  rigStatusChanged,
}

/// The pillar a [NotificationCategory] belongs to.
///
/// Exists so the settings screen can render headed groups instead of a flat
/// list — sixteen ungrouped toggles is a wall nobody reads, and the operator
/// looking for "stop telling me about CI" should not have to scan past
/// calendars and tickets to find it. Declaration order is the order the groups
/// render in.
enum NotificationCategoryGroup {
  /// Agent runs.
  agents,

  /// Pull requests and code review.
  pullRequests,

  /// Spaces and direct messages.
  messages,

  /// Ticketing.
  tickets,

  /// Calendar and meetings.
  calendar,

  /// Enclosures (rigs).
  machines,
}

/// Which settings group each category renders under.
extension NotificationCategoryGrouping on NotificationCategory {
  /// The pillar this category belongs to.
  ///
  /// Exhaustive by construction: a new [NotificationCategory] fails to compile
  /// here until it is placed, which is what stops one from silently never
  /// appearing in Settings.
  NotificationCategoryGroup get group => switch (this) {
    NotificationCategory.agentRunCompleted => NotificationCategoryGroup.agents,
    NotificationCategory.pullRequestPublished ||
    NotificationCategory.prMerged ||
    NotificationCategory.prMentioned ||
    NotificationCategory.reviewRequested ||
    NotificationCategory.reviewStale ||
    NotificationCategory.prMergeReadiness ||
    NotificationCategory.prReviewDecision ||
    NotificationCategory.prChecksStatus ||
    NotificationCategory.prThreadActivity =>
      NotificationCategoryGroup.pullRequests,
    NotificationCategory.newMessage => NotificationCategoryGroup.messages,
    NotificationCategory.ticketAssigned ||
    NotificationCategory.ticketStatusChanged =>
      NotificationCategoryGroup.tickets,
    NotificationCategory.meetingStartsSoon ||
    NotificationCategory.calendarAuthExpired =>
      NotificationCategoryGroup.calendar,
    NotificationCategory.rigStatusChanged => NotificationCategoryGroup.machines,
  };
}

/// How prominently a notification should surface in the app.
///
/// Banner status is **earned**, never the default: an event is promoted to
/// [banner] only when it is both time-critical *and* directly actionable (a
/// meeting starting, a calendar that must be reconnected). Everything else
/// stays [centerOnly] so the ambient banner rail (PRD 25 §1) never becomes a
/// dumping ground — the hard inclusion rule that keeps it legible.
enum NotificationPresentation {
  /// Recorded in the in-app notification center only (the durable history and
  /// the top-bar bell). No ambient surface. The default.
  centerOnly,

  /// Delivered as an OS/desktop notification (a transient toast) in addition
  /// to the center.
  notification,

  /// Raised into the ambient in-app banner rail — reserved for time-critical,
  /// actionable events the operator must see and act on in-flow.
  banner,
}

/// Data class carrying everything the notification infrastructure needs
/// to display a desktop notification and handle a click-through.
///
/// Constructed by the event-to-notification mapping logic in the
/// infrastructure layer. The domain layer never builds these — it only
/// fires domain events.
class AppNotification {
  /// Creates an [AppNotification].
  ///
  /// [workspaceId] is **required** (never positionally defaulted) so every
  /// producer must consciously attribute the notification to a workspace —
  /// the in-app activity feed is workspace-scoped. It is nullable only for
  /// notifications that are genuinely workspace-less (e.g. external-PR polling,
  /// which is cross-workspace by design); those are excluded from any
  /// workspace's dashboard activity feed but still appear in the global bell.
  const AppNotification({
    required this.category,
    required this.title,
    required this.body,
    required this.route,
    required this.workspaceId,
    this.spaceId,
    this.presentation = NotificationPresentation.centerOnly,
  });

  /// Which notification category this belongs to.
  final NotificationCategory category;

  /// Notification title shown in the OS notification center.
  final String title;

  /// Notification body text.
  final String body;

  /// Route to navigate to when the user clicks the notification.
  final String route;

  /// Owning workspace, used to scope the in-app "Recent activity" feed to the
  /// active workspace. Null only when the originating event is genuinely
  /// cross-workspace (see the constructor doc).
  final String? workspaceId;

  /// Optional space/conversation ID for space-level suppression.
  ///
  /// When set, the notification service checks whether the user is
  /// currently viewing this specific space and suppresses the
  /// notification (and sound) if so.
  final String? spaceId;

  /// How prominently this notification surfaces. Defaults to
  /// [NotificationPresentation.centerOnly]; the event-to-notification mappers
  /// promote only time-critical, actionable events to
  /// [NotificationPresentation.banner].
  final NotificationPresentation presentation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          category == other.category &&
          title == other.title &&
          body == other.body &&
          route == other.route &&
          workspaceId == other.workspaceId &&
          spaceId == other.spaceId &&
          presentation == other.presentation;

  @override
  int get hashCode => Object.hash(
    category,
    title,
    body,
    route,
    workspaceId,
    spaceId,
    presentation,
  );
}
