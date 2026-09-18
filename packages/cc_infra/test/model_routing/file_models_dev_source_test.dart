import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/model_routing/file_models_dev_source.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Object? Function(RequestOptions) handler;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    final result = handler(options);
    if (result is Exception) {
      throw result;
    }
    return ResponseBody.fromString(
      result is String ? result : jsonEncode(result),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

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
    _FakeAdapter adapter, {
    Duration ttl = const Duration(hours: 1),
    bool allowNetwork = true,
  }) => FileModelsDevSource(
    cacheFilePath: cachePath(),
    dio: Dio()..httpClientAdapter = adapter,
    ttl: ttl,
    allowNetwork: allowNetwork,
  );

  group('load', () {
    test('is disk-only and does not fetch', () async {
      final adapter = _FakeAdapter((_) => _doc());
      final source = sourceOver(adapter);

      expect(await source.load(), isNull);
      expect(adapter.calls, 0);
    });

    test('returns a previously written cache', () async {
      final file = File(cachePath())..parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode(_doc()));
      final adapter = _FakeAdapter((_) => throw Exception('offline'));
      final source = sourceOver(adapter);

      final loaded = await source.load();
      expect(loaded?['anthropic'], isA<Map>());
      expect(adapter.calls, 0);
    });
  });

  group('refresh', () {
    test('fetches, caches, and returns the document', () async {
      final adapter = _FakeAdapter((_) => _doc());
      final source = sourceOver(adapter);

      final json = await source.refresh(force: true);
      expect(json?['anthropic'], isA<Map>());
      expect(adapter.calls, 1);
      expect(File(cachePath()).existsSync(), isTrue);
      expect(await source.load(), isNotNull);
    });

    test('skips the network when a fresh cache exists and force is false', () async {
      final adapter = _FakeAdapter((_) => _doc());
      final source = sourceOver(adapter);
      await source.refresh(force: true);
      adapter.calls = 0;

      final json = await source.refresh();
      expect(json?['anthropic'], isA<Map>());
      expect(adapter.calls, 0);
    });

    test('falls back to a stale cache when the network fails', () async {
      final file = File(cachePath())..parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode(_doc()));
      final adapter = _FakeAdapter((_) => Exception('offline'));
      final source = sourceOver(adapter);

      final json = await source.refresh(force: true);
      expect(json?['anthropic'], isA<Map>());
    });

    test('does not fetch when the network is disallowed', () async {
      final adapter = _FakeAdapter((_) => _doc());
      final source = sourceOver(adapter, allowNetwork: false);

      expect(await source.refresh(force: true), isNull);
      expect(adapter.calls, 0);
    });

    test('an unreachable catalogue is null, never an error', () async {
      final source = sourceOver(_FakeAdapter((_) => Exception('offline')));
      expect(await source.refresh(force: true), isNull);
    });
  });
}
