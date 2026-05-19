/// Web implementation of the service-worker probe + page reload seam.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Whether the Flutter service worker has a new version **installed and
/// waiting** behind the active one — the browser-side second signal that a
/// new deploy exists (the primary signal is `/deploy.json`).
///
/// A waiting worker means the new build's assets are already cached; a
/// `location.reload()` after it activates is the fastest possible pick-up.
Future<bool> hasWaitingServiceWorker() async {
  try {
    final registration = await web.window.navigator.serviceWorker
        .getRegistration()
        .toDart;
    return registration?.waiting != null;
  } on Object {
    // No service worker support (or none registered) — not an update signal.
    return false;
  }
}

/// Reloads the page (the user explicitly consented via the banner's Refresh
/// button; this is never called automatically).
void reloadPage() {
  web.window.location.reload();
}
