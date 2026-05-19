/// The start or end time of a Google Calendar event.
///
/// Google sends timed events as `dateTime` (RFC 3339, carries an offset) and
/// all-day events as `date` (`YYYY-MM-DD`, no time/zone). They are kept
/// distinct here — an all-day `date` is parsed as local midnight and flagged via
/// [isDate]; it must never be treated as a `00:00` timestamp for alerting.
class GoogleEventTime {
  /// Creates a [GoogleEventTime].
  const GoogleEventTime({this.dateTime, this.date, this.timeZone});

  /// Creates a [GoogleEventTime] from a Calendar API time object.
  factory GoogleEventTime.fromJson(Map<String, dynamic> json) {
    final dt = json['dateTime'];
    final d = json['date'];
    return GoogleEventTime(
      dateTime: dt is String ? DateTime.tryParse(dt) : null,
      date: d is String ? DateTime.tryParse(d) : null,
      timeZone: json['timeZone'] as String?,
    );
  }

  /// Set for timed events (RFC 3339).
  final DateTime? dateTime;

  /// Set for all-day events (date-only, parsed as local midnight).
  final DateTime? date;

  /// The IANA time zone, when provided.
  final String? timeZone;

  /// Whether this is an all-day (date-only) value.
  bool get isDate => date != null && dateTime == null;

  /// The resolved [DateTime] (timed value, else the all-day date).
  DateTime get resolved =>
      dateTime ?? date ?? DateTime.fromMillisecondsSinceEpoch(0);
}

/// An attendee on a Google Calendar event.
class GoogleEventAttendee {
  /// Creates a [GoogleEventAttendee].
  const GoogleEventAttendee({
    required this.email,
    this.displayName,
    this.responseStatus,
    this.self = false,
    this.organizer = false,
  });

  /// Creates a [GoogleEventAttendee] from JSON.
  factory GoogleEventAttendee.fromJson(Map<String, dynamic> json) {
    return GoogleEventAttendee(
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
      responseStatus: json['responseStatus'] as String?,
      self: json['self'] as bool? ?? false,
      organizer: json['organizer'] as bool? ?? false,
    );
  }

  /// The attendee email.
  final String email;

  /// Optional display name.
  final String? displayName;

  /// `needsAction` / `declined` / `tentative` / `accepted`.
  final String? responseStatus;

  /// Whether this attendee is the authenticated user.
  final bool self;

  /// Whether this attendee is the organizer.
  final bool organizer;
}

/// Typed representation of a Google Calendar event resource.
class GoogleCalendarEvent {
  /// Creates a [GoogleCalendarEvent].
  const GoogleCalendarEvent({
    required this.id,
    required this.status,
    required this.start,
    required this.end,
    this.summary = '',
    this.description,
    this.location,
    this.attendees = const <GoogleEventAttendee>[],
    this.organizer,
    this.creator,
    this.hangoutLink,
    this.meetUrl,
    this.recurringEventId,
    this.htmlLink,
    this.updated,
  });

  /// Creates a [GoogleCalendarEvent] from a Calendar API event resource.
  factory GoogleCalendarEvent.fromJson(Map<String, dynamic> json) {
    final start = json['start'];
    final end = json['end'];
    final attendees = json['attendees'];
    final organizer = json['organizer'];
    final creator = json['creator'];
    return GoogleCalendarEvent(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'confirmed',
      summary: json['summary'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      start: GoogleEventTime.fromJson(
        start is Map<String, dynamic> ? start : const <String, dynamic>{},
      ),
      end: GoogleEventTime.fromJson(
        end is Map<String, dynamic> ? end : const <String, dynamic>{},
      ),
      attendees: attendees is List
          ? attendees
              .whereType<Map<String, dynamic>>()
              .map(GoogleEventAttendee.fromJson)
              .toList(growable: false)
          : const <GoogleEventAttendee>[],
      organizer: organizer is Map<String, dynamic>
          ? GoogleEventAttendee.fromJson(organizer)
          : null,
      creator: creator is Map<String, dynamic>
          ? GoogleEventAttendee.fromJson(creator)
          : null,
      hangoutLink: json['hangoutLink'] as String?,
      meetUrl: _resolveMeetUrl(json),
      recurringEventId: json['recurringEventId'] as String?,
      htmlLink: json['htmlLink'] as String?,
      updated: json['updated'] is String
          ? DateTime.tryParse(json['updated'] as String)
          : null,
    );
  }

  /// Google's event id (stable per calendar; for recurrences with
  /// `singleEvents=true` this is the per-instance id).
  final String id;

  /// `confirmed` / `tentative` / `cancelled`.
  final String status;

  /// Event title.
  final String summary;

  /// Optional description.
  final String? description;

  /// Optional location.
  final String? location;

  /// Start time (timed or all-day).
  final GoogleEventTime start;

  /// End time (timed or all-day).
  final GoogleEventTime end;

  /// Attendees, when present.
  final List<GoogleEventAttendee> attendees;

  /// The event organizer, when present. Carries a display name more often than
  /// the per-attendee entries do, so it is used to backfill attendee names.
  final GoogleEventAttendee? organizer;

  /// The event creator, when present.
  final GoogleEventAttendee? creator;

  /// Legacy Hangouts link, when present.
  final String? hangoutLink;

  /// Resolved video-conference (Meet/Hangouts) URL, when present.
  final String? meetUrl;

  /// The master recurring event id, when this is a recurrence instance.
  final String? recurringEventId;

  /// The event's web URL.
  final String? htmlLink;

  /// Last modified time.
  final DateTime? updated;

  /// Whether this is an all-day event.
  bool get isAllDay => start.isDate;

  static String? _resolveMeetUrl(Map<String, dynamic> json) {
    final conference = json['conferenceData'];
    if (conference is Map<String, dynamic>) {
      final entryPoints = conference['entryPoints'];
      if (entryPoints is List) {
        for (final entry in entryPoints) {
          if (entry is Map<String, dynamic> &&
              entry['entryPointType'] == 'video') {
            final uri = entry['uri'] as String?;
            if (uri != null && uri.isNotEmpty) {
              return uri;
            }
          }
        }
      }
    }
    return json['hangoutLink'] as String?;
  }
}
