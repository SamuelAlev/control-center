import 'dart:convert';

import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:cc_infra/src/git/service_status_service.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Exercises [ServiceStatusService] — the Statuspage summary fetcher
/// (githubstatus.com, status.claude.com, status.openai.com,
/// status.moonshot.cn).
/// Uses a stubbed [Dio] adapter (no live network) to drive the parse path:
/// the raw JSON round-trips through [ServiceStatusService.fetchSummaryJson]
/// and parses into the domain entity via [ServiceStatusService.fetch].
void main() {
  Dio dioWithBody(Map<String, dynamic> body) {
    final dio = Dio();
    dio.httpClientAdapter = _FakeAdapter(body);
    return dio;
  }

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
      final svc = ServiceStatusService(dioWithBody(sampleSummary));
      final json = await svc.fetchSummaryJson();
      expect(json['status'], isA<Map>());
      expect((json['status'] as Map)['indicator'], 'minor');
      expect(json['components'], isA<List>());
    });

    test('returns an empty map when the response body is null', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter(null);
      final svc = ServiceStatusService(dio);
      expect(await svc.fetchSummaryJson(), isEmpty);
    });
  });

  group('ServiceStatusService.fetch', () {
    test('parses the summary into a GitHubServiceStatus', () async {
      final svc = ServiceStatusService(dioWithBody(sampleSummary));
      final status = await svc.fetch();
      expect(status.indicator, GitHubStatusIndicator.minor);
      expect(status.description, 'Minor Service Issue');
      expect(status.components, isNotEmpty);
    });

    test('requests the githubstatus.com summary URL', () async {
      final adapter = _RecordingAdapter(sampleSummary);
      final dio = Dio()..httpClientAdapter = adapter;
      final svc = ServiceStatusService(dio);
      await svc.fetch();
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.path, githubStatusSummaryUrl);
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);
  final Map<String, dynamic>? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) => Future.value(_json(body));

  @override
  void close({bool force = false}) {}
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body);
  final Map<String, dynamic> body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return Future.value(_json(body));
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic>? body) => ResponseBody.fromString(
  body == null ? '' : jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);
