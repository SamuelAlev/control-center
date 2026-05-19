import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/conferencing_apps.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_detection.dart';
import 'package:cc_infra/src/meetings/calendar_meeting_signal_collector.dart';
import 'package:cc_infra/src/meetings/process_meeting_signal_collector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('conferencing app catalog', () {
    test('matches per-meeting processes case-insensitively', () {
      expect(matchPerMeetingProcess('/Applications/zoom.us')?.name, 'Zoom');
      expect(matchPerMeetingProcess('CiscoWebexMeeting')?.name, 'Webex');
      expect(matchPerMeetingProcess('g2mcomm.exe')?.name, 'GoTo Meeting');
    });

    test('ignores persistent always-on apps for process matching', () {
      expect(matchPerMeetingProcess('Microsoft Teams'), isNull);
      expect(matchPerMeetingProcess('Slack Helper'), isNull);
      expect(matchPerMeetingProcess('Discord'), isNull);
    });

    test('matches meeting URLs including persistent apps', () {
      expect(matchMeetingUrl('https://meet.google.com/abc')?.name,
          'Google Meet');
      expect(
        matchMeetingUrl('https://teams.microsoft.com/l/meetup')?.name,
        'Microsoft Teams',
      );
      expect(matchMeetingUrl('https://example.com/notes'), isNull);
    });
  });

  group('ProcessMeetingSignalCollector', () {
    final now = DateTime(2026, 6, 17, 10);

    test('emits one conferencingApp signal per per-meeting app, deduped',
        () async {
      final collector = ProcessMeetingSignalCollector(
        runProcessList: () async => [
          'zoom.us',
          'zoom.us (Helper)', // same app, must dedupe
          'CiscoWebex',
          'Microsoft Teams', // persistent → ignored
          'firefox',
        ],
      );
      final signals = await collector.sample(now);
      expect(
        signals.map((s) => s.label).toSet(),
        {'Zoom', 'Webex'},
      );
      expect(
        signals.every((s) => s.kind == MeetingSignalKind.conferencingApp),
        isTrue,
      );
      expect(signals.every((s) => s.active && s.at == now), isTrue);
    });

    test('returns nothing (no throw) when the process list command fails',
        () async {
      final collector = ProcessMeetingSignalCollector(
        runProcessList: () async => throw Exception('boom'),
      );
      expect(await collector.sample(now), isEmpty);
    });
  });

  group('CalendarMeetingSignalCollector', () {
    final now = DateTime(2026, 6, 17, 10, 30);

    CalendarEvent event({
      required DateTime start,
      required DateTime end,
      bool allDay = false,
      String? meetingUrl,
      int attendees = 2,
      String? myResponse = 'accepted',
      CalendarEventStatus status = CalendarEventStatus.confirmed,
      String title = 'Weekly sync',
    }) {
      return CalendarEvent(
        id: 'e1',
        workspaceId: 'ws',
        accountId: 'a',
        externalEventId: 'x',
        calendarId: 'c',
        title: title,
        startTime: start,
        endTime: end,
        updatedAt: now,
        isAllDay: allDay,
        meetingUrl: meetingUrl,
        status: status,
        attendees: [
          for (var i = 0; i < attendees; i++)
            CalendarAttendee(
              email: 'p$i@x.com',
              self: i == 0,
              responseStatus: i == 0 ? myResponse : 'accepted',
            ),
        ],
      );
    }

    Future<List<MeetingSignal>> sample(List<CalendarEvent> events) {
      final collector = CalendarMeetingSignalCollector(
        repository: _FakeCalendarRepo(events),
        activeWorkspaceId: () => 'ws',
      );
      return collector.sample(now);
    }

    test('emits a calendarEvent signal for a live, accepted meeting', () async {
      final signals = await sample([
        event(
          start: now.subtract(const Duration(minutes: 5)),
          end: now.add(const Duration(minutes: 25)),
        ),
      ]);
      expect(signals, hasLength(1));
      expect(signals.single.kind, MeetingSignalKind.calendarEvent);
      expect(signals.single.label, 'Weekly sync');
      expect(signals.single.at, now);
    });

    test('also emits a browserMeeting signal when a known join URL is present',
        () async {
      final signals = await sample([
        event(
          start: now.subtract(const Duration(minutes: 5)),
          end: now.add(const Duration(minutes: 25)),
          meetingUrl: 'https://meet.google.com/xyz',
        ),
      ]);
      expect(
        signals.map((s) => s.kind).toSet(),
        {MeetingSignalKind.calendarEvent, MeetingSignalKind.browserMeeting},
      );
    });

    test('fires within the pre-start grace window', () async {
      final signals = await sample([
        event(
          start: now.add(const Duration(minutes: 1)), // starts in 1 min
          end: now.add(const Duration(minutes: 31)),
        ),
      ]);
      expect(signals, hasLength(1));
    });

    test('ignores all-day, declined, cancelled, solo, and not-yet events',
        () async {
      final live = {
        'allDay': event(
          start: now.subtract(const Duration(hours: 1)),
          end: now.add(const Duration(hours: 1)),
          allDay: true,
        ),
        'declined': event(
          start: now.subtract(const Duration(minutes: 5)),
          end: now.add(const Duration(minutes: 25)),
          myResponse: 'declined',
        ),
        'cancelled': event(
          start: now.subtract(const Duration(minutes: 5)),
          end: now.add(const Duration(minutes: 25)),
          status: CalendarEventStatus.cancelled,
        ),
        'solo': event(
          start: now.subtract(const Duration(minutes: 5)),
          end: now.add(const Duration(minutes: 25)),
          attendees: 1,
        ),
        'tooEarly': event(
          start: now.add(const Duration(minutes: 10)),
          end: now.add(const Duration(minutes: 40)),
        ),
        'over': event(
          start: now.subtract(const Duration(hours: 2)),
          end: now.subtract(const Duration(hours: 1)),
        ),
      };
      for (final entry in live.entries) {
        expect(await sample([entry.value]), isEmpty, reason: entry.key);
      }
    });

    test('emits nothing when there is no active workspace', () async {
      final collector = CalendarMeetingSignalCollector(
        repository: _FakeCalendarRepo(const []),
        activeWorkspaceId: () => null,
      );
      expect(await collector.sample(now), isEmpty);
    });
  });
}

/// Minimal fake exposing only [watchEventsInRange]; every other member throws
/// via [noSuchMethod] (never called by the collector).
class _FakeCalendarRepo implements CalendarRepository {
  _FakeCalendarRepo(this._events);

  final List<CalendarEvent> _events;

  @override
  Stream<List<CalendarEvent>> watchEventsInRange(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) =>
      Stream.value(_events);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
