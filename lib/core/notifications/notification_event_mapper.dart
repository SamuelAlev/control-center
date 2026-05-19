import 'dart:async';

import 'package:control_center/core/domain/events/agent_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/messaging_events.dart';
import 'package:control_center/core/domain/events/pr_events.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/domain/ports/notification_port.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';

/// Subscribes to [DomainEventBus] and maps events to [AppNotification]s.
///
/// This is the single place that decides *which* events produce
/// notifications and what title/body/route they carry. Pure mapping logic —
/// the actual display is delegated to [NotificationPort].
class NotificationEventMapper {
  /// Creates a [NotificationEventMapper] and subscribes to [eventBus].
  NotificationEventMapper({
    required DomainEventBus eventBus,
    required NotificationPort notificationPort,
    required AppLocalizations Function() localizations,
  })  : _eventBus = eventBus,
        _notificationPort = notificationPort,
        _localizations = localizations {
    _subscriptions = [
      _eventBus.on<AgentRunCompleted>().listen(_onAgentRunCompleted),
      _eventBus.on<PullRequestPublished>().listen(_onPullRequestPublished),
      _eventBus.on<PrMerged>().listen(_onPrMerged),
      _eventBus.on<MessageReceived>().listen(_onMessageReceived),
      _eventBus.on<ExternalPrDetected>().listen(_onExternalPrDetected),
      _eventBus.on<TicketAssigned>().listen(_onTicketAssigned),
      _eventBus.on<TicketStatusChanged>().listen(_onTicketStatusChanged),
    ];
  }

  final DomainEventBus _eventBus;
  final NotificationPort _notificationPort;
  final AppLocalizations Function() _localizations;
  late final List<StreamSubscription<DomainEvent>> _subscriptions;

  void _onAgentRunCompleted(AgentRunCompleted event) {
    final conversationId = event.conversationId;
    if (conversationId == null) return;

    final l10n = _localizations();
    _notificationPort.show(AppNotification(
      category: NotificationCategory.agentRunCompleted,
      title: l10n.notificationAgentFinished,
      body: l10n.runCompleted,
      route: messagingRoute,
      workspaceId: event.workspaceId,
      channelId: conversationId,
    ));
  }

  void _onPullRequestPublished(PullRequestPublished event) {
    final l10n = _localizations();
    _notificationPort.show(AppNotification(
      category: NotificationCategory.pullRequestPublished,
      title: l10n.notificationPrPublished,
      body: '${event.repoOwner}/${event.repoName}',
      route: pullRequestsRoute,
      workspaceId: event.workspaceId,
    ));
  }

  void _onPrMerged(PrMerged event) {
    final l10n = _localizations();
    _notificationPort.show(AppNotification(
      category: NotificationCategory.prMerged,
      title: l10n.notificationPrMerged,
      body: l10n.prMergedBody,
      route: pullRequestsRoute,
      workspaceId: event.workspaceId,
    ));
  }

  void _onMessageReceived(MessageReceived event) {
    if (!event.isAgentMessage) return;

    _notificationPort.show(AppNotification(
      category: NotificationCategory.newMessage,
      title: event.senderName,
      body: event.contentPreview,
      route: messagingRoute,
      workspaceId: event.workspaceId,
      channelId: event.channelId,
    ));
  }

  void _onExternalPrDetected(ExternalPrDetected event) {
    final l10n = _localizations();
    _notificationPort.show(AppNotification(
      category: NotificationCategory.externalPr,
      title: l10n.newPrToReview,
      body:
          '${event.author}: ${event.prTitle} (${event.repoOwner}/${event.repoName})',
      route: pullRequestsRoute,
      workspaceId: event.workspaceId,
    ));
  }

  void _onTicketAssigned(TicketAssigned event) {
    final l10n = _localizations();
    _notificationPort.show(AppNotification(
      category: NotificationCategory.ticketAssigned,
      title: l10n.notificationTicketAssigned,
      body: event.ticketTitle,
      route: ticketDetailRoute(event.ticketId),
      workspaceId: event.workspaceId,
    ));
  }

  void _onTicketStatusChanged(TicketStatusChanged event) {
    final l10n = _localizations();
    _notificationPort.show(AppNotification(
      category: NotificationCategory.ticketStatusChanged,
      title: l10n.notificationTicketStatusChanged,
      body: '${_humanizeStatus(event.from)} → ${_humanizeStatus(event.to)}',
      route: ticketDetailRoute(event.ticketId),
      workspaceId: event.workspaceId,
    ));
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
