import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/google_calendar_api_client.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhttp/rhttp.dart';

/// Routes each request through its handler with a 0-based call index so
/// paginated responses can be varied per call.
class _RecordingClient {
  _RecordingClient(
    FutureOr<HttpResponse> Function(HttpRequest request, int callIndex) handler,
  ) : fake = TestHttpClient(handler: (request) => handler(request, _calls++));

  final TestHttpClient fake;
  int _calls = 0;

  List<HttpRequest> get requests => fake.requests;
}

GoogleCalendarApiClient _client(_RecordingClient recording) =>
    GoogleCalendarApiClient(recording.fake);

void main() {
  group('GoogleCalendarApiClient.listEvents', () {
    test('follows nextPageToken and concatenates pages', () async {
      final recording = _RecordingClient((request, i) {
        if (i == 0) {
          return httpTextResponse(request, {
            'items': [
              {'id': 'a', 'status': 'confirmed', 'start': {}, 'end': {}},
            ],
            'nextPageToken': 'page-2',
          });
        }
        return httpTextResponse(request, {
          'items': [
            {'id': 'b', 'status': 'confirmed', 'start': {}, 'end': {}},
          ],
        });
      });
      final client = _client(recording);

      final events = await client.listEvents(
        accountId: 'acc-1',
        timeMin: DateTime.utc(2026, 6, 1),
        timeMax: DateTime.utc(2026, 7, 1),
      );

      expect(events.map((e) => e.id), ['a', 'b']);
      expect(recording.requests, hasLength(2));
      // Second request carries the page token.
      expect(recording.requests[1].query!['pageToken'], 'page-2');
    });

    test('sends singleEvents, orderBy and RFC3339 time bounds', () async {
      final recording = _RecordingClient(
        (request, callIndex) => httpTextResponse(request, {'items': []}),
      );
      final client = _client(recording);

      await client.listEvents(
        accountId: 'acc-1',
        timeMin: DateTime.utc(2026, 6, 1, 8),
        timeMax: DateTime.utc(2026, 6, 30, 8),
      );

      final request = recording.requests.single;
      // The request carries the account id so the auth interceptor can attach
      // (and refresh) the right account's token.
      expect(request.additionalData['googleAccountId'], 'acc-1');
      final qp = request.query!;
      expect(qp['singleEvents'], 'true');
      expect(qp['orderBy'], 'startTime');
      expect(qp['timeMin'], '2026-06-01T08:00:00.000Z');
      expect(qp['timeMax'], '2026-06-30T08:00:00.000Z');
    });

    test('maps a 401 to NetworkException(auth_error)', () async {
      final recording = _RecordingClient(
        (request, callIndex) =>
            httpTextResponse(request, {'error': 'x'}, statusCode: 401),
      );
      final client = _client(recording);

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
      final recording = _RecordingClient(
        (request, callIndex) => throw RhttpCancelException(request),
      );
      final client = _client(recording);
      final token = CancelToken();

      await expectLater(
        client.listEvents(
          accountId: 'acc-1',
          timeMin: DateTime.utc(2026, 6, 1),
          timeMax: DateTime.utc(2026, 7, 1),
          cancelToken: token,
        ),
        throwsA(isA<RhttpCancelException>()),
      );
    });
  });

  group('GoogleCalendarApiClient.listCalendars', () {
    test('decodes calendar list entries', () async {
      final recording = _RecordingClient(
        (request, callIndex) => httpTextResponse(request, {
          'items': [
            {'id': 'primary', 'summary': 'Me', 'primary': true},
            {'id': 'team@x.com', 'summary': 'Team'},
          ],
        }),
      );
      final client = _client(recording);

      final calendars = await client.listCalendars(accountId: 'acc-1');
      expect(calendars.map((c) => c.id), ['primary', 'team@x.com']);
      expect(calendars.first.primary, isTrue);
    });
  });
}
