// The pure `notifications/*` frame → [AppNotification] mapping, shared by the
// live toast path (`RpcNotificationMapper`, rendering frames as the server
// pushes them) and the durable notification center (rendering the same frames
// back out of the server-side per-workspace feed). Keeping ONE mapping is what
// guarantees the bell's history and the toasts agree on titles and deep links.
// The PRD 16 §7 principal routing is not here: the server applies one rule
// (`notificationTargetsUser`) to both the live frames and the feed.
library;

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/notifications/work_notification_frames.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';

/// Maps one pushed/stored `notifications/*` frame to the [AppNotification] it
/// renders as, or null when the frame is not renderable — an unknown method
/// (task-lifecycle frames are pushed but never rendered as notifications), a
/// frame missing its identifying params, a muted repository, or the
/// operator's own forge action.
///
/// Pure: no workspace filtering (callers scope to their surface — the live
/// path filters to the active workspace, the feed is per-workspace by
/// construction) and no side effects. Who a frame is FOR is the server's
/// decision; [currentUserId] only picks a message's category (mentioned vs
/// an agent's finished turn).
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
  // Principal routing ("who is notified": directed frames, message routing,
  // agent-only spaces, ticket assignees, rig controllers) is decided on the
  // server by `notificationTargetsUser`, which filters the live frames per
  // session and the feed per viewer. Nothing here re-derives it.
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
      return _ticketAssigned(p, l10n);
    case 'notifications/ticket_status_changed':
      return _ticketStatusChanged(p, l10n);
    case 'notifications/meeting_starting_soon':
      return _meetingStartingSoon(p, l10n);
    case 'notifications/calendar_auth_expired':
      return _calendarAuthExpired(p, l10n);
    case 'notifications/rig_control_changed':
      return _rigControlChanged(p, l10n);
    case 'notifications/rig_reaped':
      return _rigReaped(p, l10n);
    case 'notifications/rig_closed':
      return _rigClosed(p, l10n);
    case 'notifications/agent_awaiting_input':
      return _agentAwaitingInput(p, l10n);
    case 'notifications/agent_action_blocked':
      return _agentActionBlocked(p, l10n);
  }
  return mapWorkNotificationFrame(method, p, l10n: l10n);
}

/// Builds a workspace-scoped deep-link route, falling back to the workspace
/// picker when the originating event carries no workspace. Tapping the
/// notification navigates here, which also switches the active workspace
/// (the URL is the source of truth).
String _wsRoute(String? workspaceId, String Function(String) build) =>
    workspaceId == null ? workspaceListRoute : build(workspaceId);

/// Deep-links to a specific space when both the workspace and space are
/// known, falling back to the space list (or the workspace picker) so the
/// URL still resolves. The space id in the URL selects the space; a known
/// [conversationId] rides as `?tab=` so the tap opens THAT conversation rather
/// than the space's standing one.
String _spaceDeepLink(
  String? workspaceId,
  String? spaceId, {
  String? conversationId,
  String? messageId,
}) {
  if (workspaceId == null) {
    return workspaceListRoute;
  }
  if (spaceId == null) {
    return spacesRoute(workspaceId);
  }
  return spaceRoute(
    workspaceId,
    spaceId,
    messageId: messageId,
    tab: conversationId == null ? null : conversationTabKey(conversationId),
  );
}

/// Deep-links to the PR detail screen when the frame identifies the PR
/// (`repo_owner`/`repo_name`/`pr_number`), falling back to the PR list so a
/// partial frame still lands somewhere useful.
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
/// A list of the per-event keys rather than one shared `actor_login`: each
/// frame names its actor in that event's own terms.
const _actorLoginKeys = <String>[
  // Who merged the pull request (`external_pr_merged`).
  'merged_by_login',
  // Who submitted the review (`pr_approved` / `pr_changes_requested` /
  // `pr_review_dismissed`).
  'approver_login',
  // Who wrote the comment (`pr_comment_mentioned` / `pr_thread_replied`).
  'author_login',
  // Who resolved the review thread (`pr_thread_resolved`).
  'resolved_by_login',
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

AppNotification _prReadyToMerge(Map<String, dynamic> p, AppLocalizations l10n) {
  final workspaceId = p['workspace_id'] as String?;
  return AppNotification(
    category: NotificationCategory.prMergeReadiness,
    tone: NotificationTone.positive,
    title: l10n.notificationPrReadyToMerge,
    body: l10n.notificationPrReadyToMergeBody(p['pr_title'] as String? ?? ''),
    route: _prDeepLink(workspaceId, p),
    workspaceId: workspaceId,
  );
}

AppNotification _prMergeBlocked(Map<String, dynamic> p, AppLocalizations l10n) {
  final workspaceId = p['workspace_id'] as String?;
  final title = p['pr_title'] as String? ?? '';
  // `reason` is `PrBlockReason.name` on the wire. An unrecognised value falls
  // to the generic body rather than rendering an enum name at the operator.
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
    tone: NotificationTone.negative,
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
    tone: NotificationTone.positive,
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
    tone: NotificationTone.negative,
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
    tone: NotificationTone.neutral,
    title: l10n.notificationPrReviewDismissed,
    body: l10n.notificationPrReviewDismissedBody(
      p['pr_title'] as String? ?? '',
    ),
    route: _prDeepLink(workspaceId, p),
    workspaceId: workspaceId,
  );
}

AppNotification _prChecksFailed(Map<String, dynamic> p, AppLocalizations l10n) {
  final workspaceId = p['workspace_id'] as String?;
  final title = p['pr_title'] as String? ?? '';
  final check = p['check_name'] as String?;
  return AppNotification(
    category: NotificationCategory.prChecksStatus,
    tone: NotificationTone.negative,
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
    tone: NotificationTone.positive,
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

/// A message frame the server already routed to this user (PRD 16 §7). A
/// message that mentions [me] files under [NotificationCategory.newMessage];
/// an agent's turn — the "agent finished" signal, since the server sends no
/// separate run-completed frame — under
/// [NotificationCategory.agentRunCompleted] and obeys that toggle.
AppNotification? _messageReceived(Map<String, dynamic> p, String? me) {
  final workspaceId = p['workspace_id'] as String?;
  final spaceId = p['space_id'] as String?;
  final mentionWires =
      (p['mentions'] as List?)?.whereType<String>().toList() ??
      const <String>[];
  final iAmMentioned = me != null && mentionWires.contains('user:$me');
  final body = (p['content_preview'] as String? ?? '').trim();
  if (body.isEmpty) {
    return null;
  }
  return AppNotification(
    category: iAmMentioned
        ? NotificationCategory.newMessage
        : NotificationCategory.agentRunCompleted,
    title: p['sender_name'] as String? ?? '',
    body: body,
    route: _spaceDeepLink(
      workspaceId,
      spaceId,
      conversationId: p['conversation_id'] as String?,
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
/// whole workspace. An agent assignment (or a frame with no `assignee_type`)
/// is unfiltered.
AppNotification _ticketAssigned(Map<String, dynamic> p, AppLocalizations l10n) {
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
    // A click opens the event; the actions join or record without it.
    route: _wsRoute(workspaceId, (w) => calendarDetailRoute(w, eventId)),
    workspaceId: workspaceId,
    // Time-critical + actionable → earns the ambient banner rail (PRD 25 §1).
    presentation: NotificationPresentation.banner,
    // A meeting about to start is worth an alert even with its event open.
    suppressWhenViewingTarget: false,
    meeting: NotificationMeeting(
      workspaceId: workspaceId,
      eventId: eventId,
      meetingUrl: _meetingUrl(p['meeting_url']),
    ),
  );
}

/// The call link of a meeting frame, or null when it is missing or is not an
/// http(s) link: the value is opened in the browser, so nothing else passes.
String? _meetingUrl(Object? raw) {
  if (raw is! String) {
    return null;
  }
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      !uri.hasAuthority ||
      !const {'http', 'https'}.contains(uri.scheme)) {
    return null;
  }
  return raw;
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
/// it is unfiltered — as is a frame seen before identity finishes loading,
/// which degrades to "notify", never to a silently dropped machine event.
///
/// A rig is not a destination of its own (its live view is a TAB in the
/// space or PR it serves) and the event does not name a conversation, so the
/// deep link goes to Settings → Server → Enclosures: the running-machine list,
/// which is the one place that can answer "which machines are up right now".
AppNotification _rigControlChanged(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String?;
  final held = p['held'] == true;
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
    tone: NotificationTone.negative,
    title: l10n.notificationRigFailed,
    body: l10n.notificationRigFailedBody,
    route: _wsRoute(workspaceId, settingsRigsRoute),
    workspaceId: workspaceId,
  );
}

/// An agent is waiting on the operator. The title says who and for what; the
/// body is what they are being asked. Tapping opens the space where the wait
/// is answered — the approval card, the question form, the credential dialog
/// all render there.
///
/// Carries the space id so the toast stays quiet while the operator is already
/// looking at that space: the card in front of them is the notification.
///
/// Carries the wait so the OS notification keeps one identity for its whole
/// life (reminders replace it, the wait's end withdraws it) and, for an
/// approval, offers Approve and Deny. A frame without a `wait_id` is not a
/// wait and is dropped.
AppNotification? _agentAwaitingInput(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final wait = agentWaitOf(p);
  if (wait == null) {
    return null;
  }
  final workspaceId = p['workspace_id'] as String?;
  final spaceId = p['space_id'] as String?;
  final name = (p['agent_name'] as String? ?? '').trim();
  final named = name.isNotEmpty;
  // An unknown kind (a newer server) still says an agent is waiting rather
  // than dropping the one notification that unblocks it.
  final title = switch (p['kind'] as String?) {
    'question' =>
      named
          ? l10n.notificationAgentAskedQuestion(name)
          : l10n.notificationAgentAskedQuestionUnnamed,
    'credential' =>
      named
          ? l10n.notificationAgentBlockedOnCredential(name)
          : l10n.notificationAgentBlockedOnCredentialUnnamed,
    _ =>
      named
          ? l10n.notificationAgentNeedsApproval(name)
          : l10n.notificationAgentNeedsApprovalUnnamed,
  };
  return AppNotification(
    category: NotificationCategory.agentAwaitingInput,
    title: title,
    body: (p['summary'] as String? ?? '').trim(),
    route: _spaceDeepLink(
      workspaceId,
      spaceId,
      conversationId: p['conversation_id'] as String?,
    ),
    workspaceId: workspaceId,
    spaceId: spaceId,
    wait: wait,
  );
}

/// The wait an `agent_awaiting_input` frame's [params] announce, or null when
/// they carry no `wait_id`.
NotificationWait? agentWaitOf(Map<String, dynamic> params) {
  final id = params['wait_id'] as String?;
  if (id == null || id.isEmpty) {
    return null;
  }
  return NotificationWait(
    id: id,
    kind: AgentInputKind.values.asNameMap()[params['kind'] as String?],
  );
}

/// Policy refused an action an agent tried to take.
///
/// Deliberately NOT the awaiting-input copy: nothing here can be approved, and
/// "needs your approval" would send the operator hunting for a button that
/// does not exist. The title states the refusal (the same "Blocked" the rest
/// of the app uses for that state) and names the agent; the body carries the
/// action and the rule's own terminal reason — the two things an operator
/// opens a refusal to read. Tapping opens the space the agent was stopped in,
/// where both the work and the rule live.
///
/// Still notifies while this space is open: unlike a pending approval, a
/// refusal has no inline card to make the block visible.
AppNotification? _agentActionBlocked(
  Map<String, dynamic> p,
  AppLocalizations l10n,
) {
  final workspaceId = p['workspace_id'] as String?;
  final spaceId = p['space_id'] as String?;
  final name = (p['agent_name'] as String? ?? '').trim();
  final action = (p['summary'] as String? ?? '').trim();
  final reason = (p['reason'] as String? ?? '').trim();
  // What was refused, then why. Either half can be missing — a guard with
  // nothing to summarize — so the other still carries the row.
  final body = action.isEmpty
      ? reason
      : reason.isEmpty
      ? action
      : '$action — $reason';
  return AppNotification(
    category: NotificationCategory.agentAwaitingInput,
    title: name.isEmpty ? l10n.blocked : '$name: ${l10n.blocked}',
    body: body,
    route: _spaceDeepLink(workspaceId, spaceId),
    workspaceId: workspaceId,
    spaceId: spaceId,
    presentation: NotificationPresentation.notification,
    suppressWhenViewingTarget: false,
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
