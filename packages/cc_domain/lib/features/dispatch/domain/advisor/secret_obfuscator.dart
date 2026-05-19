/// Replacement token substituted for any matched secret.
const String kRedactedToken = '[REDACTED]';

/// Patterns matching common secret shapes. Ordered most-specific first so a
/// provider-prefixed key is redacted as a whole before the generic
/// `key = value` rule could split it.
final List<RegExp> _secretPatterns = [
  // JSON Web Tokens (header.payload.signature).
  RegExp(r'eyJ[A-Za-z0-9_\-]+\.eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+'),
  // OpenAI-style keys (sk-..., sk-proj-...).
  RegExp(r'sk-[A-Za-z0-9_\-]{16,}'),
  // GitHub tokens (PAT, OAuth, app, refresh) + fine-grained.
  RegExp(r'gh[pousr]_[A-Za-z0-9]{20,}'),
  RegExp(r'github_pat_[A-Za-z0-9_]{20,}'),
  // Slack tokens.
  RegExp(r'xox[baprs]-[A-Za-z0-9\-]{10,}'),
  // AWS access key ids.
  RegExp(r'AKIA[0-9A-Z]{16}'),
  // Google API keys.
  RegExp(r'AIza[0-9A-Za-z_\-]{35}'),
  // Authorization: Bearer <token>.
  RegExp(r'(?<=[Bb]earer\s)[A-Za-z0-9._\-]{12,}'),
  // Generic `secret/token/api_key/password = <value>` assignments.
  RegExp(
    r'''(?<=(?:api[_-]?key|secret|token|password|passwd|pwd)["']?\s*[:=]\s*["']?)[A-Za-z0-9._\-]{8,}''',
    caseSensitive: false,
  ),
];

/// Redacts secrets from [text] before it is shown to the advisor (or any other
/// secondary consumer). Replaces every match of [_secretPatterns] with
/// [kRedactedToken]. Conservative — it errs toward over-redaction of
/// high-value credential shapes rather than leaking them into a second model's
/// context. Returns [text] unchanged when nothing matches.
String obfuscateSecrets(String text) {
  if (text.isEmpty) {
    return text;
  }
  var result = text;
  for (final pattern in _secretPatterns) {
    result = result.replaceAll(pattern, kRedactedToken);
  }
  return result;
}
