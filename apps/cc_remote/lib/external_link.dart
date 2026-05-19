import 'package:web/web.dart' as web;

/// Opens [url] in a new browser tab.
///
/// cc_remote is a web PWA, so this is `window.open` rather than a
/// url_launcher dependency — one platform, one call. `noopener,noreferrer` is
/// not decoration: without `noopener` the opened page gets a live
/// `window.opener` handle back into the PWA and can navigate it (the classic
/// reverse-tabnabbing trick), and these URLs point at forges and article
/// upstreams — pages the app does not control.
///
/// A blank or non-`http(s)` URL is ignored rather than handed to the browser:
/// a `javascript:` URL from a feed item or a PR body would otherwise execute
/// in this origin.
void openExternal(String? url) {
  if (url == null || url.isEmpty) {
    return;
  }
  final parsed = Uri.tryParse(url);
  if (parsed == null || (parsed.scheme != 'http' && parsed.scheme != 'https')) {
    return;
  }
  web.window.open(url, '_blank', 'noopener,noreferrer');
}
