// The pure `notifications/*` frame → [AppNotification] mapping, shared by the
// live toast path (`RpcNotificationMapper`, rendering frames as the server
// pushes them) and the durable notification center (rendering the same frames
// back out of the server-side per-workspace feed). Keeping ONE mapping is what
// guarantees the bell's history and the toasts agree on titles, deep links,
// and — critically — the PRD 16 §7 principal routing rules: a frame that would
// not have pinged this user live must not surface in their bell either.
library;

import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';

/// Maps one pushed/stored `notifications/*` frame to the [AppNotification] it
/// renders as, or null when the frame is not renderable — an unknown method
/// (task-lifecycle frames are pushed but never rendered as notifications), a
/// frame missing its identifying params, or one the PRD 16 §7 routing rules
/// suppress for [currentUserId].
///
/// Pure: no workspace filtering (callers scope to their surface — the live
/// path filters to the active workspace, the feed is per-workspace by
/// construction) and no side effects. [currentUserId] null (identity not
/// wired or still loading) degrades every routing rule to its
/// pre-multiplayer fallback — never a silently dropped notification.
AppNotification? mapNotificationFrame(
  String method,
  Map<String, dynamic> params, {
  required AppLocalizations l10n,
  String? currentUserId,
}) {
  final p = params;
  switch (method) {
    case 'notifications/agent_run_completed':
      return _agentRunCompleted(p, l10n);
    case 'notifications/pr_published':
      return _prPublished(p, l10n);
    case 'notifications/pr_merged':
      return _prMerged(p, l10n);
    case 'notifications/message_received':
      return _messageReceived(p, currentUserId);
    case 'notifications/pr_mentioned':
      return _prMentioned(p, l10n);
    case 'notifications/pr_review_requested':
      return _prReviewRequested(p, l10n);
    case 'notifications/external_pr_merged':
      return _externalPrMerged(p, l10n);
    case 'notifications/ticket_assigned':
      return _ticketAssigned(p, l10n, currentUserId);
    case 'notifications/ticket_status_changed':
      return _ticketStatusChanged(p, l10n);
    case 'notifications/meeting_starting_soon':
      return _meetingStartingSoon(p, l10n);
    case 'notifications/calendar_auth_expired':
      return _calendarAuthExpired(p, l10n);
  }
  return null;
}

/// Builds a workspace-scoped deep-link route, falling back to the workspace
/// picker when the originating event carries no workspace. Tapping the
/// notification navigates here, which also switches the active workspace
/// (the URL is the source of truth).
String _wsRoute(String? workspaceId, String Function(String) build) =>
    workspaceId == null ? workspaceListRoute : build(workspaceId);

/// Deep-links to a specific channel when both the workspace and channel are
/// known, falling back to the channel list (or the workspace picker) so the
/// URL still resolves. The channel id in the URL is the source of truth for
/// the open conversation.
String _channelDeepLink(
  String? workspaceId,
  String? channelId, {
  String? messageId,
}) {
  if (workspaceId == null) {
    return workspaceListRoute;
  }
  if (channelId == null) {
    return channelsRoute(workspaceId);
  }
  return channelRoute(workspaceId, channelId, messageId: messageId);
}

/// Deep-links to the PR detail screen when the frame identifies the PR
/// (`repo_owner`/`repo_name`/`pr_number`), falling back to the PR list so a
/// partial frame from an older server still lands somewhere useful.
String _prDeepLink(String? workspaceId, Map<String, dynamic> p) {
  if (workspaceId == null) {
    return workspaceListRoute;
  }
  final owner = p['repo_owner'] as String?;
  final name = p['repo_name'] as String?;
  final number = p['pr_number'] as int?;
  if (owner == null || name == null || number == null) {
    return pullRequestsRoute(workspaceId);
  }
  return pullRequestDetailRoute(workspaceId, '$owner/$name', number);
}

AppNotification? _agentRunCompleted(Map<String, dynamic> p, AppLocalizations l10n) {
  final conversationId = p['conversation_id'] as String?;
  if (conversationId == null) {
    return null;
  }
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.agentRunCompleted,
    title: l10n.notificationAgentFinished,
    body: l10n.runCompleted,
    route: _channelDeepLink(workspaceId, conversationId),
    workspaceId: workspaceId,
    channelId: conversationId,
  );
}

AppNotification _prPublished(Map<String, dynamic> p, AppLocalizations l10n) {
  final workspaceId = p['workspace_id'] as String;
  return AppNotification(
    category: NotificationCategory.pullRequestPublished,
    title: l10n.notificationPrPublished,
    body: '${p['repo_owner']}/${p['repo_name']}',
    route: _wsRoute(workspaceId, pullRequestsRoute),
    workspaceId: workspaceId,
  );
}

AppNotification _prMerged(Map<String, dynamic> p, AppLocalizations l10n) {
  final workspaceId = p['workspace_id'] as String;
  return AppNotification(
    category: NotificationCategory.prMerged,
    title: l10n.notificationPrMerged,
    body: l10n.prMergedBody,
    route: _wsRoute(workspaceId, pullRequestsRoute),
    workspaceId: workspaceId,
  );
}

/// PRD 16 §7 routing — a shared channel must ping the RESPONSIBLE
/// principal(s), not everyone in it:
///
///  1. Explicitly `@mentioned` (human or agent mention roster, PRD 16 §15)
///     → always notify, whoever authored the message.
///  2. Otherwise, the pre-multiplayer behaviour: only an agent's completed
///     turn notifies (a human's own un-mentioned message never pings
///     anyone — the forwarder does not even push those frames) — UNLESS
///     the frame names the human who requested that run
///     (`requested_by_user_id`) and it names someone OTHER than me, in
///     which case it is THEIR run finishing, not mine, so it is suppressed.
///
/// A frame from a server that predates this routing (or before identity
/// finishes loading) carries neither `mentions` nor a resolvable
/// `currentUserId` — both checks degrade to "notify", never silently
/// dropping a real notification because identity is unknown.
AppNotification? _messageReceived(Map<String, dynamic> p, String? me) {
  final workspaceId = p['workspace_id'] as String?;
  final channelId = p['channel_id'] as String?;
  final isAgentMessage = p['is_agent_message'] as bool? ?? true;
  final mentionWires =
      (p['mentions'] as List?)?.whereType<String>().toList() ??
      const <String>[];

  final iAmMentioned = me != null && mentionWires.contains('user:$me');
  if (!iAmMentioned) {
    if (!isAgentMessage) {
      return null;
    }
    final requestedBy = p['requested_by_user_id'] as String?;
    if (requestedBy != null && me != null && requestedBy != me) {
      return null;
    }
  }
  // A body-less message notification is noise: the bell renders the body as
  // its subtitle, so an empty preview reads as a bare sender name with a blank
  // line under it. The server already suppresses these at the source; this is
  // the matching client-side floor for older servers.
  final body = (p['content_preview'] as String? ?? '').trim();
  if (body.isEmpty) {
    return null;
  }
  return AppNotification(
    category: NotificationCategory.newMessage,
    title: p['sender_name'] as String? ?? '',
    body: body,
    route: _channelDeepLink(
      workspaceId,
      channelId,
      messageId: p['message_id'] as String?,
    ),
    workspaceId: workspaceId,
    channelId: channelId,
  );
}

AppNotification _prMentioned(Map<String, dynamic> p, AppLocalizations l10n) {
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.prMentioned,
    title: l10n.notificationPrMentioned,
    body:
        '${p['pr_title']} '
        '(${p['repo_owner']}/${p['repo_name']}#${p['pr_number']})',
    route: _prDeepLink(workspaceId, p),
    workspaceId: workspaceId,
  );
}

AppNotification _externalPrMerged(Map<String, dynamic> p, AppLocalizations l10n) {
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.prMerged,
    title: l10n.notificationPrMerged,
    body:
        '${p['pr_title']} '
        '(${p['repo_owner']}/${p['repo_name']}#${p['pr_number']})',
    route: _prDeepLink(workspaceId, p),
    workspaceId: workspaceId,
  );
}

AppNotification _prReviewRequested(Map<String, dynamic> p, AppLocalizations l10n) {
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.reviewRequested,
    title: l10n.notificationReviewRequested,
    body:
        '${p['pr_title']} '
        '(${p['repo_owner']}/${p['repo_name']}#${p['pr_number']})',
    route: _prDeepLink(workspaceId, p),
    workspaceId: workspaceId,
  );
}

/// PRD 16 §7(b): when the ticket is assigned to a human
/// (`assignee_type == 'user'`) and that assignee is known, only the actual
/// assignee is pinged — assigning a ticket to a teammate must not ping the
/// whole workspace. An agent assignment (or an older frame with no
/// `assignee_type`) keeps today's unfiltered behaviour.
AppNotification? _ticketAssigned(
  Map<String, dynamic> p,
  AppLocalizations l10n,
  String? me,
) {
  final assigneeType = p['assignee_type'] as String?;
  final assignedId = p['assigned_agent_id'] as String?;
  if (assigneeType == 'user' &&
      assignedId != null &&
      me != null &&
      assignedId != me) {
    return null;
  }
  final workspaceId = p['workspace_id'] as String?;
  final ticketId = p['ticket_id'] as String;
  return AppNotification(
    category: NotificationCategory.ticketAssigned,
    title: l10n.notificationTicketAssigned,
    body: p['ticket_title'] as String? ?? '',
    route: _wsRoute(workspaceId, (w) => ticketDetailRoute(w, ticketId)),
    workspaceId: workspaceId,
  );
}

AppNotification _ticketStatusChanged(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String?;
  final ticketId = p['ticket_id'] as String;
  return AppNotification(
    category: NotificationCategory.ticketStatusChanged,
    title: l10n.notificationTicketStatusChanged,
    body:
        '${_humanizeStatus(p['from'] as String? ?? '')} → '
        '${_humanizeStatus(p['to'] as String? ?? '')}',
    route: _wsRoute(workspaceId, (w) => ticketDetailRoute(w, ticketId)),
    workspaceId: workspaceId,
  );
}

AppNotification _meetingStartingSoon(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String;
  final eventId = p['event_id'] as String;
  return AppNotification(
    category: NotificationCategory.meetingStartsSoon,
    title: l10n.notificationMeetingStartsSoon,
    body: p['title'] as String? ?? '',
    // Opens the event detail, where the "Start recording & link" action lives.
    route: _wsRoute(workspaceId, (w) => calendarDetailRoute(w, eventId)),
    workspaceId: workspaceId,
    // Time-critical + actionable → earns the ambient banner rail (PRD 25 §1).
    presentation: NotificationPresentation.banner,
  );
}

AppNotification _calendarAuthExpired(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String;
  final accountEmail = p['account_email'] as String? ?? '';
  return AppNotification(
    category: NotificationCategory.calendarAuthExpired,
    title: l10n.notificationCalendarAuthExpiredTitle,
    // Opens the calendar, where the reconnect banner offers a one-click fix.
    body: accountEmail.isEmpty
        ? l10n.notificationCalendarAuthExpiredBodyNoEmail
        : l10n.notificationCalendarAuthExpiredBody(accountEmail),
    route: _wsRoute(workspaceId, calendarRoute),
    workspaceId: workspaceId,
    // Time-critical + actionable (sync is broken until reconnect) → banner.
    presentation: NotificationPresentation.banner,
  );
}

/// Turns a storage status string into a readable label for display:
/// "inProgress" → "In progress", "in_review" → "In review", "open" → "Open".
String _humanizeStatus(String storage) {
  if (storage.isEmpty) {
    return storage;
  }
  final words = storage
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (m) => '${m[1]} ${m[2]}',
      )
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .trim()
      .toLowerCase();
  if (words.isEmpty) {
    return storage;
  }
  return words[0].toUpperCase() + words.substring(1);
}
