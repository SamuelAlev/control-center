// The single domain-event → `notifications/*` wire-frame mapping, shared by
// `RemoteEventForwarder` (live push to every connected client) and
// `NotificationFeedRecorder` (the durable per-workspace feed). One mapping
// guarantees a stored feed item is byte-identical to the frame a live client
// rendered, so the client-side frame mapper treats both the same.
library;

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/events/rig_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';

/// One `notifications/*` JSON-RPC frame: its method and wire params.
typedef NotificationFrame = ({String method, Map<String, dynamic> params});

/// PRD 16 §7/§15 forwarding gate: an un-mentioned human message carries no
/// notification value (mirrors the pre-multiplayer policy) — but a message
/// that resolved at least one `@mention` DOES forward, human-authored or not,
/// so the mentioned principal is pinged. The client applies the actual
/// "am I the one who should be notified" routing; this is just the gate.
NotificationFrame? messageReceivedFrame(MessageReceived event) {
  if (!event.isAgentMessage && event.mentions.isEmpty) {
    return null;
  }
  return (
    method: 'notifications/message_received',
    params: {
      'space_id': event.spaceId,
      'message_id': event.messageId,
      'sender_name': event.senderName,
      'content_preview': event.contentPreview,
      'workspace_id': event.workspaceId,
      'is_agent_message': event.isAgentMessage,
      if (event.mentions.isNotEmpty)
        'mentions': [for (final p in event.mentions) p.wire],
      if (event.requestedByUserId != null)
        'requested_by_user_id': event.requestedByUserId,
      // Who WROTE it, so a client can drop the operator's own message. The
      // frame still ships to everyone: the author is one member, and their
      // message is exactly what the others are being told about.
      if (event.senderUserId != null) 'sender_user_id': event.senderUserId,
    },
  );
}

/// Ticket assigned. PRD 16 §7(b): `assignee_type` lets the client tell a human
/// assignment (only ping that person) from an agent assignment (unfiltered).
NotificationFrame ticketAssignedFrame(TicketAssigned event) => (
  method: 'notifications/ticket_assigned',
  params: {
    'ticket_id': event.ticketId,
    'ticket_title': event.ticketTitle,
    if (event.assignedAgentId != null)
      'assigned_agent_id': event.assignedAgentId,
    'assignee_type': event.assigneeType,
    if (event.ticketUrl != null) 'ticket_url': event.ticketUrl,
    'workspace_id': event.workspaceId,
  },
);

/// Ticket status changed. PRD 16 §7(b): carries no assignee/creator field
/// today, so it keeps the pre-multiplayer unfiltered behaviour rather than
/// guessing at a principal to scope it to.
NotificationFrame ticketStatusChangedFrame(TicketStatusChanged event) => (
  method: 'notifications/ticket_status_changed',
  params: {
    'ticket_id': event.ticketId,
    'from': event.from,
    'to': event.to,
    'workspace_id': event.workspaceId,
  },
);

/// Ticket reassigned. The event carries no workspace id; the caller resolves
/// [workspaceId] (or passes null and the client falls back accordingly).
NotificationFrame ticketReassignedFrame(
  TicketReassigned event,
  String? workspaceId,
) => (
  method: 'notifications/ticket_reassigned',
  params: {
    'ticket_id': event.ticketId,
    if (event.fromAgentId != null) 'from_agent_id': event.fromAgentId,
    if (event.toAgentId != null) 'to_agent_id': event.toAgentId,
    'workspace_id': ?workspaceId,
  },
);

/// Agent run completed. Null when the run has no conversation to link to.
NotificationFrame? agentRunCompletedFrame(AgentRunCompleted event) {
  final conversationId = event.conversationId;
  if (conversationId == null) {
    return null;
  }
  return (
    method: 'notifications/agent_run_completed',
    params: {
      'agent_id': event.agentId,
      'conversation_id': conversationId,
      'workspace_id': ?event.workspaceId,
      if (event.runId != null) 'run_id': event.runId,
    },
  );
}

/// Pull request published.
NotificationFrame prPublishedFrame(PullRequestPublished event) => (
  method: 'notifications/pr_published',
  params: {
    'pr_id': event.prId,
    'repo_owner': event.repoOwner,
    'repo_name': event.repoName,
    'workspace_id': event.workspaceId,
  },
);

/// Pull request merged.
NotificationFrame prMergedFrame(PrMerged event) => (
  method: 'notifications/pr_merged',
  params: {
    'pr_id': event.prId,
    'agent_id': event.agentId,
    'workspace_id': event.workspaceId,
  },
);

/// The user was mentioned in a pull request.
NotificationFrame prMentionedFrame(PrMentioned event) => (
  method: 'notifications/pr_mentioned',
  params: {
    'repo_owner': event.repoOwner,
    'repo_name': event.repoName,
    'pr_number': event.prNumber,
    'pr_title': event.prTitle,
    'workspace_id': event.workspaceId,
  },
);

/// The user's review was requested on a pull request.
NotificationFrame prReviewRequestedFrame(PrReviewRequested event) => (
  method: 'notifications/pr_review_requested',
  params: {
    'repo_owner': event.repoOwner,
    'repo_name': event.repoName,
    'pr_number': event.prNumber,
    'pr_title': event.prTitle,
    'workspace_id': event.workspaceId,
  },
);

/// A pull request the operator authored became mergeable, or stopped being.
///
/// Two methods off one event because the two edges read as opposite news and
/// the client renders them with different copy and colour — but ONE category
/// (`prMergeReadiness`), so muting is all-or-nothing.
NotificationFrame prMergeReadinessFrame(PrMergeReadinessChanged event) => (
  method: event.ready
      ? 'notifications/pr_ready_to_merge'
      : 'notifications/pr_merge_blocked',
  params: {
    'workspace_id': event.workspaceId,
    'repo_owner': event.repoOwner,
    'repo_name': event.repoName,
    'pr_number': event.prNumber,
    'pr_title': event.prTitle,
    'reason': event.reason,
    'for_user_id': ?event.forUserId,
  },
);

/// A reviewer decided on a pull request the operator authored.
NotificationFrame prReviewDecisionFrame(PrReviewDecisionChanged event) => (
  method: switch (event.decision) {
    'changesRequested' => 'notifications/pr_changes_requested',
    'dismissed' => 'notifications/pr_review_dismissed',
    _ => 'notifications/pr_approved',
  },
  params: {
    'workspace_id': event.workspaceId,
    'repo_owner': event.repoOwner,
    'repo_name': event.repoName,
    'pr_number': event.prNumber,
    'pr_title': event.prTitle,
    'reviewers_remaining': event.reviewersRemaining,
    'approver_login': ?event.approverLogin,
    'for_user_id': ?event.forUserId,
  },
);

/// CI on a pull request the operator authored went red, or recovered.
NotificationFrame prChecksStatusFrame(PrChecksStatusChanged event) => (
  method: event.failing
      ? 'notifications/pr_checks_failed'
      : 'notifications/pr_checks_recovered',
  params: {
    'workspace_id': event.workspaceId,
    'repo_owner': event.repoOwner,
    'repo_name': event.repoName,
    'pr_number': event.prNumber,
    'pr_title': event.prTitle,
    'check_name': ?event.failingCheckName,
    'check_url': ?event.failingCheckUrl,
    'for_user_id': ?event.forUserId,
  },
);

/// The operator was @mentioned in a specific comment.
///
/// Carries the comment anchor so the client's route can land on the comment
/// itself rather than the top of the pull request.
NotificationFrame prCommentMentionedFrame(PrCommentMentioned event) => (
  method: 'notifications/pr_comment_mentioned',
  params: {
    'workspace_id': event.workspaceId,
    'repo_owner': event.repoOwner,
    'repo_name': event.repoName,
    'pr_number': event.prNumber,
    'pr_title': event.prTitle,
    'comment_id': event.commentId,
    'author_login': event.authorLogin,
    'body_preview': event.bodyPreview,
    'is_review_comment': event.isReviewComment,
    'thread_id': ?event.threadId,
    'path': ?event.path,
    'line': ?event.line,
    'for_user_id': ?event.forUserId,
  },
);

/// Someone replied in a review thread the operator is in.
NotificationFrame prThreadRepliedFrame(PrThreadReplied event) => (
  method: 'notifications/pr_thread_replied',
  params: {
    'workspace_id': event.workspaceId,
    'repo_owner': event.repoOwner,
    'repo_name': event.repoName,
    'pr_number': event.prNumber,
    'pr_title': event.prTitle,
    'comment_id': event.commentId,
    'author_login': event.authorLogin,
    'body_preview': event.bodyPreview,
    'thread_id': ?event.threadId,
    'path': ?event.path,
    'line': ?event.line,
    'for_user_id': ?event.forUserId,
  },
);

/// A review thread the operator is in was resolved.
NotificationFrame prThreadResolvedFrame(PrThreadResolved event) => (
  method: 'notifications/pr_thread_resolved',
  params: {
    'workspace_id': event.workspaceId,
    'repo_owner': event.repoOwner,
    'repo_name': event.repoName,
    'pr_number': event.prNumber,
    'pr_title': event.prTitle,
    'thread_id': event.threadId,
    'comment_id': ?event.commentId,
    'path': ?event.path,
    'line': ?event.line,
    'for_user_id': ?event.forUserId,
  },
);

/// A finished review went stale — the pull request moved on beneath it.
NotificationFrame reviewBecameStaleFrame(ReviewBecameStale event) => (
  method: 'notifications/review_stale',
  params: {
    'workspace_id': event.workspaceId,
    'space_id': event.spaceId,
    'repo_owner': event.repoOwner,
    'repo_name': event.repoName,
    'pr_number': event.prNumber,
    'pr_title': event.prTitle,
    'reviewed_head_sha': event.reviewedHeadSha,
    'head_sha': event.headSha,
  },
);

/// An externally-tracked pull request merged.
///
/// Carries the merger's forge login so the client can apply the same rule the
/// rig lane does: the person who merged it already knows they merged it. The
/// filtering is deliberately theirs and not ours — this frame reaches every
/// member of the workspace, and one member's merge is still news to the rest.
NotificationFrame externalPrMergedFrame(ExternalPrMerged event) => (
  method: 'notifications/external_pr_merged',
  params: {
    'workspace_id': event.workspaceId,
    'repo_owner': event.repoOwner,
    'repo_name': event.repoName,
    'pr_number': event.prNumber,
    'pr_title': event.prTitle,
    'merged_by_login': ?event.mergedByLogin,
  },
);

/// A calendar meeting starts within the lead window.
NotificationFrame meetingStartingSoonFrame(MeetingStartingSoon event) => (
  method: 'notifications/meeting_starting_soon',
  params: {
    'event_id': event.eventId,
    'title': event.title,
    'start_time': event.startTime.toIso8601String(),
    if (event.meetingUrl != null) 'meeting_url': event.meetingUrl,
    'workspace_id': event.workspaceId,
  },
);

/// A calendar account's OAuth token expired.
NotificationFrame calendarAuthExpiredFrame(CalendarAuthExpired event) => (
  method: 'notifications/calendar_auth_expired',
  params: {
    'account_email': event.accountEmail,
    'workspace_id': event.workspaceId,
  },
);

/// A human took exclusive control of a rig, or gave it back.
///
/// Carries the controller's wire principal so the client can apply the PRD 16
/// §7 rule: the person who took the wheel is not told they took the wheel. A
/// RELEASE carries no controller — the event does not record who let go — so
/// it reaches everyone who can see the workspace.
NotificationFrame rigControlChangedFrame(RigControlChanged event) => (
  method: 'notifications/rig_control_changed',
  params: {
    'rig_id': event.rigId,
    'workspace_id': event.workspaceId,
    'held': event.controller != null,
    if (event.controller != null) 'controller': event.controller!.wire,
  },
);

/// The system reclaimed a rig (idle, TTL, or memory-pressure eviction).
///
/// Distinct from a close somebody asked for: a machine that went away on its
/// own is the case where the operator needs to be told, because nothing they
/// did explains it.
NotificationFrame rigReapedFrame(RigReaped event) => (
  method: 'notifications/rig_reaped',
  params: {
    'rig_id': event.rigId,
    'workspace_id': event.workspaceId,
    'reason': event.reason.wire,
    if (event.agentId != null) 'agent_id': event.agentId,
  },
);

/// A rig closed — forwarded only when the close was NOT expected.
///
/// Null for every reason that is already accounted for:
/// [RigCloseReason.requested] (somebody asked), [RigCloseReason.serverShutdown]
/// (everything is going away), [RigCloseReason.conversationEnded] /
/// [RigCloseReason.workspaceGone] (the work the rig served no longer exists),
/// and the idle/TTL pair — which `RigService` always publishes ALONGSIDE a
/// [RigReaped] carrying the same reason plus the driving agent, so forwarding
/// both would double every reap. What survives is
/// [RigCloseReason.backendFailure]: the machine died under the agent, and
/// nothing the operator did explains it.
NotificationFrame? rigClosedFrame(RigClosedEvent event) {
  if (event.reason != RigCloseReason.backendFailure) {
    return null;
  }
  return (
    method: 'notifications/rig_closed',
    params: {
      'rig_id': event.rigId,
      'workspace_id': event.workspaceId,
      'reason': event.reason.wire,
    },
  );
}
