/// The ONE seam every connect surface uses to discover and start an SSO
/// login, so the desktop setup window, the web connect gate and the in-app
/// "add server" dialog cannot disagree about what a server offers.
///
/// Two platform shapes hide behind it:
/// * Probing — `GET <origin>/auth/providers`, the unauthenticated
///    document naming the enabled SSO connections (id/kind/label) and
///    whether manual pairing is still allowed. On web that is a `fetch`; on
///    the VM it is an `HttpClient` that accepts the probed host's
///    SELF-SIGNED certificate, narrowed to that exact host:port.
/// * Starting a round-trip — each client generates an X25519 recipient. Web
///    decrypts a sealed popup message or same-tab fragment; the desktop
///    decrypts an out-of-band `control-center://pair` deep link. The newly
///    issued PSK never appears in the browser completion response.
library;

import 'package:control_center/core/server/auth_providers.dart';
import 'package:control_center/core/server/sso_login_io.dart'
    if (dart.library.js_interop) 'package:control_center/core/server/sso_login_web.dart';
import 'package:control_center/core/server/sso_pair_link.dart';

/// Probes `<origin>/auth/providers` for the interactive auth methods
/// [origin] offers. Returns null when the server is unreachable or answered
/// something unparseable — callers treat that as "nothing offered" and fall
/// back to manual pairing, exactly as an older server with no such endpoint
/// would behave.
///
/// [origin] is an HTTP origin (`https://host:9030`), not a `ws(s)://` URL —
/// derive it with `httpOriginFor`.
Future<AuthProvidersSnapshot?> probeAuthProviders(String origin) =>
    probeAuthProvidersImpl(origin);

/// Starts [provider]'s interactive round-trip against [origin].
/// Resolves with the minted credential when this platform captures it inline (the web popup
/// relay), or with null when it arrives out-of-band — on the desktop the server's
/// bounce page opens a `control-center://pair` deep link, which the running app adopts in
/// `DesktopServerSwitcher.adoptPairLink` and the pre-app setup window picks up off
/// `pendingSsoPairLink`.
/// A null result is therefore success-so-far, never a failure.
Future<SsoPairPayload?> startSsoLogin({
  required AuthProviderInfo provider,
  required String origin,
  String? clientOrigin,
  void Function()? onAwaiting,
}) => startSsoLoginImpl(
  provider: provider,
  origin: origin,
  clientOrigin: clientOrigin,
  onAwaiting: onAwaiting,
);

/// Stops waiting on the round-trip [startSsoLogin] began (a closed dialog, a
/// disposed screen), resolving its pending future with null.
///
/// This abandons only the *listener*. It deliberately does NOT retract the
/// in-flight marker: the user really did start a login, and a credential
/// arriving after the screen closed must still be recognized as expected
/// rather than refused as an unbidden link.
void cancelSsoLogin() => cancelSsoLoginImpl();

/// A round-trip THIS client started is still inside its adoption window.
/// The client-held recipient key, not the window alone, authenticates the
/// handoff and prevents forged plaintext pair links.
bool ssoLoginInFlight() => ssoLoginInFlightImpl();
