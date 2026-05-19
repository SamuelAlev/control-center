import 'package:web/web.dart' as web;

/// Web implementation of the `openExternalUrl` seam: opens [url] in a new
/// browser tab. Returns `true` — the browser may block the popup, but there is
/// no synchronous signal for that, and a user-gesture-driven open succeeds.
bool openUrlImpl(String url) {
  web.window.open(url, '_blank');
  return true;
}
