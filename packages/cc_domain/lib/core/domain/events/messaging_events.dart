import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';

/// Fired when a new message is inserted into a space.
///
/// Emitted by the messaging data layer after the DB write succeeds.
/// The notification infrastructure listens to this event to show a
/// desktop notification when the user is not viewing the space.
class MessageReceived implements DomainEvent {
  /// Creates a [MessageReceived] event.
  const MessageReceived({
    required this.spaceId,
    required this.messageId,
    required this.senderName,
    required this.contentPreview,
    required this.isAgentMessage,
    required this.workspaceId,
    required this.occurredAt,
    this.mentions = const [],
    this.requestedByUserId,
    this.senderUserId,
  });

  /// Space the message was posted in.
  final String spaceId;

  /// Owning workspace of the space, used to scope the in-app activity feed.
  ///
  /// Sourced from the sending agent's workspace on the agent path and resolved
  /// from the space on the human-mention path (see `MessagingService`).
  ///
  /// `required` but still nullable, and the second half is deliberate rather
  /// than forgotten: the DISPATCH CHAIN cannot yet prove non-null.
  /// `AgentDispatchPort.start` takes `String? workspaceId` and
  /// `DispatchSession` stores it as `String?`, so tightening the event without
  /// tightening that chain would only move the `!` to the publisher. What `required` buys today is that a publisher has to SAY
  /// `null` rather than omit the argument, which is what let sites drift.
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

  /// The human who WROTE this message, when one did.
  ///
  /// The counterpart to [requestedByUserId], and the opposite test: that field
  /// says who a notification is FOR, this one says who it is ABOUT. It exists
  /// so a receiver can drop their own message — a person who `@mentions`
  /// themselves would otherwise be pinged by their own typing, because
  /// [mentions] is checked before anything else.
  ///
  /// Null for an agent-authored message (no human wrote it), which leaves the
  /// mention and requester rules to decide as before.
  final String? senderUserId;

  @override
  final DateTime occurredAt;
}

/// Fired when a conversation/space is deleted.
///
/// Emitted by the messaging data layer after the space is removed. Listeners
/// (e.g. the worktree garbage collector) use it to tear down per-conversation
/// resources such as isolated repo worktrees.
///
/// [workspaceId] is required. It used to be optional "when it could not be
/// resolved before deletion", with teardown falling back to a space-id
/// lookup ACROSS workspaces — a cross-workspace scan as the failure mode of a
/// missing argument. Both publishers always had the workspace in hand
/// (`deleteSpace(workspaceId, spaceId)`; `ctx.workspaceId` in the RPC op),
/// so the fallback existed only because the parameter let them omit it.
class SpaceDeleted implements DomainEvent {
  /// Creates a [SpaceDeleted] event.
  const SpaceDeleted({
    required this.spaceId,
    required this.occurredAt,
    required this.workspaceId,
  });

  /// The deleted space's id.
  final String spaceId;

  /// Owning workspace.
  final String workspaceId;

  @override
  final DateTime occurredAt;
}

/// Fired when a new conversation/space is created.
///
/// Emitted by the messaging service after the space row is committed (the
/// single chokepoint for both desktop-embedded and RPC paths). Listeners use it
/// to kick off background provisioning of the conversation workspace (repo
/// worktrees + per-agent overlay + derived `.mcp.json`) so the first agent turn
/// doesn't pay the setup cost and the UI can reflect a "preparing" state.
class SpaceCreated implements DomainEvent {
  /// Creates a [SpaceCreated] event.
  const SpaceCreated({
    required this.spaceId,
    required this.occurredAt,
    required this.workspaceId,
  });

  /// The created space's id.
  final String spaceId;

  /// Owning workspace. Required: a space is always created inside one, and
  /// the provisioning listener needs it to resolve the repos to prepare.
  final String workspaceId;

  @override
  final DateTime occurredAt;
}

/// Fired as a space's conversation workspace is provisioned: on entry, on each
/// granular step (cloning a repo, checking out a PR, setting up an agent) and on
/// the terminal ready/failed flip.
///
/// The same state is written to the space row — that is what the desktop's
/// "Cloning …" banner reads — but a chat client is not watching a row. The chat
/// bridge listens here so a reader in Slack sees what a fresh space is doing
/// instead of silence for the minutes a first clone can take.
class SpaceProvisioningChanged implements DomainEvent {
  /// Creates a [SpaceProvisioningChanged] event.
  const SpaceProvisioningChanged({
    required this.workspaceId,
    required this.spaceId,
    required this.status,
    required this.occurredAt,
    this.step,
  });

  /// Owning workspace of the space being provisioned.
  final String workspaceId;

  /// The space whose workspace is being provisioned.
  final String spaceId;

  /// Where provisioning stands.
  final SpaceProvisioningStatus status;

  /// The granular step in flight, when one is known. Null on entry and on the
  /// terminal flip, which clears the space's step column.
  final SpaceProvisioningStep? step;

  @override
  final DateTime occurredAt;
}
