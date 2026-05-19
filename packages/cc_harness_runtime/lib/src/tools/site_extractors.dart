/// Turns a known site's HTML into the structure that page is actually about.
///
/// **Why generic HTML-to-text is not enough.** A GitHub issue stripped to text
/// is a wall of nav chrome, reaction counts and "N participants" with the
/// conversation buried in the middle. A pub.dev page becomes a list of link
/// labels. What the agent needed — the title, the body, the answer, the
/// version, the install line — was in there, and it now has to guess which
/// paragraph it was.
///
/// Each extractor pulls the page's actual structure into markdown, keeping
/// anchors and code blocks intact so the agent can quote and cite instead of
/// paraphrasing something it half-read.
///
/// Every extractor is best-effort by construction: a site that changed its
/// markup returns null and the caller falls back to generic text. A wrong
/// extraction is worse than a generic one, so each returns null rather than
/// guessing when its anchors are missing.
abstract interface class SiteExtractor {
  /// Whether this extractor handles [uri].
  bool handles(Uri uri);

  /// Extracts markdown from [html], or null when the page does not match the
  /// expected shape.
  String? extract(Uri uri, String html);
}

/// Strips tags from an HTML fragment and decodes the common entities.
String stripTags(String html) {
  var text = html
      .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), ' ')
      .replaceAll(RegExp('<br[^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp('</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp('</li>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  const entities = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&mdash;': '—',
    '&ndash;': '–',
    '&hellip;': '…',
  };
  entities.forEach((from, to) => text = text.replaceAll(from, to));
  text = text.replaceAllMapped(
    RegExp(r'&#(\d+);'),
    (m) => String.fromCharCode(int.parse(m.group(1)!)),
  );
  return text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
}

/// The first capture of [pattern] in [html], stripped, or null.
String? _first(String html, RegExp pattern, {int group = 1}) {
  final match = pattern.firstMatch(html);
  if (match == null) {
    return null;
  }
  final raw = match.group(group);
  if (raw == null) {
    return null;
  }
  final text = stripTags(raw);
  return text.isEmpty ? null : text;
}

/// A `<meta>` tag's content, by `property` or `name`.
String? metaContent(String html, String key) =>
    _first(
      html,
      RegExp(
        '<meta[^>]+(?:property|name)=["\']${RegExp.escape(key)}["\'][^>]*'
        'content=["\']([^"\']*)["\']',
        caseSensitive: false,
      ),
    ) ??
    _first(
      html,
      RegExp(
        '<meta[^>]+content=["\']([^"\']*)["\'][^>]*'
        '(?:property|name)=["\']${RegExp.escape(key)}["\']',
        caseSensitive: false,
      ),
    );

/// Converts `<pre><code>` blocks into fenced markdown, so code survives.
///
/// The single most valuable thing on a Stack Overflow answer or a package
/// README is the code, and generic tag-stripping turns it into unindented
/// prose that reads as if the author wrote a paragraph of syntax.
String preserveCodeBlocks(String html) => html.replaceAllMapped(
  RegExp(
    r'<pre[^>]*>\s*(?:<code[^>]*>)?([\s\S]*?)(?:</code>)?\s*</pre>',
    caseSensitive: false,
  ),
  (m) => '\n\n```\n${stripTags(m.group(1) ?? '')}\n```\n\n',
);

/// GitHub issues, pull requests and repository landing pages.
class GitHubExtractor implements SiteExtractor {
  /// Creates a [GitHubExtractor].
  const GitHubExtractor();

  @override
  bool handles(Uri uri) => uri.host == 'github.com' || uri.host == 'www.github.com';

  @override
  String? extract(Uri uri, String html) {
    final title = metaContent(html, 'og:title') ?? _first(html, RegExp(r'<title>([\s\S]*?)</title>'));
    if (title == null) {
      return null;
    }
    final buffer = StringBuffer('# $title\n\n');
    final description = metaContent(html, 'og:description');
    if (description != null && description.isNotEmpty) {
      buffer.writeln(description);
      buffer.writeln();
    }
    // The issue/PR body and each comment live in `.comment-body` containers.
    final bodies = RegExp(
      r'<td[^>]*class="[^"]*comment-body[^"]*"[^>]*>([\s\S]*?)</td>',
      caseSensitive: false,
    ).allMatches(html);
    var index = 0;
    for (final match in bodies) {
      if (index >= 20) {
        buffer.writeln('_…more comments not shown._');
        break;
      }
      final text = stripTags(preserveCodeBlocks(match.group(1) ?? ''));
      if (text.isEmpty) {
        continue;
      }
      buffer
        ..writeln(index == 0 ? '## Description' : '## Comment $index')
        ..writeln(text)
        ..writeln();
      index++;
    }
    final out = buffer.toString().trim();
    // Title + description alone is what the generic path already produces, so
    // returning it here would claim a structured extraction that did not
    // happen.
    return index == 0 && (description == null || description.isEmpty)
        ? null
        : out;
  }
}

/// Stack Overflow / Stack Exchange questions.
class StackOverflowExtractor implements SiteExtractor {
  /// Creates a [StackOverflowExtractor].
  const StackOverflowExtractor();

  @override
  bool handles(Uri uri) =>
      uri.host.endsWith('stackoverflow.com') ||
      uri.host.endsWith('stackexchange.com') ||
      uri.host.endsWith('superuser.com') ||
      uri.host.endsWith('serverfault.com');

  @override
  String? extract(Uri uri, String html) {
    final title =
        _first(html, RegExp(r'<title>([\s\S]*?)</title>')) ??
        metaContent(html, 'og:title');
    final posts = RegExp(
      // Non-greedy to the first `</div>`. Answer bodies are prose, code and
      // lists rather than nested containers, so this holds — and where it does
      // not, the extraction degrades to a shorter excerpt rather than to a
      // wrong one. Requiring a trailing sibling (as an earlier version did)
      // silently dropped the LAST answer on every page, which is usually the
      // accepted one.
      r'<div[^>]*class="[^"]*(?:s-prose|post-text)[^"]*"[^>]*>([\s\S]*?)</div>',
      caseSensitive: false,
    ).allMatches(html).toList();
    if (title == null || posts.isEmpty) {
      return null;
    }
    final buffer = StringBuffer('# $title\n\n');
    for (var i = 0; i < posts.length && i < 8; i++) {
      final text = stripTags(preserveCodeBlocks(posts[i].group(1) ?? ''));
      if (text.isEmpty) {
        continue;
      }
      // The first prose block on a question page is the question; the rest are
      // answers, and the top one is usually what the agent came for.
      buffer
        ..writeln(i == 0 ? '## Question' : '## Answer $i')
        ..writeln(text)
        ..writeln();
    }
    return buffer.toString().trim();
  }
}

/// pub.dev package pages.
class PubDevExtractor implements SiteExtractor {
  /// Creates a [PubDevExtractor].
  const PubDevExtractor();

  @override
  bool handles(Uri uri) => uri.host == 'pub.dev';

  @override
  String? extract(Uri uri, String html) {
    final segments = uri.pathSegments;
    final packageIndex = segments.indexOf('packages');
    if (packageIndex < 0 || packageIndex + 1 >= segments.length) {
      return null;
    }
    final package = segments[packageIndex + 1];
    final description = metaContent(html, 'description');
    // The version is the one fact an agent almost always wants from pub.dev
    // and the one a text dump buries under the sidebar.
    final version = _first(
      html,
      RegExp(r'<h1[^>]*class="[^"]*title[^"]*"[^>]*>\s*([^<]*?)\s*</h1>'),
    );
    final readme = _first(
      html,
      RegExp(
        r'<section[^>]*class="[^"]*detail-tab-readme-content[^"]*"[^>]*>([\s\S]*?)</section>',
        caseSensitive: false,
      ),
    );
    if (description == null && readme == null) {
      return null;
    }
    final buffer = StringBuffer('# $package\n\n');
    if (version != null) {
      buffer.writeln('Latest: $version\n');
    }
    if (description != null) {
      buffer.writeln('$description\n');
    }
    buffer.writeln('Install: `dart pub add $package`\n');
    if (readme != null) {
      buffer.writeln('## README\n');
      buffer.writeln(readme);
    }
    return buffer.toString().trim();
  }
}

/// npm package pages.
class NpmExtractor implements SiteExtractor {
  /// Creates an [NpmExtractor].
  const NpmExtractor();

  @override
  bool handles(Uri uri) => uri.host == 'www.npmjs.com' || uri.host == 'npmjs.com';

  @override
  String? extract(Uri uri, String html) {
    final segments = uri.pathSegments;
    final packageIndex = segments.indexOf('package');
    if (packageIndex < 0 || packageIndex + 1 >= segments.length) {
      return null;
    }
    final package = segments.sublist(packageIndex + 1).join('/');
    final description = metaContent(html, 'og:description');
    if (description == null) {
      return null;
    }
    return '# $package\n\n$description\n\nInstall: `npm install $package`';
  }
}

/// arXiv abstract pages.
class ArxivExtractor implements SiteExtractor {
  /// Creates an [ArxivExtractor].
  const ArxivExtractor();

  @override
  bool handles(Uri uri) => uri.host.endsWith('arxiv.org');

  @override
  String? extract(Uri uri, String html) {
    final title = _first(
      html,
      RegExp(
        r'<h1[^>]*class="title[^"]*"[^>]*>(?:<span[^>]*>[^<]*</span>)?([\s\S]*?)</h1>',
        caseSensitive: false,
      ),
    );
    final abstract = _first(
      html,
      RegExp(
        r'<blockquote[^>]*class="abstract[^"]*"[^>]*>(?:<span[^>]*>[^<]*</span>)?([\s\S]*?)</blockquote>',
        caseSensitive: false,
      ),
    );
    if (title == null || abstract == null) {
      return null;
    }
    final authors = _first(
      html,
      RegExp(
        r'<div[^>]*class="authors"[^>]*>([\s\S]*?)</div>',
        caseSensitive: false,
      ),
    );
    final buffer = StringBuffer('# $title\n\n');
    if (authors != null) {
      buffer.writeln('$authors\n');
    }
    buffer.writeln('## Abstract\n\n$abstract');
    return buffer.toString().trim();
  }
}

/// MDN documentation pages.
class MdnExtractor implements SiteExtractor {
  /// Creates an [MdnExtractor].
  const MdnExtractor();

  @override
  bool handles(Uri uri) => uri.host == 'developer.mozilla.org';

  @override
  String? extract(Uri uri, String html) {
    final title = metaContent(html, 'og:title');
    final main = _first(
      html,
      RegExp(
        r'<article[^>]*class="[^"]*main-page-content[^"]*"[^>]*>([\s\S]*?)</article>',
        caseSensitive: false,
      ),
    );
    if (title == null || main == null) {
      return null;
    }
    return '# $title\n\n$main';
  }
}

/// The extractors tried in order.
const List<SiteExtractor> siteExtractors = [
  GitHubExtractor(),
  StackOverflowExtractor(),
  PubDevExtractor(),
  NpmExtractor(),
  ArxivExtractor(),
  MdnExtractor(),
];

/// Structured markdown for [uri]'s [html], or null when no extractor matched
/// or the page did not have the expected shape.
///
/// Callers fall back to generic HTML-to-text on null — a site that changed its
/// markup should degrade to the old behaviour, never to an error.
String? extractSiteContent(Uri uri, String html) {
  for (final extractor in siteExtractors) {
    if (!extractor.handles(uri)) {
      continue;
    }
    try {
      final extracted = extractor.extract(uri, html);
      if (extracted != null && extracted.trim().isNotEmpty) {
        return extracted;
      }
    } on Object {
      // A malformed page must not fail the fetch.
      return null;
    }
    return null;
  }
  return null;
}
