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
  Set<String> mutedRepos = const {},
  Set<String> viewerLogins = const {},
}) {
  final p = params;
  // Per-repository mute, applied here rather than in the notification service
  // because BOTH surfaces route through this function: the live toast
  // (`RpcNotificationMapper`) and the durable bell (`notificationCenterProvider`,
  // which consults no preferences of its own). Gating in the service alone
  // would silence the toast and leave the bell full of the repo just muted.
  //
  // The frame is still recorded server-side, so un-muting restores the history
  // rather than having discarded it.
  if (mutedRepos.isNotEmpty && _isMutedRepo(p, mutedRepos)) {
    return null;
  }
  // Principal routing for the author-facing PR lanes. Same shape as
  // `_ticketAssigned`: a frame addressed to someone else is dropped, and an
  // unknown on EITHER side degrades to notifying — an older server that sends
  // no `for_user_id`, or an identity still loading, must never silently
  // swallow a notification.
  final forUserId = p['for_user_id'] as String?;
  if (forUserId != null &&
      currentUserId != null &&
      forUserId != currentUserId) {
    return null;
  }
  // Nobody needs to be told what they just did. A frame whose ACTOR is the
  // operator themselves is news to everyone except them, so it is dropped
  // here — the same shape as the rig rule below ("the person who took the
  // wheel already knows they took it"), generalised to the forge lanes.
  //
  // Applied to both surfaces on purpose: an event you caused is not history
  // worth a bell row either, and the alternative (toast-only) would leave the
  // bell badge counting the operator's own merges and comments.
  if (_isSelfAuthored(p, viewerLogins)) {
    return null;
  }
  switch (method) {
    case 'notifications/pr_ready_to_merge':
      return _prReadyToMerge(p, l10n);
    case 'notifications/pr_merge_blocked':
      return _prMergeBlocked(p, l10n);
    case 'notifications/pr_approved':
      return _prApproved(p, l10n);
    case 'notifications/pr_changes_requested':
      return _prChangesRequested(p, l10n);
    case 'notifications/pr_review_dismissed':
      return _prReviewDismissed(p, l10n);
    case 'notifications/pr_checks_failed':
      return _prChecksFailed(p, l10n);
    case 'notifications/pr_checks_recovered':
      return _prChecksRecovered(p, l10n);
    case 'notifications/pr_comment_mentioned':
      return _prCommentMentioned(p, l10n);
    case 'notifications/pr_thread_replied':
      return _prThreadReplied(p, l10n);
    case 'notifications/pr_thread_resolved':
      return _prThreadResolved(p, l10n);
  }
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
    case 'notifications/review_stale':
      return _reviewStale(p, l10n);
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
    case 'notifications/rig_control_changed':
      return _rigControlChanged(p, l10n, currentUserId);
    case 'notifications/rig_reaped':
      return _rigReaped(p, l10n);
    case 'notifications/rig_closed':
      return _rigClosed(p, l10n);
  }
  return null;
}

/// Builds a workspace-scoped deep-link route, falling back to the workspace
/// picker when the originating event carries no workspace. Tapping the
/// notification navigates here, which also switches the active workspace
/// (the URL is the source of truth).
String _wsRoute(String? workspaceId, String Function(String) build) =>
    workspaceId == null ? workspaceListRoute : build(workspaceId);

/// Deep-links to a specific space when both the workspace and space are
/// known, falling back to the space list (or the workspace picker) so the
/// URL still resolves. The space id in the URL is the source of truth for
/// the open conversation.
String _spaceDeepLink(
  String? workspaceId,
  String? spaceId, {
  String? messageId,
}) {
  if (workspaceId == null) {
    return workspaceListRoute;
  }
  if (spaceId == null) {
    return spacesRoute(workspaceId);
  }
  return spaceRoute(workspaceId, spaceId, messageId: messageId);
}

/// Deep-links to the PR detail screen when the frame identifies the PR
/// (`repo_owner`/`repo_name`/`pr_number`), falling back to the PR list so a
/// partial frame from an older server still lands somewhere useful.
String _prDeepLink(
  String? workspaceId,
  Map<String, dynamic> p, {
  String? tab,
  int? commentId,
}) {
  if (workspaceId == null) {
    return workspaceListRoute;
  }
  final owner = p['repo_owner'] as String?;
  final name = p['repo_name'] as String?;
  final number = p['pr_number'] as int?;
  if (owner == null || name == null || number == null) {
    return pullRequestsRoute(workspaceId);
  }
  return pullRequestDetailRoute(
    workspaceId,
    '$owner/$name',
    number,
    tab: tab,
    commentId: commentId,
  );
}

/// Whether this frame's repository is muted.
///
/// Reads the `repo_owner`/`repo_name` pair every PR-shaped frame carries; a
/// frame without them (agent runs, meetings, tickets) is never muted by a
/// repository rule.
bool _isMutedRepo(Map<String, dynamic> p, Set<String> muted) {
  final owner = p['repo_owner'] as String?;
  final name = p['repo_name'] as String?;
  if (owner == null || name == null) {
    return false;
  }
  return muted.contains('$owner/$name'.toLowerCase());
}

/// The frame params that name the person who CAUSED the event, in the forge's
/// own vocabulary (a login, not a Control Center user id — the pollers only
/// ever learn the forge identity).
///
/// Deliberately a list of existing keys rather than one renamed `actor_login`:
/// these names are already on the wire and already in stored feed rows, so
/// renaming them would silently stop matching every notification recorded
/// before the change.
const _actorLoginKeys = <String>[
  // Who merged the pull request (`external_pr_merged`).
  'merged_by_login',
  // Who submitted the review (`pr_approved` / `pr_changes_requested` /
  // `pr_review_dismissed`).
  'approver_login',
  // Who wrote the comment (`pr_comment_mentioned` / `pr_thread_replied`).
  'author_login',
];

/// Whether this frame describes something the operator did themselves.
///
/// [viewerLogins] is the operator's account name on each connected forge,
/// lower-cased — the same "is this mine?" identity the PR list resolves
/// against. Empty (no forge connected, or connections still loading) means no
/// login can match, which degrades to notifying rather than silently dropping.
bool _isSelfAuthored(Map<String, dynamic> p, Set<String> viewerLogins) {
  if (viewerLogins.isEmpty) {
    return false;
  }
  for (final key in _actorLoginKeys) {
    final login = p[key] as String?;
    if (login != null &&
        login.isNotEmpty &&
        viewerLogins.contains(login.toLowerCase())) {
      return true;
    }
  }
  return false;
}

/// A human-readable location for a comment: `path:line` when the comment is
/// anchored in the diff, else the pull request itself.
String _commentLocation(Map<String, dynamic> p) {
  final path = p['path'] as String?;
  if (path == null || path.isEmpty) {
    final number = p['pr_number'];
    final title = p['pr_title'] as String?;
    return (title == null || title.isEmpty) ? '#$number' : title;
  }
  final line = p['line'] as int?;
  return line == null ? path : '$path:$line';
}

/// The tab a comment deep link should open.
///
/// A review comment lives in the diff; a conversation-timeline comment does
/// not exist there at all, so sending the reader to the diff would land them
/// on a file with nothing highlighted.
String _commentTab(Map<String, dynamic> p) =>
    p['is_review_comment'] == true ? 'pr.diff' : 'pr.overview';

AppNotification _prReadyToMerge(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.prMergeReadiness,
    title: l10n.notificationPrReadyToMerge,
    body: l10n.notificationPrReadyToMergeBody(p['pr_title'] as String? ?? ''),
    route: _prDeepLink(workspaceId, p),
    workspaceId: workspaceId,
  );
}

AppNotification _prMergeBlocked(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String?;
  final title = p['pr_title'] as String? ?? '';
  // `reason` is `PrBlockReason.name` on the wire. An unrecognised value (an
  // older or newer server) falls to the generic body rather than rendering an
  // enum name at the operator.
  final body = switch (p['reason'] as String?) {
    'conflicts' => l10n.notificationPrMergeBlockedBodyConflicts(title),
    'behind' => l10n.notificationPrMergeBlockedBodyBehind(title),
    'reviewsOutstanding' => l10n.notificationPrMergeBlockedBodyReviews(title),
    'changesRequested' => l10n.notificationPrMergeBlockedBodyChanges(title),
    'checksFailing' => l10n.notificationPrMergeBlockedBodyChecks(title),
    _ => l10n.notificationPrMergeBlockedBodyOther(title),
  };
  return AppNotification(
    category: NotificationCategory.prMergeReadiness,
    title: l10n.notificationPrMergeBlocked,
    body: body,
    route: _prDeepLink(workspaceId, p),
    workspaceId: workspaceId,
  );
}

AppNotification _prApproved(Map<String, dynamic> p, AppLocalizations l10n) {
  final workspaceId = p['workspace_id'] as String?;
  final title = p['pr_title'] as String? ?? '';
  final approver = p['approver_login'] as String?;
  final remaining = p['reviewers_remaining'] as int? ?? 0;
  // Two halves joined here rather than as six ARB permutations: who approved
  // (or that it was approved at all) and how many are still out.
  final who = (approver == null || approver.isEmpty)
      ? l10n.notificationPrApprovedBody(title)
      : l10n.notificationPrApprovedBodyBy(approver, title);
  return AppNotification(
    category: NotificationCategory.prReviewDecision,
    title: l10n.notificationPrApproved,
    body: '$who — ${l10n.notificationPrReviewersRemaining(remaining)}',
    route: _prDeepLink(workspaceId, p),
    workspaceId: workspaceId,
  );
}

AppNotification _prChangesRequested(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String?;
  final title = p['pr_title'] as String? ?? '';
  final who = p['approver_login'] as String?;
  return AppNotification(
    category: NotificationCategory.prReviewDecision,
    title: l10n.notificationPrChangesRequested,
    body: (who == null || who.isEmpty)
        ? l10n.notificationPrChangesRequestedBody(title)
        : l10n.notificationPrChangesRequestedBodyBy(who, title),
    route: _prDeepLink(workspaceId, p),
    workspaceId: workspaceId,
  );
}

AppNotification _prReviewDismissed(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.prReviewDecision,
    title: l10n.notificationPrReviewDismissed,
    body: l10n.notificationPrReviewDismissedBody(
      p['pr_title'] as String? ?? '',
    ),
    route: _prDeepLink(workspaceId, p),
    workspaceId: workspaceId,
  );
}

AppNotification _prChecksFailed(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String?;
  final title = p['pr_title'] as String? ?? '';
  final check = p['check_name'] as String?;
  return AppNotification(
    category: NotificationCategory.prChecksStatus,
    title: l10n.notificationPrChecksFailed,
    body: (check == null || check.isEmpty)
        ? l10n.notificationPrChecksFailedBodyUnnamed(title)
        : l10n.notificationPrChecksFailedBody(check, title),
    // The checks tab, not the diff: the operator's next action is reading the
    // failing run, not the code.
    route: _prDeepLink(workspaceId, p, tab: 'pr.actions'),
    workspaceId: workspaceId,
  );
}

AppNotification _prChecksRecovered(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.prChecksStatus,
    title: l10n.notificationPrChecksRecovered,
    body: l10n.notificationPrChecksRecoveredBody(
      p['pr_title'] as String? ?? '',
    ),
    route: _prDeepLink(workspaceId, p, tab: 'pr.actions'),
    workspaceId: workspaceId,
  );
}

/// A mention resolved down to the comment carrying it.
///
/// Renders as [NotificationCategory.prMentioned] — the same category as the
/// coarse PR-level mention — because it is the same concern to the operator
/// and a second toggle would only invite muting the wrong one. What it adds is
/// the location in the body and the comment anchor on the route.
AppNotification _prCommentMentioned(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.prMentioned,
    title: l10n.notificationPrMentioned,
    body: l10n.notificationPrMentionedInCommentBody(
      p['author_login'] as String? ?? '',
      _commentLocation(p),
    ),
    route: _prDeepLink(
      workspaceId,
      p,
      tab: _commentTab(p),
      commentId: p['comment_id'] as int?,
    ),
    workspaceId: workspaceId,
  );
}

AppNotification _prThreadReplied(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.prThreadActivity,
    title: l10n.notificationPrThreadReplied,
    body: l10n.notificationPrThreadRepliedBody(
      p['author_login'] as String? ?? '',
      _commentLocation(p),
    ),
    route: _prDeepLink(
      workspaceId,
      p,
      tab: 'pr.diff',
      commentId: p['comment_id'] as int?,
    ),
    workspaceId: workspaceId,
  );
}

AppNotification _prThreadResolved(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.prThreadActivity,
    title: l10n.notificationPrThreadResolved,
    body: l10n.notificationPrThreadResolvedBody(_commentLocation(p)),
    route: _prDeepLink(
      workspaceId,
      p,
      tab: 'pr.diff',
      commentId: p['comment_id'] as int?,
    ),
    workspaceId: workspaceId,
  );
}

AppNotification? _agentRunCompleted(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final conversationId = p['conversation_id'] as String?;
  if (conversationId == null) {
    return null;
  }
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.agentRunCompleted,
    title: l10n.notificationAgentFinished,
    body: l10n.runCompleted,
    route: _spaceDeepLink(workspaceId, conversationId),
    workspaceId: workspaceId,
    spaceId: conversationId,
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

/// PRD 16 §7 routing — a shared space must ping the RESPONSIBLE
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
  final spaceId = p['space_id'] as String?;
  final isAgentMessage = p['is_agent_message'] as bool? ?? true;
  // My own message, before anything else — including the mention rule, which
  // would otherwise ping someone for `@`-mentioning themselves. An older
  // server sends no `sender_user_id` and an unresolved identity is null; both
  // fall through to the rules below rather than dropping anything.
  final senderUserId = p['sender_user_id'] as String?;
  if (senderUserId != null && me != null && senderUserId == me) {
    return null;
  }
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
    route: _spaceDeepLink(
      workspaceId,
      spaceId,
      messageId: p['message_id'] as String?,
    ),
    workspaceId: workspaceId,
    spaceId: spaceId,
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

AppNotification _externalPrMerged(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
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

AppNotification _prReviewRequested(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
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

/// A finished review no longer describes the pull request beneath it.
///
/// Centre-only, deliberately. A banner is reserved for something time-critical
/// AND directly actionable; a stale review is neither — the code is not on
/// fire, and re-reviewing is a choice the person makes when they next look at
/// the PR. Interrupting them for it would spend the banner's credibility on
/// the wrong thing.
AppNotification _reviewStale(Map<String, dynamic> p, AppLocalizations l10n) {
  final workspaceId = p['workspace_id'] as String?;
  final prNumber = p['pr_number'];
  return AppNotification(
    category: NotificationCategory.reviewStale,
    title: l10n.reviewStaleNotificationTitle(
      prNumber is int ? prNumber : int.tryParse('$prNumber') ?? 0,
    ),
    body: l10n.reviewStaleNotificationBody('${p['pr_title']}'),
    route: _prDeepLink(workspaceId, p),
    workspaceId: workspaceId,
    presentation: NotificationPresentation.centerOnly,
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

/// PRD 16 §7 routing for enclosures: the person who took the wheel already
/// knows they took it, so the notification goes to everyone EXCEPT them.
///
/// A release carries no controller (the event does not record who let go), so
/// it is unfiltered — as is any frame from a server that predates the
/// `controller` param, or one seen before identity finishes loading. Both
/// degrade to "notify", never to a silently dropped machine event.
///
/// A rig is not a destination of its own (its live view is a TAB in the
/// space or PR it serves) and the event does not name a conversation, so the
/// deep link goes to Settings → Server → Enclosures: the running-machine list,
/// which is the one place that can answer "which machines are up right now".
AppNotification? _rigControlChanged(
  Map<String, dynamic> p,
  AppLocalizations l10n,
  String? me,
) {
  final workspaceId = p['workspace_id'] as String?;
  final controller = p['controller'] as String?;
  final held = p['held'] as bool? ?? (controller != null);
  if (held && me != null && controller == 'user:$me') {
    return null;
  }
  return AppNotification(
    category: NotificationCategory.rigStatusChanged,
    title: held ? l10n.notificationRigTakenOver : l10n.notificationRigReleased,
    body: held
        ? l10n.notificationRigTakenOverBody
        : l10n.notificationRigReleasedBody,
    route: _wsRoute(workspaceId, settingsRigsRoute),
    workspaceId: workspaceId,
  );
}

AppNotification _rigReaped(Map<String, dynamic> p, AppLocalizations l10n) {
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.rigStatusChanged,
    title: l10n.notificationRigReclaimed,
    body: p['reason'] == 'ttlExpired'
        ? l10n.notificationRigReclaimedBodyTtl
        : l10n.notificationRigReclaimedBodyIdle,
    route: _wsRoute(workspaceId, settingsRigsRoute),
    workspaceId: workspaceId,
  );
}

AppNotification _rigClosed(Map<String, dynamic> p, AppLocalizations l10n) {
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.rigStatusChanged,
    title: l10n.notificationRigFailed,
    body: l10n.notificationRigFailedBody,
    route: _wsRoute(workspaceId, settingsRigsRoute),
    workspaceId: workspaceId,
  );
}

/// Turns a storage status string into a readable label for display:
/// "inProgress" → "In progress", "in_review" → "In review", "open" → "Open".
String _humanizeStatus(String storage) {
  if (storage.isEmpty) {
    return storage;
  }
  final words = storage
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .trim()
      .toLowerCase();
  if (words.isEmpty) {
    return storage;
  }
  return words[0].toUpperCase() + words.substring(1);
}
