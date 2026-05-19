import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_step.dart';

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
    this.mentions = const [],
    this.requestedByUserId,
  });

  /// Channel the message was posted in.
  final String channelId;

  /// Owning workspace of the channel, used to scope the in-app activity feed.
  /// Sourced from the sending agent's workspace on the agent path; resolved
  /// from the channel on the human-mention path (see `MessagingService`);
  /// left null for every other human message (which never raises a
  /// notification).
  final String? workspaceId;

  /// Unique message identifier.
  final String messageId;

  /// Display name of the sender (user name or agent name).
  final String senderName;

  /// Truncated preview of the message content.
  final String contentPreview;

  /// Whether the message was sent by an agent (vs the user).
  final bool isAgentMessage;

  /// Principals explicitly `@mentioned` in this message (PRD 16 §15), used
  /// for notification ROUTING (PRD 16 §7): a mentioned principal is always
  /// notified, regardless of the sender-type/requester checks below. Empty
  /// for a message that resolved no mentions.
  final List<Principal> mentions;

  /// The human on whose behalf this message's agent run executed, when known
  /// (PRD 16 §7): lets a notification receiver suppress "someone else's agent
  /// run finished" pings that are not theirs. Null for a human-authored
  /// message, or when the requester was not resolved (e.g. a programmatic
  /// dispatch with no acting human).
  final String? requestedByUserId;

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
class ChannelDeleted implements DomainEvent {
  /// Creates a [ChannelDeleted] event.
  const ChannelDeleted({
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

/// Fired when a new conversation/channel is created.
///
/// Emitted by the messaging service after the channel row is committed (the
/// single chokepoint for both desktop-embedded and RPC paths). Listeners use it
/// to kick off background provisioning of the conversation workspace (repo
/// worktrees + per-agent overlay + derived `.mcp.json`) so the first agent turn
/// doesn't pay the setup cost and the UI can reflect a "preparing" state.
class ChannelCreated implements DomainEvent {
  /// Creates a [ChannelCreated] event.
  const ChannelCreated({
    required this.channelId,
    required this.occurredAt,
    this.workspaceId,
  });

  /// The created channel's id.
  final String channelId;

  /// Owning workspace, when known.
  final String? workspaceId;

  @override
  final DateTime occurredAt;
}

/// Fired as a channel's conversation workspace is provisioned: on entry, on each
/// granular step (cloning a repo, checking out a PR, setting up an agent), and on
/// the terminal ready/failed flip.
///
/// The same state is written to the channel row — that is what the desktop's
/// "Cloning …" banner reads — but a chat client is not watching a row. The chat
/// bridge listens here so a reader in Slack sees what a fresh channel is doing
/// instead of silence for the minutes a first clone can take.
class ChannelProvisioningChanged implements DomainEvent {
  /// Creates a [ChannelProvisioningChanged] event.
  const ChannelProvisioningChanged({
    required this.workspaceId,
    required this.channelId,
    required this.status,
    required this.occurredAt,
    this.step,
  });

  /// Owning workspace of the channel being provisioned.
  final String workspaceId;

  /// The channel whose workspace is being provisioned.
  final String channelId;

  /// Where provisioning stands.
  final ChannelProvisioningStatus status;

  /// The granular step in flight, when one is known. Null on entry and on the
  /// terminal flip, which clears the channel's step column.
  final ChannelProvisioningStep? step;

  @override
  final DateTime occurredAt;
}

/// Fired when a new conversation (parenthesis) is opened inside a channel.
class ConversationOpened implements DomainEvent {
  /// Creates a [ConversationOpened] event.
  const ConversationOpened({
    required this.workspaceId,
    required this.channelId,
    required this.conversationId,
    required this.occurredAt,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The channel the conversation lives in.
  final String channelId;

  /// The opened conversation's id.
  final String conversationId;

  @override
  final DateTime occurredAt;
}

/// Fired when a conversation (parenthesis) is archived (closed).
class ConversationArchived implements DomainEvent {
  /// Creates a [ConversationArchived] event.
  const ConversationArchived({
    required this.workspaceId,
    required this.channelId,
    required this.conversationId,
    required this.occurredAt,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The channel the conversation lives in.
  final String channelId;

  /// The archived conversation's id.
  final String conversationId;

  @override
  final DateTime occurredAt;
}
