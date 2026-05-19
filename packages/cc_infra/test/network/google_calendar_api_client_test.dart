import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_infra/src/network/google_calendar_api_client.dart';
import 'package:cc_infra/src/network/network_constants.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, {int status = 200}) => ResponseBody.fromString(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

GoogleCalendarApiClient _client(ResponseBody Function(RequestOptions) h) {
  final dio = Dio()..httpClientAdapter = _FakeAdapter(h);
  return GoogleCalendarApiClient(dio);
}

void main() {
  group('GoogleCalendarApiClient.listCalendars', () {
    test('lists calendars from a single page', () async {
      final client = _client(
        (_) => _json({
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
      final client = _client((options) {
        call++;
        if (call == 1) {
          return _json({
            'items': [
              {'id': 'cal-1', 'summary': 'A'},
            ],
            'nextPageToken': 'tok',
          });
        }
        return _json({
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
      final client = _client((_) => _json({}));
      final calendars = await client.listCalendars(accountId: 'acct-1');
      expect(calendars, isEmpty);
    });

    test('drops non-map items', () async {
      final client = _client(
        (_) => _json({
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

    test('stamps the account id as extra on the request', () async {
      RequestOptions? captured;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          captured = options;
          return _json({'items': []});
        });
      final client = GoogleCalendarApiClient(dio);

      await client.listCalendars(accountId: 'my-acct');

      expect(captured!.path, '$googleCalendarApiBaseUrl/users/me/calendarList');
      expect(captured!.extra[googleAccountIdExtraKey], 'my-acct');
    });

    test('maps a DioException to NetworkException', () async {
      final client = _client(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 500,
            data: 'boom',
          ),
        ),
      );
      await expectLater(
        client.listCalendars(accountId: 'acct-1'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('rethrows cancel exceptions unchanged', () async {
      final client = _client(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
        ),
      );
      await expectLater(
        client.listCalendars(accountId: 'acct-1'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('GoogleCalendarApiClient.listEvents', () {
    test('lists events in a window', () async {
      final client = _client(
        (_) => _json({
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
      RequestOptions? captured;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          captured = options;
          return _json({'items': []});
        });
      final client = GoogleCalendarApiClient(dio);

      await client.listEvents(
        accountId: 'acct-1',
        calendarId: 'some.user@example.com',
        timeMin: DateTime.utc(2025, 1, 1),
        timeMax: DateTime.utc(2025, 1, 2),
      );

      // Encoded calendar id appears in the path.
      expect(
        captured!.path,
        contains(Uri.encodeComponent('some.user@example.com')),
      );
    });

    test('passes timeMin/timeMax as ISO8601 UTC', () async {
      RequestOptions? captured;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          captured = options;
          return _json({'items': []});
        });
      final client = GoogleCalendarApiClient(dio);

      await client.listEvents(
        accountId: 'acct-1',
        calendarId: 'primary',
        timeMin: DateTime.utc(2025, 3, 4, 5, 6, 7),
        timeMax: DateTime.utc(2025, 3, 5, 8, 9, 10),
      );

      expect(captured!.queryParameters['timeMin'], '2025-03-04T05:06:07.000Z');
      expect(captured!.queryParameters['timeMax'], '2025-03-05T08:09:10.000Z');
      expect(captured!.queryParameters['singleEvents'], true);
      expect(captured!.queryParameters['orderBy'], 'startTime');
    });

    test('follows nextPageToken across pages', () async {
      var call = 0;
      final client = _client((_) {
        call++;
        if (call == 1) {
          return _json({
            'items': [
              {'id': 'e1', 'summary': 'A'},
            ],
            'nextPageToken': 'tok',
          });
        }
        return _json({
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
      final client = _client((_) => _json({}));
      final events = await client.listEvents(
        accountId: 'acct-1',
        calendarId: 'primary',
        timeMin: DateTime.utc(2025, 1, 1),
        timeMax: DateTime.utc(2025, 1, 2),
      );
      expect(events, isEmpty);
    });

    test('maps a DioException to NetworkException', () async {
      final client = _client(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            data: 'unauthorized',
          ),
        ),
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

  group('GoogleCalendarApiClient.patchEventResponse', () {
    test('PATCHes the attendees array', () async {
      RequestOptions? captured;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          captured = options;
          return _json({});
        });
      final client = GoogleCalendarApiClient(dio);

      await client.patchEventResponse(
        accountId: 'acct-1',
        calendarId: 'primary',
        eventId: 'evt-123',
        attendees: [
          {'email': 'me@example.com', 'responseStatus': 'accepted'},
        ],
      );

      expect(captured!.method, 'PATCH');
      // Path contains URL-encoded calendar + event ids.
      expect(captured!.path, contains('primary'));
      expect(captured!.path, contains('evt-123'));
      expect((captured!.data as Map)['attendees'], hasLength(1));
      expect(captured!.extra[googleAccountIdExtraKey], 'acct-1');
    });

    test('URL-encodes the calendar and event ids', () async {
      RequestOptions? captured;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          captured = options;
          return _json({});
        });
      final client = GoogleCalendarApiClient(dio);

      await client.patchEventResponse(
        accountId: 'acct-1',
        calendarId: 'me@example.com',
        eventId: 'evt with space',
        attendees: const [],
      );

      expect(captured!.path, contains(Uri.encodeComponent('me@example.com')));
      expect(captured!.path, contains(Uri.encodeComponent('evt with space')));
    });

    test('maps a DioException to NetworkException', () async {
      final client = _client(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 403,
            data: 'forbidden',
          ),
        ),
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
}
