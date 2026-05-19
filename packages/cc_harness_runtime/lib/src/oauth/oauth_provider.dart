import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/pkce.dart';

/// A browser OAuth flow for one LLM provider (authorization-code + PKCE).
///
/// The broker drives it: build the authorize URL, run the loopback callback (or
/// accept a pasted code), exchange the code for tokens and refresh before
/// expiry. Each implementation knows its provider's endpoints, client id,
/// scopes and callback port.
abstract class HarnessOAuthProvider {
  /// Provider id this flow authenticates (e.g. `anthropic`).
  String get providerId;

  /// The fixed loopback port the provider redirects to.
  int get callbackPort;

  /// The callback path (e.g. `/callback`).
  String get callbackPath;

  /// The loopback redirect URI the provider is registered against.
  String get redirectUri => 'http://localhost:$callbackPort$callbackPath';

  /// Builds the authorization URL the user opens in a browser.
  String buildAuthUrl({required Pkce pkce, required String state});

  /// Exchanges an authorization [code] for a stored credential.
  Future<ProviderCredential> exchange({
    required String code,
    required Pkce pkce,
  });

  /// Refreshes [credential], returning a new credential with a fresh token.
  Future<ProviderCredential> refresh(ProviderCredential credential);
}

/// A device-authorization OAuth flow (RFC 8628) for one LLM provider.
///
/// The sibling of [HarnessOAuthProvider] for providers that issue no redirect:
/// the user opens a verification page on any device, confirms a short code and
/// the server polls the token endpoint until it flips. There is no loopback
/// port, no PKCE and no pasteable authorization code — which is exactly why it
/// cannot reuse [HarnessOAuthProvider]. The broker drives both kinds.
abstract class HarnessDeviceOAuthProvider {
  /// Provider id this flow authenticates (e.g. `kimi-code`).
  String get providerId;

  /// Requests a device code, returning what the user must be shown and what the
  /// broker must poll with.
  Future<HarnessDeviceAuthorization> authorize();

  /// Polls once for [deviceCode]. Returns the credential once the user has
  /// authorized, or null while the authorization is still pending. Throws when
  /// the flow has terminally failed (denied, expired, unknown error).
  Future<ProviderCredential?> poll(String deviceCode);

  /// Refreshes [credential], returning a new credential with a fresh token.
  Future<ProviderCredential> refresh(ProviderCredential credential);
}

/// A pending device authorization: what to show the user and how to poll.
class HarnessDeviceAuthorization {
  /// Creates a [HarnessDeviceAuthorization].
  const HarnessDeviceAuthorization({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.interval,
    required this.expiresIn,
  });

  /// The secret the broker polls the token endpoint with. Never shown.
  final String deviceCode;

  /// The short code the user confirms in the browser.
  final String userCode;

  /// The page the user opens, with [userCode] pre-filled where the provider
  /// supports it.
  final String verificationUri;

  /// The minimum interval the provider allows between polls.
  final Duration interval;

  /// How long the device code stays valid.
  final Duration expiresIn;
}

/// Thrown by a device flow's `poll` when the provider answered `slow_down`:
/// still pending, but the client is polling too fast. Distinct from a plain
/// pending (null) because the broker must widen its interval and distinct from
/// [HarnessDeviceAuthException] because the flow is still alive.
class HarnessDeviceSlowDown implements Exception {
  /// Creates a [HarnessDeviceSlowDown].
  const HarnessDeviceSlowDown();
}

/// Thrown when a device-code flow fails in a way retrying cannot fix.
class HarnessDeviceAuthException implements Exception {
  /// Creates a [HarnessDeviceAuthException].
  const HarnessDeviceAuthException(this.message);

  /// Human-readable cause, surfaced to the user in the settings UI.
  final String message;

  @override
  String toString() => message;
}
