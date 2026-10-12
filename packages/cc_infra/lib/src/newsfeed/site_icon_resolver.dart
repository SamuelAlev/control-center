import 'package:cc_infra/src/network/app_network.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:rhttp/rhttp.dart';

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

/// Best-effort favicon from homepage HTML `<link rel="icon">` when a feed has
/// no image. Fail-silent → null (caller keeps `/favicon.ico`). No third-party
/// favicon service. Skips SVG (Flutter/media proxy cannot decode — worse than
/// no stored icon).
class SiteIconResolver {
  /// Creates a new [SiteIconResolver].
  ///
  /// The passed client's settings (trust store, timeouts, base URL) and
  /// interceptor chain carry over to the client the page fetch actually runs
  /// on: rhttp does not report the URL a redirect chain ended on, so redirects
  /// are turned off there and followed here, where each `Location` is visible.
  /// `redirectlessHttpClient` injects that client directly, for tests.
  SiteIconResolver(this._httpClient, {RhttpClient? redirectlessHttpClient})
    : _redirectlessHttpClientOverride = redirectlessHttpClient;

  final RhttpClient _httpClient;
  final RhttpClient? _redirectlessHttpClientOverride;

  /// Maximum redirects to follow before abandoning the fetch.
  static const int _maxRedirects = 5;

  /// The fetch transport: the injected client's settings and interceptors with
  /// redirect-following turned OFF, so every hop is observable here. Created on
  /// first use, so a caller that never resolves an icon never needs the native
  /// runtime.
  late final RhttpClient _redirectlessHttpClient =
      _redirectlessHttpClientOverride ??
      RhttpClient.createSync(
        settings: httpClientSettings(
          settings: _httpClient.settings.copyWith(
            redirectSettings: const RedirectSettings.none(),
          ),
        ),
        interceptors: [
          if (_httpClient.interceptor != null) _httpClient.interceptor!,
        ],
      );

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
      final page = await _fetchPage(
        uri,
        userAgent: userAgent,
        cancelToken: cancelToken,
      );
      if (page == null || page.body.isEmpty) {
        return null;
      }
      // Hrefs resolve against the URL the page was finally served from, not the
      // one that was requested — a site that redirects to a subdomain or a path
      // prefix would otherwise point every relative icon href at the wrong
      // host.
      return pickBestIcon(page.body, base: page.finalUri);
    } on Object {
      return null;
    }
  }

  /// Fetches [uri] through the redirect-less transport, following up to
  /// [_maxRedirects] `Location` hops itself so the page's effective URL is
  /// known. Null when the chain left http(s) or exceeded the budget.
  Future<({String body, Uri finalUri})?> _fetchPage(
    Uri uri, {
    String? userAgent,
    CancelToken? cancelToken,
  }) async {
    var current = uri;
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      final response = await _redirectlessHttpClient.getText(
        current.toString(),
        headers: HttpHeaders.rawMap({
          'User-Agent': userAgent?.isNotEmpty == true
              ? userAgent!
              : 'ControlCenter/1.0 (+https://github.com/SamuelAlev/control-center)',
          'Accept': 'text/html, application/xhtml+xml, */*;q=0.5',
        }),
        cancelToken: cancelToken,
      );
      final location = _header(response, 'location');
      final isRedirect = response.statusCode ~/ 100 == 3;
      if (!isRedirect || location == null || location.isEmpty) {
        return (body: response.body, finalUri: current);
      }
      final next = current.resolve(location);
      if (next.scheme != 'http' && next.scheme != 'https') {
        return null;
      }
      current = next;
    }
    return null;
  }

  /// Case-insensitive lookup of [name] in a response's headers (reqwest
  /// lower-cases them; a canned test response may not).
  static String? _header(HttpResponse response, String name) {
    final direct = response.headerMap[name];
    if (direct != null) {
      return direct;
    }
    for (final entry in response.headerMap.entries) {
      if (entry.key.toLowerCase() == name) {
        return entry.value;
      }
    }
    return null;
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
