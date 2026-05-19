/// One search result, normalized across backends.
class SearchHit {
  /// Creates a [SearchHit].
  const SearchHit({
    required this.title,
    required this.url,
    required this.snippet,
  });

  /// Result title.
  final String title;

  /// Destination URL, already unwrapped from any redirector.
  final String url;

  /// Result snippet, possibly empty.
  final String snippet;
}

/// A keyless web-search backend: a URL to fetch and a parser for its HTML.
///
/// **Why several.** A single backend is a single point of failure that fails
/// in the least useful way: a bot challenge returns a 200 with no results,
/// which reads to the model as "there is nothing about this on the internet".
/// That is a wrong answer, not a missing one, and the agent proceeds on it.
///
/// All of these are keyless on purpose. A chain that needs credentials is a
/// chain that is empty on a fresh install, and the value here is precisely
/// that search keeps working when the first backend blocks the request.
abstract interface class SearchBackend {
  /// Backend name, used in the failure message.
  String get name;

  /// Builds the query URL.
  Uri queryUrl(String query);

  /// Parses results out of the response body.
  List<SearchHit> parse(String html);
}

/// Strips tags and decodes the entities search engines actually emit.
String cleanSearchText(String html) => html
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&amp;', '&')
    .replaceAll('&#x27;', "'")
    .replaceAll('&#39;', "'")
    .replaceAll('&quot;', '"')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&nbsp;', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Unwraps a redirector URL (`/l/?uddg=…`, `/url?q=…`) to its target.
String unwrapRedirect(String href) {
  final normalized = href.startsWith('//') ? 'https:$href' : href;
  final uri = Uri.tryParse(normalized);
  if (uri == null) {
    return normalized;
  }
  for (final key in const ['uddg', 'q', 'u', 'url']) {
    final value = uri.queryParameters[key];
    if (value != null && value.startsWith('http')) {
      return value;
    }
  }
  return normalized;
}

/// Whether [body] looks like a bot challenge rather than an empty result set.
///
/// The distinction matters more than it looks: "no results" makes an agent
/// conclude the thing does not exist, while "blocked" makes it try another
/// route. Conflating them turns an infrastructure problem into a wrong answer.
bool looksBlocked(String body) {
  final lower = body.toLowerCase();
  return body.length < 512 ||
      lower.contains('captcha') ||
      lower.contains('unusual traffic') ||
      lower.contains('anomaly') ||
      lower.contains('challenge') ||
      lower.contains('are you a robot');
}

/// DuckDuckGo's HTML endpoint.
class DuckDuckGoBackend implements SearchBackend {
  /// Creates a [DuckDuckGoBackend].
  const DuckDuckGoBackend();

  @override
  String get name => 'duckduckgo';

  @override
  Uri queryUrl(String query) => Uri.parse(
    'https://html.duckduckgo.com/html/',
  ).replace(queryParameters: {'q': query});

  @override
  List<SearchHit> parse(String html) {
    final out = <SearchHit>[];
    final snippets = RegExp(
      r'<a[^>]*class="[^"]*result__snippet[^"]*"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html).map((m) => cleanSearchText(m.group(1) ?? '')).toList();
    var i = 0;
    for (final match in RegExp(
      r'<a[^>]*class="[^"]*result__a[^"]*"[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html)) {
      final url = unwrapRedirect(match.group(1) ?? '');
      final title = cleanSearchText(match.group(2) ?? '');
      if (url.isEmpty || title.isEmpty) {
        continue;
      }
      out.add(
        SearchHit(
          title: title,
          url: url,
          snippet: i < snippets.length ? snippets[i] : '',
        ),
      );
      i++;
    }
    return out;
  }
}

/// Mojeek — an independent index, so it fails independently of the others.
class MojeekBackend implements SearchBackend {
  /// Creates a [MojeekBackend].
  const MojeekBackend();

  @override
  String get name => 'mojeek';

  @override
  Uri queryUrl(String query) =>
      Uri.parse('https://www.mojeek.com/search').replace(
        queryParameters: {'q': query},
      );

  @override
  List<SearchHit> parse(String html) {
    final out = <SearchHit>[];
    for (final match in RegExp(
      r'<a[^>]*class="[^"]*ob[^"]*"[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html)) {
      final url = unwrapRedirect(match.group(1) ?? '');
      final title = cleanSearchText(match.group(2) ?? '');
      if (!url.startsWith('http') || title.isEmpty) {
        continue;
      }
      out.add(SearchHit(title: title, url: url, snippet: ''));
    }
    return out;
  }
}

/// Bing's HTML results.
class BingBackend implements SearchBackend {
  /// Creates a [BingBackend].
  const BingBackend();

  @override
  String get name => 'bing';

  @override
  Uri queryUrl(String query) =>
      Uri.parse('https://www.bing.com/search').replace(
        queryParameters: {'q': query, 'format': 'rss'},
      );

  /// Bing's RSS output is parsed instead of its HTML: the markup changes
  /// constantly and the feed does not, so this backend stays working across
  /// redesigns that break scrapers.
  @override
  List<SearchHit> parse(String html) {
    final out = <SearchHit>[];
    for (final item in RegExp(
      r'<item>([\s\S]*?)</item>',
      caseSensitive: false,
    ).allMatches(html)) {
      final body = item.group(1) ?? '';
      final title = cleanSearchText(
        RegExp(r'<title>([\s\S]*?)</title>').firstMatch(body)?.group(1) ?? '',
      );
      final link = cleanSearchText(
        RegExp(r'<link>([\s\S]*?)</link>').firstMatch(body)?.group(1) ?? '',
      );
      final description = cleanSearchText(
        RegExp(
              r'<description>([\s\S]*?)</description>',
            ).firstMatch(body)?.group(1) ??
            '',
      );
      if (!link.startsWith('http') || title.isEmpty) {
        continue;
      }
      out.add(SearchHit(title: title, url: link, snippet: description));
    }
    return out;
  }
}

/// The chain walked in order until one backend answers.
///
/// DuckDuckGo first because it is the most consistently parseable; Bing's feed
/// second because it survives redesigns; Mojeek last because its independent
/// index is the best chance when the other two are rate-limiting the same IP.
const List<SearchBackend> searchBackends = [
  DuckDuckGoBackend(),
  BingBackend(),
  MojeekBackend(),
];
