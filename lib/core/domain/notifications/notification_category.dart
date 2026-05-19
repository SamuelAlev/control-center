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

  /// An external PR was detected via polling (not authored by our agents).
  externalPr,

  /// A ticket was assigned to an agent or team.
  ticketAssigned,

  /// A ticket changed status.
  ticketStatusChanged,
  ;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          category == other.category &&
          title == other.title &&
          body == other.body &&
          route == other.route &&
          workspaceId == other.workspaceId &&
          channelId == other.channelId;

  @override
  int get hashCode =>
      Object.hash(category, title, body, route, workspaceId, channelId);
}
