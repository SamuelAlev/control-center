import 'dart:convert';

import 'package:cc_analytics/cc_analytics.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

AnalyticsEnvelope _event(String name, {String? path = '/inbox'}) =>
    AnalyticsEnvelope(
      kind: AnalyticsEnvelopeKind.event,
      name: name,
      path: path,
      appType: AnalyticsAppType.desktop,
      occurredAt: DateTime.utc(2026, 10, 27, 12),
      properties: const {'app_type': 'desktop', 'char_count': 3},
      distinctId: 'abc123',
      locale: 'en_US',
      screen: '1440x900',
    );

void main() {
  test('maps events and screen views to the /api/send payload', () {
    final event = umamiPayload(_event('message_sent'), websiteId: 'site');
    expect(event, {
      'type': 'event',
      'payload': {
        'website': 'site',
        'hostname': 'desktop',
        'url': '/inbox',
        'referrer': '',
        'language': 'en-US',
        'screen': '1440x900',
        'name': 'message_sent',
        'id': 'abc123',
        'timestamp':
            DateTime.utc(2026, 10, 27, 12).millisecondsSinceEpoch ~/ 1000,
        'data': {'app_type': 'desktop', 'char_count': 3},
      },
    });

    final view =
        umamiPayload(
              AnalyticsEnvelope(
                kind: AnalyticsEnvelopeKind.screenView,
                name: 'space',
                path: '/workspaces/:workspaceId/spaces/:spaceId',
                appType: AnalyticsAppType.remote,
                occurredAt: DateTime.utc(2026),
                properties: const {},
              ),
              websiteId: 'site',
            )['payload']!
            as Map;
    expect(view['title'], 'space');
    expect(view.containsKey('name'), isFalse);
    expect(view['hostname'], 'remote');
  });

  test('posts serially, echoes the session cache token', () async {
    final requests = <http.Request>[];
    final sink =
        UmamiAnalyticsSink(
            host: Uri.parse('https://analytics.example/'),
            websiteId: 'site',
            userAgent: 'UA/1',
            client: MockClient((request) async {
              requests.add(request);
              return http.Response(
                jsonEncode({'cache': 'tok-${requests.length}'}),
                200,
              );
            }),
          )
          ..record(_event('a'))
          ..record(_event('b'));
    await sink.flush();
    expect(requests.map((r) => r.url.toString()), [
      'https://analytics.example/api/send',
      'https://analytics.example/api/send',
    ]);
    expect(requests.first.headers['User-Agent'], 'UA/1');
    expect(requests.first.headers.containsKey('x-umami-cache'), isFalse);
    expect(requests.last.headers['x-umami-cache'], 'tok-1');
    expect(sink.queued, 0);
  });

  test('keeps a record across a transient failure, drops a 4xx', () async {
    var calls = 0;
    final sink = UmamiAnalyticsSink(
      host: Uri.parse('https://analytics.example/'),
      websiteId: 'site',
      client: MockClient((request) async {
        calls++;
        return http.Response('', calls == 1 ? 503 : 400);
      }),
    )..record(_event('a'));
    await sink.flush();
    expect(sink.queued, 1, reason: '503 is retried later');
    await sink.flush();
    expect(sink.queued, 0, reason: '400 can never succeed');
    await sink.close(flush: false);
  });

  test('bounds the queue and discards on close without flush', () async {
    final sink = UmamiAnalyticsSink(
      host: Uri.parse('https://analytics.example/'),
      websiteId: 'site',
      maxQueue: 2,
      client: MockClient((_) async => http.Response('', 503)),
    );
    await sink.flush();
    sink
      ..record(_event('a'))
      ..record(_event('b'))
      ..record(_event('c'));
    expect(sink.queued, lessThanOrEqualTo(2));
    await sink.close(flush: false);
    expect(sink.queued, 0);
    sink.record(_event('d'));
    expect(sink.queued, 0);
  });

  test('user agent lets Umami recognize the OS', () {
    expect(
      umamiUserAgent(platform: 'macos', appVersion: '0.0.11'),
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) ControlCenter/0.0.11',
    );
    expect(
      umamiUserAgent(platform: 'windows', appVersion: '1.0.0'),
      contains('Windows NT'),
    );
  });

  test('destination defaults to the Control Center instance', () {
    expect(
      AnalyticsDestination.umamiHost.toString(),
      'https://analytics.alev.dev/',
    );
    expect(
      AnalyticsDestination.umamiWebsiteId,
      '1ce627f2-53d8-49de-b3e1-0fc8daf94951',
    );
  });
}
