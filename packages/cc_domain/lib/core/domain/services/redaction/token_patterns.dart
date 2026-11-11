/// The one table of credential shapes: every consumer that looks for a
/// token in free text (the secret scanner, command and log redaction, the
/// audit trail) reads it from here, so a provider's new token format is
/// added once.
///
/// Every pattern matches the credential itself, with no capture groups, so
/// a consumer can replace the whole match. Context-dependent spellings
/// (`--token VALUE`, `Authorization: …`, a password in a URL) belong to the
/// consumer that knows the context.
library;

/// A named credential shape.
final class TokenPattern {
  const TokenPattern._(this.label, this.pattern);

  /// What the match is, for a finding (`GitHub token`).
  final String label;

  /// The shape, matching the credential only.
  final RegExp pattern;
}

/// Every credential shape this codebase recognises.
final List<TokenPattern> kTokenPatterns = List.unmodifiable([
  TokenPattern._(
    'bearer token',
    RegExp(r'\bBearer\s+[A-Za-z0-9._~+/=-]{16,}', caseSensitive: false),
  ),
  TokenPattern._('Anthropic API key', RegExp(r'\bsk-ant-[A-Za-z0-9_-]{20,}')),
  // 20 characters after `sk-` is the shortest key the redaction ever
  // caught; the body may carry `_` and `-` (project and service keys).
  TokenPattern._('API key', RegExp(r'\bsk-[A-Za-z0-9][A-Za-z0-9_-]{19,}')),
  TokenPattern._('Google API key', RegExp(r'\bAIza[0-9A-Za-z_-]{20,}')),
  TokenPattern._('AWS access key', RegExp(r'\b(?:AKIA|ASIA)[0-9A-Z]{16}\b')),
  // PATs, OAuth, user-to-server, refresh and installation tokens. An
  // installation token is `ghs_<appId>_<JWT>` (about 520 characters, with
  // dots and hyphens), so the body is not alphanumeric-only; it never ends
  // on a dot, which keeps a sentence's full stop out of the match.
  TokenPattern._(
    'GitHub token',
    RegExp(r'\bgh[pousr]_[A-Za-z0-9_-][A-Za-z0-9._-]{18,}[A-Za-z0-9_-]'),
  ),
  TokenPattern._('GitHub token', RegExp(r'\bgithub_pat_[A-Za-z0-9_]{22,}')),
  TokenPattern._(
    'GitLab token',
    RegExp(
      r'\bgl(?:pat|oas|dt|rt|cbt|ptt|ft|imt|agent|soat|ffct|wt)-'
      r'[A-Za-z0-9_-]{16,}',
    ),
  ),
  TokenPattern._(
    'Atlassian token',
    RegExp(r'\bAT(?:ATT|CTT)[A-Za-z0-9_=+/-]{16,}'),
  ),
  // Bot, user and app-config tokens, rotating `xoxe.` access tokens, their
  // `xoxe-1-` refresh tokens and app-level `xapp-` tokens.
  TokenPattern._(
    'Slack token',
    RegExp(r'\b(?:xox[abeoprs]|xoxe\.xox[abprs]|xapp)-[A-Za-z0-9-]{8,}'),
  ),
  TokenPattern._(
    'Linear token',
    RegExp(r'\blin_(?:api|oauth)_[A-Za-z0-9]{16,}'),
  ),
  // Access (`ya29.`) and refresh (`1//`) tokens. The refresh shape must not
  // start inside a URL path (`https://1//…` is not one).
  TokenPattern._(
    'Google OAuth token',
    RegExp(
      r'\bya29\.[A-Za-z0-9._-]{20,}|(?<![A-Za-z0-9/:._-])1//[A-Za-z0-9_-]{20,}',
    ),
  ),
  // A signed JWT (an ID token, an App JWT, a Connect seal's inner token).
  TokenPattern._(
    'JSON web token',
    RegExp(r'\beyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]*'),
  ),
  // The whole block where it is complete, else from the header on.
  TokenPattern._(
    'private key',
    RegExp(
      r'-----BEGIN [A-Z ]*PRIVATE KEY-----'
      r'(?:[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----|[\s\S]*)',
    ),
  ),
]);

/// One alternation of [kTokenPatterns], for a single "is anything here?"
/// scan before the per-pattern work. Case-insensitive so it never misses
/// what a case-insensitive pattern would find; a probe hit only means the
/// patterns run.
final RegExp kAnyTokenPattern = RegExp(
  kTokenPatterns.map((p) => '(?:${p.pattern.pattern})').join('|'),
  caseSensitive: false,
);

/// [input] with every credential [kTokenPatterns] recognises replaced by
/// [replacement].
String redactTokens(String input, {String replacement = '[REDACTED]'}) {
  if (input.isEmpty || !kAnyTokenPattern.hasMatch(input)) {
    return input;
  }
  var out = input;
  for (final token in kTokenPatterns) {
    out = out.replaceAll(token.pattern, replacement);
  }
  return out;
}
