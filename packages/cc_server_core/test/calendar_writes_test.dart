import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event_draft.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event_reschedule.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/google_calendar_server.dart';
import 'package:rhttp/rhttp.dart' show CancelToken;
import 'package:test/test.dart';

const _ws = 'ws-1';
const _mine = 'google:ws-1:user-a:a@example.com';
const _theirs = 'google:ws-1:user-b:b@example.com';

/// Records the Google calls instead of making them.
class _Google extends GoogleCalendarApiClient {
  _Google()
    : super(TestHttpClient(handler: (_) => throw StateError('no network')));

  final inserted = <(String, String, Map<String, dynamic>, bool)>[];
  final deleted = <(String, String, String)>[];
  final patched = <(String, String, List<Map<String, dynamic>>)>[];
  final moved = <(String, String, Map<String, String>, Map<String, String>)>[];

  @override
  Future<GoogleCalendarEvent> patchEventTimes({
    required String accountId,
    required String calendarId,
    required String eventId,
    required Map<String, String> start,
    required Map<String, String> end,
    CancelToken? cancelToken,
  }) async {
    moved.add((accountId, eventId, start, end));
    return GoogleCalendarEvent.fromJson({
      'id': eventId,
      'status': 'confirmed',
      'summary': 'Standup',
      'start': start,
      'end': end,
    });
  }

  @override
  Future<GoogleCalendarEvent> insertEvent({
    required String accountId,
    required String calendarId,
    required Map<String, dynamic> event,
    bool withConference = false,
    CancelToken? cancelToken,
  }) async {
    inserted.add((accountId, calendarId, event, withConference));
    return GoogleCalendarEvent.fromJson({
      'id': 'g-new',
      'status': 'confirmed',
      'summary': event['summary'],
      'start': event['start'],
      'end': event['end'],
      'hangoutLink': withConference ? 'https://meet.google.com/abc' : null,
    });
  }

  @override
  Future<void> deleteEvent({
    required String accountId,
    required String calendarId,
    required String eventId,
    CancelToken? cancelToken,
  }) async => deleted.add((accountId, calendarId, eventId));

  @override
  Future<void> patchEventResponse({
    required String accountId,
    required String calendarId,
    required String eventId,
    required List<Map<String, dynamic>> attendees,
    CancelToken? cancelToken,
  }) async => patched.add((eventId, calendarId, attendees));
}

/// Just enough calendar store for the writes.
class _Store implements CalendarRepository {
  final accounts = <CalendarAccount>[
    const CalendarAccount(
      id: _mine,
      workspaceId: _ws,
      userId: 'user-a',
      providerId: 'google',
      accountEmail: 'a@example.com',
    ),
    const CalendarAccount(
      id: _theirs,
      workspaceId: _ws,
      userId: 'user-b',
      providerId: 'google',
      accountEmail: 'b@example.com',
    ),
  ];
  final sources = <CalendarSource>[
    const CalendarSource(
      workspaceId: _ws,
      accountId: _mine,
      id: 'primary',
      summary: 'Mine',
      primary: true,
      writable: true,
    ),
    const CalendarSource(
      workspaceId: _ws,
      accountId: _mine,
      id: 'holidays',
      summary: 'Holidays',
    ),
  ];
  final events = <CalendarEvent>[];

  @override
  Future<List<CalendarAccount>> getAccounts(String workspaceId) async => [
    for (final a in accounts)
      if (a.workspaceId == workspaceId) a,
  ];

  @override
  Stream<List<CalendarSource>> watchSources(
    String workspaceId,
    String accountId,
  ) => Stream.value([
    for (final s in sources)
      if (s.workspaceId == workspaceId && s.accountId == accountId) s,
  ]);

  @override
  Future<void> upsertEvents(List<CalendarEvent> incoming) async {
    for (final e in incoming) {
      final i = events.indexWhere(
        (x) =>
            x.accountId == e.accountId &&
            x.externalEventId == e.externalEventId,
      );
      if (i < 0) {
        events.add(e);
      } else {
        // Like the DAO: the stored row keeps its id.
        events[i] = _withId(e, events[i].id);
      }
    }
  }

  @override
  Stream<CalendarEvent?> watchEventById(String workspaceId, String eventId) =>
      Stream.value(
        events
            .where((e) => e.workspaceId == workspaceId && e.id == eventId)
            .firstOrNull,
      );

  @override
  Stream<List<CalendarEvent>> watchEventsInRange(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) => Stream.value([
    for (final e in events)
      if (e.workspaceId == workspaceId &&
          e.startTime.isBefore(to) &&
          e.endTime.isAfter(from))
        e,
  ]);

  @override
  Future<void> deleteEventsByExternalIds({
    required String workspaceId,
    required String accountId,
    required String calendarId,
    required Set<String> externalIds,
  }) async => events.removeWhere(
    (e) =>
        e.workspaceId == workspaceId &&
        e.accountId == accountId &&
        e.calendarId == calendarId &&
        externalIds.contains(e.externalEventId),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

CalendarEvent _event(
  String id, {
  String accountId = _mine,
  String calendarId = 'primary',
  String? externalEventId,
  DateTime? start,
  List<CalendarAttendee> attendees = const [],
}) {
  final from = start ?? DateTime.utc(2026, 11, 9, 9);
  return CalendarEvent(
    id: id,
    workspaceId: _ws,
    accountId: accountId,
    externalEventId: externalEventId ?? 'g-$id',
    calendarId: calendarId,
    title: 'Standup',
    startTime: from,
    endTime: from.add(const Duration(minutes: 30)),
    updatedAt: DateTime.utc(2026, 11, 8),
    attendees: attendees,
  );
}

CalendarEvent _withId(CalendarEvent e, String id) => CalendarEvent(
  id: id,
  workspaceId: e.workspaceId,
  accountId: e.accountId,
  externalEventId: e.externalEventId,
  calendarId: e.calendarId,
  title: e.title,
  description: e.description,
  location: e.location,
  startTime: e.startTime,
  endTime: e.endTime,
  isAllDay: e.isAllDay,
  attendees: e.attendees,
  meetingUrl: e.meetingUrl,
  status: e.status,
  recurringEventId: e.recurringEventId,
  updatedAt: e.updatedAt,
);

CalendarEventDraft _draft({
  String accountId = _mine,
  String calendarId = 'primary',
  bool meet = false,
}) => CalendarEventDraft(
  accountId: accountId,
  calendarId: calendarId,
  title: ' Design review ',
  start: DateTime.utc(2026, 11, 10, 14),
  end: DateTime.utc(2026, 11, 10, 15),
  attendeeEmails: const ['Guest@Example.com', 'guest@example.com'],
  addConference: meet,
);

void main() {
  late _Google google;
  late _Store store;
  late ServerCalendarWrites writes;

  setUp(() {
    google = _Google();
    store = _Store();
    writes = ServerCalendarWrites(
      calendarRepository: store,
      apiClient: google,
      clock: () => DateTime.utc(2026, 11, 8),
    );
  });

  group('create', () {
    test('books on Google and stores what Google returned', () async {
      final id = await writes.create(
        workspaceId: _ws,
        userId: 'user-a',
        draft: _draft(meet: true),
      );

      final (account, calendar, resource, withMeet) = google.inserted.single;
      expect(account, _mine);
      expect(calendar, 'primary');
      expect(withMeet, isTrue);
      expect(resource['summary'], 'Design review');
      expect(resource['start'], {'dateTime': '2026-11-10T14:00:00.000Z'});
      expect(resource['attendees'], [
        {'email': 'guest@example.com'},
      ]);
      expect(
        (resource['conferenceData'] as Map)['createRequest'],
        containsPair('conferenceSolutionKey', {'type': 'hangoutsMeet'}),
      );

      final stored = store.events.single;
      expect(stored.id, id);
      expect(stored.externalEventId, 'g-new');
      expect(stored.meetingUrl, 'https://meet.google.com/abc');
    });

    test('an all-day event travels as dates', () async {
      await writes.create(
        workspaceId: _ws,
        userId: 'user-a',
        draft: CalendarEventDraft(
          accountId: _mine,
          calendarId: 'primary',
          title: 'Offsite',
          start: DateTime(2026, 11, 12),
          end: DateTime(2026, 11, 14),
          isAllDay: true,
        ),
      );
      final resource = google.inserted.single.$3;
      expect(resource['start'], {'date': '2026-11-12'});
      expect(resource['end'], {'date': '2026-11-14'});
    });

    test('returns the id a concurrent sync already stored', () async {
      store.events.add(
        _event(
          'synced',
          externalEventId: 'g-new',
          start: DateTime.utc(2026, 11, 10, 14),
        ),
      );
      final id = await writes.create(
        workspaceId: _ws,
        userId: 'user-a',
        draft: _draft(),
      );
      expect(id, 'synced');
      expect(store.events, hasLength(1));
    });

    test("never books on a colleague's calendar", () async {
      await expectLater(
        writes.create(
          workspaceId: _ws,
          userId: 'user-a',
          draft: _draft(accountId: _theirs),
        ),
        throwsA(isA<AuthException>()),
      );
      expect(google.inserted, isEmpty);
    });

    test('refuses an account from another workspace', () async {
      await expectLater(
        writes.create(
          workspaceId: _ws,
          userId: 'user-a',
          draft: _draft(accountId: 'google:ws-2:user-a:a@example.com'),
        ),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      expect(google.inserted, isEmpty);
    });

    test('refuses a calendar the account may only read', () async {
      await expectLater(
        writes.create(
          workspaceId: _ws,
          userId: 'user-a',
          draft: _draft(calendarId: 'holidays'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(google.inserted, isEmpty);
    });
  });

  group('delete', () {
    test('deletes on Google, then locally', () async {
      store.events.add(_event('e1'));
      await writes.delete(workspaceId: _ws, userId: 'user-a', eventId: 'e1');
      expect(google.deleted.single, (_mine, 'primary', 'g-e1'));
      expect(store.events, isEmpty);
    });

    test("never deletes from a colleague's calendar", () async {
      store.events.add(_event('e1', accountId: _theirs));
      await expectLater(
        writes.delete(workspaceId: _ws, userId: 'user-a', eventId: 'e1'),
        throwsA(isA<AuthException>()),
      );
      expect(google.deleted, isEmpty);
      expect(store.events, hasLength(1));
    });

    test('an event from another workspace is not found', () async {
      store.events.add(_event('e1'));
      await expectLater(
        writes.delete(workspaceId: 'ws-2', userId: 'user-a', eventId: 'e1'),
        throwsA(isA<NotFoundException>()),
      );
      expect(google.deleted, isEmpty);
    });

    test('refuses an event on a read-only calendar', () async {
      store.events.add(_event('e1', calendarId: 'holidays'));
      await expectLater(
        writes.delete(workspaceId: _ws, userId: 'user-a', eventId: 'e1'),
        throwsA(isA<ValidationException>()),
      );
      expect(google.deleted, isEmpty);
    });
  });

  group('move', () {
    CalendarEventReschedule to(String id) => CalendarEventReschedule(
      eventId: id,
      start: DateTime.utc(2026, 11, 10, 14),
      end: DateTime.utc(2026, 11, 10, 14, 30),
    );

    test('moves on Google and keeps the local id', () async {
      store.events.add(_event('e1'));
      await writes.move(workspaceId: _ws, userId: 'user-a', move: to('e1'));
      final (account, eventId, start, end) = google.moved.single;
      expect((account, eventId), (_mine, 'g-e1'));
      expect(start, {'dateTime': '2026-11-10T14:00:00.000Z'});
      expect(end, {'dateTime': '2026-11-10T14:30:00.000Z'});
      final stored = store.events.single;
      expect(stored.id, 'e1');
      expect(stored.startTime, DateTime.utc(2026, 11, 10, 14));
    });

    test('an all-day move travels as dates', () async {
      store.events.add(_event('e1'));
      await writes.move(
        workspaceId: _ws,
        userId: 'user-a',
        move: CalendarEventReschedule(
          eventId: 'e1',
          start: DateTime(2026, 11, 12),
          end: DateTime(2026, 11, 14),
          isAllDay: true,
        ),
      );
      final (_, _, start, end) = google.moved.single;
      expect(start, {'date': '2026-11-12'});
      expect(end, {'date': '2026-11-14'});
    });

    test('leaves an invitation where the organizer put it', () async {
      store.events.add(
        _event(
          'e1',
          attendees: const [
            CalendarAttendee(email: 'boss@example.com', organizer: true),
            CalendarAttendee(email: 'a@example.com', self: true),
          ],
        ),
      );
      await expectLater(
        writes.move(workspaceId: _ws, userId: 'user-a', move: to('e1')),
        throwsA(isA<ValidationException>()),
      );
      expect(google.moved, isEmpty);
    });

    test("never moves a colleague's event", () async {
      store.events.add(_event('e1', accountId: _theirs));
      await expectLater(
        writes.move(workspaceId: _ws, userId: 'user-a', move: to('e1')),
        throwsA(isA<AuthException>()),
      );
      expect(google.moved, isEmpty);
    });

    test('an event from another workspace is not found', () async {
      store.events.add(_event('e1'));
      await expectLater(
        writes.move(workspaceId: 'ws-2', userId: 'user-a', move: to('e1')),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('refuses an event on a read-only calendar', () async {
      store.events.add(_event('e1', calendarId: 'holidays'));
      await expectLater(
        writes.move(workspaceId: _ws, userId: 'user-a', move: to('e1')),
        throwsA(isA<ValidationException>()),
      );
      expect(google.moved, isEmpty);
    });
  });

  group('respond', () {
    const invite = [
      CalendarAttendee(email: 'boss@example.com', organizer: true),
      CalendarAttendee(email: 'a@example.com', self: true),
    ];

    test('sends the full roster with only my answer changed', () async {
      store.events.add(_event('e1', attendees: invite));
      await writes.respond(
        workspaceId: _ws,
        userId: 'user-a',
        eventId: 'e1',
        responseStatus: 'accepted',
      );
      final roster = google.patched.single.$3;
      expect(roster.map((a) => a['responseStatus']), [
        'needsAction',
        'accepted',
      ]);
      expect(store.events.single.myResponseStatus, 'accepted');
    });

    test('never answers for a colleague', () async {
      store.events.add(_event('e1', accountId: _theirs, attendees: invite));
      await expectLater(
        writes.respond(
          workspaceId: _ws,
          userId: 'user-a',
          eventId: 'e1',
          responseStatus: 'accepted',
        ),
        throwsA(isA<AuthException>()),
      );
      expect(google.patched, isEmpty);
    });

    test('refuses an answer Google does not know', () async {
      store.events.add(_event('e1', attendees: invite));
      await expectLater(
        writes.respond(
          workspaceId: _ws,
          userId: 'user-a',
          eventId: 'e1',
          responseStatus: 'maybe',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(google.patched, isEmpty);
    });
  });
}
