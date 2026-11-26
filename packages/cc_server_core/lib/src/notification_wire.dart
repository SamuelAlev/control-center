// The single domain-event → `notifications/*` wire-frame mapping, shared by
// `RemoteEventForwarder` (live push to every connected client) and
// `NotificationFeedRecorder` (the durable per-workspace feed). One mapping
// guarantees a stored feed item is byte-identical to the frame a live client
// rendered, so the client-side frame mapper treats both the same.
library;

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/digest_events.dart';
import 'package:cc_domain/core/domain/events/learning_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/events/rig_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/notifications/domain/value_objects/notification_kind.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';

/// One `notifications/*` JSON-RPC frame: its method and wire params.
typedef NotificationFrame = ({String method, Map<String, dynamic> params});

/// PRD 16 §7/§15 forwarding gate: an un-mentioned human message carries no
/// notification value (mirrors the pre-multiplayer policy) — but a message
/// that resolved at least one `@mention` DOES forward, human-authored or not,
/// so the mentioned principal is pinged. The client applies the actual
/// "am I the one who should be notified" routing; this is just the gate.
///
/// An agent's message is also the ONLY "agent finished" signal: the turn's
/// stream processor publishes it after the final message is persisted and
/// broadcast. `AgentRunCompleted` is deliberately not a frame — the dispatch
/// publishes it when the process stream ends, before the turn is written, so a
/// toast keyed off it announced a reply the conversation had not rendered yet,
/// and doubled every agent turn in the feed.
NotificationFrame? messageReceivedFrame(MessageReceived event) {
  if (!event.isAgentMessage && event.mentions.isEmpty) {
    return null;
  }
  // A schedule or watch run that finished cleanly tells no one unless it
  // mentions them: a loop every 20 minutes must not ping every 20 minutes.
  if (event.quietRun && event.mentions.isEmpty) {
    return null;
  }
  return (
    method: 'notifications/message_received',
    params: {
      notificationKindKey: NotificationKind.notify.wire,
      notificationQuietKey: false,
      'space_id': event.spaceId,
      if (event.conversationId != null) 'conversation_id': event.conversationId,
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
      if (event.inAgentOnlySpace) 'agent_only_space': true,
    },
  );
}

/// THE "who is notified" rule — whether `userId` should be told about the
/// `notifications/*` frame `method` with `p`.
///
/// One server-side predicate, applied wherever a frame reaches a person: the
/// live forwarder (per session), the durable feed (per viewer) and Web Push
/// (per device). Clients render what they receive and re-derive none of it.
/// Directed frames fail closed; nobody is told about their own action.
bool notificationTargetsUser(
  String method,
  Map<String, dynamic> p,
  String userId,
) {
  final recipient = p['for_user_id'];
  if (recipient is String && recipient.isNotEmpty && recipient != userId) {
    return false;
  }
  if (method == 'notifications/message_received') {
    if (p['sender_user_id'] == userId ||
        (p['content_preview'] as String? ?? '').trim().isEmpty) {
      return false;
    }
    final mentions = p['mentions'];
    if (mentions is List && mentions.contains('user:$userId')) {
      return true;
    }
    // Agent-only spaces (by kind) reach nobody unless they mention them; this
    // also covers `ask_agent`/`send_to_agent` turns, which carry no requester.
    if (p['agent_only_space'] == true) {
      return false;
    }
    final requestedBy = p['requested_by_user_id'];
    return p['is_agent_message'] == true &&
        (requestedBy == null || requestedBy == userId);
  }
  if (method == 'notifications/ticket_assigned' &&
      p['assignee_type'] == 'user') {
    return p['assigned_agent_id'] == userId;
  }
  if (method == 'notifications/rig_control_changed' && p['held'] == true) {
    return p['controller'] != 'user:$userId';
  }
  return true;
}

/// Ticket assigned. PRD 16 §7(b): `assignee_type` lets the client tell a human
/// assignment (only ping that person) from an agent assignment (unfiltered).
NotificationFrame ticketAssignedFrame(TicketAssigned event) => (
  method: 'notifications/ticket_assigned',
  params: {
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
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
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
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
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
    'ticket_id': event.ticketId,
    if (event.fromAgentId != null) 'from_agent_id': event.fromAgentId,
    if (event.toAgentId != null) 'to_agent_id': event.toAgentId,
    'workspace_id': ?workspaceId,
  },
);

/// Pull request published.
NotificationFrame prPublishedFrame(PullRequestPublished event) => (
  method: 'notifications/pr_published',
  params: {
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
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
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
    'pr_id': event.prId,
    'agent_id': event.agentId,
    'workspace_id': event.workspaceId,
  },
);

/// The user was mentioned in a pull request.
NotificationFrame prMentionedFrame(PrMentioned event) => (
  method: 'notifications/pr_mentioned',
  params: {
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
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
    notificationKindKey: NotificationKind.review.wire,
    notificationQuietKey: false,
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
    notificationKindKey: event.ready
        ? NotificationKind.review.wire
        : NotificationKind.notify.wire,
    notificationQuietKey: false,
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
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
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
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
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
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
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
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
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
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
    'workspace_id': event.workspaceId,
    'repo_owner': event.repoOwner,
    'repo_name': event.repoName,
    'pr_number': event.prNumber,
    'pr_title': event.prTitle,
    'thread_id': event.threadId,
    'comment_id': ?event.commentId,
    'path': ?event.path,
    'line': ?event.line,
    'resolved_by_login': ?event.resolvedByLogin,
    'for_user_id': ?event.forUserId,
  },
);

/// A finished review went stale — the pull request moved on beneath it.
NotificationFrame reviewBecameStaleFrame(ReviewBecameStale event) => (
  method: 'notifications/review_stale',
  params: {
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
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
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
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
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
    'event_id': event.eventId,
    'title': event.title,
    'start_time': event.startTime.toIso8601String(),
    if (event.meetingUrl != null) 'meeting_url': event.meetingUrl,
    'workspace_id': event.workspaceId,
    'for_user_id': event.forUserId,
  },
);

/// A calendar account's OAuth token expired.
NotificationFrame calendarAuthExpiredFrame(CalendarAuthExpired event) => (
  method: 'notifications/calendar_auth_expired',
  params: {
    notificationKindKey: NotificationKind.review.wire,
    notificationQuietKey: false,
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
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
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
    notificationKindKey: NotificationKind.notify.wire,
    notificationQuietKey: false,
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
      notificationKindKey: NotificationKind.notify.wire,
      notificationQuietKey: false,
      'rig_id': event.rigId,
      'workspace_id': event.workspaceId,
      'reason': event.reason.wire,
    },
  );
}

/// An agent stopped and is waiting on a human: an approval, a question or a
/// credential. The client names the agent and says which, and links to the
/// space where the wait can be answered. `wait_id` lets the feed find the row
/// again when the wait ends. One frame per wait: a wait is announced once,
/// however long it lasts. Params:
///
/// ```json
/// {
///   "workspace_id": "ws-1",
///   "wait_id": "cf_1",
///   "kind": "approval",
///   "summary": "Push to main",
///   "space_id": "space-1",
///   "conversation_id": "conv-1",
///   "agent_id": "agent-1",
///   "agent_name": "Ada",
///   "notification_kind": "question"
/// }
/// ```
///
/// `kind` is what the agent waits for (`approval`, `question`,
/// `credential`); `notification_kind` is always `question`. The optional
/// keys are omitted when absent.
NotificationFrame agentAwaitingInputFrame(AgentAwaitingInput event) => (
  method: 'notifications/agent_awaiting_input',
  params: {
    'workspace_id': event.workspaceId,
    'wait_id': event.waitId,
    'kind': event.kind.wire,
    'summary': event.summary,
    if (event.spaceId != null) 'space_id': event.spaceId,
    if (event.conversationId != null) 'conversation_id': event.conversationId,
    if (event.agentId != null) 'agent_id': event.agentId,
    if (event.agentName != null) 'agent_name': event.agentName,
    notificationKindKey: NotificationKind.question.wire,
    notificationQuietKey: false,
  },
);

/// A durable goal reached an outcome its owner should hear about: it
/// completed, failed, was cancelled or ran out of budget
/// (`notification_kind: notify`), or it paused on a hold only a person can
/// lift (`notification_kind: review`). A pause the
/// person made themselves publishes nothing.
///
/// Directed at the person who started the goal (`for_user_id`); the feed and
/// Web Push also require that viewer to read the goal's space. Params:
///
/// ```json
/// {
///   "workspace_id": "ws-1",
///   "goal_id": "goal-1",
///   "space_id": "space-1",
///   "conversation_id": "conv-1",
///   "agent_id": "agent-1",
///   "status": "completed",
///   "hold": "needs_review",
///   "summary": "Durable /goal completed: the changelog is current.",
///   "for_user_id": "user-1",
///   "notification_kind": "notify",
///   "quiet": true
/// }
/// ```
///
/// `quiet` is true for a terminal status (an FYI) and false for a review.
/// `status` is the goal's wire status (`completed`, `failed`, `cancelled`,
/// `budget_exhausted`, or `paused` for a review). `hold` (a `GoalHold` wire
/// name), `summary` and `for_user_id` are omitted when absent.
NotificationFrame goalSettledFrame(GoalSettled event) => (
  method: 'notifications/goal_settled',
  params: {
    'workspace_id': event.workspaceId,
    'goal_id': event.goalId,
    'space_id': event.spaceId,
    'conversation_id': event.conversationId,
    'agent_id': event.agentId,
    'status': event.status.wire,
    if (event.hold != null) 'hold': event.hold!.wire,
    if (event.summary != null) 'summary': event.summary,
    if (event.requestedByUserId != null)
      'for_user_id': event.requestedByUserId,
    notificationKindKey: event.status.isTerminal
        ? NotificationKind.notify.wire
        : NotificationKind.review.wire,
    notificationQuietKey: event.status.isTerminal,
  },
);

/// Policy refused an agent action without asking a human. A DIFFERENT method
/// from [agentAwaitingInputFrame] on purpose: this is not a wait, so the bell
/// must not offer it as one and the feed must never look for its end. The
/// client renders the refusal (reason + the action that was refused) and links
/// to the space the agent was working in — informational, nothing to approve.
NotificationFrame agentActionBlockedFrame(AgentActionBlocked event) => (
  method: 'notifications/agent_action_blocked',
  params: {
    notificationKindKey: NotificationKind.review.wire,
    notificationQuietKey: false,
    'workspace_id': event.workspaceId,
    'reason': event.reason,
    'summary': event.actionSummary,
    if (event.spaceId != null) 'space_id': event.spaceId,
    if (event.agentId != null) 'agent_id': event.agentId,
    if (event.agentName != null) 'agent_name': event.agentName,
    if (event.source != null) 'source': event.source,
  },
);

/// An improvement review proposed changes for a person to accept or reject
/// (`notification_kind: review`). Directed at the person the review is for
/// (`for_user_id`: the goal's or the `/refine`'s person, omitted for a
/// bot-started goal); the feed and Web Push also require that viewer to read
/// the space. The proposals themselves are read with `improvements.get` /
/// `improvements.watchForWorkspace`. Params:
///
/// ```json
/// {
///   "workspace_id": "ws-1",
///   "space_id": "space-1",
///   "conversation_id": "conv-1",
///   "agent_id": "agent-1",
///   "goal_id": "goal-1",
///   "proposal_ids": ["p-1", "p-2"],
///   "count": 2,
///   "for_user_id": "user-1",
///   "notification_kind": "review"
/// }
/// ```
NotificationFrame improvementProposedFrame(ImprovementProposed event) => (
  method: 'notifications/improvement_proposed',
  params: {
    'workspace_id': event.workspaceId,
    'space_id': event.spaceId,
    'conversation_id': event.conversationId,
    'agent_id': event.agentId,
    'goal_id': ?event.goalId,
    'proposal_ids': event.proposalIds,
    'count': event.proposalIds.length,
    'for_user_id': ?event.requestedByUserId,
    notificationKindKey: NotificationKind.review.wire,
    notificationQuietKey: false,
  },
);

/// A pipeline run's remaining steps are held at its orchestration's cost cap
/// (`notification_kind: review`): raising the cap (`orchestration.raiseCap`)
/// resumes it. Directed at the run's requester when it
/// has one. Params:
///
/// ```json
/// {
///   "workspace_id": "ws-1",
///   "pipeline_run_id": "run-1",
///   "orchestration_id": "orch-1",
///   "space_id": "space-1",
///   "reason": "orchestration_budget",
///   "cap_micros": 5000000,
///   "spent_micros": 5120000,
///   "for_user_id": "user-1",
///   "can_raise_cap": true,
///   "notification_kind": "review"
/// }
/// ```
///
/// `space_id` and `for_user_id` are omitted when absent. A person's run is
/// told only to that person, the one viewer who may raise its cap
/// (`orchestration.raiseCap`), so it carries `can_raise_cap: true`; a bot's
/// run reaches every member who may see it and carries no `can_raise_cap`
/// (only an admin may raise it): a client reads the per-viewer
/// `can_raise_cap` of the held run (`pipeline_run.*`) instead.
NotificationFrame pipelineRunHeldFrame(PipelineRunHeld event) => (
  method: 'notifications/pipeline_run_held',
  params: {
    'workspace_id': event.workspaceId,
    'pipeline_run_id': event.pipelineRunId,
    'orchestration_id': event.orchestrationId,
    'space_id': ?event.spaceId,
    'reason': event.reason,
    'cap_micros': event.capMicros,
    'spent_micros': event.spentMicros,
    'for_user_id': ?event.requestedByUserId,
    if (event.requestedByUserId != null) 'can_raise_cap': true,
    notificationKindKey: NotificationKind.review.wire,
    notificationQuietKey: false,
  },
);

/// The end reasons of a wake rule its person is told about: it ran out of
/// time, runs or budget, or its stored row broke. A one-off that fired (its
/// run speaks for itself), a rule whose goal ended (`goal_settled` says
/// so), one cancelled by hand and one whose person left tell no one.
const Set<WakeRuleEndReason> notifiedWakeRuleEnds = {
  WakeRuleEndReason.expired,
  WakeRuleEndReason.runCap,
  WakeRuleEndReason.costCap,
  WakeRuleEndReason.invalidRow,
};

/// A wake rule (a schedule, loop or watch) ended for good
/// (`notification_kind: notify`). Directed at the person it acted for
/// (`for_user_id`); a bot's rule, and the reasons outside
/// [notifiedWakeRuleEnds], have no frame. Params:
///
/// ```json
/// {
///   "workspace_id": "ws-1",
///   "rule_id": "rule-1",
///   "space_id": "space-1",
///   "conversation_id": "conv-1",
///   "agent_id": "agent-1",
///   "reason": "run_cap",
///   "for_user_id": "user-1",
///   "notification_kind": "notify",
///   "quiet": true
/// }
/// ```
///
/// `reason` is a `WakeRuleEndReason` wire name. Always `quiet` (an FYI).
NotificationFrame? wakeRuleEndedFrame(WakeRuleEnded event) {
  final person = event.requestedByUserId;
  if (person == null ||
      person.isEmpty ||
      !notifiedWakeRuleEnds.contains(event.reason)) {
    return null;
  }
  return (
    method: 'notifications/wake_rule_ended',
    params: {
      'workspace_id': event.workspaceId,
      'rule_id': event.ruleId,
      'space_id': event.spaceId,
      'conversation_id': event.conversationId,
      'agent_id': event.agentId,
      'reason': event.reason.wire,
      'for_user_id': person,
      notificationKindKey: NotificationKind.notify.wire,
      notificationQuietKey: true,
    },
  );
}

/// The once-a-day digest of what waits for one person in one workspace
/// (`notification_kind: review`): goals that need review or an answer, held
/// wakes and improvement proposals waiting for a decision. Directed at that
/// person (`for_user_id`); sent only when something waits. Params:
///
/// ```json
/// {
///   "workspace_id": "ws-1",
///   "for_user_id": "user-1",
///   "day": "2026-11-20",
///   "count": 2,
///   "items": [
///     {
///       "type": "goal_review",
///       "id": "goal-1",
///       "summary": "Keep the changelog current",
///       "space_id": "space-1",
///       "conversation_id": "conv-1",
///       "agent_id": "agent-1"
///     },
///     {"type": "held_wake", "id": "wake-1", "summary": "…"}
///   ],
///   "notification_kind": "review"
/// }
/// ```
///
/// `type` is `goal_review`, `goal_person`, `held_wake`, `improvement` or
/// `request` (an approval or question of a run the server started; its `id`
/// is the request's, and `expires_at`, ISO-8601 UTC, is when it stops
/// waiting); an item's `space_id`, `conversation_id`, `agent_id` and
/// `expires_at` are omitted when absent. `day` is the local day in the workspace's time zone.
NotificationFrame waitingDigestFrame(WaitingDigest event) => (
  method: 'notifications/waiting_digest',
  params: {
    'workspace_id': event.workspaceId,
    'for_user_id': event.forUserId,
    'day': event.day,
    'count': event.items.length,
    'items': [
      for (final item in event.items)
        {
          'type': item.type.wire,
          'id': item.id,
          'summary': item.summary,
          'space_id': ?item.spaceId,
          'conversation_id': ?item.conversationId,
          'agent_id': ?item.agentId,
          'expires_at': ?item.expiresAt?.toUtc().toIso8601String(),
        },
    ],
    notificationKindKey: NotificationKind.review.wire,
    notificationQuietKey: false,
  },
);
