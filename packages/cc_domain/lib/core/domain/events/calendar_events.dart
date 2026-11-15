import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// Fired when a connected calendar account's OAuth refresh token is found to be
/// permanently invalid (Google `invalid_grant`) and the user must reconnect.
///
/// Published exactly once per disconnection episode (the repository's
/// `markNeedsReauth` only returns true on the null→set transition). Drives the
/// "calendar disconnected — reconnect" desktop notification (see
/// `NotificationEventMapper`); the in-app banner reacts to the persisted flag,
/// not this event.
class CalendarAuthExpired implements DomainEvent {
  /// Creates a [CalendarAuthExpired].
  const CalendarAuthExpired({
    required this.workspaceId,
    required this.accountEmail,
    required this.occurredAt,
  });

  /// The workspace whose account lost authorization.
  final String workspaceId;

  /// The disconnected account's email (for the notification body).
  final String accountEmail;

  @override
  final DateTime occurredAt;
}

/// Fired when a calendar event is starting within the configured lead window.
///
/// Raised by the server's meeting alert sweep. Carries a real [workspaceId],
/// the calendar owner [forUserId] (a meeting on one person's calendar is
/// nobody else's alert) and the [meetingUrl] so the notification / event card
/// can offer a join action.
class MeetingStartingSoon implements DomainEvent {
  /// Creates a [MeetingStartingSoon].
  const MeetingStartingSoon({
    required this.workspaceId,
    required this.forUserId,
    required this.eventId,
    required this.title,
    required this.startTime,
    required this.meetingUrl,
    required this.occurredAt,
  });

  /// Owning workspace.
  final String workspaceId;

  /// The member whose calendar holds the event: the only one alerted.
  final String forUserId;

  /// The calendar event's local id.
  final String eventId;

  /// The event title.
  final String title;

  /// When the event starts.
  final DateTime startTime;

  /// The video-conference URL, when present.
  final String? meetingUrl;

  @override
  final DateTime occurredAt;
}
