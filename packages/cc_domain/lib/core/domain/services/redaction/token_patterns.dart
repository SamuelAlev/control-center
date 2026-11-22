/// The one table of credential shapes: every consumer that looks for a
/// token in free text (the secret scanner, command and log redaction, the
/// audit trail) reads it from here, so a provider's new token format is
/// added once.
///
/// Every pattern matches the credential itself, with no numbered capture
/// groups, so a consumer can replace the whole match. Every pattern runs in
/// time linear in its input (a test pins each at 1 MiB): free text reaches
/// them on the server's event loop. Context-dependent spellings
/// (`--token VALUE`, `Authorization: …`, a password in a URL) belong to the
/// consumer that knows the context.
///
/// Every pattern matches after a word boundary. `sk-ant-`, the GitHub
/// families (`gh[pousr]_`, `github_pat_`), the GitLab families (`glpat-`
/// and the rest), the Slack `xox...-` forms and `ya29.` also match glued to
/// the letter or digit before them (`xghp_...`, `1sk-ant-...`, a cut of
/// padding run into a token), but only in the vendor's own shape of the
/// token, stated beside each: glued, a loose body is an identifier
/// (`thighs_and_calves`, `task-ant-colony`, `boxoxb-1`), which the
/// redaction must leave alone, since it also rewrites command output an
/// agent reads back. The others are found after a boundary only, because
/// glued they are ordinary text or base64: `Bearer` is a word, a bare `sk-`
/// ends words (`task-`, `risk-`), `AIza`, `AKIA`/`ASIA` and `ATATT`/`ATCTT`
/// have no separator and occur in base64, `xapp-` ends words (`flexapp-`),
/// and `lin_api_`/`lin_oauth_` follow words ending `lin` in identifiers
/// (`kotlin_api_...`, `berlin_api_...`).
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
  // Glued: a key's kind and version (`api03`, `admin01`, `oat01`, `ort01`,
  // `sid01`: lower-case letters, two digits, a dash), then its body, as
  // Anthropic's API, admin and OAuth keys are written.
  TokenPattern._(
    'Anthropic API key',
    RegExp(
      r'\bsk-ant-[A-Za-z0-9_-]{20,}|sk-ant-[a-z]{3,5}[0-9]{2}-[A-Za-z0-9_-]{32,}',
    ),
  ),
  // 20 characters after `sk-` is the shortest key the redaction ever
  // caught; the body may carry `_` and `-` (project and service keys).
  TokenPattern._('API key', RegExp(r'\bsk-[A-Za-z0-9][A-Za-z0-9_-]{19,}')),
  TokenPattern._('Google API key', RegExp(r'\bAIza[0-9A-Za-z_-]{20,}')),
  TokenPattern._('AWS access key', RegExp(r'\b(?:AKIA|ASIA)[0-9A-Z]{16}\b')),
  // PATs, OAuth, user-to-server, refresh and installation tokens. An
  // installation token is `ghs_<appId>_<JWT>` (about 520 characters, with
  // dots and hyphens), so the body is not alphanumeric-only; it never ends
  // on a dot, which keeps a sentence's full stop out of the match. Glued:
  // the body GitHub documents for its prefixed tokens, letters and digits
  // only (30 random characters and a 6-character checksum), from 30 of
  // them, so a token whose checksum a length bound cut off is still found;
  // or an installation token's `ghs_`, the app's numeric id, `_` and a
  // JWT: a header of `eyJ` and 8 to 200 more characters (a run of them is
  // passed over at most 200 characters from each start, so the time stays
  // linear), then its dot-separated segments, never ending on a dot.
  TokenPattern._(
    'GitHub token',
    RegExp(
      r'\bgh[pousr]_[A-Za-z0-9_-][A-Za-z0-9._-]{18,}[A-Za-z0-9_-]'
      r'|gh[pousr]_[A-Za-z0-9]{30,}'
      r'|ghs_[0-9]{1,12}_eyJ[A-Za-z0-9_-]{8,200}(?:\.[A-Za-z0-9_-]+)+',
    ),
  ),
  // Glued: a fine-grained token's own shape, 22 letters and digits, `_`,
  // then 59 more (82 characters after the prefix).
  TokenPattern._(
    'GitHub token',
    RegExp(
      r'\bgithub_pat_[A-Za-z0-9_]{22,}|github_pat_[A-Za-z0-9]{22}_[A-Za-z0-9]{59}',
    ),
  ),
  // Glued, any prefix: the default body, 20 characters and no more (as
  // gitleaks' `gitlab-pat` rule states it), or a routable token (GitLab 17
  // and later): a base64url payload (a random part and a few short routing
  // fields, from 27 characters; gitleaks allows up to 300, 120 keeps a
  // glued prefix that is not one cheap to pass over), `.`, a two-character
  // version and a CRC32 checksum in lower-case base 36, ending the token.
  // gitleaks' `gitlab-pat-routable` rule writes version and checksum as
  // nine characters after the `.`; tokens are also shown with a second `.`
  // after the version and up to nine characters after it, so both are
  // read. Glued, one prefix's own body, then the rest of its run: a
  // pipeline trigger token (`glptt-`) 40 lower-case hex digits; an OAuth
  // application secret (`gloas-`) 64 base64url characters; an agent token
  // (`glagent-`) 50; an incoming mail token (`glimt-`) 25; a CI/CD job
  // token (`glcbt-`) a short id of up to 5 letters or digits, `_` and 20;
  // a runner authentication token (`glrt-`) `t`, a digit, `_` and 20. These
  // six lengths are from memory of public secret scanners' rules (such as
  // gitleaks'), not checked against GitLab's documentation; each is where
  // the shortest such token ends, so a longer one is still found.
  TokenPattern._(
    'GitLab token',
    RegExp(
      r'\bgl(?:pat|oas|dt|rt|cbt|ptt|ft|imt|agent|soat|ffct|wt)-'
      r'[A-Za-z0-9_-]{16,}'
      r'|gl(?:pat|oas|dt|rt|cbt|ptt|ft|imt|agent|soat|ffct|wt)-'
      r'(?:[A-Za-z0-9_-]{27,120}\.[0-9a-z]{2}\.?[0-9a-z]{7,9}(?![A-Za-z0-9])'
      r'|[A-Za-z0-9_-]{20}(?![A-Za-z0-9_-]))'
      r'|gl(?:ptt-[0-9a-f]{40}|oas-[A-Za-z0-9_-]{64}|agent-[A-Za-z0-9_-]{50}'
      r'|imt-[A-Za-z0-9_-]{25}|cbt-[A-Za-z0-9]{1,5}_[A-Za-z0-9_-]{20}'
      r'|rt-t[0-9]_[A-Za-z0-9_-]{20})[A-Za-z0-9_-]*',
    ),
  ),
  TokenPattern._(
    'Atlassian token',
    RegExp(r'\bAT(?:ATT|CTT)[A-Za-z0-9_=+/-]{16,}'),
  ),
  // Bot, user and app-config tokens, rotating `xoxe.` access tokens, their
  // `xoxe-1-` refresh tokens and app-level `xapp-` tokens. Glued: a bot,
  // user or legacy token's first field, the workspace's numeric id of 10 to
  // 13 digits, then a `-` and the rest; or a rotating token's one-digit
  // version, a `-` and its long body of letters and digits (the shapes of
  // Slack's token documentation, as gitleaks' `slack-*` rules state them).
  // A glued body runs on through a `.` before `xox`, so it covers a
  // `xoxe.` token that follows it the way the bounded form would. Glued
  // too: a legacy workspace app token (`xoxa-2-`, `xoxr-2-`), its version
  // digit, `-` and from 30 letters, digits and dashes (from memory of
  // public scanner rules, not checked against Slack's documentation).
  TokenPattern._(
    'Slack token',
    RegExp(
      r'\b(?:xox[abeoprs]|xoxe\.xox[abprs]|xapp)-[A-Za-z0-9-]{8,}'
      r'|xox[abeoprs]-[0-9]{10,13}-(?:[A-Za-z0-9-]|\.(?=xox)){8,}'
      r'|xoxe(?:\.xox[abprs])?-[0-9]-[A-Za-z0-9]{100,}'
      r'|xox[ar]-[0-9]-[A-Za-z0-9-]{30,}',
    ),
  ),
  TokenPattern._(
    'Linear token',
    RegExp(r'\blin_(?:api|oauth)_[A-Za-z0-9]{16,}'),
  ),
  // Access (`ya29.`) and refresh (`1//`) tokens. The refresh shape must not
  // start inside a URL path (`https://1//...` is not one). Glued: Google
  // states no length, only that an access token is opaque base64url of up
  // to 2048 bytes; issued ones run past 100 characters, so a glued one is
  // read from 64 characters of base64url on, and then takes what the
  // bounded form takes (dots too). A service account's (`ya29.c.`) holds
  // dots of its own early on, so glued it is read from 64 characters of
  // base64url and dots after `ya29.c.`.
  TokenPattern._(
    'Google OAuth token',
    RegExp(
      r'\bya29\.[A-Za-z0-9._-]{20,}|ya29\.[A-Za-z0-9_-]{64}[A-Za-z0-9._-]*'
      r'|ya29\.c\.[A-Za-z0-9._-]{64,}'
      r'|(?<![A-Za-z0-9/:._-])1//[A-Za-z0-9_-]{20,}',
    ),
  ),
  // A signed JWT (an ID token, an App JWT, a Connect seal's inner token):
  // a header segment holding `eyJ` and 8 more characters after a word
  // boundary, a payload segment starting `eyJ`, and a signature. Segments
  // have no length bound, so a JWT of any size matches. The match starts
  // where the header's run of segment characters starts (so a `-`-joined
  // prefix such as `x-` is redacted too) and takes that run whole, at once:
  // a run is scanned a fixed number of times, never once per `eyJ` inside
  // it, so the time is linear in the input. Started at every `eyJ`, a long
  // run of `-eyJ…` with no `.` rescanned the rest of the run from each one
  // (quadratic: 43.8 s at 256 KiB).
  TokenPattern._(
    'JSON web token',
    RegExp(
      r'(?<![A-Za-z0-9_-])'
      r'(?=[A-Za-z0-9_-]*?(?<![A-Za-z0-9_])eyJ[A-Za-z0-9_-]{8})'
      r'(?=(?<jwtHeader>[A-Za-z0-9_-]+))\k<jwtHeader>'
      r'\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]*',
    ),
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
