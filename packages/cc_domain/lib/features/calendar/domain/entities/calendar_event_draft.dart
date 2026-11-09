/// A new calendar event as the person composed it, before Google assigns it
/// an id.
///
/// Validated on construction, so the client's composer and the server's
/// `calendar.createEvent` op refuse the same drafts. A timed event carries
/// instants ([start] before [end]); an all-day event carries calendar days,
/// with [end] the day AFTER the last one, matching Google's exclusive `date`
/// end. [toArgs] and [CalendarEventDraft.fromArgs] are the op's argument
/// shape: all-day days travel as `yyyy-MM-dd` strings so no time zone can
/// move them to a neighbouring day.
class CalendarEventDraft {
  /// Creates a [CalendarEventDraft]. Throws [ArgumentError] when a field is
  /// out of range.
  CalendarEventDraft({
    required this.accountId,
    required this.calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
    this.isAllDay = false,
    String? location,
    String? description,
    List<String> attendeeEmails = const [],
    this.addConference = false,
  }) : title = title.trim(),
       start = isAllDay ? _day(start) : start.toUtc(),
       end = isAllDay ? _day(end) : end.toUtc(),
       location = _optional(location),
       description = _optional(description),
       attendeeEmails = List.unmodifiable(_emails(attendeeEmails)) {
    if (accountId.isEmpty || calendarId.isEmpty) {
      throw ArgumentError('A calendar event needs an account and a calendar.');
    }
    if (this.title.isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
    if (this.title.length > maxTitleLength) {
      throw ArgumentError.value(title, 'title', 'is too long');
    }
    if (!this.end.isAfter(this.start)) {
      throw ArgumentError.value(end, 'end', 'must be after the start');
    }
    if (this.end.difference(this.start) > maxDuration) {
      throw ArgumentError.value(end, 'end', 'is too far from the start');
    }
    if ((this.description?.length ?? 0) > maxDescriptionLength) {
      throw ArgumentError.value(description, 'description', 'is too long');
    }
  }

  /// Parses the `calendar.createEvent` arguments. Throws [ArgumentError] on a
  /// missing or malformed field.
  factory CalendarEventDraft.fromArgs(Map<String, dynamic> args) {
    final allDay = args['all_day'] == true;
    DateTime when(String key) {
      final raw = args[key];
      final parsed = raw is String ? DateTime.tryParse(raw) : null;
      if (parsed == null) {
        throw ArgumentError.value(raw, key, 'is not a date');
      }
      return parsed;
    }

    final guests = args['attendees'];
    return CalendarEventDraft(
      accountId: args['account_id'] as String? ?? '',
      calendarId: args['calendar_id'] as String? ?? '',
      title: args['title'] as String? ?? '',
      start: when('start'),
      end: when('end'),
      isAllDay: allDay,
      location: args['location'] as String?,
      description: args['description'] as String?,
      attendeeEmails: guests is List ? guests.whereType<String>().toList() : [],
      addConference: args['add_conference'] == true,
    );
  }

  /// The longest title Google keeps in full.
  static const int maxTitleLength = 1024;

  /// The longest description accepted.
  static const int maxDescriptionLength = 8192;

  /// The most guests one event may invite.
  static const int maxAttendees = 200;

  /// The longest event accepted; anything longer is a typo in a date.
  static const Duration maxDuration = Duration(days: 366);

  /// The connected Google account the event is created with.
  final String accountId;

  /// The Google calendar id the event is created on.
  final String calendarId;

  /// The event title, trimmed.
  final String title;

  /// The start: a UTC instant, or the first day (a date-only value) when
  /// [isAllDay].
  final DateTime start;

  /// The end: a UTC instant, or the day after the last one when [isAllDay].
  final DateTime end;

  /// Whether the event spans whole days.
  final bool isAllDay;

  /// Where the event takes place, if anywhere.
  final String? location;

  /// The event description, if any.
  final String? description;

  /// Invited guests, lowercased and de-duplicated. Google emails each one.
  final List<String> attendeeEmails;

  /// Whether Google should attach a Meet link.
  final bool addConference;

  /// The `calendar.createEvent` arguments for this draft.
  Map<String, dynamic> toArgs() => {
    'account_id': accountId,
    'calendar_id': calendarId,
    'title': title,
    'start': isAllDay ? dateOnly(start) : start.toIso8601String(),
    'end': isAllDay ? dateOnly(end) : end.toIso8601String(),
    'all_day': isAllDay,
    'location': ?location,
    'description': ?description,
    if (attendeeEmails.isNotEmpty) 'attendees': attendeeEmails,
    if (addConference) 'add_conference': true,
  };

  /// [day] as `yyyy-MM-dd`.
  static String dateOnly(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String? _optional(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static final RegExp _emailShape = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static List<String> _emails(List<String> raw) {
    final seen = <String>{};
    for (final entry in raw) {
      final email = entry.trim().toLowerCase();
      if (email.isEmpty) {
        continue;
      }
      if (!_emailShape.hasMatch(email)) {
        throw ArgumentError.value(entry, 'attendees', 'is not an email');
      }
      seen.add(email);
    }
    if (seen.length > maxAttendees) {
      throw ArgumentError.value(raw.length, 'attendees', 'too many guests');
    }
    return seen.toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEventDraft &&
          accountId == other.accountId &&
          calendarId == other.calendarId &&
          title == other.title &&
          start == other.start &&
          end == other.end &&
          isAllDay == other.isAllDay &&
          location == other.location &&
          description == other.description &&
          _sameList(attendeeEmails, other.attendeeEmails) &&
          addConference == other.addConference;

  @override
  int get hashCode => Object.hash(
    accountId,
    calendarId,
    title,
    start,
    end,
    isAllDay,
    location,
    description,
    Object.hashAll(attendeeEmails),
    addConference,
  );

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
