/// The ONE seam every connect surface uses to discover and start an SSO
/// login, so the desktop setup window, the web connect gate and the in-app
/// "add server" dialog cannot disagree about what a server offers.
///
/// Two platform shapes hide behind it:
///  * **Probing** — `GET <origin>/auth/providers`, the unauthenticated
///    document naming the enabled SSO connections (id/kind/label) and
///    whether manual pairing is still allowed. On web that is a `fetch`; on
///    the VM it is an `HttpClient` that accepts the probed host's
///    SELF-SIGNED certificate, narrowed to that exact host:port.
///  * **Starting a round-trip** — web opens a popup and receives the minted
///    credential back by `postMessage`; the desktop hands the URL to the
///    SYSTEM browser and the credential returns out-of-band as a
///    `control-center://pair` deep link.
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
///
/// Resolves with the minted credential when this platform captures it
/// inline (the web popup relay), or with **null** when it arrives
/// out-of-band — on the desktop the server's bounce page opens a
/// `control-center://pair` deep link, which the running app adopts in
/// `DesktopServerSwitcher.adoptPairLink` and the pre-app setup window picks
/// up off `pendingSsoPairLink`. A null result is therefore success-so-far,
/// never a failure.
///
/// Throws [SsoBrowserOpenException] when no browser could be opened at all.
///
/// [clientOrigin] declares the calling tab's own browser origin (web only):
/// the server holds it with the pending login and posts the credential back
/// to exactly that origin. It defaults to this document's origin.
///
/// [onAwaiting] fires once the browser is up and the credential is being
/// waited for — the cue to swap a button's spinner for "waiting for your
/// browser…".
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

/// Whether a round-trip THIS client started is still inside its adoption
/// window. A bounce-back arriving outside it was not asked for — anyone can
/// craft one, and adopting it would silently re-home the app to an impostor
/// server — so surfaces confirm with the user or refuse.
bool ssoLoginInFlight() => ssoLoginInFlightImpl();
