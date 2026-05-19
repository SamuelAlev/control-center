import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/model_routing/file_models_dev_source.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final Object? Function(RequestOptions) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final result = handler(options);
    if (result is ResponseBody) {
      return result;
    }
    if (result is Exception) {
      throw result;
    }
    return ResponseBody.fromString(
      result == null ? '' : jsonEncode(result),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Object _networkOk(Map<String, dynamic> json) => ResponseBody.fromString(
  jsonEncode(json),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Dio _dio(Object? Function(RequestOptions) handler) =>
    Dio()..httpClientAdapter = _FakeAdapter(handler);

const _sampleJson = <String, dynamic>{
  'models': [
    {'id': 'gpt-4', 'name': 'GPT-4'},
  ],
};

void main() {
  late Directory temp;
  late String cachePath;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('models_dev_test_');
    cachePath = '${temp.path}/cache.json';
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  group('FileModelsDevSource.load', () {
    test('returns the fresh disk cache when present', () async {
      File(cachePath).writeAsStringSync(jsonEncode(_sampleJson));
      final source = FileModelsDevSource(
        cacheFilePath: cachePath,
        dio: _dio((_) => throw Exception('should not fetch')),
      );

      final result = await source.load();

      expect(result, isNotNull);
      expect(result!['models'], isA<List>());
    });

    test('fetches from network when cache is stale', () async {
      // Write a stale cache file (old mtime).
      final f = File(cachePath)..writeAsStringSync(jsonEncode({'old': true}));
      // Set mtime to an hour ago.
      f.setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 1)));
      final source = FileModelsDevSource(
        cacheFilePath: cachePath,
        dio: _dio((_) => _networkOk(_sampleJson)),
        ttl: const Duration(minutes: 5),
      );

      final result = await source.load();

      expect(result, isNotNull);
      expect(result!['models'], isA<List>());
      // Network response was written to cache.
      final written =
          jsonDecode(File(cachePath).readAsStringSync()) as Map<String, dynamic>;
      expect(written['models'], isA<List>());
    });

    test('falls back to stale cache when network fails', () async {
      final f = File(cachePath)..writeAsStringSync(jsonEncode({'stale': 1}));
      f.setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 1)));
      final source = FileModelsDevSource(
        cacheFilePath: cachePath,
        dio: _dio(
          (_) => DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
      );

      final result = await source.load();

      expect(result, isNotNull);
      expect(result!['stale'], 1);
    });

    test(
      'falls back to bundled snapshot when no cache and network fails',
      () async {
        final source = FileModelsDevSource(
          cacheFilePath: cachePath,
          dio: _dio(
            (_) => DioException(
              requestOptions: RequestOptions(path: '/'),
              type: DioExceptionType.connectionTimeout,
            ),
          ),
        );

        final result = await source.load();

        // Bundled snapshot is non-empty.
        expect(result, isNotNull);
        expect(result!.isNotEmpty, isTrue);
      },
    );

    test('does not fetch when allowNetwork is false', () async {
      final source = FileModelsDevSource(
        cacheFilePath: cachePath,
        dio: _dio((_) => throw Exception('should not fetch')),
        allowNetwork: false,
      );

      final result = await source.load();

      // Falls back to bundled snapshot.
      expect(result, isNotNull);
    });

    test('network response of an empty map is ignored', () async {
      final source = FileModelsDevSource(
        cacheFilePath: cachePath,
        dio: _dio((_) => _networkOk(<String, dynamic>{})),
      );

      final result = await source.load();

      // Empty map is not cached; falls back to bundled snapshot.
      expect(result, isNotNull);
      expect(result!.isNotEmpty, isTrue);
    });

    test('corrupt cache file is ignored', () async {
      File(cachePath).writeAsStringSync('not json');
      final source = FileModelsDevSource(
        cacheFilePath: cachePath,
        dio: _dio(
          (_) => DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
      );

      final result = await source.load();

      // Corrupt cache ignored; falls back to bundled snapshot.
      expect(result, isNotNull);
    });

    test('cache containing a non-map is ignored', () async {
      File(cachePath).writeAsStringSync(jsonEncode([1, 2, 3]));
      final source = FileModelsDevSource(
        cacheFilePath: cachePath,
        dio: _dio(
          (_) => DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
      );

      final result = await source.load();

      expect(result, isNotNull);
    });
  });

  group('FileModelsDevSource.refresh', () {
    test('returns fresh cache when not forced', () async {
      File(cachePath).writeAsStringSync(jsonEncode(_sampleJson));
      final source = FileModelsDevSource(
        cacheFilePath: cachePath,
        dio: _dio((_) => throw Exception('should not fetch')),
      );

      final result = await source.refresh();

      expect(result, isNotNull);
      expect(result!['models'], isA<List>());
    });

    test('force=true bypasses the cache and fetches', () async {
      File(cachePath).writeAsStringSync(jsonEncode({'old': true}));
      final source = FileModelsDevSource(
        cacheFilePath: cachePath,
        dio: _dio((_) => _networkOk(_sampleJson)),
      );

      final result = await source.refresh(force: true);

      expect(result, isNotNull);
      expect(result!['models'], isA<List>());
    });

    test(
      'falls back to bundled snapshot on network failure with no cache',
      () async {
        final source = FileModelsDevSource(
          cacheFilePath: cachePath,
          dio: _dio(
            (_) => DioException(
              requestOptions: RequestOptions(path: '/'),
              type: DioExceptionType.connectionTimeout,
            ),
          ),
        );

        final result = await source.refresh(force: true);

        expect(result, isNotNull);
      },
    );
  });

  group('FileModelsDevSource.bundledSnapshot', () {
    test('returns a non-empty map', () {
      final source = FileModelsDevSource(
        cacheFilePath: cachePath,
        allowNetwork: false,
      );
      expect(source.bundledSnapshot.isNotEmpty, isTrue);
    });
  });
}
