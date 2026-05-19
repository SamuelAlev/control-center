import 'package:control_center/shared/utils/video_embed_adapter.dart';

/// Builds a `{uuid → presigned-url}` map by scanning the HTML version of a
/// GitHub issue/PR body for `private-user-images.githubusercontent.com` URLs.
///
/// GitHub returns these URLs in `body_html` (requested via
/// `Accept: application/vnd.github.full+json`) — they carry a JWT in the
/// query string that authenticates the request, so they can be fetched
/// without any GitHub session cookie. The corresponding raw markdown body
/// only contains the web-only `github.com/user-attachments/assets/<uuid>`
/// form, which requires a session cookie to resolve.
///
/// Use [rewriteUserAttachmentUrls] to splice the resolved URLs back into
/// markdown before rendering.
Map<String, String> extractUserAttachmentUrls(String? bodyHtml) {
  if (bodyHtml == null || bodyHtml.isEmpty) {
    return const <String, String>{};
  }

  final pattern = RegExp(
    r'https://private-user-images\.githubusercontent\.com/[^\s"'
    r"'"
    r']*?-([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})\.[a-zA-Z0-9]+\?[^\s"'
    r"'"
    r']+',
  );

  final out = <String, String>{};
  for (final match in pattern.allMatches(bodyHtml)) {
    final uuid = match.group(1)!;
    out.putIfAbsent(uuid, () => match.group(0)!);
  }
  return out;
}

/// Returns the set of user-attachment UUIDs that GitHub renders as
/// `<video>` (rather than `<img>`) in [bodyHtml]. Lets the renderer
/// dispatch to a video player even when the splice can't run (no
/// bodyHtml) or the pre-signed URL is missing its extension.
Set<String> extractUserAttachmentVideoUuids(String? bodyHtml) {
  if (bodyHtml == null || bodyHtml.isEmpty) {
    return const <String>{};
  }
  // Match: <video ... src="https://.../-<UUID>.<ext>?...">
  final pattern = RegExp(
    r'<video\b[^>]*\bsrc\s*=\s*["' "'"
    r']https?://[^"'
    r"'"
    r']*?-([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})',
    caseSensitive: false,
  );
  final out = <String>{};
  for (final m in pattern.allMatches(bodyHtml)) {
    out.add(m.group(1)!.toLowerCase());
  }
  return out;
}

/// Width/height hint extracted from an `<img>` tag, encoded into the image
/// URL's fragment by [preprocessHtmlMediaTags] so the dimensions survive the
/// markdown round-trip. Values are in CSS pixels; [widthPercent] is set when
/// the source was a percentage (e.g. `width="50%"`) and represents the
/// fraction of the available layout width.
class ImageDimensionHint {
  /// Creates an [ImageDimensionHint].
  const ImageDimensionHint({this.width, this.height, this.widthPercent});

  /// Pixel width, when the source used a numeric `width` attribute.
  final double? width;

  /// Pixel height, when the source used a numeric `height` attribute.
  final double? height;

  /// Fractional width (0..1) when the source used a percentage value.
  /// Mutually exclusive with [width].
  final double? widthPercent;

  /// Whether this hint carries any usable dimension.
  bool get isEmpty =>
      width == null && height == null && widthPercent == null;
}

/// Rewrites every `github.com/user-attachments/assets/<uuid>` reference in
/// [markdown] to the pre-signed `private-user-images.*` URL from [urlMap],
/// when one is available. Untouched if [urlMap] is empty.
///
/// Fenced-code-block aware: tags inside ``` fences are preserved verbatim.
String rewriteUserAttachmentUrls(
  String markdown, {
  required Map<String, String> urlMap,
}) {
  if (markdown.isEmpty || urlMap.isEmpty) {
    return markdown;
  }

  final lines = markdown.split('\n');
  final result = <String>[];
  var inFencedCodeBlock = false;

  final pattern = RegExp(
    r'https://github\.com/user-attachments/assets/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})',
    caseSensitive: false,
  );

  for (final line in lines) {
    final fenceMatch = RegExp(r'^(\s*)```').firstMatch(line);
    if (fenceMatch != null) {
      result.add(line);
      inFencedCodeBlock = !inFencedCodeBlock;
      continue;
    }
    if (inFencedCodeBlock) {
      result.add(line);
      continue;
    }
    result.add(line.replaceAllMapped(pattern, (m) {
      final uuid = m.group(1)!.toLowerCase();
      return urlMap[uuid] ?? m.group(0)!;
    }));
  }
  return result.join('\n');
}

/// Strips HTML comments (`<!-- ... -->`) from [markdown]. Required because
/// `flutter_markdown_plus` is configured with `encodeHtml: false` and passes
/// raw HTML through as literal text — comments end up visible in the output
/// (e.g. Renovate's `<!-- rebase-check -->` markers in task list items).
///
/// Fenced-code-block aware: comments inside ``` fences are preserved.
String stripHtmlComments(String markdown) {
  if (markdown.isEmpty || !markdown.contains('<!--')) {
    return markdown;
  }

  final fences = <(int, int)>[];
  final lines = markdown.split('\n');
  var offset = 0;
  int? fenceStart;
  final fenceRe = RegExp(r'^\s*```');
  for (final line in lines) {
    if (fenceRe.hasMatch(line)) {
      if (fenceStart == null) {
        fenceStart = offset;
      } else {
        fences.add((fenceStart, offset + line.length));
        fenceStart = null;
      }
    }
    offset += line.length + 1;
  }

  final commentRe = RegExp(r'<!--[\s\S]*?-->');
  return markdown.replaceAllMapped(commentRe, (m) {
    for (final (a, b) in fences) {
      if (m.start >= a && m.start < b) {
        return m.group(0)!;
      }
    }
    return '';
  });
}

/// Whether [body] carries no visible content once HTML comments and surrounding
/// whitespace are removed.
///
/// GitHub PR/issue *templates* are largely `<!-- ... -->` comments, and the
/// renderer hides comments (see [stripHtmlComments]). So a body that reads as
/// empty to a human is frequently not `String.trim().isEmpty` — it still
/// carries the template's comments, which render to nothing and leave a blank
/// gap with no placeholder. Gate the "No description provided." placeholder and
/// the "Add a description" affordance on this instead of a bare `trim()` so an
/// all-comments body is correctly treated as having no description.
///
/// Comments inside fenced code blocks count as content (they're shown
/// verbatim), matching [stripHtmlComments]'s fence-awareness.
bool isMarkdownBodyEffectivelyEmpty(String body) {
  if (body.trim().isEmpty) {
    return true;
  }
  return stripHtmlComments(body).trim().isEmpty;
}

/// Converts raw HTML `<img>` and `<video>` tags into markdown image syntax
/// (`![alt](url)`), and converts bare GitHub user-attachment URLs on their
/// own line into inline images.
///
/// This is necessary because the `flutter_markdown_plus` parser treats HTML
/// tags as raw text (with `encodeHtml: false`) rather than parsing them into
/// `img` elements. GitHub PR bodies often contain raw `<img>` tags from the
/// "Attach files" feature.
///
/// The function is fenced-code-block aware: tags inside fenced code blocks
/// are left untouched.
String preprocessHtmlMediaTags(String markdown) {
  if (markdown.isEmpty) {
    return markdown;
  }

  final lines = markdown.split('\n');
  final result = <String>[];
  var inFencedCodeBlock = false;

  for (final line in lines) {
    final fenceMatch = RegExp(r'^(\s*)```').firstMatch(line);
    if (fenceMatch != null) {
      result.add(line);
      inFencedCodeBlock = !inFencedCodeBlock;
      continue;
    }

    if (inFencedCodeBlock) {
      result.add(line);
      continue;
    }

    result.add(_processMediaLine(line));
  }

  return result.join('\n');
}

String _processMediaLine(String line) {
  var processed = line;

  processed = processed.replaceAllMapped(
    RegExp(r'<img\b[^>]*/?\s*>', caseSensitive: false),
    (m) => _convertImgTag(m.group(0)!),
  );

  processed = processed.replaceAllMapped(
    RegExp(r'<video\b[^>]*>.*?</video\s*>', caseSensitive: false, dotAll: true),
    (m) => _convertVideoTag(m.group(0)!),
  );

  processed = processed.replaceAllMapped(
    RegExp(r'<video\b[^>]*/?\s*>', caseSensitive: false),
    (m) => _convertVideoTag(m.group(0)!),
  );

  // Catches both the raw `github.com/user-attachments/assets/<uuid>` form
  // and the spliced `private-user-images.*?jwt=...` form (post-rewrite).
  final bareUrlMatch = RegExp(
    r'^\s*(https://github\.com/user-attachments/assets/[a-f0-9-]+'
    r'|https://private-user-images\.githubusercontent\.com/[^\s]+)\s*$',
  ).firstMatch(processed);
  if (bareUrlMatch != null) {
    final url = bareUrlMatch.group(1)!;
    return '![GitHub attachment]($url)';
  }

  return processed;
}

String _convertImgTag(String tag) {
  final src = _extractAttr(tag, 'src');
  if (src == null) {
    return tag;
  }

  final alt = _extractAttr(tag, 'alt') ?? '';
  return '![${_encodeAltWithDimensions(tag, alt)}]($src)';
}

/// Sentinel prefix used to smuggle `<img>` dimensions through the markdown
/// pipeline via the alt-text. We can't use the URL fragment (`#WxH`)
/// because `flutter_markdown_plus` strips it before calling our
/// `imageBuilder` — see its `builder.dart:600`. Alt text, on the other
/// hand, is passed through verbatim.
///
/// Encoded form: `ccdim:w=NNN&h=NNN|<original alt>`. Real alt text
/// effectively never starts with `ccdim:` so collisions are negligible.
/// Public sentinel — alt text starting with this carries dimension hints.
const String ccDimSentinel = 'ccdim:';
/// Separator between the encoded payload and the original alt text.
const String ccDimDelimiter = '|';

/// If the tag carries `width` / `height` attributes, returns
/// `ccdim:w=NNN&h=NNN|<alt>`. Otherwise returns [alt] unchanged.
String _encodeAltWithDimensions(String tag, String alt) {
  final parts = <String>[];
  final w = _parseDimension(_extractAttr(tag, 'width'));
  if (w != null) {
    parts.add('w=$w');
  }
  final h = _parseDimension(_extractAttr(tag, 'height'));
  if (h != null) {
    parts.add('h=$h');
  }
  if (parts.isEmpty) {
    return alt;
  }
  return '$ccDimSentinel${parts.join('&')}$ccDimDelimiter$alt';
}

/// Result of [decodeAltWithDimensions]: original alt minus the sentinel,
/// plus any dimension hints recovered from the prefix.
class AltDecodeResult {
  /// Creates an [AltDecodeResult].
  const AltDecodeResult({required this.alt, required this.hint});

  /// Alt text with the `ccdim:` prefix stripped (or the original, untouched
  /// alt when no sentinel was present).
  final String alt;

  /// Dimension hint recovered from the sentinel. Empty when no sentinel was
  /// present or the encoded payload was malformed.
  final ImageDimensionHint hint;
}

/// Strips the `ccdim:w=NNN&h=NNN|` prefix (if any) from [alt] and returns
/// the remaining text plus the parsed dimension hint. Always succeeds —
/// when no sentinel is present, returns [alt] unchanged with an empty hint.
AltDecodeResult decodeAltWithDimensions(String? alt) {
  if (alt == null || !alt.startsWith(ccDimSentinel)) {
    return AltDecodeResult(alt: alt ?? '', hint: const ImageDimensionHint());
  }
  final pipe = alt.indexOf(ccDimDelimiter, ccDimSentinel.length);
  if (pipe < 0) {
    return AltDecodeResult(alt: alt, hint: const ImageDimensionHint());
  }
  final payload = alt.substring(ccDimSentinel.length, pipe);
  final rest = alt.substring(pipe + 1);

  double? widthPx;
  double? heightPx;
  double? widthPct;
  for (final part in payload.split('&')) {
    final eq = part.indexOf('=');
    if (eq <= 0) {
      continue;
    }
    final key = part.substring(0, eq);
    final value = part.substring(eq + 1);
    final isPercent = value.endsWith('p');
    final numeric = double.tryParse(
      isPercent ? value.substring(0, value.length - 1) : value,
    );
    if (numeric == null) {
      continue;
    }
    switch (key) {
      case 'w':
        if (isPercent) {
          widthPct = numeric / 100.0;
        } else {
          widthPx = numeric;
        }
      case 'h':
        if (!isPercent) {
          heightPx = numeric;
        }
    }
  }
  return AltDecodeResult(
    alt: rest,
    hint: ImageDimensionHint(
      width: widthPx,
      height: heightPx,
      widthPercent: widthPct,
    ),
  );
}

/// Parses an HTML `width`/`height` attribute. Accepts bare integers and
/// `NNNpx` (returns `"NNN"`), and percentages `NNN%` (returns `"NNNp"`).
/// Returns null for anything else (e.g. `auto`, empty, non-numeric).
String? _parseDimension(String? raw) {
  if (raw == null) {
    return null;
  }
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final percent = RegExp(r'^(\d+(?:\.\d+)?)\s*%$').firstMatch(trimmed);
  if (percent != null) {
    return '${percent.group(1)}p';
  }

  final px = RegExp(r'^(\d+(?:\.\d+)?)\s*(?:px)?$').firstMatch(trimmed);
  if (px != null) {
    return px.group(1);
  }
  return null;
}

String _convertVideoTag(String tag) {
  final poster = _extractAttr(tag, 'poster');
  if (poster != null) {
    final alt = _extractAttr(tag, 'alt') ?? '';
    final label = alt.isNotEmpty ? alt : 'video';
    return '![🎬 $label]($poster)';
  }

  final src = _extractAttr(tag, 'src');
  if (src != null) {
    final alt = _extractAttr(tag, 'alt') ?? '';
    final label = alt.isNotEmpty ? alt : 'video';
    return '[🎬 $label]($src)';
  }

  final sourceSrc = RegExp(
    "<source\\b[^>]*src\\s*=\\s*[\"']([^\"']*)[\"']",
    caseSensitive: false,
  ).firstMatch(tag);
  if (sourceSrc != null) {
    return '[🎬 video](${sourceSrc.group(1)})';
  }

  return tag;
}

String? _extractAttr(String tag, String name) {
  final match = RegExp(
    "$name\\s*=\\s*[\"']([^\"']*)[\"']",
    caseSensitive: false,
  ).firstMatch(tag);
  return match?.group(1);
}

/// Converts GitHub shorthand references inside markdown text into proper
/// markdown links with the app's deep-link scheme.
///
/// The preprocessor is conservative: it skips fenced code blocks, inline
/// code, heading lines, and hex colours so that references inside code
/// examples or CSS values are left untouched.
///
/// Recognised patterns:
///   * `#123`                 → `[#123](control-center://pr/<owner>/<repo>/123)`
///   * `owner/repo#123`       → `[owner/repo#123](control-center://pr/owner/repo/123)`
///
/// Using the deep-link scheme means a copy-paste of the rendered link also
/// opens the PR in the desktop app via the OS URL handler.
///
/// [owner] and [repo] describe the repository the markdown content belongs
/// to, so that bare `#123` references can be resolved.
String preprocessGitHubReferences(
  String markdown, {
  required String owner,
  required String repo,
}) {
  if (markdown.isEmpty) {
    return markdown;
  }

  final lines = markdown.split('\n');
  final result = <String>[];
  var inFencedCodeBlock = false;

  for (final line in lines) {
    // Toggle fenced-code-block state.  We treat a line that starts with
    // three backticks (and nothing but optional whitespace before them)
    // as a fence marker.
    final fenceMatch = RegExp(r'^(\s*)```').firstMatch(line);
    if (fenceMatch != null) {
      result.add(line);
      inFencedCodeBlock = !inFencedCodeBlock;
      continue;
    }

    if (inFencedCodeBlock) {
      result.add(line);
      continue;
    }

    // Skip heading lines (start with `# `, `## `, etc.).  We only skip when
    // there is a space after the hash sequence so that a line like
    // `#42 is fixed` is still processed.
    if (RegExp(r'^#{1,6} ').hasMatch(line)) {
      result.add(line);
      continue;
    }

    result.add(_processLine(line, owner: owner, repo: repo));
  }

  return result.join('\n');
}

// ---------------------------------------------------------------------------
// Line-level processing
// ---------------------------------------------------------------------------

/// Replaces shorthand references in a single line, taking care not to
/// touch text inside inline code spans (`...`).
String _processLine(String line, {required String owner, required String repo}) {
  // Find inline code regions so we can skip them during replacement.
  final codeRegions = _findInlineCodeRegions(line);

  // Build a safe replacement function that checks whether a match falls
  // inside an inline code region.
  String replaceIfOutside(
    RegExp pattern,
    String Function(Match) replacer,
  ) {
    return line.replaceAllMapped(pattern, (match) {
      if (_isInsideRegions(match.start, match.end, codeRegions)) {
        return match.group(0)!; // leave untouched
      }
      return replacer(match);
    });
  }

  var processed = line;

  // Cross-repo shorthand: `owner/repo#123`.
  // Negative lookbehind avoids matching when preceded by `.`, `/`, `&`, or a
  // word character (so we don't corrupt existing URLs, markdown links, or
  // HTML entities like `&#8203;`).
  processed = replaceIfOutside(
    RegExp(r'(?<![.\w/&])([\w-]+)/([\w-]+)#(\d{1,7})\b'),
    (m) => '[${m.group(0)}](control-center://pr/${m.group(1)}/${m.group(2)}/${m.group(3)})',
  );

  // Same-repo shorthand: `#123` (must NOT be preceded by `.`, `/`, `&`, or a
  // word character, and must NOT be a 6-digit hex colour).
  processed = replaceIfOutside(
    RegExp(r'(?<![.\w/&])#(\d{1,7})\b'),
    (m) {
      final number = m.group(1)!;
      // 6-digit-only numbers look like hex colours → skip.
      if (number.length == 6) {
        return m.group(0)!;
      }
      return '[#$number](control-center://pr/$owner/$repo/$number)';
    },
  );

  return processed;
}

// ---------------------------------------------------------------------------
// Inline code helpers
// ---------------------------------------------------------------------------

/// Returns a list of `(start, end)` character ranges that are inside inline
/// code spans (single or double backtick delimiters).
List<(int, int)> _findInlineCodeRegions(String line) {
  final regions = <(int, int)>[];
  var i = 0;
  while (i < line.length) {
    final backtick = line.indexOf('`', i);
    if (backtick == -1) {
      break;
    }

    // Count consecutive backticks.
    var count = 0;
    var j = backtick;
    while (j < line.length && line[j] == '`') {
      count++;
      j++;
    }

    // Find closing run of the same count.
    final close = line.indexOf('`' * count, j);
    if (close == -1) {
      break;
    }

    regions.add((backtick, close + count));
    i = close + count;
  }
  return regions;
}

/// Returns `true` when `[start, end)` overlaps any of the given regions.
bool _isInsideRegions(int start, int end, List<(int, int)> regions) {
  for (final (rStart, rEnd) in regions) {
    if (start < rEnd && end > rStart) {
      return true;
    }
  }
  return false;
}

// ---------------------------------------------------------------------------
// Video embeds (Loom, …)
// ---------------------------------------------------------------------------

/// Rewrites standalone third-party video links into inline markdown images so
/// the renderer's `imageBuilder` can swap them for an embedded player.
///
/// A line that consists solely of a recognised provider URL — bare
/// (`loom.com/share/<id>`), as an autolink (`<https://…>`), or as a markdown
/// link (`[label](https://…)`) — is replaced with
/// `![<Provider> video](<embed-url> "<source-url>")`. The [registry] decides
/// what's recognised and produces the embed URL (e.g. Loom's `share` → `embed`
/// swap). Everything else — links inside prose, code fences, non-provider URLs
/// — is left untouched, so this never mangles a paragraph.
///
/// Fenced-code-block aware: lines inside ``` fences pass through verbatim.
String preprocessVideoEmbeds(
  String markdown, {
  VideoEmbedRegistry registry = VideoEmbedRegistry.instance,
}) {
  if (markdown.isEmpty) {
    return markdown;
  }

  final lines = markdown.split('\n');
  final result = <String>[];
  var inFencedCodeBlock = false;
  final fenceRe = RegExp(r'^(\s*)```');

  for (final line in lines) {
    if (fenceRe.hasMatch(line)) {
      result.add(line);
      inFencedCodeBlock = !inFencedCodeBlock;
      continue;
    }
    if (inFencedCodeBlock) {
      result.add(line);
      continue;
    }
    result.add(_processEmbedLine(line, registry));
  }

  return result.join('\n');
}

/// Rewrites a single (non-fenced) line for video embeds:
///   * If the whole line is one recognised provider link, it's replaced by the
///     embed player marker.
///   * If a recognised link appears inline amongst other text (e.g.
///     `🎥 Loom walkthrough: [..](..)`), the line is kept as-is and an embed
///     player block is appended below it.
///   * Otherwise the line is returned untouched.
String _processEmbedLine(String line, VideoEmbedRegistry registry) {
  final sole = _embedMarkerForLine(line.trim(), registry);
  if (sole != null) {
    return sole;
  }
  final inline = _inlineEmbedMarkers(line, registry);
  if (inline.isEmpty) {
    return line;
  }
  // Keep the original line (caption + clickable link) and drop the player(s)
  // below it as their own block(s). The leading/trailing blank lines keep the
  // image markers from being folded into the caption's paragraph.
  return '$line\n\n${inline.join('\n\n')}\n';
}

/// Returns the embed image marker for [trimmed] when it's a standalone
/// recognised provider link, or `null` to leave the line untouched.
String? _embedMarkerForLine(String trimmed, VideoEmbedRegistry registry) {
  if (trimmed.isEmpty) {
    return null;
  }
  final candidate = _soleUrlCandidate(trimmed);
  if (candidate == null) {
    return null;
  }
  return _embedMarker(candidate, registry);
}

/// Finds every recognised provider link *within* [line] (markdown links,
/// autolinks, then bare URLs) and returns one embed marker per distinct
/// provider URL, in appearance order. Markdown-link spans are masked before
/// the bare scan so a `[url](url)` link isn't counted twice.
List<String> _inlineEmbedMarkers(String line, VideoEmbedRegistry registry) {
  final markers = <String>[];
  final seen = <String>{};

  void consider(String? raw) {
    if (raw == null) {
      return;
    }
    final marker = _embedMarker(_trimUrlPunctuation(raw), registry, seen: seen);
    if (marker != null) {
      markers.add(marker);
    }
  }

  var masked = line;
  masked = masked.replaceAllMapped(_mdLinkInlineRe, (m) {
    consider(m.group(1));
    return ' ' * m.group(0)!.length;
  });
  masked = masked.replaceAllMapped(_autolinkInlineRe, (m) {
    consider(m.group(1));
    return ' ' * m.group(0)!.length;
  });
  for (final m in _bareUrlInlineRe.allMatches(masked)) {
    consider(m.group(0));
  }
  return markers;
}

/// Builds the embed image marker for [rawUrl] when [registry] recognises it,
/// or `null` otherwise. When [seen] is provided, a URL whose embed form was
/// already emitted is skipped (returns `null`) so duplicates collapse.
String? _embedMarker(
  String rawUrl,
  VideoEmbedRegistry registry, {
  Set<String>? seen,
}) {
  final normalized = _normalizeUrl(rawUrl);
  if (normalized == null) {
    return null;
  }
  final match = registry.resolve(normalized);
  if (match == null) {
    return null;
  }
  if (seen != null && !seen.add(match.embedUrl.toString())) {
    return null;
  }
  // Carry the original URL through the markdown image `title` so the embed
  // widget can offer an "open externally" fallback that points at the link the
  // author actually wrote.
  return '![${match.adapter.providerName} video](${match.embedUrl} "$normalized")';
}

/// Strips trailing sentence punctuation a bare URL may have picked up (e.g. a
/// period or closing bracket at the end of a sentence).
String _trimUrlPunctuation(String url) =>
    url.replaceAll(RegExp(r'''[.,;:!?)\]}'"]+$'''), '');

final RegExp _mdLinkInlineRe = RegExp(
  r'''\[[^\]]*\]\(\s*<?([^()\s]+?)>?(?:\s+"[^"]*"|\s+'[^']*')?\s*\)''',
);
final RegExp _autolinkInlineRe = RegExp(r'<([^>\s]+)>');
// A bare domain/URL token: optional scheme, one or more dot-separated labels,
// an alphabetic TLD, and an optional path. The registry gates which of these
// actually become embeds, so over-matching unrelated domains is harmless.
final RegExp _bareUrlInlineRe = RegExp(
  r'(?:https?://)?(?:[\w-]+\.)+[A-Za-z]{2,}(?:/[^\s)]*)?',
  caseSensitive: false,
);

final RegExp _mdLinkLineRe = RegExp(
  r'''^\[[^\]]*\]\(\s*<?([^()\s]+?)>?(?:\s+"[^"]*"|\s+'[^']*')?\s*\)$''',
);
final RegExp _autolinkLineRe = RegExp(r'^<([^>\s]+)>$');
// A bare token that looks like a domain/URL — has a dot-suffixed TLD and no
// whitespace. Excludes things like a stray `![a](b)` image (no bare TLD).
final RegExp _bareUrlLineRe = RegExp(
  r'^(https?://)?[\w.-]+\.[A-Za-z]{2,}(?:/\S*)?$',
);

/// Extracts the single URL a line is made of — as a markdown link, an
/// autolink, or a bare URL — or `null` when the line isn't a lone URL.
String? _soleUrlCandidate(String trimmed) {
  final link = _mdLinkLineRe.firstMatch(trimmed);
  if (link != null) {
    return link.group(1);
  }
  final auto = _autolinkLineRe.firstMatch(trimmed);
  if (auto != null) {
    return auto.group(1);
  }
  if (_bareUrlLineRe.hasMatch(trimmed)) {
    return trimmed;
  }
  return null;
}

/// Parses [raw] into a [Uri], prepending `https://` when it carries no scheme
/// so a bare `loom.com/share/<id>` resolves to a host rather than a path.
Uri? _normalizeUrl(String raw) {
  final withScheme = raw.contains('://') ? raw : 'https://$raw';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || uri.host.isEmpty) {
    return null;
  }
  return uri;
}
