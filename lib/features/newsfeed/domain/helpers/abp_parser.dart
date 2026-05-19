/// Parses ABP-format filter lists into CSS element-hiding rules and
/// ContentBlocker-style network-block entries.
///
/// Only supports universal element-hiding rules (`##…`) and simple
/// network-block rules (`||domain.com^`). Everything else is skipped.
/// Parses ABP-format filter lists into CSS element-hiding rules and
/// ContentBlocker-style network-block entries.
// ignore: avoid_classes_with_only_static_members
class AbpParser {
  AbpParser._();

  /// Parses a raw ABP filter list string.
  static AbpParseResult parse(String raw) {
    final cssSelectors = <String>[];
    final domainHides = <DomainHide>[];
    final blocklist = <Map<String, dynamic>>[];
    final scriptlets = <ScriptletInjection>[];

    final lines = const LineSplitter().convert(raw);
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (trimmed.startsWith('!')) {
        continue;
      }
      if (trimmed.startsWith('[')) {
        continue;
      }

      // Universal element-hiding rule (`##selector`, no domain prefix).
      if (trimmed.startsWith('##')) {
        final selector = trimmed.substring(2);
        // Universal scriptlet rule (`##+js(name, args)`) — rare but valid.
        final scriptlet = _parseScriptletSelector(selector, const <String>[]);
        if (scriptlet != null) {
          scriptlets.add(scriptlet);
          continue;
        }
        if (_isValidCssSelector(selector)) {
          cssSelectors.add(selector);
        }
        continue;
      }

      // Skip exception rules — both network (`@@`) and element-hide
      // unhide (`#@#`).
      if (trimmed.startsWith('@@') || trimmed.contains('#@#')) {
        continue;
      }

      // Domain-specific element-hiding rule (`domain.com##selector` or
      // `d1.com,d2.com##selector`). Also covers scriptlet injections
      // (`domain.com##+js(name, args)`).
      final hideIdx = trimmed.indexOf('##');
      if (hideIdx > 0) {
        final domains = _parseDomainList(trimmed.substring(0, hideIdx));
        if (domains.isEmpty) {
          continue;
        }
        final selector = trimmed.substring(hideIdx + 2);
        final scriptlet = _parseScriptletSelector(selector, domains);
        if (scriptlet != null) {
          scriptlets.add(scriptlet);
          continue;
        }
        final hide = _parseDomainHide(selector, domains);
        if (hide != null) {
          domainHides.add(hide);
        }
        continue;
      }

      // Skip regex filters.
      if (trimmed.startsWith('/') && trimmed.endsWith('/')) {
        continue;
      }

      // Network-block rule.
      if (trimmed.startsWith('||')) {
        final entry = _parseNetworkRule(trimmed);
        if (entry != null) {
          blocklist.add(entry);
        }
        continue;
      }

      // Skip everything else (generic filters, etc.).
    }

    return AbpParseResult(
      cssSelectors: cssSelectors,
      domainHides: domainHides,
      blocklist: blocklist,
      scriptlets: scriptlets,
    );
  }

  /// Parses the domain list in front of `##` (e.g. `d1.com,d2.com`) into
  /// a list of WebKit `if-domain` entries. Drops negated (`~domain`) and
  /// invalid entries.
  static List<String> _parseDomainList(String domainPart) {
    final domains = <String>[];
    for (final raw in domainPart.split(',')) {
      final d = raw.trim().toLowerCase();
      if (d.isEmpty || d.startsWith('~')) {
        continue;
      }
      final ifDomain = '*$d';
      if (isValidIfDomain(ifDomain)) {
        domains.add(ifDomain);
      }
    }
    return domains;
  }

  /// If [selector] is a `+js(name, arg1, arg2, ...)` scriptlet injection,
  /// returns the parsed [ScriptletInjection]. Otherwise returns null
  /// (signalling the caller to fall back to CSS-rule handling).
  static ScriptletInjection? _parseScriptletSelector(
    String selector,
    List<String> domains,
  ) {
    final trimmed = selector.trim();
    if (!trimmed.startsWith('+js(') || !trimmed.endsWith(')')) {
      return null;
    }
    final inner = trimmed.substring(4, trimmed.length - 1);
    final tokens = _splitScriptletArgs(inner);
    if (tokens.isEmpty) {
      return null;
    }
    final name = tokens.first.trim();
    if (name.isEmpty) {
      return null;
    }
    final args = tokens.skip(1).map((s) => s.trim()).toList();
    return ScriptletInjection(domains: domains, name: name, args: args);
  }

  /// Splits the body of `+js(...)` on commas, with uBO quote-awareness.
  ///
  /// Each arg is delimited by a comma at the top level; an arg that
  /// starts with `'`, `"`, or `` ` `` is read up to the matching closing
  /// quote with commas inside taken literally. Outer quotes are stripped
  /// from the returned arg so `\`/regex/\`` becomes `/regex/`. Inside
  /// a quoted arg, `\x` preserves both the backslash and `x` literally
  /// (needed for regex character classes). Outside any quote, `\,` is
  /// an escape for a literal comma.
  static List<String> _splitScriptletArgs(String input) {
    final out = <String>[];
    final buf = StringBuffer();
    String? insideQuote;
    var leading = true;

    void flushArg() {
      out.add(buf.toString());
      buf.clear();
      leading = true;
      insideQuote = null;
    }

    var i = 0;
    while (i < input.length) {
      final ch = input[i];

      if (insideQuote != null) {
        if (ch == insideQuote) {
          insideQuote = null;
          i += 1;
          continue;
        }
        if (ch == r'\' && i + 1 < input.length) {
          buf.write(ch);
          buf.write(input[i + 1]);
          i += 2;
          continue;
        }
        buf.write(ch);
        i += 1;
        continue;
      }

      if (leading) {
        if (ch == ' ' || ch == '\t') {
          i += 1;
          continue;
        }
        if (ch == "'" || ch == '"' || ch == '`') {
          insideQuote = ch;
          leading = false;
          i += 1;
          continue;
        }
        leading = false;
      }

      if (ch == r'\' && i + 1 < input.length && input[i + 1] == ',') {
        buf.write(',');
        i += 2;
        continue;
      }
      if (ch == ',') {
        flushArg();
        i += 1;
        continue;
      }
      buf.write(ch);
      i += 1;
    }

    if (buf.isNotEmpty || out.isNotEmpty) {
      out.add(buf.toString());
    }
    return out;
  }

  /// Builds a [DomainHide] for the given parsed [domains] (already in
  /// WebKit `if-domain` form) and CSS [selector]. Returns null when the
  /// selector is unsupported (scriptlet, regex, ABP pseudo-class).
  static DomainHide? _parseDomainHide(String selector, List<String> domains) {
    if (!_isValidCssSelector(selector)) {
      return null;
    }
    if (domains.isEmpty) {
      return null;
    }
    return DomainHide(domains: domains, selector: selector);
  }

  /// True when [selector] looks like a plain CSS selector (not a
  /// uBlock scriptlet or proprietary pseudo-class that would break
  /// the injected stylesheet).
  static bool _isValidCssSelector(String selector) {
    // Skip scriptlet injection rules.
    if (selector.contains('+js')) {
      return false;
    }
    // Skip ABP `:style()` and `:has-text()` extensions — they are not
    // valid CSS and may cause the browser to ignore the whole rule.
    if (selector.contains(':style(') ||
        selector.contains(':has-text(') ||
        selector.contains(':contains(')) {
      return false;
    }
    // Skip rules that are clearly not selectors (e.g. just a number).
    if (selector.trim().isEmpty) {
      return false;
    }
    // Allow everything else — unknown pseudo-classes are ignored by the
    // browser on a per-rule basis, so they won't break the stylesheet.
    return true;
  }

  /// True when [s] is a value that WebKit's `WKContentRuleList` will accept
  /// as an `if-domain` entry: a lowercase punycode hostname with an
  /// optional single leading `*` for subdomain matching. Anything else
  /// (paths, query strings, non-leading wildcards, uppercase, empty)
  /// will fail the entire rule list compile, so callers should drop
  /// the rule rather than emit it.
  static bool isValidIfDomain(String s) {
    if (s.isEmpty) {
      return false;
    }
    final body = s.startsWith('*') ? s.substring(1) : s;
    if (body.isEmpty) {
      return false;
    }
    return _ifDomainBody.hasMatch(body);
  }

  static final RegExp _ifDomainBody = RegExp(r'^[a-z0-9.\-]+$');

  /// Parses a `||domain.com^…` network block rule into a ContentBlocker
  /// JSON entry, or `null` if the rule has unsupported options.
  static Map<String, dynamic>? _parseNetworkRule(String rule) {
    // Strip leading `||`.
    var remainder = rule.substring(2);

    // Separate options after `$`.
    String? options;
    final dollarIdx = remainder.indexOf('\$');
    if (dollarIdx != -1) {
      options = remainder.substring(dollarIdx + 1);
      remainder = remainder.substring(0, dollarIdx);
    }

    // The remainder should end with `^` (separator) or be the full domain.
    // Strip trailing `^` if present.
    if (remainder.endsWith('^')) {
      remainder = remainder.substring(0, remainder.length - 1);
    }

    // Extract domain. WebKit requires lowercase punycode in `if-domain`.
    final domain = remainder.trim().toLowerCase();
    if (domain.isEmpty) {
      return null;
    }

    // Build if-domain pattern.
    String ifDomain;
    if (domain.startsWith('*.')) {
      ifDomain = '*${domain.substring(2)}';
    } else {
      ifDomain = '*$domain';
    }
    if (!isValidIfDomain(ifDomain)) {
      return null;
    }

    // Parse options.
    final resourceTypes = <String>[];
    if (options != null && options.isNotEmpty) {
      final opts = options.split(',');
      for (final opt in opts) {
        final trimmedOpt = opt.trim();
        switch (trimmedOpt) {
          case 'script':
            resourceTypes.add('script');
          case 'image':
            resourceTypes.add('image');
          case 'media':
            resourceTypes.add('media');
          case 'stylesheet':
            resourceTypes.add('stylesheet');
          case 'font':
            resourceTypes.add('font');
          case 'third-party':
          case '3p':
            // No resource-type restriction, just domain match.
            break;
          case 'first-party':
          case '1p':
          case 'important':
          case 'popup':
          case 'websocket':
          case 'xmlhttprequest':
          case 'xhr':
          case 'document':
          case 'subdocument':
          case 'other':
          case 'all':
            // Unsupported options — skip the whole rule to be safe.
            return null;
          default:
            // Unknown option — skip rule.
            return null;
        }
      }
    }

    final trigger = <String, dynamic>{
      'url-filter': '.*',
      'if-domain': [ifDomain],
    };
    if (resourceTypes.isNotEmpty) {
      trigger['resource-type'] = resourceTypes;
    }

    return <String, dynamic>{
      'trigger': trigger,
      'action': <String, dynamic>{'type': 'block'},
    };
  }
}

/// Result of parsing an ABP filter list.
class AbpParseResult {
  /// Creates a new [AbpParseResult].
  const AbpParseResult({
    required this.cssSelectors,
    required this.domainHides,
    required this.blocklist,
    required this.scriptlets,
  });

  /// Universal element-hiding CSS selectors (the part after `##` in
  /// ABP rules with no domain prefix). Applied on every page.
  final List<String> cssSelectors;

  /// Domain-scoped element-hiding rules (`domain.com##selector`).
  /// Each entry pairs a list of `if-domain` patterns with a CSS
  /// selector — only applied when the page host matches.
  final List<DomainHide> domainHides;

  /// Network-block rules formatted as ContentBlocker-compatible JSON maps.
  final List<Map<String, dynamic>> blocklist;

  /// uBO scriptlet injections (`domain.com##+js(name, args...)`). Each
  /// entry names a scriptlet from the library + its arguments + the
  /// domains the rule applies to. Empty [ScriptletInjection.domains]
  /// means the rule had no domain prefix (universal — rare).
  final List<ScriptletInjection> scriptlets;
}

/// A single domain-scoped element-hiding rule: hide [selector] on any
/// page whose host matches one of [domains] (each in WebKit
/// `if-domain` form — see [AbpParser.isValidIfDomain]).
class DomainHide {
  /// Creates a new [DomainHide].
  const DomainHide({required this.domains, required this.selector});

  /// `if-domain` patterns the rule applies to.
  final List<String> domains;

  /// CSS selector to hide.
  final String selector;
}

/// A parsed `+js(name, args...)` scriptlet rule from a filter list.
/// [domains] is in WebKit `if-domain` form (`*example.com` style) and
/// may be empty for universal scriptlet rules.
class ScriptletInjection {
  /// Creates a new [ScriptletInjection].
  const ScriptletInjection({
    required this.domains,
    required this.name,
    required this.args,
  });

  /// `if-domain` patterns the scriptlet applies to. Empty = universal.
  final List<String> domains;

  /// Scriptlet name as written in the filter rule. Matched against the
  /// runtime library — unknown names are silently dropped at injection
  /// time so listing format changes don't break us.
  final String name;

  /// Positional arguments after the scriptlet name.
  final List<String> args;
}

/// Simple line-splitter that avoids importing dart:io.
class LineSplitter {
  /// Creates a const [LineSplitter].
  const LineSplitter();

  /// Splits [input] into lines.
  List<String> convert(String input) {
    return input.split(RegExp(r'\r?\n'));
  }
}
