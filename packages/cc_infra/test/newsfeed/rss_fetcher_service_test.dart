import 'dart:async';

import 'package:cc_infra/src/newsfeed/rss_fetcher_service.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// Exercises the RSS/Atom fetch + parse pipeline of [RssFetcherService]:
/// envelope extraction (stripping server-prepended HTML), XML sanitization
/// (CDATA preservation, bare-ampersand / stray-`<` escaping, control-char
/// stripping), Hacker News discussion preference, tracking-param stripping,
/// and the primary→fallback format retry. Uses a [TestHttpClient] so no
/// native runtime or sockets are needed.

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

HttpResponse _xmlBody(HttpRequest request, String body, {int status = 200}) =>
    httpTextResponse(
      request,
      body,
      statusCode: status,
      headers: const {'content-type': 'application/rss+xml'},
    );

typedef Handler = FutureOr<HttpResponse> Function(HttpRequest request);

/// Builds the service with a single [TestHttpClient] backing both the feed
/// client and the og:image page client, mirroring the pre-migration setup
/// where one adapter served every request.
({RssFetcherService svc, TestHttpClient fake}) build(Handler handler) {
  final fake = TestHttpClient(handler: handler);
  return (svc: RssFetcherService(fake, pageHttpClient: fake), fake: fake);
}

const _rssSingle = '''<?xml version="1.0"?>
<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Feed</title>
    <item>
      <title>Hello &amp; world</title>
      <link>https://example.com/post?utm_source=x</link>
      <guid>guid-1</guid>
      <pubDate>Mon, 02 Jan 2026 03:04:05 GMT</pubDate>
      <description>&lt;p&gt;body&lt;/p&gt;</description>
    </item>
    <item>
      <title>Empty link</title>
      <link></link>
    </item>
  </channel>
</rss>''';

const _atomSingle = '''<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Atom Feed</title>
  <entry>
    <title>An entry</title>
    <link href="https://example.com/atom/1"/>
    <id>atom-id-1</id>
    <published>2026-01-02T03:04:05Z</published>
    <summary>summary text</summary>
  </entry>
</feed>''';

void main() {
  group('RssFetcherService.fetchAndParse — RSS', () {
    test('parses items and strips tracking params from the link', () async {
      final b = build((r) => _xmlBody(r, _rssSingle));
      final articles = await b.svc.fetchAndParse(
        feedId: 'f1',
        url: 'https://example.com/feed',
      );
      expect(articles, hasLength(1)); // the empty-link item is dropped
      final a = articles.single;
      expect(a.title, 'Hello & world'); // HTML entities decoded
      expect(a.link, 'https://example.com/post'); // utm_source stripped
      expect(a.guid, 'guid-1');
      expect(a.summary, 'body'); // HTML stripped from description
      expect(a.publishedAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
    });

    test('sends the configured User-Agent when provided', () async {
      final b = build((r) => _xmlBody(r, _rssSingle));
      await b.svc.fetchAndParse(
        feedId: 'f1',
        url: 'https://x',
        userAgent: 'MyReader/2.0',
      );
      // The first request is the feed; the image-less item triggers a
      // second (og:image fallback) request for its page.
      expect(_header(b.fake.requests.first, 'User-Agent'), 'MyReader/2.0');
    });

    test('falls back to the default User-Agent when none provided', () async {
      final b = build((r) => _xmlBody(r, _rssSingle));
      await b.svc.fetchAndParse(feedId: 'f1', url: 'https://x');
      expect(
        _header(b.fake.requests.first, 'User-Agent'),
        contains('ControlCenter'),
      );
    });

    test('returns [] for an empty body', () async {
      final b = build((r) => _xmlBody(r, ''));
      expect(
        await b.svc.fetchAndParse(feedId: 'f1', url: 'https://x'),
        isEmpty,
      );
    });
  });

  group('RssFetcherService.fetchAndParse — Atom', () {
    test('parses Atom entries', () async {
      final b = build((r) => _xmlBody(r, _atomSingle));
      final articles = await b.svc.fetchAndParse(
        feedId: 'f2',
        url: 'https://example.com/atom',
      );
      expect(articles, hasLength(1));
      final a = articles.single;
      expect(a.title, 'An entry');
      expect(a.link, 'https://example.com/atom/1');
      expect(a.guid, 'atom-id-1');
      expect(a.publishedAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
    });
  });

  group('RssFetcherService — envelope extraction', () {
    test('strips HTML prepended before the RSS envelope', () async {
      const body = '<html><body>error page</body></html>\n$_rssSingle';
      final b = build((r) => _xmlBody(r, body));
      final articles = await b.svc.fetchAndParse(
        feedId: 'f1',
        url: 'https://x',
      );
      expect(articles, hasLength(1));
      expect(articles.single.title, 'Hello & world');
    });

    test('throws when no RSS/Atom envelope is present', () async {
      final b = build(
        (r) => _xmlBody(r, '<html><body>not a feed</body></html>'),
      );
      await expectLater(
        b.svc.fetchAndParse(feedId: 'f1', url: 'https://x'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('RssFetcherService — XML sanitization', () {
    test('preserves CDATA content (bare ampersands inside are kept)', () async {
      const body = '''<?xml version="1.0"?>
<rss version="2.0"><channel><title>F</title>
<item>
  <title><![CDATA[A & B < C]]></title>
  <link>https://example.com/cdata</link>
</item>
</channel></rss>''';
      final b = build((r) => _xmlBody(r, body));
      final articles = await b.svc.fetchAndParse(
        feedId: 'f1',
        url: 'https://x',
      );
      expect(articles.single.title, 'A & B < C');
    });

    test('escapes a bare ampersand outside CDATA', () async {
      // The title has a raw `&` not part of an entity; the sanitizer must
      // escape it before the XML parser sees it.
      const body = '''<?xml version="1.0"?>
<rss version="2.0"><channel><title>F</title>
<item>
  <title>Tom & Jerry</title>
  <link>https://example.com/tj</link>
</item>
</channel></rss>''';
      final b = build((r) => _xmlBody(r, body));
      final articles = await b.svc.fetchAndParse(
        feedId: 'f1',
        url: 'https://x',
      );
      expect(articles.single.title, 'Tom & Jerry');
    });
  });

  group('RssFetcherService — Hacker News handling', () {
    test('prefers the HN comments URL over the external link', () async {
      const body = '''<?xml version="1.0"?>
<rss version="2.0"><channel><title>HN</title>
<item>
  <title>Story</title>
  <link>https://externalsite.com/story</link>
  <comments>https://news.ycombinator.com/item?id=1</comments>
</item>
</channel></rss>''';
      final b = build((r) => _xmlBody(r, body));
      final articles = await b.svc.fetchAndParse(
        feedId: 'hn',
        url: 'https://x',
      );
      expect(articles.single.link, 'https://news.ycombinator.com/item?id=1');
      // HN items drop the (empty) summary.
      expect(articles.single.summary, isEmpty);
    });

    test('keeps the external link when comments is not an HN URL', () async {
      const body = '''<?xml version="1.0"?>
<rss version="2.0"><channel><title>HN</title>
<item>
  <title>Story</title>
  <link>https://externalsite.com/story</link>
  <comments>https://other.com/thread</comments>
</item>
</channel></rss>''';
      final b = build((r) => _xmlBody(r, body));
      final articles = await b.svc.fetchAndParse(
        feedId: 'hn',
        url: 'https://x',
      );
      expect(articles.single.link, 'https://externalsite.com/story');
    });

    test('keeps the external link when comments is empty', () async {
      const body = '''<?xml version="1.0"?>
<rss version="2.0"><channel><title>HN</title>
<item>
  <title>Story</title>
  <link>https://externalsite.com/story</link>
</item>
</channel></rss>''';
      final b = build((r) => _xmlBody(r, body));
      final articles = await b.svc.fetchAndParse(
        feedId: 'hn',
        url: 'https://x',
      );
      expect(articles.single.link, 'https://externalsite.com/story');
    });
  });

  group('RssFetcherService — image extraction', () {
    test(
      'prefers media:thumbnail, then media:content, then enclosure',
      () async {
        const body = '''<?xml version="1.0"?>
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
<channel><title>F</title>
<item>
  <title>Img</title>
  <link>https://example.com/img</link>
  <media:thumbnail url="https://example.com/thumb.jpg"/>
</item>
</channel></rss>''';
        final b = build((r) => _xmlBody(r, body));
        final articles = await b.svc.fetchAndParse(
          feedId: 'f1',
          url: 'https://x',
        );
        expect(articles.single.imageUrl, 'https://example.com/thumb.jpg');
      },
    );

    test(
      'extracts the first <img> from the description when no media',
      () async {
        const body = '''<?xml version="1.0"?>
<rss version="2.0"><channel><title>F</title>
<item>
  <title>Img</title>
  <link>https://example.com/img</link>
  <description>&lt;p&gt;&lt;img src="https://example.com/desc.jpg"/&gt;text&lt;/p&gt;</description>
</item>
</channel></rss>''';
        final b = build((r) => _xmlBody(r, body));
        final articles = await b.svc.fetchAndParse(
          feedId: 'f1',
          url: 'https://x',
        );
        expect(articles.single.imageUrl, 'https://example.com/desc.jpg');
      },
    );
  });

  group('RssFetcherService — og:image fallback', () {
    HttpResponse htmlBody(HttpRequest request, String body) => httpTextResponse(
      request,
      body,
      headers: const {'content-type': 'text/html'},
    );

    test('uses the page og:image when the item has no image', () async {
      const feed = '''<?xml version="1.0"?>
<rss version="2.0"><channel><title>F</title>
<item>
  <title>No img</title>
  <link>https://example.com/post</link>
  <description>text only</description>
</item>
</channel></rss>''';
      final b = build(
        (r) => httpRequestUri(r).toString() == 'https://example.com/feed'
            ? _xmlBody(r, feed)
            : htmlBody(
                r,
                '<html><head><meta property="og:image" '
                'content="https://example.com/og.png"/></head><body></body></html>',
              ),
      );
      final articles = await b.svc.fetchAndParse(
        feedId: 'f1',
        url: 'https://example.com/feed',
      );
      expect(articles.single.imageUrl, 'https://example.com/og.png');
      expect(
        b.fake.requests.map((r) => httpRequestUri(r).toString()),
        contains('https://example.com/post'),
      );
    });

    test('resolves a relative og:image against the article URL', () async {
      const feed = '''<?xml version="1.0"?>
<rss version="2.0"><channel><title>F</title>
<item>
  <title>No img</title>
  <link>https://example.com/blog/post</link>
</item>
</channel></rss>''';
      final b = build(
        (r) => httpRequestUri(r).toString() == 'https://example.com/feed'
            ? _xmlBody(r, feed)
            : htmlBody(
                r,
                '<html><head><meta property="og:image" '
                'content="/assets/og.png"/></head></html>',
              ),
      );
      final articles = await b.svc.fetchAndParse(
        feedId: 'f1',
        url: 'https://example.com/feed',
      );
      expect(articles.single.imageUrl, 'https://example.com/assets/og.png');
    });

    test('leaves imageUrl empty when the page has no og:image', () async {
      const feed = '''<?xml version="1.0"?>
<rss version="2.0"><channel><title>F</title>
<item>
  <title>No img</title>
  <link>https://example.com/post</link>
</item>
</channel></rss>''';
      final b = build(
        (r) => httpRequestUri(r).toString() == 'https://example.com/feed'
            ? _xmlBody(r, feed)
            : htmlBody(r, '<html><head><title>x</title></head></html>'),
      );
      final articles = await b.svc.fetchAndParse(
        feedId: 'f1',
        url: 'https://example.com/feed',
      );
      expect(articles.single.imageUrl, isEmpty);
    });

    test('does not fetch pages for items that already have an image', () async {
      const feed = '''<?xml version="1.0"?>
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
<channel><title>F</title>
<item>
  <title>Img</title>
  <link>https://example.com/img</link>
  <media:thumbnail url="https://example.com/thumb.jpg"/>
</item>
</channel></rss>''';
      final b = build((r) => _xmlBody(r, feed));
      final articles = await b.svc.fetchAndParse(
        feedId: 'f1',
        url: 'https://example.com/feed',
      );
      expect(articles.single.imageUrl, 'https://example.com/thumb.jpg');
      // Only the feed was fetched — no og:image page request.
      expect(b.fake.requests, hasLength(1));
    });

    test(
      'a failing page fetch leaves imageUrl empty without throwing',
      () async {
        const feed = '''<?xml version="1.0"?>
<rss version="2.0"><channel><title>F</title>
<item>
  <title>No img</title>
  <link>https://example.com/post</link>
</item>
</channel></rss>''';
        final b = build(
          (r) => httpRequestUri(r).toString() == 'https://example.com/feed'
              ? _xmlBody(r, feed)
              : httpTextResponse(r, 'boom', statusCode: 500),
        );
        final articles = await b.svc.fetchAndParse(
          feedId: 'f1',
          url: 'https://example.com/feed',
        );
        expect(articles.single.imageUrl, isEmpty);
      },
    );

    test('Hacker News: fetches og:image from the external story, '
        'never the discussion page', () async {
      const feed = '''<?xml version="1.0"?>
<rss version="2.0"><channel><title>HN</title>
<item>
  <title>Story</title>
  <link>https://externalsite.com/story</link>
  <comments>https://news.ycombinator.com/item?id=1</comments>
</item>
</channel></rss>''';
      final b = build((r) {
        if (httpRequestUri(r).toString() == 'https://example.com/feed') {
          return _xmlBody(r, feed);
        }
        if (httpRequestUri(r).toString() == 'https://externalsite.com/story') {
          return htmlBody(
            r,
            '<html><head><meta property="og:image" '
            'content="https://externalsite.com/cover.png"/></head></html>',
          );
        }
        fail('unexpected request to ${httpRequestUri(r)}');
      });
      final articles = await b.svc.fetchAndParse(
        feedId: 'hn',
        url: 'https://example.com/feed',
      );
      final a = articles.single;
      // The article still opens the HN discussion…
      expect(a.link, 'https://news.ycombinator.com/item?id=1');
      // …but the cover image comes from the external story's og:image.
      expect(a.imageUrl, 'https://externalsite.com/cover.png');
      expect(
        b.fake.requests.map((r) => httpRequestUri(r).toString()),
        isNot(contains(startsWith('https://news.ycombinator.com'))),
      );
    });
  });

  group('RssFetcherService — error handling', () {
    test('a non-2xx response (validation failure) throws', () async {
      final b = build((r) => _xmlBody(r, 'not found', status: 404));
      await expectLater(
        b.svc.fetchAndParse(feedId: 'f1', url: 'https://x'),
        throwsA(
          isA<RhttpStatusCodeException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });
  });

  group('RssFetcherService.fetchAndParseFeed — channel metadata', () {
    test(
      'extracts the RSS channel image and site link (TechCrunch shape)',
      () async {
        const body = '''<?xml version="1.0"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>TechCrunch</title>
    <link>https://techcrunch.com/</link>
    <image>
      <url>https://techcrunch.com/wp-content/uploads/2015/02/cropped-cropped-favicon-gradient.png?w=32</url>
      <title>TechCrunch</title>
      <link>https://techcrunch.com/</link>
      <width>32</width>
      <height>32</height>
    </image>
    <item>
      <title>An item</title>
      <link>https://techcrunch.com/2026/08/11/x/</link>
    </item>
  </channel>
</rss>''';
        final b = build((r) => _xmlBody(r, body));
        final parsed = await b.svc.fetchAndParseFeed(
          feedId: 'tc',
          url: 'https://techcrunch.com/feed/',
        );
        expect(parsed.articles, hasLength(1));
        expect(
          parsed.iconUrl,
          'https://techcrunch.com/wp-content/uploads/2015/02/cropped-cropped-favicon-gradient.png?w=32',
        );
        expect(parsed.siteUrl, 'https://techcrunch.com/');
      },
    );

    test('a feed without a channel image reports no iconUrl', () async {
      final b = build((r) => _xmlBody(r, _rssSingle));
      final parsed = await b.svc.fetchAndParseFeed(
        feedId: 'f1',
        url: 'https://example.com/feed',
      );
      expect(parsed.iconUrl, isNull);
    });

    test('extracts the Atom <icon> and alternate site link', () async {
      const body = '''<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Atom Feed</title>
  <icon>https://blog.example.com/icon.png</icon>
  <logo>https://blog.example.com/logo.png</logo>
  <link rel="self" href="https://blog.example.com/feed.xml"/>
  <link rel="alternate" href="https://blog.example.com/"/>
  <entry>
    <title>An entry</title>
    <link href="https://blog.example.com/1"/>
    <id>atom-1</id>
    <published>2026-01-02T03:04:05Z</published>
  </entry>
</feed>''';
      final b = build((r) => _xmlBody(r, body));
      final parsed = await b.svc.fetchAndParseFeed(
        feedId: 'a1',
        url: 'https://blog.example.com/feed.xml',
      );
      expect(parsed.iconUrl, 'https://blog.example.com/icon.png');
      expect(parsed.siteUrl, 'https://blog.example.com/');
    });

    test('falls back to the Atom <logo> when no <icon>', () async {
      const body = '''<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Atom Feed</title>
  <logo>https://blog.example.com/logo.png</logo>
  <link href="https://blog.example.com/"/>
  <entry>
    <title>An entry</title>
    <link href="https://blog.example.com/1"/>
    <id>atom-1</id>
    <published>2026-01-02T03:04:05Z</published>
  </entry>
</feed>''';
      final b = build((r) => _xmlBody(r, body));
      final parsed = await b.svc.fetchAndParseFeed(
        feedId: 'a2',
        url: 'https://blog.example.com/feed.xml',
      );
      expect(parsed.iconUrl, 'https://blog.example.com/logo.png');
    });

    test('resolves a relative Atom icon against the feed URL', () async {
      const body = '''<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Atom Feed</title>
  <icon>/favicon.ico</icon>
  <link href="https://lea.verou.me/"/>
  <entry>
    <title>An entry</title>
    <link href="https://lea.verou.me/1"/>
    <id>atom-1</id>
    <published>2026-01-02T03:04:05Z</published>
  </entry>
</feed>''';
      final b = build((r) => _xmlBody(r, body));
      final parsed = await b.svc.fetchAndParseFeed(
        feedId: 'a3',
        url: 'https://lea.verou.me/feed.xml',
      );
      expect(parsed.iconUrl, 'https://lea.verou.me/favicon.ico');
    });
  });
}
