/// Returns true when [host] matches any of the [patterns].
///
/// Patterns support a single leading `*.` wildcard: `*.example.com` matches
/// `foo.example.com` and `a.b.example.com`, but not `example.com` itself —
/// list both the apex and the wildcard if you want both.
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
  return false;
}

String _normalize(String s) => s.trim().toLowerCase();
