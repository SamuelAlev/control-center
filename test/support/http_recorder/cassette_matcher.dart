import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';

import 'cassette.dart';

/// Recursively sorts map keys so two structurally-equal JSON values serialize
/// identically — the basis of order-insensitive request matching.
Object? canonicalizeJson(Object? value) {
  if (value is List) {
    return [for (final item in value) canonicalizeJson(item)];
  }
  if (value is Map) {
    final keys = value.keys.map((k) => '$k').toList()..sort();
    return {for (final k in keys) k: canonicalizeJson(value[k])};
  }
  return value;
}

/// Decodes [body] as JSON, returning the raw string when it is not JSON.
Object? _bodyValue(String body) {
  if (body.isEmpty) {
    return body;
  }
  try {
    return canonicalizeJson(jsonDecode(body));
  } catch (_) {
    return body;
  }
}

/// A canonical string identity for a request: method, URL, headers and JSON
/// body with object keys sorted.
String canonicalRequest(RequestSnapshot snapshot) => jsonEncode({
  'method': snapshot.method,
  'url': snapshot.url,
  'headers': canonicalizeJson(snapshot.headers),
  'body': _bodyValue(snapshot.body),
});

/// Decides whether an incoming request matches a recorded one.
typedef RequestMatcher =
    bool Function(RequestSnapshot incoming, RequestSnapshot recorded);

/// The default matcher: canonical request equality.
bool defaultRequestMatcher(
  RequestSnapshot incoming,
  RequestSnapshot recorded,
) => canonicalRequest(incoming) == canonicalRequest(recorded);

String _safeText(Object? value) {
  if (value == null) {
    return 'null';
  }
  final text = value is String ? value : jsonEncode(value);
  return text.length > 300 ? '${text.substring(0, 300)}...' : text;
}

List<String> _valueDiffs(
  Object? expected,
  Object? received, [
  String base = r'$',
  int limit = 8,
]) {
  if (expected == received) {
    return const [];
  }
  if (expected is Map && received is Map) {
    final keys = {...expected.keys, ...received.keys}.map((k) => '$k').toList()
      ..sort();
    final out = <String>[];
    for (final key in keys) {
      out.addAll(
        _valueDiffs(expected[key], received[key], '$base.$key', limit),
      );
      if (out.length >= limit) {
        break;
      }
    }
    return out.take(limit).toList();
  }
  if (expected is List && received is List) {
    final out = <String>[];
    final length = expected.length > received.length
        ? expected.length
        : received.length;
    for (var i = 0; i < length; i++) {
      final e = i < expected.length ? expected[i] : null;
      final r = i < received.length ? received[i] : null;
      out.addAll(_valueDiffs(e, r, '$base[$i]', limit));
      if (out.length >= limit) {
        break;
      }
    }
    return out.take(limit).toList();
  }
  return [
    '$base expected ${_safeText(expected)}, received ${_safeText(received)}',
  ];
}

/// Builds a rich, per-field diff explaining why an [expected] recorded request
/// did not match the [received] incoming one — surfaced when replay fails.
List<String> requestDiff(RequestSnapshot expected, RequestSnapshot received) {
  final lines = <String>[];
  if (expected.method != received.method) {
    lines.add('method:');
    lines.add('  expected ${expected.method}, received ${received.method}');
  }
  if (expected.url != received.url) {
    lines.add('url:');
    lines.add('  expected ${expected.url}');
    lines.add('  received ${received.url}');
  }
  final headerKeys = {
    ...expected.headers.keys,
    ...received.headers.keys,
  }.toList()..sort();
  final headerLines = <String>[];
  for (final key in headerKeys) {
    final e = expected.headers[key];
    final r = received.headers[key];
    if (e == r) {
      continue;
    }
    if (e == null) {
      headerLines.add('  $key unexpected ${_safeText(r)}');
    } else if (r == null) {
      headerLines.add('  $key missing expected ${_safeText(e)}');
    } else {
      headerLines.add(
        '  $key expected ${_safeText(e)}, received ${_safeText(r)}',
      );
    }
  }
  if (headerLines.isNotEmpty) {
    lines.add('headers:');
    lines.addAll(headerLines.take(8));
  }
  if (expected.body != received.body) {
    final eBody = _bodyValue(expected.body);
    final rBody = _bodyValue(received.body);
    final bodyLines = (eBody is! String || rBody is! String)
        ? _valueDiffs(eBody, rBody).map((l) => '  $l').toList()
        : ['  expected ${_safeText(eBody)}, received ${_safeText(rBody)}'];
    if (bodyLines.isNotEmpty) {
      lines.add('body:');
      lines.addAll(bodyLines);
    }
  }
  return lines;
}

/// The outcome of a sequential cursor lookup.
class CassetteMatch {
  /// Creates a [CassetteMatch].
  const CassetteMatch({this.interaction, required this.detail});

  /// The matched interaction, or null when none matched.
  final HttpInteraction? interaction;

  /// Human-readable diagnostics when [interaction] is null.
  final String detail;
}

/// Walks the cassette in record order: the Nth request executed at runtime is
/// served by the Nth recorded interaction, validated as the cursor advances.
/// Deliberately strict — repeated identical requests must return their own
/// recorded responses in turn (so retry/polling/cache tests stay honest).
CassetteMatch selectSequential(
  List<HttpInteraction> interactions,
  RequestSnapshot incoming,
  RequestMatcher match,
  int index,
) {
  if (index >= interactions.length) {
    return CassetteMatch(
      detail: 'interaction ${index + 1} of ${interactions.length} not recorded',
    );
  }
  final interaction = interactions[index];
  if (!match(incoming, interaction.request)) {
    return CassetteMatch(
      detail: requestDiff(interaction.request, incoming).join('\n'),
    );
  }
  return CassetteMatch(interaction: interaction, detail: '');
}
