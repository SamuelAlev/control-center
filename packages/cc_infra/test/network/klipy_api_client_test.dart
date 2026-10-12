import 'package:cc_infra/src/network/klipy_api_client.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// Exercises [KlipyApiClient] — the server-side GIF client. Pure response
/// parsing over an injectable [RhttpClient]: pins the request path + query
/// params, the nested `data.data` array flattening and the HD-vs-SD GIF url
/// selection.
void main() {
  late TestHttpClient fake;
  late KlipyApiClient client;
  const baseUrl = 'https://api.klipy.com';

  Object nextBody = <String, dynamic>{};

  setUp(() {
    nextBody = <String, dynamic>{};
    fake = TestHttpClient(
      settings: const ClientSettings(baseUrl: baseUrl),
      handler: (request) => httpTextResponse(request, nextBody),
    );
    client = KlipyApiClient(appKey: 'APPKEY', httpClient: fake);
  });

  test('isConfigured reflects the app key', () {
    expect(KlipyApiClient(appKey: 'k', httpClient: fake).isConfigured, isTrue);
    expect(KlipyApiClient(appKey: '', httpClient: fake).isConfigured, isFalse);
  });

  group('search', () {
    test(
      'GETs the search endpoint with query/per_page/format_filter',
      () async {
        nextBody = {
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
        };
        final results = await client.search('cats');
        final req = fake.requests.single;
        expect(httpRequestUri(req).path, '/api/v1/APPKEY/gifs/search');
        final qp = req.query!;
        expect(qp['q'], 'cats');
        expect(qp['per_page'], '30');
        expect(qp['format_filter'], 'gif');

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
      nextBody = {'data': <String, dynamic>{}};
      expect(await client.search('x'), isEmpty);

      nextBody = <String, dynamic>{};
      expect(await client.search('x'), isEmpty);
    });
  });

  group('trending', () {
    test('GETs the trending endpoint', () async {
      nextBody = {
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
      };
      final results = await client.trending();
      final req = fake.requests.single;
      expect(httpRequestUri(req).path, '/api/v1/APPKEY/gifs/trending');
      expect(req.query!['format_filter'], 'gif');
      expect(results.single.id, 9);
      expect(results.single.url, 'g.gif');
    });

    test('returns empty when data.data is null', () async {
      nextBody = {
        'data': {'data': null},
      };
      expect(await client.trending(), isEmpty);
    });
  });
}
