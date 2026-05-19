/// An entry in the user's Google Calendar list (`/users/me/calendarList`).
class GoogleCalendarListEntry {
  /// Creates a [GoogleCalendarListEntry].
  const GoogleCalendarListEntry({
    required this.id,
    required this.summary,
    this.primary = false,
    this.selected = false,
    this.description,
    this.backgroundColor,
    this.foregroundColor,
    this.accessRole,
    this.timeZone,
  });

  /// Creates a [GoogleCalendarListEntry] from JSON.
  factory GoogleCalendarListEntry.fromJson(Map<String, dynamic> json) {
    return GoogleCalendarListEntry(
      id: json['id'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      primary: json['primary'] as bool? ?? false,
      selected: json['selected'] as bool? ?? false,
      description: json['description'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      foregroundColor: json['foregroundColor'] as String?,
      accessRole: json['accessRole'] as String?,
      timeZone: json['timeZone'] as String?,
    );
  }

  /// Calendar id (`primary` for the main calendar).
  final String id;

  /// Display name.
  final String summary;

  /// Whether this is the user's primary calendar.
  final bool primary;

  /// Whether the user has this calendar selected/visible.
  final bool selected;

  /// Optional description.
  final String? description;

  /// Hex background color, when provided.
  final String? backgroundColor;

  /// Hex foreground color, when provided.
  final String? foregroundColor;

  /// The user's access role (`owner` / `writer` / `reader` / `freeBusyReader`).
  final String? accessRole;

  /// The calendar's IANA time zone.
  final String? timeZone;
}
