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

  /// A new message arrived in a non-active channel.
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
    this.channelId,
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

  /// Optional channel/conversation ID for channel-level suppression.
  ///
  /// When set, the notification service checks whether the user is
  /// currently viewing this specific channel and suppresses the
  /// notification (and sound) if so.
  final String? channelId;

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
          channelId == other.channelId &&
          presentation == other.presentation;

  @override
  int get hashCode => Object.hash(
    category,
    title,
    body,
    route,
    workspaceId,
    channelId,
    presentation,
  );
}
