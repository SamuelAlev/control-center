/// The rule for which tool-call arguments are too sensitive to keep in a log
/// or an audit row, and the redaction that applies it.
///
/// One rule for every place that records a tool call's arguments: the MCP
/// dispatcher's call log and the code mode call rows. Two copies of the key
/// list is how one of them quietly starts keeping a token the other drops.
///
/// Matching is by key, case-insensitive and ignoring separators, on a
/// substring: `api_key`, `X-Api-Key` and `githubToken` are all sensitive. Free text (`content`,
/// `body`, `message`, `text`) counts too, because it is where a person's own
/// words and pasted secrets end up.
// ignore: avoid_classes_with_only_static_members
abstract final class SensitiveArguments {
  /// The fragments that make a key sensitive.
  static const Set<String> keyFragments = {
    'content',
    'body',
    'message',
    'text',
    'token',
    'secret',
    'psk',
    'password',
    'authorization',
    'api_key',
    'apikey',
    'credential',
  };

  /// What a redacted value is replaced with.
  static const String marker = '‹redacted›';

  /// Whether the argument named [key] holds a value that must not be kept.
  ///
  /// Hyphens, underscores and spaces are ignored on both sides, so
  /// `X-Api-Key`, `api_key` and `apiKey` are one key to this rule.
  static bool isSensitiveKey(String key) {
    final k = _normalize(key);
    return _normalizedFragments.any(k.contains);
  }

  static final Set<String> _normalizedFragments = {
    for (final fragment in keyFragments) _normalize(fragment),
  };

  static String _normalize(String key) =>
      key.toLowerCase().replaceAll(RegExp('[-_ ]'), '');

  /// A copy of [value] with every sensitive key's value replaced by
  /// [marker], at any depth: maps inside lists inside maps are redacted the
  /// same way as the top level.
  ///
  /// Keys are kept, so a reader still sees which arguments were passed.
  /// Values that are not maps or lists are returned unchanged; a map's keys
  /// are read as strings.
  static Object? redact(Object? value) {
    if (value is Map) {
      return <String, Object?>{
        for (final entry in value.entries)
          '${entry.key}': isSensitiveKey('${entry.key}')
              ? marker
              : redact(entry.value),
      };
    }
    if (value is List) {
      return [for (final item in value) redact(item)];
    }
    return value;
  }
}
