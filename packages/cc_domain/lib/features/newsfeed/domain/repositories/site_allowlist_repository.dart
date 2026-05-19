/// Per-domain allowlist for content blocking: a domain on this list has
/// blocking disabled (ads/trackers will render).
///
/// Inspired by `flutter_adblocker_webview`'s `allowedDomains` semantics:
/// adding `example.com` also allows `www.example.com` and any deeper
/// subdomain, but not unrelated hosts that merely share the suffix
/// (`notexample.com` is *not* matched by `example.com`).
abstract class SiteAllowlistRepository {
  /// Emits the current allowlist whenever it changes. Always emits the
  /// initial value on subscribe.
  Stream<Set<String>> watch();

  /// Returns the current allowlist.
  Future<Set<String>> read();

  /// Adds [domain] to the allowlist. Caller is responsible for normalising
  /// (lowercase, no scheme, no path) — see [normalizeDomain].
  Future<void> add(String domain);

  /// Removes [domain] from the allowlist.
  Future<void> remove(String domain);

  /// True when [url]'s host is covered by an entry in [allowedDomains].
  /// Match is exact host OR subdomain (`sub.example.com` is allowed by
  /// `example.com`).
  bool isAllowedUrl(String url, Set<String> allowedDomains);

  /// Extracts the host from [url], lowercased, or empty string if [url]
  /// isn't parseable.
  String hostOf(String url);

  /// Normalises a user-entered domain: trims, lowercases, strips scheme +
  /// path. Returns empty string if the input doesn't contain a usable
  /// domain.
  String normalizeDomain(String input);
}
