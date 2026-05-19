import 'package:meta/meta.dart';

/// Lifecycle status of a calendar event.
enum CalendarEventStatus {
  /// The event is confirmed.
  confirmed,

  /// The event is tentative.
  tentative,

  /// The event was cancelled.
  cancelled;

  /// Parses a stored status string (defaults to [confirmed]).
  static CalendarEventStatus fromStorage(String? raw) {
    switch (raw) {
      case 'tentative':
        return CalendarEventStatus.tentative;
      case 'cancelled':
        return CalendarEventStatus.cancelled;
      default:
        return CalendarEventStatus.confirmed;
    }
  }

  /// The storage representation.
  String toStorage() => name;
}

/// An attendee on a [CalendarEvent].
@immutable
class CalendarAttendee {
  /// Creates a [CalendarAttendee].
  const CalendarAttendee({
    required this.email,
    this.displayName,
    this.responseStatus,
    this.self = false,
    this.organizer = false,
  });

  /// Attendee email.
  final String email;

  /// Optional display name.
  final String? displayName;

  /// `needsAction` / `declined` / `tentative` / `accepted`.
  final String? responseStatus;

  /// Whether this attendee is the local user.
  final bool self;

  /// Whether this attendee is the organizer.
  final bool organizer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarAttendee &&
          email == other.email &&
          displayName == other.displayName &&
          responseStatus == other.responseStatus &&
          self == other.self &&
          organizer == other.organizer;

  @override
  int get hashCode =>
      Object.hash(email, displayName, responseStatus, self, organizer);
}

/// A calendar event synced (read-only) from a connected provider.
///
/// Distinct from a recording `Meeting`: this is a future commitment, with a
/// real scheduled time. All-day events are flagged via [isAllDay] and carry a
/// date-only [startTime] (local midnight); timed events carry UTC times — render
/// with `toLocal()`.
@immutable
class CalendarEvent {
  /// Creates a [CalendarEvent].
  const CalendarEvent({
    required this.id,
    required this.workspaceId,
    required this.accountId,
    required this.externalEventId,
    required this.calendarId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.updatedAt,
    this.description,
    this.location,
    this.meetingUrl,
    this.recurringEventId,
    this.alertedAt,
    this.isAllDay = false,
    this.status = CalendarEventStatus.confirmed,
    this.attendees = const <CalendarAttendee>[],
  });

  /// Local UUID id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The connected account this event came from.
  final String accountId;

  /// The provider's event id.
  final String externalEventId;

  /// The provider calendar id.
  final String calendarId;

  /// Event title.
  final String title;

  /// Optional description.
  final String? description;

  /// Optional location.
  final String? location;

  /// Start time.
  final DateTime startTime;

  /// End time.
  final DateTime endTime;

  /// Whether this is an all-day event.
  final bool isAllDay;

  /// Attendees.
  final List<CalendarAttendee> attendees;

  /// Resolved video-conference (Meet) URL, when present.
  final String? meetingUrl;

  /// Event status.
  final CalendarEventStatus status;

  /// Master recurring event id, when this is a recurrence instance.
  final String? recurringEventId;

  /// When a "starting soon" alert was fired (null until alerted).
  final DateTime? alertedAt;

  /// Last update time.
  final DateTime updatedAt;

  /// The signed-in user's RSVP response on this event (`needsAction` /
  /// `accepted` / `declined` / `tentative`), or null when the user is not an
  /// attendee.
  String? get myResponseStatus {
    for (final attendee in attendees) {
      if (attendee.self) {
        return attendee.responseStatus;
      }
    }
    return null;
  }

  /// Whether this is an invitation the user has been asked to attend but has not
  /// answered yet (RSVP still `needsAction`).
  bool get isUnansweredInvitation => myResponseStatus == 'needsAction';

  /// Returns a copy with the given fields replaced.
  CalendarEvent copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    List<CalendarAttendee>? attendees,
    String? meetingUrl,
    CalendarEventStatus? status,
    String? recurringEventId,
    DateTime? alertedAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id,
      workspaceId: workspaceId,
      accountId: accountId,
      externalEventId: externalEventId,
      calendarId: calendarId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      attendees: attendees ?? this.attendees,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      status: status ?? this.status,
      recurringEventId: recurringEventId ?? this.recurringEventId,
      alertedAt: alertedAt ?? this.alertedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          externalEventId == other.externalEventId &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          isAllDay == other.isAllDay &&
          status == other.status &&
          title == other.title;

  @override
  int get hashCode => Object.hash(
        id,
        workspaceId,
        externalEventId,
        startTime,
        endTime,
        isAllDay,
        status,
        title,
      );
}

/// A connected calendar account (per workspace).
@immutable
class CalendarAccount {
  /// Creates a [CalendarAccount].
  const CalendarAccount({
    required this.id,
    required this.workspaceId,
    required this.providerId,
    required this.accountEmail,
    this.displayName,
    this.lastSyncedAt,
    this.authExpiredAt,
  });

  /// Local UUID id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Provider id (`google`).
  final String providerId;

  /// Connected account email.
  final String accountEmail;

  /// Optional display name.
  final String? displayName;

  /// When events were last synced.
  final DateTime? lastSyncedAt;

  /// When this account's OAuth refresh token was found dead and re-consent is
  /// required; null while healthy. Included in `==`/`hashCode` so the accounts
  /// stream re-emits (and the reconnect banner toggles) when only this flips.
  final DateTime? authExpiredAt;

  /// Whether this account needs the user to reconnect (refresh token is dead).
  bool get needsReauth => authExpiredAt != null;

  /// Returns a copy with the given fields replaced.
  CalendarAccount copyWith({
    String? displayName,
    DateTime? lastSyncedAt,
    DateTime? authExpiredAt,
  }) =>
      CalendarAccount(
        id: id,
        workspaceId: workspaceId,
        providerId: providerId,
        accountEmail: accountEmail,
        displayName: displayName ?? this.displayName,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        authExpiredAt: authExpiredAt ?? this.authExpiredAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarAccount &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          providerId == other.providerId &&
          accountEmail == other.accountEmail &&
          displayName == other.displayName &&
          lastSyncedAt == other.lastSyncedAt &&
          authExpiredAt == other.authExpiredAt;

  @override
  int get hashCode => Object.hash(
        id,
        workspaceId,
        providerId,
        accountEmail,
        displayName,
        lastSyncedAt,
        authExpiredAt,
      );
}
