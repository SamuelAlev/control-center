import 'package:cc_infra/src/network/models/google_calendar_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleCalendarEvent.fromJson', () {
    test('parses a timed event', () {
      final event = GoogleCalendarEvent.fromJson({
        'id': 'evt-1',
        'status': 'confirmed',
        'summary': 'Standup',
        'description': 'Daily',
        'location': 'Room 1',
        'start': {'dateTime': '2026-06-11T10:00:00Z'},
        'end': {'dateTime': '2026-06-11T10:30:00Z'},
      });
      expect(event.id, 'evt-1');
      expect(event.summary, 'Standup');
      expect(event.isAllDay, isFalse);
      expect(event.start.dateTime, DateTime.utc(2026, 6, 11, 10));
      expect(event.end.dateTime, DateTime.utc(2026, 6, 11, 10, 30));
    });

    test('parses an all-day event as date-only (isAllDay)', () {
      final event = GoogleCalendarEvent.fromJson({
        'id': 'evt-2',
        'status': 'confirmed',
        'summary': 'Holiday',
        'start': {'date': '2026-06-11'},
        'end': {'date': '2026-06-12'},
      });
      expect(event.isAllDay, isTrue);
      expect(event.start.isDate, isTrue);
      expect(event.start.dateTime, isNull);
      expect(event.start.date, DateTime(2026, 6, 11));
    });

    test('extracts Meet URL from conferenceData video entry point', () {
      final event = GoogleCalendarEvent.fromJson({
        'id': 'evt-3',
        'status': 'confirmed',
        'start': {'dateTime': '2026-06-11T10:00:00Z'},
        'end': {'dateTime': '2026-06-11T11:00:00Z'},
        'hangoutLink': 'https://hangouts.example/abc',
        'conferenceData': {
          'entryPoints': [
            {'entryPointType': 'phone', 'uri': 'tel:+123'},
            {'entryPointType': 'video', 'uri': 'https://meet.google.com/xyz'},
          ],
        },
      });
      expect(event.meetUrl, 'https://meet.google.com/xyz');
    });

    test('falls back to hangoutLink when no conferenceData', () {
      final event = GoogleCalendarEvent.fromJson({
        'id': 'evt-4',
        'status': 'confirmed',
        'start': {'dateTime': '2026-06-11T10:00:00Z'},
        'end': {'dateTime': '2026-06-11T11:00:00Z'},
        'hangoutLink': 'https://hangouts.example/abc',
      });
      expect(event.meetUrl, 'https://hangouts.example/abc');
    });

    test('maps attendees and recurringEventId', () {
      final event = GoogleCalendarEvent.fromJson({
        'id': 'evt-5',
        'status': 'tentative',
        'recurringEventId': 'master-1',
        'start': {'dateTime': '2026-06-11T10:00:00Z'},
        'end': {'dateTime': '2026-06-11T11:00:00Z'},
        'attendees': [
          {'email': 'a@x.com', 'responseStatus': 'accepted', 'self': true},
          {'email': 'b@x.com', 'organizer': true},
        ],
      });
      expect(event.status, 'tentative');
      expect(event.recurringEventId, 'master-1');
      expect(event.attendees, hasLength(2));
      expect(event.attendees.first.email, 'a@x.com');
      expect(event.attendees.first.self, isTrue);
      expect(event.attendees[1].organizer, isTrue);
    });

    test('parses the top-level organizer and creator', () {
      final event = GoogleCalendarEvent.fromJson({
        'id': 'evt-7',
        'status': 'confirmed',
        'start': {'dateTime': '2026-06-11T10:00:00Z'},
        'end': {'dateTime': '2026-06-11T11:00:00Z'},
        'organizer': {'email': 'org@x.com', 'displayName': 'Org Anizer'},
        'creator': {'email': 'maker@x.com', 'displayName': 'Cre Ator'},
      });
      expect(event.organizer?.email, 'org@x.com');
      expect(event.organizer?.displayName, 'Org Anizer');
      expect(event.creator?.email, 'maker@x.com');
      expect(event.creator?.displayName, 'Cre Ator');
    });

    test('tolerates missing optional fields', () {
      final event = GoogleCalendarEvent.fromJson({'id': 'evt-6'});
      expect(event.summary, '');
      expect(event.status, 'confirmed');
      expect(event.description, isNull);
      expect(event.attendees, isEmpty);
      expect(event.organizer, isNull);
      expect(event.creator, isNull);
      expect(event.meetUrl, isNull);
    });
  });
}
