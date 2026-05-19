import 'package:any_date/any_date.dart';
import 'package:cc_domain/core/utils/string_utils.dart'
    show decodeHtmlEntities;
import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/social_media_url_transformer.dart';
import 'package:cc_domain/features/newsfeed/domain/tracking_param_stripper.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:rss_dart/dart_rss.dart';
import 'package:uuid/uuid.dart';

/// Network-facing service that fetches and parses an RSS/Atom feed URL into
/// domain [RssArticle]s.
///
/// Stays in the data layer: returns domain entities with no row IDs yet
/// (the repository assigns them).
class RssFetcherService {
  /// Creates a new [Rss fetcher service].
  RssFetcherService(this._dio);

  final Dio _dio;
  final _uuid = const Uuid();

  /// Fetches and parses [url]. Throws on network or parse errors.
  Future<List<RssArticle>> fetchAndParse({
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
              : 'ControlCenter/1.0 (+https://github.com/SamuelAlev/control-center)',
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
      return const [];
    }
    return _parseAny(feedId: feedId, body: body);
  }

  List<RssArticle> _parseAny({required String feedId, required String body}) {
    final trimmed = body.trimLeft();
    final looksAtom = trimmed.contains('<feed') && trimmed.contains('xmlns');
    final envelope = _extractXmlEnvelope(body);
    final sanitized = _sanitizeXmlBody(envelope);

    try {
      if (looksAtom) {
        return _parseAtom(feedId: feedId, body: sanitized);
      }
      return _parseRss(feedId: feedId, body: sanitized);
    } on Object catch (primaryError) {
      // Try the other format as a fallback.
      try {
        return looksAtom
            ? _parseRss(feedId: feedId, body: sanitized)
            : _parseAtom(feedId: feedId, body: sanitized);
      } on Object catch (_) {
        // The primary error reveals what actually went wrong (e.g.
        // XML parse failure); the fallback error (e.g.
        // "feed not found") is only misleading.
        throw primaryError;
      }
    }
  }

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

  List<RssArticle> _parseRss({required String feedId, required String body}) {
    final feed = RssFeed.parse(body);
    final items = feed.items;
    return items
        .map((it) => _itemToArticle(feedId: feedId, item: it))
        .whereType<RssArticle>()
        .toList();
  }

  List<RssArticle> _parseAtom({required String feedId, required String body}) {
    final feed = AtomFeed.parse(body);
    final items = feed.items;
    return items
        .map((it) => _atomItemToArticle(feedId: feedId, item: it))
        .whereType<RssArticle>()
        .toList();
  }

  RssArticle? _itemToArticle({required String feedId, required RssItem item}) {
    final title = decodeHtmlEntities((item.title ?? '').trim());
    final rawLink = _preferHackerNewsDiscussion(
      link: (item.link ?? '').trim(),
      comments: (item.comments ?? '').trim(),
    );
    final link = stripTrackingParams(
      transformSocialMediaUrl(rawLink),
      knownParams: defaultRemoveParams(),
    );
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
    return RssArticle(
      id: _uuid.v4(),
      feedId: feedId,
      guid: guid,
      title: title,
      link: link,
      summary: summary,
      imageUrl: image ?? '',
      author: author,
      publishedAt: _parseRssDate(item.pubDate) ?? _parseRssDate(item.dc?.date),
      createdAt: DateTime.now(),
    );
  }

  RssArticle? _atomItemToArticle({
    required String feedId,
    required AtomItem item,
  }) {
    final title = decodeHtmlEntities((item.title ?? '').trim());
    final link = stripTrackingParams(
      transformSocialMediaUrl(_atomLink(item.links)),
      knownParams: defaultRemoveParams(),
    );
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
    return RssArticle(
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
    );
  }

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
