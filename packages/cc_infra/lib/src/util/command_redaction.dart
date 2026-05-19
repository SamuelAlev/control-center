import 'dart:convert';

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
  RegExp(r'\bsk-[a-zA-Z0-9]{20,}\b'),
  RegExp(r'\bghp_[a-zA-Z0-9]{36,}\b'),
  RegExp(r'\bgho_[a-zA-Z0-9]{36,}\b'),
  // VULN-012: GitHub App server-to-server / user-to-server / refresh token
  // prefixes — the shapes the fine-grained broker and GitHub App flows mint.
  RegExp(r'\bghs_[a-zA-Z0-9]{36,}\b'),
  RegExp(r'\bghu_[a-zA-Z0-9]{36,}\b'),
  RegExp(r'\bghr_[a-zA-Z0-9]{36,}\b'),
  RegExp(r'\bgithub_pat_[a-zA-Z0-9_]{22,}\b'),
  // VULN-010: a PAT embedded in a git/https URL — as git echoes on stderr
  // (`https://x-access-token:ghp_…@github.com/…`) when a clone/fetch fails.
  RegExp(r'(x-access-token:)[^@\s]+(@)', caseSensitive: false),
  RegExp(r'([a-zA-Z][a-zA-Z0-9+.-]*://[^/@\s]+:)[^@/\s]+(@)', caseSensitive: false),
  // Provider-specific token shapes (defense-in-depth secret scrubbing).
  RegExp(r'\blin_api_[a-zA-Z0-9]{20,}\b'),
  RegExp(r'(TICKETING_API_KEY\s*=\s*)\S+', caseSensitive: false),
  RegExp(r'(GH_TOKEN\s*=\s*)\S+', caseSensitive: false),
  RegExp(r'(GITHUB_TOKEN\s*=\s*)\S+', caseSensitive: false),
  RegExp(r'("api[-_]?key"\s*:\s*")[^"]*(")', caseSensitive: false),
  RegExp(r'("token"\s*:\s*")[^"]*(")', caseSensitive: false),
  RegExp(r'("secret"\s*:\s*")[^"]*(")', caseSensitive: false),
];

const _redacted = '***REDACTED***';

/// Redacts sensitive values such as API keys and tokens from [input].
String redactSecrets(String input) {
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

/// Redacts sensitive values from a JSON string by parsing and recursively
/// sanitizing its keys and values.
String redactSecretsFromJson(String jsonLine) {
  try {
    final map = jsonDecode(jsonLine) as Map<String, dynamic>;
    final sanitized = _redactMapValues(map);
    return jsonEncode(sanitized);
  } catch (_) {
    return redactSecrets(jsonLine);
  }
}

Map<String, dynamic> _redactMapValues(Map<String, dynamic> map) {
  final result = <String, dynamic>{};
  for (final entry in map.entries) {
    final keyLower = entry.key.toLowerCase();
    if (entry.value is String &&
        (_isSecretKey(keyLower) || _looksLikeSecret(entry.value as String))) {
      result[entry.key] = _redacted;
    } else if (entry.value is Map<String, dynamic>) {
      result[entry.key] = _redactMapValues(entry.value as Map<String, dynamic>);
    } else if (entry.value is List) {
      result[entry.key] = entry.value;
    } else {
      result[entry.key] = entry.value;
    }
  }
  return result;
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

bool _looksLikeSecret(String value) {
  if (value.length < 10) {
    return false;
  }
  return value.startsWith('sk-') ||
      value.startsWith('ghp_') ||
      value.startsWith('gho_') ||
      value.startsWith('ghs_') ||
      value.startsWith('ghu_') ||
      value.startsWith('ghr_') ||
      value.startsWith('github_pat_') ||
      value.startsWith('lin_');
}
