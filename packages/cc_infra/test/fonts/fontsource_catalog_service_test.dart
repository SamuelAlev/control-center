import 'dart:io';

import 'package:cc_infra/src/fonts/fontsource_catalog_service.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:test/test.dart';

/// One catalogue row. Mirrors the upstream shape: a lowercase-hyphenated [id]
/// and a Title Case display family (defaulted from [id] here).
Map<String, Object?> _row(
  String id, {
  String? family,
  String type = 'google',
  String category = 'sans-serif',
  List<int> weights = const [400, 700],
  List<String> styles = const ['normal', 'italic'],
  List<String> subsets = const ['latin', 'cyrillic'],
  String defSubset = 'latin',
}) => {
  'id': id,
  'family': family ?? '${id[0].toUpperCase()}${id.substring(1)}',
  'type': type,
  'category': category,
  'weights': weights,
  'styles': styles,
  'subsets': subsets,
  'defSubset': defSubset,
};

void main() {
  late Directory tempDir;

  setUp(() => tempDir = Directory.systemTemp.createTempSync('cc_fonts_test'));
  tearDown(() => tempDir.deleteSync(recursive: true));

  String cachePath() => '${tempDir.path}/font_catalog.json';

  FontsourceCatalogService serviceOver(
    TestHttpClient httpClient, {
    Duration ttl = const Duration(days: 1),
  }) => FontsourceCatalogService(
    cacheFilePath: cachePath(),
    httpClient: httpClient,
    ttl: ttl,
  );

  group('catalog', () {
    test('parses and sorts families by display name', () async {
      final service = serviceOver(
        TestHttpClient(
          handler: (request) => httpTextResponse(request, [
            _row('roboto', family: 'Roboto'),
            _row('inter'),
          ]),
        ),
      );

      final catalog = await service.catalog();

      expect(catalog.map((f) => f.family), ['Inter', 'Roboto']);
    });

    test('drops non-Google and icon pseudo-families', () async {
      // Icon sets are glyph tables, not text faces and a non-Google origin is
      // not served by the CDN path this resolves against.
      final service = serviceOver(
        TestHttpClient(
          handler: (request) => httpTextResponse(request, [
            _row('inter'),
            _row('material-icons', category: 'icons'),
            _row('some-open-font', type: 'other'),
          ]),
        ),
      );

      final catalog = await service.catalog();

      expect(catalog.map((f) => f.id), ['inter']);
    });

    test('drops rows missing the fields a variant needs', () async {
      final service = serviceOver(
        TestHttpClient(
          handler: (request) => httpTextResponse(request, [
            _row('inter'),
            _row('no-weights', weights: []),
            _row('no-subsets', subsets: []),
            {'id': 'no-family', 'type': 'google'},
          ]),
        ),
      );

      final catalog = await service.catalog();

      expect(catalog.map((f) => f.id), ['inter']);
    });

    test('falls back to the first subset when defSubset is not offered', () {
      final service = serviceOver(
        TestHttpClient(
          handler: (request) => httpTextResponse(request, [
            _row('inter', subsets: ['latin'], defSubset: 'greek'),
          ]),
        ),
      );

      expectLater(
        service.catalog().then((c) => c.single.defSubset),
        completion('latin'),
      );
    });

    test('fetches once and memoises', () async {
      final httpClient = TestHttpClient(
        handler: (request) => httpTextResponse(request, [_row('inter')]),
      );
      final service = serviceOver(httpClient);

      await service.catalog();
      await service.catalog();

      expect(httpClient.requests, hasLength(1));
    });

    test('concurrent callers share one fetch', () async {
      final httpClient = TestHttpClient(
        handler: (request) => httpTextResponse(request, [_row('inter')]),
      );
      final service = serviceOver(httpClient);

      await Future.wait([service.catalog(), service.catalog()]);

      expect(httpClient.requests, hasLength(1));
    });

    test('a second service reads the fresh disk cache', () async {
      final first = TestHttpClient(
        handler: (request) => httpTextResponse(request, [_row('inter')]),
      );
      await serviceOver(first).catalog();

      final second = TestHttpClient(
        handler: (_) => throw Exception('should not be called'),
      );
      final catalog = await serviceOver(second).catalog();

      expect(second.requests, isEmpty, reason: 'a restart costs no network');
      expect(catalog.map((f) => f.family), ['Inter']);
    });

    test('a stale cache serves when the fetch fails', () async {
      await serviceOver(
        TestHttpClient(
          handler: (request) => httpTextResponse(request, [_row('inter')]),
        ),
      ).catalog();
      // Backdate the cache so ttl: zero is UNAMBIGUOUSLY stale: Windows'
      // coarse wall clock can read `now - mtime` as 0 (or negative) for a
      // file written this instant, which would make the just-written cache
      // "fresh" and skip the revalidation this test asserts happens.
      File(cachePath()).setLastModifiedSync(
        DateTime.now().subtract(const Duration(minutes: 1)),
      );

      final offline = TestHttpClient(
        handler: (_) => throw Exception('offline'),
      );
      final catalog = await serviceOver(offline, ttl: Duration.zero).catalog();

      expect(
        offline.requests,
        hasLength(1),
        reason: 'staleness is retried first',
      );
      expect(catalog.map((f) => f.family), ['Inter']);
    });

    test('an unreachable catalogue is empty, never an error', () async {
      final service = serviceOver(
        TestHttpClient(handler: (_) => throw Exception('offline')),
      );

      expect(await service.catalog(), isEmpty);
    });

    test('an empty answer is not memoised as the catalogue', () async {
      // Otherwise one offline start would leave the picker fontless for the
      // rest of the session.
      var payload = <Object?>[];
      final httpClient = TestHttpClient(
        handler: (request) => httpTextResponse(request, payload),
      );
      final service = serviceOver(httpClient);

      expect(await service.catalog(), isEmpty);
      payload = [_row('inter')];

      expect((await service.catalog()).map((f) => f.family), ['Inter']);
    });

    test('does not fetch when the network is disallowed', () async {
      final httpClient = TestHttpClient(
        handler: (request) => httpTextResponse(request, [_row('inter')]),
      );
      final service = FontsourceCatalogService(
        cacheFilePath: cachePath(),
        httpClient: httpClient,
        allowNetwork: false,
      );

      expect(await service.catalog(), isEmpty);
      expect(httpClient.requests, isEmpty);
    });
  });

  group('resolveFileUrl', () {
    late FontsourceCatalogService service;

    setUp(() {
      service = serviceOver(
        TestHttpClient(
          handler: (request) => httpTextResponse(request, [
            _row('inter', family: 'Inter'),
            _row(
              'roboto-mono',
              family: 'Roboto Mono',
              category: 'monospace',
              styles: ['normal'],
              subsets: ['latin'],
            ),
          ]),
        ),
      );
    });

    test('builds a ttf URL for the requested variant', () async {
      final url = await service.resolveFileUrl(
        family: 'Inter',
        weight: 700,
        italic: true,
      );

      expect(
        url.toString(),
        '$kFontsourceCdnBase/inter@latest/latin-700-italic.ttf',
        reason:
            'Skia decodes ttf; the woff2 an upstream serves a browser is '
            'unusable',
      );
    });

    test('snaps an unoffered weight to the nearest cut', () async {
      final url = await service.resolveFileUrl(family: 'Inter', weight: 620);

      expect(url.toString(), endsWith('latin-700-normal.ttf'));
    });

    test('falls back to upright when italic is not offered', () async {
      final url = await service.resolveFileUrl(
        family: 'Roboto Mono',
        italic: true,
      );

      expect(url.toString(), endsWith('latin-400-normal.ttf'));
    });

    test('falls back to the default subset when one is not offered', () async {
      final url = await service.resolveFileUrl(
        family: 'Roboto Mono',
        subset: 'cyrillic',
      );

      expect(url.toString(), endsWith('latin-400-normal.ttf'));
    });

    test('an uncatalogued family resolves to nothing', () async {
      // This is the ownership check behind the fonts proxy: the URL is derived
      // from a catalogued id, never from anything a client supplies.
      expect(await service.resolveFileUrl(family: 'Menlo'), isNull);
      expect(
        await service.resolveFileUrl(family: 'https://evil.test/x.ttf'),
        isNull,
      );
    });
  });
}
