import 'package:cc_infra/src/newsfeed/site_icon_resolver.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// Exercises [SiteIconResolver]: the pure HTML candidate scoring
/// ([SiteIconResolver.pickBestIcon]) and the fail-silent network behaviour of
/// [SiteIconResolver.resolve] over a stubbed [TestHttpClient].
({SiteIconResolver resolver, TestHttpClient fake}) resolverReturning(
  String body, {
  int status = 200,
}) {
  final fake = TestHttpClient(
    handler: (request) => httpTextResponse(
      request,
      body,
      statusCode: status,
      headers: {'content-type': 'text/html'},
    ),
  );
  return (
    resolver: SiteIconResolver(fake, redirectlessHttpClient: fake),
    fake: fake,
  );
}

/// The value of [name] on a captured request, matched case-insensitively.
String? _header(HttpRequest request, String name) {
  final headers = request.headers?.toMapList();
  if (headers == null) {
    return null;
  }
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value.first;
    }
  }
  return null;
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
        SiteIconResolver.pickBestIcon(
          '<html><body>hi</body></html>',
          base: base,
        ),
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
      final built = resolverReturning('''
        <html><head>
          <link rel="apple-touch-icon" href="/icon-180.png">
        </head></html>''');
      expect(
        await built.resolver.resolve('https://lea.verou.me'),
        'https://lea.verou.me/icon-180.png',
      );
      final request = built.fake.requests.single;
      expect(httpRequestUri(request), Uri.parse('https://lea.verou.me'));
      expect(_header(request, 'User-Agent'), startsWith('ControlCenter/'));
      expect(_header(request, 'Accept'), contains('text/html'));
    });

    test('returns null for a non-http(s) or hostless URL', () async {
      final built = resolverReturning('<link rel="icon" href="/x.png">');
      expect(await built.resolver.resolve('ftp://example.com'), isNull);
      expect(await built.resolver.resolve('not a url'), isNull);
      // Neither URL is dialable, so nothing hits the transport.
      expect(built.fake.requests, isEmpty);
    });

    test('returns null on a network error (never throws)', () async {
      final fake = TestHttpClient(
        handler: (request) =>
            throw RhttpConnectionException(request, 'unreachable'),
      );
      expect(
        await SiteIconResolver(
          fake,
          redirectlessHttpClient: fake,
        ).resolve('https://down.example.com'),
        isNull,
      );
    });

    test(
      'resolves a relative icon against the page after a redirect',
      () async {
        final fake = TestHttpClient(
          handler: (request) {
            final uri = httpRequestUri(request);
            if (uri.path == '/old') {
              // A relative Location, resolved against the URL that answered.
              return httpTextResponse(
                request,
                '',
                statusCode: 302,
                headers: {'location': '/new/page'},
              );
            }
            return httpTextResponse(
              request,
              '<html><head><link rel="icon" href="icon.png"></head></html>',
              headers: {'content-type': 'text/html'},
            );
          },
        );

        expect(
          await SiteIconResolver(
            fake,
            redirectlessHttpClient: fake,
          ).resolve('https://lea.verou.me/old'),
          'https://lea.verou.me/new/icon.png',
          reason: 'icon.png belongs to the page the redirect served',
        );
        expect(fake.requests, hasLength(2));
        expect(
          httpRequestUri(fake.requests[0]).toString(),
          'https://lea.verou.me/old',
        );
        expect(
          httpRequestUri(fake.requests[1]).toString(),
          'https://lea.verou.me/new/page',
        );
      },
    );

    test(
      'a redirect without a Location falls back to the served body',
      () async {
        final built = resolverReturning(
          '<html><head><link rel="icon" href="/icon.png"></head></html>',
          status: 302,
        );
        expect(
          await built.resolver.resolve('https://lea.verou.me'),
          'https://lea.verou.me/icon.png',
        );
      },
    );

    test('returns null when the site serves no icon links', () async {
      final built = resolverReturning('<html><body>no icons</body></html>');
      expect(await built.resolver.resolve('https://plain.example.com'), isNull);
    });
  });
}
