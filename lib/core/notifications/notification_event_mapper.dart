import 'dart:async';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/ports/notification_port.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';

/// Subscribes to [DomainEventBus] and maps events to [AppNotification]s.
///
/// This is the single place that decides *which* events produce
/// notifications and what title/body/route they carry. Pure mapping logic —
/// the actual display is delegated to [NotificationPort].
class NotificationEventMapper {
  /// Creates a [NotificationEventMapper] and subscribes to [_eventBus].
  NotificationEventMapper({
    required this._eventBus,
    required this._notificationPort,
    required this._localizations,
  }) {
    _subscriptions = [
      _eventBus.on<AgentRunCompleted>().listen(_onAgentRunCompleted),
      _eventBus.on<PullRequestPublished>().listen(_onPullRequestPublished),
      _eventBus.on<PrMerged>().listen(_onPrMerged),
      _eventBus.on<MessageReceived>().listen(_onMessageReceived),
      _eventBus.on<PrMentioned>().listen(_onPrMentioned),
      _eventBus.on<PrReviewRequested>().listen(_onPrReviewRequested),
      _eventBus.on<TicketAssigned>().listen(_onTicketAssigned),
      _eventBus.on<TicketStatusChanged>().listen(_onTicketStatusChanged),
      _eventBus.on<MeetingStartingSoon>().listen(_onMeetingStartingSoon),
      _eventBus.on<CalendarAuthExpired>().listen(_onCalendarAuthExpired),
    ];
  }

  final DomainEventBus _eventBus;
  final NotificationPort _notificationPort;
  final AppLocalizations Function() _localizations;
  late final List<StreamSubscription<DomainEvent>> _subscriptions;

  /// Builds a workspace-scoped deep-link route, falling back to the workspace
  /// picker when the originating event carries no workspace. Tapping the
  /// notification navigates here, which also switches the active workspace
  /// (the URL is the source of truth).
  static String _wsRoute(String? workspaceId, String Function(String) build) =>
      workspaceId == null ? workspaceListRoute : build(workspaceId);

  /// Deep-links to a specific channel when both the workspace and channel are
  /// known, falling back to the channel list (or the workspace picker) so the
  /// URL still resolves. The channel id in the URL is the source of truth for
  /// the open conversation.
  static String _channelDeepLink(
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

  void _onAgentRunCompleted(AgentRunCompleted event) {
    final conversationId = event.conversationId;
    if (conversationId == null) {
      return;
    }

    final l10n = _localizations();
    _notificationPort.show(
      AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: l10n.notificationAgentFinished,
        body: l10n.runCompleted,
        route: _channelDeepLink(event.workspaceId, conversationId),
        workspaceId: event.workspaceId,
        channelId: conversationId,
      ),
    );
  }

  void _onPullRequestPublished(PullRequestPublished event) {
    final l10n = _localizations();
    _notificationPort.show(
      AppNotification(
        category: NotificationCategory.pullRequestPublished,
        title: l10n.notificationPrPublished,
        body: '${event.repoOwner}/${event.repoName}',
        route: _wsRoute(event.workspaceId, pullRequestsRoute),
        workspaceId: event.workspaceId,
      ),
    );
  }

  void _onPrMerged(PrMerged event) {
    final l10n = _localizations();
    _notificationPort.show(
      AppNotification(
        category: NotificationCategory.prMerged,
        title: l10n.notificationPrMerged,
        body: l10n.prMergedBody,
        route: _wsRoute(event.workspaceId, pullRequestsRoute),
        workspaceId: event.workspaceId,
      ),
    );
  }

  void _onMessageReceived(MessageReceived event) {
    if (!event.isAgentMessage) {
      return;
    }
    // Mirrors the guard in [RpcNotificationMapper]: a content-less turn must not
    // raise a notification whose body is blank. Kept in both mappers so the
    // in-process and remote paths can't drift.
    final body = event.contentPreview.trim();
    if (body.isEmpty) {
      return;
    }

    _notificationPort.show(
      AppNotification(
        category: NotificationCategory.newMessage,
        title: event.senderName,
        body: body,
        route: _channelDeepLink(
          event.workspaceId,
          event.channelId,
          messageId: event.messageId,
        ),
        workspaceId: event.workspaceId,
        channelId: event.channelId,
      ),
    );
  }

  void _onPrMentioned(PrMentioned event) {
    final l10n = _localizations();
    _notificationPort.show(
      AppNotification(
        category: NotificationCategory.prMentioned,
        title: l10n.notificationPrMentioned,
        body:
            '${event.prTitle} (${event.repoOwner}/${event.repoName}#${event.prNumber})',
        route: _wsRoute(
          event.workspaceId,
          (w) => pullRequestDetailRoute(
            w,
            '${event.repoOwner}/${event.repoName}',
            event.prNumber,
          ),
        ),
        workspaceId: event.workspaceId,
      ),
    );
  }

  void _onPrReviewRequested(PrReviewRequested event) {
    final l10n = _localizations();
    _notificationPort.show(
      AppNotification(
        category: NotificationCategory.reviewRequested,
        title: l10n.notificationReviewRequested,
        body:
            '${event.prTitle} '
            '(${event.repoOwner}/${event.repoName}#${event.prNumber})',
        route: _wsRoute(
          event.workspaceId,
          (w) => pullRequestDetailRoute(
            w,
            '${event.repoOwner}/${event.repoName}',
            event.prNumber,
          ),
        ),
        workspaceId: event.workspaceId,
      ),
    );
  }

  void _onTicketAssigned(TicketAssigned event) {
    final l10n = _localizations();
    _notificationPort.show(
      AppNotification(
        category: NotificationCategory.ticketAssigned,
        title: l10n.notificationTicketAssigned,
        body: event.ticketTitle,
        route: _wsRoute(
          event.workspaceId,
          (w) => ticketDetailRoute(w, event.ticketId),
        ),
        workspaceId: event.workspaceId,
      ),
    );
  }

  void _onTicketStatusChanged(TicketStatusChanged event) {
    final l10n = _localizations();
    _notificationPort.show(
      AppNotification(
        category: NotificationCategory.ticketStatusChanged,
        title: l10n.notificationTicketStatusChanged,
        body: '${_humanizeStatus(event.from)} → ${_humanizeStatus(event.to)}',
        route: _wsRoute(
          event.workspaceId,
          (w) => ticketDetailRoute(w, event.ticketId),
        ),
        workspaceId: event.workspaceId,
      ),
    );
  }

  void _onMeetingStartingSoon(MeetingStartingSoon event) {
    final l10n = _localizations();
    _notificationPort.show(
      AppNotification(
        category: NotificationCategory.meetingStartsSoon,
        title: l10n.notificationMeetingStartsSoon,
        body: event.title,
        // Opens the event detail, where the "Start recording & link" action lives.
        route: _wsRoute(
          event.workspaceId,
          (w) => calendarDetailRoute(w, event.eventId),
        ),
        workspaceId: event.workspaceId,
        // Time-critical + actionable → earns the ambient banner rail (PRD 25 §1).
        presentation: NotificationPresentation.banner,
      ),
    );
  }

  void _onCalendarAuthExpired(CalendarAuthExpired event) {
    final l10n = _localizations();
    _notificationPort.show(
      AppNotification(
        category: NotificationCategory.calendarAuthExpired,
        title: l10n.notificationCalendarAuthExpiredTitle,
        // Opens the calendar, where the reconnect banner offers a one-click fix.
        body: event.accountEmail.isEmpty
            ? l10n.notificationCalendarAuthExpiredBodyNoEmail
            : l10n.notificationCalendarAuthExpiredBody(event.accountEmail),
        route: _wsRoute(event.workspaceId, calendarRoute),
        workspaceId: event.workspaceId,
        // Time-critical + actionable (sync is broken until reconnect) → banner.
        presentation: NotificationPresentation.banner,
      ),
    );
  }

  /// Turns a storage status string into a readable label for display:
  /// "inProgress" → "In progress", "in_review" → "In review", "open" → "Open".
  /// String-based on purpose so core stays decoupled from the ticketing enum.
  static String _humanizeStatus(String storage) {
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

  /// Cancels all event subscriptions.
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}
