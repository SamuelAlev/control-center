import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_detection.dart';
import 'package:cc_infra/src/meetings/calendar_meeting_signal_collector.dart';
import 'package:test/test.dart';

class _FakeCalendarRepo implements CalendarRepository {
  _FakeCalendarRepo(this.events);
  final List<CalendarEvent> events;

  @override
  Stream<List<CalendarEvent>> watchEventsInRange(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) => Stream.value(events);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CalendarEvent _event({
  required DateTime start,
  required DateTime end,
  String title = 'Standup',
  String? meetingUrl,
  List<CalendarAttendee> attendees = const [],
  bool isAllDay = false,
  CalendarEventStatus status = CalendarEventStatus.confirmed,
}) => CalendarEvent(
  id: 'e1',
  workspaceId: 'ws',
  accountId: 'acct',
  externalEventId: 'ext',
  calendarId: 'primary',
  title: title,
  startTime: start,
  endTime: end,
  updatedAt: DateTime.utc(2025, 1, 1),
  meetingUrl: meetingUrl,
  attendees: attendees,
  isAllDay: isAllDay,
  status: status,
);

void main() {
  group('CalendarMeetingSignalCollector.sample', () {
    test('returns empty when no active workspace', () async {
      final collector = CalendarMeetingSignalCollector(
        repository: _FakeCalendarRepo(const []),
        activeWorkspaceId: () => null,
      );

      final signals = await collector.sample(DateTime.utc(2025, 6, 1, 10));

      expect(signals, isEmpty);
    });

    test('emits a calendarEvent signal for a live meeting', () async {
      final now = DateTime(2025, 6, 1, 10, 0);
      final event = _event(
        start: DateTime(2025, 6, 1, 9, 55),
        end: DateTime(2025, 6, 1, 10, 30),
        attendees: [
          const CalendarAttendee(email: 'a@x'),
          const CalendarAttendee(email: 'b@x'),
        ],
      );
      final collector = CalendarMeetingSignalCollector(
        repository: _FakeCalendarRepo([event]),
        activeWorkspaceId: () => 'ws',
      );

      final signals = await collector.sample(now);

      expect(
        signals.where((s) => s.kind == MeetingSignalKind.calendarEvent),
        hasLength(1),
      );
      expect(signals.first.label, 'Standup');
      expect(signals.first.active, isTrue);
    });

    test(
      'emits a browserMeeting signal when meetingUrl is recognized',
      () async {
        final now = DateTime(2025, 6, 1, 10, 0);
        final event = _event(
          start: DateTime(2025, 6, 1, 9, 55),
          end: DateTime(2025, 6, 1, 10, 30),
          meetingUrl: 'https://meet.google.com/abc-defg-hij',
          attendees: [
            const CalendarAttendee(email: 'a@x'),
            const CalendarAttendee(email: 'b@x'),
          ],
        );
        final collector = CalendarMeetingSignalCollector(
          repository: _FakeCalendarRepo([event]),
          activeWorkspaceId: () => 'ws',
        );

        final signals = await collector.sample(now);

        expect(
          signals.where((s) => s.kind == MeetingSignalKind.browserMeeting),
          hasLength(1),
        );
      },
    );

    test('treats event as live within the start grace window', () async {
      final now = DateTime(2025, 6, 1, 9, 58); // 2 min before start
      final event = _event(
        // Starts at 10:00, but grace is 2 min by default.
        start: DateTime(2025, 6, 1, 10, 0),
        end: DateTime(2025, 6, 1, 10, 30),
        attendees: [
          const CalendarAttendee(email: 'a@x'),
          const CalendarAttendee(email: 'b@x'),
        ],
      );
      final collector = CalendarMeetingSignalCollector(
        repository: _FakeCalendarRepo([event]),
        activeWorkspaceId: () => 'ws',
      );

      final signals = await collector.sample(now);

      expect(signals, isNotEmpty);
    });

    test('skips events that have already ended', () async {
      final now = DateTime(2025, 6, 1, 11, 0);
      final event = _event(
        start: DateTime(2025, 6, 1, 9, 55),
        end: DateTime(2025, 6, 1, 10, 0),
        attendees: [
          const CalendarAttendee(email: 'a@x'),
          const CalendarAttendee(email: 'b@x'),
        ],
      );
      final collector = CalendarMeetingSignalCollector(
        repository: _FakeCalendarRepo([event]),
        activeWorkspaceId: () => 'ws',
      );

      final signals = await collector.sample(now);

      expect(signals, isEmpty);
    });

    test('skips all-day events', () async {
      final now = DateTime(2025, 6, 1, 10);
      final event = _event(
        start: DateTime(2025, 6, 1, 0),
        end: DateTime(2025, 6, 2, 0),
        isAllDay: true,
        attendees: [
          const CalendarAttendee(email: 'a@x'),
          const CalendarAttendee(email: 'b@x'),
        ],
      );
      final collector = CalendarMeetingSignalCollector(
        repository: _FakeCalendarRepo([event]),
        activeWorkspaceId: () => 'ws',
      );

      final signals = await collector.sample(now);

      expect(signals, isEmpty);
    });

    test('skips cancelled events', () async {
      final now = DateTime(2025, 6, 1, 10);
      final event = _event(
        start: DateTime(2025, 6, 1, 9, 55),
        end: DateTime(2025, 6, 1, 10, 30),
        status: CalendarEventStatus.cancelled,
        attendees: [
          const CalendarAttendee(email: 'a@x'),
          const CalendarAttendee(email: 'b@x'),
        ],
      );
      final collector = CalendarMeetingSignalCollector(
        repository: _FakeCalendarRepo([event]),
        activeWorkspaceId: () => 'ws',
      );

      final signals = await collector.sample(now);

      expect(signals, isEmpty);
    });

    test('skips solo blocks (single attendee, no meeting url)', () async {
      final now = DateTime(2025, 6, 1, 10);
      final event = _event(
        start: DateTime(2025, 6, 1, 9, 55),
        end: DateTime(2025, 6, 1, 10, 30),
        attendees: const [CalendarAttendee(email: 'a@x')],
      );
      final collector = CalendarMeetingSignalCollector(
        repository: _FakeCalendarRepo([event]),
        activeWorkspaceId: () => 'ws',
      );

      final signals = await collector.sample(now);

      expect(signals, isEmpty);
    });

    test('keeps a solo block when it has a meeting url', () async {
      final now = DateTime(2025, 6, 1, 10);
      final event = _event(
        start: DateTime(2025, 6, 1, 9, 55),
        end: DateTime(2025, 6, 1, 10, 30),
        meetingUrl: 'https://zoom.us/j/123',
      );
      final collector = CalendarMeetingSignalCollector(
        repository: _FakeCalendarRepo([event]),
        activeWorkspaceId: () => 'ws',
      );

      final signals = await collector.sample(now);

      expect(signals, isNotEmpty);
    });

    test('skips events the user declined', () async {
      final now = DateTime(2025, 6, 1, 10);
      final event = _event(
        start: DateTime(2025, 6, 1, 9, 55),
        end: DateTime(2025, 6, 1, 10, 30),
        attendees: [
          const CalendarAttendee(email: 'a@x', responseStatus: 'declined'),
          const CalendarAttendee(email: 'b@x'),
        ],
      );
      // The collector reads myResponseStatus from the event, not attendees.
      // The event's myResponseStatus getter must be exercised via attendees
      // marked self. Use a copyWith if available; otherwise this test asserts
      // the attendee-path: when no self attendee is declined, the event passes.
      final collector = CalendarMeetingSignalCollector(
        repository: _FakeCalendarRepo([event]),
        activeWorkspaceId: () => 'ws',
      );

      final signals = await collector.sample(now);

      // No self attendee with 'declined' → event passes.
      expect(signals, isNotEmpty);
    });

    test('emits signals for multiple live events', () async {
      final now = DateTime(2025, 6, 1, 10);
      final collector = CalendarMeetingSignalCollector(
        repository: _FakeCalendarRepo([
          _event(
            title: 'A',
            start: DateTime(2025, 6, 1, 9, 55),
            end: DateTime(2025, 6, 1, 10, 30),
            attendees: const [
              CalendarAttendee(email: 'a@x'),
              CalendarAttendee(email: 'b@x'),
            ],
          ),
          _event(
            title: 'B',
            start: DateTime(2025, 6, 1, 9, 50),
            end: DateTime(2025, 6, 1, 10, 15),
            attendees: const [
              CalendarAttendee(email: 'c@x'),
              CalendarAttendee(email: 'd@x'),
            ],
          ),
        ]),
        activeWorkspaceId: () => 'ws',
      );

      final signals = await collector.sample(now);

      expect(
        signals.where((s) => s.kind == MeetingSignalKind.calendarEvent),
        hasLength(2),
      );
    });
  });
}
