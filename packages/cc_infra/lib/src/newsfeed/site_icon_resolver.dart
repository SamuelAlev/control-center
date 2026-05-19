import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

/// Whether [url] points at an SVG document. SVG icons cannot be decoded by
/// the client's raster pipeline (Flutter `Image` + the media proxy's ICO→PNG
/// transcoder), so they must never be stored as feed icons — an SVG renders
/// as nothing, worse than the `/favicon.ico` fallback.
bool isSvgIconUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return false;
  }
  return uri.path.toLowerCase().endsWith('.svg');
}

/// Best-effort resolver for a website's favicon from its HTML
/// (`<link rel="icon">` and friends).
///
/// Used when a feed advertises no channel image of its own (e.g.
/// lea.verou.me/feed.xml): the site's homepage is fetched once and the best
/// icon candidate is picked from its `<link>` tags. Everything here is
/// fail-silent — a network error, a non-HTML page, or a page without icon
/// links all return null and the caller keeps its existing fallback
/// (origin `/favicon.ico`). No third-party favicon service is contacted: the
/// feature blocks trackers and the site's origin is already contacted to
/// fetch its feed, so this adds no new party.
///
/// SVG candidates are SKIPPED: the client renders icons through Flutter's
/// raster pipeline (and the media proxy's ICO→PNG transcoder), which cannot
/// decode SVG, so an SVG favicon paints as nothing — worse than no stored
/// icon, which falls back to the origin's `/favicon.ico`.
class SiteIconResolver {
  /// Creates a new [SiteIconResolver].
  SiteIconResolver(this._dio);

  final Dio _dio;

  /// Resolves the favicon of [siteUrl]. Returns null when nothing usable is
  /// found; never throws.
  Future<String?> resolve(
    String siteUrl, {
    String? userAgent,
    CancelToken? cancelToken,
  }) async {
    final uri = Uri.tryParse(siteUrl.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return null;
    }
    try {
      final response = await _dio.get<String>(
        uri.toString(),
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': userAgent?.isNotEmpty == true
                ? userAgent!
                : 'ControlCenter/1.0 (+https://github.com/SamuelAlev/control-center)',
            'Accept': 'text/html, application/xhtml+xml, */*;q=0.5',
          },
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
      );
      final body = response.data ?? '';
      if (body.isEmpty) {
        return null;
      }
      // Hrefs resolve against the FINAL url after redirects, not the
      // requested one.
      return pickBestIcon(body, base: response.realUri);
    } on Object {
      return null;
    }
  }

  /// Picks the best icon candidate out of an HTML document. Visible for
  /// testing; [base] resolves relative hrefs.
  static String? pickBestIcon(String html, {required Uri base}) {
    String? best;
    var bestScore = -1;
    try {
      final doc = html_parser.parse(html);
      for (final link in doc.querySelectorAll('link[rel]')) {
        final rel = (link.attributes['rel'] ?? '').toLowerCase();
        final tokens = rel.split(RegExp(r'\s+'));
        // mask-icon is a monochrome SVG for Safari pinned tabs, not a
        // favicon substitute.
        if (tokens.contains('mask-icon')) {
          continue;
        }
        final isApple =
            tokens.contains('apple-touch-icon') ||
            tokens.contains('apple-touch-icon-precomposed');
        final isIcon = tokens.contains('icon');
        if (!isApple && !isIcon) {
          continue;
        }
        final href = (link.attributes['href'] ?? '').trim();
        if (href.isEmpty) {
          continue;
        }
        final resolved = base.resolve(href);
        if (!resolved.hasScheme) {
          continue;
        }
        final typeAttr = (link.attributes['type'] ?? '').toLowerCase();
        // SVG cannot be decoded by the client's raster pipeline — an SVG
        // icon renders as nothing, so it is worse than no icon at all.
        if (typeAttr.contains('svg') || isSvgIconUrl(resolved.toString())) {
          continue;
        }
        // Apple touch icons are reliably square, high-resolution PNGs;
        // plain icons win on their declared size.
        final score =
            (isApple ? 100 : 0) + _largestSize(link.attributes['sizes']);
        if (score > bestScore) {
          best = resolved.toString();
          bestScore = score;
        }
      }
    } on Object {
      return null;
    }
    return best;
  }

  /// The largest square dimension in a `sizes` attribute ("32x32 192x192" →
  /// 192; "any" or absent → 0).
  static int _largestSize(String? sizes) {
    if (sizes == null) {
      return 0;
    }
    var best = 0;
    for (final token in sizes.toLowerCase().split(RegExp(r'\s+'))) {
      final match = RegExp(r'^(\d+)x\d+$').firstMatch(token);
      if (match != null) {
        final w = int.tryParse(match.group(1)!) ?? 0;
        if (w > best) {
          best = w;
        }
      }
    }
    return best;
  }
}
