import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/site_extractors.dart';

/// Fetches a URL and returns its readable text content (HTML stripped to plain
/// text / light markdown). Network-tier via the exec gate — a fetch reaches
/// outside the sandbox, so it is confirmation-gated like a command.
///
/// Hardened against SSRF: the target host is resolved and any address that is
/// loopback, link-local (incl. the `169.254.169.254` cloud-metadata endpoint),
/// private, or otherwise internal is refused. The response is read with an
/// inactivity timeout and a hard byte cap so a slow or huge response cannot hang
/// the run or exhaust memory. When [allowNetwork] is false the tool is disabled
/// entirely (honors the agent's network capability).
class WebFetchTool extends HarnessTool {
  /// Creates a [WebFetchTool] with an optional [maxChars] output cap.
  WebFetchTool({
    this.maxChars = 20000,
    this.allowNetwork = true,
    Duration? timeout,
    HttpClient? client,
  }) : _timeout = timeout ?? const Duration(seconds: 30),
       _client = client ?? (HttpClient()..connectionTimeout = _connectTimeout);

  static const Duration _connectTimeout = Duration(seconds: 15);

  /// Maximum characters of extracted text returned (older content truncated).
  final int maxChars;

  /// When false the tool refuses every fetch (agent has no network capability).
  final bool allowNetwork;

  /// Inactivity timeout for connecting and reading the response.
  final Duration _timeout;
  final HttpClient _client;

  /// Hard cap on bytes read from the response body before truncation.
  static const int _maxBodyBytes = 5 * 1024 * 1024;

  /// Redirect hops followed, each re-validated against the SSRF guard.
  static const int _maxRedirects = 5;

  @override
  String get name => 'web_fetch';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.networkEgress};

  @override
  String get description =>
      'Fetch a URL and return its readable text content (HTML converted to '
      'plain text). Use for docs, articles and pages. Returns truncated text '
      'for very large pages.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.exec;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'url': {'type': 'string', 'description': 'The absolute http(s) URL.'},
    },
    'required': ['url'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    if (!allowNetwork) {
      return HarnessToolResult.error(
        'Network access is disabled for this agent; web_fetch is unavailable.',
      );
    }
    final url = args['url'];
    if (url is! String || url.isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: url');
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return HarnessToolResult.error('Invalid URL (must be http/https): $url');
    }
    // SSRF guard: resolve the host and refuse if any resolved address is
    // internal (loopback / link-local / private / metadata).
    final blocked = await _blockedReason(uri.host);
    if (blocked != null) {
      return HarnessToolResult.error('Refusing to fetch $url: $blocked');
    }
    try {
      // Redirects are followed MANUALLY, one hop at a time, re-running the
      // SSRF guard on each. `followRedirects: true` let dart:io chase a 302
      // from a permitted public host straight to `169.254.169.254` — the
      // pre-fetch check had already passed and nothing looked again, so the
      // thorough internal-address classifier below was decided before the only
      // hop that mattered.
      var current = uri;
      HttpClientResponse? response;
      for (var hop = 0; hop <= _maxRedirects; hop++) {
        final request = await _client.getUrl(current).timeout(_timeout);
        request.followRedirects = false;
        request.headers.set(
          HttpHeaders.userAgentHeader,
          'ControlCenter-Agent/1.0',
        );
        request.headers.set(
          HttpHeaders.acceptHeader,
          'text/html,text/plain,*/*',
        );
        final hopResponse = await request.close().timeout(_timeout);
        if (!hopResponse.isRedirect || hop == _maxRedirects) {
          response = hopResponse;
          break;
        }
        final location = hopResponse.headers.value(HttpHeaders.locationHeader);
        await hopResponse.drain<void>();
        if (location == null || location.isEmpty) {
          return HarnessToolResult.error(
            'Redirect with no Location header fetching $url',
          );
        }
        final next = current.resolve(location);
        if (!(next.isScheme('http') || next.isScheme('https'))) {
          return HarnessToolResult.error(
            'Refusing to follow a non-http(s) redirect to $next',
          );
        }
        final hopBlocked = await _blockedReason(next.host);
        if (hopBlocked != null) {
          return HarnessToolResult.error(
            'Refusing to follow redirect to $next: $hopBlocked',
          );
        }
        current = next;
      }
      if (response == null) {
        return HarnessToolResult.error('Too many redirects fetching $url');
      }
      if (response.statusCode >= 400) {
        return HarnessToolResult.error(
          'HTTP ${response.statusCode} fetching $url',
        );
      }
      // Read incrementally with a hard byte cap and idle timeout so a huge or
      // slow body cannot exhaust memory or hang the run.
      // A `List<int>` stores one boxed pointer slot per byte — a 5 MB page
      // becomes ~40 MB of heap. BytesBuilder keeps the chunks as the typed
      // byte lists the socket already handed us.
      final builder = BytesBuilder(copy: false);
      var overflowed = false;
      await for (final chunk in response.timeout(_timeout)) {
        builder.add(chunk);
        if (builder.length > _maxBodyBytes) {
          overflowed = true;
          break;
        }
      }
      final bytes = builder.takeBytes();
      // Decode with the response charset when known; tolerate malformed bytes
      // rather than failing the whole fetch on one bad byte.
      final charset = response.headers.contentType?.charset;
      final codec = charset == null
          ? utf8
          : (Encoding.getByName(charset) ?? utf8);
      final String body;
      if (codec is Utf8Codec) {
        body = codec.decode(bytes, allowMalformed: true);
      } else {
        body = codec.decode(bytes);
      }
      final contentType = response.headers.contentType?.mimeType ?? 'text/html';
      // Site-aware extraction first: a GitHub issue, a Stack Overflow answer
      // or a pub.dev page has a STRUCTURE, and tag-stripping it into prose
      // throws that structure away — the agent then has to guess which
      // paragraph was the answer. Falls back to generic text whenever a site
      // is unknown or its markup has moved, so a layout change degrades to
      // the old behaviour rather than to an error.
      final text = contentType.contains('html')
          ? (extractSiteContent(uri, body) ?? _htmlToText(body))
          : body.trim();
      if (text.isEmpty) {
        return HarnessToolResult.success('(no readable text at $url)');
      }
      final capped = text.length > maxChars
          ? '${text.substring(0, maxChars)}\n…[truncated ${text.length - maxChars} chars]'
          : text;
      final suffix = overflowed
          ? '\n…[response exceeded ${_maxBodyBytes ~/ (1024 * 1024)}MB; '
                'truncated]'
          : '';
      return HarnessToolResult.success('# $url\n\n$capped$suffix');
    } on Object catch (e) {
      return HarnessToolResult.error('Failed to fetch $url: $e');
    }
  }

  /// Returns a human-readable reason when [host] resolves to an internal
  /// address that must not be fetched, or null when the host is safe.
  static Future<String?> _blockedReason(String host) async {
    if (host.isEmpty) {
      return 'empty host';
    }
    final List<InternetAddress> addresses;
    final literal = InternetAddress.tryParse(host);
    if (literal != null) {
      addresses = [literal];
    } else {
      try {
        addresses = await InternetAddress.lookup(
          host,
        ).timeout(const Duration(seconds: 5));
      } on Object {
        return 'could not resolve host';
      }
      if (addresses.isEmpty) {
        return 'could not resolve host';
      }
    }
    for (final addr in addresses) {
      if (_isInternal(addr)) {
        return 'resolves to an internal address (${addr.address})';
      }
    }
    return null;
  }

  /// Whether [addr] is a loopback, link-local, private, or otherwise internal
  /// address that an agent must not reach over the network.
  static bool _isInternal(InternetAddress addr) {
    if (addr.isLoopback || addr.isLinkLocal || addr.isMulticast) {
      return true;
    }
    final b = addr.rawAddress;
    if (addr.type == InternetAddressType.IPv4) {
      // this-network / loopback / RFC1918 private / link-local / CGNAT.
      if (b[0] == 0 || b[0] == 127) {
        return true;
      }
      if (b[0] == 10) {
        return true;
      }
      if (b[0] == 172 && b[1] >= 16 && b[1] <= 31) {
        return true;
      }
      if (b[0] == 192 && b[1] == 168) {
        return true;
      }
      if (b[0] == 169 && b[1] == 254) {
        return true;
      }
      if (b[0] == 100 && b[1] >= 64 && b[1] <= 127) {
        return true;
      }
      return false;
    }
    // IPv6.
    final isUnspecified = b.every((byte) => byte == 0);
    if (isUnspecified) {
      return true;
    }
    if ((b[0] & 0xfe) == 0xfc) {
      return true; // fc00::/7 unique-local
    }
    // IPv4-mapped ::ffff:a.b.c.d — re-check the embedded IPv4.
    final isV4Mapped =
        b.take(10).every((byte) => byte == 0) && b[10] == 0xff && b[11] == 0xff;
    if (isV4Mapped) {
      return _isInternal(
        InternetAddress.fromRawAddress(Uint8List.fromList(b.sublist(12, 16))),
      );
    }
    return false;
  }

  /// Dependency-free HTML → text: drop script/style, convert breaks/headings to
  /// newlines, strip remaining tags, decode common entities, collapse blank
  /// runs. Not a full readability pass, but enough for an agent to read a page.
  /// Test seam for [_htmlToText] (`meta` is not a dependency here, so this
  /// carries the intent in its name rather than in an annotation).
  static String debugHtmlToText(String html) => _htmlToText(html);

  /// One pass over the source, not nine `replaceAll`s.
  ///
  /// Each `replaceAll` allocated a fresh full copy of the page, so a 5 MB body
  /// churned ~50 MB of transient strings per fetch. This walks the input once,
  /// writing directly into the output buffer, and folds the entity decode and
  /// whitespace collapse into the same pass.
  static String _htmlToText(String html) {
    final out = StringBuffer();
    // Pending whitespace is buffered rather than written, so runs collapse
    // without a second pass: `_pendingNewlines` counts hard breaks (capped at
    // the blank-line squeeze) and `_pendingSpace` a soft space.
    var pendingNewlines = 0;
    var pendingSpace = false;
    var pendingBullet = false;
    var wroteAnything = false;

    void flushWhitespace() {
      if (!wroteAnything) {
        // Leading whitespace is trimmed — but a leading list bullet is
        // content, not whitespace, so it still goes out.
        if (pendingBullet) {
          out.write('- ');
          wroteAnything = true;
        }
        pendingNewlines = 0;
        pendingSpace = false;
        pendingBullet = false;
        return;
      }
      if (pendingNewlines > 0) {
        out.write(pendingNewlines >= 2 ? '\n\n' : '\n');
        if (pendingBullet) {
          out.write('- ');
        }
      } else if (pendingBullet) {
        out.write('\n- ');
      } else if (pendingSpace) {
        out.write(' ');
      }
      pendingNewlines = 0;
      pendingSpace = false;
      pendingBullet = false;
    }

    void writeText(String text) {
      if (text.isEmpty) {
        return;
      }
      flushWhitespace();
      out.write(text);
      wroteAnything = true;
    }

    var i = 0;
    while (i < html.length) {
      final c = html.codeUnitAt(i);
      if (c == 0x3C /* < */ ) {
        final close = html.indexOf('>', i + 1);
        if (close < 0) {
          // Unterminated tag: the rest is not markup, treat it as text.
          writeText(html.substring(i));
          break;
        }
        final tag = html.substring(i + 1, close);
        final tagName = _tagName(tag);
        if (_skippedElements.contains(tagName) && !tag.startsWith('/')) {
          final endIdx = _indexOfCloseTag(html, tagName, close + 1);
          if (endIdx >= 0) {
            // Drop the element's whole body along with it.
            pendingSpace = true;
            i = endIdx;
            continue;
          }
          // No closing tag: fall through and treat the opener as an ordinary
          // tag rather than swallowing the rest of the document. A body cut
          // off at the size cap mid-script must not lose everything after it.
        }
        if (tagName == 'br') {
          pendingNewlines = pendingNewlines < 2 ? pendingNewlines + 1 : 2;
        } else if (tag.startsWith('/') && _blockElements.contains(tagName)) {
          pendingNewlines = pendingNewlines < 2 ? pendingNewlines + 1 : 2;
        } else if (tagName == 'li') {
          pendingNewlines = pendingNewlines < 1 ? 1 : pendingNewlines;
          pendingBullet = true;
        } else {
          pendingSpace = true;
        }
        i = close + 1;
        continue;
      }
      if (c == 0x26 /* & */ ) {
        final decoded = _decodeEntityAt(html, i);
        if (decoded != null) {
          // `&nbsp;` decodes to a space, which must collapse with surrounding
          // whitespace the same way a literal space does.
          if (decoded.$1 == ' ') {
            pendingSpace = true;
          } else {
            writeText(decoded.$1);
          }
          i = decoded.$2;
          continue;
        }
      }
      if (c == 0x0A || c == 0x0D) {
        pendingNewlines = pendingNewlines < 2 ? pendingNewlines + 1 : 2;
        i++;
        continue;
      }
      if (c == 0x20 || c == 0x09) {
        pendingSpace = true;
        i++;
        continue;
      }
      // A run of ordinary characters — copy it in one slice.
      final start = i;
      while (i < html.length) {
        final n = html.codeUnitAt(i);
        if (n == 0x3C ||
            n == 0x26 ||
            n == 0x0A ||
            n == 0x0D ||
            n == 0x20 ||
            n == 0x09) {
          break;
        }
        i++;
      }
      writeText(html.substring(start, i));
    }
    return out.toString();
  }

  /// Elements whose entire content is dropped.
  static const Set<String> _skippedElements = {
    'script',
    'style',
    'head',
    'noscript',
  };

  /// Elements whose closing tag ends a line.
  static const Set<String> _blockElements = {
    'p',
    'div',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'li',
    'tr',
    'section',
    'article',
    'header',
    'footer',
  };

  /// The lower-cased element name of a tag body (`"/DIV class=x"` → `"div"`).
  static String _tagName(String tag) {
    var start = 0;
    if (start < tag.length && tag.codeUnitAt(start) == 0x2F /* / */ ) {
      start++;
    }
    var end = start;
    while (end < tag.length) {
      final c = tag.codeUnitAt(end);
      final isAlnum =
          (c >= 0x30 && c <= 0x39) ||
          (c >= 0x41 && c <= 0x5A) ||
          (c >= 0x61 && c <= 0x7A);
      if (!isAlnum) {
        break;
      }
      end++;
    }
    return tag.substring(start, end).toLowerCase();
  }

  /// Index just past `</name>` at or after [from], or -1 when absent.
  static int _indexOfCloseTag(String html, String name, int from) {
    var i = from;
    while (i < html.length) {
      final lt = html.indexOf('<', i);
      if (lt < 0) {
        return -1;
      }
      final gt = html.indexOf('>', lt + 1);
      if (gt < 0) {
        return -1;
      }
      final tag = html.substring(lt + 1, gt);
      if (tag.startsWith('/') && _tagName(tag) == name) {
        return gt + 1;
      }
      i = gt + 1;
    }
    return -1;
  }

  /// The entity starting at [i] as (text, nextIndex), or null when [i] does not
  /// start one of the handled entities.
  static (String, int)? _decodeEntityAt(String s, int i) {
    for (final entry in _entities.entries) {
      if (s.startsWith(entry.key, i)) {
        return (entry.value, i + entry.key.length);
      }
    }
    return null;
  }

  static const Map<String, String> _entities = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
  };
}
