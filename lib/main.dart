import 'package:control_center/bootstrap/bootstrap.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

/// Single entrypoint for both desktop and web.
///
/// The real startup lives behind a conditional-import seam (`bootstrap.dart`):
/// on the VM it runs the full native multi-window desktop bootstrap; on web it
/// runs the connect-then-render thin-client bootstrap. Both expose
/// `bootstrapAndRun`, so this shim is target-agnostic.
void main() {
  // Use clean path-based URLs on web (`/workspaces/<id>/dashboard` instead of
  // `/#/workspaces/<id>/dashboard`). This also frees the URL fragment for the
  // pairing PSK that the connect bootstrap reads (see `_readUrlHints` in
  // bootstrap_web.dart). Platform-safe — a no-op on desktop. The deployed web
  // app already serves index.html for every path (wrangler.jsonc
  // `single-page-application`), so deep-link reloads resolve to the app shell.
  usePathUrlStrategy();
  bootstrapAndRun();
}
