import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_infra/src/network/google_calendar_api_client.dart';
import 'package:cc_infra/src/network/network_constants.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

GoogleCalendarApiClient _client(
  FutureOr<HttpResponse> Function(HttpRequest request) handler,
) => GoogleCalendarApiClient(TestHttpClient(handler: handler));

/// A [TestHttpClient] plus the client under test, so a test can assert on the
/// captured request as well as the parsed result.
({GoogleCalendarApiClient client, TestHttpClient fake}) _clientWithFake(
  FutureOr<HttpResponse> Function(HttpRequest request) handler,
) {
  final fake = TestHttpClient(handler: handler);
  return (client: GoogleCalendarApiClient(fake), fake: fake);
}

void main() {
  group('GoogleCalendarApiClient.listCalendars', () {
    test('lists calendars from a single page', () async {
      final client = _client(
        (request) => httpTextResponse(request, {
          'items': [
            {'id': 'cal-1', 'summary': 'Work'},
            {'id': 'cal-2', 'summary': 'Personal'},
          ],
        }),
      );

      final calendars = await client.listCalendars(accountId: 'acct-1');

      expect(calendars.map((c) => c.id), ['cal-1', 'cal-2']);
      expect(calendars.first.summary, 'Work');
    });

    test('follows nextPageToken across pages', () async {
      var call = 0;
      final client = _client((request) {
        call++;
        if (call == 1) {
          return httpTextResponse(request, {
            'items': [
              {'id': 'cal-1', 'summary': 'A'},
            ],
            'nextPageToken': 'tok',
          });
        }
        return httpTextResponse(request, {
          'items': [
            {'id': 'cal-2', 'summary': 'B'},
          ],
        });
      });

      final calendars = await client.listCalendars(accountId: 'acct-1');

      expect(calendars.map((c) => c.id), ['cal-1', 'cal-2']);
      expect(call, 2);
    });

    test('returns empty when items missing', () async {
      final client = _client((request) => httpTextResponse(request, {}));
      final calendars = await client.listCalendars(accountId: 'acct-1');
      expect(calendars, isEmpty);
    });

    test('drops non-map items', () async {
      final client = _client(
        (request) => httpTextResponse(request, {
          'items': [
            'str',
            {'id': 'x', 'summary': 'x'},
            42,
          ],
        }),
      );
      final calendars = await client.listCalendars(accountId: 'acct-1');
      expect(calendars, hasLength(1));
      expect(calendars.single.id, 'x');
    });

    test('stamps the account id as metadata on the request', () async {
      final (:client, :fake) = _clientWithFake(
        (request) => httpTextResponse(request, {'items': []}),
      );

      await client.listCalendars(accountId: 'my-acct');

      final request = fake.requests.single;
      expect(
        httpRequestUri(request).toString(),
        '$googleCalendarApiBaseUrl/users/me/calendarList',
      );
      expect(request.additionalData[googleAccountIdExtraKey], 'my-acct');
    });

    test('maps a failed status to NetworkException', () async {
      final client = _client(
        (request) => httpTextResponse(request, 'boom', statusCode: 500),
      );
      await expectLater(
        client.listCalendars(accountId: 'acct-1'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('rethrows cancellations unchanged', () async {
      final client = _client((request) => throw RhttpCancelException(request));
      await expectLater(
        client.listCalendars(accountId: 'acct-1'),
        throwsA(isA<RhttpCancelException>()),
      );
    });
  });

  group('GoogleCalendarApiClient.listEvents', () {
    test('lists events in a window', () async {
      final client = _client(
        (request) => httpTextResponse(request, {
          'items': [
            {
              'id': 'e1',
              'summary': 'Meeting',
              'start': {'dateTime': '2025-01-01T10:00:00Z'},
              'end': {'dateTime': '2025-01-01T11:00:00Z'},
            },
          ],
        }),
      );

      final events = await client.listEvents(
        accountId: 'acct-1',
        calendarId: 'primary',
        timeMin: DateTime.utc(2025, 1, 1),
        timeMax: DateTime.utc(2025, 1, 31),
      );

      expect(events, hasLength(1));
      expect(events.first.id, 'e1');
      expect(events.first.summary, 'Meeting');
    });

    test('URL-encodes the calendar id', () async {
      final (:client, :fake) = _clientWithFake(
        (request) => httpTextResponse(request, {'items': []}),
      );

      await client.listEvents(
        accountId: 'acct-1',
        calendarId: 'some.user@example.com',
        timeMin: DateTime.utc(2025, 1, 1),
        timeMax: DateTime.utc(2025, 1, 2),
      );

      // Encoded calendar id appears in the path.
      expect(
        httpRequestUri(fake.requests.single).path,
        contains(Uri.encodeComponent('some.user@example.com')),
      );
    });

    test('passes timeMin/timeMax as ISO8601 UTC', () async {
      final (:client, :fake) = _clientWithFake(
        (request) => httpTextResponse(request, {'items': []}),
      );

      await client.listEvents(
        accountId: 'acct-1',
        calendarId: 'primary',
        timeMin: DateTime.utc(2025, 3, 4, 5, 6, 7),
        timeMax: DateTime.utc(2025, 3, 5, 8, 9, 10),
      );

      final query = fake.requests.single.query!;
      expect(query['timeMin'], '2025-03-04T05:06:07.000Z');
      expect(query['timeMax'], '2025-03-05T08:09:10.000Z');
      expect(query['singleEvents'], 'true');
      expect(query['orderBy'], 'startTime');
    });

    test('follows nextPageToken across pages', () async {
      var call = 0;
      final client = _client((request) {
        call++;
        if (call == 1) {
          return httpTextResponse(request, {
            'items': [
              {'id': 'e1', 'summary': 'A'},
            ],
            'nextPageToken': 'tok',
          });
        }
        return httpTextResponse(request, {
          'items': [
            {'id': 'e2', 'summary': 'B'},
          ],
        });
      });

      final events = await client.listEvents(
        accountId: 'acct-1',
        calendarId: 'primary',
        timeMin: DateTime.utc(2025, 1, 1),
        timeMax: DateTime.utc(2025, 1, 2),
      );

      expect(events.map((e) => e.id), ['e1', 'e2']);
      expect(call, 2);
    });

    test('returns empty when items absent', () async {
      final client = _client((request) => httpTextResponse(request, {}));
      final events = await client.listEvents(
        accountId: 'acct-1',
        calendarId: 'primary',
        timeMin: DateTime.utc(2025, 1, 1),
        timeMax: DateTime.utc(2025, 1, 2),
      );
      expect(events, isEmpty);
    });

    test('maps a 401 to NetworkException', () async {
      final client = _client(
        (request) => httpTextResponse(request, 'unauthorized', statusCode: 401),
      );
      await expectLater(
        client.listEvents(
          accountId: 'acct-1',
          calendarId: 'primary',
          timeMin: DateTime.utc(2025, 1, 1),
          timeMax: DateTime.utc(2025, 1, 2),
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('GoogleCalendarApiClient.listEventsSync', () {
    test('a 410 means the sync token expired', () async {
      final client = _client(
        (request) => httpTextResponse(request, 'gone', statusCode: 410),
      );
      await expectLater(
        client.listEventsSync(accountId: 'acct-1', syncToken: 'tok'),
        throwsA(isA<CalendarSyncTokenExpired>()),
      );
    });

    test('an expired token is presented instead of the window', () async {
      final (:client, :fake) = _clientWithFake(
        (request) => httpTextResponse(request, {'items': []}),
      );

      await client.listEventsSync(
        accountId: 'acct-1',
        calendarId: 'primary',
        timeMin: DateTime.utc(2025, 1, 1),
        timeMax: DateTime.utc(2025, 1, 2),
        syncToken: 'tok-1',
      );

      final query = fake.requests.single.query!;
      expect(query['syncToken'], 'tok-1');
      expect(query.containsKey('timeMin'), isFalse);
      expect(query.containsKey('timeMax'), isFalse);
    });

    test('returns the nextSyncToken from the final page', () async {
      final client = _client(
        (request) => httpTextResponse(request, {
          'items': [
            {'id': 'e1', 'summary': 'A'},
          ],
          'nextSyncToken': 'tok-2',
        }),
      );
      final result = await client.listEventsSync(
        accountId: 'acct-1',
        timeMin: DateTime.utc(2025, 1, 1),
        timeMax: DateTime.utc(2025, 1, 2),
      );
      expect(result.events.map((e) => e.id), ['e1']);
      expect(result.nextSyncToken, 'tok-2');
    });
  });

  group('GoogleCalendarApiClient.patchEventResponse', () {
    test('PATCHes the attendees array', () async {
      final (:client, :fake) = _clientWithFake(
        (request) => httpTextResponse(request, {}),
      );

      await client.patchEventResponse(
        accountId: 'acct-1',
        calendarId: 'primary',
        eventId: 'evt-123',
        attendees: [
          {'email': 'me@example.com', 'responseStatus': 'accepted'},
        ],
      );

      final request = fake.requests.single;
      expect(request.method.value, 'PATCH');
      // Path contains URL-encoded calendar + event ids.
      expect(httpRequestUri(request).path, contains('primary'));
      expect(httpRequestUri(request).path, contains('evt-123'));
      final body = request.body! as HttpBodyJson;
      expect((body.json as Map)['attendees'], hasLength(1));
      expect(request.additionalData[googleAccountIdExtraKey], 'acct-1');
    });

    test('URL-encodes the calendar and event ids', () async {
      final (:client, :fake) = _clientWithFake(
        (request) => httpTextResponse(request, {}),
      );

      await client.patchEventResponse(
        accountId: 'acct-1',
        calendarId: 'me@example.com',
        eventId: 'evt with space',
        attendees: const [],
      );

      final path = httpRequestUri(fake.requests.single).path;
      expect(path, contains(Uri.encodeComponent('me@example.com')));
      expect(path, contains(Uri.encodeComponent('evt with space')));
    });

    test('maps a failed status to NetworkException', () async {
      final client = _client(
        (request) => httpTextResponse(request, 'forbidden', statusCode: 403),
      );
      await expectLater(
        client.patchEventResponse(
          accountId: 'acct-1',
          calendarId: 'primary',
          eventId: 'e',
          attendees: const [],
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('GoogleCalendarApiClient.patchEventResponse notifies', () {
    test('tells the organizer about the answer', () async {
      final (:client, :fake) = _clientWithFake(
        (request) => httpTextResponse(request, {}),
      );
      await client.patchEventResponse(
        accountId: 'acct-1',
        calendarId: 'primary',
        eventId: 'evt-1',
        attendees: const [],
      );
      expect(
        httpRequestUri(fake.requests.single).queryParameters['sendUpdates'],
        'all',
      );
    });
  });

  group('GoogleCalendarApiClient.patchEventTimes', () {
    test('PATCHes only the times and tells the guests', () async {
      final (:client, :fake) = _clientWithFake(
        (request) => httpTextResponse(request, {
          'id': 'evt-1',
          'start': {'dateTime': '2026-11-17T18:45:00Z'},
          'end': {'dateTime': '2026-11-17T19:45:00Z'},
        }),
      );

      final event = await client.patchEventTimes(
        accountId: 'acct-1',
        calendarId: 'primary',
        eventId: 'evt/1',
        start: const {'dateTime': '2026-11-17T18:45:00.000Z'},
        end: const {'dateTime': '2026-11-17T19:45:00.000Z'},
      );

      final request = fake.requests.single;
      final uri = httpRequestUri(request);
      expect(request.method.value, 'PATCH');
      expect(uri.path, endsWith('/events/${Uri.encodeComponent('evt/1')}'));
      expect(uri.queryParameters['sendUpdates'], 'all');
      expect((request.body! as HttpBodyJson).json, {
        'start': {'dateTime': '2026-11-17T18:45:00.000Z'},
        'end': {'dateTime': '2026-11-17T19:45:00.000Z'},
      });
      expect(request.additionalData[googleAccountIdExtraKey], 'acct-1');
      expect(event.start.resolved, DateTime.utc(2026, 11, 17, 18, 45));
    });
  });

  group('GoogleCalendarApiClient.insertEvent', () {
    test('POSTs the resource and parses what Google stored', () async {
      final (:client, :fake) = _clientWithFake(
        (request) => httpTextResponse(request, {
          'id': 'evt-new',
          'summary': 'Review',
          'start': {'dateTime': '2026-11-10T14:00:00Z'},
          'end': {'dateTime': '2026-11-10T15:00:00Z'},
        }),
      );

      final event = await client.insertEvent(
        accountId: 'acct-1',
        calendarId: 'me@example.com',
        event: const {'summary': 'Review'},
      );

      final request = fake.requests.single;
      final uri = httpRequestUri(request);
      expect(request.method.value, 'POST');
      expect(uri.path, endsWith('/events'));
      expect(uri.path, contains(Uri.encodeComponent('me@example.com')));
      expect(uri.queryParameters['sendUpdates'], 'all');
      expect(uri.queryParameters, isNot(contains('conferenceDataVersion')));
      expect((request.body! as HttpBodyJson).json, {'summary': 'Review'});
      expect(request.additionalData[googleAccountIdExtraKey], 'acct-1');
      expect(event.id, 'evt-new');
    });

    test('asks for conference data only with a Meet request', () async {
      final (:client, :fake) = _clientWithFake(
        (request) => httpTextResponse(request, {'id': 'evt-new'}),
      );
      await client.insertEvent(
        accountId: 'acct-1',
        calendarId: 'primary',
        event: const {},
        withConference: true,
      );
      expect(
        httpRequestUri(
          fake.requests.single,
        ).queryParameters['conferenceDataVersion'],
        '1',
      );
    });

    test('maps a refusal to NetworkException', () async {
      final client = _client(
        (request) => httpTextResponse(request, 'forbidden', statusCode: 403),
      );
      await expectLater(
        client.insertEvent(
          accountId: 'acct-1',
          calendarId: 'primary',
          event: const {},
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('GoogleCalendarApiClient.deleteEvent', () {
    test('DELETEs the event and notifies guests', () async {
      final (:client, :fake) = _clientWithFake(
        (request) => httpTextResponse(request, '', statusCode: 204),
      );
      await client.deleteEvent(
        accountId: 'acct-1',
        calendarId: 'primary',
        eventId: 'evt with space',
      );
      final request = fake.requests.single;
      final uri = httpRequestUri(request);
      expect(request.method.value, 'DELETE');
      expect(uri.path, contains(Uri.encodeComponent('evt with space')));
      expect(uri.queryParameters['sendUpdates'], 'all');
    });

    for (final status in [404, 410]) {
      test(
        'an event Google already forgot ($status) counts as deleted',
        () async {
          final client = _client(
            (request) => httpTextResponse(request, 'gone', statusCode: status),
          );
          await client.deleteEvent(
            accountId: 'acct-1',
            calendarId: 'primary',
            eventId: 'evt-1',
          );
        },
      );
    }

    test('maps any other refusal to NetworkException', () async {
      final client = _client(
        (request) => httpTextResponse(request, 'forbidden', statusCode: 403),
      );
      await expectLater(
        client.deleteEvent(
          accountId: 'acct-1',
          calendarId: 'primary',
          eventId: 'evt-1',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
