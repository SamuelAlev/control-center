/// VM (desktop) half of the SSO login seam — see `sso_login.dart`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/server/auth_providers.dart';
import 'package:control_center/core/server/sso_pair_link.dart';
import 'package:control_center/shared/utils/open_url.dart';

/// VM `/auth/providers` probe.
///
/// It accepts the probed host's SELF-SIGNED certificate, narrowed to that
/// exact host:port — the same bargain (and the same reasoning) as
/// `identityProbeClientFactory`. A non-loopback `cc_server` serves TLS with
/// a self-signed certificate BY DESIGN, so a strict `HttpClient` fails the
/// handshake and the probe returns nothing; the connect screen then hides
/// every "Sign in with …" button and single sign-on looks like a feature the
/// desktop does not have, while the browser — already taught to trust that
/// certificate — shows it on the web client. That asymmetry is the bug this
/// callback fixes.
///
/// Why it is safe: the document is unauthenticated and carries no secret
/// (ids, kinds, labels, one bool), the login itself runs in the system
/// browser, which does full validation, and the credential it mints is
/// verified cryptographically by the Ed25519 handshake in `connectToEntry`
/// — so a poisoned probe fails closed there rather than being trusted. Do
/// NOT widen this to `HttpOverrides.global`, which would disable validation
/// app-wide.
Future<AuthProvidersSnapshot?> probeAuthProvidersImpl(String origin) async {
  final uri = Uri.tryParse('$origin/auth/providers');
  if (uri == null || uri.host.isEmpty) {
    return null;
  }
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 3)
    ..badCertificateCallback = (cert, host, port) =>
        host == uri.host && port == uri.port;
  try {
    final request = await client.getUrl(uri);
    final response = await request.close().timeout(const Duration(seconds: 4));
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      return null;
    }
    return AuthProvidersSnapshot.tryParse(
      await utf8.decoder.bind(response).join(),
    );
  } on Object {
    // Silent by design: the user has not asked for SSO yet, they are still
    // typing a URL. An unreachable server simply offers nothing.
    return null;
  } finally {
    client.close(force: true);
  }
}

/// Desktop round-trip: hand the login URL to the SYSTEM browser (an embedded
/// webview would defeat the IdP's own device trust and MFA) and let the
/// server's bounce page return the credential as a `control-center://pair`
/// deep link. That link arrives on the app's URL channel rather than here,
/// so this always resolves to null.
Future<SsoPairPayload?> startSsoLoginImpl({
  required AuthProviderInfo provider,
  required String origin,
  String? clientOrigin,
  void Function()? onAwaiting,
}) async {
  // Marked BEFORE the browser opens: a fast IdP (an existing session, no
  // prompt) can bounce back before this call even returns, and an unmarked
  // pair link is refused as unbidden.
  markSsoLoginStarted();
  if (!openExternalUrl(provider.loginUrl(origin, relay: 'desktop'))) {
    ssoLoginStartedAt.value = null; // Nothing started; do not leave it armed.
    throw const SsoBrowserOpenException();
  }
  onAwaiting?.call();
  return null;
}

/// No-op on the desktop: there is no listener to tear down (the deep-link
/// handler is app-wide and permanent), and the in-flight marker must survive
/// a closed dialog or the returning credential would be refused.
void cancelSsoLoginImpl() {}

/// Desktop in-flight check — the process-lifetime marker in
/// `sso_pair_link.dart`.
bool ssoLoginInFlightImpl() => isSsoLoginInFlight();
