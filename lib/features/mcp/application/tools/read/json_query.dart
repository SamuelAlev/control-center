/// JSON query parser and executor for `agent://` URL extraction.
///
/// Supports jq-like syntax: `.foo`, `[0]`, `.foo.bar[0].baz`, `["special-key"]`.
/// Also supports path form: `/foo/bar/0` → `.foo.bar[0]`.
library;

/// Parse a jq-like query string into tokens.
///
/// ```dart
/// parseQuery('.foo.bar[0]') // ['foo', 'bar', 0]
/// parseQuery(".foo['special-key']") // ['foo', 'special-key']
/// ```
List<dynamic> parseQuery(String query) {
  var input = query.trim();
  if (input.isEmpty) {
    return [];
  }
  if (input.startsWith('.')) {
    input = input.substring(1);
  }
  if (input.isEmpty) {
    return [];
  }

  final tokens = <dynamic>[];
  var i = 0;

  bool isIdentChar(String ch) => RegExp(r'[A-Za-z0-9_-]').hasMatch(ch);

  while (i < input.length) {
    final ch = input[i];
    if (ch == '.') {
      i++;
      continue;
    }
    if (ch == '[') {
      final closeIndex = input.indexOf(']', i + 1);
      if (closeIndex == -1) {
        throw FormatException('Invalid query: missing ] in $query');
      }
      final raw = input.substring(i + 1, closeIndex).trim();
      if (raw.isEmpty) {
        throw FormatException('Invalid query: empty [] in $query');
      }
      final quote = raw[0];
      if ((quote == '"' || quote == "'") && raw.endsWith(quote)) {
        var inner = raw.substring(1, raw.length - 1);
        inner = inner.replaceAll(RegExp('\\\\(["\'\\\\])'), '\$1');
        tokens.add(inner);
      } else if (RegExp(r'^\d+$').hasMatch(raw)) {
        tokens.add(int.parse(raw));
      } else {
        tokens.add(raw);
      }
      i = closeIndex + 1;
      continue;
    }

    final start = i;
    while (i < input.length && isIdentChar(input[i])) {
      i++;
    }
    if (start == i) {
      throw FormatException(
        "Invalid query: unexpected token '${input[i]}' in $query",
      );
    }
    final ident = input.substring(start, i);
    tokens.add(ident);
  }

  return tokens;
}

/// Apply a query string to a JSON value.
///
/// ```dart
/// applyQuery({'foo': {'bar': [1, 2, 3]}}, '.foo.bar[0]') // 1
/// ```
dynamic applyQuery(dynamic data, String query) {
  final tokens = parseQuery(query);
  var current = data;
  for (final token in tokens) {
    if (current == null) {
      return null;
    }
    if (token is int) {
      if (current is! List) {
        return null;
      }
      if (token >= current.length) {
        return null;
      }
      current = current[token];
      continue;
    }
    if (token is! String) {
      return null;
    }
    if (current is! Map<String, dynamic>) {
      return null;
    }
    current = current[token];
  }
  return current;
}

/// Convert a URL path form to a query string.
///
/// Path form: `/foo/bar/0` → `.foo.bar[0]`
/// Trailing slash is normalized (ignored).
///
/// Segments that are not valid identifiers use bracket notation: `['segment']`.
String pathToQuery(String urlPath) {
  if (urlPath.isEmpty || urlPath == '/') {
    return '';
  }

  final segments = urlPath.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) {
    return '';
  }

  final parts = <String>[];
  for (final segment in segments) {
    var decoded = segment;
    try {
      decoded = Uri.decodeComponent(segment);
    } catch (_) {
      decoded = segment;
    }
    if (RegExp(r'^\d+$').hasMatch(decoded)) {
      parts.add('[$decoded]');
    } else if (RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(decoded)) {
      parts.add('.$decoded');
    } else {
      final escaped = decoded.replaceAll('\\', r'\\').replaceAll("'", r"\'");
      parts.add("['$escaped']");
    }
  }

  return parts.join();
}
