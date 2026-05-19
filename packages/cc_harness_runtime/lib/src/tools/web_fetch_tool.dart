import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_harness/tools.dart';

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

  @override
  String get name => 'web_fetch';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.networkEgress};

  @override
  String get description =>
      'Fetch a URL and return its readable text content (HTML converted to '
      'plain text). Use for docs, articles, and pages. Returns truncated text '
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
      final request = await _client.getUrl(uri).timeout(_timeout);
      request.followRedirects = true;
      request.maxRedirects = 5;
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'ControlCenter-Agent/1.0',
      );
      request.headers.set(HttpHeaders.acceptHeader, 'text/html,text/plain,*/*');
      final response = await request.close().timeout(_timeout);
      if (response.statusCode >= 400) {
        return HarnessToolResult.error(
          'HTTP ${response.statusCode} fetching $url',
        );
      }
      // Read incrementally with a hard byte cap and idle timeout so a huge or
      // slow body cannot exhaust memory or hang the run.
      final bytes = <int>[];
      var overflowed = false;
      await for (final chunk in response.timeout(_timeout)) {
        bytes.addAll(chunk);
        if (bytes.length > _maxBodyBytes) {
          overflowed = true;
          break;
        }
      }
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
      final text = contentType.contains('html')
          ? _htmlToText(body)
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
  static String _htmlToText(String html) {
    var s = html;
    s = s.replaceAll(
      RegExp(
        r'<(script|style|head|noscript)[^>]*>.*?</\1>',
        caseSensitive: false,
        dotAll: true,
      ),
      ' ',
    );
    s = s.replaceAll(
      RegExp(
        r'</(p|div|h[1-6]|li|tr|section|article|header|footer)>',
        caseSensitive: false,
      ),
      '\n',
    );
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n- ');
    s = s.replaceAll(RegExp(r'<[^>]+>'), ' ');
    s = _decodeEntities(s);
    // Collapse spaces then squeeze blank lines.
    s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
    s = s.replaceAll(RegExp(r'\n[ \t]+'), '\n');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  static String _decodeEntities(String s) => s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
}
