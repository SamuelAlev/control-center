/// Returns [value] as a JSON object, or null when it is anything else.
///
/// Bitbucket nests almost everything one level deep (`author`, `inline`,
/// `source.branch`, `state.result`, …); this keeps the wire models free of
/// repeated `is Map<String, dynamic>` ceremony.
Map<String, dynamic>? asJsonMap(Object? value) =>
    value is Map<String, dynamic> ? value : null;

/// Returns the `href` of the [name] entry inside a Bitbucket `links` object.
///
/// Every Bitbucket resource carries `links: {self: {href}, html: {href},
/// avatar: {href}, …}`. Returns `''` when the link — or the whole `links`
/// object — is absent, which is the same "unknown" the domain entities model
/// with an empty URL string.
String linkHref(Object? links, String name) {
  final entry = asJsonMap(asJsonMap(links)?[name]);
  return entry?['href'] as String? ?? '';
}

/// Decodes a JSON array of objects with [fromJson], skipping non-object
/// entries.
///
/// Bitbucket embeds arrays of accounts (`reviewers`), participants and
/// diffstat entries inline; a malformed element is dropped rather than taking
/// the whole payload down.
List<T> decodeJsonList<T>(
  Object? value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List) {
    return <T>[];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map(fromJson)
      .toList(growable: false);
}
