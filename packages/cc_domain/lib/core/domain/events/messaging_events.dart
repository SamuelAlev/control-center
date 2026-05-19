import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// Fired when a new message is inserted into a channel.
///
/// Emitted by the messaging data layer after the DB write succeeds.
/// The notification infrastructure listens to this event to show a
/// desktop notification when the user is not viewing the channel.
class MessageReceived implements DomainEvent {
  /// Creates a [MessageReceived] event.
  const MessageReceived({
    required this.channelId,
    required this.messageId,
    required this.senderName,
    required this.contentPreview,
    required this.isAgentMessage,
    required this.workspaceId,
    required this.occurredAt,
  });

  /// Channel the message was posted in.
  final String channelId;

  /// Owning workspace of the channel, used to scope the in-app activity feed.
  /// Sourced from the sending agent's workspace on the agent path; null on the
  /// user-message path (which never raises a notification).
  final String? workspaceId;

  /// Unique message identifier.
  final String messageId;

  /// Display name of the sender (user name or agent name).
  final String senderName;

  /// Truncated preview of the message content.
  final String contentPreview;

  /// Whether the message was sent by an agent (vs the user).
  final bool isAgentMessage;

  @override
  final DateTime occurredAt;
}

/// Fired when a conversation/channel is deleted.
///
/// Emitted by the messaging data layer after the channel is removed. Listeners
/// (e.g. the worktree garbage collector) use it to tear down per-conversation
/// resources such as isolated repo worktrees. [workspaceId] may be null when it
/// could not be resolved before deletion; teardown then falls back to a
/// channel-id lookup across workspaces.
class ConversationDeleted implements DomainEvent {
  /// Creates a [ConversationDeleted] event.
  const ConversationDeleted({
    required this.channelId,
    required this.occurredAt,
    this.workspaceId,
  });

  /// The deleted channel's id.
  final String channelId;

  /// Owning workspace, when known.
  final String? workspaceId;

  @override
  final DateTime occurredAt;
}
