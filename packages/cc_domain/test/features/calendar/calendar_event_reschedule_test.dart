import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event_reschedule.dart';
import 'package:test/test.dart';

CalendarEvent _event(List<CalendarAttendee> attendees) => CalendarEvent(
  id: 'evt',
  workspaceId: 'ws',
  accountId: 'acct',
  externalEventId: 'g',
  calendarId: 'primary',
  title: 'Review',
  startTime: DateTime.utc(2026, 11, 19, 19),
  endTime: DateTime.utc(2026, 11, 19, 20),
  updatedAt: DateTime.utc(2026, 11, 8),
  attendees: attendees,
);

void main() {
  test('refuses an empty or inverted span', () {
    final at = DateTime.utc(2026, 11, 19, 19);
    expect(
      () => CalendarEventReschedule(eventId: 'evt', start: at, end: at),
      throwsArgumentError,
    );
    expect(
      () => CalendarEventReschedule(
        eventId: '',
        start: at,
        end: at.add(const Duration(hours: 1)),
      ),
      throwsArgumentError,
    );
  });

  test('a timed move survives its arguments, in UTC', () {
    final move = CalendarEventReschedule(
      eventId: 'evt',
      start: DateTime.utc(2026, 11, 17, 18, 45),
      end: DateTime.utc(2026, 11, 17, 19, 45),
    );
    expect(CalendarEventReschedule.fromArgs(move.toArgs()), move);
  });

  test('an all-day move travels as dates with an exclusive end', () {
    final move = CalendarEventReschedule(
      eventId: 'evt',
      start: DateTime(2026, 11, 17, 9),
      end: DateTime(2026, 11, 19),
      isAllDay: true,
    );
    expect(move.toArgs()['start'], '2026-11-17');
    expect(move.toArgs()['end'], '2026-11-19');
    expect(CalendarEventReschedule.fromArgs(move.toArgs()), move);
  });

  test('only an own event or one the person organizes may move', () {
    expect(CalendarEventReschedule.allowedFor(_event(const [])), isTrue);
    expect(
      CalendarEventReschedule.allowedFor(
        _event(const [
          CalendarAttendee(email: 'a@x.com', self: true, organizer: true),
          CalendarAttendee(email: 'b@x.com'),
        ]),
      ),
      isTrue,
    );
    expect(
      CalendarEventReschedule.allowedFor(
        _event(const [
          CalendarAttendee(email: 'a@x.com', self: true),
          CalendarAttendee(email: 'b@x.com', organizer: true),
        ]),
      ),
      isFalse,
    );
  });
}
