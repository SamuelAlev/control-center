/// Returns true when [host] matches any of the [patterns].
///
/// Two wildcard forms, both with exactly one `*`:
///
///  * **Leading** — `*.example.com` matches `foo.example.com` and
///    `a.b.example.com`, but not `example.com` itself. List both the apex and
///    the wildcard if you want both.
///  * **Middle label** — `bedrock.*.amazonaws.com` matches
///    `bedrock.us-east-1.amazonaws.com` and nothing else: the `*` stands for
///    exactly ONE label, so it cannot swallow dots and reach
///    `bedrock.evil.attacker.amazonaws.com`.
///
/// The middle form exists because the alternative was `*.amazonaws.com` — an
/// entry that had to be written to reach AWS Bedrock and admitted every S3
/// bucket and every AWS subdomain in the world along with it.
bool matchesAny(String host, Iterable<String> patterns) {
  if (host.isEmpty) {
    return false;
  }
  final normalized = _normalize(host);
  for (final pattern in patterns) {
    if (_matches(normalized, _normalize(pattern))) {
      return true;
    }
  }
  return false;
}

bool _matches(String host, String pattern) {
  if (pattern.isEmpty) {
    return false;
  }
  if (pattern == host) {
    return true;
  }
  if (pattern.startsWith('*.')) {
    final suffix = pattern.substring(1); // ".example.com"
    return host.endsWith(suffix) && host.length > suffix.length;
  }
  // A single middle-label wildcard: `a.*.b.com`. Anything with more than one
  // `*`, or a `*` glued to other characters inside a label, is not a pattern
  // this matcher understands — and an unrecognised pattern must match NOTHING
  // rather than something surprising.
  final star = pattern.indexOf('*');
  if (star <= 0 || pattern.indexOf('*', star + 1) != -1) {
    return false;
  }
  if (pattern[star - 1] != '.' ||
      star + 1 >= pattern.length ||
      pattern[star + 1] != '.') {
    return false;
  }
  final prefix = pattern.substring(0, star); // "bedrock."
  final suffix = pattern.substring(star + 1); // ".amazonaws.com"
  // The length guard is not decoration: `bedrock.amazonaws.com` starts with
  // `bedrock.` AND ends with `.amazonaws.com` because the two OVERLAP, and
  // slicing between them throws.
  if (host.length <= prefix.length + suffix.length ||
      !host.startsWith(prefix) ||
      !host.endsWith(suffix)) {
    return false;
  }
  final middle = host.substring(prefix.length, host.length - suffix.length);
  // Exactly one label: non-empty and dot-free.
  return middle.isNotEmpty && !middle.contains('.');
}

String _normalize(String s) => s.trim().toLowerCase();
