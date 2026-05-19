import 'package:any_date/any_date.dart';
import 'package:cc_domain/core/utils/string_utils.dart' show decodeHtmlEntities;
import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/social_media_url_transformer.dart';
import 'package:cc_domain/features/newsfeed/domain/tracking_param_stripper.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:rss_dart/dart_rss.dart';
import 'package:uuid/uuid.dart';

/// The channel-level metadata of a parsed feed, alongside its articles.
///
/// [iconUrl] is the image the feed advertises for itself (RSS
/// `<channel><image><url>`, Atom `<icon>` / `<logo>`), resolved against the
/// feed URL when relative. [siteUrl] is the human-facing site the feed
/// belongs to (RSS channel `<link>`, Atom `rel="alternate"`), used to look up
/// a favicon from the site HTML when the feed advertises no icon.
class ParsedFeed {
  /// Creates a new [ParsedFeed].
  const ParsedFeed({required this.articles, this.iconUrl, this.siteUrl});

  /// The parsed articles.
  final List<RssArticle> articles;

  /// The feed's self-advertised icon, when present.
  final String? iconUrl;

  /// The feed's human-facing site, when present.
  final String? siteUrl;
}

/// A parsed article plus the URL whose `og:image` should be consulted when
/// the item carries no image of its own.
///
/// Usually the article link itself, but NOT for Hacker News: the article
/// link deliberately points at the YC discussion page (see
/// [RssFetcherService._preferHackerNewsDiscussion]), whose og:image is just
/// the HN logo — the og fallback must fetch the *external* story instead.
typedef _ParsedEntry = ({RssArticle article, String ogImageSource});

/// A feed parse result before og:image fallbacks are resolved.
typedef _ParsedEntries = ({
  List<_ParsedEntry> articles,
  String? iconUrl,
  String? siteUrl,
});

/// Network-facing service that fetches and parses an RSS/Atom feed URL into
/// domain [RssArticle]s.
///
/// Stays in the data layer: returns domain entities with no row IDs yet
/// (the repository assigns them).
class RssFetcherService {
  /// Creates a new [Rss fetcher service].
  ///
  /// [pageDio] fetches article pages for the og:image fallback. When omitted
  /// it is a plain [Dio] sharing [dio]'s adapter — deliberately WITHOUT the
  /// interceptor chain: no retry (a 403 challenge page never becomes
  /// fetchable by retrying) and no error logging (Cloudflare/paywall 403s
  /// are routine for page fetches, not warnings worth logging).
  RssFetcherService(Dio dio, {Dio? pageDio})
    : _dio = dio,
      _pageDio =
          pageDio ??
          (Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)))
            ..httpClientAdapter = dio.httpClientAdapter);

  final Dio _dio;
  final Dio _pageDio;
  final _uuid = const Uuid();

  static const _defaultUserAgent =
      'ControlCenter/1.0 (+https://github.com/SamuelAlev/control-center)';

  /// Wall-clock budget for one feed's og:image fallback pass: page fetches
  /// past the deadline are skipped so a feed full of image-less items cannot
  /// stretch a refresh unboundedly.
  static const _ogImageBudget = Duration(seconds: 15);

  /// Fetches and parses [url]. Throws on network or parse errors.
  Future<List<RssArticle>> fetchAndParse({
    required String feedId,
    required String url,
    String? userAgent,
    CancelToken? cancelToken,
  }) async => (await fetchAndParseFeed(
    feedId: feedId,
    url: url,
    userAgent: userAgent,
    cancelToken: cancelToken,
  )).articles;

  /// Fetches and parses [url], returning the articles plus the channel-level
  /// metadata ([ParsedFeed.iconUrl] / [ParsedFeed.siteUrl]). Throws on
  /// network or parse errors.
  Future<ParsedFeed> fetchAndParseFeed({
    required String feedId,
    required String url,
    String? userAgent,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<String>(
      url,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          'User-Agent': userAgent?.isNotEmpty == true
              ? userAgent!
              : _defaultUserAgent,
          'Accept':
              'application/rss+xml, application/atom+xml, '
              'application/xml;q=0.9, text/xml;q=0.8, */*;q=0.5',
        },
        followRedirects: true,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
    final body = response.data ?? '';
    if (body.isEmpty) {
      return const ParsedFeed(articles: []);
    }
    final parsed = _parseAny(feedId: feedId, feedUrl: url, body: body);
    return _resolveOgImages(
      parsed,
      userAgent: userAgent,
      cancelToken: cancelToken,
    );
  }

  _ParsedEntries _parseAny({
    required String feedId,
    required String feedUrl,
    required String body,
  }) {
    final trimmed = body.trimLeft();
    final looksAtom = trimmed.contains('<feed') && trimmed.contains('xmlns');
    final envelope = _extractXmlEnvelope(body);
    final sanitized = _sanitizeXmlBody(envelope);

    try {
      if (looksAtom) {
        return _parseAtom(feedId: feedId, feedUrl: feedUrl, body: sanitized);
      }
      return _parseRss(feedId: feedId, feedUrl: feedUrl, body: sanitized);
    } on Object catch (primaryError) {
      // Try the other format as a fallback.
      try {
        return looksAtom
            ? _parseRss(feedId: feedId, feedUrl: feedUrl, body: sanitized)
            : _parseAtom(feedId: feedId, feedUrl: feedUrl, body: sanitized);
      } on Object catch (_) {
        // The primary error reveals what actually went wrong (e.g.
        // XML parse failure); the fallback error (e.g.
        // "feed not found") is only misleading.
        throw primaryError;
      }
    }
  }

  /// Best-effort `og:image` fallback for image-less articles: fetches each
  /// article's page (bounded concurrency, per-request timeouts, failures
  /// ignored) and fills `imageUrl` from its `og:image` meta tag.
  Future<ParsedFeed> _resolveOgImages(
    _ParsedEntries parsed, {
    String? userAgent,
    CancelToken? cancelToken,
  }) async {
    final articles = List<RssArticle>.of(parsed.articles.map((e) => e.article));
    final pending = [
      for (var i = 0; i < parsed.articles.length; i++)
        if (articles[i].imageUrl.isEmpty) i,
    ];
    if (pending.isNotEmpty) {
      var next = 0;
      final deadline = DateTime.now().add(_ogImageBudget);
      const concurrency = 4;
      await Future.wait(
        List.generate(
          concurrency < pending.length ? concurrency : pending.length,
          (_) async {
            while (next < pending.length && DateTime.now().isBefore(deadline)) {
              final i = pending[next++];
              final og = await _fetchOgImage(
                parsed.articles[i].ogImageSource,
                userAgent: userAgent,
                cancelToken: cancelToken,
              );
              if (og != null) {
                articles[i] = _withImage(articles[i], og);
              }
            }
          },
        ),
      );
    }
    return ParsedFeed(
      articles: articles,
      iconUrl: parsed.iconUrl,
      siteUrl: parsed.siteUrl,
    );
  }

  /// Fetches [url] and extracts its `og:image` meta tag, resolved against
  /// the page URL when relative. Returns null on any failure — the fallback
  /// is best-effort and must never break a feed refresh.
  Future<String?> _fetchOgImage(
    String url, {
    String? userAgent,
    CancelToken? cancelToken,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    // A YC discussion page's og:image is the HN logo — not a cover image.
    if (uri.host.toLowerCase() == 'news.ycombinator.com') {
      return null;
    }
    try {
      final response = await _pageDio.get<String>(
        url,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'User-Agent': userAgent?.isNotEmpty == true
                ? userAgent!
                : _defaultUserAgent,
            'Accept': 'text/html, application/xhtml+xml;q=0.9, */*;q=0.5',
          },
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
      );
      final body = response.data ?? '';
      if (body.isEmpty) {
        return null;
      }
      return _extractOgImage(body, uri);
    } on Object catch (_) {
      return null;
    }
  }

  /// Extracts the `og:image` URL from a page's `<head>`.
  static String? _extractOgImage(String html, Uri base) {
    // The meta tag lives in <head>; parsing a huge body is wasted work.
    final headEnd = html.toLowerCase().indexOf('</head>');
    final head = headEnd != -1
        ? html.substring(0, headEnd + 7)
        : (html.length > 512 * 1024 ? html.substring(0, 512 * 1024) : html);
    try {
      final doc = html_parser.parse(head);
      final meta =
          doc.querySelector('meta[property="og:image"]') ??
          doc.querySelector('meta[name="og:image"]');
      final content = meta?.attributes['content']?.trim();
      if (content == null || content.isEmpty) {
        return null;
      }
      final resolved = base.resolve(content);
      if (resolved.scheme != 'http' && resolved.scheme != 'https') {
        return null;
      }
      return resolved.toString();
    } on Object catch (_) {
      return null;
    }
  }

  static RssArticle _withImage(RssArticle article, String imageUrl) =>
      RssArticle(
        id: article.id,
        feedId: article.feedId,
        guid: article.guid,
        title: article.title,
        link: article.link,
        summary: article.summary,
        imageUrl: imageUrl,
        author: article.author,
        publishedAt: article.publishedAt,
        saved: article.saved,
        read: article.read,
        createdAt: article.createdAt,
      );

  /// Extracts only the RSS or Atom XML envelope, discarding any HTML that
  /// some servers prepend or append (e.g. error pages, tracking pixels).
  ///
  /// Throws [FormatException] when no RSS or Atom envelope is found,
  /// so callers get a clear error instead of a confusing XML parse failure.
  static String _extractXmlEnvelope(String raw) {
    final lower = raw.toLowerCase();

    // RSS envelope: first <rss to last </rss>
    final rssStart = lower.indexOf('<rss');
    final rssEnd = lower.lastIndexOf('</rss>');
    if (rssStart != -1 && rssEnd != -1 && rssEnd > rssStart) {
      return raw.substring(rssStart, rssEnd + 6); // 6 = '</rss>'.length
    }

    // Atom envelope: first <feed to last </feed>
    final feedStart = lower.indexOf('<feed');
    final feedEnd = lower.lastIndexOf('</feed>');
    if (feedStart != -1 && feedEnd != -1 && feedEnd > feedStart) {
      return raw.substring(feedStart, feedEnd + 7); // 7 = '</feed>'.length
    }

    // No XML envelope found — the server likely returned an error page.
    final preview = raw.length > 120 ? '${raw.substring(0, 120)}...' : raw;
    throw FormatException(
      'Response does not contain a valid RSS/Atom XML envelope. '
      'The server may have returned an error or block page. Preview: $preview',
    );
  }

  /// Sanitizes common RSS/Atom XML issues before parsing.
  ///
  /// 1. Temporarily replaces CDATA sections with placeholders so we don't
  ///    modify literal content inside them.
  /// 2. Removes invalid XML control characters.
  /// 3. Escapes bare ampersands that aren't part of known entity references.
  /// 4. Restores CDATA sections.
  static String _sanitizeXmlBody(String xml) {
    final cdataSections = <String>[];
    var sanitized = xml.replaceAllMapped(
      RegExp(r'<!\[CDATA\[.*?\]\]>', dotAll: true),
      (match) {
        cdataSections.add(match.group(0)!);
        return '__CDATA_SECTION_${cdataSections.length - 1}__';
      },
    );

    // Remove invalid XML characters (control chars except tab, LF, CR).
    sanitized = sanitized.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
      '',
    );

    // Escape bare ampersands not followed by a known entity reference.
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'&(?!(?:amp|lt|gt|quot|apos|#[0-9]+|#x[0-9a-fA-F]+);)'),
      (match) => '&amp;',
    );

    // Escape stray `<` that aren't part of markup (e.g. `3 < 4` in titles).
    // Only replaces `<` when not followed by `/`, `!`, `?`, or an ASCII letter
    // (i.e. not a valid tag start).
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'<(?![/!?]|\w)'),
      (match) => '&lt;',
    );

    for (var i = 0; i < cdataSections.length; i++) {
      sanitized = sanitized.replaceFirst(
        '__CDATA_SECTION_${i}__',
        cdataSections[i],
      );
    }

    return sanitized;
  }

  _ParsedEntries _parseRss({
    required String feedId,
    required String feedUrl,
    required String body,
  }) {
    final feed = RssFeed.parse(body);
    final items = feed.items;
    return (
      articles: items
          .map((it) => _itemToArticle(feedId: feedId, item: it))
          .whereType<_ParsedEntry>()
          .toList(),
      iconUrl: _absoluteUrl(feed.image?.url, feedUrl),
      siteUrl: _absoluteUrl(feed.link, feedUrl),
    );
  }

  _ParsedEntries _parseAtom({
    required String feedId,
    required String feedUrl,
    required String body,
  }) {
    final feed = AtomFeed.parse(body);
    final items = feed.items;
    return (
      articles: items
          .map((it) => _atomItemToArticle(feedId: feedId, item: it))
          .whereType<_ParsedEntry>()
          .toList(),
      // `<icon>` is the small square one, `<logo>` a larger (often 2:1)
      // rendition — the icon fits the newsfeed's square avatar better.
      iconUrl:
          _absoluteUrl(feed.icon, feedUrl) ?? _absoluteUrl(feed.logo, feedUrl),
      siteUrl: _absoluteUrl(_atomAlternateLink(feed.links), feedUrl),
    );
  }

  /// The `rel="alternate"` link of an Atom feed — the human-facing site.
  static String? _atomAlternateLink(List<AtomLink> links) {
    for (final link in links) {
      if ((link.rel ?? 'alternate') == 'alternate' &&
          (link.href ?? '').isNotEmpty) {
        return link.href;
      }
    }
    return null;
  }

  /// Resolves [url] against [base] when it is relative (Atom `<icon>` is
  /// commonly `/favicon.ico`); returns null when absent or unparseable.
  static String? _absoluteUrl(String? url, String base) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final baseUri = Uri.tryParse(base);
    final uri = Uri.tryParse(trimmed);
    if (uri == null || baseUri == null) {
      return uri?.hasScheme == true ? trimmed : null;
    }
    return baseUri.resolveUri(uri).toString();
  }

  _ParsedEntry? _itemToArticle({
    required String feedId,
    required RssItem item,
  }) {
    final title = decodeHtmlEntities((item.title ?? '').trim());
    final originalLink = (item.link ?? '').trim();
    final rawLink = _preferHackerNewsDiscussion(
      link: originalLink,
      comments: (item.comments ?? '').trim(),
    );
    final link = _cleanUrl(rawLink);
    if (title.isEmpty || link.isEmpty) {
      return null;
    }
    final guid = (item.guid ?? '').trim().isNotEmpty ? item.guid!.trim() : link;
    final isHackerNews =
        Uri.tryParse(link)?.host.toLowerCase() == 'news.ycombinator.com';
    final summaryHtml = item.content?.value ?? item.description ?? '';
    // HN's description it empty, we drop it.
    final summary = isHackerNews
        ? ''
        : decodeHtmlEntities(_stripHtml(summaryHtml));
    final image = _firstImage(
      mediaThumbnailUrl: item.media?.thumbnails.firstOrNull?.url,
      mediaContentUrl: item.media?.contents.firstOrNull?.url,
      enclosureUrl: _isImageMime(item.enclosure?.type)
          ? item.enclosure?.url
          : null,
      html: summaryHtml,
    );
    final author = decodeHtmlEntities(
      (item.author ?? item.dc?.creator ?? '').trim(),
    );
    return (
      article: RssArticle(
        id: _uuid.v4(),
        feedId: feedId,
        guid: guid,
        title: title,
        link: link,
        summary: summary,
        imageUrl: image ?? '',
        author: author,
        publishedAt:
            _parseRssDate(item.pubDate) ?? _parseRssDate(item.dc?.date),
        createdAt: DateTime.now(),
      ),
      // For HN the article link is the discussion page; the og:image fallback
      // must fetch the external story instead. Ask-HN-style items (no
      // external link) skip the fetch — the YC page's og:image is the logo.
      ogImageSource: isHackerNews ? _cleanUrl(originalLink) : link,
    );
  }

  _ParsedEntry? _atomItemToArticle({
    required String feedId,
    required AtomItem item,
  }) {
    final title = decodeHtmlEntities((item.title ?? '').trim());
    final link = _cleanUrl(_atomLink(item.links));
    if (title.isEmpty || link.isEmpty) {
      return null;
    }
    final guid = (item.id ?? '').trim().isNotEmpty ? item.id!.trim() : link;
    final summaryHtml = item.content ?? item.summary ?? '';
    final summary = decodeHtmlEntities(_stripHtml(summaryHtml));
    final image = _firstImage(
      mediaThumbnailUrl: item.media?.thumbnails.firstOrNull?.url,
      mediaContentUrl: item.media?.contents.firstOrNull?.url,
      enclosureUrl: null,
      html: summaryHtml,
    );
    final author = decodeHtmlEntities(
      (item.authors.firstOrNull?.name ?? '').trim(),
    );
    final published =
        _parseAtomDate(item.published) ?? _parseAtomDate(item.updated);
    return (
      article: RssArticle(
        id: _uuid.v4(),
        feedId: feedId,
        guid: guid,
        title: title,
        link: link,
        summary: summary,
        imageUrl: image ?? '',
        author: author,
        publishedAt: published,
        createdAt: DateTime.now(),
      ),
      ogImageSource: link,
    );
  }

  static String _cleanUrl(String url) => stripTrackingParams(
    transformSocialMediaUrl(url),
    knownParams: defaultRemoveParams(),
  );

  /// Hacker News RSS items put the external article in `<link>` and the
  /// discussion page in `<comments>`. Prefer the discussion page so users
  /// land on the HN thread instead of the linked site.
  static String _preferHackerNewsDiscussion({
    required String link,
    required String comments,
  }) {
    if (comments.isEmpty) {
      return link;
    }
    final uri = Uri.tryParse(comments);
    if (uri == null || !uri.hasScheme) {
      return link;
    }
    if (uri.host.toLowerCase() != 'news.ycombinator.com') {
      return link;
    }
    return comments;
  }

  String _atomLink(List<AtomLink>? links) {
    if (links == null || links.isEmpty) {
      return '';
    }
    final alternate = links.firstWhere(
      (l) => (l.rel ?? 'alternate') == 'alternate',
      orElse: () => links.first,
    );
    return alternate.href ?? '';
  }

  static const _dateParser = AnyDate();

  DateTime? _parseRssDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return _dateParser.parse(raw).toUtc();
    } on Object {
      return null;
    }
  }

  DateTime? _parseAtomDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return _dateParser.parse(raw).toUtc();
    } on Object {
      return null;
    }
  }

  bool _isImageMime(String? mime) =>
      mime != null && mime.toLowerCase().startsWith('image/');

  String? _firstImage({
    required String? mediaThumbnailUrl,
    required String? mediaContentUrl,
    required String? enclosureUrl,
    required String html,
  }) {
    for (final candidate in [
      mediaThumbnailUrl,
      mediaContentUrl,
      enclosureUrl,
    ]) {
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return _extractImageFromHtml(html);
  }

  String? _extractImageFromHtml(String html) {
    if (html.isEmpty) {
      return null;
    }
    try {
      final doc = html_parser.parse(html);
      final img = doc.querySelector('img');
      final src = img?.attributes['src'];
      if (src != null && src.isNotEmpty) {
        return src;
      }
    } on Object catch (_) {
      // Fall through to null.
    }
    return null;
  }

  String _stripHtml(String html) {
    if (html.isEmpty) {
      return '';
    }
    try {
      final doc = html_parser.parse(html);
      return doc.body?.text.trim() ?? '';
    } on Object catch (_) {
      return html.replaceAll(RegExp(r'<[^>]+>'), ' ').trim();
    }
  }
}
