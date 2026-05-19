import 'package:cc_infra/src/network/models/google_calendar_event.dart';
import 'package:test/test.dart';

/// Pins [GoogleCalendarEvent] / [GoogleEventTime] / [GoogleEventAttendee]
/// parsing. The calendar sync relies on distinguishing timed vs. all-day
/// events and on resolving the Meet URL from conferenceData — both of which
/// have non-trivial branching the original test suite never covered.
void main() {
  group('GoogleEventTime', () {
    test('timed event: dateTime set, isDate false', () {
      final t = GoogleEventTime.fromJson({
        'dateTime': '2026-01-01T10:00:00Z',
        'timeZone': 'UTC',
      });
      expect(t.dateTime, DateTime.utc(2026, 1, 1, 10));
      expect(t.date, isNull);
      expect(t.timeZone, 'UTC');
      expect(t.isDate, isFalse);
      expect(t.resolved, t.dateTime);
    });

    test('all-day event: date set, isDate true', () {
      final t = GoogleEventTime.fromJson({'date': '2026-01-01'});
      expect(t.date, isNotNull);
      expect(t.dateTime, isNull);
      expect(t.isDate, isTrue);
      expect(t.resolved, t.date);
    });

    test('empty object: resolved falls back to epoch', () {
      final t = GoogleEventTime.fromJson(const {});
      expect(t.dateTime, isNull);
      expect(t.date, isNull);
      expect(t.isDate, isFalse);
      expect(t.resolved.millisecondsSinceEpoch, 0);
    });

    test('non-string dateTime/date are treated as null', () {
      final t = GoogleEventTime.fromJson({
        'dateTime': 12345,
        'date': <String, dynamic>{},
      });
      expect(t.dateTime, isNull);
      expect(t.date, isNull);
    });

    test('unparseable strings parse to null', () {
      final t = GoogleEventTime.fromJson({'dateTime': 'not-a-date'});
      expect(t.dateTime, isNull);
    });
  });

  group('GoogleEventAttendee', () {
    test('parses all fields with defaults', () {
      final a = GoogleEventAttendee.fromJson({
        'email': 'x@y.com',
        'displayName': 'X',
        'responseStatus': 'accepted',
        'self': true,
        'organizer': false,
      });
      expect(a.email, 'x@y.com');
      expect(a.displayName, 'X');
      expect(a.responseStatus, 'accepted');
      expect(a.self, isTrue);
      expect(a.organizer, isFalse);
    });

    test('missing fields default sensibly', () {
      final a = GoogleEventAttendee.fromJson(const {});
      expect(a.email, '');
      expect(a.displayName, isNull);
      expect(a.responseStatus, isNull);
      expect(a.self, isFalse);
      expect(a.organizer, isFalse);
    });
  });

  group('GoogleCalendarEvent.fromJson', () {
    test('parses a fully-populated timed event with Meet URL', () {
      final e = GoogleCalendarEvent.fromJson({
        'id': 'evt-1',
        'status': 'confirmed',
        'summary': 'Standup',
        'description': 'daily',
        'location': 'Room A',
        'start': {'dateTime': '2026-01-01T09:00:00Z'},
        'end': {'dateTime': '2026-01-01T09:30:00Z'},
        'attendees': [
          {'email': 'a@y.com', 'responseStatus': 'accepted'},
          {'email': 'b@y.com', 'self': true},
        ],
        'organizer': {'email': 'org@y.com', 'displayName': 'Org'},
        'creator': {'email': 'c@y.com'},
        'conferenceData': {
          'entryPoints': [
            {'entryPointType': 'video', 'uri': 'https://meet.google.com/abc'},
          ],
        },
        'recurringEventId': 'master-1',
        'htmlLink': 'https://cal/event',
        'updated': '2026-01-01T00:00:00Z',
      });
      expect(e.id, 'evt-1');
      expect(e.status, 'confirmed');
      expect(e.summary, 'Standup');
      expect(e.description, 'daily');
      expect(e.location, 'Room A');
      expect(e.isAllDay, isFalse);
      expect(e.start.dateTime, DateTime.utc(2026, 1, 1, 9));
      expect(e.attendees, hasLength(2));
      expect(e.attendees.last.self, isTrue);
      expect(e.organizer!.displayName, 'Org');
      expect(e.creator!.email, 'c@y.com');
      expect(e.meetUrl, 'https://meet.google.com/abc');
      expect(e.hangoutLink, isNull);
      expect(e.recurringEventId, 'master-1');
      expect(e.htmlLink, 'https://cal/event');
      expect(e.updated, DateTime.utc(2026, 1, 1));
    });

    test('all-day event is flagged via isAllDay', () {
      final e = GoogleCalendarEvent.fromJson({
        'id': 'allday',
        'start': {'date': '2026-02-02'},
        'end': {'date': '2026-02-03'},
      });
      expect(e.isAllDay, isTrue);
      expect(e.start.isDate, isTrue);
    });

    test('meetUrl falls back to hangoutLink when no video entryPoint', () {
      final e = GoogleCalendarEvent.fromJson({
        'id': 'x',
        'start': {},
        'end': {},
        'hangoutLink': 'https://hangouts/x',
        'conferenceData': {
          'entryPoints': [
            {'entryPointType': 'phone', 'uri': 'tel:+1'},
          ],
        },
      });
      expect(e.meetUrl, 'https://hangouts/x');
    });

    test('meetUrl is null when conference data has no video + no hangout', () {
      final e = GoogleCalendarEvent.fromJson({
        'id': 'x',
        'start': {},
        'end': {},
      });
      expect(e.meetUrl, isNull);
    });

    test('ignores a video entryPoint with an empty uri', () {
      final e = GoogleCalendarEvent.fromJson({
        'id': 'x',
        'start': {},
        'end': {},
        'conferenceData': {
          'entryPoints': [
            {'entryPointType': 'video', 'uri': ''},
          ],
        },
        'hangoutLink': 'https://h/x',
      });
      expect(e.meetUrl, 'https://h/x');
    });

    test('defaults status to confirmed when missing', () {
      final e = GoogleCalendarEvent.fromJson({
        'id': 'x',
        'start': {},
        'end': {},
      });
      expect(e.status, 'confirmed');
      expect(e.summary, '');
      expect(e.attendees, isEmpty);
      expect(e.organizer, isNull);
      expect(e.creator, isNull);
    });

    test('non-map start/end fall back to empty time objects', () {
      final e = GoogleCalendarEvent.fromJson({
        'id': 'x',
        'start': 'bad',
        'end': 5,
      });
      expect(e.start.dateTime, isNull);
      expect(e.start.date, isNull);
      expect(e.start.resolved.millisecondsSinceEpoch, 0);
    });

    test('non-map attendees/organizer/creator are tolerated', () {
      final e = GoogleCalendarEvent.fromJson({
        'id': 'x',
        'start': {},
        'end': {},
        'attendees': 'nope',
        'organizer': 'nope',
        'creator': 42,
      });
      expect(e.attendees, isEmpty);
      expect(e.organizer, isNull);
      expect(e.creator, isNull);
    });
  });
}
