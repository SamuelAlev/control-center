part of 'dtos.dart';

// ---- Calendar (events + connected accounts) ----
//
// The calendar feature is workspace-scoped at the repository (the per-workspace
// Google account, not id uniqueness, is the isolation boundary). The thin
// client only READS this surface — synced events + connected accounts; the
// writes (account connect/disconnect, RSVP, the sync reconciler, alerts) depend
// on the host-resident OAuth tokens + Google API client, so they have no RPC
// surface. These DTOs are the typed wire view the client parses back; the host
// injects the authoritative workspace per session, so no `workspace_id` travels
// on the wire. Enum-free shapes → plain scalars; timestamps are ISO-8601.
//
// NOTE: OAuth tokens are NOT part of this surface — they live in the platform
// secure store (`GoogleCredentialsRepository`), never in the calendar
// repository, so nothing secret is carried here.

/// CalendarAttendee wire DTO — one attendee on a [CalendarEventDto].
class CalendarAttendeeDto {
  CalendarAttendeeDto({
    required this.email,
    this.displayName,
    this.responseStatus,
    this.self = false,
    this.organizer = false,
  });

  factory CalendarAttendeeDto.fromJson(Map<String, dynamic> json) =>
      CalendarAttendeeDto(
        email: json['email'] as String? ?? '',
        displayName: json['display_name'] as String?,
        responseStatus: json['response_status'] as String?,
        self: json['self'] as bool? ?? false,
        organizer: json['organizer'] as bool? ?? false,
      );

  final String email;
  final String? displayName;
  final String? responseStatus;
  final bool self;
  final bool organizer;

  Map<String, dynamic> toJson() => {
    'email': email,
    'display_name': ?displayName,
    'response_status': ?responseStatus,
    'self': self,
    'organizer': organizer,
  };
}

/// CalendarEvent wire DTO — a calendar event synced (read-only) from a provider.
/// Carries no `workspace_id` (the host binds it per session).
class CalendarEventDto {
  CalendarEventDto({
    required this.id,
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
    this.status = 'confirmed',
    this.attendees = const [],
  });

  factory CalendarEventDto.fromJson(Map<String, dynamic> json) =>
      CalendarEventDto(
        id: json['id'] as String,
        accountId: json['account_id'] as String? ?? '',
        externalEventId: json['external_event_id'] as String? ?? '',
        calendarId: json['calendar_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        startTime: json['start_time'] as String? ?? '',
        endTime: json['end_time'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        description: json['description'] as String?,
        location: json['location'] as String?,
        meetingUrl: json['meeting_url'] as String?,
        recurringEventId: json['recurring_event_id'] as String?,
        alertedAt: json['alerted_at'] as String?,
        isAllDay: json['is_all_day'] as bool? ?? false,
        status: json['status'] as String? ?? 'confirmed',
        attendees: ((json['attendees'] as List?) ?? const [])
            .whereType<Map>()
            .map((a) => CalendarAttendeeDto.fromJson(a.cast<String, dynamic>()))
            .toList(),
      );

  final String id;
  final String accountId;
  final String externalEventId;
  final String calendarId;
  final String title;

  /// ISO-8601 start timestamp — or a bare `YYYY-MM-DD` civil date when
  /// [isAllDay] (an all-day event is a day, not an instant: a bare date
  /// parses as the READER's local midnight, so the day never shifts with the
  /// reader's timezone).
  final String startTime;

  /// ISO-8601 end timestamp — bare `YYYY-MM-DD` (exclusive) when [isAllDay].
  final String endTime;

  /// ISO-8601 last-updated timestamp.
  final String updatedAt;
  final String? description;
  final String? location;
  final String? meetingUrl;
  final String? recurringEventId;

  /// ISO-8601 timestamp when the "starting soon" alert fired, or null.
  final String? alertedAt;
  final bool isAllDay;

  /// `confirmed` / `tentative` / `cancelled`.
  final String status;
  final List<CalendarAttendeeDto> attendees;

  Map<String, dynamic> toJson() => {
    'id': id,
    'account_id': accountId,
    'external_event_id': externalEventId,
    'calendar_id': calendarId,
    'title': title,
    'start_time': startTime,
    'end_time': endTime,
    'updated_at': updatedAt,
    'description': ?description,
    'location': ?location,
    'meeting_url': ?meetingUrl,
    'recurring_event_id': ?recurringEventId,
    'alerted_at': ?alertedAt,
    'is_all_day': isAllDay,
    'status': status,
    'attendees': attendees.map((a) => a.toJson()).toList(),
  };
}

/// CalendarAccount wire DTO — a connected calendar account (per workspace).
/// Carries no `workspace_id` (the host binds it per session) and, by design, no
/// OAuth tokens — only the non-secret display/sync metadata.
class CalendarAccountDto {
  CalendarAccountDto({
    required this.id,
    this.userId = '',
    required this.providerId,
    required this.accountEmail,
    this.displayName,
    this.lastSyncedAt,
    this.authExpiredAt,
  });

  factory CalendarAccountDto.fromJson(Map<String, dynamic> json) =>
      CalendarAccountDto(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? '',
        providerId: json['provider_id'] as String? ?? 'google',
        accountEmail: json['account_email'] as String? ?? '',
        displayName: json['display_name'] as String?,
        lastSyncedAt: json['last_synced_at'] as String?,
        authExpiredAt: json['auth_expired_at'] as String?,
      );

  final String id;

  /// The member who connected this account. Empty on legacy workspace-pool
  /// rows.
  final String userId;
  final String providerId;
  final String accountEmail;
  final String? displayName;

  /// ISO-8601 last-synced timestamp, or null.
  final String? lastSyncedAt;

  /// ISO-8601 timestamp when the OAuth refresh token was found dead, or null.
  final String? authExpiredAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'provider_id': providerId,
    'account_email': accountEmail,
    'display_name': ?displayName,
    'last_synced_at': ?lastSyncedAt,
    'auth_expired_at': ?authExpiredAt,
  };
}

/// CalendarSource wire DTO — one of a connected account's calendars (the
/// sidebar's per-account calendar list). Carries no `workspace_id` (the host
/// binds it per session); `account_id` is stamped host→client so a viewer can
/// group sources by owning account even when watching across accounts.
class CalendarSourceDto {
  CalendarSourceDto({
    required this.accountId,
    required this.id,
    required this.summary,
    required this.primary,
    required this.writable,
    this.backgroundColor,
  });

  factory CalendarSourceDto.fromJson(Map<String, dynamic> json) =>
      CalendarSourceDto(
        accountId: json['account_id'] as String? ?? '',
        id: json['id'] as String,
        summary: json['summary'] as String? ?? '',
        primary: json['primary'] as bool? ?? false,
        writable: json['writable'] as bool? ?? false,
        backgroundColor: json['background_color'] as String?,
      );

  /// Owning connected account id.
  final String accountId;

  /// Provider calendar id (`primary` for the account's main calendar).
  final String id;

  /// Display name.
  final String summary;

  /// The calendar's accent color as a `#rrggbb` hex string, or null.
  final String? backgroundColor;

  /// Whether this is the account's primary calendar.
  final bool primary;

  /// Whether the user can write to it (owner/writer access role).
  final bool writable;

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'id': id,
    'summary': summary,
    'primary': primary,
    'writable': writable,
    'background_color': ?backgroundColor,
  };
}
