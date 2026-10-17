import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';

String activityTitle(NotificationFeedItem item, AppLocalizations l) {
  final method = item.method;
  if (method == 'notifications/agent_awaiting_input') {
    return l.activityAgentWaiting;
  }
  if (method == 'notifications/agent_action_blocked') {
    return l.activityAgentBlocked;
  }
  if (method == 'notifications/message_received') {
    final sender = item.params['sender_name'];
    return sender is String && sender.isNotEmpty ? sender : l.activityMessage;
  }
  if (method == 'notifications/pr_ready_to_merge') return l.activityPrReady;
  if (method == 'notifications/pr_merge_blocked') return l.activityPrBlocked;
  if (method == 'notifications/pr_approved') return l.activityPrApproved;
  if (method == 'notifications/pr_changes_requested') {
    return l.activityPrChanges;
  }
  if (method == 'notifications/pr_checks_failed') {
    return l.activityPrChecksFailed;
  }
  if (method == 'notifications/pr_checks_recovered') {
    return l.activityPrChecksRecovered;
  }
  if (method == 'notifications/pr_comment_mentioned' ||
      method == 'notifications/pr_thread_replied') {
    return l.activityPrComment;
  }
  if (method == 'notifications/pr_published') return l.activityPrPublished;
  if (method == 'notifications/pr_merged' ||
      method == 'notifications/external_pr_merged') {
    return l.activityPrMerged;
  }
  if (method == 'notifications/pr_mentioned') return l.activityPrMentioned;
  if (method == 'notifications/pr_review_requested') {
    return l.activityPrReviewRequested;
  }
  if (method == 'notifications/review_stale') return l.activityPrReviewStale;
  if (method == 'notifications/ticket_assigned') {
    return l.activityTicketAssigned;
  }
  if (method == 'notifications/ticket_status_changed') {
    return l.activityTicketChanged;
  }
  if (method == 'notifications/meeting_starting_soon') {
    return l.activityMeetingSoon;
  }
  if (method == 'notifications/calendar_auth_expired') {
    return l.activityCalendarExpired;
  }
  if (method == 'notifications/rig_control_changed') {
    return l.activityRigControl;
  }
  if (method == 'notifications/rig_reaped' ||
      method == 'notifications/rig_closed') {
    return l.activityRigClosed;
  }
  if (method.startsWith('notifications/pr_')) return l.activityPullRequest;
  if (method.startsWith('notifications/rig_')) return l.activityRig;
  return l.activityEvent;
}

String activityBody(NotificationFeedItem item) {
  final p = item.params;
  for (final key in [
    'body',
    'detail',
    'reason',
    'pr_title',
    'ticket_title',
    'title',
    'content_preview',
    'summary',
    'action',
  ]) {
    final text = p[key];
    if (text is String && text.trim().isNotEmpty) return text;
  }
  final owner = p['repo_owner'];
  final repo = p['repo_name'];
  final number = p['pr_number'];
  if (owner is String && repo is String && number != null) {
    return '$owner/$repo #$number';
  }
  return '';
}

String? activityDestination(NotificationFeedItem item, List<Repo> repos) {
  final p = item.params;
  final ws = item.workspaceId;
  final space = p['space_id'];
  if (space is String && space.isNotEmpty) {
    return remoteSpaceLocation(
      workspaceId: ws,
      spaceId: space,
      conversationId: p['conversation_id'] as String?,
      messageId: p['message_id'] as String?,
    );
  }
  final owner = p['repo_owner'];
  final repoName = p['repo_name'];
  final number = p['pr_number'];
  if (owner is String && repoName is String && number is num) {
    for (final repo in repos) {
      if (repo.remoteOwner.toLowerCase() == owner.toLowerCase() &&
          repo.remoteName.toLowerCase() == repoName.toLowerCase()) {
        return remoteWorkspaceLocation(
          '/pr/${Uri.encodeComponent(repo.id)}/${number.toInt()}',
          ws,
        );
      }
    }
    return remoteWorkspaceLocation('/prs', ws);
  }
  final ticket = p['ticket_id'];
  if (ticket is String && ticket.isNotEmpty) {
    return remoteWorkspaceLocation(
      '/ticket/${Uri.encodeComponent(ticket)}',
      ws,
    );
  }
  final event = p['event_id'];
  if (event is String && event.isNotEmpty) {
    return remoteWorkspaceLocation('/event/${Uri.encodeComponent(event)}', ws);
  }
  if (item.method.startsWith('notifications/rig_')) {
    return remoteWorkspaceLocation('/settings', ws);
  }
  return null;
}
