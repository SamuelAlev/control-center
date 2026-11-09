import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event_draft.dart';

/// New times for an existing calendar event: where a drag on the grid, or a
/// resize of its edge, put it.
///
/// Timed spans are stored in UTC; an all-day span holds date-only values with
/// an exclusive end (the day after the last one), as Google wants them.
class CalendarEventReschedule {
  /// Creates the reschedule of [eventId]. Throws [ArgumentError] named `end`
  /// when the span is empty, inverted or longer than
  /// [CalendarEventDraft.maxDuration].
  CalendarEventReschedule({
    required this.eventId,
    required DateTime start,
    required DateTime end,
    this.isAllDay = false,
  }) : start = isAllDay ? _day(start) : start.toUtc(),
       end = isAllDay ? _day(end) : end.toUtc() {
    if (eventId.isEmpty) {
      throw ArgumentError.value(eventId, 'eventId', 'must not be empty');
    }
    if (!this.end.isAfter(this.start)) {
      throw ArgumentError.value(end, 'end', 'must be after the start');
    }
    if (this.end.difference(this.start) > CalendarEventDraft.maxDuration) {
      throw ArgumentError.value(end, 'end', 'is too far from the start');
    }
  }

  /// Parses the `calendar.moveEvent` arguments [toArgs] writes.
  factory CalendarEventReschedule.fromArgs(Map<String, dynamic> args) {
    DateTime when(String key) {
      final raw = args[key];
      final parsed = raw is String ? DateTime.tryParse(raw) : null;
      if (parsed == null) {
        throw ArgumentError.value(raw, key, 'is not a date');
      }
      return parsed;
    }

    return CalendarEventReschedule(
      eventId: args['event_id'] as String? ?? '',
      start: when('start'),
      end: when('end'),
      isAllDay: args['all_day'] == true,
    );
  }

  /// Whether the person may move [event] at all: an event of their own with
  /// no guests, or one they organize. A guest's change would only touch
  /// their own copy and leave everyone else at the old time, so an
  /// invitation stays where the organizer put it.
  static bool allowedFor(CalendarEvent event) =>
      event.attendees.isEmpty ||
      event.attendees.any((a) => a.self && a.organizer);

  /// The local id of the event being moved.
  final String eventId;

  /// The new start (UTC, or the first day when [isAllDay]).
  final DateTime start;

  /// The new end (UTC, or the day after the last when [isAllDay]).
  final DateTime end;

  /// Whether the event covers whole days.
  final bool isAllDay;

  /// The RPC arguments for `calendar.moveEvent`.
  Map<String, dynamic> toArgs() => {
    'event_id': eventId,
    'start': isAllDay
        ? CalendarEventDraft.dateOnly(start)
        : start.toIso8601String(),
    'end': isAllDay ? CalendarEventDraft.dateOnly(end) : end.toIso8601String(),
    'all_day': isAllDay,
  };

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEventReschedule &&
          eventId == other.eventId &&
          start == other.start &&
          end == other.end &&
          isAllDay == other.isAllDay;

  @override
  int get hashCode => Object.hash(eventId, start, end, isAllDay);
}
