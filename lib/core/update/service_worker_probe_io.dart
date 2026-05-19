/// Native (non-web) stub for the service-worker probe + page reload seam.
/// Compiles into desktop builds so the shared update code needs no
/// conditional imports at every call site.
library;

/// Always false off-web: there is no service worker to have a waiting
/// installer.
Future<bool> hasWaitingServiceWorker() async => false;

/// Never called off-web (the refresh banner is web-only); reloads nothing.
void reloadPage() {}
