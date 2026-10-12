import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:cc_infra/src/git/service_status_service.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:test/test.dart';

/// Exercises [ServiceStatusService] — the Statuspage summary fetcher
/// (githubstatus.com, status.claude.com, status.openai.com,
/// status.moonshot.cn).
/// Uses a canned transport (no live network) to drive the parse path: the raw
/// JSON round-trips through [ServiceStatusService.fetchSummaryJson] and parses
/// into the domain entity via [ServiceStatusService.fetch].
void main() {
  TestHttpClient clientWithBody(Object? body) =>
      TestHttpClient(handler: (request) => httpTextResponse(request, body));

  const sampleSummary = <String, dynamic>{
    'page': {'id': 'kctbh9vrtdwd', 'name': 'GitHub'},
    'status': {'indicator': 'minor', 'description': 'Minor Service Issue'},
    'components': [
      {
        'id': '8v4l0qpznf4j',
        'name': 'Git Operations',
        'status': 'operational',
        'position': 3,
      },
    ],
  };

  group('ServiceStatusService.fetchSummaryJson', () {
    test('returns the parsed summary map verbatim', () async {
      final svc = ServiceStatusService(clientWithBody(sampleSummary));
      final json = await svc.fetchSummaryJson();
      expect(json['status'], isA<Map>());
      expect((json['status'] as Map)['indicator'], 'minor');
      expect(json['components'], isA<List>());
    });

    test('returns an empty map when the response body is empty', () async {
      final svc = ServiceStatusService(clientWithBody(''));
      expect(await svc.fetchSummaryJson(), isEmpty);
    });
  });

  group('ServiceStatusService.fetch', () {
    test('parses the summary into a GitHubServiceStatus', () async {
      final svc = ServiceStatusService(clientWithBody(sampleSummary));
      final status = await svc.fetch();
      expect(status.indicator, GitHubStatusIndicator.minor);
      expect(status.description, 'Minor Service Issue');
      expect(status.components, isNotEmpty);
    });

    test('requests the githubstatus.com summary URL', () async {
      final client = clientWithBody(sampleSummary);
      final svc = ServiceStatusService(client);
      await svc.fetch();
      expect(client.requests, hasLength(1));
      expect(client.requests.single.url, githubStatusSummaryUrl);
    });
  });
}
