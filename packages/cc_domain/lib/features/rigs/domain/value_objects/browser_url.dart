/// URLs that are the browser's own documents, not a destination a person
/// chose.
///
/// Chromium's failed-load interstitial commits as
/// `chrome-error://chromewebdata/` while the address bar should keep showing
/// the URL that failed. `about:blank` is the same class: a frame that never
/// finished loading must not blank out the address a person just read.
/// Re-committing that interstitial (a viewport resize, a pointer move that
/// restarts the error document) is what makes the bar flicker between the
/// two.
bool isBrowserInternalUrl(String url) {
  if (url.isEmpty) {
    return true;
  }
  final lower = url.toLowerCase();
  if (lower == 'about:blank' || lower == 'about:srcdoc') {
    return true;
  }
  if (lower.startsWith('chrome-error:') ||
      lower.startsWith('edge-error:') ||
      lower.startsWith('devtools:')) {
    return true;
  }
  return false;
}

/// The URL the address bar should show for a committed document.
///
/// When [url] is browser furniture, [fallback] is the failed destination
/// CDP still names (`frame.unreachableUrl`, history `userTypedURL`). An
/// empty result means "do not replace whatever the bar already shows".
String visibleBrowserUrl(String url, {String? fallback}) {
  if (!isBrowserInternalUrl(url)) {
    return url;
  }
  final other = fallback?.trim() ?? '';
  if (other.isNotEmpty && !isBrowserInternalUrl(other)) {
    return other;
  }
  return '';
}

/// Rewrites `localhost` / `[::1]` to `127.0.0.1` so a navigate hits the
/// IPv4 reverse-tunnel listener.
///
/// Enclosed Chromium resolves bare `localhost` to `::1` (and
/// `--host-resolver-rules` does not always override that). The ports
/// service plants `TCP4-LISTEN` on `127.0.0.1`. A numeric IPv4 URL skips
/// DNS entirely. Other hosts are unchanged, including `*.localhost` and
/// `*.test` dev domains.
String guestLoopbackUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasAuthority) {
    return url;
  }
  final host = uri.host.toLowerCase();
  if (host != 'localhost' && host != 'localhost.' && host != '::1') {
    return url;
  }
  return uri.replace(host: '127.0.0.1').toString();
}

/// What the address field shows for a committed [url].
///
/// The guest home page is a `file://` document inside the enclosure — a
/// fresh tab, not a place the person chose — so it shows empty. Browser
/// furniture (`chrome-error://`, `about:blank`) is empty too; the toolbar
/// keeps whatever address it already had.
String browserAddressBarText(String? url) {
  if (url == null || url.isEmpty || url.startsWith('file://')) {
    return '';
  }
  return visibleBrowserUrl(url);
}

/// Turns address-bar input into a loadable `http(s)` URL, or null when blank.
String? normalizeBrowserAddressInput(String value) {
  final raw = value.trim();
  if (raw.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(raw);
  final hasScheme = uri != null && uri.hasScheme;
  return hasScheme ? guestLoopbackUrl(raw) : 'https://$raw';
}
