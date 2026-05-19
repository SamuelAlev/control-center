import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:control_center/features/meetings/presentation/widgets/detail/meeting_transcript_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CalendarEvent eventWith(List<CalendarAttendee> attendees) => CalendarEvent(
        id: 'e',
        workspaceId: 'ws',
        accountId: 'a',
        externalEventId: 'x',
        calendarId: 'c',
        title: 'Sync',
        startTime: DateTime(2026, 6, 17, 10),
        endTime: DateTime(2026, 6, 17, 11),
        updatedAt: DateTime(2026, 6, 17, 9),
        attendees: attendees,
      );

  group('attendeeNameSuggestions', () {
    test('returns empty when there is no linked event', () {
      expect(attendeeNameSuggestions(null, MeetingSpeaker.them), isEmpty);
    });

    test('them → other invitees, preferring display name then derived name',
        () {
      final event = eventWith(const [
        CalendarAttendee(email: 'me@x.com', displayName: 'Me', self: true),
        CalendarAttendee(email: 'ada@x.com', displayName: 'Ada Lovelace'),
        // no display name → name derived from the email local part.
        CalendarAttendee(email: 'grace.hopper@x.com'),
      ]);
      expect(
        attendeeNameSuggestions(event, MeetingSpeaker.them),
        ['Ada Lovelace', 'Grace Hopper'],
      );
    });

    test('me → only the local user', () {
      final event = eventWith(const [
        CalendarAttendee(email: 'me@x.com', displayName: 'Me', self: true),
        CalendarAttendee(email: 'ada@x.com', displayName: 'Ada Lovelace'),
      ]);
      expect(attendeeNameSuggestions(event, MeetingSpeaker.me), ['Me']);
    });

    test('de-duplicates repeated names', () {
      final event = eventWith(const [
        CalendarAttendee(email: 'ada@x.com', displayName: 'Ada'),
        CalendarAttendee(email: 'ada2@x.com', displayName: 'Ada'),
      ]);
      expect(attendeeNameSuggestions(event, MeetingSpeaker.them), ['Ada']);
    });
  });
}
