import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/model_routing/file_models_dev_source.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:test/test.dart';

Map<String, dynamic> _doc() => {
  'anthropic': {
    'id': 'anthropic',
    'name': 'Anthropic',
    'env': ['ANTHROPIC_API_KEY'],
    'models': {
      'claude-opus-4-5': {'id': 'claude-opus-4-5', 'name': 'Claude Opus 4.5'},
    },
  },
};

void main() {
  late Directory tempDir;

  setUp(() => tempDir = Directory.systemTemp.createTempSync('cc_models_dev_'));
  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  String cachePath() => '${tempDir.path}/models_dev/api.json';

  FileModelsDevSource sourceOver(
    TestHttpClient httpClient, {
    Duration ttl = const Duration(hours: 1),
    bool allowNetwork = true,
  }) => FileModelsDevSource(
    cacheFilePath: cachePath(),
    httpClient: httpClient,
    ttl: ttl,
    allowNetwork: allowNetwork,
  );

  group('load', () {
    test('is disk-only and does not fetch', () async {
      final httpClient = TestHttpClient(
        handler: (request) => httpTextResponse(request, _doc()),
      );
      final source = sourceOver(httpClient);

      expect(await source.load(), isNull);
      expect(httpClient.requests, isEmpty);
    });

    test('returns a previously written cache', () async {
      final file = File(cachePath())..parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode(_doc()));
      final httpClient = TestHttpClient(
        handler: (_) => throw Exception('offline'),
      );
      final source = sourceOver(httpClient);

      final loaded = await source.load();
      expect(loaded?['anthropic'], isA<Map>());
      expect(httpClient.requests, isEmpty);
    });
  });

  group('refresh', () {
    test('fetches, caches, and returns the document', () async {
      final httpClient = TestHttpClient(
        handler: (request) => httpTextResponse(request, _doc()),
      );
      final source = sourceOver(httpClient);

      final json = await source.refresh(force: true);
      expect(json?['anthropic'], isA<Map>());
      expect(httpClient.requests, hasLength(1));
      expect(File(cachePath()).existsSync(), isTrue);
      expect(await source.load(), isNotNull);
    });

    test(
      'skips the network when a fresh cache exists and force is false',
      () async {
        final httpClient = TestHttpClient(
          handler: (request) => httpTextResponse(request, _doc()),
        );
        final source = sourceOver(httpClient);
        await source.refresh(force: true);
        httpClient.requests.clear();

        final json = await source.refresh();
        expect(json?['anthropic'], isA<Map>());
        expect(httpClient.requests, isEmpty);
      },
    );

    test('falls back to a stale cache when the network fails', () async {
      final file = File(cachePath())..parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode(_doc()));
      final httpClient = TestHttpClient(
        handler: (_) => throw Exception('offline'),
      );
      final source = sourceOver(httpClient);

      final json = await source.refresh(force: true);
      expect(json?['anthropic'], isA<Map>());
    });

    test('does not fetch when the network is disallowed', () async {
      final httpClient = TestHttpClient(
        handler: (request) => httpTextResponse(request, _doc()),
      );
      final source = sourceOver(httpClient, allowNetwork: false);

      expect(await source.refresh(force: true), isNull);
      expect(httpClient.requests, isEmpty);
    });

    test('an unreachable catalogue is null, never an error', () async {
      final source = sourceOver(
        TestHttpClient(handler: (_) => throw Exception('offline')),
      );
      expect(await source.refresh(force: true), isNull);
    });
  });
}
