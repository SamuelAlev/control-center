/// GitHub serves avatars downscaled when the URL carries an `s=<pixels>` query
/// param, returning a square `s×s` image instead of the full 460×460 default
/// (~283 KB → a few KB for a 48px disc). The stored source is capped at 460px,
/// so any `s` ≥ 460 returns the identical original bytes — we clamp there.
///
/// This must be applied to the upstream GitHub URL BEFORE it is routed through
/// the media proxy (`MediaProxyScope`): the proxy signs and fetches the exact
/// URL it is handed, so sizing here also shrinks what the proxy relays to the
/// client. Both web and the desktop (loopback `cc_server`) route through the
/// proxy; if no scope is present yet it shrinks the direct fetch.
library;

/// Returns [url] with GitHub's server-side downscale `s=` param appended, sized
/// to [logicalSize] logical pixels at [devicePixelRatio], when [url] points at a
/// GitHub avatar host. Non-GitHub hosts (feed favicons, article banners) are
/// returned unchanged — those rely on the proxy resize / client `cacheWidth`.
String sizedGitHubAvatarUrl(
  String url,
  double logicalSize,
  double devicePixelRatio,
) {
  if (url.isEmpty || logicalSize <= 0) {
    return url;
  }
  final uri = Uri.tryParse(url);
  if (uri == null || uri.hasFragment || !_isGitHubAvatarHost(uri)) {
    return url;
  }
  // 460 is GitHub's stored avatar size; larger requests yield the same bytes.
  final s = (logicalSize * devicePixelRatio).ceil().clamp(1, 460);
  // Append raw rather than via Uri.replace(queryParameters:) so existing params
  // (e.g. the `u=`/`v=` tokens GitHub mints) are preserved byte-for-byte instead
  // of round-tripped through form-encoding.
  final separator = uri.hasQuery ? '&' : '?';
  return '$url${separator}s=$s';
}

/// Avatars come from `avatars.githubusercontent.com` (and sibling
/// `*.githubusercontent.com` subdomains) or the `github.com/<owner>.png`
/// redirect shorthand — all of which honour `s=`.
bool _isGitHubAvatarHost(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host.endsWith('githubusercontent.com')) {
    return true;
  }
  return host == 'github.com' && uri.path.toLowerCase().endsWith('.png');
}
