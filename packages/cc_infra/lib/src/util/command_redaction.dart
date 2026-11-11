import 'package:cc_domain/core/domain/services/redaction/token_patterns.dart';

final _redactionPatterns = <RegExp>[
  // `--flag=VALUE` (equals form).
  RegExp(r'(--api[-_]?key\s*=\s*)\S+', caseSensitive: false),
  RegExp(r'(--token\s*=\s*)\S+', caseSensitive: false),
  RegExp(r'(--key\s*=\s*)\S+', caseSensitive: false),
  // VULN-012: `--flag VALUE` (space-separated form, e.g. `gh --token ghp_…`).
  RegExp(r'(--api[-_]?key\s+)\S+', caseSensitive: false),
  RegExp(r'(--token\s+)\S+', caseSensitive: false),
  RegExp(r'(--key\s+)\S+', caseSensitive: false),
  RegExp(r'(Authorization:\s*Bearer\s+)\S+', caseSensitive: false),
  RegExp(r'(Authorization:\s*Basic\s+)\S+', caseSensitive: false),
  RegExp(r'(Authorization:\s*token\s+)\S+', caseSensitive: false),
  // Basic credentials of `x-access-token:<token>` wherever they appear (the
  // `http.extraHeader` value git carries in `GIT_CONFIG_PARAMETERS`, quoted or
  // re-spelled): "x-access-token:" is 15 bytes, so its base64 is always this
  // 20-character prefix.
  RegExp(r'eC1hY2Nlc3MtdG9rZW46[A-Za-z0-9+/=]*'),
  RegExp(r'(CLAUDE_CODE_OAUTH_TOKEN\s*=\s*)\S+', caseSensitive: false),
  // VULN-010: a PAT embedded in a git/https URL — as git echoes on stderr
  // (`https://x-access-token:ghp_…@github.com/…`) when a clone/fetch fails.
  RegExp(r'(x-access-token:)[^@\s]+(@)', caseSensitive: false),
  RegExp(
    r'([a-zA-Z][a-zA-Z0-9+.-]*://[^/@\s]+:)[^@/\s]+(@)',
    caseSensitive: false,
  ),
  RegExp(r'(TICKETING_API_KEY\s*=\s*)\S+', caseSensitive: false),
  RegExp(r'(GH_TOKEN\s*=\s*)\S+', caseSensitive: false),
  RegExp(r'(GITHUB_TOKEN\s*=\s*)\S+', caseSensitive: false),
  RegExp(r'("api[-_]?key"\s*:\s*")[^"]*(")', caseSensitive: false),
  RegExp(r'("token"\s*:\s*")[^"]*(")', caseSensitive: false),
  RegExp(r'("secret"\s*:\s*")[^"]*(")', caseSensitive: false),
  // Every credential shape (GitHub, GitLab, Slack, Linear, Google, Atlassian,
  // API keys, JWTs, private keys): the one table the scanner shares.
  for (final token in kTokenPatterns) token.pattern,
];

const _redacted = '***REDACTED***';

/// One alternation over every pattern in [_redactionPatterns], used only as a
/// "does anything match at all?" probe.
///
/// Redaction runs on every logged event and over every tool result, and the
/// overwhelming majority of them contain no secret at all. Testing them one
/// pattern at a time meant ~20 full scans (and ~20 fresh result strings) of a
/// payload that was going to come back unchanged. This collapses the common
/// case to a single scan with byte-identical output: when the probe finds
/// nothing, no individual pattern could have matched either.
final RegExp _anyRedactionPattern = RegExp(
  _redactionPatterns.map((p) => '(?:${p.pattern})').join('|'),
  caseSensitive: false,
);

/// Redacts sensitive values such as API keys and tokens from [input].
String redactSecrets(String input) {
  if (input.isEmpty || !_anyRedactionPattern.hasMatch(input)) {
    return input;
  }
  var result = input;
  for (final pattern in _redactionPatterns) {
    result = result.replaceAllMapped(pattern, (m) {
      if (m.groupCount >= 2) {
        return '${m[1]}$_redacted${m[2]}';
      }
      return _redacted;
    });
  }
  return result;
}

/// Recursively redacts a decoded JSON structure in place of the
/// `jsonEncode → regex → jsonDecode` round trip.
///
/// String leaves get the full [redactSecrets] treatment and secret-shaped keys
/// are blanked wholesale. This is strictly MORE thorough than scrubbing the
/// encoded form: JSON escaping (`\"token\": \"…\"`) defeats the quoted-key
/// patterns, which match the raw leaf just fine.
Object? redactSecretsInJsonValue(Object? value, {bool underSecretKey = false}) {
  if (value is String) {
    return underSecretKey ? _redacted : redactSecrets(value);
  }
  if (value is Map) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      result[key] = redactSecretsInJsonValue(
        entry.value,
        underSecretKey: _isSecretKey(key.toLowerCase()),
      );
    }
    return result;
  }
  if (value is List) {
    return [
      for (final item in value)
        redactSecretsInJsonValue(item, underSecretKey: underSecretKey),
    ];
  }
  return value;
}

bool _isSecretKey(String keyLower) {
  return keyLower.contains('api_key') ||
      keyLower.contains('apikey') ||
      keyLower.contains('token') ||
      keyLower.contains('secret') ||
      keyLower.contains('password') ||
      keyLower.contains('credential') ||
      keyLower.contains('auth');
}

