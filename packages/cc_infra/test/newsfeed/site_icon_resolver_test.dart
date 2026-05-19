import 'dart:typed_data';

import 'package:cc_infra/src/newsfeed/site_icon_resolver.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Exercises [SiteIconResolver]: the pure HTML candidate scoring
/// ([SiteIconResolver.pickBestIcon]) and the fail-silent network behaviour of
/// [SiteIconResolver.resolve] over a stubbed [HttpClientAdapter].
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

SiteIconResolver resolverReturning(String body, {int status = 200}) {
  final dio = Dio()
    ..httpClientAdapter = _FakeAdapter(
      (_) => ResponseBody.fromString(
        body,
        status,
        headers: {Headers.contentTypeHeader: ['text/html']},
      ),
    );
  return SiteIconResolver(dio);
}

void main() {
  final base = Uri.parse('https://lea.verou.me/');

  group('SiteIconResolver.pickBestIcon', () {
    test('picks a declared icon and resolves a relative href', () {
      const html = '''
        <html><head>
          <link rel="icon" href="/assets/favicon.png">
        </head><body></body></html>''';
      expect(
        SiteIconResolver.pickBestIcon(html, base: base),
        'https://lea.verou.me/assets/favicon.png',
      );
    });

    test('prefers the largest declared size', () {
      const html = '''
        <html><head>
          <link rel="icon" sizes="16x16" href="/favicon-16.png">
          <link rel="icon" sizes="32x32 192x192" href="/favicon-192.png">
        </head></html>''';
      expect(
        SiteIconResolver.pickBestIcon(html, base: base),
        'https://lea.verou.me/favicon-192.png',
      );
    });

    test('an apple-touch-icon outranks a small plain icon', () {
      const html = '''
        <html><head>
          <link rel="icon" sizes="16x16" href="/favicon.ico">
          <link rel="apple-touch-icon" href="/apple-touch-icon.png">
        </head></html>''';
      expect(
        SiteIconResolver.pickBestIcon(html, base: base),
        'https://lea.verou.me/apple-touch-icon.png',
      );
    });

    test('accepts "shortcut icon" and protocol-relative hrefs', () {
      const html = '''
        <html><head>
          <link rel="shortcut icon" href="//cdn.example.com/favicon.ico">
        </head></html>''';
      expect(
        SiteIconResolver.pickBestIcon(html, base: base),
        'https://cdn.example.com/favicon.ico',
      );
    });

    test('ignores mask-icon and unrelated link tags', () {
      const html = '''
        <html><head>
          <link rel="mask-icon" href="/mask.svg">
          <link rel="stylesheet" href="/style.css">
          <link rel="canonical" href="https://lea.verou.me/">
        </head></html>''';
      expect(SiteIconResolver.pickBestIcon(html, base: base), isNull);
    });

    test('a page without icon links yields null', () {
      expect(
        SiteIconResolver.pickBestIcon('<html><body>hi</body></html>', base: base),
        isNull,
      );
    });

    test('malformed HTML yields null, not an exception', () {
      expect(
        SiteIconResolver.pickBestIcon('\u0000\u0001\u0002', base: base),
        isNull,
      );
    });

    test('skips SVG icons (Hacker News shape) — unrenderable client-side', () {
      const html = '''
        <html><head>
          <link rel="stylesheet" href="news.css">
          <link rel="icon" href="y18.svg">
          <link rel="alternate" type="application/rss+xml" href="rss">
        </head></html>''';
      expect(SiteIconResolver.pickBestIcon(html, base: base), isNull);
    });

    test('skips SVG declared via the type attribute (no .svg extension)', () {
      const html = '''
        <html><head>
          <link rel="icon" type="image/svg+xml" href="/favicon">
        </head></html>''';
      expect(SiteIconResolver.pickBestIcon(html, base: base), isNull);
    });

    test('a raster icon beats an SVG one regardless of order', () {
      const html = '''
        <html><head>
          <link rel="apple-touch-icon" href="/touch.svg">
          <link rel="icon" sizes="32x32" href="/favicon-32.png">
        </head></html>''';
      expect(
        SiteIconResolver.pickBestIcon(html, base: base),
        'https://lea.verou.me/favicon-32.png',
      );
    });
  });

  group('isSvgIconUrl', () {
    test('detects .svg paths, ignoring the query', () {
      expect(isSvgIconUrl('https://news.ycombinator.com/y18.svg'), isTrue);
      expect(isSvgIconUrl('https://x.test/icon.svg?v=2'), isTrue);
    });

    test('raster and extensionless URLs are not SVG', () {
      expect(isSvgIconUrl('https://x.test/favicon.ico'), isFalse);
      expect(isSvgIconUrl('https://x.test/a.png?w=32'), isFalse);
      expect(isSvgIconUrl('https://x.test/favicon'), isFalse);
      expect(isSvgIconUrl('not a url'), isFalse);
    });
  });

  group('SiteIconResolver.resolve', () {
    test('fetches the site and returns the resolved icon URL', () async {
      final resolver = resolverReturning('''
        <html><head>
          <link rel="apple-touch-icon" href="/icon-180.png">
        </head></html>''');
      expect(
        await resolver.resolve('https://lea.verou.me'),
        'https://lea.verou.me/icon-180.png',
      );
    });

    test('returns null for a non-http(s) or hostless URL', () async {
      final resolver = resolverReturning('<link rel="icon" href="/x.png">');
      expect(await resolver.resolve('ftp://example.com'), isNull);
      expect(await resolver.resolve('not a url'), isNull);
    });

    test('returns null on a network error (never throws)', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
          (_) => throw DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionError,
          ),
        );
      expect(
        await SiteIconResolver(dio).resolve('https://down.example.com'),
        isNull,
      );
    });

    test('returns null when the site serves no icon links', () async {
      final resolver = resolverReturning('<html><body>no icons</body></html>');
      expect(await resolver.resolve('https://plain.example.com'), isNull);
    });
  });
}
