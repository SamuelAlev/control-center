import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_infra/src/network/klipy_api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Exercises [KlipyApiClient] — the server-side GIF client. Pure response
/// parsing over an injectable [Dio]: pins the request path + query params, the
/// nested `data.data` array flattening and the HD-vs-SD GIF url selection.
void main() {
  late RecordingAdapter adapter;
  late KlipyApiClient client;

  setUp(() {
    adapter = RecordingAdapter();
    client = KlipyApiClient(
      appKey: 'APPKEY',
      dio: Dio()..httpClientAdapter = adapter,
    );
  });

  test('isConfigured reflects the app key', () {
    expect(KlipyApiClient(appKey: 'k', dio: Dio()).isConfigured, isTrue);
    expect(KlipyApiClient(appKey: '', dio: Dio()).isConfigured, isFalse);
  });

  group('search', () {
    test(
      'GETs the search endpoint with query/per_page/format_filter',
      () async {
        adapter.nextJson({
          'data': {
            'data': [
              {
                'id': 1,
                'file': {
                  'sm': {
                    'gif': {'url': 'sm.gif', 'width': 100, 'height': 80},
                  },
                  'hd': {
                    'gif': {'url': 'hd.gif', 'width': 200, 'height': 160},
                  },
                },
              },
              {
                'id': 2,
                'file': {
                  'sm': {
                    'webp': {'url': 'sm.webp', 'width': 10, 'height': 8},
                  },
                },
              },
            ],
          },
        });
        final results = await client.search('cats');
        final req = adapter.requests.single;
        expect(req.path, '/api/v1/APPKEY/gifs/search');
        expect(req.queryParameters['q'], 'cats');
        expect(req.queryParameters['per_page'], 30);
        expect(req.queryParameters['format_filter'], 'gif');

        expect(results, hasLength(2));
        // HD preferred for the GIF url.
        expect(results[0].id, 1);
        expect(results[0].url, 'hd.gif');
        expect(results[0].width, 200);
        expect(results[0].height, 160);
        // Preview prefers sm gif.
        expect(results[0].previewUrl, 'sm.gif');
        // Second item: only sm webp → url falls back to sm webp.
        expect(results[1].url, 'sm.webp');
        expect(results[1].previewUrl, 'sm.webp');
      },
    );

    test('returns empty when the nested data array is absent', () async {
      adapter.nextJson({'data': <String, dynamic>{}});
      expect(await client.search('x'), isEmpty);

      adapter.nextJson(<String, dynamic>{});
      expect(await client.search('x'), isEmpty);
    });
  });

  group('trending', () {
    test('GETs the trending endpoint', () async {
      adapter.nextJson({
        'data': {
          'data': [
            {
              'id': '9',
              'file': {
                'sm': {
                  'gif': {'url': 'g.gif', 'width': 1, 'height': 1},
                },
              },
            },
          ],
        },
      });
      final results = await client.trending();
      expect(adapter.requests.single.path, '/api/v1/APPKEY/gifs/trending');
      expect(adapter.requests.single.queryParameters['format_filter'], 'gif');
      expect(results.single.id, 9);
      expect(results.single.url, 'g.gif');
    });

    test('returns empty when data.data is null', () async {
      adapter.nextJson({
        'data': {'data': null},
      });
      expect(await client.trending(), isEmpty);
    });
  });
}

class RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Object _nextBody = <String, dynamic>{};
  void nextJson(Object body) => _nextBody = body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(_nextBody),
      200,
      headers: const {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
