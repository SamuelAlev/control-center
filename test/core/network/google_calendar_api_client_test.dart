import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/google_calendar_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canned-response adapter routing each `fetch` through [handler] with a
/// 0-based call index so paginated responses can be varied per call.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options, int callIndex) handler;
  final List<RequestOptions> requests = [];
  int _calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options, _calls++);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

GoogleCalendarApiClient _client(_FakeAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return GoogleCalendarApiClient(dio);
}

void main() {
  group('GoogleCalendarApiClient.listEvents', () {
    test('follows nextPageToken and concatenates pages', () async {
      final adapter = _FakeAdapter((options, i) {
        if (i == 0) {
          return _json({
            'items': [
              {'id': 'a', 'status': 'confirmed', 'start': {}, 'end': {}},
            ],
            'nextPageToken': 'page-2',
          });
        }
        return _json({
          'items': [
            {'id': 'b', 'status': 'confirmed', 'start': {}, 'end': {}},
          ],
        });
      });
      final client = _client(adapter);

      final events = await client.listEvents(
        accountId: 'acc-1',
        timeMin: DateTime.utc(2026, 6, 1),
        timeMax: DateTime.utc(2026, 7, 1),
      );

      expect(events.map((e) => e.id), ['a', 'b']);
      expect(adapter.requests, hasLength(2));
      // Second request carries the page token.
      expect(adapter.requests[1].uri.queryParameters['pageToken'], 'page-2');
    });

    test('sends singleEvents, orderBy and RFC3339 time bounds', () async {
      final adapter = _FakeAdapter((options, callIndex) => _json({'items': []}));
      final client = _client(adapter);

      await client.listEvents(
        accountId: 'acc-1',
        timeMin: DateTime.utc(2026, 6, 1, 8),
        timeMax: DateTime.utc(2026, 6, 30, 8),
      );

      final request = adapter.requests.single;
      // The request carries the account id so the auth interceptor can attach
      // (and refresh) the right account's token.
      expect(request.extra['googleAccountId'], 'acc-1');
      final qp = request.uri.queryParameters;
      expect(qp['singleEvents'], 'true');
      expect(qp['orderBy'], 'startTime');
      expect(qp['timeMin'], '2026-06-01T08:00:00.000Z');
      expect(qp['timeMax'], '2026-06-30T08:00:00.000Z');
    });

    test('maps a 401 to NetworkException(auth_error)', () async {
      final adapter = _FakeAdapter((options, callIndex) => _json({'error': 'x'}, status: 401));
      final client = _client(adapter);

      await expectLater(
        client.listEvents(
          accountId: 'acc-1',
          timeMin: DateTime.utc(2026, 6, 1),
          timeMax: DateTime.utc(2026, 7, 1),
        ),
        throwsA(
          isA<NetworkException>().having((e) => e.code, 'code', 'auth_error'),
        ),
      );
    });

    test('rethrows on cancellation', () async {
      final adapter = _FakeAdapter((options, callIndex) => _json({'items': []}));
      final client = _client(adapter);
      final token = CancelToken()..cancel('stop');

      await expectLater(
        client.listEvents(
          accountId: 'acc-1',
          timeMin: DateTime.utc(2026, 6, 1),
          timeMax: DateTime.utc(2026, 7, 1),
          cancelToken: token,
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('GoogleCalendarApiClient.listCalendars', () {
    test('decodes calendar list entries', () async {
      final adapter = _FakeAdapter((options, callIndex) => _json({
            'items': [
              {'id': 'primary', 'summary': 'Me', 'primary': true},
              {'id': 'team@x.com', 'summary': 'Team'},
            ],
          }));
      final client = _client(adapter);

      final calendars = await client.listCalendars(accountId: 'acc-1');
      expect(calendars.map((c) => c.id), ['primary', 'team@x.com']);
      expect(calendars.first.primary, isTrue);
    });
  });
}
